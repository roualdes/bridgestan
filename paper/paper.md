---
title: '`BridgeStan`: Efficient in-memory access to the methods of a Stan model'
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

Stan provides a probabilistic programming language in which users can code
Bayesian models [@Carpenter:2017; @Stan:2022]. A Stan program is transpiled to
to a C++ class which links to the Stan math library to implement smooth,
unconstrained posterior log densities, gradients, and Hessians as well as
constraining/unconstraining transforms.  Implementation is provided through
automatic differentiation in the Stan math library
[@Carpenter:2015]. `BridgeStan` provides in-memory access to the methods of Stan
models through Python, Julia, and R. This allows algorithm development in these
languages with the numerical efficiency and expressiveness of Stan models.
Furthermore, these features are exposed through a language-agnostic C API,
allowing foreign function interfaces in other languages with minimal additional
development.


# Statement of need

Stan was developed for applied statisticians working on real world
problems and has been used by hundreds of thousands of researchers and
practitioners across the social, biological, and physical sciences,
engineering, education, sports, and finance. Stan provides several
state-of-the-art, gradient-based algorithms: full Bayesian inference
with Hamiltonian Monte Carlo, Laplace approximation based on L-BFGS
optimization, and autodiff variational inference (ADVI).

In the statistical software environment R, Stan is heavily relied upon for
development of applied statistics packages. Using Google's
[PageRank](https://www.sciencedirect.com/science/article/pii/S016975529800110X)
algorithm on the dependency graph [@de-Vries:2014] amongst the 19,159 R packages
listed on the Comprehensive R Archive Network (CRAN) as of 2022-12-31, three R
packages that exist solely to provide access to Stan rank quite well: `rstan`
ranks at number 70, `rstantools` 179, and `rstanarm` 502. Further, two Python
interfaces to Stan, `pystan` and `cmdstanpy`, both rank in the top 600 packages
by downloads on the Python Package Index (PyPI).

C++ can be cumbersome for algorithm prototyping.  As such, developers have been
requesting ways to access Stan models for algorithm development in Python, R,
and Julia. `BridgeStan` answers this call, making it easy for algorithm
developers to leverage existing Stan models in their evaluation, e.g., the
dozens of diverse models with reference posteriors in
[`posteriordb`](https://github.com/stan-dev/posteriordb) [@Magnusson:2022].  By
providing access to the method of Stan model, `BridgeStan` aides algorithm
development by making more consistent the models being tested and the
implementations of those models and their underlying mathematical
representations.

`BridgeStan` is an interface, written in C-compatible C++, between a Stan
program and any higher level language which exposes a C foreign function
interface. Julia, Python, and R each have C foreign function interfaces. Using
memory allocated within such higher level languages, `BridgeStan` provides
computations of the log joint density function, and its gradient, of a Stan
model, which is itself implemented using highly templated C++ from the Stan math
library. Using a memory-compatible C interface makes this possible even if the
host language (e.g., R) was compiled with a different compiler, something no
prior interface which exposed Stan's log density calculations could allow.

Other software in the Stan ecosystem provides some overlapping features with
`BridgeStan`.  For instance, `rstan` [@rstan] provides functions `log_prob` and
`grad_log_prob`, which provide access to the log joint density and its gradient.
Similarly, `httpstan` [@httpstan] offers `log_prob` and `log_prob_grad`.  Such
cases of similar functionality are unfortunately limited.  As of 2023-05-19,
`rstan` via CRAN is still on Stan version 2.21.0 (released 2019-10-18) and the
development version of `rstan`, which is not hosted on CRAN, is on Stan version
2.26.1 (released 2021-02-17), while the latest version of Stan is on 2.32.2
(released 2023-05-15).  Further, `rstan` is limited to the host language R.  On
the other hand, `httpstan` is a Python package which offers a REST API,
primarily targeting the Stan algorithms, which allows some limited access to the
methods of a Stan model.  The REST API may be used by languages other than
Python, but by design cannot take advantage of direct memory access of the host
language.  Additionally, `httpstan` is not natively supported on Windows
operating systems.  `BridgeStan` addresses these issues by providing a portable
and easy to maintain shim between any host language with a foreign function
interface to C and the core C++ of Stan.

Existing tools with similar automatic differentiation functionality
include `JAX` [@Bradbury:2018] and `Turing.jl` via the `JuliaAD`
ecosystem [@Ge:2018].  `BridgeStan` differs from these tools by
providing access to the existing, well-known DSL for modeling and
highly efficient CPU computation of the Stan ecosystem.  The Stan
community predominantly uses CPU hardware, and since Stan has been
tuned for CPU performance, `BridgeStan` is more efficient than its
competitors in implementing differentiable log densities on CPUs
[@Carpenter:2015; @Radul:2020; @Tarek:2020].  Like the immutable Stan
models they interface, `BridgeStan` functions are thread safe for
parallel applications. They also support all of the internal
parallelization of Stan models, such as internal parallel map
functions and GPU-enabled matrix operations.

`BridgeStan` enables memory allocated in the host language (Julia,
Python, or R), to be reused within Stan; though any language with a C
foreign function interface could be similarly interfaced to access
Stan methods. By avoiding unnecessary copies of vectors created in the
host language, `BridgeStan` is a zero-cost abstraction built upon
Stan's math library.

# Example

The probabilistic programming language Stan, together with its
automatic differentiation tools enable parameterizations of otherwise
numerically challenging distributions. Consider the following Stan
program, which encodes an isotropic multivariate Student-t
distribution of dimension $D$ and degrees of freedom $df$.

This parameterization[^1] of the Student-t distribution enables gradient-based
Markov chain Monte Carlo algorithms to capture the heaviness of the tails when
$df$ is less than say $30$. Calculating the gradient of the joint log density
of this parameterization of the Student-t distribution is not difficult, but it
is cumbersome and time consuming to encode in software. Since `BridgeStan` uses
Stan, users of `BridgeStan` can trust that their bespoke parameterizations of
numerically challenging distributions will be differentiated with
thoroughly tested tools from Stan.
\footnotesize
```stan
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
\normalsize
`BridgeStan` users can access the gradient of this model easily,
allowing for simple implementations of sampling algorithms. In the
below example, we show an implementation of the Metropolis-adjusted
Langevin algorithm (MALA) [@Besag:1994] built on `BridgeStan`.
\footnotesize
```python
import bridgestan as bs
import numpy as np

stan_model = "path/to/student-t.stan"
stan_data = "path/to/student-t.json"
model = bs.StanModel.from_stan_file(stan_model, stan_data)
D = model.param_unc_num()
M = 10000

def MALA(model, theta, epsilon=0.45):
    def correction(theta_prime, theta, grad_theta):
        x = theta_prime - theta - epsilon * grad_theta
        return (-0.25 / epsilon) * x.dot(x)

    lp, grad = model.log_density_gradient(theta)
    theta_prop = (
        theta
        + epsilon * grad
        + np.sqrt(2 * epsilon) * np.random.normal(size=model.param_unc_num())
    )

    lp_prop, grad_prop = model.log_density_gradient(theta_prop)
    if np.log(np.random.random()) < lp_prop + correction(
        theta, theta_prop, grad_prop
    ) - lp - correction(theta_prop, theta, grad):
        return theta_prop
    return theta

unc_draws = np.empty(shape=(M, D))
unc_draws[0] = MALA(model, np.random.normal(size=D))
for m in range(1, M):
    unc_draws[m] = MALA(model, unc_draws[m - 1])

# post processing: recover constrained/transformed parameters
draws = np.empty(shape=(M, model.param_num(include_tp=True, include_gq=True)))
for (i, draw) in enumerate(unc_draws):
    draws[i] = model.param_constrain(draw, include_tp=True, include_gq=True)
```
\normalsize

# Conclusion

On the [Stan Discourse forums](https://discourse.mc-stan.org/), statistical
algorithm developers have long asked for access to the gradients and Hessians that
underlie the statistical model of a Stan program, see for instance requests on
the Stan Discourse forums related to the phrase [extract gradient](https://discourse.mc-stan.org/search?q=extract%20gradient) or the
software from which `BridgeStan` is derived [Stan Model Server](https://github.com/bob-carpenter/stan-model-server/) and [ReddingStan](https://github.com/dmuck/redding-stan). `BridgeStan` enables access to
these methods, with a portable and in-memory solution. Further, because
statistical models are so easy to write in Stan, algorithm developers can write
their model in common statistical notation using the Stan programming language
and then rely on the Stan math library and its automatic differentiation toolset
to more easily build advanced gradient based statistical inference
algorithms. `BridgeStan` documentation and example programs are found at
<https://roualdes.github.io/bridgestan/index.html>.


[^1]: See Wikipedia's page on the [Student's t-distribution](https://en.wikipedia.org/wiki/Student%27s_t-distribution#Characterization)for a brief introduction to this parameterization.

# Acknowledgements

Edward A. Roualdes received support from Flatiron Institute during the beginning
of this project.

# References
