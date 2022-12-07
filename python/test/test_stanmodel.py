from pathlib import Path

import numpy as np
import pytest

import bridgestan as bs

STAN_FOLDER = Path(__file__).parent.parent.parent / "test_models"


def test_constructor():

    # implicit destructor tests in success and fail cases

    # test empty data
    std_so = str(STAN_FOLDER / "stdnormal" / "stdnormal_model.so")
    b1 = bs.StanModel(std_so)
    np.testing.assert_allclose(bool(b1), True)

    # test load data
    bernoulli_so = str(STAN_FOLDER / "bernoulli" / "bernoulli_model.so")
    bernoulli_data = str(STAN_FOLDER / "bernoulli" / "bernoulli.data.json")
    b2 = bs.StanModel(bernoulli_so, bernoulli_data)
    np.testing.assert_allclose(bool(b2), True)

    bernoulli_data_string = (
        STAN_FOLDER / "bernoulli" / "bernoulli.data.json"
    ).read_text()
    b3 = bs.StanModel(bernoulli_so, bernoulli_data_string)
    np.testing.assert_allclose(bool(b3), True)

    # test missing so file
    with np.testing.assert_raises(FileNotFoundError):
        bs.StanModel("nope, not going to find it")

    # test missing data file
    with np.testing.assert_raises(FileNotFoundError):
        bs.StanModel(bernoulli_so, "nope, not going to find it.json")

    # test data load exception
    throw_data_so = str(STAN_FOLDER / "throw_data" / "throw_data_model.so")
    print("construct() EXCEPTION MSG ON NEXT LINE IS NOT AN ERROR")
    with np.testing.assert_raises(RuntimeError):
        b4 = bs.StanModel(throw_data_so)

    # TODO(carpenter): test get right error message on stderr


def test_name():
    std_so = str(STAN_FOLDER / "stdnormal" / "stdnormal_model.so")
    b = bs.StanModel(std_so)
    np.testing.assert_equal("stdnormal_model", b.name())


def test_model_info():
    std_so = str(STAN_FOLDER / "stdnormal" / "stdnormal_model.so")
    b = bs.StanModel(std_so)
    assert "STAN_OPENCL" in b.model_info()


def test_param_num():
    full_so = str(STAN_FOLDER / "full" / "full_model.so")
    b = bs.StanModel(full_so)
    np.testing.assert_equal(1, b.param_num())
    np.testing.assert_equal(1, b.param_num(include_tp=False))
    np.testing.assert_equal(1, b.param_num(include_gq=False))
    np.testing.assert_equal(1, b.param_num(include_tp=False, include_gq=False))
    np.testing.assert_equal(3, b.param_num(include_gq=True))
    np.testing.assert_equal(3, b.param_num(include_tp=False, include_gq=True))
    np.testing.assert_equal(2, b.param_num(include_tp=True))
    np.testing.assert_equal(2, b.param_num(include_tp=True, include_gq=False))
    np.testing.assert_equal(4, b.param_num(include_tp=True, include_gq=True))


def test_param_unc_num():
    simplex_so = str(STAN_FOLDER / "simplex" / "simplex_model.so")
    b = bs.StanModel(simplex_so)
    np.testing.assert_equal(5, b.param_num())
    np.testing.assert_equal(4, b.param_unc_num())


