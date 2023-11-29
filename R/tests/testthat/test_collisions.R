
test_that("loading another library didn't break prior ones", {
    if (.Platform$OS.type == "windows") {
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
