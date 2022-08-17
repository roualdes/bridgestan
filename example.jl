include("./JuliaClient.jl")

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = joinpath(@__DIR__, "stan/bernoulli/bernoulli_model.so")
bernoulli_data = joinpath(@__DIR__, "stan/bernoulli/bernoulli.data.json")
blib = Libc.Libdl.dlopen(bernoulli_lib)

smb = JBS.StanModel(blib, bernoulli_data);
x = rand(smb.dims);
q = @. log(x / (1 - x));        # unconstrained scale

JBS.log_density_gradient!(smb, q, jacobian = 0)

println()
println("log_density and gradient of Bernoulli model:")
println((smb.log_density, smb.gradient))
println()

## JBS.destroy(smb)


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = joinpath(@__DIR__, "stan/multi/multi_model.so")
multi_data = joinpath(@__DIR__, "stan/multi/multi.data.json")
mlib = Libc.Libdl.dlopen(multi_lib)

smm = JBS.StanModel(mlib, multi_data)
x = randn(smm.dims);

JBS.log_density_gradient!(smm, x)

println("log_density and gradient of Multivariate Gaussian model:")
println((smm.log_density, smm.gradient))
println()

## JBS.destroy(smm)


# HMC
include("./MCMC.jl")
using Statistics

model = JBS.StanModel(mlib, multi_data);

stepsize = 0.25
steps = 10
hmcd = HMCDiag(model, stepsize, steps);

M = 10_000
theta = zeros(M, model.dims)
for m in 1:M
    theta[m, :] .= sample(hmcd)
end

println("Empirical mean: $(round.(mean(theta, dims = 1), digits = 3))")
println("Empirical std: $(round.(std(theta, dims = 1), digits = 3))")
