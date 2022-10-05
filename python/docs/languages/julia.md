
<a id='Julia-Interface:-BridgeStan.jl'></a>

<a id='Julia-Interface:-BridgeStan.jl-1'></a>

# Julia Interface: BridgeStan.jl


% NB: If you are reading this file in python/docs/languages, you are reading a generated output!
% This should be apparent due to the html tags everywhere.
% If you are reading this in julia/docs/src, you are reading the true source!
% Please only make edits in the later file, since the first is DELETED each re-build.


---


<a id='StanModel-interface'></a>

<a id='StanModel-interface-1'></a>

## StanModel interface

<a id='BridgeStan.StanModel' href='#BridgeStan.StanModel'>#</a>
**`BridgeStan.StanModel`** &mdash; *Type*.



```julia
StanModel(lib, datafile="", seed=204, chain_id=0)
```

A StanModel instance encapsulates a Stan model instantiated with data.

The constructor a Stan model from the supplied library file path and data file path. If seed or chain_id are supplied, these are used to initialize the RNG used by the model.

```
StanModel(;stan_file, data="", seed=204, chain_id=0)
```

Construct a StanModel instance from a `.stan` file, compiling if necessary.

This is equivalent to calling `compile_model` and then the original constructor of StanModel.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L4-L17' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density' href='#BridgeStan.log_density'>#</a>
**`BridgeStan.log_density`** &mdash; *Function*.



```julia
log_density(sm, q; propto=true, jacobian=true)
```

Return the log density of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L351-L358' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient' href='#BridgeStan.log_density_gradient'>#</a>
**`BridgeStan.log_density_gradient`** &mdash; *Function*.



```julia
log_density_gradient(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L423-L435' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian' href='#BridgeStan.log_density_hessian'>#</a>
**`BridgeStan.log_density_hessian`** &mdash; *Function*.



```julia
log_density_hessian(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient and Hessian output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L509-L520' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain' href='#BridgeStan.param_constrain'>#</a>
**`BridgeStan.param_constrain`** &mdash; *Function*.



```julia
param_constrain(sm, theta_unc, out; include_tp=false, include_gq=false)
```

This turns a vector of unconstrained params into constrained parameters and (if `include_tp` and `include_gq` are set, respectively) transformed parameters and generated quantities.

This allocates new memory for the output each call. See `param_constrain!` for a version which allows re-using existing memory.

This is the inverse of `param_unconstrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L222-L234' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain' href='#BridgeStan.param_unconstrain'>#</a>
**`BridgeStan.param_unconstrain`** &mdash; *Function*.



```julia
param_unconstrain(sm, theta)
```

This turns a vector of constrained params into unconstrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_unc_names(sm)`). If structured input is needed, use `param_unconstrain_json`

This allocates new memory for the output each call. See `param_unconstrain!` for a version which allows re-using existing memory.

This is the inverse of `param_constrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L282-L295' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json' href='#BridgeStan.param_unconstrain_json'>#</a>
**`BridgeStan.param_unconstrain_json`** &mdash; *Function*.



```julia
param_unconstrain_json(sm, theta)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

This allocates new memory for the output each call. See `param_unconstrain_json!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L335-L345' class='documenter-source'>source</a><br>

<a id='BridgeStan.name' href='#BridgeStan.name'>#</a>
**`BridgeStan.name`** &mdash; *Function*.



```julia
name(sm)
```

Return the name of the model `sm`


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L66-L70' class='documenter-source'>source</a><br>

<a id='BridgeStan.model_info' href='#BridgeStan.model_info'>#</a>
**`BridgeStan.model_info`** &mdash; *Function*.



```julia
model_info(sm)
```

Return information about the model `sm`.

This includes the Stan version and important compiler flags.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L81-L88' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_num' href='#BridgeStan.param_num'>#</a>
**`BridgeStan.param_num`** &mdash; *Function*.



```julia
param_num(sm; include_tp=false, include_gq=false)
```

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block of the model. If `include_tp` or `include_gq` are true, items declared in the `transformed parameters` and `generate quantities` blocks are included, respectively.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L99-L108' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_num' href='#BridgeStan.param_unc_num'>#</a>
**`BridgeStan.param_unc_num`** &mdash; *Function*.



```julia
param_unc_num(sm)
```

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num` when variables are declared with constraints. For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L121-L129' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_names' href='#BridgeStan.param_names'>#</a>
**`BridgeStan.param_names`** &mdash; *Function*.



