include("./JuliaClient.jl")

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

mutable struct StanModelStruct
end

mutable struct StanModel
    D::Int64
end

const bernoulli_lib = joinpath(@__DIR__, "stan/bernoulli/bernoulli_model.so")
bernoulli_data = joinpath(@__DIR__, "stan/bernoulli/bernoulli.data.json")
# const blib = Libc.Libdl.dlopen(bernoulli_lib)

function create_(clib, data_)
    Libc.Libdl.dlopen(clib) do lib
        create_ = Libc.Libdl.dlsym(lib, :create; throw_error = false)
        println("made it here")
        ccall(create_,
              Cvoid,
              (Cstring, UInt32),
              data_, 204)
    end
end

create_(bernoulli_lib, bernoulli_data)

function numparams(clib)
    D = zero(Int32)
    Libc.Libdl.dlopen(clib) do lib
        numparams_ = Libc.Libdl.dlsym(lib, :get_num_unc_params; throw_error = false)
        D = ccall((:get_num_unc_params, bernoulli_lib), Cint, ())
    end
    return D
end

D = numparams(smb, blib)

x = rand(D);
q = @. log(x / (1 - x));                  # unconstrained scale
logdensity = zeros(1);
grad = zeros(D);

function logdensity_(clib, q)
    logdensity = zeros(1)
    D = length(q)
    grad = zeros(D)
    Libc.Libdl.dlopen(clib) do lib
        log_density_ = Libc.Libdl.dlsym(lib, :log_density; throw_error = false)
        ccall(log_density,
              Cvoid,
              (Cint, Ref{Cdouble},  Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
              D, q, logdensity, grad, 1, 0)

    end
    return logdensity, grad
end

logdensity_(smb, blib, q)

function destroy_(clib)
    Libc.Libdl.dlopen(clib) do lib
        destroy_ = Libc.Libdl.dlsym(lib, :destroy; throw_error = false)
        ccall(destroy_, Cvoid, ())
    end
end

destroy_(smb, blib)








# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

const multi_lib = joinpath(@__DIR__, "stan/multi/multi_model.so")
multi_data = joinpath(@__DIR__, "stan/multi/multi.data.json")


smm = ccall((:create, multi_lib),
            Ptr{StanModelStruct},
            (Cstring, UInt32),
            multi_data, 204)

D = ccall((:get_num_unc_params, multi_lib),
          Cint,
          (Ptr{Cvoid},),
          smm)

x = randn(D);
logdensity = zeros(1);
grad = zeros(D);

ccall((:log_density, multi_lib),
          Cvoid,
      (Ptr{StanModelStruct}, Ref{Cdouble}, Cint,
       Ref{Cdouble}, Ref{Cdouble}, Cint, Cint),
      smm, x, D, logdensity, grad, 1, 0)

ccall((:destroy, multi_lib),
      Cvoid,
      (Ptr{StanModelStruct},),
      smm)



smm = JuliaBridgeStan.StanModel(mlib, multi_data);

x = randn(smm.D);

JuliaBridgeStan.logdensity_grad!(smm, x)

smm.logdensity
smm.grad

function gaussian(x)
    return -0.5 * x' * x
end


gaussian(x)

using ReverseDiff

[grad ReverseDiff.gradient(gaussian, x)]
