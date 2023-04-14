
Language Interfaces
===================

BridgeStan currently has clients in four languages, a public C API
which underlies all the clients, and an example of a standalone program
written in C.

All language interfaces expose the same core functionality from the
:doc:`C API <./languages/c-api>`.
Additional "quality of life" features such as the ability to download
BridgeStan's source code automatically or compile models from inside the language
(rather than manually calling ``make``) are available on a best-effort basis.
If you are missing these features in your favorite language, we would welcome a
`contribution <https://github.com/roualdes/bridgestan/blob/main/CONTRIBUTING.md>`__!

.. toctree::
    :maxdepth: 2

    languages/python
    languages/julia
    languages/r
    languages/rust
    languages/c-api



