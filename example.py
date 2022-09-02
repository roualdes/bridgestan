import bridgestan as bs
import MCMC as mcmc
import numpy as np

# small shim to add dims(), required by MCMC impl
class BridgeDims(bs.Bridge):
    def dims(self) -> int:
        return self.param_unc_num()

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

bernoulli_lib = "./stan/bernoulli/bernoulli_model.so"
bernoulli_data = "./stan/bernoulli/bernoulli.data.json"

smb = BridgeDims(bernoulli_lib, bernoulli_data)
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

smm = BridgeDims(multi_lib, multi_data)
x = np.random.uniform(size = smm.param_num())

print("log_density and gradient of Multivariate Gaussian model:")
print(smm.log_density_gradient(x))
print()

## del smm


# HMC

model = BridgeDims(multi_lib, multi_data, seed=1234)

stepsize = 0.25
steps = 10
metric_diag = np.ones(model.dims())
sampler = mcmc.HMCDiag(model, stepsize=stepsize, steps=steps, metric_diag=metric_diag)


M = 10000
theta = np.empty([M, model.dims()])
for m in range(M):
    theta[m, :] = sampler.sample()


print(f"Empirical mean: {np.round(theta.mean(0), 3)}")
print(f"Empirical std: {np.round(theta.std(0), 3)}")
