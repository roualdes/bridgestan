# R Interface

% The skeleton of this page was made using Roxygen2 and tools::Rd2txt, but it is not automated.
% Maybe it will be one day
% Used:
% roxygen2::roxygenize()
% tools::Rd2txt_options(underline_titles=FALSE, itemBullet="* ", showURLs=TRUE)
% tools::Rd2txt('./man/StanModel.Rd', 'r.txt')


---

## Installation

This assumes you have followed the [Getting Started guide](../getting-started.rst)
to install BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.


```R
devtools::install_github("https://github.com/roualdes/bridgestan", subdir="R")
```

Or, since you have already downloaded the repository, you can run

```R
install.packages(file.path(getwd(),"R"), repos=NULL, type="source")
```
from the BridgeStan folder.

Note that the R package depends on R 3+ and R6, and will install R6 if it is not
already installed.

```{note}
Mac users have reported issues when using a copy of R installed from [conda-forge](https://conda-forge.org/). If you encounter an issue, you may need to use R from the official [R project website](https://www.r-project.org/) or a system package manager like `brew`.
```

## Example Program

An example program is provided alongside the R interface code in `example.R`:

<details>
<summary><a>Show example.R</a></summary>

```{literalinclude} ../../R/example.R
:language: R
```

</details>

## API Reference

### *R6::R6Class* `StanModel`

`R6` Class representing a compiled BridgeStan model.

This model exposes log density, gradient, and Hessian information
as well as constraining and unconstraining transforms.

#### Methods

**Method** `new()`:

Create a Stan Model instance.

_Usage_

```R
StanModel$new(lib, data, rng_seed)
```


_Arguments_

  - `lib` A path to a compiled BridgeStan Shared Object file or a .stan file (will be compiled).

  - `data` Either a JSON string literal, a path to a data file in JSON format ending in ".json", or the empty string.

  - `rng_seed` Seed for the RNG used in constructing the model.

  - `stan_args` A list of arguments to pass to stanc3 if the model is not already compiled.

  - `make_args` A list of additional arguments to pass to Make if the model is not already compiled.

_Returns_

  A new StanModel.


**Method** `name()`:

Get the name of this StanModel.

_Usage_

```R
StanModel$name()
```


_Returns_

  A character vector of the name.


**Method** `model_info()`:

Get compile information about this Stan model.

_Usage_

```R
StanModel$model_info()
```


_Returns_

  A character vector of the Stan version and important flags.

**Method** `param_names()`:

Return the indexed names of the (constrained) parameters. For
containers, indexes are separated by periods (.).

For example, the scalar a has indexed name a, the vector entry
a[1] has indexed name a.1 and the matrix entry a[2, 3] has
indexed name a.2.3. Parameter order of the output is column
major and more generally last-index major for containers.

_Usage_

```R
StanModel$param_names(include_tp = FALSE, include_gq = FALSE)
```


_Arguments_

  - `include_tp` Whether to include variables from transformed
      parameters.

  - `include_gq` Whether to include variables from generated
      quantities.


_Returns_

  A list of character vectors of the names.


**Method** `param_unc_names()`:

Return the indexed names of the unconstrained parameters. For
containers, indexes are separated by periods (.).

For example, the scalar a has indexed name a, the vector entry
a[1] has indexed name a.1 and the matrix entry a[2, 3] has
indexed name a.2.3. Parameter order of the output is column
major and more generally last-index major for containers.

_Usage_

```R
StanModel$param_unc_names()
```


_Returns_

  A list of character vectors of the names.


**Method** `param_num()`:

Return the number of (constrained) parameters in the model.

_Usage_

```R
StanModel$param_num(include_tp = FALSE, include_gq = FALSE)
```


_Arguments_

  - `include_tp` Whether to include variables from transformed
      parameters.

  - `include_gq` Whether to include variables from generated
      quantities.


_Returns_

  The number of parameters in the model.


**Method** `param_unc_num()`:

Return the number of unconstrained parameters in the model.
This function is mainly different from `param_num` when
variables are declared with constraints. For example,
`simplex[5]` has a constrained size of 5, but an unconstrained
size of 4.

