# BridgeStan from Rust

This is a minimal Rust wrapper for BridgeStan.
 It relies on `bindgen`, and assumes you have already
build the `example` program in `../c-example/`
(required to build `NAME_model.so`).

A very simple safe wrapper is sketched, it does
not currently expose all the behavior required to
use bridgestan in full however.

## Usage:

Similar to the c-example, you can set a specific test model to link with `MODEL`


```shell
MODEL=multi cargo r  ../test_models/multi/multi.data.json
```

Should output:

```
The model has 10 parameters.
The model's name is multi_model.
[[-1.0, -2.0, -3.0, -4.0, -5.0, -6.0, -7.0, -8.0, -9.0, -10.0],
* repeated 25 times *
```

These 25 calls to log_density_gradient are done in parallel with threads.


## Example: nuts-rs

We also include an feature to use the BridgeStan wrapper with [nuts-rs](https://github.com/pymc-devs/nuts-rs).
This implements the `CpuLogpFunc` and `LogpError` traits for the BridgeStan struct.

An example is provided to sample and print one of the final draws from the posterior:

```shell
MODEL=multi cargo r -r --features=nuts --example nuts ../test_models/multi/multi.data.json
```

Outputs

```
[-0.7492664338050083, 1.3638668456632483, -0.5250675759468274, -0.2714837242561625, -0.3839224681163139, -1.5989557104812806, -0.19106094532098128, -1.2464839328119341, -0.9932869161133645, -1.5862836535025469]
Done!
```
