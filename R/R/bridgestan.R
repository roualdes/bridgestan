#' StanModel
#'
#' R6 Class representing a compiled BridgeStan model.
#'
#' This model exposes log density, gradient, and Hessian information
#' as well as constraining and unconstraining transforms.
#' @export
StanModel <- R6::R6Class("StanModel",
  public = list(
    #' @description
    #' Create a Stan Model instance.
    #' @param lib A path to a compiled BridgeStan Shared Object file.
    #' @param data Either a JSON string literal or a path to a data file in JSON format ending in ".json".
    #' @param seed Seed for the RNG in the model object.
    #' @return A new StanModel.
    initialize = function(lib, data, seed) {
      if (.Platform$OS.type == "windows"){
        lib_old <- lib
        lib <- paste0(tools::file_path_sans_ext(lib), ".dll")
        file.copy(from=lib_old, to=lib)
      }

      private$seed <- seed
      private$lib <- tools::file_path_as_absolute(lib)
      private$lib_name <- tools::file_path_sans_ext(basename(lib))
      if (is.loaded("construct_R", PACKAGE = private$lib_name)) {
        warning(
          paste0("Loading a shared object '", lib, "' which is already loaded.\n",
                  "If the file has changed since the last time it was loaded, this load may not update the library!"
          )
        )
      }

      dyn.load(private$lib, PACKAGE = private$lib_name)
      ret <- .C("bs_construct_R",
        as.character(data), as.integer(seed),
        ptr_out = raw(8),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (all(ret$ptr_out == 0)) {
        stop(handle_error(private$lib_name, ret$err_msg, ret$err_ptr, "construct"))
      }
      private$model <- ret$ptr_out

      model_version <- self$model_version()
      if (packageVersion("bridgestan") != paste(model_version$major, model_version$minor, model_version$patch, sep = ".")) {
        warning(paste0("The version of the compiled model does not match the version of the R library. ",
                       "Consider recompiling the model."))
      }
    },
    #' @description
    #' Get the name of this StanModel.
    #' @return A character vector of the name.
    name = function() {
      .C("bs_name_R", as.raw(private$model),
        name_out = as.character(""),
        PACKAGE = private$lib_name
      )$name_out
    },
    #' @description
    #' Get compile information about this Stan model.
    #' @return A character vector of the Stan version and important flags.
    model_info = function() {
      .C("bs_model_info_R", as.raw(private$model),
        info_out = as.character(""),
        PACKAGE = private$lib_name
      )$info_out
    },

    model_version= function() {
      .C("bs_version_R",
        major = as.integer(0),
        minor = as.integer(0),
        patch = as.integer(0),
        PACKAGE = private$lib_name
      )
    },
    #' @description
    #' Return the indexed names of the (constrained) parameters.
    #' For containers, indexes are separated by periods (.).
    #'
    #' For example, the scalar `a` has indexed name "a", the vector entry `a[1]` has
    #' indexed name "a.1" and the matrix entry `a[2, 3]` has indexed name "a.2.3". Parameter
    #' order of the output is column major and more generally last-index major for containers.
    #' @param include_tp Whether to include variables from transformed parameters.
    #' @param include_gq Whether to include variables from generated quantities.
    #' @return A list of character vectors of the names.
    param_names = function(include_tp = FALSE, include_gq = FALSE) {
      .C("bs_param_names_R", as.raw(private$model),
        as.logical(include_tp), as.logical(include_gq),
        names_out = as.character(""),
        PACKAGE = private$lib_name
      )$names_out -> names
      strsplit(names, ",")[[1]]
    },
    #' @description
    #' Return the indexed names of the unconstrained parameters.
    #' For containers, indexes are separated by periods (.).
    #'
    #' For example, the scalar `a` has indexed name "a", the vector entry `a[1]` has
    #' indexed name "a.1" and the matrix entry `a[2, 3]` has indexed name "a.2.3". Parameter
    #' order of the output is column major and more generally last-index major for containers.
    #' @return A list of character vectors of the names.
    param_unc_names = function() {
      .C("bs_param_unc_names_R", as.raw(private$model),
        names_out = as.character(""),
        PACKAGE = private$lib_name
      )$names_out -> names
      strsplit(names, ",")[[1]]
    },
    #' @description
    #' Return the number of (constrained) parameters in the model.
    #' @param include_tp Whether to include variables from transformed parameters.
    #' @param include_gq Whether to include variables from generated quantities.
    #' @return The number of parameters in the model.
    param_num = function(include_tp = FALSE, include_gq = FALSE) {
      .C("bs_param_num_R", as.raw(private$model),
        as.logical(include_tp), as.logical(include_gq),
        num = as.integer(0),
        PACKAGE = private$lib_name
      )$num
    },
    #' @description
    #' Return the number of unconstrained parameters in the model.
    #'
    #' This function is mainly different from `param_num` when variables are declared with constraints.
    #' For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.
    #' @return The number of parameters in the model.
    param_unc_num = function() {
      .C("bs_param_unc_num_R", as.raw(private$model),
        num = as.integer(0),
        PACKAGE = private$lib_name
      )$num
    },
    #' @description
    #' Returns a vector of constrained parameters given the unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta_unc The vector of unconstrained parameters.
    #' @param include_tp Whether to also output the transformed parameters of the model.
    #' @param include_gq Whether to also output the generated quantities of the model.
    #' @param chain_id A chain ID used to offset a PRNG seeded with the model's seed
    #' which should be unique between calls. One of `rng` or `seed` must be specified
    #' if `include_gq` is `True`.
    #' @param rng The random number generator to use.  See `StanModel$new_rng()`.
    #' One of `rng` or `seed` must be specified if `include_gq` is `True`.
    #' @return The constrained parameters of the model.
    param_constrain = function(theta_unc, include_tp = FALSE, include_gq = FALSE, chain_id, rng) {
      if (missing(chain_id) && missing(rng)){
        if (include_gq) {
          stop("Either chain_id or rng must be specified if include_gq is True.")
        } else {
          chain_id <- 0
        }
      }
      if (!missing(rng)){
        vars <- .C("bs_param_constrain_R", as.raw(private$model),
          as.logical(include_tp), as.logical(include_gq), as.double(theta_unc),
          theta = double(self$param_num(include_tp = include_tp, include_gq = include_gq)),
          rng = as.raw(rng$rng),
          return_code = as.integer(0),
          err_msg = as.character(""),
          err_ptr = raw(8),
          PACKAGE = private$lib_name
        )
      } else {
        vars <- .C("bs_param_constrain_id_R", as.raw(private$model),
          as.logical(include_tp), as.logical(include_gq), as.double(theta_unc),
          theta = double(self$param_num(include_tp = include_tp, include_gq = include_gq)),
          chain_id = as.integer(chain_id),
          return_code = as.integer(0),
          err_msg = as.character(""),
          err_ptr = raw(8),
          PACKAGE = private$lib_name
        )
      }

      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "param_constrain"))
      }
      vars$theta
    },
    #' @description
    #' Create a new persistent PRNG object for use in `param_constrain()`.
    #' @param chain_id Identifier for a sequence in the RNG. This should be made
    #' a distinct number for each PRNG created with the same seed
    #' (for example, 1:N for N PRNGS).
    #' @param seed The seed for the PRNG. If this is not specified, the model's seed is used.
    #' @return A `StanRNG` object.
    new_rng = function(chain_id, seed) {
      if (missing(seed)){
        seed <- private$seed
      }
      StanRNG$new(private$lib_name, seed, chain_id)
    },
    #' @description
    #' Returns a vector of unconstrained parameters give the constrained parameters.
    #'
    #' It is assumed that these will be in the same order as internally represented by
    #' the model (e.g., in the same order as `StanModel$param_names()`).
    #' If structured input is needed, use `StanModel$param_unconstrain_json()`.
    #' See also `StanModel$param_constrain()`, the inverse of this function.
    #' @param theta The vector of constrained parameters.
    #' @return The unconstrained parameters of the model.
    param_unconstrain = function(theta) {
      vars <- .C("bs_param_unconstrain_R", as.raw(private$model),
        as.double(theta),
        theta_unc = double(self$param_unc_num()),
        return_code = as.integer(0),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "param_unconstrain"))
      }
      vars$theta_unc
    },
    #' @description
    #' This accepts a JSON string of constrained parameters and returns the unconstrained parameters.
    #'
    #' The JSON is expected to be in the [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).
    #' @param json Character vector containing a string representation of JSON data.
    #' @return The unconstrained parameters of the model.
    param_unconstrain_json = function(json) {
      vars <- .C("bs_param_unconstrain_json_R", as.raw(private$model),
        as.character(json),
        theta_unc = double(self$param_unc_num()),
        return_code = as.integer(0),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "param_unconstrain_json"))
      }
      vars$theta_unc
    },
    #' @description
    #' Return the log density of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta_unc The vector of unconstrained parameters.
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return The log density.
    log_density = function(theta_unc, propto = TRUE, jacobian = TRUE) {
      vars <- .C("bs_log_density_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.double(theta_unc),
        val = double(1),
        return_code = as.integer(0),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "log_density"))
      }
      vars$val
    },
    #' @description
    #' Return the log density and gradient of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta_unc The vector of unconstrained parameters.
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return List containing entries `val` (the log density) and `gradient` (the gradient).
    log_density_gradient = function(theta_unc, propto = TRUE, jacobian = TRUE) {
      dims <- self$param_unc_num()
      vars <- .C("bs_log_density_gradient_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.double(theta_unc),
        val = double(1), gradient = double(dims),
        return_code = as.integer(0),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "log_density_gradient"))
      }
      list(val = vars$val, gradient = vars$gradient)
    },
    #' @description
    #' Return the log density, gradient, and Hessian of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta_unc The vector of unconstrained parameters.
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return List containing entries `val` (the log density), `gradient` (the gradient), and `hessian` (the Hessian).
    log_density_hessian = function(theta_unc, propto = TRUE, jacobian = TRUE) {
      dims <- self$param_unc_num()
      vars <- .C("bs_log_density_hessian_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.double(theta_unc),
        val = double(1), gradient = double(dims), hess = double(dims * dims),
        return_code = as.integer(0),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop(handle_error(private$lib_name, vars$err_msg, vars$err_ptr, "log_density_hessian"))
      }
      list(val = vars$val, gradient = vars$gradient, hessian = matrix(vars$hess, nrow = dims, byrow = TRUE))
    }
  ),
  private = list(
    lib = NA,
    lib_name = NA,
    model = NA,
    seed = NA,
    finalize = function() {
      .C("bs_destruct_R",
        as.raw(private$model),
        PACKAGE = private$lib_name
      )
    }
  ),
  cloneable=FALSE
)
#' Get and free the error message stored at the C++ pointer
#' @keywords internal
handle_error <- function(lib_name, err_msg, err_ptr, function_name) {
  if (all(err_ptr == 0)) {
    return(paste("Unknown error in", function_name))
  } else {
    .C("bs_free_error_msg_R", as.raw(err_ptr), PACKAGE = lib_name)
    return(err_msg)
  }
}

#' StanRNG
#'
#' RNG object for use with `StanModel$param_constrain()`
#' @field rng The pointer to the RNG object.
#' @keywords internal
StanRNG <- R6::R6Class("StanRNG",
  public = list(
    #' @description
    #' Create a StanRng
    #' @param lib_name The name of the Stan dynamic library.
    #' @param seed The seed for the RNG.
    #' @param chain_id The chain ID for the RNG.
    #' @return A new StanRNG.
    initialize = function(lib_name, seed, chain_id) {
      private$lib_name <- lib_name

      vars <- .C("bs_construct_rng_R",
        as.integer(seed),
        as.integer(chain_id),
        ptr_out = raw(8),
        err_msg = as.character(""),
        err_ptr = raw(8),
        PACKAGE = private$lib_name
      )

      if (all(vars$ptr_out == 0)) {
        stop(handle_error("construct_rng", vars$err_msg, vars$err_ptr, private$lib_name))
      } else {
        self$rng <- vars$ptr_out
      }
    },
    rng = NA
  ),
  private = list(
    lib = NA,
    lib_name = NA,
    finalize = function() {
      .C("bs_destruct_rng_R",
        as.raw(self$rng),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
    }
  ),
  cloneable=FALSE
)
