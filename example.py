import PythonClient as pbs
import MCMC as mcmc
import numpy as np

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = "/Users/ez/bridgestan/stan/bernoulli/bernoulli_model.so"
bernoulli_data = "/Users/ez/bridgestan/stan/bernoulli/bernoulli.data.json"

smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)

x = np.random.uniform(size = smb.dims)
q = np.log(x / (1 - x))         # unconstrained scale

smb.log_density_grad(q, 1, 0)

smb.log_density
smb.grad

## del smb


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = "/Users/ez/bridgestan/stan/multi/multi_model.so"
multi_data = "/Users/ez/bridgestan/stan/multi/multi.data.json"

smm = pbs.PyBridgeStan(multi_lib, multi_data)

x = np.random.uniform(size = smm.dims)

smm.log_density_grad(x)

smm.log_density
smm.grad

## del smm


# HMC

model = pbs.PyBridgeStan(multi_lib, multi_data, 1234)

stepsize = 0.25
steps = 10
metric_diag = [1] * model.dims()
sampler = mcmc.HMCDiag(model, stepsize=stepsize, steps=steps, metric_diag=metric_diag)


M = 10000
theta = np.empty([M, model.dims()])
for m in range(M):
    theta[m, :], _ = sampler.sample()
