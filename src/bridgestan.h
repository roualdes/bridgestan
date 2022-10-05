#ifndef BRIDGESTAN_H
#define BRIDGESTAN_H

#ifdef __cplusplus
#include "model_rng.hpp"
extern "C" {
#else
typedef struct model_rng model_rng;
typedef int bool;
#endif
/**
 * Construct an instance of a model and pseudorandom number
 * generator (PRNG) wrapper.  Data must be encoded in JSON as
 * indicated in the *CmdStan Reference Manual*.
 *
 * @param[in] data_file C-style path to JSON-encoded data file
 * @param[in] seed seed for PRNG
 * @param[in] chain_id identifier for concurrent sequence of PRNG
 * draws
 * @return pointer to constructed model or `nullptr` if construction
 * fails
 */
model_rng* construct(char* data_file, unsigned int seed, unsigned int chain_id);

/**
 * Destroy the model and return 0 for success and -1 if there is an
 * exception while freeing memory.
 *
 * @param[in] mr pointer to model and RNG structure
 * @return 0 for success and -1 if there is an exception freeing one
 * of the model components.
 */
int destruct(model_rng* mr);

/**
 * Return the name of the specified model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model and RNG wrapper is destroyed.
 *
 * @param[in] mr pointer to model and RNG structure
 * @return name of model
 */
const char* name(model_rng* mr);

/**
 * Return information about the compiled model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model and RNG wrapper is destroyed.
 *
 * @param[in] mr pointer to model and RNG structure
 * @return Information about the model including Stan version, Stan defines, and
 * compiler flags.
 */
const char* model_info(model_rng* mr);

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
 * model and RNG wrapper is destroyed.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return CSV-separated, indexed, parameter names
 */
const char* param_names(model_rng* mr, bool include_tp, bool include_gq);

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
 * model and RNG wrapper is destroyed.
 *
 * @param[in] mr pointer to model and RNG structure
 * @return CSV-separated, indexed, unconstrained parameter names
 */
const char* param_unc_names(model_rng* mr);

/**
 * Return the number of scalar parameters, optionally including the
 * number of transformed parameters and/or generated quantities.
 * For example, a 2 x 3 matrix counts as 6 scalar parameters.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return number of parameters
 */
int param_num(model_rng* mr, bool include_tp, bool include_gq);

/**
 * Return the number of unconstrained parameters.  The number of
 * unconstrained parameters might be smaller than the number of
 * parameters if the unconstrained space has fewer dimensions than
 * the constrained (e.g., for simplexes or correlation matrices).
 *
 * @param[in] mr pointer to model and RNG structure
 * @return number of unconstrained parameters
 */
int param_unc_num(model_rng* mr);

/**
 * Set the sequence of constrained parameters based on the specified
 * unconstrained parameters, including transformed parameters and/or
 * generated quantities as specified, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @param[in] theta_unc sequence of unconstrained parameters
 * @param[out] theta sequence of constrained parameters
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int param_constrain(model_rng* mr, bool include_tp, bool include_gq,
                    const double* theta_unc, double* theta);

/**
 * Set the sequence of unconstrained parameters based on the
 * specified constrained parameters, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] theta sequence of constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int param_unconstrain(model_rng* mr, const double* theta, double* theta_unc);

/**
 * Set the sequence of unconstrained parameters based on the JSON
 * specification of the constrained parameters, and return a return
 * code of 0 for success and -1 for failure.  Parameter order is as
 * declared in the Stan program, with multivariate parameters given
 * in last-index-major order.  The JSON schema assumed is fully
 * defined in the *CmdStan Reference Manual*.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] json json-encoded constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int param_unconstrain_json(model_rng* mr, const char* json, double* theta_unc);

/**
 * Set the log density of the specified parameters, dropping
 * constants if `propto` is `true` and including the Jacobian terms
 * resulting from constraining parameters if `jacobian` is `true`,
 * and return a return code of 0 for success and -1 if there is an
 * exception executing the Stan program.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta unconstrained parameters
 * @param[out] lp log density to be set
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int log_density(model_rng* mr, bool propto, bool jacobian, const double* theta,
                double* lp);

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
 * @param[in] mr pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int log_density_gradient(model_rng* mr, bool propto, bool jacobian,
                         const double* theta, double* val, double* grad);

/**
 * Set the log density, gradient, and Hessian of the specified parameters,
 * dropping constants if `propto` is `true` and including the
 * Jacobian terms resulting from constraining parameters if
 * `jacobian` is `true`, and return a return code of 0 for success
 * and -1 if there is an exception executing the Stan program.  The
 * pointer `grad` must have enough space to hold the gradient.  The
 * pointer `Hessian` must have enough space to hold the Hessian.
 *
 * The gradients are computed using automatic differentiation.  the
 * Hessians are
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int log_density_hessian(model_rng* mr, bool propto, bool jacobian,
                        const double* theta, double* val, double* grad,
                        double* hessian);

#ifdef __cplusplus
}
#endif

#endif
