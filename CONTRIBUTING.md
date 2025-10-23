# Contributing to BridgeStan

We welcome contributions to the project in any form, including bug reports, bug fixes, new features, improved documentation, or improved test coverage.

**Developer-specific documentation is available [as part of our online documentation](https://roualdes.us/bridgestan/latest/internals.html)**. Information on building BridgeStan, running tests, and developing with the project is available there.

This document houses additional information about licensing and procedures for contributing to the project.

## Licensing

We have different open-source licenses for the code and for the documentation.

* The code is released under [BSD-3](https://github.com/roualdes/bridgestan/blob/main/LICENSE-CODE) license.
* The documentation is released under the [CC BY 4.0](https://github.com/roualdes/bridgestan/blob/main/LICENSE-DOC) license.

We follow the practices laid out in the [GitHub Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service), in the section "User-Generated Content", subsection "Contributions Under Repository License".

* Developers (or their assignees) retain copyright for their doc and code contributions.
* Developers agree to release their contributed code and documentation under the repository licenses (see above).

## Development Process

We follow standard open source and GitHub practices:

* We discuss bugs, features, and implementations through [GitHub Issues](https://github.com/roualdes/bridgestan/issues).

* We add unit tests when changing or adding code.

* We keep our code formatted using automatic tools (`make format` can run all of them for you).

* We keep the main branch in a release-ready state at all times.

* We propose updates through [GitHub Pull Requests](https://github.com/roualdes/bridgestan/pulls) so that we can do code review.  We do not push directly to the main branch.

## Proposing a new interface language

If you would like to extend BridgeStan to a language besides Python, R, or Julia, please open a [GitHub Issue](https://github.com/roualdes/bridgestan/issues) to discuss your proposal.

If you would like to write an interface to a proprietary language, such as MATLAB, Mathematica, SAS, or Stata, we suggest you fork this project and work from our C++ interface, which is [permissively licensed](https://github.com/roualdes/bridgestan/blob/main/LICENSE-CODE) in order to support this kind of extension.