def test_param_names():
    matrix_so = str(STAN_FOLDER / "matrix" / "matrix_model.so")
    b = bs.StanModel(matrix_so)
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"], b.param_names()
    )
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"],
        b.param_names(include_tp=False),
    )
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"],
        b.param_names(include_gq=False),
    )
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"],
        b.param_names(include_tp=False, include_gq=False),
    )
    np.testing.assert_array_equal(
        [
            "A.1.1",
            "A.2.1",
            "A.3.1",
            "A.1.2",
            "A.2.2",
            "A.3.2",
            "B.1.1",
            "B.2.1",
            "B.3.1",
            "B.1.2",
            "B.2.2",
            "B.3.2",
        ],
        b.param_names(include_tp=True),
    )
    np.testing.assert_array_equal(
        [
            "A.1.1",
            "A.2.1",
            "A.3.1",
            "A.1.2",
            "A.2.2",
            "A.3.2",
            "B.1.1",
            "B.2.1",
            "B.3.1",
            "B.1.2",
            "B.2.2",
            "B.3.2",
        ],
        b.param_names(include_tp=True, include_gq=False),
    )
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2", "c"],
        b.param_names(include_gq=True),
    )
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2", "c"],
        b.param_names(include_tp=False, include_gq=True),
    )
    np.testing.assert_array_equal(
        [
            "A.1.1",
            "A.2.1",
            "A.3.1",
            "A.1.2",
            "A.2.2",
            "A.3.2",
            "B.1.1",
            "B.2.1",
            "B.3.1",
            "B.1.2",
            "B.2.2",
            "B.3.2",
            "c",
        ],
        b.param_names(include_tp=True, include_gq=True),
    )


def test_param_unc_names():
    matrix_so = str(STAN_FOLDER / "matrix" / "matrix_model.so")
    b1 = bs.StanModel(matrix_so)
    np.testing.assert_array_equal(
        ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"], b1.param_unc_names()
    )

    simplex_so = str(STAN_FOLDER / "simplex" / "simplex_model.so")
    b2 = bs.StanModel(simplex_so)
    np.testing.assert_array_equal(
        ["theta.1", "theta.2", "theta.3", "theta.4"], b2.param_unc_names()
    )


def cov_constrain(v, D):
    L = np.zeros([D, D])
    idxL = np.tril_indices(D)
    L[idxL] = v
    idxD = np.diag_indices(D)
    L[idxD] = np.exp(L[idxD])
    return np.matmul(L, L.T)


def test_param_constrain():
    fr_gaussian_so = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian_model.so")
    fr_gaussian_data = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian.data.json")
    bridge = bs.StanModel(fr_gaussian_so, fr_gaussian_data)

    D = 4
    unc_size = 10
    a = np.random.normal(size=unc_size)
    B_expected = cov_constrain(a, D)

    b = bridge.param_constrain(a, include_tp=False, include_gq=False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a, include_gq=False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a, include_tp=False)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    b = bridge.param_constrain(a)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)

    full_so = str(STAN_FOLDER / "full" / "full_model.so")
    bridge2 = bs.StanModel(full_so)

    np.testing.assert_equal(1, bridge2.param_constrain(a).size)
    np.testing.assert_equal(2, bridge2.param_constrain(a, include_tp=True).size)
    np.testing.assert_equal(3, bridge2.param_constrain(a, include_gq=True).size)
    np.testing.assert_equal(
        4, bridge2.param_constrain(a, include_tp=True, include_gq=True).size
    )

    # out tests, matched and mismatched
    scratch = np.zeros(16)
    b = bridge.param_constrain(a, out=scratch)
    B = b.reshape(D, D)
    np.testing.assert_allclose(B_expected, B)
    scratch_wrong = np.zeros(10)
    with np.testing.assert_raises(ValueError):
        bridge.param_constrain(a, out=scratch_wrong)

    # exception handling test in transformed parameters/model (compiled same way)
    throw_tp_so = str(STAN_FOLDER / "throw_tp" / "throw_tp_model.so")
    bridge2 = bs.StanModel(throw_tp_so)

    y = np.array(np.random.uniform(1))
    bridge2.param_constrain(y, include_tp=False)
    print("param_constrain() EXCEPTION MSG ON NEXT LINE IS NOT AN ERROR")
    with np.testing.assert_raises(RuntimeError):
        bridge2.param_constrain(y, include_tp=True)

    throw_gq_so = str(STAN_FOLDER / "throw_gq" / "throw_gq_model.so")
    bridge3 = bs.StanModel(throw_gq_so)
    bridge3.param_constrain(y, include_gq=False)
    print("param_constrain() EXCEPTION MSG ON NEXT LINE IS NOT AN ERROR")
    with np.testing.assert_raises(RuntimeError):
        bridge3.param_constrain(y, include_gq=True)


