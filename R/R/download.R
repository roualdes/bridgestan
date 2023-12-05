current_version <- packageVersion("bridgestan")
HOME_BRIDGESTAN <- path.expand(file.path("~", ".bridgestan"))
CURRENT_BRIDGESTAN <- file.path(HOME_BRIDGESTAN, paste0("bridgestan-", current_version))

RETRIES <- 5

get_bridgestan_src <- function() {
    url <- paste0("https://github.com/roualdes/bridgestan/releases/download/", "v",
        current_version, "/bridgestan-", current_version, ".tar.gz")

    dir.create(HOME_BRIDGESTAN, showWarnings = FALSE, recursive = TRUE)
    temp <- tempfile()
    err_text <- paste("Failed to download BridgeStan", current_version, "from github.com.")
    for (i in 1:RETRIES) {
        tryCatch({
            download.file(url, destfile = temp, mode = "wb", quiet = TRUE, method = "auto")
        }, error = function(e) {
            cat(err_text, "\n")
            if (i == RETRIES) {
                stop(err_text, call. = FALSE)
            } else {
                cat("Retrying (", i + 1, "/", RETRIES, ")...\n", sep = "")
                Sys.sleep(1)
            }
        })
    }

    tryCatch({
        untar(temp, exdir = HOME_BRIDGESTAN)
    }, error = function(e) {
        stop(paste("Failed to unpack", url, "during installation"), call. = FALSE)
    })

    unlink(temp)
}
