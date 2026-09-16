check_compile_model_works <- function(name) {
  base <- get_bridgestan_path(download = FALSE)

  file <- file.path(base, "test_models", name, paste0(name, ".stan"))

  lib <- file.path(base, "test_models", name, paste0(name, "_model.so"))
  unlink(lib, force = TRUE)

  out <- compile_model(file, stanc_args = c("--O1"))

  expect_true(file.exists(lib))
  expect_equal(normalizePath(lib), normalizePath(out))

  unlink(lib, force = TRUE)

  out <- compile_model(file, make_args = c("STAN_THREADS=True"))
}

test_that("compilation works", {
  check_compile_model_works(name = "multi")
})

test_that("compilation with bridgestan path containing spaces works", {
  temp_dir <- withr::local_tempdir(pattern = "Bridge Stan")
  bridgestan_path <- get_bridgestan_path(download = TRUE)
  file.copy(bridgestan_path, temp_dir, recursive = TRUE)
  temp_bridgestan_path <- file.path(temp_dir, basename(bridgestan_path))
  verify_bridgestan_path(temp_bridgestan_path)
  withr::with_envvar(c("BRIDGESTAN" = temp_bridgestan_path), {
    bridgestan_path <- get_bridgestan_path(download = FALSE)
    expect_equal(bridgestan_path, temp_bridgestan_path)
    check_compile_model_works(name = "multi")
  })
})

test_that("compilation fails on non-stan file", {
  expect_error(
    compile_model(file.path(base, "test_models", "simple", "simple.data.json")),
    "does not end with '.stan'"
  )
})

test_that("compilation fails on missing file", {
  expect_error(compile_model("badpath.stan"), "does not exist!")
})

test_that("compilation fails on bad syntax", {
  expect_error(
    compile_model(file.path(
      base,
      "test_models",
      "syntax_error",
      "syntax_error.stan"
    )),
    "Compilation failed"
  )
})

test_that("bad paths fail", {
  expect_error(set_bridgestan_path("badpath"), "does not exist!")
  expect_error(
    set_bridgestan_path(file.path(base, "test_models")),
    "does not contain file 'Makefile'"
  )
})
