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
    orcid: 0000-0002-9841-3342
    equal-contrib: true
    affiliation: 2
  - name: Bob Carpenter
	orcid: 0000-0002-2433-9688
    equal-contrib: true
    affiliation: 2
affiliations:
 - name: California State University, Chico
   index: 1
 - name: Center for Computational Mathematics, Flatiron Institute
   index: 2
date: 5 January 2022
bibliography: paper.bib
---

# Summary

Stan provides a probabilistic programming language in which users can
code Bayesian models [@Carpenter:2017; @Stan:2022].  A Stan program is
transpiled to to a C++ class which links to the Stan math library to
implement smooth, unconstrained posterior log densities, gradients,
and Hessians as well as constraining/unconstraining transforms.
Implementation is provided through automatic differentiation in the
Stan math library [@Carpenter:2015].  BridgeStan provides efficient
in-memory access to the methods of Stan models through Python, Julia,
R.  This allows algorithm development in these languages with
the efficiency and expressiveness of Stan models.
Furthermore, these features are exposed through a language-agnostic C
API, allowing foreign function interfaces in other languages with
minimal additional development.


# Statement of need

Stan was developed for applied statisticians working on real world
problems and has been used by hundreds of thousands of researchers and
practitioners across the social, biological, and physical sciences,
engineering, education, sports, and finance.  Stan provides several
state-of-the-art, gradient-based algorithms: full Bayesian inference
with Hamiltonian Monte Carlo, Laplace approximation based on L-BFGS
optimization, and autodiff variational inference (ADVI).

