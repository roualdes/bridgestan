library(bridgestan)

model <- StanModel$new("../test_models/bernoulli/bernoulli_model.so", "../test_models/bernoulli/bernoulli.data.json", 1234, 0)

print(paste0("This model's name is ", model$name(), "."))
print(paste0("This model has ", model$param_num(), " parameters."))


x <- runif(model$param_unc_num())
q <- log(x / (1 - x))

res <- model$log_density_gradient(q, jacobian = FALSE)

print(paste0("log_density and gradient of Bernoulli model: ",
             res$val, ", ", res$gradient))

