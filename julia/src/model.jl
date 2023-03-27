
mutable struct StanModelStruct end

# utility macro to annotate a field as const only if supported
@eval macro $(Symbol("const"))(x)
    if VERSION >= v"1.8"
        Expr(:const, esc(x))
    else
        esc(x)
    end
end

"""
    StanModel(lib, datafile="", seed=204, chain_id=0)

A StanModel instance encapsulates a Stan model instantiated with data.

Construct a Stan model from the supplied library file path and data. Data
should either be a string containing a JSON string literal or a path to a data file ending in `.json`.
If seed or chain_id are supplied, these are used to initialize the RNG used by the model.

    StanModel(;stan_file, data="", seed=204, chain_id=0)

Construct a `StanModel` instance from a `.stan` file, compiling if necessary.

    StanModel(;stan_file, stanc_args=[], make_args=[], data="", seed=204, chain_id=0)

Construct a `StanModel` instance from a `.stan` file.  Compilation
occurs if no shared object file exists for the supplied Stan file or
if a shared object file exists and the Stan file has changed since
last compilation.  This is equivalent to calling `compile_model` and
then the original constructor of `StanModel`.
"""
mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    @const data::String
    @const seed::UInt32
    @const chain_id::UInt32

    function StanModel(lib::String, data::String = "", seed = 204, chain_id = 0)
        seed = convert(UInt32, seed)
        chain_id = convert(UInt32, chain_id)

        if !isfile(lib)
            throw(SystemError("Dynamic library file not found"))
        end

        if in(abspath(lib), Libc.Libdl.dllist())
            @warn "Loading a shared object '" *
                  lib *
                  "' which is already loaded.\n" *
                  "If the file has changed since the last time it was loaded, this load may not update the library!"
        end

        if data != "" && endswith(data, ".json") && !isfile(data)
            throw(SystemError("Data file not found"))
        end

        lib = Libc.Libdl.dlopen(lib)

        err = Ref{Cstring}()

        stanmodel = ccall(
            Libc.Libdl.dlsym(lib, "bs_construct"),
            Ptr{StanModelStruct},
            (Cstring, UInt32, UInt32, Ref{Cstring}),
            data,
            seed,
            chain_id,
            err,
        )
        if stanmodel == C_NULL
            error(_get_err(lib, err, "bs_construct"))
        end

        sm = new(lib, stanmodel, data, seed, chain_id)

        function f(sm)
            ccall(
                Libc.Libdl.dlsym(sm.lib, "bs_destruct"),
                UInt32,
                (Ptr{StanModelStruct},),
                sm.stanmodel,
            )
        end

        finalizer(f, sm)
    end
end

"""
    name(sm)

Return the name of the model `sm`
"""
function name(sm::StanModel)
    cstr = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_name"),
        Cstring,
        (Ptr{StanModelStruct},),
        sm.stanmodel,
    )
    unsafe_string(cstr)
end

"""
    model_info(sm)

Return information about the model `sm`.

This includes the Stan version and important
compiler flags.
"""
function model_info(sm::StanModel)
    cstr = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_model_info"),
        Cstring,
        (Ptr{StanModelStruct},),
        sm.stanmodel,
    )
    unsafe_string(cstr)
end

"""
    param_num(sm; include_tp=false, include_gq=false)

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block
of the model. If `include_tp` or `include_gq` are true, items declared
in the `transformed parameters` and `generate quantities` blocks are included,
respectively.
"""
function param_num(sm::StanModel; include_tp = false, include_gq = false)
    ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_num"),
        Cint,
        (Ptr{StanModelStruct}, Cint, Cint),
        sm.stanmodel,
        include_tp,
        include_gq,
    )
end


"""
    param_unc_num(sm)

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num`
when variables are declared with constraints. For example,
`simplex[5]` has a constrained size of 5, but an unconstrained size of 4.
"""
function param_unc_num(sm::StanModel)
    ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_unc_num"),
        Cint,
        (Ptr{StanModelStruct},),
        sm.stanmodel,
    )
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
function param_names(sm::StanModel; include_tp = false, include_gq = false)
    cstr = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_names"),
        Cstring,
        (Ptr{StanModelStruct}, Cint, Cint),
        sm.stanmodel,
        include_tp,
        include_gq,
    )
    string.(split(unsafe_string(cstr), ','))
end

"""
    param_unc_names(sm)

Return the indexed names of the unconstrained parameters.

For example, a scalar unconstrained parameter `b` has indexed name `b`
and a vector entry `b[3]` has indexed name `b.3`.
"""
function param_unc_names(sm::StanModel)
    cstr = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_unc_names"),
        Cstring,
        (Ptr{StanModelStruct},),
        sm.stanmodel,
    )
    string.(split(unsafe_string(cstr), ','))
