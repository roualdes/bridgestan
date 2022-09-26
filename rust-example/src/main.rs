#![allow(non_camel_case_types)]
// Include generated bindings file
include!(concat!(env!("OUT_DIR"), "/bindings.rs"));


use std::ffi::CString;
use std::ffi::CStr;

fn main() {
    unsafe {
        let data = CString::new("").expect("CString::new failed");
        let model = construct(data.into_raw(), 123, 0);
        if model.is_null() {
            panic!("Failed to allocate model");
        }
        println!("This model's name is {:?}.\n", CStr::from_ptr(name(model)));
        println!("It has {:?} parameters.\n", param_num(model, 0, 0));
        if destruct(model) != 0 {
            panic!("Failed to deallocate model");
        }
    }
}