def test_param_unconstrain():
    fr_gaussian_so = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian_model.so")
    fr_gaussian_data = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian.data.json")
    bridge = bs.StanModel(fr_gaussian_so, fr_gaussian_data)

    unc_size = 10
    a = np.random.normal(size=unc_size)
    b = bridge.param_constrain(a)
    c = bridge.param_unconstrain(b)
    np.testing.assert_allclose(a, c)

    scratch = np.zeros(10)
    c2 = bridge.param_unconstrain(b, out=scratch)
    np.testing.assert_allclose(a, c2)
    scratch_wrong = np.zeros(16)
    with np.testing.assert_raises(ValueError):
        bridge.param_unconstrain(b, out=scratch_wrong)


def test_param_unconstrain_json():
    gaussian_so = str(STAN_FOLDER / "gaussian" / "gaussian_model.so")
    gaussian_data = str(STAN_FOLDER / "gaussian" / "gaussian.data.json")
    bridge = bs.StanModel(gaussian_so, gaussian_data)

    # theta = np.array([0.2, 1.9])
    theta_unc = np.array([0.2, np.log(1.9)])
    theta_json = '{"mu": 0.2, "sigma": 1.9}'
    theta_unc_j_test = bridge.param_unconstrain_json(theta_json)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test)

    scratch = np.zeros(2)
    theta_unc_j_test2 = bridge.param_unconstrain_json(theta_json, out=scratch)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test2)

    scratch_bad = np.zeros(10)
    with np.testing.assert_raises(ValueError):
        bridge.param_unconstrain_json(theta_json, out=scratch_bad)


def _log_jacobian(p):
    return np.log(p * (1 - p))


def _bernoulli(y, p):
    return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))


def _bernoulli_jacobian(y, p):
    return _bernoulli(y, p) + _log_jacobian(p)


def test_log_density():
    bernoulli_so = str(STAN_FOLDER / "bernoulli" / "bernoulli_model.so")
    bernoulli_data = str(STAN_FOLDER / "bernoulli" / "bernoulli.data.json")
    bridge = bs.StanModel(bernoulli_so, bernoulli_data)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    for _ in range(2):
        x = np.random.uniform(size=bridge.param_unc_num())
        x_unc = np.log(x / (1 - x))
        lp = bridge.log_density(np.array([x_unc]), propto=False, jacobian=False)
        np.testing.assert_allclose(lp, _bernoulli(y, x))
        lp2 = bridge.log_density(np.array([x_unc]), propto=False, jacobian=True)
        np.testing.assert_allclose(lp2, _bernoulli_jacobian(y, x))
        lp3 = bridge.log_density(np.array([x_unc]), propto=True, jacobian=True)
        np.testing.assert_allclose(lp3, _bernoulli_jacobian(y, x))
        lp4 = bridge.log_density(np.array([x_unc]), propto=True, jacobian=False)
        np.testing.assert_allclose(lp4, _bernoulli(y, x))

    throw_lp_so = str(STAN_FOLDER / "throw_lp" / "throw_lp_model.so")
    bridge2 = bs.StanModel(throw_lp_so)
    y2 = np.array(np.random.uniform(1))
    print("log_density() EXCEPTION MSG ON NEXT LINE IS NOT AN ERROR")
    with np.testing.assert_raises(RuntimeError):
        bridge2.log_density(y2)


