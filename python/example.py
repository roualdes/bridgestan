import numpy as np

import bridgestan as bs

# These paths are what they are because this example lives in a subfolder
# of the BridgeStan repository. If you're running this on your own, you
# will most likely want to delete the next line (to have BridgeStan
# download its sources for you) and change the paths on the following two
bs.set_bridgestan_path("..")

stan = "../test_models/bernoulli/bernoulli.stan"
data = "../test_models/bernoulli/bernoulli.data.json"
model = bs.StanModel.from_stan_file(stan, data)

print(f"This model's name is {model.name()}.")
print(f"It has {model.param_num()} parameters.")

x = np.random.random(model.param_unc_num())
q = np.log(x / (1 - x))  # unconstrained scale
lp, grad = model.log_density_gradient(q, jacobian=False)
print(f"log_density and gradient of Bernoulli model: {(lp, grad)}")
