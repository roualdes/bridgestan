
Getting Started
===============

Requirement: C++ toolchain
--------------------------

Stan requires a C++ tool chain consisting of

* A C++14 compiler. On Windows, MSCV is *not* supported, so something like MinGW GCC is required.
* The Gnu ``make`` utility for \*nix *or* ``mingw32-make`` for Windows

Here are complete instructions by platform for installing both, from the CmdStan installation instructions.

* `C++ tool chain installation - CmdStan User's Guide <https://mc-stan.org/docs/cmdstan-guide/cmdstan-installation.html#cpp-toolchain>`__

Downloading BridgeStan
----------------------

Installing BridgeStan is as simple as ensuring that the above requirements are installed and then downloading
the source repository.

Downloading a released archive
______________________________

Downloads of a complete copy of the source code and interfaces are available
on `our GitHub releases page <https://github.com/roualdes/bridgestan/releases>`__.

To use these, simply download the file associated with the version you wish to use,
and unzip its contents into the folder you would like BridgeStan to be in.


Installing the latest version with ``git``
__________________________________________

If you have ``git`` installed, you may download BridgeStan by navigating to the folder you'd like
BridgeStan to be in and running

.. code-block:: shell

    git clone --recurse-submodules https://github.com/roualdes/bridgestan.git

If you clone without the ``--recurse-submodules`` argument, you can download the required
submodules with ``make stan-update``.


Testing the Installation
________________________

After this, BridgeStan is installed. You can test a basic compilation by opening
a terminal in your BridgeStan folder and running

.. code-block:: shell

    # MacOS and Linux
    make test_models/multi/multi_model.so
    # Windows
    mingw32-make.exe test_models/multi/multi_model.so

This will compile the file ``test_models/multi/multi.stan`` into a shared library object for use with BridgeStan.
This will require internet access the first time you run it in order
to download the appropriate Stan compiler for your platform into
``<bridgestan-dir>/bin/stanc[.exe]``

Installing an Interface
-----------------------

To see instructions for installing the BridgeStan client package in your language of
choice, see the :doc:`Language Interfaces page <languages>`.

Optional: Customizing BridgeStan
--------------------------------

BridgeStan has many compiler flags and options set by default. Many of these defaults
are the same as those used by the CmdStan interface to Stan.
You can override the defaults or add new flags
on the command line when invoking ``make``, or make them persistent by
creating or editing the file ``<bridgestan dir>/make/local``.

For example, setting the contents of ``make/local`` to the following
includes compiler flags for optimization level and architecture.

.. code-block:: Makefile

    # By default we use -O3, this sets a less aggressive C++ optimization level
    O=2
    # Adding other arbitrary C++ compiler flags
    CXXFLAGS+= -march=native

Flags for ``stanc3`` can also be set here

.. code-block:: Makefile

    # pedantic mode and level 1 optimization
    STANCFLAGS+= --warn-pedantic --O1

Enabling Parallel Calls of Stan Programs
________________________________________

In order for Python or Julia to be able to call a single Stan model
concurrently from multiple threads or for a Stan model to execute its
own code in parallel, the following flag must be set in ``make/local``
or on the command line.

.. code-block:: Makefile

    # Enable threading
    STAN_THREADS=true

Note that this flag changes a lot of the internals of the Stan library
and as such, **all models used in the same process should have the same
setting**. Mixing models which have ``STAN_THREADS`` enabled with those that do not
will most likely lead to segmentation faults or other crashes.

Additional flags, such as those for MPI and OpenCL, are covered in the
`CmdStan User's Guide page on Parallelization <https://mc-stan.org/docs/cmdstan-guide/parallelization.html>`__.

Faster Hessian calculations
___________________________

By default, Hessians in BridgeStan are calculated using central finite differences.
This is because not all Stan models support the nested autodiff required for Hessians
to be computed directly, particularly models which use implicit functions like the ``algebra_solver``
or ODE integrators.

If your Stan model does not use these features, you can enable autodiff Hessians by
setting the compile-time flag ``BRIDGESTAN_AD_HESSIAN=true`` in the invocation to ``make``.
This can be set in ``make/local`` if you wish to use it by default.

This value is reported by the ``model_info`` function if you would like to check at run time
whether Hessians are computed with nested autodiff or with finite differences. Similar to
``STAN_THREADS``, it is not advised to mix models which use autodiff Hessians with those that
do not in the same program.

Using Custom Stan Versions
__________________________

If you wish to use BridgeStan for an older released version, all you need to do is

1. Set ``STANC3_VERSION`` in ``make/local`` to your desired version, e.g. ``v2.26.0``
2. Go into the ``stan`` submodule and run ``git checkout release/VERSION``, e.g. ``release/v2.26.0``
3. Also in the ``stan`` submodule, run ``make math-update``
4. In the top level BridgeStan directory, run ``make clean``

To return to the version of Stan currently used by BridgeStan, you can run ``make stan-update`` from the top level directory
and remove ``STANC3_VERSION`` from your ``make/local`` file, before running ``make clean`` again.


If you wish to use BridgeStan with a custom fork or branch, the best thing to do is to check out that branch in the ``stan`` submodule,
or, if the fork is of stan-math, in ``stan/libs/stan_math``. The easiest way to use a custom stanc3 is to place the built executable at
``bin/stanc[.exe]``.
