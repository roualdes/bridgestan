using BridgeStan
using Test



models = joinpath(BridgeStan.get_bridgestan_path(), "test_models/")


function test_compile(stanfile; check_threads = true)
    lib = splitext(stanfile)[1] * "_model.so"
    rm(lib, force = true)
    res = BridgeStan.compile_model(stanfile; stanc_args = ["--O1"])
    @test Base.samefile(lib, res)
    rm(lib)

    if check_threads
        # test constructor triggered compilation
        model = BridgeStan.StanModel(
            stanfile,
            joinpath(models, "multi", "multi.data.json");
            make_args = ["STAN_THREADS=true"],
        )
        @test isfile(lib)
        @test contains(BridgeStan.model_info(model), "STAN_THREADS=true")
    end
end

@testset "compile with space in path" begin
    bridgestan_path = get_bridgestan_path()
    mktempdir(prefix = "Bridge Stan") do d
        cp(bridgestan_path, d, force = true)
        set_bridgestan_path!(d)
        test_compile(
            joinpath(d, "test_models", "multi", "multi.stan");
            check_threads = false,
        )
    end
    set_bridgestan_path!(bridgestan_path)
end


@testset "compile good" begin
    test_compile(joinpath(models, "multi", "multi.stan"))
end



@testset "compile bad" begin
    not_stanfile = joinpath(models, "multi", "multi.data.json")
    @test_throws ErrorException BridgeStan.compile_model(not_stanfile)

    nonexistent = joinpath(models, "multi", "multi-notthere.stan")
    @test_throws SystemError BridgeStan.compile_model(nonexistent)

    syntax_error = joinpath(models, "syntax_error", "syntax_error.stan")
    @test_throws ErrorException BridgeStan.compile_model(syntax_error)
end


@testset "bad paths" begin
    @test_throws ErrorException BridgeStan.set_bridgestan_path!("dummy")
    @test_throws ErrorException BridgeStan.set_bridgestan_path!(models)
end
