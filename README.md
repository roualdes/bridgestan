# BridgeStan

This library provides a bridge from Julia/Python to a Stan programs via C, in
order to expose log density evaluations and gradients of the contained Stan
model.

## Prerequisites

See the page [Getting Started with
CmdStan](https://github.com/stan-dev/cmdstan/wiki/Getting-Started-with-CmdStan).

Mostly

* A C++11 compiler
* The Gnu make utility for *nix, mingw_64 for Windows

## Use

First download CmdStan and BridgeStan from their repositories.

```
git clone https://github.com/stan-dev/cmdstan.git --recursive
make stan-update
git clone https://gitlab.com/roualdes/bridgestan.git
```

Next compile a Stan program.  As an example, consider the Stan program stored in
the file named `multi.stan` in the directory `./stan/multi/`.

```
$ cd bridgestan
$ CMDSTAN=/path/to/cmdstan/ make stan/multi/multi_model.so
```

NB There is a necessary forward slash at the end of the `cmdstan` path.

The make target is a shared object (.so) file, with a file name created by
replacing the `.stan` extension of your Stan program with `_model.so`.

BridgeStan has been tested (with commands as above) under both Ubuntu (20.04
with gcc 9.4.0) and macOS (12.2 with Apple clang 11.0.3).

This makefile has also been tested on Windows 10 with gcc -v MSYS2 5.3.0, and
works so long as the path to the CmdStan directory uses forward slashes, eg

```
mingw32-make.exe CMDSTAN="C:/Users/<username>/path/to/cmdstan/" ./stan/multi/multi_model.so
```

Last follow along in either `example.py` or `example.jl`, updating paths within
the Python or Julia code as necessary.

## Acknowledgements

Much of this project came from Bob Carpenter's [Stan Model
Server](https://github.com/bob-carpenter/stan-model-server/).