_Usage_

```R
StanModel$param_unc_num()
```


_Returns_

  The number of parameters in the model.


**Method** `param_constrain()`:

Returns a vector of constrained parameters given the unconstrained parameters. See also `StanModel$param_unconstrain()`, the inverse
of this function.

_Usage_

```R
StanModel$param_constrain(theta_unc, include_tp = FALSE, include_gq = FALSE, rng)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters.

  - `include_tp` Whether to also output the transformed parameters
      of the model.

  - `include_gq` Whether to also output the generated quantities
      of the model.

  - `rng` The random number generator to use if `include_gq` is
      `TRUE`.  See `StanModel$new_rng()`.


_Returns_

  The constrained parameters of the model.


**Method** `new_rng()`:

Create a new persistent PRNG object for use in `param_constrain()`.


_Usage_

```R
StanModel$new_rng(seed)
```


_Arguments_

  - `seed` The seed for the PRNG.

_Returns_

  A `StanRNG` object.


**Method** `param_unconstrain()`:

Returns a vector of unconstrained parameters given the constrained parameters.

It is assumed that these will be in the same order as internally
represented by the model (e.g., in the same order as
`StanModel$param_names()`). If structured input is needed, use
`StanModel$param_unconstrain_json()`. See also
`StanModel$param_constrain()`, the inverse of this function.

_Usage_

```R
StanModel$param_unconstrain(theta)
```


_Arguments_

  - `theta` The vector of constrained parameters.


_Returns_

  The unconstrained parameters of the model.


**Method** `param_unconstrain_json()`:

This accepts a JSON string of constrained parameters and returns
the unconstrained parameters.

The JSON is expected to be in the [JSON Format for
CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

_Usage_

```R
StanModel$param_unconstrain_json(json)
```


_Arguments_

  - `json` Character vector containing a string representation of
      JSON data.


_Returns_

  The unconstrained parameters of the model.


**Method** `log_density()`:

Return the log density of the specified unconstrained
parameters.

_Usage_

```R
StanModel$log_density(theta_unc, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters.

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  The log density.


**Method** `log_density_gradient()`:

Return the log density and gradient of the specified
unconstrained parameters.

_Usage_

```R
StanModel$log_density_gradient(theta_unc, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters.

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  List containing entries `val` (the log density) and `gradient`
  (the gradient).


**Method** `log_density_hessian()`:

Return the log density, gradient, and Hessian of the specified
unconstrained parameters.

_Usage_

```R
StanModel$log_density_hessian(theta_unc, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters.

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  List containing entries `val` (the log density), `gradient`
  (the gradient), and `hessian` (the Hessian).


**Method** `log_density_hessian_vector_product()`:

Return the log density and the product of the Hessian
with the specified vector.

_Usage_

```R
StanModel$log_density_hessian_vector_product(theta_unc, v, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters.

  - `v` The vector to multiply the Hessian by.

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  List containing entries `val` (the log density) and `Hvp`
  (the hessian-vector product).

### Compilation utilities

**Function** `compile_model()`:

Run BridgeStan's Makefile on a `.stan` file, creating the `.so` used by
the StanModel class. This function checks that the path to BridgeStan
is valid and will error if not. This can be set with `set_bridgestan_path()`.

_Usage_
```R
compile_model(stan_file, stanc_args = NULL, make_args = NULL)
```

_Arguments_

  - `stan_file` A path to a Stan model file.

  - `stanc_arg` A vector of arguments to pass to stanc3. For example,
      `c("--O1")` will enable compiler optimization level 1.

  - `make_args` A vector of additional arguments to pass to Make. For example,
      `c("STAN_THREADS=True")` will enable threading for the
      compiled model. If the same flags are defined in
      `make/local`, the versions passed here will take precedent.

_Returns_

  Path to the compiled `.so` file.

**Function** `set_bridgestan_path()`:

Set the path to BridgeStan. This should point to the top-level folder of the repository.

_Usage_
```R
set_bridgestan_path(path)
```
