#![doc = include_str!("../README.md")]

mod bs_safe;
mod compile;
#[cfg(feature = "download-bridgestan-src")]
mod download;
pub(crate) mod ffi;

pub use bs_safe::{BridgeStanError, Model, Rng, StanLibrary, open_library};
pub use compile::compile_model;

#[cfg(feature = "download-bridgestan-src")]
pub use download::download_bridgestan_src;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
