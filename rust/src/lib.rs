#![doc = include_str!("../README.md")]

mod bs_safe;
pub(crate) mod ffi;

pub use bs_safe::{open_library, BridgeStanError, Model, Rng, StanLibrary};
