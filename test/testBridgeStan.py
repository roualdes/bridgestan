import sys
import os
import json
import numpy as np

sys.path.append(os.getcwd() + '/..')

import bridgestan as bs

def test_constructor():
    std_so = "../stan/stdnormal/stdnormal_model.so"

    # implicit destructor tests in success and fail cases

    # test empty data
    b1 = bs.Bridge(std_so)
    np.testing.assert_allclose(bool(b1), True)

    # test load data
    bernoulli_so = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"
    b2 = bs.Bridge(bernoulli_so, bernoulli_data)
    np.testing.assert_allclose(bool(b2), True)

    # test missing so file
    with np.testing.assert_raises(FileNotFoundError):
        b3 = bs.Bridge("nope, not going to find it")

    # test missing data file
    with np.testing.assert_raises(FileNotFoundError):
        b3 = bs.Bridge(bernoulli_so, "nope, not going to find it")

def test_name():
    std_so = "../stan/stdnormal/stdnormal_model.so"
    b = bs.Bridge(std_so)
    np.testing.assert_equal("stdnormal_model", b.name())

def test_param_num():
    full_so = "../stan/full/full_model.so"
    b = bs.Bridge(full_so)
    np.testing.assert_equal(1, b.param_num())
    np.testing.assert_equal(1, b.param_num(include_tp = False))
    np.testing.assert_equal(1, b.param_num(include_gq = False))
    np.testing.assert_equal(1, b.param_num(include_tp = False, include_gq = False))
    np.testing.assert_equal(3, b.param_num(include_gq = True))
    np.testing.assert_equal(3, b.param_num(include_tp = False, include_gq = True))
    np.testing.assert_equal(2, b.param_num(include_tp = True))
    np.testing.assert_equal(2, b.param_num(include_tp = True, include_gq = False))
    np.testing.assert_equal(4, b.param_num(include_tp = True, include_gq = True));

def test_param_unc_num():
    simplex_so = "../stan/simplex/simplex_model.so"
    b = bs.Bridge(simplex_so)
    np.testing.assert_equal(5, b.param_num())
    np.testing.assert_equal(4, b.param_unc_num())

def test_param_names():
    matrix_so = "../stan/matrix/matrix_model.so"
    b = bs.Bridge(matrix_so)
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2'], b.param_names())
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2'], b.param_names(include_tp = False))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2'], b.param_names(include_gq = False))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2'], b.param_names(include_tp = False, include_gq = False))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2', 'B.1.1', 'B.2.1', 'B.3.1', 'B.1.2', 'B.2.2', 'B.3.2'],
                            b.param_names(include_tp=True))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2', 'B.1.1', 'B.2.1', 'B.3.1', 'B.1.2', 'B.2.2', 'B.3.2'],
                            b.param_names(include_tp=True, include_gq = False))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2', 'c'],
                                      b.param_names(include_gq=True))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2', 'c'],
                                      b.param_names(include_tp=False, include_gq=True))
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2', 'B.1.1', 'B.2.1', 'B.3.1', 'B.1.2', 'B.2.2', 'B.3.2', 'c'],
                            b.param_names(include_tp=True, include_gq=True))

def test_param_unc_names():
    matrix_so = "../stan/matrix/matrix_model.so"
    b1 = bs.Bridge(matrix_so)
    np.testing.assert_array_equal(['A.1.1', 'A.2.1', 'A.3.1', 'A.1.2', 'A.2.2', 'A.3.2'], b1.param_unc_names())

    simplex_so = "../stan/simplex/simplex_model.so"
    b2 = bs.Bridge(simplex_so)
    np.testing.assert_array_equal(['theta.1', 'theta.2', 'theta.3', 'theta.4'], b2.param_unc_names())

def cov_constrain(v, D):
    L = np.zeros([D, D])
    idxL = np.tril_indices(D)
    L[idxL] = v
    idxD = np.diag_indices(D)
    L[idxD] = np.exp(L[idxD])
    return np.matmul(L, L.T)

