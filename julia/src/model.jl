using Base.Libc.Libdl: dlsym, dllist, dlopen

struct StanModelStruct end

mutable struct StanRNGStruct end

# utility macro to annotate a field as const only if supported
@eval macro $(Symbol("const"))(x)
    if VERSION >= v"1.8"
        Expr(:const, esc(x))
    else
        esc(x)
    end
end

"""
    StanModel(lib, data="", seed=204; stanc_args=[], make_args=[], warn=true)

A StanModel instance encapsulates a Stan model instantiated with data.

Construct a Stan model from the supplied library file path and data.
If lib is a path to a file ending in `.stan`, this will first compile
the model.  Compilation occurs if no shared object file exists for the
supplied Stan file or if a shared object file exists and the Stan file
has changed since last compilation.  This is equivalent to calling
`compile_model` and then the constructor of `StanModel`. If `warn` is
false, the warning about re-loading the same shared objects is suppressed.

Data should either be a string containing a JSON string literal, a
path to a data file ending in `.json`, or the empty string.

If seed is supplied, it is used to initialize the RNG used by the model's constructor.
"""
mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    @const data::String
    @const seed::UInt32

    function StanModel(
        lib::String,
        data::String = "",
        seed = 204;
        stanc_args::AbstractVector{String} = String[],
        make_args::AbstractVector{String} = String[],
        warn::Bool = true,
    )
        seed = convert(UInt32, seed)

        if !isfile(lib)
            throw(SystemError("File not found: $lib"))
        end

        if endswith(lib, ".stan")
            lib = compile_model(lib; stanc_args, make_args)
        end

        if warn && in(abspath(lib), dllist())
            @warn "Loading a shared object '" *
                  lib *
                  "' which is already loaded.\n" *
                  "If the file has changed since the last time it was loaded, this load may not update the library!"
        end

        if data != "" && endswith(data, ".json")
            if !isfile(data)
                throw(SystemError("Data file not found"))
            end
            data = open(data) do f
                read(f, String)
            end
        end

        windows_dll_path_setup()

        lib = dlopen(lib)

        err = Ref{Cstring}()
        stanmodel = @ccall $(dlsym(lib, :bs_model_construct))(
            data::Cstring,
            seed::UInt32,
            err::Ref{Cstring},
        )::Ptr{StanModelStruct}
        if stanmodel == C_NULL
            error(handle_error(lib, err, "bs_model_construct"))
        end

        sm = new(lib, stanmodel, data, seed)

        function f(sm)
            @ccall $(dlsym(sm.lib, :bs_model_destruct))(
                sm.stanmodel::Ptr{StanModelStruct},
            )::Cvoid
        end

        finalizer(f, sm)
    end
end

"""
    StanRNG(sm::StanModel, seed)

Construct a StanRNG instance from a `StanModel` instance and a seed.

This can be used in the `param_constrain` and `param_constrain!` methods
when using the generated quantities block.

This object is not thread-safe, one should be created per thread.
"""
mutable struct StanRNG
    lib::Ptr{Nothing}
    ptr::Ptr{StanRNGStruct}
    seed::UInt32

    function StanRNG(sm::StanModel, seed)
        seed = convert(UInt32, seed)

        err = Ref{Cstring}()

        ptr = @ccall $(dlsym(sm.lib, :bs_rng_construct))(
            seed::UInt32,
            err::Ref{Cstring},
        )::Ptr{StanRNGStruct}

        if ptr == C_NULL
            error(handle_error(sm.lib, err, "bs_rng_construct"))
        end

        stanrng = new(sm.lib, ptr, seed)

        function f(stanrng)
            @ccall $(dlsym(stanrng.lib, :bs_rng_destruct))(
                stanrng.ptr::Ptr{StanRNGStruct},
            )::Cvoid
        end

        finalizer(f, stanrng)
    end
end

"""
    new_rng(sm::StanModel, seed)

Construct a StanRNG instance from a `StanModel` instance and a seed.  This
function is a wrapper around the constructor `StanRNG`.

This can be used in the `param_constrain` and `param_constrain!` methods
when using the generated quantities block.

The StanRNG object created is not thread-safe, one should be created per thread.
"""
new_rng(sm::StanModel, seed) = StanRNG(sm, seed)

"""
    name(sm)

Return the name of the model `sm`
"""
function name(sm::StanModel)
    cstr = @ccall $(dlsym(sm.lib, :bs_name))(sm.stanmodel::Ptr{StanModelStruct})::Cstring
    unsafe_string(cstr)
end

