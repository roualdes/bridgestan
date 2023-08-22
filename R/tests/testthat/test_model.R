

test_that("missing data throws error", {
    expect_error(load_model("simple", include_data = FALSE))
})

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

test_that("simple_model grad(x) is -x", {
    x <- runif(5)
    expect_equal(-x, simple$log_density_gradient(x)$gradient)
})


test_that("models can be passed NAN or INF", {
    x <- runif(5)
    x[1] <- NaN
    x[2] <- Inf
    x[3] <- -Inf
    grad <- simple$log_density_gradient(x)$gradient
    expect_equal(-x, grad)
    expect_true(is.nan(grad[1]))
    expect_true(is.infinite(grad[2]))
    expect_true(is.infinite(grad[3]))
})


test_that("simple_model Hessian is -I", {
    x <- runif(5)
    expect_equal(-diag(5), simple$log_density_hessian(x)$hessian)
})

test_that("simple_model Hvp returns -v", {
    x <- runif(5)
    v <- runif(5)
    expect_equal(-v, simple$log_density_hessian_vector_product(x, v)$Hvp)
})

test_that("bernoulli constrain works", {
    x <- runif(bernoulli$param_unc_num())
    q <- log(x/(1 - x))
    expect_equal(x, bernoulli$param_constrain(q))
})

test_that("bernoulli unconstrain works", {
    x <- runif(bernoulli$param_unc_num())
    q <- log(x/(1 - x))
    expect_equal(q, bernoulli$param_unconstrain(x))
    expect_equal(q, bernoulli$param_unconstrain_json(paste("{\"theta\":", as.character(x),
        "}")))
})


fr_gaussian <- load_model("fr_gaussian")

cov_constrain <- function(v, D) {
    L <- matrix(c(0), D, D)
    L[upper.tri(L, diag = TRUE)] <- v
    diag(L) <- exp(diag(L))
    return(t(L) %*% L)
}

test_that("param_constrain works for a nontrivial case", {
    D <- 4
    unc_size <- 10

    a <- rnorm(unc_size)
    B_expected <- cov_constrain(a, D)

    b <- fr_gaussian$param_constrain(a)
    B <- array(b, dim = c(D, D))

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

test_that("param_constrain handles rng arguments", {
    full <- load_model("full", include_data = FALSE)
    expect_equal(1, length(full$param_constrain(c(1.2))))
    expect_equal(2, length(full$param_constrain(c(1.2), include_tp = TRUE)))
    rng <- full$new_rng(123)
    expect_equal(3, length(full$param_constrain(c(1.2), include_gq = TRUE, rng = rng)))
    expect_equal(4, length(full$param_constrain(c(1.2), include_tp = TRUE, include_gq = TRUE,
        rng = rng)))

    # check reproducibility
    expect_equal(full$param_constrain(c(1.2), include_gq = TRUE, rng = full$new_rng(456)),
        full$param_constrain(c(1.2), include_gq = TRUE, rng = full$new_rng(456)))

    # require at least one present
    expect_error(full$param_constrain(c(1.2), include_gq = TRUE), "rng must be provided")
})


test_that("constructor propagates errors", {
    expect_error(load_model("throw_data", include_data = FALSE), "find this text: datafails")
})

test_that("log_density propagates errors", {
    m <- load_model("throw_lp", include_data = FALSE)
    expect_error(m$log_density(c(1.2)), "find this text: lpfails")
    expect_error(m$log_density_gradient(c(1.2)), "find this text: lpfails")
    expect_error(m$log_density_hessian(c(1.2)), "find this text: lpfails")
})

test_that("param_constrain propagates errors", {
    m1 <- load_model("throw_tp", include_data = FALSE)
    m1$param_constrain(c(1.2))  # no error
    expect_error(m1$param_constrain(c(1.2), include_tp = TRUE), "find this text: tpfails")


    m2 <- load_model("throw_gq", include_data = FALSE)
    m2$param_constrain(c(1.2))  # no error
    expect_error(m2$param_constrain(c(1.2), include_gq = TRUE, rng = m2$new_rng(1234)),
        "find this text: gqfails")
})
