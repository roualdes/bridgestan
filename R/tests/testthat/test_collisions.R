
test_that("loading another library didn't break prior ones", {
    bernoulli <- load_model("bernoulli")
    simple <- load_model("simple")

    if (.Platform$OS.type == "windows") {
        dll = "./test_collisions.dll"
    } else {
        dll = "./test_collisions.so"
    }
    skip_if_not(file.exists(dll), "Compiled DLL not found")

    dyn.load(dll)
    expect_equal(bernoulli$name(), "bernoulli_model")
    expect_equal(simple$name(), "simple_model")
})