"""
    model_info(sm)

Return information about the model `sm`.

This includes the Stan version and important
compiler flags.
"""
function model_info(sm::StanModel)
    cstr =
        @ccall $(dlsym(sm.lib, :bs_model_info))(sm.stanmodel::Ptr{StanModelStruct})::Cstring
    unsafe_string(cstr)
end

"""
    model_version(sm)

Return the BridgeStan version of the compiled model `sm`.
"""
function model_version(sm::StanModel)
    major = reinterpret(Ptr{Cint}, dlsym(sm.lib, "bs_major_version"))
    minor = reinterpret(Ptr{Cint}, dlsym(sm.lib, "bs_minor_version"))
    patch = reinterpret(Ptr{Cint}, dlsym(sm.lib, "bs_patch_version"))
    (unsafe_load(major), unsafe_load(minor), unsafe_load(patch))
end

"""
    param_num(sm; include_tp=false, include_gq=false)

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block
of the model. If `include_tp` or `include_gq` are true, items declared
in the `transformed parameters` and `generate quantities` blocks are included,
respectively.
"""
function param_num(sm::StanModel; include_tp::Bool = false, include_gq::Bool = false)
    @ccall $(dlsym(sm.lib, :bs_param_num))(
        sm.stanmodel::Ptr{StanModelStruct},
        include_tp::Bool,
        include_gq::Bool,
    )::Cint
end


"""
    param_unc_num(sm)

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num`
when variables are declared with constraints. For example,
`simplex[5]` has a constrained size of 5, but an unconstrained size of 4.
"""
function param_unc_num(sm::StanModel)
    @ccall $(dlsym(sm.lib, :bs_param_unc_num))(sm.stanmodel::Ptr{StanModelStruct})::Cint
end

"""
    param_names(sm; include_tp=false, include_gq=false)

Return the indexed names of the (constrained) parameters,
including transformed parameters and/or generated quantities as indicated.

For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name `"a"`, the vector entry `a[1]`
has indexed name `"a.1"` and the matrix entry `a[2, 3]` has indexed names `"a.2.3"`.
Parameter order of the output is column major and more generally last-index major for containers.
"""
function param_names(sm::StanModel; include_tp::Bool = false, include_gq::Bool = false)
    cstr = @ccall $(dlsym(sm.lib, :bs_param_names))(
        sm.stanmodel::Ptr{StanModelStruct},
        include_tp::Bool,
        include_gq::Bool,
    )::Cstring
    string.(split(unsafe_string(cstr), ','))
end

"""
    param_unc_names(sm)

Return the indexed names of the unconstrained parameters.

For example, a scalar unconstrained parameter `b` has indexed name `b`
and a vector entry `b[3]` has indexed name `b.3`.
"""
function param_unc_names(sm::StanModel)
    cstr = @ccall $(dlsym(sm.lib, :bs_param_unc_names))(
        sm.stanmodel::Ptr{StanModelStruct},
    )::Cstring
    string.(split(unsafe_string(cstr), ','))
end

"""
    param_constrain!(sm, theta_unc, out; include_tp=false, include_gq=false, rng=nothing)

Returns a vector constrained parameters given unconstrained parameters.
Additionally (if `include_tp` and `include_gq` are set, respectively)
returns transformed parameters and generated quantities.

If `include_gq` is `true`, then `rng` must be provided.
See `StanRNG` for details on how to construct RNGs.

The result is stored in the vector `out`, and a reference is returned. See
`param_constrain` for a version which allocates fresh memory.

This is the inverse of `param_unconstrain!`.
"""
function param_constrain!(
    sm::StanModel,
    theta_unc::Vector{Float64},
    out::Vector{Float64};
    include_tp::Bool = false,
    include_gq::Bool = false,
    rng::Union{StanRNG,Nothing} = nothing,
)
    dims = param_num(sm; include_tp = include_tp, include_gq = include_gq)
    if length(out) != dims
        throw(
            DimensionMismatch("out must be same size as number of constrained parameters"),
        )
    end

    if rng === nothing
        if include_gq
            throw(ArgumentError("Must provide an RNG when including generated quantities"))
        end
        rng_ptr = C_NULL
    else
        rng_ptr = rng.ptr
    end

    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_param_constrain))(
        sm.stanmodel::Ptr{StanModelStruct},
        include_tp::Bool,
        include_gq::Bool,
        theta_unc::Ref{Cdouble},
        out::Ref{Cdouble},
        rng_ptr::Ptr{StanRNGStruct},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "param_constrain"))
    end
    out
