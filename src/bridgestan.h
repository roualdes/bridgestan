#ifndef BRIDGESTAN_H
#define BRIDGESTAN_H

/// \file bridgestan.h

#ifdef __cplusplus
#include "model_rng.hpp"
#include "callback_stream.hpp"
extern "C" {
#else
#include <stddef.h>   // for size_t
#include <stdbool.h>  // for bool
typedef struct bs_model bs_model;  ///< Opaque type for model
typedef struct bs_rng bs_rng;      ///< Opaque type for RNG

/** Type signature for optional print callback */
typedef void (*STREAM_CALLBACK)(const char* data, size_t size);
#endif

// Macros to control visibility of symbols in the shared library.
#if defined _WIN32 || defined __MINGW32__
#ifdef BRIDGESTAN_EXPORT
#define BS_PUBLIC __declspec(dllexport)
#else
#define BS_PUBLIC __declspec(dllimport)
#endif
#else
#define BS_PUBLIC __attribute__((visibility("default")))
#endif

/**
 * Version information for the BridgeStan library.
 * @note These are *not* the version of the wrapped Stan library.
 * @note These were not available pre-2.0.0, so their absence
 * implies the library is in the 1.0.x series
 */
BS_PUBLIC extern int bs_major_version;
BS_PUBLIC extern int bs_minor_version;
BS_PUBLIC extern int bs_patch_version;

/**
 * Construct an instance of a model wrapper.
 * Data must be encoded in JSON as indicated
 * in the *CmdStan Reference Manual*.
 *
 * @param[in] data C-style string. This is either a
 * path to JSON-encoded data file (must end with ".json"),
 * a JSON string literal, or nullptr. An empty string or null
 * pointer are both interpreted as no data.
 * @param[in] seed seed for PRNG used during model construction.
 * This PRNG is used for RNG functions in the `transformed data`
 * block of the model, and then discarded.
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return pointer to constructed model or `nullptr` if construction
 * fails
 */
BS_PUBLIC bs_model* bs_model_construct(const char* data, unsigned int seed,
                                       char** error_msg);

/**
 * Destroy the model.
 *
 * @param[in] m pointer to model structure
 */
BS_PUBLIC void bs_model_destruct(bs_model* m);

/**
 * Free the error messages created by other methods.
 *
 * @param[in] error_msg pointer to error message
 */
BS_PUBLIC void bs_free_error_msg(char* error_msg);

/**
 * Return the name of the specified model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model wrapper is destroyed.
 *
 * @param[in] m pointer to model and RNG structure
 * @return name of model
 */
BS_PUBLIC const char* bs_name(const bs_model* m);

/**
 * Return information about the compiled model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model wrapper is destroyed.
 *
 * @param[in] m pointer to model structure
 * @return Information about the model including Stan version, Stan defines, and
 * compiler flags.
 */
BS_PUBLIC const char* bs_model_info(const bs_model* m);

/**
 * Return a comma-separated sequence of indexed parameter names,
 * including the transformed parameters and/or generated quantities
 * as specified.
 *
 * The parameters are returned in the order they are declared.
 * Multivariate parameters are return in column-major (more
 * generally last-index major) order.  Parameters are separated with
 * periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
 * 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
 *
 * The returned string should not be modified; it is freed when the
 * model wrapper is destroyed.
 *
 * @param[in] m pointer to model structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return CSV-separated, indexed, parameter names
 */
BS_PUBLIC const char* bs_param_names(const bs_model* m, bool include_tp,
                                     bool include_gq);

/**
 * Return a comma-separated sequence of unconstrained parameters.
 * Only parameters are unconstrained, so there are no unconstrained
 * transformed parameters or generated quantities.
 *
 * The parameters are returned in the order they are declared.
 * Multivariate parameters are return in column-major (more
 * generally last-index major) order.  Parameters are separated with
 * periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
 * 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
 *
 * The returned string should not be modified; it is freed when the
 * model wrapper is destroyed.
 *
 * @param[in] m pointer to model structure
 * @return CSV-separated, indexed, unconstrained parameter names
 */
BS_PUBLIC const char* bs_param_unc_names(const bs_model* m);

/**
 * Return the number of scalar parameters, optionally including the
 * number of transformed parameters and/or generated quantities.
 * For example, a 2 x 3 matrix counts as 6 scalar parameters.
 *
 * @param[in] m pointer to model structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return number of parameters
 */
BS_PUBLIC int bs_param_num(const bs_model* m, bool include_tp, bool include_gq);

/**
 * Return the number of unconstrained parameters.  The number of
 * unconstrained parameters might be smaller than the number of
 * parameters if the unconstrained space has fewer dimensions than
 * the constrained (e.g., for simplexes or correlation matrices).
 *
 * @param[in] m pointer to model structure
 * @return number of unconstrained parameters
 */
BS_PUBLIC int bs_param_unc_num(const bs_model* m);

/**
 * Set the sequence of constrained parameters based on the specified
 * unconstrained parameters, including transformed parameters and/or
 * generated quantities as specified, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] m pointer to model structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @param[in] theta_unc sequence of unconstrained parameters
 * @param[out] theta sequence of constrained parameters
 * @param[in] rng pointer to pseudorandom number generator, should be created
 * by bs_rng_construct(). This is only required when `include_gq` is `true`,
 * otherwise it can be null.
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_param_constrain(const bs_model* m, bool include_tp,
                                 bool include_gq, const double* theta_unc,
                                 double* theta, bs_rng* rng, char** error_msg);

/**
 * Set the sequence of unconstrained parameters based on the
 * specified constrained parameters, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] m pointer to model structure
 * @param[in] theta sequence of constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_param_unconstrain(const bs_model* m, const double* theta,
                                   double* theta_unc, char** error_msg);

/**
 * Set the sequence of unconstrained parameters based on the JSON
 * specification of the constrained parameters, and return a return
 * code of 0 for success and -1 for failure. The JSON schema assumed
 * is fully defined in the *CmdStan Reference Manual*.
 *
 * @param[in] m pointer to model structure
 * @param[in] json JSON-encoded constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_param_unconstrain_json(const bs_model* m, const char* json,
                                        double* theta_unc, char** error_msg);

/**
 * Set the log density of the specified parameters, dropping
 * constants if `propto` is `true` and including the Jacobian terms
 * resulting from constraining parameters if `jacobian` is `true`,
 * and return a return code of 0 for success and -1 if there is an
 * exception executing the Stan program.
 *
 * @param[in] m pointer to model structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] lp log density to be set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_log_density(const bs_model* m, bool propto, bool jacobian,
                             const double* theta_unc, double* lp,
                             char** error_msg);

/**
 * Set the log density and gradient of the specified parameters,
 * dropping constants if `propto` is `true` and including the
 * Jacobian terms resulting from constraining parameters if
 * `jacobian` is `true`, and return a return code of 0 for success
 * and -1 if there is an exception executing the Stan program.  The
 * gradient must have enough space to hold the gradient.
 *
 * The gradients are computed using automatic differentiation.
 *
 * @param[in] m pointer to model structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_log_density_gradient(const bs_model* m, bool propto,
                                      bool jacobian, const double* theta_unc,
                                      double* val, double* grad,
                                      char** error_msg);

/**
 * Set the log density, gradient, and Hessian of the specified parameters,
 * dropping constants if `propto` is `true` and including the
 * Jacobian terms resulting from constraining parameters if
 * `jacobian` is `true`, and return a return code of 0 for success
 * and -1 if there is an exception executing the Stan program.  The
 * pointer `grad` must have enough space to hold the gradient.  The
 * pointer `hessian` must have enough space to hold the Hessian.
 *
 * The gradients are computed using automatic differentiation.
 * Hessians are computed using nested automatic differentiation if
 * `BRIDGESTAN_AD_HESSIAN` is defined, otherwise they are computed
 * using central finite differences of `size(theta_unc)` calculations
 * of gradient.
 *
 * @param[in] m pointer to model structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @param[out] hessian hessian to set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_log_density_hessian(const bs_model* m, bool propto,
                                     bool jacobian, const double* theta_unc,
                                     double* val, double* grad, double* hessian,
                                     char** error_msg);

/**
 * Calculate the log density and the product of the Hessian with the specified
 * vector for the specified unconstrained parameters and write it into the
 * specified value pointer and Hessian-vector product pointer, dropping
 * constants it `propto` is `true` and including the Jacobian adjustment if
 * `jacobian` is `true`. Returns a return code of 0 for success
 * and -1 if there is an exception executing the Stan program. The
 * pointer `hvp` must have enough space to hold the product.
 *
 * Hessian-vector-products are computed using nested automatic
 * differentiation if `BRIDGESTAN_AD_HESSIAN` is defined, otherwise
 * they are computed using central finite differences of the gradient
 * of `theta_unc` perturbed in the direction of `vector`. This
 * approximates the Hessian-vector product using two gradient
 * evaluations, but at a lower accuracy than the nested automatic
 * differentiation.
 *
 * @param[in] m pointer to model structure
 * @param[in] propto `true` to drop constant terms
 * @param[in] jacobian `true` to include Jacobian adjustment for
 * constrained parameter transforms
 * @param[in] theta_unc unconstrained parameters
 * @param[in] vector vector to multiply Hessian by
 * @param[out] val log density to set
 * @param[out] hvp Hessian-vector to set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
BS_PUBLIC int bs_log_density_hessian_vector_product(
    const bs_model* m, bool propto, bool jacobian, const double* theta_unc,
    const double* vector, double* val, double* hvp, char** error_msg);

/**
 * Construct an PRNG object to be used in bs_param_constrain().
 * This object is not thread safe and should be constructed and
 * destructed for each thread.
 *
 * @param[in] seed seed for the RNG
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 */
BS_PUBLIC bs_rng* bs_rng_construct(unsigned int seed, char** error_msg);

/**
 * Destruct an RNG object.
 *
 * @param[in] rng pointer to RNG object
 */
BS_PUBLIC void bs_rng_destruct(bs_rng* rng);

/**
 * Provide a function for printing. This will be called when the Stan
 * model prints output. The default is to print to stdout.
 *
 * @param[in] callback function to call when the Stan model prints. This
 * function will be guarded by a mutex, so it need not be thread safe. It must
 * never propagate an exception. Passing NULL will redirect printing back to
 * stdout.
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling bs_free_error_msg().
 * @return code 0 if successful and code -1 if there is an exception
 */
BS_PUBLIC int bs_set_print_callback(STREAM_CALLBACK callback, char** error_msg);

#ifdef __cplusplus
}
#endif

#endif
