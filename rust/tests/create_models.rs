use std::{
    f64::consts::PI,
    ffi::CString,
    path::{Path, PathBuf},
};

use approx::assert_ulps_eq;
use bridgestan::{open_library, BridgeStanError, Model, StanLibrary};

fn model_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("test_models")
}

/// Load stan library and corresponding data if available
fn get_model<S: AsRef<str>>(name: S) -> (StanLibrary, Option<CString>) {
    let name = name.as_ref();
    let mut base = model_dir();
    base.push(name);
    let lib = base.join(format!("{}_model.so", name));
    if !lib.exists() {
        panic!("Could not find compiled model {}", name);
    }
    let lib = open_library(lib).unwrap_or_else(|_| panic!("Could not open library {}", name,));

    let data_path = base.join(name).with_extension("data.json");

    if data_path.exists() {
        let contents = std::fs::read(data_path).unwrap();
        (lib, Some(CString::new(contents).unwrap()))
    } else {
        (lib, None)
    }
}

#[test]
fn create_all() {
    let base = model_dir();
    for path in base.read_dir().unwrap() {
        let path = path.unwrap().path();
        let name = path.file_name().unwrap().to_str().unwrap();

        if (name == "logistic") | (name == "regression") | (name == "syntax_error") {
            continue;
        }

        let (lib, data) = get_model(name);
        // Create the model with a reference
        let Ok(model) = Model::new(&lib, data.as_ref(), 42) else {
            // Only those two models should fail to create.
            assert!((name == "ode") | (name == "throw_data"));
            continue;
        };
        assert!(model.name().unwrap().contains(name));
    }
}

#[test]
fn throw_data() {
    let (lib, data) = get_model("throw_data");
    let Err(err) = Model::new(&lib, data, 42) else {
        panic!("throw_data model should not successfully be created.");
    };

    let BridgeStanError::ConstructFailedError(msg) = err else {
        panic!("Creating throw_data model return an unexpected error");
    };
    assert!(msg.contains("find this text: datafails"));
}

#[test]
#[should_panic(expected = "number of parameters")]
fn bad_arglength() {
    let (lib, data) = get_model("stdnormal");
    let model = Model::new(&lib, data, 42).unwrap();
    let theta = vec![];
    let mut grad = vec![];
    let _ = model.log_density_gradient(&theta[..], true, true, &mut grad[..]);
}

#[test]
fn logp_gradient() {
    let (lib, data) = get_model("stdnormal");
    let model = Model::new(&lib, data, 42).unwrap();
    let theta = vec![1f64];
    let mut grad = vec![0f64];
    let logp = model
        .log_density_gradient(&theta[..], false, true, &mut grad[..])
        .unwrap();
    assert_ulps_eq!(logp, (2. * PI).sqrt().recip().ln() - 0.5);
    assert_ulps_eq!(grad[0], -1f64);
}
