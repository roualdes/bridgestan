parameters {
   real theta;
}
model {
  theta ~ normal(0, 1);
  print("Hi from Stan!");
  print("theta = ", theta);
}
generated quantities {
  print("Hi from Stan GQ!");
}
