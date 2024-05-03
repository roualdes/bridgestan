IS_WINDOWS <- isTRUE(.Platform$OS.type == "windows")
MAKE <- Sys.getenv("MAKE", ifelse(IS_WINDOWS, "mingw32-make", "make"))


verify_bridgestan_path <- function(path) {
    suppressWarnings({
        folder <- normalizePath(path)
    })
    if (!dir.exists(folder)) {
        stop(paste0("BridgeStan folder '", folder, "' does not exist!\n", "If you need to set a different location, call 'set_bridgestan_path()'"))
    }
    makefile <- file.path(folder, "Makefile")
    if (!file.exists(makefile)) {
        stop(paste0("BridgeStan folder '", folder, "' does not contain file 'Makefile',",
            " please ensure it is built properly!\n", "If you need to set a different location, call 'set_bridgestan_path()'"))
    }
}

#' @title Function `set_bridgestan_path()`
#' @description Set the path to BridgeStan.
#' @details This should point to the top-level folder of the repository.
#' @export
set_bridgestan_path <- function(path) {
    verify_bridgestan_path(path)
    Sys.setenv(BRIDGESTAN = normalizePath(path))
}

#' Get the path to BridgeStan.
#'
#' By default this is set to the value of the environment
#' variable `BRIDGESTAN`.
#'
#' If there is no path set, this function will download
#' a matching version of BridgeStan to a folder called
#' `.bridgestan` in the user's home directory.
#'
#' @seealso [set_bridgestan_path()]
get_bridgestan_path <- function() {
    # try to get from environment
    path <- Sys.getenv("BRIDGESTAN", unset = "")
    if (path == "") {
        path <- CURRENT_BRIDGESTAN
        tryCatch({
            verify_bridgestan_path(path)
        }, error = function(e) {
            print(paste0("BridgeStan not found at location specified by $BRIDGESTAN ",
                "environment variable, downloading version ", packageVersion("bridgestan"),
                " to ", path))
            get_bridgestan_src()
        })
        num_files <- length(list.files(HOME_BRIDGESTAN))
        if (num_files >= 5) {
            warning(paste0("Found ", num_files, " different versions of BridgeStan in ",
                HOME_BRIDGESTAN, ". Consider deleting old versions to save space."))
        }
        print("Done!")
    }

    return(path)
}


#' @title Function `compile_model()`
#' @description Compiles a Stan model.
#' @details Run BridgeStan's Makefile on a `.stan` file, creating
#' the `.so` used by the StanModel class.
#' This function checks that the path to BridgeStan is valid
#' and will error if not. This can be set with `set_bridgestan_path`.
#'
#' @param stan_file A path to a Stan model file.
#' @param stanc_arg A vector of arguments to pass to stanc3.
#' For example, `c('--O1')` will enable compiler optimization level 1.
#' @param make_args A vector of additional arguments to pass to Make.
#' For example, `c('STAN_THREADS=True')` will enable
#' threading for the compiled model. If the same flags are defined
#' in `make/local`, the versions passed here will take precedent.
#' @return Path to the compiled model.
#'
#' @seealso [bridgestan::set_bridgestan_path()]
#' @export
compile_model <- function(stan_file, stanc_args = NULL, make_args = NULL) {
    verify_bridgestan_path(get_bridgestan_path())
    suppressWarnings({
        file_path <- normalizePath(stan_file)
    })
    if (tools::file_ext(file_path) != "stan") {
        stop(paste0("File '", file_path, "' does not end with '.stan'"))
    }
    if (!file.exists(file_path)) {
        stop(paste0("File '", file_path, "' does not exist!"))
    }

    output <- paste0(tools::file_path_sans_ext(file_path), "_model.so")
    stancflags <- paste("--include-paths=.", paste(stanc_args, collapse = " "))

    flags <- c(paste("-C", get_bridgestan_path()), make_args, paste0("STANCFLAGS=\"",
        stancflags, "\""), output)

    suppressWarnings({
        res <- system2(MAKE, args = flags, stdout = TRUE, stderr = TRUE)
    })
    res_attrs <- attributes(res)
    if ("status" %in% names(res_attrs) && res_attrs$status != 0) {
        stop(paste0("Compilation failed with error code ", res_attrs$status, "\noutput:\n",
            paste(res, collapse = "\n")))
    }

    return(output)
}

tbb_found <- function() {
    suppressWarnings(out <- system2("where.exe", "tbb.dll", stdout = NULL, stderr = NULL))
    return(out == 0)
}

WINDOWS_PATH_SET <- FALSE

windows_dll_path_setup <- function() {
    if (.Platform$OS.type == "windows" && !WINDOWS_PATH_SET) {

        if (tbb_found()) {
            assign("WINDOWS_PATH_SET", TRUE, envir = .GlobalEnv)
        } else {
            tbb_path <- file.path(get_bridgestan_path(), "stan", "lib", "stan_math",
                "lib", "tbb")
            Sys.setenv(PATH = paste(tbb_path, Sys.getenv("PATH"), sep = ";"))
            assign("WINDOWS_PATH_SET", tbb_found(), envir = .GlobalEnv)
        }
    }
}