def test_log_density_gradient():
    def _logp(y_unc):
        y = np.exp(y_unc)
        return -0.5 * y**2

    def _propto_false(y_unc):
        return -0.5 * np.log(2 * np.pi)

    def _jacobian_true(y_unc):
        return y_unc

    def _grad_logp(y_unc):
        y = np.exp(y_unc)
        return -(y**2)

    def _grad_propto_false(y_unc):
        return 0

    def _grad_jacobian_true(y_unc):
        return 1

    jacobian_so = str(STAN_FOLDER / "jacobian" / "jacobian_model.so")
    bridge = bs.StanModel(jacobian_so)

    y = np.abs(np.random.normal(1))
    y_unc = np.log(y)
    y_unc_arr = np.array(y_unc)
    logdensity, grad = bridge.log_density_gradient(
        y_unc_arr, propto=True, jacobian=True
    )
    np.testing.assert_allclose(_logp(y_unc) + _jacobian_true(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_jacobian_true(y_unc), grad[0])
    #
    logdensity, grad = bridge.log_density_gradient(
        y_unc_arr, propto=True, jacobian=False
    )
    np.testing.assert_allclose(_logp(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc), grad[0])
    #
    logdensity, grad = bridge.log_density_gradient(
        y_unc_arr, propto=False, jacobian=True
    )
    np.testing.assert_allclose(
        _logp(y_unc) + _propto_false(y_unc) + _jacobian_true(y_unc), logdensity
    )
    np.testing.assert_allclose(
        _grad_logp(y_unc) + _grad_propto_false(y_unc) + _grad_jacobian_true(y_unc),
        grad[0],
    )
    #
    logdensity, grad = bridge.log_density_gradient(
        y_unc_arr, propto=False, jacobian=False
    )
    np.testing.assert_allclose(_logp(y_unc) + _propto_false(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_propto_false(y_unc), grad[0])

    # test use of scratch
    scratch = np.zeros(bridge.param_unc_num())
    logdensity, grad = bridge.log_density_gradient(
        y_unc_arr, propto=True, jacobian=True, out=scratch
    )
    np.testing.assert_allclose(_logp(y_unc) + _jacobian_true(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_jacobian_true(y_unc), grad[0])
    #
    scratch_bad = np.zeros(bridge.param_unc_num() + 10)
    with np.testing.assert_raises(ValueError):
        bridge.log_density_gradient(y_unc, out=scratch_bad)


def test_log_density_hessian():
    def _logp(y_unc):
        y = np.exp(y_unc)
        return -0.5 * y**2

    def _propto_false(y_unc):
        return -0.5 * np.log(2 * np.pi)

    def _jacobian_true(y_unc):
        return y_unc

    def _grad_logp(y_unc):
        y = np.exp(y_unc)
        return -(y**2)

    def _grad_propto_false(y_unc):
        return 0

    def _grad_jacobian_true(y_unc):
        return 1

    def _hess_logp(y_unc):
        y = np.exp(y_unc)
        return -2.0 * y**2

    def _hess_propto_false(y_unc):
        return 0

    def _hess_jacobian_true(y_unc):
        return 0

    jacobian_so = str(STAN_FOLDER / "jacobian" / "jacobian_model.so")
    bridge = bs.StanModel(jacobian_so)

    # test value, gradient, hessian, all combos +/- propto, +/- jacobian
    y = np.abs(np.random.normal(1))
    y_unc = np.log(y)
    y_unc_arr = np.array(y_unc)
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=True, jacobian=True
    )
    np.testing.assert_allclose(_logp(y_unc) + _jacobian_true(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_jacobian_true(y_unc), grad[0])
    np.testing.assert_allclose(
        _hess_logp(y_unc) + _hess_jacobian_true(y_unc), hess[0, 0]
    )
    #
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=True, jacobian=False
    )
    np.testing.assert_allclose(_logp(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc), grad[0])
    np.testing.assert_allclose(_hess_logp(y_unc), hess[0, 0])
    #
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=False, jacobian=True
    )
    np.testing.assert_allclose(
        _logp(y_unc) + _propto_false(y_unc) + _jacobian_true(y_unc), logdensity
    )
    np.testing.assert_allclose(
        _grad_logp(y_unc) + _grad_propto_false(y_unc) + _grad_jacobian_true(y_unc),
        grad[0],
    )
    np.testing.assert_allclose(
        _hess_logp(y_unc) + _hess_propto_false(y_unc) + _hess_jacobian_true(y_unc),
        hess[0, 0],
    )
    #
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=False, jacobian=True
    )
    np.testing.assert_allclose(
        _logp(y_unc) + _propto_false(y_unc) + _jacobian_true(y_unc), logdensity
    )
    np.testing.assert_allclose(
        _grad_logp(y_unc) + _grad_propto_false(y_unc) + _grad_jacobian_true(y_unc),
        grad[0],
    )
    np.testing.assert_allclose(
        _hess_logp(y_unc) + _hess_propto_false(y_unc) + _hess_jacobian_true(y_unc),
        hess[0, 0],
    )
    #
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=False, jacobian=False
    )
    np.testing.assert_allclose(_logp(y_unc) + _propto_false(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_propto_false(y_unc), grad[0])
    np.testing.assert_allclose(
        _hess_logp(y_unc) + _hess_propto_false(y_unc), hess[0, 0]
    )

    # test use of scratch
    scratch = np.zeros(bridge.param_unc_num())
    logdensity, grad, hess = bridge.log_density_hessian(
        y_unc_arr, propto=True, jacobian=True, out_grad=scratch
    )
    np.testing.assert_allclose(_logp(y_unc) + _jacobian_true(y_unc), logdensity)
    np.testing.assert_allclose(_grad_logp(y_unc) + _grad_jacobian_true(y_unc), grad[0])
    #
    scratch_bad = np.zeros(bridge.param_unc_num() + 10)
    with np.testing.assert_raises(ValueError):
        bridge.log_density_hessian(y_unc, out_grad=scratch_bad)

    # test with 5 x 5 Hessian
    simple_so = str(STAN_FOLDER / "simple" / "simple_model.so")
    simple_data = str(STAN_FOLDER / "simple" / "simple.data.json")
    bridge2 = bs.StanModel(simple_so, simple_data)

    D = 5
    y = np.random.uniform(size=D)
    lp, grad, hess = bridge2.log_density_hessian(y)
    np.testing.assert_allclose(-y, grad)
    np.testing.assert_allclose(-np.identity(D), hess)


def test_out_behavior():
    bernoulli_so = str(STAN_FOLDER / "bernoulli" / "bernoulli_model.so")
    bernoulli_data = str(STAN_FOLDER / "bernoulli" / "bernoulli.data.json")
    smb = bs.StanModel(bernoulli_so, bernoulli_data)

    grads = []
    for _ in range(2):
        x = np.random.uniform(size=smb.param_unc_num())
        q = np.log(x / (1 - x))  # unconstrained scale
        _, grad = smb.log_density_gradient(q, propto=1, jacobian=0)
        grads.append(grad)

    # default behavior is fresh array
    assert grads[0] is not grads[1]

    grads = []
    out_grad = np.zeros(shape=smb.param_unc_num())
    for _ in range(2):
        x = np.random.uniform(size=smb.param_unc_num())
        q = np.log(x / (1 - x))  # unconstrained scale
        _, grad = smb.log_density_gradient(q, propto=1, jacobian=0, out=out_grad)
        grads.append(out_grad)

    # out parameter is modified and reference is returned
    assert grads[0] is grads[1]
    assert grads[0] is out_grad
    assert grads[1] is out_grad
    np.testing.assert_allclose(grads[0], grads[1])


# BONUS TESTS


def test_bernoulli():
    def _bernoulli(y, p):
        return np.sum(y * np.log(p) + (1 - y) * np.log(1 - p))

    bernoulli_so = str(STAN_FOLDER / "bernoulli" / "bernoulli_model.so")
    bernoulli_data = str(STAN_FOLDER / "bernoulli" / "bernoulli.data.json")
    smb = bs.StanModel(bernoulli_so, bernoulli_data)
    np.testing.assert_string_equal(smb.name(), "bernoulli_model")
    np.testing.assert_allclose(smb.param_unc_num(), 1)
    np.testing.assert_allclose(smb.param_num(include_tp=False, include_gq=False), 1)
    y = np.asarray([0, 1, 0, 0, 0, 0, 0, 0, 0, 1])
    R = 2
    for _ in range(R):
        x = np.random.uniform(size=smb.param_unc_num())
        q = np.log(x / (1 - x))  # unconstrained scale
        logdensity, grad = smb.log_density_gradient(q, propto=True, jacobian=False)
        np.testing.assert_allclose(logdensity, _bernoulli(y, x))
        constrained_theta = smb.param_constrain(q, include_tp=False, include_gq=False)
        np.testing.assert_allclose(constrained_theta, x)
        np.testing.assert_allclose(smb.param_unconstrain(constrained_theta), q)


def test_multi():
    def _multi(x):
        return -0.5 * np.dot(x, x)

    def _grad_multi(x):
        return -x

    multi_so = str(STAN_FOLDER / "multi" / "multi_model.so")
    multi_data = str(STAN_FOLDER / "multi" / "multi.data.json")

    smm = bs.StanModel(multi_so, multi_data)
    x = np.random.normal(size=smm.param_unc_num())
    logdensity, grad = smm.log_density_gradient(x)
    np.testing.assert_allclose(logdensity, _multi(x))
    np.testing.assert_allclose(grad, _grad_multi(x))


def test_gaussian():

    lib = str(STAN_FOLDER / "gaussian" / "gaussian_model.so")
    data = str(STAN_FOLDER / "gaussian" / "gaussian.data.json")

    model = bs.StanModel(lib, data)

    theta = np.array([0.2, 1.9])
    theta_unc = np.array([0.2, np.log(1.9)])

    theta_test = model.param_constrain(theta_unc, include_tp=0, include_gq=0)
    np.testing.assert_allclose(theta, theta_test)

    theta_unc_test = model.param_unconstrain(theta)
    np.testing.assert_allclose(theta_unc, theta_unc_test)

    theta_json = '{"mu": 0.2, "sigma": 1.9}'
    theta_unc_j_test = model.param_unconstrain_json(theta_json)
    np.testing.assert_allclose(theta_unc, theta_unc_j_test)


def test_fr_gaussian():

    lib = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian_model.so")
    data = str(STAN_FOLDER / "fr_gaussian" / "fr_gaussian.data.json")
    model = bs.StanModel(lib, data)

    size = 16
    unc_size = 10
    np.testing.assert_allclose(model.param_num(include_tp=True, include_gq=True), size)
    np.testing.assert_allclose(model.param_unc_num(), unc_size)

    D = 4
    a = np.random.normal(size=unc_size)
    b = model.param_constrain(a, include_tp=False, include_gq=False)

    B = b.reshape(D, D)
    B_expected = cov_constrain(a, D)
    np.testing.assert_allclose(B_expected, B)

    c = model.param_unconstrain(b)
    np.testing.assert_allclose(a, c)

    names = model.param_names(include_tp=True, include_gq=True)
    pos = 0
    for j in range(1, 5):
        for i in range(1, 5):
            np.testing.assert_string_equal(names[pos], f"Omega.{i}.{j}")
            pos += 1

    names_unc = model.param_unc_names()
    pos = 0
    for n in range(1, 11):
        np.testing.assert_string_equal(names_unc[pos], f"Omega.{n}")
        pos += 1


@pytest.fixture
def recompile_simple():
    """Recompile simple_model with autodiff hessian enable, then clean-up/restore it after test"""

    stanfile = STAN_FOLDER / "simple" / "simple.stan"
    lib = bs.compile.generate_so_name(stanfile)
    lib.unlink(missing_ok=True)
    res = bs.compile_model(stanfile, make_args=["BRIDGESTAN_AD_HESSIAN=true"])

    yield res

    lib.unlink(missing_ok=True)
    bs.compile_model(stanfile, make_args=["STAN_THREADS=true"])


@pytest.mark.ad_hessian
def test_hessian_autodiff(recompile_simple):
    simple_data = str(STAN_FOLDER / "simple" / "simple.data.json")
    model = bs.StanModel(recompile_simple, simple_data)
    assert "BRIDGESTAN_AD_HESSIAN=true" in model.model_info()
    D = 5
    y = np.random.uniform(size=D)
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
    print("test: log_density")
    test_log_density()
    print("test: log_density_gradient")
    test_log_density_gradient()
    print("test: log_density_hessian")
    test_log_density_hessian()
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
    print("------------------------------------------------------------")
    print("If no errors were reported, all tests passed.")
