include("../JuliaClient.jl")

using Test

@testset "bernoulli" begin
    # Bernoulli
    # CMDSTAN=/path/to/cmdstan/ make stan/bernoulli/bernoulli_model.so

    function bernoulli(y, p)
        sum(yn -> yn * log(p) + (1 - yn) * log(1 - p), y)
    end

    bernoulli_lib = joinpath(@__DIR__, "../stan/bernoulli/bernoulli_model.so")
    bernoulli_data = joinpath(@__DIR__, "../stan/bernoulli/bernoulli.data.json")
    blib = Libc.Libdl.dlopen(bernoulli_lib)

    smb = JBS.StanModel(blib, bernoulli_data);
    y = [0, 1, 0, 0, 0, 0, 0, 0, 0, 1];
    R = 1000

    for _ in 1:R
        x = rand(smb.dims);
        q = @. log(x / (1 - x)); # unconstrained scale
        JBS.log_density_gradient!(smb, q, jacobian = 0)

        p = x[1];
        @test isapprox(smb.log_density[1], bernoulli(y, p))

        JBS.param_constrain(smb, q)
        @test isapprox(smb.constrained_parameters, x)
    end
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

    multi_lib = joinpath(@__DIR__, "../stan/multi/multi_model.so")
    multi_data = joinpath(@__DIR__, "../stan/multi/multi.data.json")
    mlib = Libc.Libdl.dlopen(multi_lib)

    nt = Threads.nthreads()
    smm = Tuple(JBS.StanModel(mlib, multi_data) for _ in 1:nt)

    R = 1000
    ld = Vector{Bool}(undef, R)
    g = Vector{Bool}(undef, R)

    @sync for it in 1:nt
        Threads.@spawn for r in it:nt:R
            x = randn(smm[it].dims)
            JBS.log_density_gradient!(smm[it], x)

            ld[r] = isapprox(smm[it].log_density[1], gaussian(x))
            g[r] = isapprox(smm[it].gradient, grad_gaussian(x))
        end
    end

    @test all(ld)
    @test all(g)
end
