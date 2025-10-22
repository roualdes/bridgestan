Developer Information
=====================

The following information is intended for developers who wish to modify the
code.

The pages on :doc:`testing` and :doc:`documentation` are also relevant.

Building BridgeStan
-------------------

Developers should follow the instructions in :doc:`../getting-started` to ensure
they have the minimal C++ build tools required for working with BridgeStan.

C++
---

* We use the C++17 standard for compilation (``-std=c++17`` in both clang and gcc).
  This is what Stan requires since version 2.36.

* We try to write standards-compliant code that does not depend on features of specific platforms
  (except where needed for compatibility).

  Specifically, we do not use OS-dependent or compiler-dependent C++.
  Our C++ code does not depend on the ``R.h`` or ``Python.h`` headers, for example.
  On the other hand, adding new signatures to work with a specific language's style of foreign
  function interface is permitted (an example can be found in the :ref:`R compatibility functions <R-compat>`,
  which requires a particular pointer-based style).

* We try to follow the `Google C++ Style Guide <https://google.github.io/styleguide/cppguide.html>`_, but
  (a) we allow C++ exceptions, and (b) we allow reference arguments.

* We recommend using `Clang format <https://clang.llvm.org/docs/ClangFormat.html>`_ with our config file
  `.clang-format <https://github.com/roualdes/bridgestan/blob/main/.clang-format>`_.

Python
------

* Python dependencies:

  * `NumPy <https://numpy.org/>`_

* We autoformat code with `black <https://black.readthedocs.io/en/stable/>`_.

Julia
-----

* Julia dependencies:

  * `Tar <https://docs.julialang.org/en/v1/stdlib/Tar/>`_ (standard library)
  * `TOML <https://docs.julialang.org/en/v1/stdlib/TOML/>`_ (standard library)
  * `Downloads <https://docs.julialang.org/en/v1/stdlib/Downloads/>`_ (standard library)
  * `Inflate.jl <https://github.com/GunnarFarneback/Inflate.jl>`_ (external)


* Julia code is formatted using `JuliaFormatter <https://github.com/domluna/JuliaFormatter.jl>`_.

R
-

* R dependencies:

  * `R6 <https://cran.r-project.org/web/packages/R6/index.html>`_

* R code is formatted using `air <https://github.com/posit-dev/air>`_.

Rust
----

* Rust development is based on :command:`cargo`, which should handle dependencies and formatting.
