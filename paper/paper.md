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
access through Python, Julia, and R to the methods of a Stan model, including
log densities, gradients, Hessians, and constraining and unconstraining
transforms.  Furthermore, these features are exposed through a language-agnostic C
API, allowing for interfaces in other languages with minimal additional development.

# Statement of need

Stan was written for applied statisticians and now has interfaces in many
different programming languages, R, Python, Julia, Matlab, and Stata, to name
the more popular ones.  Stan is both a probabilistic programming language and an
inference enginge that fits the models written in the Stan language.  From this
alone, Stan has become very successful for applied statisticians.

In the statistical software environment R, Stan is heavily relied upon for
development of applied statistics packages.  Using Google's
[PageRank](https://en.wikipedia.org/wiki/PageRank) algorithm on the dependency
graph [@pagerank:2014] amongst the 19,159 R packages listed on CRAN as of
2022-12-31, we find that RStan ranks at number 70, rstantools 179, and RStanArm
502.  So at least in the world of R, Stan and its direct package descendants is
amongst the 100 most relied upon R packages.

`BridgeStan` on the other hand brings to the forefront of the Stan community
the tools underlying Stan's inference algorithms, most importantly automatic
differentiation.  The motivation for `BridgeStan` is developing inference
algorithms in higher-level languages for arbitrary Stan models, such as those in
[posteriordb](https://github.com/stan-dev/posteriordb).  `BridgeStan` then helps
algorithm developers create new inference algorithms, which in turn will
facilitate applied statisticians.  `BridgeStan` offers to developers of
statistical inference algorithms both a probabilistic programming language,
access to Stan's math library, and the accompanying automatic differentiation
toolset.

There exist other libraries that offer automatic differentation of arbitrary
computer programs.  One of the more popular is Google's library
[JAX](https://github.com/google/jax) [@Bradbury:2018].  JAX is built off of
Google's Accelerated Linear Algebra (XLA) library, a domain-specific,
just-in-time compiler.

JAX can compile almost any NumPy program and targets GPUs and TPUs.  These are
both the strengths and limitations of JAX.  The JAX documention page [The Sharp
Bits](https://jax.readthedocs.io/en/latest/notebooks/Common_Gotchas_in_JAX.html)
details the limitations of JAX, namely their inability to deal with in-place
mutations.  And while JAX will work on CPUs, Stan's automatic differentiation
library directly targets the CPU and is thus faster on this hardware[^1].

Stan and JAX are not alone.  Below is a short list of software designed
for automatic differentiation of arbitrary computer programs.

* [TMB](https://cran.r-project.org/web/packages/TMB/index.html)
* [CppAD](https://coin-or.github.io/CppAD/html/CppAD.html)
* [JAX](https://github.com/google/jax)
* [NumPyro](https://num.pyro.ai/en/stable/)
* see [JuliaDiff](https://juliadiff.org/) for various resources written using Julia
* TODO others?

`BridgeStan` though offers a unique combination of numerical efficiency, coupled
with direct access to the probabilistic programming language Stan.  `BridgeStan`
is an interface, written in C, between a Stan program, expressed as a log joint density
function using highly templated C++ from the Stan math library, and any higher
level language which exposes a C foreign function interface.  Since Julia,
Python, and R all have C foreign function interfaces, `BridgeStan` offers
efficient, in-memory computations between Stan and the host language.

The Stan community by and large uses CPU hardware and since Stan primarily
targets CPUs, `BridgeStan` is incredibly efficient for developing inference
algorithms on CPUs.  The Stan math library and its automatic differentiation
tools were evaluated for efficiency on CPUs in @Carpenter:2015.  `BridgeStan` also
allows for the use of the same model/data in a multi-threaded environment for
parallel evaluations of the log density function.

`BridgeStan` enables memory allocated in the host language, for now Julia,
Python, and R, to be reused within Stan; though any language with a C foreign
function interface could be similarly interfaced to access Stan methods.  By avoiding
unnecessary copies of vectors created in the host language, `BridgeStan` is a
zero-cost abstraction built upon Stan's numerically efficient math library.

# Example

The probabilistic programming language Stan, together with its automatic
differentiation tools enable numerically efficient parameterizations of
otherwise numerically challenging distributions.  Consider the
following Stan program, which encodes an isotropic multivariate Student t
distribution of dimension $D$ and degrees of freedom $df$.

This parameterization[^2] of the Student t distribution enables gradient based
Markov chain Monte Carlo algorithms to capture the heaviness of the tails when
$df$ is less than say $30$.  Calculating the gradient of the joint log density
of this parameterization of the Student t distribution is not difficult, but it
is cumbersome and time consuming to encode in software.  Since `BridgeStan` uses
Stan, users of `BridgeStan` can trust that their bespoke parameterizations of
numerically challenging distributions will be differentiated with both
unit-tested and time tested tools from Stan.

```{stan}
// Multivariate Student-t
data {
  int D;
  real df;
}
transformed parameters {
  vector[D] mu = rep_vector(0.0, D);
  matrix[D, D] Sigma = identity_matrix(D);
  real<lower=0.0> nu = 0.5 * df;
}
parameters {
  vector[D] z;
  vector<lower=0>[D] ig;        /* constrained parameters */
}
transformed parameters {
  vector[D] x = z .* sqrt(ig);
}
model {
  z ~ multi_normal(mu, Sigma);
  ig ~ inv_gamma(nu, nu);
}
```

`BridgeStan` users can access the gradient and transformed parameters of this
model with Python code like below.

```{python}
import bridgestan as bs
import numpy as np

stan_model = "path/to/student-t.stan"
stan_data = "path/to/student-t.json"
model = bs.StanModel.from_stan_file(stan_model, stan_data)

x = np.random.random(model.param_unc_num()) # unconstrained inputs
ld, grad = model.log_density_gradient(x)    # log density and gradient
model.param_constrain(x, include_tp = True) # constrained (and transformed) parameters
```

# Conclusion

On the [Stan Discourse forums](https://discourse.mc-stan.org/), some statistical
algorithm developers have long asked for access to the gradients and Hessians
that underly the statistical model of a Stan program.  `BridgeStan` enables
access to these methods, with an efficient and in-memory solution.  Further,
because statistical models are so easy to write in Stan, algorithm developers
can write their model in common statistical notation using the Stan programming
language and then rely on the Stan math library and its automatic
differentiation toolset to more easily build advanced gradient based statistical
inference algorithms.  `BridgeStan` documentation and example programs are found
at <https://roualdes.github.io/bridgestan/index.html>.


[^1]: Note that both Stan and JAX work on their non-targeted hardware, but both are faster on the hardware for which they were originally designed.

[^2]: See Wikipedia's page on the [Student's t-distribution](https://en.wikipedia.org/wiki/Student%27s_t-distribution#Characterization)for a brief introduction to this parameterization.

# Acknowledgements

Edward A. Roualdes received support from Flatiron Institute during the beginning
of this project.

# References
