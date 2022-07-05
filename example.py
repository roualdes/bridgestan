import PythonClient as pbs
import numpy as np

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = "/Users/ez/bridgestan/stan/bernoulli/bernoulli_model.so"
bernoulli_data = "/Users/ez/bridgestan/stan/bernoulli/bernoulli.data.json"

smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)

x = np.random.uniform(size = smb.D)
q = np.log(x / (1 - x))         # unconstrained scale

smb.logdensity_grad(q, 1, 0)

smb.logdensity
smb.grad

## del smb


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

multi_lib = "/Users/ez/bridgestan/stan/multi/multi_model.so"
multi_data = "/Users/ez/bridgestan/stan/multi/multi.data.json"

smm = pbs.PyBridgeStan(multi_lib, multi_data)

x = np.random.uniform(size = smm.D)

smm.logdensity_grad(x)

smm.logdensity
smm.grad

## del smm
