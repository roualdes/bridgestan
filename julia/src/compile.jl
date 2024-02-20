
function get_make()
    get(ENV, "MAKE", Sys.iswindows() ? "mingw32-make.exe" : "make")
end

"""
    get_bridgestan_path() -> String

Return the path the the BridgeStan directory.

If the environment variable `BRIDGESTAN` is set, this will be returned. Otherwise, this
function downloads an artifact containing the BridgeStan repository and returns the path to
the extracted directory.
"""
function get_bridgestan_path()
    path = get(ENV, "BRIDGESTAN", "")
    if path == ""
        artifact_path = artifact"bridgestan"
        path = joinpath(artifact_path, only(readdir(artifact_path)))
    end
    return path
end

function validate_stan_dir(path::AbstractString)
    if !isdir(path)
        error("Path does not exist!\n$path")
    end
    if !isfile(joinpath(path, "Makefile"))
        error(
            "Makefile does not exist at path! Make sure it was installed correctly.\n$path",
        )
    end
end


"""
    set_bridgestan_path!(path)

Set the path BridgeStan.
"""
function set_bridgestan_path!(path::AbstractString)
    validate_stan_dir(path)
    ENV["BRIDGESTAN"] = path
end


"""
    compile_model(stan_file; stanc_args=[], make_args=[])

Run BridgeStan’s Makefile on a `.stan` file, creating the `.so` used by StanModel and
return a path to the compiled library.
Arguments to `stanc3` can be passed as a vector, for example `["--O1"]` enables level 1 compiler
optimizations.
Additional arguments to `make` can be passed as a vector, for example `["STAN_THREADS=true"]`
enables the model's threading capabilities. If the same flags are defined in `make/local`,
the versions passed here will take precedent.

This function checks that the path to BridgeStan is valid and will error if it is not.
This can be set with `set_bridgestan_path!()`.
"""
function compile_model(
    stan_file::AbstractString;
    stanc_args::AbstractVector{String} = String[],
    make_args::AbstractVector{String} = String[],
)
    bridgestan = get_bridgestan_path()
    validate_stan_dir(bridgestan)

    if !isfile(stan_file)
        throw(SystemError("Stan file not found: $stan_file"))
    end
    if splitext(stan_file)[2] != ".stan"
        error("File '$stan_file' does not end in .stan")
    end

    absolute_path = abspath(stan_file)
    output_file = splitext(absolute_path)[1] * "_model.so"

    cmd = Cmd(
        `$(get_make()) $make_args "STANCFLAGS=--include-paths=. $stanc_args" $output_file`,
        dir = abspath(bridgestan),
    )
    out = IOBuffer()
    err = IOBuffer()
    is_ok = success(pipeline(cmd; stdout = out, stderr = err))
    if !is_ok
        error(
            "Compilation failed!\nCommand: $cmd\nstdout: $(String(take!(out)))\nstderr: $(String(take!(err)))",
        )
    end
    return output_file
end

WINDOWS_PATH_SET = Ref{Bool}(false)

function tbb_found()
    try
        run(pipeline(`where.exe tbb.dll`, stdout = devnull, stderr = devnull))
    catch
        return false
    end
    return true
end

function windows_dll_path_setup()
    if Sys.iswindows() && !(WINDOWS_PATH_SET[])
        if tbb_found()
            WINDOWS_PATH_SET[] = true
        else
            # add TBB to %PATH%
            ENV["PATH"] =
                joinpath(get_bridgestan_path(), "stan", "lib", "stan_math", "lib", "tbb") *
                ";" *
                ENV["PATH"]
            WINDOWS_PATH_SET[] = tbb_found()
        end
    end
end
