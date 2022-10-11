extern crate bindgen;

use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-env-changed=MODEL");

    let model = env::var("MODEL").unwrap_or("full".to_string());

    // Tell cargo to look for shared libraries in the specified directory
    println!("cargo:rustc-link-search=../test_models/{}/", model);
    println!("cargo:rustc-link-arg=-Wl,-rpath=../test_models/{}/", model);

    // shared library.

    println!("cargo:rustc-link-lib={}_model", model);

    println!("cargo:rerun-if-changed=../src/bridgestan.h");

    // The bindgen::Builder is the main entry point
    // to bindgen, and lets you build up options for
    // the resulting bindings.
    let bindings = bindgen::Builder::default()
        .header("../src/bridgestan.h")
        .opaque_type("model")
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .generate()
        .expect("Unable to generate bindings");

    // Write the bindings to the $OUT_DIR/bindings.rs file.
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
