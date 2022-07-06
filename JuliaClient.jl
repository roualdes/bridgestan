module JBS

export
    StanModel,
    log_density_grad!,
    free

mutable struct StanModelStruct
end

mutable struct StanModel
    lib::Ptr{Nothing}
    stanmodel::Ptr{StanModelStruct}
    dims::Int
    data::String
    seed::UInt32
    log_density::Vector{Float64}
    grad::Vector{Float64}
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

        sm = new(stanlib_, stanmodel, dims, datafile_, seed, zeros(1), zeros(dims))

        function f(sm)
            ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
                  Cvoid,
                  (Ptr{Cvoid},),
                  sm.stanmodel)
        end

        finalizer(f, sm)
    end
end

function log_density_grad!(sm::StanModel, q; propto = 1, jacobian = 1)
    ccall(Libc.Libdl.dlsym(sm.lib, "log_density"),
          Cvoid,
          (Ptr{StanModelStruct}, Cint, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
          sm.stanmodel, sm.dims, q, sm.log_density, sm.grad, propto, jacobian)
end

function free(sm::StanModel)
    ccall(Libc.Libdl.dlsym(sm.lib, "destroy"),
          Cvoid,
          (Ptr{StanModelStruct},),
          sm.stanmodel)
end

end
