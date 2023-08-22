base = "../../.."

load_model <- function(name, include_data = TRUE) {
    if (include_data) {
        data = file.path(base, "test_models", name, paste0(name, ".data.json"))
    } else {
        data = ""
    }
    model <- StanModel$new(file.path(base, "test_models", name, paste0(name, "_model.so")),
        data, 1234)
    return(model)
}

simple <- load_model("simple")
bernoulli <- load_model("bernoulli")
