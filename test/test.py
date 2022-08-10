import sys
import os
import numpy as np

sys.path.append(os.getcwd() + '/..')

import PythonClient as pbs

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

def bernoulli(y, p):
    return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))

def test_bernoulli():

    bernoulli_lib = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"

    smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 1000

    for _ in range(R):
        x = np.random.uniform(size = smb.dims())
        q = np.log(x / (1 - x)) # unconstrained scale
        logdensity, grad = smb.log_density_gradient(q, 1, 0)

        assert np.isclose(logdensity, bernoulli(y, x))
        assert np.isclose(smb.param_constrain(q), x)

# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

def gaussian(x):
    return -0.5 * np.dot(x, x)

def grad_gaussian(x):
    return -x

def test_gaussian():

    multi_lib = "../stan/multi/multi_model.so"
    multi_data = "../stan/multi/multi.data.json"

    smm = pbs.PyBridgeStan(multi_lib, multi_data)
    R = 1000

    for _ in range(R):
        x = np.random.normal(size = smm.dims())
        logdensity, grad = smm.log_density_gradient(x)

        assert np.isclose(logdensity, gaussian(x))
        assert np.allclose(grad, grad_gaussian(x))
