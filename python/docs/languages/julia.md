
<a id='Julia-Interface:-BridgeStan.jl'></a>

<a id='Julia-Interface:-BridgeStan.jl-1'></a>

# Julia Interface: BridgeStan.jl


% NB: If you are reading this file in python/docs/languages, you are reading a generated output!
% This should be apparent due to the html tags everywhere.
% If you are reading this in julia/docs/src, you are reading the true source!
% Please only make edits in the later file, since the first is DELETED each re-build.

<a id='BridgeStan.StanModel' href='#BridgeStan.StanModel'>#</a>
**`BridgeStan.StanModel`** &mdash; *Type*.



```julia
StanModel(stanlib_, datafile_="", seed_=204, chain_id_=0)
```

A StanModel instance encapsulates a Stan model instantiated with data.

The constructor a Stan model from the supplied library file path and data file path. If seed or chain_id are supplied, these are used to initialize the RNG used by the model.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L23-L30' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density' href='#BridgeStan.log_density'>#</a>
**`BridgeStan.log_density`** &mdash; *Function*.



```julia
log_density(sm, q; propto=true, jacobian=true)
```

Return the log density of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L346-L353' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient' href='#BridgeStan.log_density_gradient'>#</a>
**`BridgeStan.log_density_gradient`** &mdash; *Function*.



```julia
log_density_gradient(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L418-L430' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian' href='#BridgeStan.log_density_hessian'>#</a>
**`BridgeStan.log_density_hessian`** &mdash; *Function*.



```julia
log_density_hessian(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient and Hessian output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L504-L515' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain' href='#BridgeStan.param_constrain'>#</a>
**`BridgeStan.param_constrain`** &mdash; *Function*.



```julia
param_constrain(sm, theta_unc, out; include_tp=false, include_gq=false)
```

This turns a vector of unconstrained params into constrained parameters and (if `include_tp` and `include_gq` are set, respectively) transformed parameters and generated quantities.

This allocates new memory for the output each call. See `param_constrain!` for a version which allows re-using existing memory.

This is the inverse of `param_unconstrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L217-L229' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain' href='#BridgeStan.param_unconstrain'>#</a>
**`BridgeStan.param_unconstrain`** &mdash; *Function*.



```julia
param_unconstrain(sm, theta)
```

This turns a vector of constrained params into unconstrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_unc_names(sm)`). If structured input is needed, use `param_unconstrain_json`

This allocates new memory for the output each call. See `param_unconstrain!` for a version which allows re-using existing memory.

This is the inverse of `param_constrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L277-L290' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json' href='#BridgeStan.param_unconstrain_json'>#</a>
**`BridgeStan.param_unconstrain_json`** &mdash; *Function*.



```julia
param_unconstrain_json(sm, theta)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

This allocates new memory for the output each call. See `param_unconstrain_json!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L330-L340' class='documenter-source'>source</a><br>

<a id='BridgeStan.name' href='#BridgeStan.name'>#</a>
**`BridgeStan.name`** &mdash; *Function*.



```julia
name(sm)
```

Return the name of the model `sm`


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L79-L83' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_num' href='#BridgeStan.param_num'>#</a>
**`BridgeStan.param_num`** &mdash; *Function*.



```julia
param_num(sm; include_tp=false, include_gq=false)
```

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block of the model. If `include_tp` or `include_gq` are true, items declared in the `transformed parameters` and `generate quantities` blocks are included, respectively.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L94-L103' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_num' href='#BridgeStan.param_unc_num'>#</a>
**`BridgeStan.param_unc_num`** &mdash; *Function*.



```julia
param_unc_num(sm)
```

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num` when variables are declared with constraints. For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L116-L124' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_names' href='#BridgeStan.param_names'>#</a>
**`BridgeStan.param_names`** &mdash; *Function*.



```julia
param_names(sm; include_tp=false, include_gq=false)
```

Return the indexed names of the (constrained) parameters, including transformed parameters and/or generated quantities as indicated.

For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name `"a"`, the vector entry `a[1]` has indexed name `"a.1"` and the matrix entry `a[2, 3]` has indexed names `"a.2.3"`. Parameter order of the output is column major and more generally last-index major for containers.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L134-L145' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_names' href='#BridgeStan.param_unc_names'>#</a>
**`BridgeStan.param_unc_names`** &mdash; *Function*.



```julia
param_unc_names(sm)
```

Return the indexed names of the unconstrained parameters.

For example, a scalar unconstrained parameter `b` has indexed name `b` and a vector entry `b[3]` has indexed name `b.3`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L158-L165' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient!' href='#BridgeStan.log_density_gradient!'>#</a>
**`BridgeStan.log_density_gradient!`** &mdash; *Function*.



```julia
log_density_gradient!(sm, q, out; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out`, and a reference is returned. See `log_density_gradient` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L373-L383' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian!' href='#BridgeStan.log_density_hessian!'>#</a>
**`BridgeStan.log_density_hessian!`** &mdash; *Function*.



```julia
log_density_hessian!(sm, q, out_grad, out_hess; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out_grad` and the Hessian is stored in `out_hess` and references are returned. See `log_density_hessian` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L441-L452' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain!' href='#BridgeStan.param_constrain!'>#</a>
**`BridgeStan.param_constrain!`** &mdash; *Function*.



```julia
param_constrain!(sm, theta_unc, out; include_tp=false, include_gq=false)
```

This turns a vector of unconstrained params into constrained parameters and (if `include_tp` and `include_gq` are set, respectively) transformed parameters and generated quantities.

The result is stored in the vector `out`, and a reference is returned. See `param_constrain` for a version which allocates fresh memory.

This is the inverse of `param_unconstrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L176-L187' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain!' href='#BridgeStan.param_unconstrain!'>#</a>
**`BridgeStan.param_unconstrain!`** &mdash; *Function*.



```julia
param_unconstrain!(sm, theta, out)
```

This turns a vector of constrained params into unconstrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_unc_names(sm)`). If structured input is needed, use `param_unconstrain_json!`

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain` for a version which allocates fresh memory.

This is the inverse of `param_constrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L240-L252' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json!' href='#BridgeStan.param_unconstrain_json!'>#</a>
**`BridgeStan.param_unconstrain_json!`** &mdash; *Function*.



```julia
param_unconstrain_json!(sm, theta, out)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain_json` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/888433c44697bc7076cd1fa1d9f4995da20dd82c/julia/src/BridgeStan.jl#L296-L305' class='documenter-source'>source</a><br>

