data {
  int<lower=0> M;
  int<lower=0> N;
  int<lower=0> P;
}
parameters {
  vector[M] alpha;
}
model {
  alpha ~ normal(0, 1);
}
