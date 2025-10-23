base = "../../.."

loaded <- c()

load_model <- function(name, include_data = TRUE) {
  if (include_data) {
    data <- file.path(base, "test_models", name, paste0(name, ".data.json"))
  } else {
    data <- ""
  }

  file <- file.path(base, "test_models", name, paste0(name, ".stan"))

  if (name %in% loaded) {
    expect_warning(
      model <- StanModel$new(file, data, 1234),
      ".*which is already loaded.*"
    )
  } else {
    loaded <<- c(loaded, name)
    model <- StanModel$new(file, data, 1234)
  }

  return(model)
}
