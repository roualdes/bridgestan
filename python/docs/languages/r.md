# R Interface: bridgestan.R

% The skeleton of this page was made using Roxygen2 and tools::Rd2txt, but it is not automated.
% Maybe it will be one day
% Used:
% roxygen2::roxygenize()
% tools::Rd2txt_options(underline_titles=FALSE, itemBullet="* ", showURLs=TRUE)
% tools::Rd2txt('./man/StanModel.Rd', 'r.txt')


---

## API Reference

### *R6::R6Class* `StanModel`

`R6` Class representing a compiled BridgeStan model.

This model exposes log density, gradient, and Hessian information
as well as constraining and unconstraining transforms.

#### Methods

**Method** `new()`:

Create a Stan Model instace.

_Usage_

```R
StanModel$new(lib, data, rng_seed, chain_id)
```


_Arguments_

  - `lib` A path to a compiled BridgeStan Shared Object file.

  - `data` A path to a JSON data file for the model.

  - `rng_seed` Seed for the RNG in the model object.

  - `chain_id` Used to offset the RNG by a fixed amount.


_Returns_

  A new StanModel.


**Method** `name()`:

Get the name of this StanModel

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

This turns a vector of unconstrained params into constrained
parameters See also `StanModel$param_unconstrain()`, the inverse
of this function.

_Usage_

```R
StanModel$param_constrain(theta_unc, include_tp = FALSE, include_gq = FALSE)
```


_Arguments_

  - `theta_unc` The vector of unconstrained parameters

  - `include_tp` Whether to also output the transformed parameters
      of the model.

  - `include_gq` Whether to also output the generated quantities
      of the model.


_Returns_

  The constrained parameters of the model.


**Method** `param_unconstrain()`:

This turns a vector of constrained params into unconstrained
parameters.

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

  - `theta` The vector of constrained parameters


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
parameters. See also `StanModel$param_unconstrain()`, the
inverse of this function.

_Usage_

```R
StanModel$log_density(theta, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta` The vector of unconstrained parameters

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  The log density.


**Method** `log_density_gradient()`:

Return the log density and gradient of the specified
unconstrained parameters. See also
`StanModel$param_unconstrain()`, the inverse of this function.

_Usage_

```R
StanModel$log_density_gradient(theta, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta` The vector of unconstrained parameters

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  List containing entries `val` (the log density) and `gradient`
  (the gradient).


**Method** `log_density_hessian()`:

Return the log density, gradient, and Hessian of the specified
unconstrained parameters. See also
`StanModel$param_unconstrain()`, the inverse of this function.

_Usage_

```R
StanModel$log_density_hessian(theta, propto = TRUE, jacobian = TRUE)
```


_Arguments_

  - `theta` The vector of unconstrained parameters

  - `propto` If `TRUE`, drop terms which do not depend on the
      parameters.

  - `jacobian` If `TRUE`, include change of variables terms for
      constrained parameters.


_Returns_

  List containing entries `val` (the log density), `gradient`
  (the gradient), and `hessian` (the Hessian).


