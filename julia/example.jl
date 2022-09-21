using BridgeStan

const BS = BridgeStan

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make test_models/bernoulli/bernoulli

bernoulli_lib = joinpath(@__DIR__, "../test_models/bernoulli/bernoulli_model.so")
bernoulli_data = joinpath(@__DIR__, "../test_models/bernoulli/bernoulli.data.json")

smb = BS.StanModel(bernoulli_lib, bernoulli_data);
x = rand(BS.param_unc_num(smb));
q = @. log(x / (1 - x));        # unconstrained scale

lp, grad = BS.log_density_gradient(smb, q, jacobian = 0)

println()
println("log_density and gradient of Bernoulli model:")
println((lp, grad))
println()



# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make test_models/multi/multi

multi_lib = joinpath(@__DIR__, "../test_models/multi/multi_model.so")
multi_data = joinpath(@__DIR__, "../test_models/multi/multi.data.json")

smm = BS.StanModel(multi_lib, multi_data)
x = randn(BS.param_unc_num(smm));

lp, grad = BS.log_density_gradient(smm, x)

println("log_density and gradient of Multivariate Gaussian model:")
println((lp, grad))
println()


# HMC
include("./MCMC.jl")
using Statistics

model = BS.StanModel(multi_lib, multi_data);

stepsize = 0.25
steps = 10
hmcd = HMCDiag(model, stepsize, steps);

M = 10_000
theta = zeros(M, BS.param_unc_num(model))
for m = 1:M
    theta[m, :] .= sample(hmcd)
end

println("Empirical mean: $(round.(mean(theta, dims = 1), digits = 3))")
println("Empirical std: $(round.(std(theta, dims = 1), digits = 3))")
