data {
  int<lower=0> N;
  vector[N] x;
  vector[N] y;
}
parameters {
  real alpha;
  real beta;
  real<lower=0> sigma;
}
transformed parameters {
  vector[N] mu = alpha + beta * x;
}
model {
  alpha ~ normal(0, 5);
  beta ~ normal(0, 3);
  sigma ~ cauchy(0, 1.5);
  y ~ normal(mu, sigma);
}
generated quantities {
  real x_gen = normal_rng(0, 2);
  real y_gen = normal_rng(alpha + beta * x_gen, sigma);
}
