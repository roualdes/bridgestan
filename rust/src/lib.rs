#![doc = include_str!("../README.md")]

mod bs_safe;
mod compile;

#[cfg(feature = "download-bridgestan-src")]
mod download;

pub(crate) mod ffi;
pub use bs_safe::{open_library, BridgeStanError, Model, Rng, StanLibrary};

#[cfg(feature = "download-bridgestan-src")]
pub use download::download_bridgestan_src;

pub use compile::compile_model;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
