Rust Interface
==============

`See the BridgeStan Crate documentation on docs.rs <https://docs.rs/bridgestan>`__

----

Installation
------------

The BridgeStan Rust client is available on `crates.io <https://crates.io/crates/bridgestan>`__ and via :command:`cargo`:

.. code-block:: shell

    cargo add bridgestan

The first time you compile a model, the BridgeStan source code will be downloaded to `~/.bridgestan`. If you prefer to use a source distribution of BridgeStan, you can pass its path as the `bs_path` argument to `compile_model`.

Note that the system pre-requisites from the [Getting Started Guide](../getting-started.rst) are still required and will not be automatically installed by this method.

Example Program
---------------

An example program is provided alongside the Rust crate in :file:`examples/example.rs`:

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
