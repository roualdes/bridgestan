#![doc = include_str!("../README.md")]

mod bs_safe;
mod download_compile;
pub(crate) mod ffi;

pub use bs_safe::{open_library, BridgeStanError, Model, Rng, StanLibrary};
pub use download_compile::{compile_model, get_bridgestan_src};
