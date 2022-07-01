# Installing the Stan Model Server

## Dependencies

You will at least need to install the stanc parser binary for your
platform, as well as the source for Stan (`stan-dev:stan` repo) and
for the Stan Math library (`stan-dev:math` repo).


#### GNU make

GNU make must be available on your path so that `make` on the
command-line resolves to GNU-make.


#### C++ toolchain

A C++ toolchain that supports `std=c++1y`, a version between C++14 and
C++17.  The *CmdStan Guide* contains full details of Stan's
[C++ requirements](https://mc-stan.org/docs/2_29/cmdstan-guide/cmdstan-installation.html#source-installation).

The makefile defaults to `clang`, but this can be changed by setting the
`CXX` environment variable for the makefile.  For example, to use
GCC's C++ compiler, set the make variable

```
CXX ?= g++
```

#### stan, cmdstan, and math

The server requires the following three repositories

* CmdStan [GitHub repo `stan-dev:cmdstan`](https://github.com/stan-dev/cmdstan), and

with corresponding make variables

```
CMDSTAN ?= $(HOME)github/stan-dev/
```

To get the latest `develop` version of all three, clone the CmdStan
repo and run the following make command.

```
> cd <stan-dev>
> clone https://github.com/stan-dev/cmdstan.git
> make stan-update
```

#### stanc

The environmental variable `STANC` must point to an executable version
of the Stan transpiler (translator from Stan to C++).  The default
value is the version distributed in CmdStan.

```
STANC ?= $(CMDSTAN)stan/bin/stanc
```
