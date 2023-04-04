#ifndef BRIDGESTAN_H
#define BRIDGESTAN_H

#ifdef __cplusplus
#include "model_rng.hpp"
extern "C" {
#else
typedef struct bs_model bs_model;
typedef struct bs_rng bs_rng;
typedef int bool;
#endif

extern int bs_major_version;
extern int bs_minor_version;
extern int bs_patch_version;

/**
 * Construct an instance of a model and pseudorandom number
 * generator (PRNG) wrapper.  Data must be encoded in JSON as
 * indicated in the *CmdStan Reference Manual*.
 *
 * @param[in] data_file C-style string. This is either a
 * path to JSON-encoded data file (must end with ".json"), or
 * a JSON string literal.
 * @param[in] seed seed for PRNG
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return pointer to constructed model or `nullptr` if construction
 * fails
 */
bs_model* bs_construct(const char* data_file, unsigned int seed,
                       char** error_msg);

/**
 * Destroy the model.
 *
 * @param[in] m pointer to model and RNG structure
 */
void bs_destruct(bs_model* m);

/**
 * Free the error messages created by other methods.
 *
 * @param[in] error_msg pointer to error message
 */
void bs_free_error_msg(char* error_msg);

/**
 * Return the name of the specified model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model and RNG wrapper is destroyed.
 *
 * @param[in] m pointer to model and RNG structure
 * @return name of model
 */
const char* bs_name(const bs_model* m);

/**
 * Return information about the compiled model as a C-style string.
 *
 * The returned string should not be modified; it is freed when the
 * model and RNG wrapper is destroyed.
 *
 * @param[in] m pointer to model and RNG structure
 * @return Information about the model including Stan version, Stan defines, and
 * compiler flags.
 */
const char* bs_model_info(const bs_model* m);

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
 * @param[in] m pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return CSV-separated, indexed, parameter names
 */
const char* bs_param_names(const bs_model* m, bool include_tp, bool include_gq);

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
 * @param[in] m pointer to model and RNG structure
 * @return CSV-separated, indexed, unconstrained parameter names
 */
const char* bs_param_unc_names(const bs_model* m);

/**
 * Return the number of scalar parameters, optionally including the
 * number of transformed parameters and/or generated quantities.
 * For example, a 2 x 3 matrix counts as 6 scalar parameters.
 *
 * @param[in] m pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @return number of parameters
 */
int bs_param_num(const bs_model* m, bool include_tp, bool include_gq);

/**
 * Return the number of unconstrained parameters.  The number of
 * unconstrained parameters might be smaller than the number of
 * parameters if the unconstrained space has fewer dimensions than
 * the constrained (e.g., for simplexes or correlation matrices).
 *
 * @param[in] m pointer to model and RNG structure
 * @return number of unconstrained parameters
 */
int bs_param_unc_num(const bs_model* m);

/**
 * Set the sequence of constrained parameters based on the specified
 * unconstrained parameters, including transformed parameters and/or
 * generated quantities as specified, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] m pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @param[in] theta_unc sequence of unconstrained parameters
 * @param[out] theta sequence of constrained parameters
 * @param[in] rng pointer to pseudorandom number generator, should be created
 * by `bs_construct_rng`
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_param_constrain(const bs_model* m, bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta, bs_rng* rng,
                       char** error_msg);

/**
 * Set the sequence of constrained parameters based on the specified
 * unconstrained parameters, including transformed parameters and/or
 * generated quantities as specified, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * This version accepts a chain_id which is used to create a PRNG
 * offset from the model's seed which lives only for the duration
 * of this call.
 *
 * @param[in] mr pointer to model and RNG structure
 * @param[in] include_tp `true` to include transformed parameters
 * @param[in] include_gq `true` to include generated quantities
 * @param[in] theta_unc sequence of unconstrained parameters
 * @param[out] theta sequence of constrained parameters
 * @param[in] chain_id offset for pseudorandom number generator which will be
 * created and destroyed during this call. seeded with model seed. See
 * `bs_param_constrain` for an option with a persistent RNG.
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_param_constrain_seeded(const bs_model* mr, bool include_tp,
                              bool include_gq, const double* theta_unc,
                              double* theta, unsigned int seed,
                              unsigned int chain_id, char** error_msg);

/**
 * Set the sequence of unconstrained parameters based on the
 * specified constrained parameters, and return a return code of 0
 * for success and -1 for failure.  Parameter order is as declared
 * in the Stan program, with multivariate parameters given in
 * last-index-major order.
 *
 * @param[in] m pointer to model and RNG structure
 * @param[in] theta sequence of constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_param_unconstrain(const bs_model* m, const double* theta,
                         double* theta_unc, char** error_msg);

/**
 * Set the sequence of unconstrained parameters based on the JSON
 * specification of the constrained parameters, and return a return
 * code of 0 for success and -1 for failure.  Parameter order is as
 * declared in the Stan program, with multivariate parameters given
 * in last-index-major order. The JSON schema assumed is fully
 * defined in the *CmdStan Reference Manual*.
 *
 * @param[in] m pointer to model and RNG structure
 * @param[in] json JSON-encoded constrained parameters
 * @param[out] theta_unc sequence of unconstrained parameters
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_param_unconstrain_json(const bs_model* m, const char* json,
                              double* theta_unc, char** error_msg);

/**
 * Set the log density of the specified parameters, dropping
 * constants if `propto` is `true` and including the Jacobian terms
 * resulting from constraining parameters if `jacobian` is `true`,
 * and return a return code of 0 for success and -1 if there is an
 * exception executing the Stan program.
 *
 * @param[in] m pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] lp log density to be set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_log_density(const bs_model* m, bool propto, bool jacobian,
                   const double* theta_unc, double* lp, char** error_msg);

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
 * @param[in] m pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_log_density_gradient(const bs_model* m, bool propto, bool jacobian,
                            const double* theta_unc, double* val, double* grad,
                            char** error_msg);

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
 * @param[in] m pointer to model and RNG structure
 * @param[in] propto `true` to discard constant terms
 * @param[in] jacobian `true` to include change-of-variables terms
 * @param[in] theta_unc unconstrained parameters
 * @param[out] val log density to be set
 * @param[out] grad gradient to set
 * @param[out] hessian hessian to set
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 * @return code 0 if successful and code -1 if there is an exception
 * in the underlying Stan code
 */
int bs_log_density_hessian(const bs_model* m, bool propto, bool jacobian,
                           const double* theta_unc, double* val, double* grad,
                           double* hessian, char** error_msg);

/**
 * Construct an PRNG object to be used in `bs_param_constrain`.
 * This object is not thread safe and should be constructed and
 * destructed for each thread.
 *
 * @param[in] seed seed for the RNG
 * @param[in] chain_id identifier for the current sequence of PRNG draws
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 */
bs_rng* bs_construct_rng(unsigned int seed, unsigned int chain_id,
                         char** error_msg);

/**
 * Destruct an RNG object.
 *
 * @param[in] rng pointer to RNG object
 * @param[out] error_msg a pointer to a string that will be allocated if there
 * is an error. This must later be freed by calling `bs_free_error_msg`.
 */
int bs_destruct_rng(bs_rng* rng, char** error_msg);

#ifdef __cplusplus
}
#endif

#endif
