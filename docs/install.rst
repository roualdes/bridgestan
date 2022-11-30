
Installation
============

Requirement: C++ toolchain
--------------------------

Stan requires a C++ tool chain consisting of

* A C++14 compiler. On Windows, MSCV is *not* supported, so something like MinGW GCC is required.
* The Gnu ``make`` utility for \*nix *or* ``mingw32-make`` for Windows

Here are complete instructions by platform for installing both, from the CmdStan installation instructions.

* `C++ tool chain installation <https://mc-stan.org/docs/cmdstan-guide/cmdstan-installation.html#cpp-toolchain>`__

Download
--------

Installing BridgeStan is as simple as ensuring that the above pre-requisites are installed and then downloading
the source repository.

If you have ``git`` installed, you may do this by navigating to the folder you'd like
BridgeStan to be in and running ``$ git clone --recurse-submodules https://github.com/roualdes/bridgestan.git``.

After this, BridgeStan is installed. You can test a basic compilation by opening
a terminal in your BridgeStan folder and running

.. code-block:: shell

    # MacOS and Linux
    make test_models/multi/multi_model.so
    # Windows
    mingw32-make.exe test_models/multi/multi_model.so

This will compile the file ``test_models/multi/multi.stan`` into a shared library object for use with BridgeStan.
This requires internet access the first time it is run.


Using custom Stan versions
--------------------------

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


Interface: Python
-----------------

If you would like to install the :doc:`Python interface <languages/python>`,
you can either install it directly from Github with

.. code-block:: shell

    pip install "git+https://github.com/roualdes/bridgestan.git#egg=bridgestan&subdirectory=python"

Or, since you have already downloaded the repository, you can run

.. code-block:: shell

    pip install python/

from the BridgeStan folder.

Note that the Python package depends on Python 3.9+ and NumPy, and will install
NumPy if it is not already installed.


Interface: Julia
----------------

If you would like to install the :doc:`Julia interface <languages/julia>`,
you can either install it directly from Github with

.. code-block:: julia

    ] add https://github.com/roualdes/bridgestan.git:julia

Or, since you have already downloaded the repository, you can run

.. code-block:: julia

    ] dev julia/

from the BridgeStan folder.

Note that the Julia package depends on Julia 1.8+.


Interface: R
----------------

If you would like to install the :doc:`R interface <languages/r>`,
you can either install it directly from Github with

.. code-block:: R

    devtools::install_github("https://github.com/roualdes/bridgestan", subdir="R")

Or, since you have already downloaded the repository, you can run

.. code-block:: R

    install.packages(file.path(getwd(),"R"), repos=NULL, type="source")

from the BridgeStan folder.

Note that the R package depends on R 3+ and R6, and will install R6 if it is not
already installed.
