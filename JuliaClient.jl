module JuliaBridgeStan

mutable struct StanModelSymbol
    lib::Ref{Nothing}
    create::Ref{Nothing}
    numparams::Ref{Nothing}
    logdensity::Ref{Nothing}
     free::Ref{Nothing}
    function StanModelSymbol(path::String)
        lib = Libc.Libdl.dlopen(path)
        # TODO probably don't need stanmodel_ prefixing each of these
        crsym = Libc.Libdl.dlsym(lib, :stanmodel_create)
        npsym = Libc.Libdl.dlsym(lib, :stanmodel_get_num_unc_params)
        ldsym = Libc.Libdl.dlsym(lib, :stanmodel_log_density)
        frsym = Libc.Libdl.dlsym(lib, :stanmodel_destroy) # TODO rename free
        return new(lib, crsym, npsym, ldsym, frsym)
        # TODO in my head this should be close when out of scope...
        # but I can't get it to work
        # function f(sms)
        #     Libc.Libdl.dlclose(sms.lib)
        # end
        # finalizer(f, sms)
    end
end

mutable struct StanModelStruct
end

mutable struct StanModel
    smsym::StanModelSymbol
    stanmodel::Ptr{StanModelStruct}
    D::Int
    data::String
    seed::UInt32
    logdensity::Vector{Float64}
    grad::Vector{Float64}
    function StanModel(stanlib_::String, datafile_::String, seed_ = 204)
        sms = StanModelSymbol(stanlib_)
        seed = convert(UInt32, seed_)
        stanmodel = ccall(sms.create, Ptr{StanModelStruct},
                          (Cstring, UInt32),
                          datafile_, seed)
        D = ccall(sms.numparams, Cint, (Ptr{Cvoid},), stanmodel)
        sm = new(sms, stanmodel, D, datafile_, seed, zeros(1), zeros(D))
        function f(sm)
            ccall(sm.smsym.free, Cvoid, (Ptr{Cvoid},), sm.stanmodel)
        end
        finalizer(f, sm)
    end
end

function numparams(sm::StanModel)
    return ccall(sm.smsym.numparams, Cint, (Ptr{Cvoid},), sm.stanmodel)
end

function logdensity_grad!(sm::StanModel, q; propto = 1, jacobian = 1)
    ccall(sm.smsym.logdensity, Cvoid,
          (Ptr{StanModelStruct}, Ref{Cdouble},
           Cint, Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
          sm.stanmodel, q, sm.D, sm.logdensity, sm.grad, propto, jacobian)
end

export
    StanModel,
    numparams,
    logdensity_grad!

end
