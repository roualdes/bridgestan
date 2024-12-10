<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./docs/_static/image/logo_w.png">
  <img alt="The BridgeStan logo" src="./docs/_static/image/logo.png" align="right" width=25%>
</picture>

# BridgeStan

[![DOCS](https://img.shields.io/badge/docs-latest-blue)](https://roualdes.github.io/bridgestan/) [![DOI](https://joss.theoj.org/papers/10.21105/joss.05236/status.svg)](https://doi.org/10.21105/joss.05236) [![CI](https://github.com/roualdes/bridgestan/actions/workflows/main.yaml/badge.svg)](https://github.com/roualdes/bridgestan/actions/workflows/main.yaml)

BridgeStan provides efficient in-memory access through Python, Julia,
Rust, and R to the methods of a [Stan](https://mc-stan.org) model, including
log densities, gradients, Hessians, and constraining and unconstraining
transforms.  The motivation was developing inference algorithms in
higher-level languages for arbitrary Stan models.

Stan is a probabilistic programming language for coding statistical
models.  For an introduction to what can be coded in Stan, see the
[*Stan User's Guide*](https://mc-stan.org/docs/stan-users-guide/index.html).

BridgeStan is currently shipping with Stan version 2.36.0

Documentation is available at https://roualdes.github.io/bridgestan/


#### Compatibility

BridgeStan has been tested with the following operating system and C++
compiler combinations.

* Linux: Ubuntu 20.04 with gcc 9.4.0
* Apple: Mac OS X 12.2 with Apple clang 11.0.3
* Microsoft: Windows 10 with gcc MSYS2 5.3.0


## Installing BridgeStan

Installing the core of BridgeStan is as simple as
[installing a C++ toolchain](https://mc-stan.org/docs/cmdstan-guide/installation.html#cpp-toolchain)
(libraries, compiler, and the `make` command), and downloading this
repository. To download the latest development version, you can run

```shell
git clone --recurse-submodules https://github.com/roualdes/bridgestan.git
```

For a full guide on installing, configuring, and using BridgeStan, consult the
[documentation](https://roualdes.github.io/bridgestan/latest/getting-started.html)

## Using BridgeStan

### Compiling a Stan program

To compile the Stan model in `test_models/multi/multi.stan` to a binary
shared object (`.so` file), use the following.

```
$ cd bridgestan
$ make test_models/multi/multi_model.so
```

This will require internet access the first time you run it in order
to download the appropriate Stan compiler for your platform into
`<bridgestan-dir>/bin/stanc[.exe]`

### Example programs

This repository includes examples of calling Stan through BridgeStan
in Python, Julia, R, Rust, and C.

* From Python: [`example.py`](python/example.py)

* From Julia: [`example.jl`](julia/example.jl)

* From R: [`example.r`](R/example.R)

* From Rust: [`example.rs`](rust/examples/example.rs)

* From C: [`example.c`](c-example/example.c)

Examples of other functionality can be found in the `test` folder for each interface.

## Software using BridgeStan

We are aware of the following projects using BridgeStan.

### Julia

- https://github.com/sethaxen/StanLogDensityProblems.jl
- https://github.com/Julia-Tempering/Pigeons.jl
- https://github.com/TuringLang/TuringBenchmarking.jl

### Python

- https://github.com/pymc-devs/nutpie
- https://github.com/UoL-SignalProcessingGroup/retrospectr
- https://github.com/UoL-SignalProcessingGroup/SMC-NUTS


### R

- https://github.com/JTorgander/hmc-sandbox

## Research using BridgeStan

If you use BridgeStan in your research, please consider citing [our JOSS paper](https://joss.theoj.org/papers/10.21105/joss.05236)
and letting us know so we can list your project here.

- [*Verified Density Compilation for a Probabilistic Programming Language*](https://doi.org/10.1145/3591245)
- [*Variational Inference with Gaussian Score Matching*](https://arxiv.org/pdf/2307.07849.pdf)
- [*Stein Π-Importance Sampling*](https://arxiv.org/pdf/2305.10068.pdf)
- [*Batch and match: black-box variational inference with a score-based divergence*](https://arxiv.org/abs/2402.14758)

## Acknowledgements

The Julia and Python APIs were derived from the
[Stan Model Server](https://github.com/bob-carpenter/stan-model-server/)
API, which in turn was derived from
[ReddingStan](https://github.com/dmuck/redding-stan).

Thanks to Sebastian Weber (GitHub [@wds15](https://github.com/wds15))
for enabling multi-threaded calls from Julia to a single Stan model instance.

Thanks to Adrian Seyboldt (GitHub [@aseyboldt](https://github.com/aseyboldt))
for providing the Rust wrapper.
