include("../JuliaClient.jl")
include("../MCMC.jl")

using Test

@testset "bernoulli" begin
    # Bernoulli
    # CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli_model.so

    function bernoulli(y, p)
        sum(yn -> yn * log(p) + (1 - yn) * log(1 - p), y)
    end

    lib = joinpath(@__DIR__, "../stan/bernoulli/bernoulli_model.so")
    data = joinpath(@__DIR__, "../stan/bernoulli/bernoulli.data.json")
    blib = Libc.Libdl.dlopen(lib)

    model = JBS.StanModel(blib, data)
    y = [0, 1, 0, 0, 0, 0, 0, 0, 0, 1]
    R = 1000

    for _ in 1:R
        x = rand(model.dims)
        q = @. log(x / (1 - x)) # unconstrained scale
        JBS.log_density_gradient!(model, q, jacobian = 0)

        p = x[1]
        @test isapprox(model.log_density[1], bernoulli(y, p))

        JBS.param_constrain!(model, q)
        @test isapprox(model.constrained_parameters, x)

        JBS.param_unconstrain!(model, model.constrained_parameters)
        @test isapprox(model.unconstrained_parameters, q)
    end

    @test isapprox(JBS.dims(model), 1)
    @test isapprox(JBS.K(model), 1)
end


@testset "multi" begin
    # Multivariate Gaussian
    # CMDSTAN=/path/to/cmdstan/ make stan/multi/multi_model.so

    function gaussian(x)
        return -0.5 * x' * x
    end

    function grad_gaussian(x)
        return -x
    end

    lib = joinpath(@__DIR__, "../stan/multi/multi_model.so")
    data = joinpath(@__DIR__, "../stan/multi/multi.data.json")
    mlib = Libc.Libdl.dlopen(lib)

    nt = Threads.nthreads()
    models = Tuple(JBS.StanModel(mlib, data) for _ in 1:nt)

    R = 1000
    ld = Vector{Bool}(undef, R)
    g = Vector{Bool}(undef, R)

    @sync for it in 1:nt
        Threads.@spawn for r in it:nt:R
            x = randn(models[it].dims)
            JBS.log_density_gradient!(models[it], x)

            ld[r] = isapprox(models[it].log_density[1], gaussian(x))
            g[r] = isapprox(models[it].gradient, grad_gaussian(x))
        end
    end

    @test all(ld)
    @test all(g)
end


@testset "gaussian" begin
    # Guassian with positive constrained standard deviation
    # CMDSTAN=/path/to/cmdstan/ make stan/gaussian/gaussian_model.so

    lib = joinpath(@__DIR__, "../stan/gaussian/gaussian_model.so")
    data = joinpath(@__DIR__, "../stan/gaussian/gaussian.data.json")
    glib = Libc.Libdl.dlopen(lib)

    model = JBS.StanModel(glib, data)

    stepsize = 0.01
    steps = 10
    hmcd = HMCDiag(model, stepsize, steps)

    N = 10
    theta = zeros(N, model.dims)
    for n in 1:N
        theta[n, :] .= sample(hmcd)
    end

    constrained_theta = zeros(N, model.dims)
    for n in 1:N
        JBS.param_constrain!(model, theta[n, :])
        constrained_theta[n, :] .= model.constrained_parameters
    end

    @test isapprox(constrained_theta[:, 1], theta[:, 1])
    @test isapprox(constrained_theta[:, 2], exp.(theta[:, 2]))
end


@testset "fr_gaussian" begin
    # Full rank Gaussian
    # CMDSTAN=/path/to/cmdstan/ make stan/fr_gaussian/fr_gaussian_model.so

    function _covariance_constrain_transform(v, D)
        k = 0
        L = [j >= i ? (k += 1; v[k]) : 0 for i in 1:D, j in 1:D]'
        for d in 1:D
            L[d, d] = exp(L[d, d])
        end
        return L * L'
    end

    lib = joinpath(@__DIR__, "../stan/fr_gaussian/fr_gaussian_model.so")
    data = joinpath(@__DIR__, "../stan/fr_gaussian/fr_gaussian.data.json")
    glib = Libc.Libdl.dlopen(lib)

    model = JBS.StanModel(glib, data)

    D = 4
    N = 1
    stepsize = 0.01
    steps = 10
    hmcd = HMCDiag(model, stepsize, steps)

    theta = zeros(N, model.dims)
    for n in 1:N
        theta[n, :] .= sample(hmcd)
    end

    # Ad hoc scale down of parameters to prevent over-underflow
    # This is ok since we are interested only in testing transformation
    theta ./= 10

    constrained_theta = zeros(N, model.K)
    for n in 1:N
        JBS.param_constrain!(model, theta[n, :])
        constrained_theta[n, :] .= model.constrained_parameters
    end

    a = theta[N, D+1:end]
    b = constrained_theta[N, D+1:end]

    cov = _covariance_constrain_transform(a, D)
    B = reshape(b, D, D)
    @test isapprox(cov, B)

    JBS.param_unconstrain!(model, constrained_theta[N, :])
    @test isapprox(model.unconstrained_parameters, theta[N, :])

    @test isapprox(model.dims, 14)
    @test isapprox(model.K, 20)
end
