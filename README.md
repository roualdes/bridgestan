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

More documentation is available at https://roualdes.github.io/bridgestan/


#### Compatibility

BridgeStan has been tested with the following operating system and C++
compiler combinations.

* Linux: Ubuntu 20.04 with gcc 9.4.0
* Apple: Mac OS X 12.2 with Apple clang 11.0.3
* Microsoft: Windows 10 with gcc MSYS2 5.3.0


## Installing BridgeStan

### Step 1: Install a C++14 compiler and make

See the section [Prerequisites](#prerequisites) for instructions on
installing a C++ toolchain.

### Step 2: Download BridgeStan

To download BridgeStan into directory `<parent-dir>`, use the following.

```shell
$ cd <parent-dir>
$ git clone --recurse-submodules https://github.com/roualdes/bridgestan.git
```

If you clone without the `--recurse-submodules` argument, you can download the required
submodules with `make stan-update`.

There is no need to build anything up front.

## Using BridgeStan

There is a built-in example that can be used to verify that BridgeStan
is working.

### Compiling the Stan program

To compile the Stan model in `test_models/multi/multi.stan` to a binary
shared object (`.so` file), use the following.

```
$ cd bridgestan
$ make test_models/multi/multi_model.so
```

### Using BridgeStan with Python or Julia

This repository includes examples of calling Stan through BridgeStan
in Python or Julia.

* From Python: [`example.py`](julia/example.py)

* From Julia: [`example.jl`](python/example.jl)

Additional examples can be found in the `test` folder for each interface.

## Custom build instructions

### Custom C++ flags

By default, BridgeStan uses the default compiler flags set from
CmdStan's `makefile`.  To override the defaults or add new flags, create
or edit the file

* local make commands: `<bridgestan dir>/make/local`.

For example, setting the contents of `make/local` to the following
includes compiler flags for optimization level and architecture.

```
# Adding other arbitrary C++ compiler flags
CXXFLAGS+= -O3 -march=native
```

### Custom stanc flags

The Stan Blog post [Options for improving Stan sampling
speed](https://blog.mc-stan.org/2022/08/03/options-for-improving-stan-sampling-speed/)
discusses how Stan speed can be improved with the following Stan
compiler flags.

```
# pedantic mode and level 1 optimization
STANCFLAGS+= --warn-pedantic --O1
```

#### Enabling parallel calls of Stan programs

In order for Python or Julia to be able to call a single Stan model
concurrently from multiple threads or for a Stan model to execute its
own code in parallel, the following flag must be set in `make/local`
or on the command line.

```
# Enable threading
STAN_THREADS=true
```

Note that this flag changes a lot of the internals of the Stan library
and as such, **all models used in the same process** should have the same
setting. Mixing models which had `STAN_THREADS` enabled with those that didn't
will most likely lead to segmentation faults or other crashes.


## Tips

### Sizes and `param_constrain()` and `param_unconstrain()`

For a given vector `q` of unconstrained parameters, the function
`param_constrain()` can return an array with length longer than the
length of `q`.  This happens, for instance, with a `cov_matrix[K]`
parameter.  A covariance matrix has $K \times K$ elements,
but there are only $K + \binom{K}{2}$ parameters in the unconstrained
parameterization (i.e., a Cholesky factor).

### Parameter ordering

Parameters are ordered for I/O in the same order they are declared in
the underlying Stan program. The `param_names()` and `param_unc_names()`
functions give the canonical orderings for constrained and unconstrained
parameters respectively.

### Hessian calculations

By default, Hessians in BridgeStan are calculated using central finite differences.
This is because not all Stan models support the nested autodiff required for Hessians
to be computed directly, particularly models which use implicit functions like the `algebra_solver`
or ODE integrators.

If your Stan model does not use these features, you can enable autodiff Hessians by
setting the compile-time flag `BRIDGESTAN_AD_HESSIAN=true` in the invocation to `make`.
This can be set in `make/local` if you wish to use it by default.

This value is reported by the `model_info` function if you would like to check at run time
whether Hessians are computed with nested autodiff or with finite differences.

## Prerequisites

### Prereq: Julia, Python, *or* R

To use BridgeStan from Julia 1.8+, Python 3.9+, or R 3+, you will need to have those
languages installed.

The interfaces may depend on different packages in their respective languages.

### Prereq: C++ toolchain

Stan requires a C++ tool chain consisting of

* A C++11 compiler
* The Gnu `make` utility for \*nix *or* `mingw32-make` for Windows

Here are complete instructions by platform for installing both, from the CmdStan installation instructions.

* [C++ tool chain installation](https://mc-stan.org/docs/cmdstan-guide/cmdstan-installation.html#cpp-toolchain)


### Ensuring tools are built/imported

At this point, everything should be in place to build and execute a
Stan program.  We will assume BridgeStan is checked out in `<bridgestan-dir>`.

To verify the compiler chain is installed correctly, the following
should run without errors.

```shell
cd <bridgestan-dir>
make test_models/multi/multi_model.so
```

This will require internet access the first time you run it in order
to download the appropriate Stan compiler for your platform into
`<bridgestan-dir>/bin/stanc[.exe]`

## Acknowledgements

The Julia and Python APIs were derived from the
[Stan Model Server](https://github.com/bob-carpenter/stan-model-server/)
API, which in turn was derived from
[ReddingStan](https://github.com/dmuck/redding-stan).

Thanks to Sebastian Weber (GitHub [@wds15](https://github.com/wds15))
for enabling multi-threaded calls from Julia to a single Stan model instance.
