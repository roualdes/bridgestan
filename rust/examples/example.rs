use bridgestan::{compile_model, open_library, BridgeStanError, Model};
use std::ffi::CString;
use std::path::{Path, PathBuf};

fn main() {
    if std::env::var("RUST_LOG").is_err() {
        std::env::set_var("RUST_LOG", "bridgestan=info");
    }
    env_logger::init();

    // The path to the Stan model
    let path = Path::new(env!["CARGO_MANIFEST_DIR"])
        .parent()
        .unwrap()
        .join("test_models")
        .join("simple")
        .join("simple.stan");

    // You can manually set the BridgeStan src path or
    // automatically download it
    let bs_path: PathBuf = "..".into();
    // let bs_path = bridgestan::download_bridgestan_src().unwrap();

    // The path to the compiled model
    let path =
        compile_model(&bs_path, &path, vec![], vec![]).expect("Could not compile Stan model.");
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
    let logp = model
        .log_density_gradient(&point[..], true, true, &mut gradient_out[..])
        .expect("Stan failed to evaluate the logp function.");
    println!("logp: {}\ngrad: {:?}", logp, gradient_out);
}
