# BridgeStan from Rust

[*View the BridgeStan documentation on Github Pages*](https://roualdes.github.io/bridgestan/latest/languages/rust.html).

This is a Rust wrapper for [BridgeStan](https://github.com/roualdes/bridgestan). It
allows users to evaluate the log likelihood and related functions for Stan models
natively from Rust.

Internally, it relies on [`bindgen`](https://docs.rs/bindgen/) and
[`libloading`](https://docs.rs/libloading/).

## Compiling the model

The Rust wrapper does not currently have any functionality to compile Stan models.
Compiled shared libraries need to be built manually using `make` or with the Julia
or Python bindings.

For safety reasons all Stan models need to be installed with `STAN_THREADS=true`.
When compiling a model using `make`, set the environment variable:

```bash
STAN_THREADS=true make some_model
```

When compiling a Stan model in python, this has to be specified in the `make_args`
argument:

```python
path = bridgestan.compile_model("stan_model.stan", make_args=["STAN_THREADS=true"])
```

If `STAN_THREADS` was not specified while building the model, the Rust wrapper
will throw an error when loading the model.

## Usage:

Run this example with `cargo run --example=example`.

```rust
use std::ffi::CString;
use std::path::Path;
use bridgestan::{BridgeStanError, Model, open_library};

// The path to the compiled model.
// Get for instance from python `bridgestan.compile_model`
let path = Path::new(env!["CARGO_MANIFEST_DIR"])
    .parent()
    .unwrap()
    .join("test_models/simple/simple_model.so");

let lib = open_library(path).expect("Could not load compiled Stan model.");

// The dataset as json
let data = r#"{"N": 7}"#;
let data = CString::new(data.to_string().into_bytes()).unwrap();

// The seed is used in case the model contains a transformed data section
// that uses rng functions.
let seed = 42;

let model = match Model::new(&lib, Some(data), seed) {
Ok(model) => { model },
Err(BridgeStanError::ConstructFailed(msg)) => {
    panic!("Model initialization failed. Error message from Stan was {}", msg)
},
_ => { panic!("Unexpected error") },
};

let n_dim = model.param_unc_num();
assert_eq!(n_dim, 7);
let point = vec![1f64; n_dim];
let mut gradient_out = vec![0f64; n_dim];
let logp = model.log_density_gradient(&point[..], true, true, &mut gradient_out[..])
    .expect("Stan failed to evaluate the logp function.");
// gradient_out contains the gradient of the logp density
```
