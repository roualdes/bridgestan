# Contributing to BridgeStan

We welcome contributions to the project in any form, including bug reports, bug fixes, new features, improved documentation, or improved test coverage.

Our next goal is a stable 1.0 release, which is mostly a matter of more thorough testing and documentation.

## Licensing

We have different open-source licenses for the code and for the documentation.

* The code is released under [BSD-3](https://github.com/roualdes/bridgestan/blob/main/LICENSE-CODE) license.
* The documentation is released under the [CC BY 4.0](https://github.com/roualdes/bridgestan/blob/main/LICENSE-DOC) license.

We follow the practices laid out in the [GitHub Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service), in the section "User-Generated Content", subsection "Contributions Under Repository License".

* Developers (or their assignees) retain copyright for their doc and code contributions.
* Developers agree to release their contributed code and documentation under the repository licenses (see above).

## Developers

We follow standard open source and GitHub practices:

* We discuss bugs, features, and implementations through [GitHub Issues](https://github.com/roualdes/bridgestan/issues).

* We add unit tests when changing or adding code.

* We keep the main branch in a release-ready state at all times.

* We propose updates through [GitHub Pull Requests](https://github.com/roualdes/bridgestan/pulls) so that we can do code review.  We do not push directly to the main branch.


## Documentation

We use [Sphinx](https://www.sphinx-doc.org/en/master/) to generate documentation, with the goal of publishing on [Read the Docs](https://readthedocs.org) for the first release.  The docs are currently hosted on the [GitHub pages](https://roualdes.github.io/bridgestan/) for this repository.

We use the following developer-specific tools for documentation.

* [Sphinx 5.0 or above](https://www.sphinx-doc.org/en/master/)
* [nbsphinx](https://nbsphinx.readthedocs.io/en/0.8.9/)
* [pydata-sphinx-theme](https://pydata-sphinx-theme.readthedocs.io/en/stable/)
* [MySt-Parser](https://myst-parser.readthedocs.io/en/latest/)

If you wish to build the C++ portions of the documentation, you should also have:

* [Doxygen](https://doxygen.nl/)
* [Breathe](https://breathe.readthedocs.io/en/stable/index.html)


## Builds

We use [Gnu make](https://www.gnu.org/software/make/) for builds.  If you have installed [CmdStan](https://mc-stan.org/users/interfaces/cmdstan) as required for the source to work, then you will already have Gnu make and a sufficient C++ compiler.


## Language specific practices

### C and C++ development

* We require the following dependency for C++ development:

* We use the C++1y standard for compilation (`-std=c++1y` in both clang and gcc).  This is partway between C++11 and C++14, and is what Stan requires.

* We try to write standards-compliant code that does not depend on features of specific platforms (except where needed for compatibility).  Specifically, we do not use OS-dependent or compiler-dependent C++.  Our C++ code does not depend on the `R.h` or `Python.h` headers, for example.  On the other hand, adding new signatures to work with a specific language's style of foreign function interface is permitted (an example can be found in the R interface, which requires a particular pointer-based style).

* We try to follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html), but (a) we allow C++ exceptions, and (b) we allow reference arguments.

* We will use [GoogleTest](https://google.github.io/googletest/) for C++ unit testing.

* We recommend using [Clang format](https://clang.llvm.org/docs/ClangFormat.html) with our config file [`.clang-format`](https://github.com/roualdes/bridgestan/blob/main/.clang-format).


### Python development

* Python development relies on the external dependencies:
    * [pytest](https://docs.pytest.org/en/7.1.x/)
    * [NumPy](https://numpy.org/)

* We integrate a C wrapper of Stan's model class using the [ctypes](https://docs.python.org/3/library/ctypes.html) foreign function interface.

* We use the [numpy.testing](https://numpy.org/doc/stable/reference/routines.testing.html) unit testing framework and run the tests by calling [pytest](https://docs.pytest.org/en/7.1.x/) from the top-level Python directory `bridgestan/python`.

* We autoformat code with [black](https://black.readthedocs.io/en/stable/).

* We recommend but do not require checking the code style and semantics with [PyLint](https://www.pylint.org) using [BridgeStan .pylintrc](https://github.com/roualdes/bridgestan/blob/main/.pylintrc).

### R development

* R dependencies beyond those included in this repo:
    * [R6 package](https://cran.r-project.org/web/packages/R6/index.html) for reference classes
    * [testthat](https://testthat.r-lib.org) for unit testing

* We use the most basic [.C interface](https://www.biostat.jhsph.edu/~rpeng/docs/interface.pdf) for calling C from R.

### Julia development

* Julia dependencies beyond those included in this repo:
    * [Test](https://docs.julialang.org/en/v1/stdlib/Test/)
    * [LinearAlgebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/)

* We use Julia's C foreign function interface, which is documented for [base C](https://docs.julialang.org/en/v1/base/c/) and the [C standard library](https://docs.julialang.org/en/v1/stdlib/Libdl/).


## Proposing a new interface language

If you would like to extend BridgeStan to a language besides Python, R, or Julia, please open a [GitHub Issue](https://github.com/roualdes/bridgestan/issues) to discuss your proposal.

If you would like to write an interface to a proprietary language, such as MATLAB, Mathematica, SAS, or Stata, we suggest you fork this project and work from our C++ interface, which is [permissively licensed](https://github.com/roualdes/bridgestan/blob/main/LICENSE-CODE) in order to support this kind of extension.
