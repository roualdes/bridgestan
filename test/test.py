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

        np.testing.assert_allclose(logdensity, _bernoulli(y, x))

        constrained_theta = smb.param_constrain(q)
        np.testing.assert_allclose(constrained_theta, x)

        np.testing.assert_allclose(smb.param_unconstrain(constrained_theta), q)

    np.testing.assert_allclose(smb.dims(), 1)
    np.testing.assert_allclose(smb.K(), 1)


def test_out_behavior():

    bernoulli_lib = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"

    smb = pbs.PyBridgeStan(bernoulli_lib, bernoulli_data)

    grads = []
    for _ in range(2):
        x = np.random.uniform(size = smb.dims())
        q = np.log(x / (1 - x)) # unconstrained scale
        _, grad = smb.log_density_gradient(q, 1, 0)
        grads.append(grad)

    # default behavior is fresh array
    assert grads[0] is not grads[1]

    grads = []
    grad_out = np.zeros(shape = smb.dims())
    for _ in range(2):
        x = np.random.uniform(size = smb.dims())
        q = np.log(x / (1 - x)) # unconstrained scale
        _, grad = smb.log_density_gradient(q, 1, 0, grad_out=grad_out)
        grads.append(grad)

    # out parameter is modified and reference is returned
    assert grads[0] is grads[1]
    assert grads[0] is grad_out
    assert grads[1] is grad_out
    np.testing.assert_allclose(grads[0], grads[1])

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

        np.testing.assert_allclose(logdensity, _multi(x))
        np.testing.assert_allclose(grad, _grad_multi(x))

# Guassian with positive constrained standard deviation
# CMDSTAN=/path/to/cmdstan/ make stan/gaussian/gaussian_model.so

def test_gaussian():

    lib = "../stan/gaussian/gaussian_model.so"
    data = "../stan/gaussian/gaussian.data.json"

    model = pbs.PyBridgeStan(lib, data)
    N = 10

    sampler = mcmc.HMCDiag(model, stepsize = 0.01, steps = 10)
    theta = np.empty([N, model.dims()])

    for n in range(N):
        theta[n, :] = sampler.sample()

    constrained_theta = np.empty([N, model.param_num()])
    for n in range(N):
        constrained_theta[n, :] = model.param_constrain(theta[n])

    np.testing.assert_allclose(constrained_theta[:, 0], theta[:, 0])
    np.testing.assert_allclose(constrained_theta[:, 1], np.exp(theta[:, 1]))


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
    sampler = mcmc.HMCDiag(model, stepsize=0.01, steps=10)

    theta = np.empty([N, model.dims()])
    for n in range(N):
        theta[n, :] = sampler.sample()

    # Ad hoc scale down of parameters to prevent over-underflow
    # This is ok since we are interested only in testing transformation
    theta /= 10.

    constrained_theta = np.empty([N, model.param_num()])
    for n in range(N):
        constrained_theta[n, :] = model.param_constrain(theta[n])

    a = theta[-1][D:]
    b = constrained_theta[-1][D:]

    cov = _covariance_constrain_transform(a, D)
    B = b.reshape(D, D)
    np.testing.assert_allclose(cov, B)

    np.testing.assert_allclose(model.param_unconstrain(constrained_theta[-1]), theta[-1])

    np.testing.assert_allclose(model.dims(), 14)
    np.testing.assert_allclose(model.K(), 20)

if __name__ == "__main__":
    print("test out behavior")
    test_out_behavior()
    print("test multi")
    test_multi()
    print("test bernoulli")
    test_bernoulli()
    print("test gaussian")
    test_gaussian()
    print("test fr_gaussian")
    test_fr_gaussian()
    print("\nIf no errors were reported, all tests passed.")
