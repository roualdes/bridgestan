# Rust Interface

---

## Installation

The BridgeStan Rust client is available on [crates.io](https://crates.io/crates/bridgestan) and via `cargo`:

```shell
cargo add bridgestan
```

A copy of the BridgeStan C++ sources is needed to compile models. This can be downloaded to
`~/.bridgestan/` automatically if you use the `download-bridgestan-src` feature.
Otherwise, it can be downloaded manually (see [Getting Started](../getting-started.rst)).

Note that the system pre-requisites from the [Getting Started guide](../getting-started.rst)
are still required and will not be automatically installed by this method.

## Example Program

An example program is provided alongside the Rust crate in `examples/example.rs`:

<details>
<summary><a>Show example.rs</a></summary>

```{literalinclude} ../../rust/examples/example.rs
:language: Rust
```

</details>


API Reference
-------------

This is also available [on docs.rs](https://docs.rs/bridgestan)

```{include} ./_rust/bridgestan/lib.md
:start-line: 2
```
