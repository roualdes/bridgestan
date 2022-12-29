---
title: 'BridgeStan: Efficient in-memory access to the methods of a Stan model'
tags:
  - Stan
  - Python
  - Julia
  - R
  - C
  - C++
  - automatic differentiation
authors:
  - name: Edward A. Roualdes
    orcid: 0000-0002-8757-3463
    equal-contrib: true
    corresponding: true
    affiliation: 1
  - name: Brian Ward
    equal-contrib: true
    affiliation: 2
  - name: Bob Carpenter
    equal-contrib: true
    affiliation: 2
affiliations:
 - name: California State University, Chico
   index: 1
 - name: Center for Computational Mathematics, Flatiron Institute
   index: 2
date: 29 December 2022
bibliography: paper.bib
---

# Summary

Stan is a platorm for statistical modeling and computation used across many
disciplines, including but not limited to social, biological, and physical
sciences, engineering, and business [@Carpenter:2017; @Stan:2022].  Users
specify a statistical model in Stan's probabilistic programming language, which
encodes a log joint density function of their model.  With a Stan program, users
can obtain full Bayesian statistical inference via Markov chain Monte Carlo,
approximate Bayesian inference via variational methods, or penalized maximum
likelihood via optimization.  All of these methods require the gradient of the
log joint density function.  Stan's math library provides automatic
differentiation of the user supplied Stan program [@Carpenter:2015].  Until
`BridgeStan`, there was limited access to the evaluations of the log joint
density function or its gradient.  `BridgeStan` provides efficient in-memory
access through Python, Julia, and R to the methods of a Stan model.

# Statement of need

`BridgeStan` offers to developers of statistical inference algorithms both a
probabilistic programming language and access to Stan's math library and the
accompanying automatic differentiation toolset.

There exist other libraries that offer automatic differentation of arbitrary
computer programs.  Arguably the most popular is Google's library
[JAX](https://github.com/google/jax).  TODO note some highs and lows with JAX;
the biggest difference is that JAX targets GPUs and Stan targets CPUs, though
neither is restricted to their targeted hardware.

`BridgeStan` is a shim, written in C, between a Stan model, expressed using highly
templated C++ from the Stan math library, and any higher level language which
exposes a C foreign function interface.

Efficient. Something about speed of the automatic differentation library.

In-memory. Something about shared memory, where memory is created in the
higher-level language.


TODO create a list of key references to other software addressing related
needs:

* [TMB](https://cran.r-project.org/web/packages/TMB/index.html)
* [CppAD](https://coin-or.github.io/CppAD/html/CppAD.html)
* [JAX](https://github.com/google/jax)
* [NumPyro](https://num.pyro.ai/en/stable/)
* see [JuliaDiff](https://juliadiff.org/) for various resources written using Julia
* others?

TODO could we obtain some words about ongoing research projects using Stan?

# Acknowledgements

Edward A. Roualdes received support from Flatiron Institute during the beginning
of this project.

# References
