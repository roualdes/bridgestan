include("./JuliaClient.jl")

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = joinpath(@__DIR__, "stan/bernoulli/bernoulli_model.so")
bernoulli_data = joinpath(@__DIR__, "stan/bernoulli/bernoulli.data.json")

smb = JuliaBridgeStan.StanModel(bernoulli_lib, bernoulli_data);

x = rand(smb.D);
q = @. log(x / (1 - x));                  # unconstrained scale

JuliaBridgeStan.logdensity_grad!(smb, q)

smb.logdensity
smb.grad

# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = joinpath(@__DIR__, "stan/multi/multi_model.so")
multi_data = joinpath(@__DIR__, "stan/multi/multi.data.json")

smm = JuliaBridgeStan.StanModel(multi_lib, multi_data);

x = randn(smm.D);

JuliaBridgeStan.logdensity_grad!(smm, x)

smm.logdensity
smm.grad
