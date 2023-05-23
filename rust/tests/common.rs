use std::{
    ffi::CString,
    path::{Path, PathBuf},
};

use bridgestan::{open_library, StanLibrary};

pub fn model_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .join("test_models")
}

/// Load stan library and corresponding data if available
pub fn get_model<S: AsRef<str>>(name: S) -> (StanLibrary, Option<CString>) {
    let name = name.as_ref();
    let mut base = model_dir();
    base.push(name);
    let lib = base.join(format!("{}_model.so", name));
    if !lib.exists() {
        panic!("Could not find compiled model {}", name);
    }
    let lib = open_library(lib).unwrap();

    let data_path = base.join(name).with_extension("data.json");

    if data_path.exists() {
        let contents = std::fs::read(data_path).unwrap();
        (lib, Some(CString::new(contents).unwrap()))
    } else {
        (lib, None)
    }
}
