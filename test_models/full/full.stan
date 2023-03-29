parameters {
  real a;
}
transformed parameters {
  real b = exp(a);
}
generated quantities {
  array[2] int d;
  for (i in 1:2) {
    d[i] = categorical_rng([0.1, 0.2, 0.2, 0.3, 0.2]');
  }
}
