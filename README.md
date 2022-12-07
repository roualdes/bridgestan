# BridgeStan

BridgeStan provides efficient in-memory access through Python, Julia,
and R to the methods of a [Stan](https://mc-stan.org) model, including
log densities, gradients, Hessians, and constraining and unconstraining
transforms.  The motivation was developing inference algorithms in
higher-level languages for arbitrary Stan models.

Stan is a probabilistic programming language for coding statistical
models.  For an introduction to what can be coded in Stan, see the
[*Stan User's Guide*](https://mc-stan.org/docs/stan-users-guide/index.html).

BridgeStan is currently shipping with Stan version 2.31.0

Documentation is available at https://roualdes.github.io/bridgestan/


#### Compatibility

BridgeStan has been tested with the following operating system and C++
compiler combinations.

* Linux: Ubuntu 20.04 with gcc 9.4.0
* Apple: Mac OS X 12.2 with Apple clang 11.0.3
* Microsoft: Windows 10 with gcc MSYS2 5.3.0


## Installing BridgeStan

Installing the core of BridgeStan is as simple as
[installing a C++ toolchain](https://mc-stan.org/docs/cmdstan-guide/cmdstan-installation.html#cpp-toolchain)
(libraries, compiler, and the `make` command), and downloading this
repository. To download the latest development version, you can run

```shell
git clone --recurse-submodules https://github.com/roualdes/bridgestan.git
```

For a full guide on installing, configuring, and using BridgeStan, consult the
[documentation](https://roualdes.github.io/bridgestan/getting-started.html)

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
in Python, Julia, R, and C.

* From Python: [`example.py`](julia/example.py)

* From Julia: [`example.jl`](python/example.jl)

* From R: [`example.r`](R/example.R)

* From C: [`example.c`](c-example/example.c)

Examples of other functionality can be found in the `test` folder for each interface.

## Acknowledgements

The Julia and Python APIs were derived from the
[Stan Model Server](https://github.com/bob-carpenter/stan-model-server/)
API, which in turn was derived from
[ReddingStan](https://github.com/dmuck/redding-stan).

Thanks to Sebastian Weber (GitHub [@wds15](https://github.com/wds15))
for enabling multi-threaded calls from Julia to a single Stan model instance.
