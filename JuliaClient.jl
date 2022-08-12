module JBS

export
    StanModel,
    log_density_gradient!,
    param_num,
    param_constrain,
    destroy

mutable struct StanModelStruct
end

mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    dims::Int
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

        dims = ccall(Libc.Libdl.dlsym(stanlib_, "get_num_unc_params"),
                     Cint,
                     (Ptr{Cvoid},),
                     stanmodel)

        K = ccall(Libc.Libdl.dlsym(stanlib_, "param_num"),
                  Cint,
                  (Ptr{Cvoid},),
                  stanmodel)

        sm = new(stanlib_, stanmodel, dims, datafile_, seed, K, zeros(K), zeros(1), zeros(dims))

        function f(sm)
            ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
                  Cvoid,
                  (Ptr{Cvoid},),
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

function param_num(sm::StanModel)
    return ccall(Libc.Libdl.dlsym(sm.lib, "param_num"),
                 Cint,
                 (Ptr{Cvoid},),
                 sm)
end

function param_constrain(sm::StanModel, q)
    ccall(Libc.Libdl.dlsym(sm.lib, "param_constrain"),
          Cvoid,
          (Ptr{StanModelStruct}, Cint, Ref{Cdouble}, Cint, Ref{Cdouble}),
          sm.stanmodel, sm.dims, q, sm.K, sm.constrained_parameters)
end

function destroy(sm::StanModel)
    ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
          Cvoid,
          (Ptr{StanModelStruct},),
          sm.stanmodel)
end

end
