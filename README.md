# BridgeStan

This library provides a bridge from a Stan program to Julia or Python via C, in
order to expose log density evaluations and gradients of the contained Stan
model.

## Prerequisites

See the page [Getting Started with
CmdStan](https://github.com/stan-dev/cmdstan/wiki/Getting-Started-with-CmdStan).

Mostly

* A C++11 compiler
* The Gnu make utility for *nix, mingw for Windows

## Install

Download CmdStan and BridgeStan from their repositories.

```
git clone https://github.com/stan-dev/cmdstan.git --recursive
cd cmdstan
make stan-update
cd ..
git clone https://gitlab.com/roualdes/bridgestan.git
```

## Use

First, compile a Stan program.  As an example, consider the Stan program stored
in the file named `multi.stan` in the directory `stan/multi/`.

```
$ cd bridgestan
$ CMDSTAN=/path/to/cmdstan/ make stan/multi/multi_model.so
```

NB There is a necessary forward slash at the end of the `cmdstan` path.

The make target is a shared object file (.so), with a file name created by
replacing the `.stan` extension of your Stan program with `_model.so`.

Last, proceed as in either `example.py` or `example.jl`, updating paths within
the Julia or Python code as necessary.

## Custom Build Flags

BridgeStan will make use of the compiler flags set in CmdStan's file
`make/local`.  From within the CmdStan directory, create/edit the file
`make/local` to use the desired compiler flags for the various parts of a Stan
program.  If you need help getting started, copy `make/local.example` to
`make/local`.

To set the compiler flags `-O3 -march=native`, you should have

```
# Adding other arbitrary C++ compiler flags
CXXFLAGS+= -O3 -march=native
```

If you've read the Stan Blog post [Options for improving Stan sampling
speed](https://blog.mc-stan.org/2022/08/03/options-for-improving-stan-sampling-speed/),
you can set stanc3 compiler flags with

```
# Add flags that are forwarded to the Stan-to-C++ compiler (stanc3).
# This example enables pedantic mode
STANCFLAGS+= --warn-pedantic --O1
```

Last example.  Say you've written a sampler in a higher level language, which
uses multpiple threads, then you'll need

```
# Enable threading
STAN_THREADS=true
```

to enable BridgeStan to be called from multiple threads.


## Known to Work OSes and C++11 Compilers

BridgeStan has been tested (with commands as above) under both Ubuntu (20.04
with gcc 9.4.0) and macOS (12.2 with Apple clang 11.0.3).

BridgeStan has also been tested on Windows 10 with gcc MSYS2 5.3.0, and
works so long as the path to the CmdStan directory uses forward slashes, eg

```
mingw32-make.exe CMDSTAN="C:/path/to/cmdstan/" ./stan/multi/multi_model.so
```

## Acknowledgements

Much of this project came from Bob Carpenter's [Stan Model
Server](https://github.com/bob-carpenter/stan-model-server/).

GitHub user wds15 deserves much for enabling multi-threaded Julia programs to
efficiently call on one Stan program.

Much of the testing of the makefile is credited to Brian Ward.
