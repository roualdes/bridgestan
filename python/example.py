import bridgestan as bs
import numpy as np

stan = "../test_models/bernoulli/bernoulli.stan"
data = "../test_models/bernoulli/bernoulli.data.json"
model = bs.StanModel.from_stan_file(stan, data)

print(f"This model's name is {model.name()}.")
print(f"It has {model.param_num()} parameters.")

x = np.random.random(model.param_unc_num())
q = np.log(x / (1 - x))  # unconstrained scale
lp, grad = model.log_density_gradient(q, jacobian=False)
print(f"log_density and gradient of Bernoulli model: {(lp, grad)}")
