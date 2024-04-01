# Julia Interface

```@raw html
% NB: If you are reading this file in docs/languages, you are reading a generated output!
% This should be apparent due to the html tags everywhere.
% If you are reading this in julia/docs/src, you are reading the true source!
% Please only make edits in the later file, since the first is DELETED each re-build.
```

---

## Installation

### From JuliaRegistries

BridgeStan is registered on JuliaRegistries each release.


```julia
] add BridgeStan
```

The first time you compile a model, the BridgeStan source code for your current version
will be downloaded as an [Artifact](https://pkgdocs.julialang.org/v1/artifacts/). If you
prefer to use a source distribution of BridgeStan, consult the following section.

Note that the system pre-requisites from the [Getting Started guide](../getting-started.rst)
are still required and will not be automatically installed by this method.

### From Source
This section assumes you have followed the [Getting Started guide](../getting-started.rst)
to install BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.

To install the Julia interface, you can either install it directly from Github by running
the following inside a Julia REPL

```julia
] add https://github.com/roualdes/bridgestan.git:julia
```

Or, since you have already downloaded the repository, you can run

```julia
] dev julia/
```

from the BridgeStan folder.

To use the BridgeStan source you've manually downloaded instead of
one the package will download for you, you must use
[`set_bridgestan_path()`](BridgeStan.set_bridgestan_path!) or the `$BRIDGESTAN`
environment variable.

Note that the Julia package depends on Julia 1.8+.

## Example Program

An example program is provided alongside the Julia interface code in `example.jl`:


```@raw html
<details>
<summary><a>Show example.jl</a></summary>
```

```{literalinclude} ../../julia/example.jl
:language: julia
```

```@raw html
</details>
```

## API Reference

### StanModel interface

```@docs
StanModel
log_density
log_density_gradient
log_density_hessian
log_density_hessian_vector_product
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
log_density_hessian_vector_product!
param_constrain!
param_unconstrain!
param_unconstrain_json!
StanRNG
new_rng
```

### Compilation utilities
```@docs
compile_model
get_bridgestan_path
set_bridgestan_path!
```