end

"""
    param_constrain(sm, theta_unc, out; include_tp=false, include_gq=false, rng=nothing)

Returns a vector constrained parameters given unconstrained parameters.
Additionally (if `include_tp` and `include_gq` are set, respectively)
returns transformed parameters and generated quantities.

If `include_gq` is `true`, then `rng` must be provided.
See `StanRNG` for details on how to construct RNGs.

This allocates new memory for the output each call.
See `param_constrain!` for a version which allows
re-using existing memory.

This is the inverse of `param_unconstrain`.
"""
function param_constrain(
    sm::StanModel,
    theta_unc::Vector{Float64};
    include_tp::Bool = false,
    include_gq::Bool = false,
    rng::Union{StanRNG,Nothing} = nothing,
)
    out = zeros(param_num(sm, include_tp = include_tp, include_gq = include_gq))
    param_constrain!(
        sm,
        theta_unc,
        out;
        include_tp = include_tp,
        include_gq = include_gq,
        rng = rng,
    )
end

"""
    param_unconstrain!(sm, theta, out)

Returns a vector of unconstrained params give the constrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g.,
in the same order as `param_names(sm)`). If structured input is needed, use `param_unconstrain_json!`

The result is stored in the vector `out`, and a reference is returned. See
`param_unconstrain` for a version which allocates fresh memory.

This is the inverse of `param_constrain!`.
"""
function param_unconstrain!(sm::StanModel, theta::Vector{Float64}, out::Vector{Float64})
    dims = param_unc_num(sm)
    if length(out) != dims
        throw(
            DimensionMismatch(
                "out must be same size as number of unconstrained parameters",
            ),
        )
    end
    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_param_unconstrain))(
        sm.stanmodel::Ptr{StanModelStruct},
        theta::Ref{Cdouble},
        out::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "param_unconstrain"))
    end
    out
end

"""
    param_unconstrain(sm, theta)

Returns a vector of unconstrained params give the constrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g.,
in the same order as `param_unc_names(sm)`). If structured input is needed, use `param_unconstrain_json`

This allocates new memory for the output each call.
See `param_unconstrain!` for a version which allows
re-using existing memory.

This is the inverse of `param_constrain`.
"""
function param_unconstrain(sm::StanModel, theta::Vector{Float64})
    out = zeros(param_unc_num(sm))
    param_unconstrain!(sm, theta, out)
end

"""
    param_unconstrain_json!(sm, theta, out)

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

The result is stored in the vector `out`, and a reference is returned. See
`param_unconstrain_json` for a version which allocates fresh memory.
"""
function param_unconstrain_json!(sm::StanModel, theta::String, out::Vector{Float64})
    dims = param_unc_num(sm)
    if length(out) != dims
        throw(
            DimensionMismatch(
                "out must be same size as number of unconstrained parameters",
            ),
        )
    end

    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_param_unconstrain_json))(
        sm.stanmodel::Ptr{StanModelStruct},
        theta::Cstring,
        out::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "param_unconstrain_json"))
    end
    out
end

"""
    param_unconstrain_json(sm, theta)

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

This allocates new memory for the output each call.
See `param_unconstrain_json!` for a version which allows
re-using existing memory.
"""
function param_unconstrain_json(sm::StanModel, theta::String)
    out = zeros(param_unc_num(sm))
    param_unconstrain_json!(sm, theta, out)
end

"""
    log_density(sm, q; propto=true, jacobian=true)

Return the log density of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.
"""
function log_density(
    sm::StanModel,
    q::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    lp = Ref(0.0)
    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_log_density))(
        sm.stanmodel::Ptr{StanModelStruct},
        propto::Bool,
        jacobian::Bool,
        q::Ref{Cdouble},
        lp::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "log_density"))
    end
    lp[]
end


"""
    log_density_gradient!(sm, q, out; propto=true, jacobian=true)

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out`, and a reference is returned. See
`log_density_gradient` for a version which allocates fresh memory.
"""
function log_density_gradient!(
    sm::StanModel,
    q::Vector{Float64},
    out::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    dims = param_unc_num(sm)
    if length(out) != dims
        throw(
            DimensionMismatch(
                "out must be same size as number of unconstrained parameters",
            ),
        )
    end
    lp = Ref(0.0)
    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_log_density_gradient))(
        sm.stanmodel::Ptr{StanModelStruct},
        propto::Bool,
        jacobian::Bool,
        q::Ref{Cdouble},
        lp::Ref{Cdouble},
        out::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "log_density_gradient"))
    end
    (lp[], out)
