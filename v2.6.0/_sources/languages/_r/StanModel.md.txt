### StanModel

R6 Class representing a compiled BridgeStan model.

This model exposes log density, gradient, and Hessian information as well as constraining and unconstraining transforms.

#### Methods

##### Method `new()`

Create a Stan Model instance.

###### Usage

```
StanModel$new(
  lib,
  data,
  seed,
  stanc_args = NULL,
  make_args = NULL,
  warn = TRUE
)
```

 

###### Arguments

- **`lib`**: A path to a compiled BridgeStan Shared Object file or a .stan file (will be compiled).
- **`data`**: Either a JSON string literal, a path to a data file in JSON format ending in ".json", or the empty string.
- **`seed`**: Seed for the RNG used in constructing the model.
- **`stanc_args`**: A list of arguments to pass to stanc3 if the model is not already compiled.
- **`make_args`**: A list of additional arguments to pass to Make if the model is not already compiled.
- **`warn`**: If false, the warning about re-loading the same shared object is suppressed.

 

###### Returns

A new StanModel.

 

 

 

##### Method `name()`

Get the name of this StanModel.

###### Usage

```
StanModel$name()
```

 

###### Returns

A character vector of the name.

 

 

 

##### Method `model_info()`

Get compile information about this Stan model.

###### Usage

```
StanModel$model_info()
```

 

###### Returns

A character vector of the Stan version and important flags.

 

 

 

##### Method `model_version()`

Get the version of BridgeStan used in the compiled model.

###### Usage

```
StanModel$model_version()
```

 

 

 

 

##### Method `param_names()`

Return the indexed names of the (constrained) parameters. For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name "a", the vector entry `a[1]` has indexed name "a.1" and the matrix entry `a[2, 3]` has indexed name "a.2.3". Parameter order of the output is column major and more generally last-index major for containers.

###### Usage

```
StanModel$param_names(include_tp = FALSE, include_gq = FALSE)
```

 

###### Arguments

- **`include_tp`**: Whether to include variables from transformed parameters.
- **`include_gq`**: Whether to include variables from generated quantities.

 

###### Returns

A list of character vectors of the names.

 

 

 

##### Method `param_unc_names()`

Return the indexed names of the unconstrained parameters. For containers, indexes are separated by periods (.).

For example, the scalar `a` has indexed name "a", the vector entry `a[1]` has indexed name "a.1" and the matrix entry `a[2, 3]` has indexed name "a.2.3". Parameter order of the output is column major and more generally last-index major for containers.

###### Usage

```
StanModel$param_unc_names()
```

 

###### Returns

A list of character vectors of the names.

 

 

 

##### Method `param_num()`

Return the number of (constrained) parameters in the model.

###### Usage

```
StanModel$param_num(include_tp = FALSE, include_gq = FALSE)
```

 

###### Arguments

- **`include_tp`**: Whether to include variables from transformed parameters.
- **`include_gq`**: Whether to include variables from generated quantities.

 

###### Returns

The number of parameters in the model.

 

 

 

##### Method `param_unc_num()`

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num` when variables are declared with constraints. For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.

###### Usage

```
StanModel$param_unc_num()
```

 

###### Returns

The number of parameters in the model.

 

 

 

##### Method `param_constrain()`

Returns a vector of constrained parameters given the unconstrained parameters. See also `StanModel$param_unconstrain()`, the inverse of this function.

###### Usage

```
StanModel$param_constrain(
  theta_unc,
  include_tp = FALSE,
  include_gq = FALSE,
  rng
)
```

 

###### Arguments

- **`theta_unc`**: The vector of unconstrained parameters.
- **`include_tp`**: Whether to also output the transformed parameters of the model.
- **`include_gq`**: Whether to also output the generated quantities of the model.
- **`rng`**: The random number generator to use if `include_gq` is `TRUE`. See `StanModel$new_rng()`.

 

###### Returns

The constrained parameters of the model.

 

 

 

##### Method `new_rng()`

Create a new persistent PRNG object for use in `param_constrain()`.

###### Usage

```
StanModel$new_rng(seed)
```

 

###### Arguments

- **`seed`**: The seed for the PRNG.

 

###### Returns

A `StanRNG` object.

 

 

 

##### Method `param_unconstrain()`

Returns a vector of unconstrained parameters give the constrained parameters.

It is assumed that these will be in the same order as internally represented by the model (e.g., in the same order as `StanModel$param_names()`). If structured input is needed, use `StanModel$param_unconstrain_json()`. See also `StanModel$param_constrain()`, the inverse of this function.

###### Usage

```
StanModel$param_unconstrain(theta)
```

 

###### Arguments

- **`theta`**: The vector of constrained parameters.

 

###### Returns

The unconstrained parameters of the model.

 

 

 

##### Method `param_unconstrain_json()`

This accepts a JSON string of constrained parameters and returns the unconstrained parameters.

The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).

###### Usage

```
StanModel$param_unconstrain_json(json)
```

 

###### Arguments

- **`json`**: Character vector containing a string representation of JSON data.

 

###### Returns

The unconstrained parameters of the model.

 

 

 

##### Method `log_density()`

Return the log density of the specified unconstrained parameters.

###### Usage

```
StanModel$log_density(theta_unc, propto = TRUE, jacobian = TRUE)
```

 

###### Arguments

- **`theta_unc`**: The vector of unconstrained parameters.
- **`propto`**: If `TRUE`, drop terms which do not depend on the parameters.
- **`jacobian`**: If `TRUE`, include change of variables terms for constrained parameters.

 

###### Returns

The log density.

 

 

 

##### Method `log_density_gradient()`

Return the log density and gradient of the specified unconstrained parameters.

###### Usage

```
StanModel$log_density_gradient(theta_unc, propto = TRUE, jacobian = TRUE)
```

 

###### Arguments

- **`theta_unc`**: The vector of unconstrained parameters.
- **`propto`**: If `TRUE`, drop terms which do not depend on the parameters.
- **`jacobian`**: If `TRUE`, include change of variables terms for constrained parameters.

 

###### Returns

List containing entries `val` (the log density) and `gradient` (the gradient).

 

 

 

##### Method `log_density_hessian()`

Return the log density, gradient, and Hessian of the specified unconstrained parameters.

###### Usage

```
StanModel$log_density_hessian(theta_unc, propto = TRUE, jacobian = TRUE)
```

 

###### Arguments

- **`theta_unc`**: The vector of unconstrained parameters.
- **`propto`**: If `TRUE`, drop terms which do not depend on the parameters.
- **`jacobian`**: If `TRUE`, include change of variables terms for constrained parameters.

 

###### Returns

List containing entries `val` (the log density), `gradient` (the gradient), and `hessian` (the Hessian).

 

 

 

##### Method `log_density_hessian_vector_product()`

Return the log density and the product of the Hessian with the specified vector.

###### Usage

```
StanModel$log_density_hessian_vector_product(
  theta_unc,
  v,
  propto = TRUE,
  jacobian = TRUE
)
```

 

###### Arguments

- **`theta_unc`**: The vector of unconstrained parameters.
- **`v`**: The vector to multiply the Hessian by.
- **`propto`**: If `TRUE`, drop terms which do not depend on the parameters.
- **`jacobian`**: If `TRUE`, include change of variables terms for constrained parameters.

 

###### Returns

List containing entries `val` (the log density) and `Hvp` (the hessian-vector product).
