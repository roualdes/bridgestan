data {
  int<lower=0> N;
  vector[N] y;
}
parameters {
  vector[4] mu;
  cov_matrix[4] Omega;
}
model {
  y ~ multi_normal(mu, Omega);
}