end

"""
    log_density_gradient(sm, q; propto=true, jacobian=true)

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.


This allocates new memory for the gradient output each call.
See `log_density_gradient!` for a version which allows
re-using existing memory.
"""
function log_density_gradient(
    sm::StanModel,
    q::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    grad = zeros(param_unc_num(sm))
    log_density_gradient!(sm, q, grad; propto = propto, jacobian = jacobian)
end

"""
    log_density_hessian!(sm, q, out_grad, out_hess; propto=true, jacobian=true)

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out_grad` and the
Hessian is stored in `out_hess` and references are returned. See
`log_density_hessian` for a version which allocates fresh memory.
"""
function log_density_hessian!(
    sm::StanModel,
    q::Vector{Float64},
    out_grad::Vector{Float64},
    out_hess::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    dims = param_unc_num(sm)
    if length(out_grad) != dims
        throw(
            DimensionMismatch(
                "out_grad must be same size as number of unconstrained parameters",
            ),
        )
    elseif length(out_hess) != dims * dims
        throw(
            DimensionMismatch(
                "out_hess must be same size as (number of unconstrained parameters)^2",
            ),
        )
    end
    lp = Ref(0.0)
    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_log_density_hessian))(
        sm.stanmodel::Ptr{StanModelStruct},
        propto::Bool,
        jacobian::Bool,
        q::Ref{Cdouble},
        lp::Ref{Cdouble},
        out_grad::Ref{Cdouble},
        out_hess::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "log_density_hessian"))
    end
    (lp[], out_grad, reshape(out_hess, (dims, dims)))
end

"""
    log_density_hessian(sm, q; propto=true, jacobian=true)

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient and Hessian output each call.
See `log_density_gradient!` for a version which allows
re-using existing memory.
"""
function log_density_hessian(
    sm::StanModel,
    q::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    dims = param_unc_num(sm)
    grad = zeros(dims)
    hess = zeros(dims * dims)
    log_density_hessian!(sm, q, grad, hess; propto = propto, jacobian = jacobian)
end

"""
    log_density_hessian_vector_product!(sm, q, v, out; propto=true, jacobian=true)

Returns log density and the product of the Hessian of the log density with the vector `v`
at the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The product is stored in the vector `out` and a reference is returned. See
`log_density_hessian_vector_product` for a version which allocates fresh memory.
"""
function log_density_hessian_vector_product!(
    sm::StanModel,
    q::Vector{Float64},
    v::Vector{Float64},
    out::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    dims = param_unc_num(sm)
    if length(out) != dims
        throw(
            DimensionMismatch(
                "out must be same size as number of unconstrained parameters",
            ),
        )
    end
    lp = Ref(0.0)
    err = Ref{Cstring}()
    rc = @ccall $(dlsym(sm.lib, :bs_log_density_hessian_vector_product))(
        sm.stanmodel::Ptr{StanModelStruct},
        propto::Bool,
        jacobian::Bool,
        q::Ref{Cdouble},
        v::Ref{Cdouble},
        lp::Ref{Cdouble},
        out::Ref{Cdouble},
        err::Ref{Cstring},
    )::Cint
    if rc != 0
        error(handle_error(sm.lib, err, "log_density_hessian_vector_product"))
    end
    (lp[], out)
end

"""
    log_density_hessian_vector_product(sm, q, v; propto=true, jacobian=true)

Returns log density and the product of the Hessian of the log density with the vector `v`
at the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true`
and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the output each call. See
`log_density_hessian_vector_product!` for a version which allows re-using existing memory.
"""
function log_density_hessian_vector_product(
    sm::StanModel,
    q::Vector{Float64},
    v::Vector{Float64};
    propto::Bool = true,
    jacobian::Bool = true,
)
    out = zeros(param_unc_num(sm))
    log_density_hessian_vector_product!(sm, q, v, out; propto = propto, jacobian = jacobian)
end

"""
    log_density_hessian_vector_product(sm, q, v; propto=true, jacobian=true)
"""


"""
    handle_error(lib::Ptr{Nothing}, err::Ref{Cstring}, method::String)

Retrieves the error message allocated in C++ and frees it before returning a copy.
"""
function handle_error(lib::Ptr{Nothing}, err::Ref{Cstring}, method::String)
    if err[] == C_NULL
        return "Unknown error in $method."
    else
        s = string(unsafe_string(err[]))
        @ccall $(dlsym(lib, "bs_free_error_msg"))(err[]::Cstring)::Cvoid
        return s
    end
end
