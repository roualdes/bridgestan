import sys
import os
import json
import numpy as np

sys.path.append(os.getcwd() + '/..')

import bridgestan as bs

# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli_model.so

def test_out_behavior():
    bernoulli_lib = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"

    smb = bs.Bridge(bernoulli_lib, bernoulli_data)

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
        _, grad = smb.log_density_gradient(q, 1, 0, grad=grad_out)
        grads.append(grad)

    # out parameter is modified and reference is returned
    assert grads[0] is grads[1]
    assert grads[0] is grad_out
    assert grads[1] is grad_out
    np.testing.assert_allclose(grads[0], grads[1])



# Bernoulli
# CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli_model.so

def test_bernoulli():
    def _bernoulli(y, p):
        return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))
    bernoulli_lib = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"
    smb = bs.Bridge(bernoulli_lib, bernoulli_data)
    np.testing.assert_allclose(smb.dims(), 1)
    np.testing.assert_allclose(smb.K(), 1)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 2
    for _ in range(R):
        x = np.random.uniform(size = smb.dims())
        q = np.log(x / (1 - x)) # unconstrained scale
        logdensity, grad = smb.log_density_gradient(q, 1, 0)
        np.testing.assert_allclose(logdensity, _bernoulli(y, x))
        constrained_theta = smb.param_constrain(q, 0, 0)
        np.testing.assert_allclose(constrained_theta, x)
        np.testing.assert_allclose(smb.param_unconstrain(constrained_theta), q)


# Multivariate Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/multi/multi_model.so

def test_multi():

    def _multi(x):
        return -0.5 * np.dot(x, x)

    def _grad_multi(x):
        return -x

    multi_lib = "../stan/multi/multi_model.so"
    multi_data = "../stan/multi/multi.data.json"

    smm = bs.Bridge(multi_lib, multi_data)
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

    model = bs.Bridge(lib, data)
    N = 10

    theta = np.array([0.2, 1.9])
    theta_unc = np.array([0.2, np.log(1.9)])

    theta_test = model.param_constrain(theta_unc, 0, 0)
    np.testing.assert_allclose(theta, theta_test)

    theta_unc_test = model.param_unconstrain(theta)
    np.testing.assert_allclose(theta_unc, theta_unc_test)

    theta_json = "{\"mu\": 0.2, \"sigma\": 1.9}"
    theta_unc_j_test = model.param_unconstrain_json(theta_json)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test)

# Full rank Gaussian
# CMDSTAN=/path/to/cmdstan/ make stan/fr_gaussian/fr_gaussian_model.so

def test_fr_gaussian():
    def cov_constrain(v, D):
        L = np.zeros([D, D])
        idxL = np.tril_indices(D)
        L[idxL] = v
        idxD = np.diag_indices(D)
        L[idxD] = np.exp(L[idxD])
        return np.matmul(L, L.T)

    lib = "../stan/fr_gaussian/fr_gaussian_model.so"
    data = "../stan/fr_gaussian/fr_gaussian.data.json"
    model = bs.Bridge(lib, data)

    size = 16
    unc_size = 10
    np.testing.assert_allclose(model.K(), size)
    np.testing.assert_allclose(model.dims(), unc_size)

    D = 4
    a = np.random.normal(size=unc_size)
    b = model.param_constrain(a, 0, 0);

    B = b.reshape(D, D)
    B_expected = cov_constrain(a, D)
    np.testing.assert_allclose(B_expected, B)

    c = model.param_unconstrain(b)
    np.testing.assert_allclose(a, c)

def test_simple():
    lib = "../stan/simple/simple_model.so"
    data = "../stan/simple/simple.data.json"
    model = bs.Bridge(lib, data)

    D = 5
    y = np.random.uniform(size = D)
    lp, grad, hess = model.log_density_hessian(y)
    np.testing.assert_allclose(-y, grad)
    np.testing.assert_allclose(-np.identity(D), hess)

if __name__ == "__main__":
    print("")
    print("TESTING BrigeStan Python API")
    print("------------------------------------------------------------")
    print("running test: out behavior")
    test_out_behavior()
    print("running test: bernoulli")
    test_bernoulli()
    print("running test: multi")
    test_multi()
    print("running test: gaussian")
    test_gaussian()
    print("running test: fr_gaussian")
    test_fr_gaussian()
    print("running test: simple")
    test_simple()
    print("------------------------------------------------------------")
    print("If no errors were reported, all tests passed.")
