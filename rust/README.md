# BridgeStan from Rust

[*View the BridgeStan documentation on Github Pages*](https://roualdes.github.io/bridgestan/latest/languages/rust.html).

This is a Rust wrapper for [BridgeStan](https://github.com/roualdes/bridgestan). It
allows users to evaluate the log likelihood and related functions for Stan models
natively from Rust.

Internally, it relies on [`bindgen`](https://docs.rs/bindgen/) and
[`libloading`](https://docs.rs/libloading/).

## Compiling the model

The Rust wrapper has the ability to compile Stan models by invoking the `make` command through the [`compile_model`] function.

This requires a C++ toolchain and a copy of the BridgeStan source code. The source code can be downloaded automatically by enabling the `download-bridgestan-src` feature and calling [`download_bridgestan_src`]. Alternatively, the path to the BridgeStan source code can be provided manually.

For safety reasons all Stan models need to be built with `STAN_THREADS=true`. This is the default behavior in the `compile_model` function,
but may need to be set manually when compiling the model in other contexts.

If `STAN_THREADS` was not specified while building the model, the Rust wrapper
will throw an error when loading the model.

## Usage

Run this example with `cargo run --example=example`.

```rust
use std::ffi::CString;
use std::path::{Path, PathBuf};
use bridgestan::{BridgeStanError, Model, open_library, compile_model};

// The path to the Stan model
let path = Path::new(env!["CARGO_MANIFEST_DIR"])
    .parent()
    .unwrap()
    .join("test_models/simple/simple.stan");

// You can manually set the BridgeStan src path or
// automatically download it (but remember to
// enable the download-bridgestan-src feature first)
let bs_path: PathBuf = "..".into();
// let bs_path = bridgestan::download_bridgestan_src().unwrap();

// The path to the compiled model
let path = compile_model(&bs_path, &path, &[], &[]).expect("Could not compile Stan model.");
println!("Compiled model: {:?}", path);

let lib = open_library(path).expect("Could not load compiled Stan model.");

// The dataset as json
let data = r#"{"N": 7}"#;
let data = CString::new(data.to_string().into_bytes()).unwrap();

// The seed is used in case the model contains a transformed data section
// that uses rng functions.
let seed = 42;

let model = match Model::new(&lib, Some(data), seed) {
    Ok(model) => model,
    Err(BridgeStanError::ConstructFailed(msg)) => {
        panic!("Model initialization failed. Error message from Stan was {msg}")
    }
    Err(e) => {
        panic!("Unexpected error:\n{e}")
    }
};

let n_dim = model.param_unc_num();
assert_eq!(n_dim, 7);
let point = vec![1f64; n_dim];
let mut gradient_out = vec![0f64; n_dim];
let logp = model.log_density_gradient(&point[..], true, true, &mut gradient_out[..])
    .expect("Stan failed to evaluate the logp function.");
// gradient_out contains the gradient of the logp density
```
