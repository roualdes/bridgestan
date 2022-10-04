parameters {
  simplex[5] theta;
}
model {
  theta ~ dirichlet(rep_vector(2, 5));
}
