
BridgeStan -- efficient, in-memory access to the methods of a Stan model
========================================================================

BridgeStan is a library (with :doc:`bindings <languages>` available in Python,
Julia, R, and Rust) that grants access to the methods of a `Stan <https://mc-stan.org>`__
model, including log densities, gradients, Hessians, and constraining and
unconstraining transforms.

This allows researchers and library authors to develop inference algorithms in
higher-level languages and apply them to arbitrary Stan models, such as those in
`posteriordb <https://github.com/stan-dev/posteriordb>`__.


.. toctree::
   :maxdepth: 2
   :caption: Contents:

   getting-started
   languages
   internals
