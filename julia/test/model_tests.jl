using BridgeStan
using Test
using Printf

function load_test_model(name::String, with_data = true)
    lib = joinpath(@__DIR__, @sprintf("../../test_models/%s/%s_model.so", name, name))
    if with_data
        data = joinpath(@__DIR__, @sprintf("../../test_models/%s/%s.data.json", name, name))
    else
        data = ""
    end
    return BridgeStan.StanModel(lib, data)
end

@testset "constructor" begin
    # no data
    load_test_model("stdnormal", false)
    # missing DSO
    @test_throws SystemError BridgeStan.StanModel("Not going to find it")
    # missing data
    @test_throws SystemError load_test_model("stdnormal")
    # exception in constructor
    @test_throws ErrorException load_test_model("throw_data", false)
end

@testset "name" begin
    b = load_test_model("stdnormal", false)
    @test BridgeStan.name(b) == "stdnormal_model"
end

@testset "model info" begin
    b = load_test_model("stdnormal", false)
    @test occursin("STAN_THREADS=true", BridgeStan.model_info(b))
end

@testset "param_num" begin
    b = load_test_model("full", false)
    @test BridgeStan.param_num(b) == 1
    @test BridgeStan.param_num(b; include_tp = false) == 1
    @test BridgeStan.param_num(b; include_gq = false) == 1
    @test BridgeStan.param_num(b; include_tp = false, include_gq = false) == 1
    @test BridgeStan.param_num(b; include_gq = true) == 3
    @test BridgeStan.param_num(b; include_tp = false, include_gq = true) == 3
    @test BridgeStan.param_num(b; include_tp = true) == 2
    @test BridgeStan.param_num(b; include_tp = true, include_gq = false) == 2
    @test BridgeStan.param_num(b; include_tp = true, include_gq = true) == 4
end

@testset "param_unc_num" begin
    b = load_test_model("simplex", false)
    @test BridgeStan.param_num(b) == 5
    @test BridgeStan.param_unc_num(b) == 4
end

@testset "param_names" begin
    b = load_test_model("matrix", false)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"] ==
          BridgeStan.param_names(b)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"] ==
          BridgeStan.param_names(b; include_tp = false)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"] ==
          BridgeStan.param_names(b; include_gq = false)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"] ==
          BridgeStan.param_names(b; include_tp = false, include_gq = false)
    @test [
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
    ] == BridgeStan.param_names(b; include_tp = true)
    @test [
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
    ] == BridgeStan.param_names(b; include_tp = true, include_gq = false)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2", "c"] ==
          BridgeStan.param_names(b; include_gq = true)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2", "c"] ==
          BridgeStan.param_names(b; include_tp = false, include_gq = true)
    @test [
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
    ] == BridgeStan.param_names(b; include_tp = true, include_gq = true)
end

@testset "param_unc_names" begin
    b1 = load_test_model("matrix", false)
    @test ["A.1.1", "A.2.1", "A.3.1", "A.1.2", "A.2.2", "A.3.2"] ==
          BridgeStan.param_unc_names(b1)

    b2 = load_test_model("simplex", false)
    @test ["theta.1", "theta.2", "theta.3", "theta.4"] == BridgeStan.param_unc_names(b2)

end

function _covariance_constrain_transform(v, D)
    k = 0
    L = [j >= i ? (k += 1; v[k]) : 0 for i = 1:D, j = 1:D]'
    for d = 1:D
        L[d, d] = exp(L[d, d])
    end
    return L * L'
end

@testset "param_constrain" begin
    model = load_test_model("fr_gaussian")
    D = 4
    size = 16
    unc_size = 10
    a = randn(unc_size)
    B_expected = _covariance_constrain_transform(a, D)

    b = BridgeStan.param_constrain(model, a)
    B = reshape(b, (D, D))
    @test isapprox(B, B_expected)

    b = BridgeStan.param_constrain(model, a; include_tp = false)
    B = reshape(b, (D, D))
    @test isapprox(B, B_expected)

    b = BridgeStan.param_constrain(model, a; include_gq = false)
    B = reshape(b, (D, D))
    @test isapprox(B, B_expected)

    b = BridgeStan.param_constrain(model, a; include_tp = false, include_gq = false)
    B = reshape(b, (D, D))
    @test isapprox(B, B_expected)

    # out test
    scratch = zeros(16)
    b = BridgeStan.param_constrain!(model, a, scratch)
    @test b === scratch
    B = reshape(b, (D, D))
    @test isapprox(B, B_expected)
    scratch_wrong = zeros(10)
    @test_throws DimensionMismatch BridgeStan.param_constrain!(model, a, scratch_wrong)


    model2 = load_test_model("full", false)
    @test 1 == length(BridgeStan.param_constrain(model2, a))
    @test 2 == length(BridgeStan.param_constrain(model2, a; include_tp = true))
    @test 3 == length(BridgeStan.param_constrain(model2, a; include_gq = true))
    @test 4 == length(
        BridgeStan.param_constrain(model2, a; include_tp = true, include_gq = true),
    )

    # exception handling
    model3 = load_test_model("throw_tp", false)
    y = rand(1)
    BridgeStan.param_constrain(model3, y)
    @test_throws ErrorException BridgeStan.param_constrain(model3, y; include_tp = true)

    model4 = load_test_model("throw_gq", false)
    BridgeStan.param_constrain(model4, y)
    @test_throws ErrorException BridgeStan.param_constrain(model4, y; include_gq = true)
