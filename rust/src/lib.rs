#![doc = include_str!("../README.md")]

mod bs_safe;

#[cfg(feature = "compile-stan-model")]
mod download_compile;

pub(crate) mod ffi;
pub use bs_safe::{open_library, BridgeStanError, Model, Rng, StanLibrary};

#[cfg(feature = "compile-stan-model")]
pub use download_compile::{compile_model, download_bridgestan_src};

pub(crate) const VERSION: &str = env!("CARGO_PKG_VERSION");
