import sys
import os
import numpy as np

sys.path.append(os.getcwd() + '/..')

import PythonClient as pbs
import MCMC as mcmc


# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli_model.so

def test_bernoulli():

    def _bernoulli(y, p):
        return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))

    bernoulli_lib = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"

    smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 1000

    for _ in range(R):
        x = np.random.uniform(size = smb.dims())
        q = np.log(x / (1 - x)) # unconstrained scale
        logdensity, grad = smb.log_density_gradient(q, 1, 0)

        assert np.isclose(logdensity, _bernoulli(y, x))
        assert np.isclose(smb.param_constrain(q), x)

# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi_model.so

def test_multi():

    def _multi(x):
        return -0.5 * np.dot(x, x)

    def _grad_multi(x):
        return -x

    multi_lib = "../stan/multi/multi_model.so"
    multi_data = "../stan/multi/multi.data.json"

    smm = pbs.PyBridgeStan(multi_lib, multi_data)
    R = 1000

    for _ in range(R):
        x = np.random.normal(size = smm.dims())
        logdensity, grad = smm.log_density_gradient(x)

        assert np.isclose(logdensity, _multi(x))
        assert np.allclose(grad, _grad_multi(x))


# Guassian with positive constrained standard deviation
# CMDSTAN=/path/to/cmdstan/ make stan/gaussian/gaussian_model.so

def test_gaussian():

    lib = "../stan/gaussian/gaussian_model.so"
    data = "../stan/gaussian/gaussian.data.json"

    model = pbs.PyBridgeStan(lib, data)
    np.random.seed(2)
    N = 10

    sampler = mcmc.HMCDiag(model, stepsize = 0.01, steps = 10)
    theta = np.empty([N, model.dims()])

    for m in range(N):
        theta[m, :], _ = sampler.sample()

    constrained_theta = np.empty([N, model.param_num()])
    for m in range(N):
        constrained_theta[m, :] = model.param_constrain(theta[m])

    assert np.allclose(constrained_theta[:, 0], theta[:, 0])
    assert np.allclose(constrained_theta[:, 1], np.exp(theta[:, 1]))


# Full rank Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/fr_gaussian/fr_gaussian_model.so

def test_fr_gaussian():

    def _covariance_constrain_transform(v, D):
        L = np.zeros([D, D])
        idxL = np.tril_indices(D)
        L[idxL] = v
        idxD = np.diag_indices(D)
        L[idxD] = np.exp(L[idxD])
        return np.matmul(L, L.T)


    lib = "../stan/fr_gaussian/fr_gaussian_model.so"
    data = "../stan/fr_gaussian/fr_gaussian.data.json"
    model = pbs.PyBridgeStan(lib, data)

    D = 4
    N = 1
    np.random.seed(204)
    sampler = mcmc.HMCDiag(model, stepsize=0.01, steps=10)

    theta = np.empty([N, model.dims()])
    for m in range(N):
        theta[m, :], _ = sampler.sample()

    # Ad hoc scale down of parameters to prevent over-underflow
    # This is ok since we are interested only in testing transformation
    theta /= 10.

    constrained_theta = np.empty([N, model.param_num()])
    for m in range(N):
        constrained_theta[m, :] = model.param_constrain(theta[m])

    a = theta[-1][D:]
    b = constrained_theta[-1][D:]

    cov = _covariance_constrain_transform(a, D)
    B = b.reshape(D, D)
    assert np.allclose(cov, B)
