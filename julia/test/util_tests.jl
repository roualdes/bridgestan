using BridgeStan
using BridgeStan: @const
using Test

mutable struct Foo
    x::Any
    @const y
end

@testset "@const utility" begin
    a = Foo(1, 2)
    @test a.x == 1
    @test a.y == 2
    a.x = 3
    @test a.x == 3
    @test a.y == 2
    if VERSION ≥ v"1.8"
        # y is const
        @test_throws ErrorException a.y = 4
    else
        # y is mutable
        a.y = 4
        @test a.y == 4
    end
end



@testset "download artifact" begin
    withenv("BRIDGESTAN" => nothing) do
        BridgeStan.validate_stan_dir(BridgeStan.get_bridgestan_path())
    end
end
