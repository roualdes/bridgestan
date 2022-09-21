module BridgeStan

export StanModel,
    name,
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
    set_cmdstan_path,
    set_bridgestan_path,
    compile_model,
    StanModel_from_stan_file


include("model.jl")
include("compile.jl")

set_cmdstan_path = Compile.set_cmdstan_path
set_bridgestan_path = Compile.set_bridgestan_path
compile_model = Compile.compile_model

"""
    StanModel_from_stan_file(stan_file, datafile_="", seed_=204, chain_id_=0)

Construct a StanModel instance from a `.stan` file, compiling if necessary.

This is equivalent to calling `compile_model` and then the constructor of StanModel.ju
"""
function StanModel_from_stan_file(stan_file::String, datafile_::String="", seed_=204, chain_id_=0)
    library = compile_model(stan_file)
    StanModel(library, datafile_, seed_, chain_id_)
end

function __init__()
    if Compile.get_bridgestan() == ""
        @warn "BridgeStan path was not set, compilation will not work until you call `set_bridgestan_path()`"
    end
    if Compile.get_cmdstan() == ""
        @warn "CmdStan path was not set, compilation will not work until you call `set_cmdstan_path()`"
    end
end


end
