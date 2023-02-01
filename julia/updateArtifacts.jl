import Pkg;
Pkg.add("Inflate");
using Tar, Inflate, SHA, TOML

filename = ARGS[1]
version = ARGS[2]

data = Dict(
    "bridgestan" => Dict(
        "git-tree-sha1" => Tar.tree_hash(IOBuffer(inflate_gzip(filename))),
        "lazy" => true,
        "download" => Dict(
            "sha256" => bytes2hex(open(sha256, filename)),
            "url" => string(
                "https://github.com/roualdes/bridgestan/releases/download/",
                version,
                "/",
                filename,
            ),
        ),
    ),
)

open("julia/Artifacts.toml", "w") do io
    TOML.print(io, data)
end
