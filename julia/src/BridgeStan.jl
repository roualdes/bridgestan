module BridgeStan

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
    set_bridgestan_path!,
    compile_model

include("model.jl")
include("compile.jl")

"""
    StanModel(;stan_file, stanc_args=[], make_args=[], data="", seed=204, chain_id=0)

Construct a StanModel instance from a `.stan` file, compiling if necessary.

This is equivalent to calling `compile_model` and then the original constructor of StanModel.
"""
StanModel(;
    stan_file::String,
    stanc_args::AbstractVector{String} = String[],
    make_args::AbstractVector{String} = String[],
    data::String = "",
    seed = 204,
    chain_id = 0,
) = StanModel(compile_model(stan_file; stanc_args, make_args), data, seed, chain_id)

end
