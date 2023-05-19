module BridgeStan

using LazyArtifacts

export StanModel,
    name,
    model_info,
    param_num,
    param_unc_num,
    param_names,
    param_unc_names,
    param_constrain!,
    param_unconstrain!,
    param_unconstrain_json!,
    log_density_gradient!,
    log_density_hessian!,
    param_constrain,
    param_unconstrain,
    param_unconstrain_json,
    log_density,
    log_density_gradient,
    log_density_hessian,
    get_bridgestan_path,
    set_bridgestan_path!,
    compile_model,
    StanRNG

include("model.jl")
include("compile.jl")

"""
    StanModel(;stan_file, stanc_args=[], make_args=[], data="", seed=204)

Construct a StanModel instance from a `.stan` file, compiling if necessary.

This is equivalent to calling `compile_model` and then the original constructor of StanModel.
"""
StanModel(;
    stan_file::String,
    stanc_args::AbstractVector{String} = String[],
    make_args::AbstractVector{String} = String[],
    data::String = "",
    seed = 204,
) = StanModel(compile_model(stan_file; stanc_args, make_args), data, seed)


function __init__()
    # On Windows, we may need to add TBB to %PATH%
    if Sys.iswindows()
        try
            run(pipeline(`where.exe tbb.dll`, stdout=devnull, stderr=devnull))
        catch
            # add TBB to %PATH%
            ENV["PATH"] = joinpath(get_bridgestan_path(), "stan", "lib", "stan_math", "lib", "tbb") * ";" * ENV["PATH"]
        end
    end
end

end
