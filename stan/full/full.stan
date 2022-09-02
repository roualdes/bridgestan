parameters {
  real a;
}
transformed parameters {
  real b = exp(a);
}
generated quantities {
  vector[2] c = [1, 2]';
}
