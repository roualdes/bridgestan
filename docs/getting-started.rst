
Getting Started
===============

Requirement: C++ toolchain
--------------------------

Stan requires a C++ tool chain consisting of

* A C++14 compiler. On Windows, MSCV is *not* supported, so something like MinGW GCC is required.
* The Gnu :command:`make` utility. On Windows, :command:`make` or :command:`mingw32-make` can be used

Here are complete instructions by platform for installing both, from the CmdStan installation instructions.

* `C++ tool chain installation - CmdStan User's Guide <https://mc-stan.org/docs/cmdstan-guide/installation.html#cpp-toolchain>`__

Downloading BridgeStan
----------------------

.. note::
    The :doc:`Julia <languages/julia>`, :doc:`Python <languages/python>`, and :doc:`R <languages/r>`
    interfaces will download the source for you the first time you compile a model, and the :doc:`Rust <languages/rust>`
    interface has an optional feature to download the source upon request.
    This section is optional for users primarily interested in those interfaces.


Installing BridgeStan is as simple as ensuring that the above requirements are installed and then downloading
the source repository. All of the following ways of downloading BridgeStan will additionally download the
`Stan <https://github.com/stan-dev/stan>`__ and `Stan Math <https://github.com/stan-dev/math>`__ libraries for you,
and no additional dependencies are required to be installed separately for the C++ source code.


Downloading a released archive
______________________________

Downloads of a complete copy of the source code and interfaces are available
on `our GitHub releases page <https://github.com/roualdes/bridgestan/releases>`__.

To use these, simply download the file associated with the version you wish to use,
and unzip its contents into the folder you would like BridgeStan to be in.


Installing the latest version with :command:`git`
_________________________________________________

If you have :command:`git` installed, you may download BridgeStan by navigating to the folder you'd like
BridgeStan to be in and running

.. code-block:: shell

    git clone --recurse-submodules --shallow-submodules --depth=1 https://github.com/roualdes/bridgestan.git

If you clone without the ``--recurse-submodules`` argument, you can download the required
submodules with ``make stan-update``. The arguments ``--shallow-submodules`` and ``--depth=1`` are
to reduce the size of the download, but are not required.


Testing the Installation
________________________

After this, BridgeStan is installed. You can test a basic compilation by opening
a terminal in your BridgeStan folder and running

.. code-block:: shell

    make test_models/multi/multi_model.so

This will compile the file :file:`test_models/multi/multi.stan` into a shared library object for use with BridgeStan.
This will require internet access the first time you run it in order
to download the appropriate Stan compiler for your platform into
:file:`{<bridgestan-dir>}/bin/stanc{[.exe]}`

Installing an Interface
-----------------------

To see instructions for installing the BridgeStan client package in your language of
choice, see the :doc:`Language Interfaces page <languages>`.

Optional: Customizing BridgeStan
--------------------------------

BridgeStan has many compiler flags and options set by default. Many of these defaults
are the same as those used by the CmdStan interface to Stan.
You can override the defaults or add new flags
on the command line when invoking :command:`make`, or make them persistent by
creating or editing the file :file:`{<bridgestan dir>}/make/local`.

For example, setting the contents of :file:`make/local` to the following
includes compiler flags for optimization level and architecture.

.. code-block:: Makefile

    # By default we use -O3, this sets a less aggressive C++ optimization level
    O=2
    # Adding other arbitrary C++ compiler flags
    CXXFLAGS+= -march=native

Flags for :command:`stanc3` can also be set here

.. code-block:: Makefile

    # pedantic mode and level 1 optimization
    STANCFLAGS+= --warn-pedantic --O1

Enabling Parallel Calls of Stan Programs
________________________________________

In order for Python or Julia to be able to call a single Stan model
concurrently from multiple threads or for a Stan model to execute its
own code in parallel, the following flag must be set in :file:`make/local`
or on the command line.

.. code-block:: Makefile

    # Enable threading
    STAN_THREADS=true

