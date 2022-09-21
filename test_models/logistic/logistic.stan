data {
  int N;
  int K;
  array[N] int y;
  matrix[N, K] x;
}

parameters {
  real alpha;
  vector[K] beta;
}

model {
  y ~ bernoulli_logit(alpha + x * beta);
  alpha ~ normal(0, 1);
  beta ~ normal(0, 1);
}
