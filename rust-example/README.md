# BridgeStan from Rust

This is a minimal port of the `c-example` program
to Rust. It relies on `bindgen`, and assumes you have already
build the `example` program in `../c-example/`
(required to build `libfull_model.so`). No safe
wrapper is provided, the functions must be
called using `unsafe` and treated as such.

## Usage:

```shell
cargo run
```

Should output:

```
This model's name is "full_model".

It has 1 parameters.
```
