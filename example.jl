include("./JuliaClient.jl")

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = joinpath(@__DIR__, "stan/bernoulli/bernoulli_model.so")
bernoulli_data = joinpath(@__DIR__, "stan/bernoulli/bernoulli.data.json")
blib = Libc.Libdl.dlopen(bernoulli_lib)

smb = JBS.StanModel(blib, bernoulli_data);

x = rand(smb.dims);
q = @. log(x / (1 - x));                  # unconstrained scale

JBS.log_density_grad!(smb, q, jacobian = 0)

smb.log_density
smb.grad

## JBS.free(smb)


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = joinpath(@__DIR__, "stan/multi/multi_model.so")
multi_data = joinpath(@__DIR__, "stan/multi/multi.data.json")
mlib = Libc.Libdl.dlopen(multi_lib)

smm = JBS.StanModel(mlib, multi_data)

x = randn(smm.dims);

JBS.log_density_grad!(smm, x)

smm.log_density
smm.grad

## JBS.free(smm)
