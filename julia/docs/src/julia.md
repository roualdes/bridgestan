# Julia Interface: BridgeStan.jl

```@raw html
% NB: If you are reading this file in python/docs/languages, you are reading a generated output!
% This should be apparent due to the html tags everywhere.
% If you are reading this in julia/docs/src, you are reading the true source!
% Please only make edits in the later file, since the first is DELETED each re-build.
```

---

## StanModel interface

```@docs
StanModel
log_density
log_density_gradient
log_density_hessian
param_constrain
param_unconstrain
param_unconstrain_json
name
model_info
param_num
param_unc_num
param_names
param_unc_names
log_density_gradient!
log_density_hessian!
param_constrain!
param_unconstrain!
param_unconstrain_json!
```

## Compilation utilities
```@docs
compile_model
set_bridgestan_path!
set_cmdstan_path!
```