end

@testset "param_unconstrain" begin
    model = load_test_model("fr_gaussian")
    unc_size = 10
    a = randn(unc_size)
    b = BridgeStan.param_constrain(model, a)
    c = BridgeStan.param_unconstrain(model, b)
    @test isapprox(a, c)

    scratch = zeros(unc_size)
    c2 = BridgeStan.param_unconstrain!(model, b, scratch)
    @test c2 === scratch
    @test isapprox(a, c2)

    scratch_wrong = zeros(16)
    @test_throws DimensionMismatch BridgeStan.param_unconstrain!(model, b, scratch_wrong)
end

@testset "param_unconstrain_json" begin
    model = load_test_model("gaussian")
    theta_unc = [0.2, log(1.9)]
    theta_json = "{\"mu\": 0.2, \"sigma\": 1.9}"
    theta_unc_test = BridgeStan.param_unconstrain_json(model, theta_json)
    @test isapprox(theta_unc, theta_unc_test)

    scratch = zeros(2)
    theta_unc_test2 = BridgeStan.param_unconstrain_json!(model, theta_json, scratch)
    @test theta_unc_test2 === scratch
    @test isapprox(theta_unc_test2, theta_unc)

    scratch_wrong = zeros(10)
    @test_throws DimensionMismatch BridgeStan.param_unconstrain_json!(
        model,
        theta_json,
        scratch_wrong,
    )

end

function _log_jacobian(p)
    log.(p .* (1 .- p))
end

function _bernoulli(y, p)
    sum(yn -> yn .* log.(p) + (1 - yn) .* log.(1 .- p), y)
end

function _bernoulli_jacobian(y, p)
    _bernoulli(y, p) .+ _log_jacobian(p)
end

@testset "log_density" begin
    model = load_test_model("bernoulli")
    y = [0, 1, 0, 0, 0, 0, 0, 0, 0, 1]
    x = rand(BridgeStan.param_unc_num(model))
    x_unc = @. log(x / (1 - x))
    lp = BridgeStan.log_density(model, x_unc; propto = false, jacobian = false)
    @test isapprox([lp], _bernoulli(y, x))
    lp2 = BridgeStan.log_density(model, x_unc; propto = false, jacobian = true)
    @test isapprox([lp2], _bernoulli_jacobian(y, x))
    lp3 = BridgeStan.log_density(model, x_unc; propto = true, jacobian = true)
    @test isapprox([lp3], _bernoulli_jacobian(y, x))
    lp4 = BridgeStan.log_density(model, x_unc; propto = true, jacobian = false)
    @test isapprox([lp4], _bernoulli(y, x))

    model2 = load_test_model("throw_lp", false)
    y2 = rand(1)
    @test_throws ErrorException BridgeStan.log_density(model2, y2)
end


