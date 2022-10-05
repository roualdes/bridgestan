base = "../../.."


simple <- StanModel$new(file.path(base, "/test_models/simple/simple_model.so"), file.path(base, "/test_models/simple/simple.data.json"), 1234, 0)
test_that("simple_model name is correct", {
    expect_identical(simple$name(), "simple_model")
})

test_that("simple_model info exists", {
    expect_true(grepl("STAN_OPENCL", simple$model_info(), fixed = TRUE))
})

test_that("simple_model param_names are correct", {
    expect_equal(simple$param_names(), c("y.1", "y.2", "y.3", "y.4", "y.5"))
})

test_that("simple_model has 5 unconstrained parameters", {
    expect_equal(simple$param_unc_num(), 5)
})


test_that("simple_model grad(x) is -x",{
    x <- runif(5)
    expect_equal(-x, simple$log_density_gradient(x)$gradient)
})

test_that("simple_model Hessian is -I",{
    x <- runif(5)
    expect_equal(-diag(5), simple$log_density_hessian(x)$hessian)
})


bernoulli <- StanModel$new(file.path(base, "/test_models/bernoulli/bernoulli_model.so"), file.path(base, "/test_models/bernoulli/bernoulli.data.json"), 1234, 0)

test_that("loading another library didn't break prior ones", {
    if (.Platform$OS.type == "windows"){
        dll = "./test_collisions.dll"
    } else {
        dll = "./test_collisions.so"
    }
    if (file.exists(dll)) {
      dyn.load(dll)
      expect_equal(bernoulli$name(), "bernoulli_model")
      expect_equal(simple$name(), "simple_model")
    }
})

test_that("bernoulli constrain works", {
    x <- runif(bernoulli$param_unc_num())
    q <- log(x / (1 - x))
    expect_equal(x, bernoulli$param_constrain(q))
})

test_that("bernoulli unconstrain works", {
    x <- runif(bernoulli$param_unc_num())
    q <- log(x / (1 - x))
    expect_equal(q, bernoulli$param_unconstrain(x))
    expect_equal(q, bernoulli$param_unconstrain_json(paste("{\"theta\":", as.character(x), "}")))
})
