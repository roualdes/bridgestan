base = "../../.."

load_model <- function(name) {
    model <- StanModel$new(file.path(base,paste0("/test_models/", name, "/",name,"_model.so")), file.path(base, paste0("/test_models/", name, "/",name,".data.json")), 1234, 0)
    return(model)
}

test_that("missing data throws error", {
    expect_error(StanModel$new(file.path(base,paste0("/test_models/simple/simple_model.so")), "", 1234, 0))
})

simple <- load_model("simple")
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


bernoulli <- load_model("bernoulli")

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


fr_gaussian <- load_model("fr_gaussian")

cov_constrain <- function(v,D){
    L <- matrix(c(0), D, D)
    L[upper.tri(L, diag=TRUE)] <- v
    diag(L) <- exp(diag(L))
    return(t(L) %*% L)
}

test_that("param_constrain works for a nontrivial case", {
    D <- 4
    unc_size <- 10

    a <- rnorm(unc_size)
    B_expected <- cov_constrain(a, D)

    b <- fr_gaussian$param_constrain(a)
    B <- array(b, dim=c(D,D))

    expect_equal(B, B_expected)
})

test_that("param_unconstrain works for a nontrivial case", {
    D <- 4
    unc_size <- 10

    a <- rnorm(unc_size)
    B <- cov_constrain(a, D)
    
    c <- fr_gaussian$param_unconstrain(B)

    expect_equal(c, a)
})
