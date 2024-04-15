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
    log_density_hessian_vector_product!,
    param_constrain,
    param_unconstrain,
    param_unconstrain_json,
    log_density,
    log_density_gradient,
    log_density_hessian,
    log_density_hessian_vector_product,
    get_bridgestan_path,
    set_bridgestan_path!,
    compile_model,
    StanRNG,
    new_rng

include("model.jl")
include("download.jl")
include("compile.jl")

"""
    StanModel(;stan_file, stanc_args=[], make_args=[], data="", seed=204)

Deprecated; use the normal constructor, StanModel(...), with a path to a `.stan` file, instead.

Construct a StanModel instance from a `.stan` file, compiling if necessary.
This is equivalent to calling `compile_model` and then the original constructor of StanModel.
"""
function StanModel(;
    stan_file::String,
    stanc_args::AbstractVector{String} = String[],
    make_args::AbstractVector{String} = String[],
    data::String = "",
    seed = 204,
)
    Base.depwarn(
        "StanModel(;stan_file,... ) is deprecated. Use the normal constructor, StanModel(...) instead.",
        :StanModel,
    )
    StanModel(stan_file, data, seed; stanc_args, make_args)
end

end
