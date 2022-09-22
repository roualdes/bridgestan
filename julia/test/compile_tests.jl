using BridgeStan
using Test

models = joinpath(@__DIR__, "../../test_models/")


@testset "compile good" begin
    BridgeStan.set_bridgestan_path!("../..")

    stanfile = joinpath(models, "multi", "multi.stan")
    lib = splitext(stanfile)[1] * "_model.so"
    rm(lib, force = true)
    res = BridgeStan.compile_model(stanfile)
    @test Base.samefile(lib, res)

    rm(lib)
    res = BridgeStan.compile_model(stanfile, ["STAN_THREADS=true"])
    @test Base.samefile(lib, res)
end



@testset "compile bad" begin
    not_stanfile = joinpath(models, "multi", "multi.data.json")
    @test_throws ErrorException BridgeStan.compile_model(not_stanfile)

    nonexistant = joinpath(models, "multi", "multi-notthere.stan")
    @test_throws SystemError BridgeStan.compile_model(nonexistant)

    syntax_error = joinpath(models, "syntax_error", "syntax_error.stan")
    @test_throws ErrorException BridgeStan.compile_model(syntax_error)
end


@testset "bad paths" begin
    @test_throws ErrorException BridgeStan.set_cmdstan_path!("dummy")
    @test_throws ErrorException BridgeStan.set_bridgestan_path!("dummy")
    @test_throws ErrorException BridgeStan.set_bridgestan_path!(models)
end
