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



@testset "download" begin
    withenv("BRIDGESTAN" => nothing) do
        existing = BridgeStan.get_bridgestan_path(download = false)
        if existing != "" && isdir(existing)
            rm(existing; recursive = true)
        end

        # first call - download doesn't occur
        @test "" == BridgeStan.get_bridgestan_path(download = false)
        # download occurs
        BridgeStan.verify_bridgestan_path(BridgeStan.get_bridgestan_path())
        # download doesn't occur, returns path from 2nd call
        BridgeStan.verify_bridgestan_path(BridgeStan.get_bridgestan_path(download = false))
    end
end
