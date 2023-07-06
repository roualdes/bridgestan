functions {
  vector sho(real t,
             vector y,
             real theta) {
    vector[2] dydt;
    dydt[1] = y[2];
    dydt[2] = -y[1] - theta * y[2];
    return dydt;
  }
}
data {
  int<lower=1> T;
  vector[2] y0;
  real t0;
  array[T] real ts;
  real theta;
}
model {
}
generated quantities {
  array[T] vector[2] y_sim = ode_bdf(sho, y0, t0, ts, theta);
  // add measurement error
  for (t in 1:T) {
    y_sim[t, 1] += normal_rng(0, 0.1);
    y_sim[t, 2] += normal_rng(0, 0.1);
  }
}