def test_param_constrain():
    fr_gaussian_so = "../stan/fr_gaussian/fr_gaussian_model.so"
    fr_gaussian_data = "../stan/fr_gaussian/fr_gaussian.data.json"
    bridge = bs.Bridge(fr_gaussian_so, fr_gaussian_data)

    D = 4
    size = 16
    unc_size = 10
    a = np.random.normal(size=unc_size)
    B_expected = cov_constrain(a, D)

    b = bridge.param_constrain(a, include_tp = False, include_gq = False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a, include_gq = False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a, include_tp = False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    full_so = "../stan/full/full_model.so"
    bridge2 = bs.Bridge(full_so)

    b2 = bridge.param_constrain(a)
    np.testing.assert_equal(1, bridge2.param_constrain(a).size)
    np.testing.assert_equal(2, bridge2.param_constrain(a, include_tp = True).size)
    np.testing.assert_equal(3, bridge2.param_constrain(a, include_gq = True).size)
    np.testing.assert_equal(4, bridge2.param_constrain(a, include_tp = True, include_gq = True).size)

    # out tests, matched and mismatched
    scratch = np.zeros(16)
    b = bridge.param_constrain(a, out = scratch)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)
    scratch_wrong = np.zeros(10)
    with np.testing.assert_raises(ValueError):
        bridge.param_constrain(a, out = scratch_wrong)

def test_param_unconstrain():
    fr_gaussian_so = "../stan/fr_gaussian/fr_gaussian_model.so"
    fr_gaussian_data = "../stan/fr_gaussian/fr_gaussian.data.json"
    bridge = bs.Bridge(fr_gaussian_so, fr_gaussian_data)

    unc_size = 10
    a = np.random.normal(size=unc_size)
    b = bridge.param_constrain(a)
    c = bridge.param_unconstrain(b)
    np.testing.assert_allclose(a, c)

    scratch = np.zeros(10)
    c2 = bridge.param_unconstrain(b, out = scratch)
    np.testing.assert_allclose(a, c2)
    scratch_wrong = np.zeros(16)
    with np.testing.assert_raises(ValueError):
        bridge.param_unconstrain(b, out = scratch_wrong)

def test_param_unconstrain_json():
    gaussian_so = "../stan/gaussian/gaussian_model.so"
    gaussian_data = "../stan/gaussian/gaussian.data.json"
    bridge = bs.Bridge(gaussian_so, gaussian_data)

    # theta = np.array([0.2, 1.9])
    theta_unc = np.array([0.2, np.log(1.9)])
    theta_json = "{\"mu\": 0.2, \"sigma\": 1.9}"
    theta_unc_j_test = bridge.param_unconstrain_json(theta_json)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test)

    scratch = np.zeros(2)
    theta_unc_j_test2 = bridge.param_unconstrain_json(theta_json, out = scratch)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test2)

    scratch_bad = np.zeros(10)
    with np.testing.assert_raises(ValueError):
        theta_unc_j_test3 = bridge.param_unconstrain_json(theta_json, out = scratch_bad)

def test_log_density():
    def _bernoulli(y, p):
        return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))
    bernoulli_so = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"
    bridge = bs.Bridge(bernoulli_so, bernoulli_data)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    for _ in range(2):
        x = np.random.uniform(size = smb.param_unc_num())
        x_unc = np.log(x / (1 - x))
        lp = bridge.log_density([x_unc, ], propto = True, jacobian = False)
        np.testing.assert_allclose(logdensity, _bernoulli(y, x))


def test_out_behavior():
    bernoulli_so = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"

    smb = bs.Bridge(bernoulli_so, bernoulli_data)

    grads = []
    for _ in range(2):
        x = np.random.uniform(size = smb.param_unc_num())
        q = np.log(x / (1 - x)) # unconstrained scale
        _, grad = smb.log_density_gradient(q, propto = 1, jacobian = 0)
        grads.append(grad)

    # default behavior is fresh array
    assert grads[0] is not grads[1]

    grads = []
    out_grad = np.zeros(shape = smb.param_unc_num())
    for _ in range(2):
        x = np.random.uniform(size = smb.param_unc_num())
        q = np.log(x / (1 - x)) # unconstrained scale
        _, grad = smb.log_density_gradient(q, propto = 1, jacobian = 0, out=out_grad)
        grads.append(out_grad)

    # out parameter is modified and reference is returned
    assert grads[0] is grads[1]
    assert grads[0] is out_grad
    assert grads[1] is out_grad
    np.testing.assert_allclose(grads[0], grads[1])

