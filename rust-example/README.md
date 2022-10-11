# BridgeStan from Rust

This is a minimal port of the `c-example` program
to Rust. It relies on `bindgen`, and assumes you have already
build the `example` program in `../c-example/`
(required to build `libfull_model.so`).

A very simple safe wrapper is sketched, it does
not currently expose all the behavior required to
use bridgestan in full however.

## Usage:

```shell
cargo run
```

Should output:

```
This model's name is "full_model".

It has 1 parameters.
```

Similar to the c-example, you can set a specific test model to link with `MODEL`

```shell
MODEL=multi cargo run ../test_models/multi/multi.data.json
```
This will output
```
This model's name is multi_model.
It has 10 parameters.
```
