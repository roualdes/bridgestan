using BridgeStan

const BS = BridgeStan

# These paths are what they are because this example lives in a subfolder
# of the BridgeStan repository. If you're running this on your own, you
# will most likely want to delete the next line (to have BridgeStan
# download its sources for you) and change the paths on the following two
BS.set_bridgestan_path!("../")

bernoulli_stan = joinpath(@__DIR__, "../test_models/bernoulli/bernoulli.stan")
bernoulli_data = joinpath(@__DIR__, "../test_models/bernoulli/bernoulli.data.json")

smb = BS.StanModel(stan_file = bernoulli_stan, data = bernoulli_data);

println("This model's name is $(BS.name(smb)).")
println("It has $(BS.param_num(smb)) parameters.")

x = rand(BS.param_unc_num(smb));
q = @. log(x / (1 - x)); # unconstrained scale

lp, grad = BS.log_density_gradient(smb, q, jacobian = false)

println("log_density and gradient of Bernoulli model: $((lp, grad))")
