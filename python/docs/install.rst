
Installation
============

Requirement: C++ toolchain and CmdStan
--------------------------------------
BridgeStan relies on `CmdStan <https://github.com/stan-dev/cmdstan>`__ and
the following assume you have a working installation for your system.
Please make sure you are able to compile and run the CmdStan example program **before continuing**.

For more information,
see the `CmdStan installation instructions <https://mc-stan.org/docs/cmdstan-guide/cmdstan-installation.html>`__.

Download
--------

Installing BridgeStan is as simple as ensuring that the above pre-requisites are installed and then downloading
the source repository.

If you have ``git`` installed, you may do this by navigating to the folder you'd like
BridgeStan to be in and running ``git clone git@github.com:roualdes/bridgestan.git``.

If you do not have ``git`` installed, you can download a `.zip` file containing the repository
`here <https://github.com/roualdes/bridgestan/archive/refs/heads/main.zip>`__. Unzip this
file into the folder you would like BridgeStan to be in.

After this, BridgeStan is installed. You can test a basic compilation by opening
a terminal in your BridgeStan folder and running

.. code-block:: shell

    # MacOS and Linux
    make CMDSTAN=/path/to/cmdstan/here/ test_models/multi/multi_model.so
    # Windows
    mingw32-make.exe CMDSTAN=C:/path/to/cmdstan/with/forward/slashes/ test_models/multi/multi_model.so

This will compile the file ``test_models/multi/multi.stan`` into a shared library object for use with BridgeStan.



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
