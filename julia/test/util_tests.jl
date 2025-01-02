using BridgeStan
using Test

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
