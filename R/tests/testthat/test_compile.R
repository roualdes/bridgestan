

test_that("compilation works", {
    name <- "multi"
    file <- file.path(base, "test_models", name, paste0(name, ".stan"))

    lib <- file.path(base, "test_models", name, paste0(name, "_model.so"))
    unlink(lib, force = TRUE)

    out <- compile_model(file, stanc_args = c("--O1"))

    expect_true(file.exists(lib))
    expect_equal(normalizePath(lib), normalizePath(out))

    unlink(lib, force = TRUE)

    out <- compile_model(file, make_args = c("STAN_THREADS=True"))
})

test_that("compilation fails on non-stan file", {
    expect_error(compile_model(file.path(base, "test_models", "simple", "simple.data.json")),
        "does not end with '.stan'")
})

test_that("compilation fails on missing file", {
    expect_error(compile_model("badpath.stan"), "does not exist!")
})

test_that("compilation fails on bad syntax", {
    expect_error(compile_model(file.path(base, "test_models", "syntax_error", "syntax_error.stan")),
        "Compilation failed")
})

test_that("bad paths fail", {
    expect_error(set_bridgestan_path("badpath"), "does not exist!")
    expect_error(set_bridgestan_path(file.path(base, "test_models")), "does not contain file 'Makefile'")
})
