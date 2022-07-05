include("../JuliaClient.jl")

using Test
using ReverseDiff
using Distributions

@testset "Bernoulli" begin
    # Bernoulli
    # CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli

    function bernoulli_model(y, p)
        Bn = Bernoulli(p);
        Be = Beta(1, 1);
        return sum(logpdf.(Bn, y)) + logpdf(Be, p)
    end

    bernoulli_lib = joinpath(@__DIR__, "../stan/bernoulli/bernoulli_model.so")
    bernoulli_data = joinpath(@__DIR__, "../stan/bernoulli/bernoulli.data.json")
    blib = Libc.Libdl.dlopen(bernoulli_lib)

    smb = JBS.StanModel(blib, bernoulli_data);
    y = [0, 1, 0, 0, 0, 0, 0, 0, 0, 1];
    R = 1000

    for _ in 1:R
        x = rand(smb.D);
        q = @. log(x / (1 - x));                  # unconstrained scale
        JBS.logdensity_grad!(smb, q, jacobian = 0)

        p = x[1];
        @test isapprox(smb.logdensity[1], bernoulli_model(y, p))
    end
end


@testset "32D Gaussian" begin
    # Multivariate Gaussian
    # CMDSTAN=/path/to/cmdstan/ make stan/multi/multi

    function gaussian(x)
        return -0.5 * x' * x
    end

    multi_lib = joinpath(@__DIR__, "../stan/multi/multi_model.so")
    multi_data = joinpath(@__DIR__, "../stan/multi/multi.data.json")
    mlib = Libc.Libdl.dlopen(multi_lib)

    smm = JBS.StanModel(mlib, multi_data)
    R = 1000

    for _ in 1:R
        x = randn(smm.D)
        JBS.logdensity_grad!(smm, x)

        @test isapprox(smm.logdensity[1], gaussian(x))
        @test isapprox(smm.grad, ReverseDiff.gradient(gaussian, x))
    end
end