def test_bernoulli():
    def _bernoulli(y, p):
        return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))
    bernoulli_so = "../stan/bernoulli/bernoulli_model.so"
    bernoulli_data = "../stan/bernoulli/bernoulli.data.json"
    smb = bs.Bridge(bernoulli_so, bernoulli_data)
    np.testing.assert_string_equal(smb.name(), "bernoulli_model")
    np.testing.assert_allclose(smb.param_unc_num(), 1)
    np.testing.assert_allclose(smb.param_num(include_tp = False, include_gq = False), 1)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 2
    for _ in range(R):
        x = np.random.uniform(size = smb.param_unc_num())
        q = np.log(x / (1 - x)) # unconstrained scale
        logdensity, grad = smb.log_density_gradient(q, propto = True, jacobian = False)
        np.testing.assert_allclose(logdensity, _bernoulli(y, x))
        constrained_theta = smb.param_constrain(q, include_tp = False, include_gq = False)
        np.testing.assert_allclose(constrained_theta, x)
        np.testing.assert_allclose(smb.param_unconstrain(constrained_theta), q)

def test_multi():
    def _multi(x):
        return -0.5 * np.dot(x, x)

    def _grad_multi(x):
        return -x

    multi_so = "../stan/multi/multi_model.so"
    multi_data = "../stan/multi/multi.data.json"

    smm = bs.Bridge(multi_so, multi_data)
    R = 1000

    for _ in range(R):
        x = np.random.normal(size = smm.param_unc_num())
        logdensity, grad = smm.log_density_gradient(x)

        np.testing.assert_allclose(logdensity, _multi(x))
        np.testing.assert_allclose(grad, _grad_multi(x))

def test_gaussian():

    lib = "../stan/gaussian/gaussian_model.so"
    data = "../stan/gaussian/gaussian.data.json"

    model = bs.Bridge(lib, data)

    theta = np.array([0.2, 1.9])
    theta_unc = np.array([0.2, np.log(1.9)])

    theta_test = model.param_constrain(theta_unc, include_tp = 0, include_gq = 0)
    np.testing.assert_allclose(theta, theta_test)

    theta_unc_test = model.param_unconstrain(theta)
    np.testing.assert_allclose(theta_unc, theta_unc_test)

    theta_json = "{\"mu\": 0.2, \"sigma\": 1.9}"
    theta_unc_j_test = model.param_unconstrain_json(theta_json)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test)

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
    np.testing.assert_allclose(model.param_num(include_tp = True, include_gq = True), size)
    np.testing.assert_allclose(model.param_unc_num(), unc_size)

    D = 4
    a = np.random.normal(size=unc_size)
    b = model.param_constrain(a, include_tp = False, include_gq = False)

    B = b.reshape(D, D)
    B_expected = cov_constrain(a, D)
    np.testing.assert_allclose(B_expected, B)

    c = model.param_unconstrain(b)
    np.testing.assert_allclose(a, c)

    names = model.param_names(include_tp = True, include_gq = True)
    pos = 0
    for j in range(1,5):
        for i in range(1, 5):
           np.testing.assert_string_equal(names[pos], f"Omega.{i}.{j}")
           pos += 1

    names_unc = model.param_unc_names()
    pos = 0
    for n in range(1, 11):
        np.testing.assert_string_equal(names_unc[pos], f"Omega.{n}")
        pos += 1

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
    print("test: constructor")
    test_constructor()
    print("test: name")
    test_name()
    print("test: param_num")
    test_param_num()
    print("test: param_unc_num")
    test_param_unc_num()
    print("test: param_names")
    test_param_names()
    print("test: param_unc_names")
    test_param_unc_names()
    print("test: param_constrain")
    test_param_constrain()
    print("test: param_unconstrain")
    test_param_unconstrain()
    print("test: param_unconstrain_json")
    test_param_unconstrain_json()

    print("test: out behavior")
    test_out_behavior()
    print("test: bernoulli")
    test_bernoulli()
    print("test: multi")
    test_multi()
    print("test: gaussian")
    test_gaussian()
    print("test: fr_gaussian")
    test_fr_gaussian()
    print("test: simple")
    test_simple()
    print("------------------------------------------------------------")
    print("If no errors were reported, all tests passed.")
