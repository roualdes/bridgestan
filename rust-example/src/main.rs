#![allow(non_camel_case_types)]
pub mod bs {
    // Include generated bindings file
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

use std::env;
use std::ffi::CStr;
use std::ffi::CString;
use std::str::Utf8Error;

/// Safe wrapper for BridgeStan C functions
#[non_exhaustive]
pub struct StanModel {
    model: *mut bs::model_rng,
}

impl StanModel {
    pub fn new(path: &String, seed: u32, chain_id: u32) -> Result<Self, String> {
        let data = match CString::new(path.as_bytes()) {
            Ok(string) => string,
            Err(_) => return Err("Failed to convert data path to String".to_string()),
        };
        let model = unsafe { bs::construct(data.into_raw(), seed, chain_id) };
        if model.is_null() {
            return Err("Failed to allocate model_rng".to_string());
        }
        Ok(StanModel { model })
    }

    pub fn name(&self) -> Result<&str, Utf8Error> {
        let cstr = unsafe { CStr::from_ptr(bs::name(self.model)) };
        cstr.to_str()
    }

    pub fn param_num(&self, include_tp: bool, include_gq: bool) -> i32 {
        unsafe { bs::param_num(self.model, include_tp as i32, include_gq as i32) }
    }

    // etc, need more functions
    // using vec.as_mut_ptr(), etc
}

impl Drop for StanModel {
    fn drop(&mut self) {
        if unsafe { bs::destruct(self.model) } != 0 {
            panic!("Deallocating model_rng failed")
        }
    }
}

fn main() {
    let data_path = env::args().nth(1).unwrap_or("".to_string());

    let model = StanModel::new(&data_path, 123, 0).unwrap();

    let s = model.name().unwrap();
    println!("The model's name is {}.", s);
    println!(
        "The model has {} parameters.",
        model.param_num(false, false)
    );
}
