module BridgeStan

export
    StanModel,
    name,
    param_num,
    param_unc_num,
    param_names,
    param_unc_names,
    param_constrain!,
    param_unconstrain!,
    param_unconstrain_json!,
    log_density_gradient!,
    log_density_hessian!,
    param_constrain,
    param_unconstrain,
    param_unconstrain_json,
    log_density,
    log_density_gradient,
    log_density_hessian

mutable struct StanModelStruct
end

mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    const data::String
    const seed::UInt32
    const chain_id::UInt32

    function StanModel(stanlib_::String, datafile_::String, seed_ = 204, chain_id_ = 0)
        seed = convert(UInt32, seed_)
        chain_id = convert(UInt32, chain_id_)
        lib = Libc.Libdl.dlopen(stanlib_)

        stanmodel = ccall(Libc.Libdl.dlsym(lib, "construct"),
                          Ptr{StanModelStruct},
                          (Cstring, UInt32, UInt32),
                          datafile_, seed, chain_id)


        sm = new(lib, stanmodel, datafile_, seed, chain_id)

        function f(sm)
            ccall(Libc.Libdl.dlsym(sm.lib, "destruct"),
                UInt32,
                (Ptr{StanModelStruct},),
                sm.stanmodel)
            @async Libc.Libdl.dlclose(sm.lib)
        end

        finalizer(f, sm)
    end
end

function name(sm::StanModel)
    cstr = ccall(Libc.Libdl.dlsym(sm.lib, "name"),
                 Cstring,
                 (Ptr{StanModelStruct},),
                 sm.stanmodel)
    unsafe_string(cstr)
end

function param_num(sm::StanModel; include_tp = false, include_gq = false)
    ccall(Libc.Libdl.dlsym(sm.lib, "param_num"),
          Cint,
          (Ptr{StanModelStruct}, Cint, Cint),
          sm.stanmodel, include_tp, include_gq)
end

function param_unc_num(sm::StanModel)
    ccall(Libc.Libdl.dlsym(sm.lib, "param_unc_num"),
          Cint,
          (Ptr{StanModelStruct},),
          sm.stanmodel)
end

function param_names(sm::StanModel; include_tp = false, include_gq = false)
    cstr = ccall(Libc.Libdl.dlsym(sm.lib, "param_names"),
                 Cstring,
                 (Ptr{StanModelStruct}, Cint, Cint),
                 sm.stanmodel, include_tp, include_gq)
    [string(s) for s in split(unsafe_string(cstr), ',')]
end

function param_unc_names(sm::StanModel)
    cstr = ccall(Libc.Libdl.dlsym(sm.lib, "param_unc_names"),
                 Cstring,
                 (Ptr{StanModelStruct},),
                 sm.stanmodel)
    [string(s) for s in split(unsafe_string(cstr), ',')]
end

function param_constrain!(sm::StanModel, theta_unc, out::Vector{Float64}; include_tp=false, include_gq=false)
    dims = param_num(sm; include_tp=include_tp, include_gq=include_gq)
    if length(out) != dims
        error("out must be same size as number of constrained parameters")
    end
    rc = ccall(Libc.Libdl.dlsym(sm.lib, "param_constrain"),
               Cint,
               (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}),
               sm.stanmodel, include_tp, include_gq, theta_unc, out)
    if rc != 0
        error("param_constrain failed on C++ side; see stderr for messages")
    else
        out
    end
end

function param_constrain(sm::StanModel, theta_unc; include_tp=false, include_gq=false)
    out = zeros(param_num(sm, include_tp=include_tp, include_gq=include_gq))
    param_constrain!(sm, theta_unc, out; include_tp=include_tp, include_gq=include_gq)
end


function param_unconstrain!(sm::StanModel, theta, out::Vector{Float64})
    dims = param_unc_num(sm)
    if length(out) != dims
        error("out must be same size as number of unconstrained parameters")
    end

    rc = ccall(Libc.Libdl.dlsym(sm.lib, "param_unconstrain"),
               Cint,
               (Ptr{StanModelStruct}, Ref{Cdouble}, Ref{Cdouble}),
               sm.stanmodel, theta, out)
    if rc != 0
        error("param_unconstrain failed on C++ side; see stderr for messages")
    else
        out
    end
end

function param_unconstrain(sm::StanModel, theta)
    out = zeros(param_unc_num(sm))
    param_unconstrain!(sm, theta, out)
end

function param_unconstrain_json!(sm::StanModel, theta::String, out::Vector{Float64})
    dims = param_unc_num(sm)
    if length(out) != dims
        error("out must be same size as number of unconstrained parameters")
    end

    rc = ccall(Libc.Libdl.dlsym(sm.lib, "param_unconstrain_json"),
               Cint,
               (Ptr{StanModelStruct}, Cstring, Ref{Cdouble}),
               sm.stanmodel, theta, out)
    if rc != 0
        error("param_unconstrain_json failed on C++ side; see stderr for messages")
    else
        out
    end
end

function param_unconstrain_json(sm::StanModel, theta::String)
    out = zeros(param_unc_num(sm))
    param_unconstrain_json!(sm, theta, out)
end

function log_density(sm::StanModel, q; propto = true, jacobian = true)
    lp = Ref{Float64}(0.0)
    rc = ccall(Libc.Libdl.dlsym(sm.lib, "log_density"),
              Cint,
              (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}),
              sm.stanmodel, propto, jacobian, q, lp)
    if rc != 0
        error("log_density failed on C++ side; see stderr for messages")
    else
        lp[]
    end
end

function log_density_gradient!(sm::StanModel, q, out::Vector{Float64}; propto = true, jacobian = true)
    lp = Ref{Float64}(0.0)
    dims = param_unc_num(sm)
    if length(out) != dims
        error("out must be same size as number of unconstrained parameters")
    end

    rc = ccall(Libc.Libdl.dlsym(sm.lib, "log_density_gradient"),
              Cint,
              (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              sm.stanmodel, propto, jacobian, q, lp, out)
    if rc != 0
        error("log_density_gradient failed on C++ side; see stderr for messages")
    else
        (lp[], out)
    end
end

function log_density_gradient(sm::StanModel, q; propto = true, jacobian = true)
    grad = zeros(param_unc_num(sm))
    log_density_gradient!(sm, q, grad; propto=propto, jacobian=jacobian)
end

function log_density_hessian!(sm::StanModel, q, out_grad::Vector{Float64}, out_hess::Vector{Float64}; propto = true, jacobian = true)
    lp = Ref{Float64}(0.0)
    dims = param_unc_num(sm)
    if length(out_grad) != dims
        error("out_grad must be same size as number of unconstrained parameters")
    elseif length(out_hess) != dims*dims
        error("out_hess must be same size as (number of unconstrained parameters)^2")
    end

    rc = ccall(Libc.Libdl.dlsym(sm.lib, "log_density_hessian"),
              Cint,
              (Ptr{StanModelStruct}, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              sm.stanmodel, propto, jacobian, q, lp, out_grad, out_hess)
    if rc != 0
        error("log_density_hessian failed on C++ side; see stderr for messages")
    else
        (lp[], out_grad, reshape(out_hess, (dims, dims)))
    end
end

function log_density_hessian(sm::StanModel, q; propto = true, jacobian = true)
    dims = param_unc_num(sm)
    grad = zeros(dims)
    hess = zeros(dims * dims)
    log_density_hessian!(sm,q, grad, hess; propto=propto, jacobian=jacobian)
end

end