```julia
param_names(sm; include_tp=false, include_gq=false)
```

Return the indexed names of the (constrained) parameters, including transformed parameters and/or generated quantities as indicated.

For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name `"a"`, the vector entry `a[1]` has indexed name `"a.1"` and the matrix entry `a[2, 3]` has indexed names `"a.2.3"`. Parameter order of the output is column major and more generally last-index major for containers.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L139-L150' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_names' href='#BridgeStan.param_unc_names'>#</a>
**`BridgeStan.param_unc_names`** &mdash; *Function*.



```julia
param_unc_names(sm)
```

Return the indexed names of the unconstrained parameters.

For example, a scalar unconstrained parameter `b` has indexed name `b` and a vector entry `b[3]` has indexed name `b.3`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L163-L170' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient!' href='#BridgeStan.log_density_gradient!'>#</a>
**`BridgeStan.log_density_gradient!`** &mdash; *Function*.



```julia
log_density_gradient!(sm, q, out; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out`, and a reference is returned. See `log_density_gradient` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L378-L388' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian!' href='#BridgeStan.log_density_hessian!'>#</a>
**`BridgeStan.log_density_hessian!`** &mdash; *Function*.



```julia
log_density_hessian!(sm, q, out_grad, out_hess; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out_grad` and the Hessian is stored in `out_hess` and references are returned. See `log_density_hessian` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L446-L457' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain!' href='#BridgeStan.param_constrain!'>#</a>
**`BridgeStan.param_constrain!`** &mdash; *Function*.



```julia
param_constrain!(sm, theta_unc, out; include_tp=false, include_gq=false)
```

This turns a vector of unconstrained params into constrained parameters and (if `include_tp` and `include_gq` are set, respectively) transformed parameters and generated quantities.

The result is stored in the vector `out`, and a reference is returned. See `param_constrain` for a version which allocates fresh memory.

This is the inverse of `param_unconstrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L181-L192' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain!' href='#BridgeStan.param_unconstrain!'>#</a>
**`BridgeStan.param_unconstrain!`** &mdash; *Function*.



```julia
param_unconstrain!(sm, theta, out)
```

This turns a vector of constrained params into unconstrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_names(sm)`). If structured input is needed, use `param_unconstrain_json!`

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain` for a version which allocates fresh memory.

This is the inverse of `param_constrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L245-L257' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json!' href='#BridgeStan.param_unconstrain_json!'>#</a>
**`BridgeStan.param_unconstrain_json!`** &mdash; *Function*.



```julia
param_unconstrain_json!(sm, theta, out)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain_json` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L301-L310' class='documenter-source'>source</a><br>


<a id='Compilation-utilities'></a>

<a id='Compilation-utilities-1'></a>

## Compilation utilities

<a id='BridgeStan.compile_model' href='#BridgeStan.compile_model'>#</a>
**`BridgeStan.compile_model`** &mdash; *Function*.



```julia
compile_model(stan_file, args=[])
```

Run BridgeStan’s Makefile on a `.stan` file, creating the `.so` used by StanModel and return a path to the compiled library. Additional arguments to `make` can be passed as a vector, for example `["STAN_THREADS=true"]` enables the model's threading capabilities.

This function assumes that the paths to BridgeStan and CmdStan are both valid. These can be set with `set_bridgestan_path!()` and `set_cmdstan_path!()` if their default values do not match your system configuration.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L66-L77' class='documenter-source'>source</a><br>

<a id='BridgeStan.set_bridgestan_path!' href='#BridgeStan.set_bridgestan_path!'>#</a>
**`BridgeStan.set_bridgestan_path!`** &mdash; *Function*.



```julia
set_bridgestan_path!(path)
```

Set the path BridgeStan.

By default this is set to the value of the environment variable `BRIDGESTAN`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L52-L59' class='documenter-source'>source</a><br>

<a id='BridgeStan.set_cmdstan_path!' href='#BridgeStan.set_cmdstan_path!'>#</a>
**`BridgeStan.set_cmdstan_path!`** &mdash; *Function*.



```julia
set_cmdstan_path!(path)
```

Set the path to CmdStan used by BridgeStan.

By default this is set to the value of the environment variable `CMDSTAN`, or to the newest installation available in `~/.cmdstan/`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L36-L43' class='documenter-source'>source</a><br>

