test_that("downloading source code works", {
  withr::with_envvar(c("BRIDGESTAN" = ""), {
    existing <- get_bridgestan_path(download = FALSE)

    if (existing != "") {
      unlink(existing, recursive = TRUE)
    }

    expect_equal(get_bridgestan_path(download = FALSE), "")
    verify_bridgestan_path(get_bridgestan_path(download = TRUE))
    verify_bridgestan_path(get_bridgestan_path(download = FALSE))
  })
})
