module Compile

MAKE::String = get(ENV, "MAKE", Sys.iswindows() ? "mingw32-make.exe" : "make")
BRIDGESTAN_PATH::String = get(ENV, "BRIDGESTAN", "")
CMDSTAN_PATH::String = get(ENV, "CMDSTAN", "")

if BRIDGESTAN_PATH == ""
    @warn "BridgeStan path was not set, compilation will not work until you call `set_bridgestan_path()`"
end
if CMDSTAN_PATH == ""
    for el in readdir(joinpath(Base.Filesystem.homedir(), ".cmdstan/"), join=true, sort=true)
        CMDSTAN_PATH = el
        break
    end
    if CMDSTAN_PATH == ""
        @warn "CmdStan path was not set, compilation will not work until you call `set_cmdstan_path()`"
    end
end

function validate_stan_dir(path::AbstractString)
    if !isdir(path)
        error("Path does not exist!\n$path")
    end
    if !isfile(joinpath(path, "Makefile"))
        error("Makefile does not exist at path! Make sure it was installed correctly.\n$path")
    end
end

function set_cmdstan_path(path::AbstractString)
    if !isdir(path)
        error("Path does not exist!\n$path")
    end
    global CMDSTAN_PATH = path
end


function set_bridgestan_path(path::AbstractString)
    validate_stan_dir(path)
    global BRIDGESTAN_PATH = path
end

function compile_model(stan_file::AbstractString, args::AbstractVector{String}=String[])
    validate_stan_dir(BRIDGESTAN_PATH)

    if !isfile(stan_file)
        throw(SystemError("Stan file not found: $stan_file"))
    end
    if splitext(stan_file)[2] != ".stan"
        error("File '$stan_file' does not end in .stan")
    end

    absolute_path = abspath(stan_file)
    output_file = splitext(absolute_path)[1] * "_model.so"
    cmdstan = replace(abspath(CMDSTAN_PATH), "\\" => "/") * "/"

    cmd = Cmd(`$MAKE CMDSTAN=$cmdstan $args $output_file`, dir=abspath(BRIDGESTAN_PATH))
    out = IOBuffer()
    err = IOBuffer()
    is_ok = success(pipeline(cmd; stdout=out, stderr=err))
    if !is_ok
        error("Compilation failed!\nCommand: $cmd\nstdout: $(String(take!(out)))\nstderr: $(String(take!(err)))")
    end
    return output_file
end

end
