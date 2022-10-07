# BridgeStan Documentation

This folder hosts the top-level documentation for BridgeStan.

These docs are available online at
[https://roualdes.github.io/bridgestan/](https://roualdes.github.io/bridgestan/).

## Building

Documentation is generated with [Sphinx](https://www.sphinx-doc.org/en/master/).

The main documentation can be build by running `make docs` in the top-level
repository. `make` can also be run in this folder to produce a specific format,
for example `make latexpdf` will produce a PDF manual of the documentation, assuming
a LaTeX toolchain is available.

### Dependencies

We use the following developer-specific tools for documentation.

* [Sphinx 5.0 or above](https://www.sphinx-doc.org/en/master/)
* [nbsphinx](https://nbsphinx.readthedocs.io/en/0.8.9/)
* [pydata-sphinx-theme](https://pydata-sphinx-theme.readthedocs.io/en/stable/)
* [MySt-Parser](https://myst-parser.readthedocs.io/en/latest/)

If you wish to build the C++ portions of the documentation, you should also have:

* [Doxygen](https://doxygen.nl/)
* [Breathe](https://breathe.readthedocs.io/en/stable/index.html)

If you wish to build the Julia API docs, you should also have
[Julia](https://julialang.org/) installed. **Note**: the Julia
API doc sources live in `julia/docs/src/` and are merely
copied to this folder during build. If the API doc needs changing
(for example, to add a new function to the list of items to be documented)
update it **there**.


## Documentation structure

* Top-level documentation
    - language-agnostic documentation
    - `users/` for user-facing language-agnostic documentation
    - `devs/` for dev-facing language-agnostic documentation

* Language-specific documentation: `L/`
    - top-level doc for language `L` with pointers to dev and user doc
    - `L/users` for user-facing doc for language `L`
    - `L/devs` for dev-facing doc for language `L`
    - `L/api` for the API spec for language `L`
