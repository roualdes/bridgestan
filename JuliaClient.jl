module JuliaBridgeStan

mutable struct StanModelStruct
end

mutable struct StanModel
    stanmodel::Ptr{StanModelStruct}
    D::Int
    data::String
    seed::UInt32
    logdensity::Vector{Float64}
    grad::Vector{Float64}
    function StanModel(stanlib_::Ptr{Cvoid}, datafile_::String, seed_ = 204)
        seed = convert(UInt32, seed_)

        stanmodel = ccall(@dlsym("create", stanlib_),
                          Ptr{StanModelStruct},
                          (Cstring, UInt32),
                          datafile_, seed)

        D = ccall(@dlsym("get_num_unc_params", stanlib_),
                  Cint,
                  (Ptr{Cvoid},),
                  stanmodel)

        sm = new(stanlib_, stanmodel, D, datafile_, seed, zeros(1), zeros(D))

        function f(sm)
            ccall(@dlsym("destroy", sm.lib),
                  Cvoid,
                  (Ptr{Cvoid},),
                  sm.stanmodel)
        end

        finalizer(f, sm)
    end
end

function numparams(sm::StanModel, lib_)
    return ccall(@dlsym("get_num_unc_params", sm.lib),
                 Cint,
                 (Ptr{Cvoid},),
                 sm.stanmodel)
end

function logdensity_grad!(sm::StanModel, q; propto = 1, jacobian = 1)
    ccall(@dlsym("log_density", sm.lib),
          Cvoid,
          (Ptr{StanModelStruct}, Ref{Cdouble}, Cint,
           Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
          sm.stanmodel, q, sm.D, sm.logdensity, sm.grad, propto, jacobian)
end

export
    StanModel,
    numparams,
    logdensity_grad!,
    dlsym

end