end

"""
    param_constrain!(sm, theta_unc, out; include_tp=false, include_gq=false)

Returns a vector constrained parameters given unconstrained parameters.
Additionally (if `include_tp` and `include_gq` are set, respectively)
returns transformed parameters and generated quantities.

The result is stored in the vector `out`, and a reference is returned. See
`param_constrain` for a version which allocates fresh memory.

This is the inverse of `param_unconstrain!`.
"""
function param_constrain!(
    sm::StanModel,
    theta_unc::Vector{Float64},
    out::Vector{Float64};
    include_tp = false,
    include_gq = false,
)
    dims = param_num(sm; include_tp = include_tp, include_gq = include_gq)
    if length(out) != dims
        throw(
            DimensionMismatch("out must be same size as number of constrained parameters"),
        )
    end
    err = Ref{Cstring}()
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_constrain"),
        Cint,
        (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cstring}),
        sm.stanmodel,
        include_tp,
        include_gq,
        theta_unc,
        out,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "param_constrain"))
    end
    out
end

"""
    param_constrain(sm, theta_unc, out; include_tp=false, include_gq=false)

Returns a vector constrained parameters given unconstrained parameters.
Additionally (if `include_tp` and `include_gq` are set, respectively)
returns transformed parameters and generated quantities.

This allocates new memory for the output each call.
See `param_constrain!` for a version which allows
re-using existing memory.

This is the inverse of `param_unconstrain`.
"""
function param_constrain(
    sm::StanModel,
    theta_unc::Vector{Float64};
    include_tp = false,
    include_gq = false,
)
    out = zeros(param_num(sm, include_tp = include_tp, include_gq = include_gq))
    param_constrain!(sm, theta_unc, out; include_tp = include_tp, include_gq = include_gq)
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
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_unconstrain"),
        Cint,
        (Ptr{StanModelStruct}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cstring}),
        sm.stanmodel,
        theta,
        out,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "param_unconstrain"))
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
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_param_unconstrain_json"),
        Cint,
        (Ptr{StanModelStruct}, Cstring, Ref{Cdouble}, Ref{Cstring}),
        sm.stanmodel,
        theta,
        out,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "param_unconstrain_json"))
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
function log_density(sm::StanModel, q::Vector{Float64}; propto = true, jacobian = true)
    lp = Ref(0.0)
    err = Ref{Cstring}()
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_log_density"),
        Cint,
        (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cstring}),
        sm.stanmodel,
        propto,
        jacobian,
        q,
        lp,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "log_density"))
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
    propto = true,
    jacobian = true,
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
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_log_density_gradient"),
        Cint,
        (
            Ptr{StanModelStruct},
            Cint,
            Cint,
            Ref{Cdouble},
            Ref{Cdouble},
            Ref{Cdouble},
            Ref{Cstring},
        ),
        sm.stanmodel,
        propto,
        jacobian,
        q,
        lp,
        out,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "log_density_gradient"))
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
    propto = true,
    jacobian = true,
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
    propto = true,
    jacobian = true,
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
    rc = ccall(
        Libc.Libdl.dlsym(sm.lib, "bs_log_density_hessian"),
        Cint,
        (
            Ptr{StanModelStruct},
            Cint,
            Cint,
            Ref{Cdouble},
            Ref{Cdouble},
            Ref{Cdouble},
            Ref{Cdouble},
            Ref{Cstring},
        ),
        sm.stanmodel,
        propto,
        jacobian,
        q,
        lp,
        out_grad,
        out_hess,
        err,
    )
    if rc != 0
        error(_get_err(sm.lib, err, "log_density_hessian"))
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
    propto = true,
    jacobian = true,
)
    dims = param_unc_num(sm)
    grad = zeros(dims)
    hess = zeros(dims * dims)
    log_density_hessian!(sm, q, grad, hess; propto = propto, jacobian = jacobian)
end

"""
    _get_err(sm::StanModel, err::Ref{Cstring}, method::String)

Retrieves the error message allocated in C++ and frees it before returning a copy.
"""
function _get_err(lib::Ptr{Nothing}, err::Ref{Cstring}, method::String)
    if err[] == C_NULL
        return "Unknown error in $method."
    else
        s = string(unsafe_string(err[]))
        ccall(Libc.Libdl.dlsym(lib, "bs_free_error_msg"), Cvoid, (Cstring,), err[])
        return s
    end
end
