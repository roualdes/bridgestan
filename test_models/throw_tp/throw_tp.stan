parameters {
  real y;
}
transformed parameters {
  real exp_y = exp(y);
  reject("");
}
