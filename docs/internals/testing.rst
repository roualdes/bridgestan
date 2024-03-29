Testing
=======

Testing for BridgeStan is primarily done through the higher-level :doc:`interfaces <../languages>`.

All tests are based around the same set of test models (in the :file:`test_models/` folder).

You can build all of the test models at once with

.. code-block:: shell

    make STAN_THREADS=true test_models -j<jobs>

Note: The additional functionality provided by
:makevar:`STAN_THREADS` is only required by the Julia and Rust tests,
but in order to facilitate the same built models being used in
all tests we use it regardless of interface.

Tests for the compilation utilities in the various interfaces also rely on being
able to find the BridgeStan source. This is best done with the environment variable
``BRIDGESTAN``. On Linux and macOS, this can be set with ``export BRIDGESTAN=\`pwd\```.
On Windows, use ``$env:BRIDGESTAN=$pwd``.

Python
______

In Python we use `pytest <https://docs.pytest.org/en/7.2.x/>`__ to run tests. Tests
are written using basic ``assert`` statements and helper code from :py:mod:`numpy.testing`.

The Python test suite has the ability to run mutually exclusive groups of code. This is to allow
testing of features such as the :makevar:`BRIDGESTAN_AD_HESSIAN` flag which change underlying code and
therefore cannot be loaded at the same time as models compiled without it.

Running

.. code-block:: shell

    pytest -v python/

Will run the "default" grouping. To run the other group(s), run

.. code-block:: shell

    pytest --run-type=ad_hessian -v python/

The set up for this can be seen in :file:`tests/conftest.py` and is based on the
`Pytest documentation examples <https://docs.pytest.org/en/7.1.x/example/simple.html#control-skipping-of-tests-according-to-command-line-option>`__.

Julia
_____

Julia tests are written using the built in
`unit testing library <https://docs.julialang.org/en/v1/stdlib/Test/>`__.

.. code-block:: shell

    julia --project=./julia -t 2 -e "using Pkg; Pkg.test()"


R
_

R tests are written using `testthat <https://testthat.r-lib.org/>`__.

.. code-block:: shell

    cd R/
    Rscript -e "devtools::test()"

The R unit tests are much more basic than the Python or Julia tests.

Rust
_____

The Rust tests can be run with :command:`cargo`

.. code-block:: shell

    cd rust/
    cargo test
