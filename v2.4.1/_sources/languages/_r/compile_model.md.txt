### Function `compile_model()`

```r
compile_model(stan_file, stanc_args = NULL, make_args = NULL)
```

#### Arguments

- `stan_file`: A path to a Stan model file.
- `make_args`: A vector of additional arguments to pass to Make. For example, `c('STAN_THREADS=True')` will enable threading for the compiled model. If the same flags are defined in `make/local`, the versions passed here will take precedent.
- `stanc_arg`: A vector of arguments to pass to stanc3. For example, `c('--O1')` will enable compiler optimization level 1.

#### Returns

Path to the compiled model.

Compiles a Stan model.

#### Details

Run BridgeStan's Makefile on a `.stan` file, creating the `.so` used by the StanModel class. This function checks that the path to BridgeStan is valid and will error if not. This can be set with `set_bridgestan_path`.

#### See Also

`set_bridgestan_path()`
