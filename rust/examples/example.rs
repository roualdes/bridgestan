use bridgestan::{open_library, BridgeStanError, Model};
use std::ffi::CString;
use std::path::Path;

fn main() {
    // The path to the compiled model.
    // Get for instance from python `bridgestan.compile_model`
    let path = Path::new(env!["CARGO_MANIFEST_DIR"])
        .parent()
        .unwrap()
        .join("test_models/simple/simple_model.so");

    let lib = open_library(path).expect("Could not load compiled stan model.");

    // The dataset as json
    let data = r#"{"N": 7}"#;
    let data = CString::new(data.to_string().into_bytes()).unwrap();

    // The seed is used in case the model contains a transformed data section
    // that uses rng functions.
    let seed = 42;

    let model = match Model::new(&lib, Some(data), seed) {
        Ok(model) => model,
        Err(BridgeStanError::ConstructFailed(msg)) => {
            panic!(
                "Model initialization failed. Error message from stan was {}",
                msg
            )
        }
        _ => {
            panic!("Unexpected error")
        }
    };

    let n_dim = model.param_unc_num();
    assert_eq!(n_dim, 7);
    let point = vec![1f64; n_dim];
    let mut gradient_out = vec![0f64; n_dim];
    let logp = model
        .log_density_gradient(&point[..], true, true, &mut gradient_out[..])
        .expect("Stan failed to evaluate the logp function.");
    println!("logp: {}\ngrad: {:?}", logp, gradient_out);
}
