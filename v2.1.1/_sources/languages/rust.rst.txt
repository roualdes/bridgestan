Rust Interface
==============

`See the BridgeStan Crate documentation on docs.rs <https://docs.rs/bridgestan>`__

----

Installation
------------

The BridgeStan Rust client is available on `crates.io <https://crates.io/crates/bridgestan>`__ and via ``cargo``:

.. code-block:: shell

    cargo add bridgestan

To build and use BridgeStan models, a copy of the BridgeStan C++ source code
is required. Please follow the :doc:`Getting Started guide <../getting-started>`
or use the Rust client in tandem with an interface such as :doc:`Python <./python>`
which automates this process.

``STAN_THREADS=true`` needs to be specified when compiling a model, for more
details see the `API reference <https://docs.rs/bridgestan>`__.

Example Program
---------------

An example program is provided alongside the Rust crate in ``examples/example.rs``:

.. raw:: html

   <details>
   <summary><a>Show example.rs</a></summary>


.. literalinclude:: ../../rust/examples/example.rs
   :language: Rust

.. raw:: html

   </details>


API Reference
-------------

See docs.rs for the full API reference: `<https://docs.rs/bridgestan>`__
