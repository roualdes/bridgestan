module JBS

export
    StanModel,
    log_density_gradient!,
    K,
    param_num,
    param_constrain!,
    dims,
    param_unc_num,
    param_unconstrain!,
    destroy

mutable struct StanModelStruct
end

mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    dims::Int
    unconstrained_parameters::Vector{Float64}
    data::String
    seed::UInt32
    K::Int
    constrained_parameters::Vector{Float64}
    log_density::Vector{Float64}
    gradient::Vector{Float64}
    function StanModel(stanlib_::Ptr{Nothing}, datafile_::String, seed_ = 204)
        seed = convert(UInt32, seed_)

        stanmodel = ccall(Libc.Libdl.dlsym(stanlib_, "create"),
                          Ptr{StanModelStruct},
                          (Cstring, UInt32),
                          datafile_, seed)

        dims = ccall(Libc.Libdl.dlsym(stanlib_, "param_unc_num"),
                     Cint,
                     (Ptr{StanModelStruct},),
                     stanmodel)

        K = ccall(Libc.Libdl.dlsym(stanlib_, "param_num"),
                  Cint,
                  (Ptr{StanModelStruct},),
                  stanmodel)

        sm = new(stanlib_, stanmodel, dims, zeros(dims), datafile_, seed, K, zeros(K), zeros(1), zeros(dims))

        function f(sm)
            ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
                  Cvoid,
                  (Ptr{StanModelStruct},),
                  sm.stanmodel)
        end

        finalizer(f, sm)
    end
end

function log_density_gradient!(sm::StanModel, q; propto = 1, jacobian = 1)
    ccall(Libc.Libdl.dlsym(sm.lib, "log_density_gradient"),
          Cvoid,
          (Ptr{StanModelStruct}, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
          sm.stanmodel, sm.dims, q, sm.log_density, sm.gradient, propto, jacobian)
end



function K(sm::StanModel)
    return sm.K
end

function param_num(sm::StanModel)
    return ccall(Libc.Libdl.dlsym(sm.lib, "param_num"),
                 Cint,
                 (Ptr{StanModelStruct},),
                 sm)
end

function param_constrain!(sm::StanModel, q)
    ccall(Libc.Libdl.dlsym(sm.lib, "param_constrain"),
          Cvoid,
          (Ptr{StanModelStruct}, Cint, Ref{Cdouble}, Cint, Ref{Cdouble}),
          sm.stanmodel, sm.dims, q, sm.K, sm.constrained_parameters)
end

function dims(sm::StanModel)
    return sm.dims
end

function param_unc_num(sm::StanModel)
    return ccall(Libc.Libdl.dlsym(sm.lib, "param_unc_num"),
                 Cint,
                 (Ptr{StanModelStruct},),
                 sm)
end

function param_unconstrain!(sm::StanModel, q)
    ccall(Libc.Libdl.dlsym(sm.lib, "param_unconstrain"),
          Cvoid,
          (Ptr{StanModelStruct}, Cint, Ref{Cdouble}, Cint, Ref{Cdouble}),
          sm.stanmodel, sm.K, q, sm.dims, sm.unconstrained_parameters)
end

function destroy(sm::StanModel)
    ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
          Cvoid,
          (Ptr{StanModelStruct},),
          sm.stanmodel)
end

end