Note that this flag changes a lot of the internals of the Stan library
and as such, **all models used in the same process should have the same
setting**. Mixing models which have :makevar:`STAN_THREADS` enabled with those that do not
will most likely lead to segmentation faults or other crashes.

Additional flags, such as those for MPI and OpenCL, are covered in the
`CmdStan User's Guide page on Parallelization <https://mc-stan.org/docs/cmdstan-guide/parallelization.html>`__.

Autodiff Hessian calculations
_____________________________

By default, Hessians in BridgeStan are calculated using central finite differences.
This is because not all Stan models support the nested autodiff required for Hessians
to be computed directly, particularly models which use implicit functions like the ``algebra_solver``
or ODE integrators.

If your Stan model does not use these features, you can enable autodiff Hessians by
setting the compile-time flag ``BRIDGESTAN_AD_HESSIAN=true`` in the invocation to :command:`make`.
This can be set in :file:`make/local` if you wish to use it by default.

This value is reported by the ``model_info`` function if you would like to check at run time
whether Hessians are computed with nested autodiff or with finite differences. Similar to
:makevar:`STAN_THREADS`, it is not advised to mix models which use autodiff Hessians with those that
do not in the same program.

Autodiff Hessians may be faster than finite differences depending on your model, and will
generally be more numerically stable.

Constraint tolerances
_____________________

The ``param_unconstrain`` family of functions check their inputs to ensure that they
are in the support of the unconstraining transform. For example, if the model has a ``simplex``
parameter, it will verify that all of the elements sum to 1.0.

When unconstraining outputs from e.g. CmdStan, it is not uncommon that these constraints are
violated by a small amount due to numerical error. If this amount is larger than `1e-8`, the
function will throw an error.

This tolerance is set in the Stan Math library, but can be overridden by defining the
``STAN_MATH_CONSTRAINT_TOLERANCE`` during compilation. One way to do this in BridgeStan is
to set :makevar:`CPPFLAGS` in :file:`make/local`:

.. code-block:: Makefile

    CPPFLAGS+=-DSTAN_MATH_CONSTRAINT_TOLERANCE=1e-5


Using External C++ Code
_______________________

BridgeStan supports the same `capability to plug in external C++ code as CmdStan <https://mc-stan.org/docs/cmdstan-guide/external_code.html>`_.

Namely, you can declare a function in your Stan model and then define it in a separate C++ file.
This requires passing the ``--allow-undefined`` flag to the Stan compiler when building your model.
The :makevar:`USER_HEADER` variable must point to the C++ file containing the function definition.
By default, this will be the file :file:`user_header.hpp` in the same directory as the Stan model.

For a more complete example, consult the `CmdStan documentation <https://mc-stan.org/docs/cmdstan-guide/external_code.html>`_.

Using Older Stan Versions
__________________________

If you wish to use BridgeStan for an older released version, all you need to do is

1. Set :makevar:`STANC3_VERSION` in :file:`make/local` to your desired version, e.g. ``v2.26.0``
2. Go into the ``stan`` submodule and run ``git checkout release/VERSION``, e.g. ``release/v2.26.0``
3. Also in the ``stan`` submodule, run ``make math-update``
4. In the top level BridgeStan directory, run ``make clean``

To return to the version of Stan currently used by BridgeStan, you can run ``make stan-update`` from the top level directory
and remove :makevar:`STANC3_VERSION` from your ``make/local`` file, before running ``make clean`` again.

Using Pre-Existing Stan Installations
_____________________________________

If you wish to use BridgeStan with a pre-existing download of the Stan repository, or with
a custom fork or branch, you can set the :makevar:`STAN` (and, optionally, :makevar:`MATH`) variables to the
path to your existing copy in calls to :command:`make`, or more permanently by setting them in a
:file:`make/local` file as described above.

The easiest way to use a custom stanc3 is to place the built executable at
:file:`bin/stanc{[.exe]}`.
