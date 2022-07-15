import PythonClient as pbs
import MCMC as mcmc
import numpy as np

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = "./stan/bernoulli/bernoulli_model.so"
bernoulli_data = "./stan/bernoulli/bernoulli.data.json"

smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)
x = np.random.uniform(size = smb.dims())
q = np.log(x / (1 - x))         # unconstrained scale

print()
print("log_density and gradient of Bernoulli model:")
print(smb.log_density_gradient(q, propto = 1, jacobian = 0))
print()

## del smb


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = "./stan/multi/multi_model.so"
multi_data = "./stan/multi/multi.data.json"

smm = pbs.PyBridgeStan(multi_lib, multi_data)
x = np.random.uniform(size = smm.dims())

print("log_density and gradient of Multivariate Gaussian model:")
print(smm.log_density_gradient(x))
print()

## del smm


# HMC

model = pbs.PyBridgeStan(multi_lib, multi_data, 1234)

stepsize = 0.25
steps = 10
metric_diag = np.ones(model.dims())
sampler = mcmc.HMCDiag(model, stepsize=stepsize, steps=steps, metric_diag=metric_diag)


M = 10000
theta = np.empty([M, model.dims()])
for m in range(M):
    theta[m, :], _ = sampler.sample()


print(f"Empirical mean: {theta.mean(0)}")
print(f"Empirical std: {theta.std(0)}")
