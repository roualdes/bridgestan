import sys
import os
import numpy as np

sys.path.append(os.getcwd() + '/..')

import PythonClient as pbs

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

def bernoulli(y, p):
    return y * np.log(p) + (1 - y) * np.log(1 - p)

def test_bernoulli():

    bernoulli_lib = "/Users/ez/bridgestan/stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "/Users/ez/bridgestan/stan/bernoulli/bernoulli.data.json"

    smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 1000

    for _ in range(R):
        x = np.random.uniform(size = smb.D)
        q = np.log(x / (1 - x))     # unconstrained scale
        smb.logdensity_grad(q, 1, 0)

        assert np.isclose(smb.logdensity[0], sum(bernoulli(y, x)))


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

def gaussian(x):
    return -0.5 * np.dot(x, x)

def grad_gaussian(x):
    return -x

def test_gaussian():

    multi_lib = "/Users/ez/bridgestan/stan/multi/multi_model.so"
    multi_data = "/Users/ez/bridgestan/stan/multi/multi.data.json"

    smm = pbs.PyBridgeStan(multi_lib, multi_data)
    R = 1000

    for _ in range(R):
        x = np.random.normal(size = smm.D)
        smm.logdensity_grad(x)

        assert np.isclose(smm.logdensity[0], gaussian(x))
        assert np.allclose(smm.grad, grad_gaussian(x))