In the statistical software environment R, Stan is heavily relied upon
for development of applied statistics packages.  Using Google's
[PageRank](https://en.wikipedia.org/wiki/PageRank) algorithm on the
dependency graph [@pagerank:2014] amongst the 19,159 R packages listed
on the Comprehensive R Archive Network (CRAN) as of 2022-12-31, we
find that RStan ranks at number 70, rstantools 179, and RStanArm 502. Two
interfaces to Stan, pystan and cmdstanpy, both rank in the top 600 packages by
downloads on the Python Package Index (PyPI).

C++ is relatively unknown and can be cumbersome for algorithm
prototyping, so developers have been requesting ways to access Stan
models for algorithm development in Python, R, and Julia. BridgeStan answers
this call, making it easy for algorithm developers to leverage existing
Stan models in their evaluation, e.g., the dozens of diverse models with
reference posteriors in [posteriordb](https://github.com/stan-dev/posteriordb).

There are language-specific alternatives to BridgeStan.  In Python,
[JAX](https://github.com/google/jax) [@Bradbury:2018] provides
automatic differentiation for NumPy-based programs and its associated
tool Oryx provides tools for transforms to make it possible to write
probabilistic programs that define unconstrained densities.  JAX is
built on top of Google's Accelerated Linear Algebra (XLA) library, a
just-in-time compiler for a domain-specific sublanguage of Python.
JAX can compile almost any NumPy program and targets GPUs and TPUs.
The JAX documentation page
[The Sharp Bits](https://jax.readthedocs.io/en/latest/notebooks/Common_Gotchas_in_JAX.html)
details the limitations of JAX, namely their inability to deal with
in-place mutations.  And while JAX will work on CPUs, Stan's automatic
differentiation library directly targets the CPU and is thus faster on
this hardware[^1].

In Julia, [Turing.jl](https://turing.ml/stable/) provides an embedded
probabilistic program for which derivatives are available, based on
any one of a number of Julia automatic differentiation systems.
Nevertheless, Stan is faster than both JAX and Julia autodiff on a
CPU, so there are advantages to using it just for speed in a
particular language.

Stan and JAX are not alone.  Below is a short list of software
designed for automatic differentiation of arbitrary computer programs.
In C++, we have
[AD Model Builder (ADMB)/Template Model Builder (TMB)](https://www.admb-project.org/),
which is layered on top of
[CppAD](https://coin-or.github.io/CppAD/html/CppAD.html).  In Python,
we have [NumPyro](https://num.pyro.ai/en/stable/), which is layered
over [JAX](https://github.com/google/jax) and
[TensorFlow Probability](https://www.tensorflow.org/probability),
which is developed on top of TensorFlow and JAX.  And in Julia, there
are several probabilistic programming languages, the most popular of
which is [Turing.jl](https://turing.ml/stable/), which can be coupled
with one of the many Julia autodiff systems such as [JuliaDiff](https://juliadiff.org/)
or [Zygote](https://fluxml.ai/Zygote.jl/stable/).

BridgeStan though offers a unique combination of numerical efficiency,
coupled with direct access to the probabilistic programming language
Stan.  BridgeStan is an interface, written in C-compatible C++,
between a Stan program and any higher level language which exposes a C
foreign function interface.  Since Julia, Python, and R all have C
foreign function interfaces, BridgeStan offers efficient, in-memory
computations of the log joint density function of a Stan model, itself
implemented using highly templated C++ from the Stan math library,
from within the host language.  Using a memory-compatible C interface
makes this possible even if the host language (e.g., R) was compiled
with a different compiler, something no prior interface which exposed
Stan's log density calculations could allow.

The Stan community by and large uses CPU hardware and since Stan has
been tuned for CPU performance, BridgeStan is more efficient than its
competitors in implementing differentiable log densities on CPU
[@Carpenter:2015; @radul2020automatically; @tarek2020dynamicppl].
Like the immutable Stan models they interface, BridgeStan functions
are thread safe for parallel applications.  They also admit all of the
internal parallelization of Stan models, such as internal parallel map
functions and GPU-enabled matrix operations.

BridgeStan enables memory allocated in the host language (Julia,
Python, or R), to be reused within Stan; though any language with a C
foreign function interface could be similarly interfaced to access
Stan methods.  By avoiding unnecessary copies of vectors created in
the host language, BridgeStan is a zero-cost abstraction built upon
Stan's numerically efficient math library.

# Example

The probabilistic programming language Stan, together with its automatic
differentiation tools enable numerically efficient parameterizations of
otherwise numerically challenging distributions.  Consider the
following Stan program, which encodes an isotropic multivariate Student-t
distribution of dimension $D$ and degrees of freedom $df$.

This parameterization[^2] of the Student-t distribution enables gradient-based
Markov chain Monte Carlo algorithms to capture the heaviness of the tails when
$df$ is less than say $30$.  Calculating the gradient of the joint log density
of this parameterization of the Student-t distribution is not difficult, but it
is cumbersome and time consuming to encode in software.  Since BridgeStan uses
Stan, users of BridgeStan can trust that their bespoke parameterizations of
numerically challenging distributions will be differentiated with
thoroughly tested tools from Stan.

```{stan}
/**
 * Multivariate Student-t distribution.
 */
data {
  int D;
  real df;
}
transformed data {
  vector[D] mu = rep_vector(0.0, D);
  matrix[D, D] Sigma = identity_matrix(D);
  real<lower=0.0> nu = 0.5 * df;
}
parameters {
  vector[D] z;
  vector<lower=0>[D] ig;  // ig constrained so ig > 0
}
transformed parameters {
  vector[D] x = z .* sqrt(ig);
}
model {
  z ~ multi_normal(mu, Sigma);
  ig ~ inv_gamma(nu, nu);
}
```

BridgeStan users can access the gradient and transformed parameters of this
model with Python code like below.

```{python}
import bridgestan as bs
import numpy as np

stan_model = "path/to/student-t.stan"
stan_data = "path/to/student-t.json"
model = bs.StanModel.from_stan_file(stan_model, stan_data)

x = np.random.random(model.param_unc_num())  # unconstrained inputs
ld, grad = model.log_density_gradient(x)  # log density and gradient
y = model.param_constrain(x, include_tp = True)  # constrained (and transformed) params
```

# Conclusion

On the [Stan Discourse forums](https://discourse.mc-stan.org/), statistical
algorithm developers have long asked for access to the gradients and Hessians
that underlie the statistical model of a Stan program.  BridgeStan enables
access to these methods, with an efficient, portable, and in-memory solution.  Further,
because statistical models are so easy to write in Stan, algorithm developers
can write their model in common statistical notation using the Stan programming
language and then rely on the Stan math library and its automatic
differentiation toolset to more easily build advanced gradient based statistical
inference algorithms.  BridgeStan documentation and example programs are found
at <https://roualdes.github.io/bridgestan/index.html>.


[^1]: Note that both Stan and JAX work on their non-targeted hardware, but both are faster on the hardware for which they were originally designed.

[^2]: See Wikipedia's page on the [Student's t-distribution](https://en.wikipedia.org/wiki/Student%27s_t-distribution#Characterization)for a brief introduction to this parameterization.

# Acknowledgements

Edward A. Roualdes received support from Flatiron Institute during the beginning
of this project.

# References
