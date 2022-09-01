source("../bridgestan.R")

simple <- Bridge$new("../stan/simple/simple_model.so", "../stan/simple/simple.data.json", 1234, 0)
simple$name()
simple$param_names()
simple$param_unc_num()

x <- runif(5)
print("grad(x) should be -x:", x)
print(x)
simple$log_density_gradient(x)$grad
print("Hessian should be -I:")
simple$log_density_hessian(x)$hess


bernoulli <- Bridge$new("../stan/bernoulli/bernoulli_model.so", "../stan/bernoulli/bernoulli.data.json", 1234, 0)
bernoulli$name()
simple$name()
x <- runif(bernoulli$param_unc_num())
q <- log(x / (1 - x))
print("x and constrain(q) should match")
print(x)
print(bernoulli$param_constrain(q))
print("q and unconstrain(x) should match")
print(q)
print(bernoulli$param_unconstrain(x))
print(bernoulli$param_unconstrain_json(paste("{\"theta\":", as.character(x), "}")))
