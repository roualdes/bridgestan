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
    #' Create a Stan Model instace.
    #' @param lib A path to a compiled BridgeStan Shared Object file.
    #' @param data A path to a JSON data file for the model.
    #' @param rng_seed Seed for the RNG in the model object.
    #' @param chain_id Used to offset the RNG by a fixed amount.
    #' @return A new StanModel.
    initialize = function(lib, data, rng_seed, chain_id) {
      if (.Platform$OS.type == "windows"){
        lib_old <- lib
        lib <- paste0(tools::file_path_sans_ext(lib), ".dll")
        file.copy(from=lib_old, to=lib)
      }

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
      .C("construct_R",
        as.character(data), as.integer(rng_seed), as.integer(chain_id),
        ptr_out = raw(8),
        PACKAGE = private$lib_name
      )$ptr_out -> ptr_out
      if (all(ptr_out == 0)) {
        stop("could not construct model RNG")
      }
      private$model <- ptr_out
    },
    #' @description
    #' Get the name of this StanModel
    #' @return A character vector of the name.
    name = function() {
      .C("name_R", as.raw(private$model),
        name_out = as.character(""),
        PACKAGE = private$lib_name
      )$name_out
    },
    #' @description
    #' Get compile information about this Stan model.
    #' @return A character vector of the Stan version and important flags.
    model_info = function() {
      .C("model_info_R", as.raw(private$model),
        info_out = as.character(""),
        PACKAGE = private$lib_name
      )$info_out
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
      .C("param_names_R", as.raw(private$model),
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
      .C("param_unc_names_R", as.raw(private$model),
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
      .C("param_num_R", as.raw(private$model),
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
      .C("param_unc_num_R", as.raw(private$model),
        num = as.integer(0),
        PACKAGE = private$lib_name
      )$num
    },
    #' @description
    #' This turns a vector of unconstrained params into constrained parameters
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta_unc The vector of unconstrained parameters
    #' @param include_tp Whether to also output the transformed parameters of the model.
    #' @param include_gq Whether to also output the generated quantities of the model.
    #' @return The constrained parameters of the model.
    param_constrain = function(theta_unc, include_tp = FALSE, include_gq = FALSE) {
      vars <- .C("param_constrain_R", as.raw(private$model),
        as.logical(include_tp), as.logical(include_gq), as.numeric(theta_unc),
        theta = double(self$param_num(include_tp = include_tp, include_gq = include_gq)),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in param_constrain(); see stderr for messages")
      }
      vars$theta
    },
    #' @description
    #' This turns a vector of constrained params into unconstrained parameters.
    #'
    #' It is assumed that these will be in the same order as internally represented by
    #' the model (e.g., in the same order as `StanModel$param_names()`).
    #' If structured input is needed, use `StanModel$param_unconstrain_json()`.
    #' See also `StanModel$param_constrain()`, the inverse of this function.
    #' @param theta The vector of constrained parameters
    #' @return The unconstrained parameters of the model.
    param_unconstrain = function(theta) {
      vars <- .C("param_unconstrain_R", as.raw(private$model),
        as.numeric(theta),
        theta_unc = double(self$param_unc_num()),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in param_unconstrain(); see stderr for messages")
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
      vars <- .C("param_unconstrain_json_R", as.raw(private$model),
        as.character(json),
        theta_unc = double(self$param_unc_num()),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in param_unconstrain_json(); see stderr for messages")
      }
      vars$theta_unc
    },
    #' @description
    #' Return the log density of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta The vector of unconstrained parameters
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return The log density.
    log_density = function(theta, propto = TRUE, jacobian = TRUE) {
      vars <- .C("log_density_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.numeric(theta),
        val = double(1),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in log_density(); see stderr for messages")
      }
      vars$val
    },
    #' @description
    #' Return the log density and gradient of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta The vector of unconstrained parameters
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return List containing entries `val` (the log density) and `gradient` (the gradient).
    log_density_gradient = function(theta, propto = TRUE, jacobian = TRUE) {
      dims <- self$param_unc_num()
      vars <- .C("log_density_gradient_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.numeric(theta),
        val = double(1), gradient = double(dims),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in log_density_gradient(); see stderr for messages")
      }
      list(val = vars$val, gradient = vars$gradient)
    },
    #' @description
    #' Return the log density, gradient, and Hessian of the specified unconstrained parameters.
    #' See also `StanModel$param_unconstrain()`, the inverse of this function.
    #' @param theta The vector of unconstrained parameters
    #' @param propto If `TRUE`, drop terms which do not depend on the parameters.
    #' @param jacobian If `TRUE`, include change of variables terms for constrained parameters.
    #' @return List containing entries `val` (the log density), `gradient` (the gradient), and `hessian` (the Hessian).
    log_density_hessian = function(theta, propto = TRUE, jacobian = TRUE) {
      dims <- self$param_unc_num()
      vars <- .C("log_density_hessian_R", as.raw(private$model),
        as.logical(propto), as.logical(jacobian), as.numeric(theta),
        val = double(1), gradient = double(dims), hess = double(dims * dims),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
      if (vars$return_code) {
        stop("C++ exception in log_density_hessian(); see stderr for messages")
      }
      list(val = vars$val, gradient = vars$gradient, hessian = matrix(vars$hess, nrow = dims, byrow = TRUE))
    }
  ),
  private = list(
    lib = NA,
    lib_name = NA,
    model = NA,
    finalize = function() {
      .C("destruct_R",
        as.raw(private$model),
        return_code = as.integer(0),
        PACKAGE = private$lib_name
      )
    }
  ),
  cloneable=FALSE
)
