#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]
#![allow(dead_code)]
#![allow(clippy::all)]
#![allow(rustdoc::broken_intra_doc_links)]
// Include generated bindings file
include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

impl BridgeStan {
    pub(crate) fn into_library(self) -> libloading::Library {
        self.__library
    }
}
