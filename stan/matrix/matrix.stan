parameters {
  matrix[3, 2] A;
}
transformed parameters {
  array[3, 2] real B;
}
generated quantities {
  int c;
}