@testset "jacobian model tests" begin

    function _logp(y_unc)
        y = exp.(y_unc)
        -0.5 .* y .^ 2
    end

    function _propto_false(y_unc)
        -0.5 .* log(2 * pi)
    end

    function _jacobian_true(y_unc)
        y_unc
    end

    function _grad_logp(y_unc)
        y = exp.(y_unc)
        return -1 .* (y .^ 2)
    end

    function _grad_propto_false(y_unc)
        0
    end

    function _grad_jacobian_true(y_unc)
        1
    end

    function _hess_logp(y_unc)
        y = exp.(y_unc)
        -2.0 .* y .^ 2
    end

    function _hess_propto_false(y_unc)
        0
    end

    function _hess_jacobian_true(y_unc)
        0
    end

    @testset "log_density_gradient" begin
        model = load_test_model("jacobian", false)
        # test value, gradient, all combos +/- propto, +/- jacobian
        y = abs.(randn(1))
        y_unc = log.(y)
        ld, grad =
            BridgeStan.log_density_gradient(model, y_unc; propto = true, jacobian = true)
        @test isapprox(_logp(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_jacobian_true(y_unc), grad)

        ld, grad =
            BridgeStan.log_density_gradient(model, y_unc; propto = true, jacobian = false)
        @test isapprox(_logp(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc), grad)

        ld, grad =
            BridgeStan.log_density_gradient(model, y_unc; propto = false, jacobian = true)
        @test isapprox(_logp(y_unc) .+ _propto_false(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(
            _grad_logp(y_unc) .+ _grad_propto_false(y_unc) .+ _grad_jacobian_true(y_unc),
            grad,
        )

        ld, grad =
            BridgeStan.log_density_gradient(model, y_unc; propto = false, jacobian = false)
        @test isapprox(_logp(y_unc) .+ _propto_false(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_propto_false(y_unc), grad)

        # out parameters
        scratch = zeros(BridgeStan.param_unc_num(model))
        ld, grad = BridgeStan.log_density_gradient!(
            model,
            y_unc,
            scratch;
            propto = true,
            jacobian = true,
        )
        @test grad === scratch
        @test isapprox(_logp(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_jacobian_true(y_unc), grad)

        scratch_bad = zeros(BridgeStan.param_unc_num(model) + 10)
        @test_throws DimensionMismatch BridgeStan.log_density_gradient!(
            model,
            y_unc,
            scratch_bad;
            propto = true,
            jacobian = true,
        )

    end

    @testset "log_density_hessian" begin

        model = load_test_model("jacobian", false)
        # test value, gradient, hessian, all combos +/- propto, +/- jacobian
        y = abs.(randn(1))
        y_unc = log.(y)
        ld, grad, hess =
            BridgeStan.log_density_hessian(model, y_unc; propto = true, jacobian = true)
        @test isapprox(_logp(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_jacobian_true(y_unc), grad)
        @test isapprox(_hess_logp(y_unc) .+ _hess_jacobian_true(y_unc), hess)

        ld, grad, hes =
            BridgeStan.log_density_hessian(model, y_unc; propto = true, jacobian = false)
        @test isapprox(_logp(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc), grad)
        @test isapprox(_hess_logp(y_unc), hess)

        ld, grad, hess =
            BridgeStan.log_density_hessian(model, y_unc; propto = false, jacobian = true)
        @test isapprox(_logp(y_unc) .+ _propto_false(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(
            _grad_logp(y_unc) .+ _grad_propto_false(y_unc) .+ _grad_jacobian_true(y_unc),
            grad,
        )
        @test isapprox(
            _hess_logp(y_unc) .+ _hess_propto_false(y_unc) .+ _hess_jacobian_true(y_unc),
            hess,
        )

        ld, grad, hess =
            BridgeStan.log_density_hessian(model, y_unc; propto = false, jacobian = false)
        @test isapprox(_logp(y_unc) .+ _propto_false(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_propto_false(y_unc), grad)
        @test isapprox(_hess_logp(y_unc) .+ _hess_propto_false(y_unc), hess)

        # out parameters
        dims = BridgeStan.param_unc_num(model)
        grad_scratch = zeros(dims)
        hess_scratch = zeros(dims^2)
        ld, grad, hess = BridgeStan.log_density_hessian!(
            model,
            y_unc,
            grad_scratch,
            hess_scratch;
            propto = true,
            jacobian = true,
        )
        @test grad === grad_scratch
        @test isapprox(_logp(y_unc) .+ _jacobian_true(y_unc), [ld])
        @test isapprox(_grad_logp(y_unc) .+ _grad_jacobian_true(y_unc), grad)
        @test isapprox(_hess_logp(y_unc) .+ _hess_jacobian_true(y_unc), hess)
        @test isapprox(
            _hess_logp(y_unc) .+ _hess_jacobian_true(y_unc),
            reshape(hess_scratch, (dims, dims)),
        )

        # force changes to prove underlying memory is same
        hess_scratch[1] = 3
        @test reshape(hess, (dims^2,)) == hess_scratch

        scratch_bad = zeros(BridgeStan.param_unc_num(model) + 10)
        @test_throws DimensionMismatch BridgeStan.log_density_hessian!(
            model,
            y_unc,
            scratch_bad,
            hess_scratch;
            propto = true,
            jacobian = true,
        )
        @test_throws DimensionMismatch BridgeStan.log_density_hessian!(
            model,
            y_unc,
            grad_scratch,
            scratch_bad;
            propto = true,
            jacobian = true,
        )

    end

end

@testset "bernoulli" begin
    # Bernoulli
    # CMDSTAN=/path/to/cmdstan/ make test_models/bernoulli/bernoulli_model.so

    model = load_test_model("bernoulli")

    @test BridgeStan.name(model) == "bernoulli_model"

    y = [0, 1, 0, 0, 0, 0, 0, 0, 0, 1]
    R = 1000

    for _ = 1:R
        x = rand(BridgeStan.param_num(model))
        q = @. log(x / (1 - x)) # unconstrained scale
        (log_density, gradient) = BridgeStan.log_density_gradient(model, q, jacobian = 0)

        p = x[1]
        @test isapprox(log_density, _bernoulli(y, p))

        constrained_parameters = BridgeStan.param_constrain(model, q)
        @test isapprox(constrained_parameters, x)

        unconstrained_parameters =
            BridgeStan.param_unconstrain(model, constrained_parameters)
        @test isapprox(unconstrained_parameters, q)
    end

    @test isapprox(BridgeStan.param_num(model), 1)
    @test isapprox(BridgeStan.param_unc_num(model), 1)
end


@testset "threaded model: multi" begin
    # Multivariate Gaussian
    # CMDSTAN=/path/to/cmdstan/ make test_models/multi/multi_model.so

    function gaussian(x)
        return -0.5 * x' * x
    end

    function grad_gaussian(x)
        return -x
    end

    model = load_test_model("multi")
    nt = Threads.nthreads()

    R = 1000
    ld = Vector{Bool}(undef, R)
    g = Vector{Bool}(undef, R)

    @sync for it = 1:nt
        Threads.@spawn for r = it:nt:R
            x = randn(BridgeStan.param_num(model))
            (lp, grad) = BridgeStan.log_density_gradient(model, x)

            ld[r] = isapprox(lp, gaussian(x))
            g[r] = isapprox(grad, grad_gaussian(x))
        end
    end

    @test all(ld)
    @test all(g)
end


@testset "gaussian" begin
    # Guassian with positive constrained standard deviation
    # CMDSTAN=/path/to/cmdstan/ make test_models/gaussian/gaussian_model.so

    model = load_test_model("gaussian")

    theta = [0.2, 1.9]
    theta_unc = [0.2, log(1.9)]


    theta_test = BridgeStan.param_constrain(model, theta_unc)
    @test isapprox(theta, theta_test)

    theta_unc_test = BridgeStan.param_unconstrain(model, theta)
    @test isapprox(theta_unc, theta_unc_test)

    theta_json = "{\"mu\": 0.2, \"sigma\": 1.9}"
    theta_unc_j_test = BridgeStan.param_unconstrain_json(model, theta_json)
    @test isapprox(theta_unc, theta_unc_j_test)
end


@testset "fr_gaussian" begin
    # Full rank Gaussian
    # CMDSTAN=/path/to/cmdstan/ make test_models/fr_gaussian/fr_gaussian_model.so

    model = load_test_model("fr_gaussian")

    size = 16
    unc_size = 10

    @test isapprox(size, BridgeStan.param_num(model, include_tp = true, include_gq = true))
    @test isapprox(unc_size, BridgeStan.param_unc_num(model))

    D = 4
    a = randn(unc_size)
    b = BridgeStan.param_constrain(model, a)
    B = reshape(b, (D, D))
    B_expected = _covariance_constrain_transform(a, D)
    @test isapprox(B_expected, B)

    c = BridgeStan.param_unconstrain(model, b)
    @test isapprox(a, c)

    names = BridgeStan.param_names(model, include_tp = true, include_gq = true)
    name_eq = Vector{Bool}(undef, size)
    pos = 1
    for j = 1:4
        for i = 1:4
            name_eq[pos] = names[pos] == ("Omega." * string(i) * "." * string(j))
            pos = pos + 1
        end
    end
    @test all(name_eq)

    unc_names = BridgeStan.param_unc_names(model)
    name_unc_eq = Vector{Bool}(undef, unc_size)
    for n = 1:10
        name_unc_eq[n] = unc_names[n] == ("Omega." * string(n))
    end
    @test all(name_unc_eq)
end


@testset "simple" begin
    model = load_test_model("simple")

    D = 5
    y = rand(D)
    lp, grad, hess = BridgeStan.log_density_hessian(model, y)

    @test isapprox(-y, grad)
    using LinearAlgebra
    @test isapprox(-Matrix(1.0I, D, D), hess)

end
