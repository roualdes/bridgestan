
<a id='Julia-Interface'></a>

<a id='Julia-Interface-1'></a>

# Julia Interface


% NB: If you are reading this file in docs/languages, you are reading a generated output!
% This should be apparent due to the html tags everywhere.
% If you are reading this in julia/docs/src, you are reading the true source!
% Please only make edits in the later file, since the first is DELETED each re-build.


---


<a id='Installation'></a>

<a id='Installation-1'></a>

## Installation


<a id='From-JuliaRegistries'></a>

<a id='From-JuliaRegistries-1'></a>

### From JuliaRegistries


BridgeStan is registered on JuliaRegistries each release.


```julia
] add BridgeStan
```


The first time you compile a model, the BridgeStan source code for your current version will be downloaded as an [Artifact](https://pkgdocs.julialang.org/v1/artifacts/). If you prefer to use a source distribution of BridgeStan, consult the following section.


Note that the system pre-requisites from the [Getting Started guide](../getting-started.rst) are still required and will not be automatically installed by this method.


<a id='From-Source'></a>

<a id='From-Source-1'></a>

### From Source


This section assumes you have followed the [Getting Started guide](../getting-started.rst) to install BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.


To install the Julia interface, you can either install it directly from Github by running the following inside a Julia REPL


```julia
] add https://github.com/roualdes/bridgestan.git:julia
```


Or, since you have already downloaded the repository, you can run


```julia
] dev julia/
```


from the BridgeStan folder.


To use the BridgeStan source you've manually downloaded instead of one the package will download for you, you must use [`set_bridgestan_path()`](BridgeStan.set_bridgestan_path!) or the `$BRIDGESTAN` environment variable.


Note that the Julia package depends on Julia 1.8+.


<a id='Example-Program'></a>

<a id='Example-Program-1'></a>

## Example Program


An example program is provided alongside the Julia interface code in `example.jl`:


<details>
<summary><a>Show example.jl</a></summary>


```{literalinclude} ../../julia/example.jl
:language: julia
```


</details>


<a id='API-Reference'></a>

<a id='API-Reference-1'></a>

## API Reference


<a id='StanModel-interface'></a>

<a id='StanModel-interface-1'></a>

### StanModel interface

<a id='BridgeStan.StanModel' href='#BridgeStan.StanModel'>#</a>
**`BridgeStan.StanModel`** &mdash; *Type*.



```julia
StanModel(lib, data="", seed=204; stanc_args=[], make_args=[], warn=true)
```

A StanModel instance encapsulates a Stan model instantiated with data.

Construct a Stan model from the supplied library file path and data. If lib is a path to a file ending in `.stan`, this will first compile the model.  Compilation occurs if no shared object file exists for the supplied Stan file or if a shared object file exists and the Stan file has changed since last compilation.  This is equivalent to calling `compile_model` and then the constructor of `StanModel`. If `warn` is false, the warning about re-loading the same shared objects is suppressed.

Data should either be a string containing a JSON string literal, a path to a data file ending in `.json`, or the empty string.

If seed is supplied, it is used to initialize the RNG used by the model's constructor.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L15-L32' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density' href='#BridgeStan.log_density'>#</a>
**`BridgeStan.log_density`** &mdash; *Function*.



```julia
log_density(sm, q; propto=true, jacobian=true)
```

Return the log density of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L501-L508' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient' href='#BridgeStan.log_density_gradient'>#</a>
**`BridgeStan.log_density_gradient`** &mdash; *Function*.



```julia
log_density_gradient(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L584-L596' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian' href='#BridgeStan.log_density_hessian'>#</a>
**`BridgeStan.log_density_hessian`** &mdash; *Function*.



```julia
log_density_hessian(sm, q; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the gradient and Hessian output each call. See `log_density_gradient!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L671-L682' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian_vector_product' href='#BridgeStan.log_density_hessian_vector_product'>#</a>
**`BridgeStan.log_density_hessian_vector_product`** &mdash; *Function*.



```julia
log_density_hessian_vector_product(sm, q, v; propto=true, jacobian=true)
```

Returns log density and the product of the Hessian of the log density with the vector `v` at the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

This allocates new memory for the output each call. See `log_density_hessian_vector_product!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L753-L764' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain' href='#BridgeStan.param_constrain'>#</a>
**`BridgeStan.param_constrain`** &mdash; *Function*.



```julia
param_constrain(sm, theta_unc, out; include_tp=false, include_gq=false, rng=nothing)
```

Returns a vector constrained parameters given unconstrained parameters. Additionally (if `include_tp` and `include_gq` are set, respectively) returns transformed parameters and generated quantities.

If `include_gq` is `true`, then `rng` must be provided. See `StanRNG` for details on how to construct RNGs.

This allocates new memory for the output each call. See `param_constrain!` for a version which allows re-using existing memory.

This is the inverse of `param_unconstrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L358-L373' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain' href='#BridgeStan.param_unconstrain'>#</a>
**`BridgeStan.param_unconstrain`** &mdash; *Function*.



```julia
param_unconstrain(sm, theta)
```

Returns a vector of unconstrained params give the constrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_unc_names(sm)`). If structured input is needed, use `param_unconstrain_json`

This allocates new memory for the output each call. See `param_unconstrain!` for a version which allows re-using existing memory.

This is the inverse of `param_constrain`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L430-L443' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json' href='#BridgeStan.param_unconstrain_json'>#</a>
**`BridgeStan.param_unconstrain_json`** &mdash; *Function*.



```julia
param_unconstrain_json(sm, theta)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

This allocates new memory for the output each call. See `param_unconstrain_json!` for a version which allows re-using existing memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L485-L495' class='documenter-source'>source</a><br>

<a id='BridgeStan.name' href='#BridgeStan.name'>#</a>
**`BridgeStan.name`** &mdash; *Function*.



```julia
name(sm)
```

Return the name of the model `sm`


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L164-L168' class='documenter-source'>source</a><br>

<a id='BridgeStan.model_info' href='#BridgeStan.model_info'>#</a>
**`BridgeStan.model_info`** &mdash; *Function*.



```julia
model_info(sm)
```

Return information about the model `sm`.

This includes the Stan version and important compiler flags.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L179-L186' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_num' href='#BridgeStan.param_num'>#</a>
**`BridgeStan.param_num`** &mdash; *Function*.



```julia
param_num(sm; include_tp=false, include_gq=false)
```

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block of the model. If `include_tp` or `include_gq` are true, items declared in the `transformed parameters` and `generate quantities` blocks are included, respectively.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L209-L218' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_num' href='#BridgeStan.param_unc_num'>#</a>
**`BridgeStan.param_unc_num`** &mdash; *Function*.



```julia
param_unc_num(sm)
```

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num` when variables are declared with constraints. For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L231-L239' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_names' href='#BridgeStan.param_names'>#</a>
**`BridgeStan.param_names`** &mdash; *Function*.



```julia
param_names(sm; include_tp=false, include_gq=false)
```

Return the indexed names of the (constrained) parameters, including transformed parameters and/or generated quantities as indicated.

For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name `"a"`, the vector entry `a[1]` has indexed name `"a.1"` and the matrix entry `a[2, 3]` has indexed names `"a.2.3"`. Parameter order of the output is column major and more generally last-index major for containers.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L249-L260' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_names' href='#BridgeStan.param_unc_names'>#</a>
**`BridgeStan.param_unc_names`** &mdash; *Function*.



```julia
param_unc_names(sm)
```

Return the indexed names of the unconstrained parameters.

For example, a scalar unconstrained parameter `b` has indexed name `b` and a vector entry `b[3]` has indexed name `b.3`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L273-L280' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_gradient!' href='#BridgeStan.log_density_gradient!'>#</a>
**`BridgeStan.log_density_gradient!`** &mdash; *Function*.



```julia
log_density_gradient!(sm, q, out; propto=true, jacobian=true)
```

Returns a tuple of the log density and gradient of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out`, and a reference is returned. See `log_density_gradient` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L530-L540' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian!' href='#BridgeStan.log_density_hessian!'>#</a>
**`BridgeStan.log_density_hessian!`** &mdash; *Function*.



```julia
log_density_hessian!(sm, q, out_grad, out_hess; propto=true, jacobian=true)
```

Returns a tuple of the log density, gradient, and Hessian  of the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The gradient is stored in the vector `out_grad` and the Hessian is stored in `out_hess` and references are returned. See `log_density_hessian` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L607-L618' class='documenter-source'>source</a><br>

<a id='BridgeStan.log_density_hessian_vector_product!' href='#BridgeStan.log_density_hessian_vector_product!'>#</a>
**`BridgeStan.log_density_hessian_vector_product!`** &mdash; *Function*.



```julia
log_density_hessian_vector_product!(sm, q, v, out; propto=true, jacobian=true)
```

Returns log density and the product of the Hessian of the log density with the vector `v` at the specified unconstrained parameters.

This calculation drops constant terms that do not depend on the parameters if `propto` is `true` and includes change of variables terms for constrained parameters if `jacobian` is `true`.

The product is stored in the vector `out` and a reference is returned. See `log_density_hessian_vector_product` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L695-L706' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_constrain!' href='#BridgeStan.param_constrain!'>#</a>
**`BridgeStan.param_constrain!`** &mdash; *Function*.



```julia
param_constrain!(sm, theta_unc, out; include_tp=false, include_gq=false, rng=nothing)
```

Returns a vector constrained parameters given unconstrained parameters. Additionally (if `include_tp` and `include_gq` are set, respectively) returns transformed parameters and generated quantities.

If `include_gq` is `true`, then `rng` must be provided. See `StanRNG` for details on how to construct RNGs.

The result is stored in the vector `out`, and a reference is returned. See `param_constrain` for a version which allocates fresh memory.

This is the inverse of `param_unconstrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L291-L305' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain!' href='#BridgeStan.param_unconstrain!'>#</a>
**`BridgeStan.param_unconstrain!`** &mdash; *Function*.



```julia
param_unconstrain!(sm, theta, out)
```

Returns a vector of unconstrained params give the constrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `param_names(sm)`). If structured input is needed, use `param_unconstrain_json!`

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain` for a version which allocates fresh memory.

This is the inverse of `param_constrain!`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L392-L404' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unconstrain_json!' href='#BridgeStan.param_unconstrain_json!'>#</a>
**`BridgeStan.param_unconstrain_json!`** &mdash; *Function*.



```julia
param_unconstrain_json!(sm, theta, out)
```

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

The result is stored in the vector `out`, and a reference is returned. See `param_unconstrain_json` for a version which allocates fresh memory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L449-L458' class='documenter-source'>source</a><br>

<a id='BridgeStan.StanRNG' href='#BridgeStan.StanRNG'>#</a>
**`BridgeStan.StanRNG`** &mdash; *Type*.



```julia
StanRNG(sm::StanModel, seed)
```

Construct a StanRNG instance from a `StanModel` instance and a seed.

This can be used in the `param_constrain` and `param_constrain!` methods when using the generated quantities block.

This object is not thread-safe, one should be created per thread.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L106-L115' class='documenter-source'>source</a><br>

<a id='BridgeStan.new_rng' href='#BridgeStan.new_rng'>#</a>
**`BridgeStan.new_rng`** &mdash; *Function*.



```julia
new_rng(sm::StanModel, seed)
```

Construct a StanRNG instance from a `StanModel` instance and a seed.  This function is a wrapper around the constructor `StanRNG`.

This can be used in the `param_constrain` and `param_constrain!` methods when using the generated quantities block.

The StanRNG object created is not thread-safe, one should be created per thread.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/model.jl#L151-L161' class='documenter-source'>source</a><br>


<a id='Compilation-utilities'></a>

<a id='Compilation-utilities-1'></a>

### Compilation utilities

<a id='BridgeStan.compile_model' href='#BridgeStan.compile_model'>#</a>
**`BridgeStan.compile_model`** &mdash; *Function*.



```julia
compile_model(stan_file; stanc_args=[], make_args=[])
```

Run BridgeStan’s Makefile on a `.stan` file, creating the `.so` used by StanModel and return a path to the compiled library. Arguments to `stanc3` can be passed as a vector, for example `["--O1"]` enables level 1 compiler optimizations. Additional arguments to `make` can be passed as a vector, for example `["STAN_THREADS=true"]` enables the model's threading capabilities. If the same flags are defined in `make/local`, the versions passed here will take precedent.

This function checks that the path to BridgeStan is valid and will error if it is not. This can be set with `set_bridgestan_path!()`.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L47-L60' class='documenter-source'>source</a><br>

<a id='BridgeStan.get_bridgestan_path' href='#BridgeStan.get_bridgestan_path'>#</a>
**`BridgeStan.get_bridgestan_path`** &mdash; *Function*.



```julia
get_bridgestan_path() -> String
```

Return the path the the BridgeStan directory.

If the environment variable `BRIDGESTAN` is set, this will be returned. Otherwise, this function downloads an artifact containing the BridgeStan repository and returns the path to the extracted directory.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L6-L14' class='documenter-source'>source</a><br>

<a id='BridgeStan.set_bridgestan_path!' href='#BridgeStan.set_bridgestan_path!'>#</a>
**`BridgeStan.set_bridgestan_path!`** &mdash; *Function*.



```julia
set_bridgestan_path!(path)
```

Set the path BridgeStan.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/main/julia/src/compile.jl#L36-L40' class='documenter-source'>source</a><br>

