data {
  int<lower=0> M;
  int<lower=0> N;
  int<lower=0> P;
}
parameters {
  vector[M] alpha;
}
transformed parameters {
  vector[N] beta = rep_vector(1.23, N);
}
model {
  alpha ~ normal(0, 1);
}
generated quantities {
  array[P] real gamma = normal_rng(rep_vector(0, P), 1);
}
