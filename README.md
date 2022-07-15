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
