# Contributing to BridgeStan

We welcome contributions to the project in any form, including bug reports, bug fixes, new features, improved documentation, or improved test coverage.

Developer-specific documentation is available at https://roualdes.github.io/bridgestan/internals.html

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


## Builds

We use [Gnu make](https://www.gnu.org/software/make/) for builds.  If you have previously used [CmdStan](https://mc-stan.org/users/interfaces/cmdstan), then you will already have Gnu make and a sufficient C++ compiler.


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
    * [NumPy](https://numpy.org/)

* We autoformat code with [black](https://black.readthedocs.io/en/stable/).

* We recommend but do not require checking the code style and semantics with [PyLint](https://www.pylint.org) using [BridgeStan .pylintrc](https://github.com/roualdes/bridgestan/blob/main/.pylintrc).

### R development

* R dependencies beyond those included in this repo:
    * [R6 package](https://cran.r-project.org/web/packages/R6/index.html) for reference classes

### Julia development

* Julia dependencies beyond those included in this repo:
    * [Test](https://docs.julialang.org/en/v1/stdlib/Test/)
    * [LinearAlgebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/)

* Julia code is formatted using [JuliaFormatter](https://github.com/domluna/JuliaFormatter.jl).


## Proposing a new interface language

If you would like to extend BridgeStan to a language besides Python, R, or Julia, please open a [GitHub Issue](https://github.com/roualdes/bridgestan/issues) to discuss your proposal.

If you would like to write an interface to a proprietary language, such as MATLAB, Mathematica, SAS, or Stata, we suggest you fork this project and work from our C++ interface, which is [permissively licensed](https://github.com/roualdes/bridgestan/blob/main/LICENSE-CODE) in order to support this kind of extension.
