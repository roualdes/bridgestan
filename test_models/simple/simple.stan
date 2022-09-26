// simple model where gradient is -y and Hessian is -unit
data {
  int<lower=0> N;
}
parameters {
  vector[N] y;
}
model {
  target += -0.5 * (y' * y);
}
