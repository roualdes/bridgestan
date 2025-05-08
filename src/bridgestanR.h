#ifndef BRIDGESTANR_HPP
#define BRIDGESTANR_HPP

#include "bridgestan.h"

/// \file bridgestanR.h

#ifdef __cplusplus
extern "C" {
#endif

// Shim to convert to R interface requirement of void with pointer args
// All calls directly delegated to versions without _R suffix

/// See \link bs_model_construct() \endlink for more details.
BS_PUBLIC void bs_model_construct_R(char** data, int* rng, bs_model** ptr_out,
                                    char** err_msg, void** err_ptr);

/// See \link bs_major_version \endlink for more details.
BS_PUBLIC void bs_version_R(int* major, int* minor, int* patch);

/// See \link bs_model_destruct() \endlink for more details.
BS_PUBLIC void bs_model_destruct_R(bs_model** model);

/**
 * Free error message allocated in C++. Because R performs copies
 * at the boundary on `char**`s, this uses `void**` pointing to the same memory.
 *
 * See \link bs_free_error_msg() \endlink for more details.
 */
BS_PUBLIC void bs_free_error_msg_R(void** err_msg);

/// See \link bs_name() \endlink for more details.
BS_PUBLIC void bs_name_R(bs_model** model, char const** name_out);

/// See \link bs_model_info() \endlink for more details.
BS_PUBLIC void bs_model_info_R(bs_model** model, char const** info_out);

/// See \link bs_param_names() \endlink for more details.
BS_PUBLIC void bs_param_names_R(bs_model** model, int* include_tp,
                                int* include_gq, char const** name_out);

/// See \link bs_param_unc_names() \endlink for more details.
BS_PUBLIC void bs_param_unc_names_R(bs_model** model, char const** name_out);

/// See \link bs_param_num() \endlink for more details.
BS_PUBLIC void bs_param_num_R(bs_model** model, int* include_tp,
                              int* include_gq, int* num_out);

/// See \link bs_param_unc_num() \endlink for more details.
BS_PUBLIC void bs_param_unc_num_R(bs_model** model, int* num_out);

/// See \link bs_param_constrain() \endlink for more details.
BS_PUBLIC void bs_param_constrain_R(bs_model** model, int* include_tp,
                                    int* include_gq, const double* theta_unc,
                                    double* theta, bs_rng** rng,
                                    int* return_code, char** err_msg,
                                    void** err_ptr);

/// See \link bs_param_unconstrain() \endlink for more details.
BS_PUBLIC void bs_param_unconstrain_R(bs_model** model, const double* theta,
                                      double* theta_unc, int* return_code,
                                      char** err_msg, void** err_ptr);

/// See \link bs_param_unconstrain_json() \endlink for more details.
BS_PUBLIC void bs_param_unconstrain_json_R(bs_model** model, char const** json,
                                           double* theta_unc, int* return_code,
                                           char** err_msg, void** err_ptr);

/// See \link bs_log_density() \endlink for more details.
BS_PUBLIC void bs_log_density_R(bs_model** model, int* propto, int* jacobian,
                                const double* theta_unc, double* val,
                                int* return_code, char** err_msg,
                                void** err_ptr);

/// See \link bs_log_density_gradient() \endlink for more details.
BS_PUBLIC void bs_log_density_gradient_R(bs_model** model, int* propto,
                                         int* jacobian, const double* theta_unc,
                                         double* val, double* grad,
                                         int* return_code, char** err_msg,
                                         void** err_ptr);

/// See \link bs_log_density_hessian() \endlink for more details.
BS_PUBLIC void bs_log_density_hessian_R(bs_model** model, int* propto,
                                        int* jacobian, const double* theta_unc,
                                        double* val, double* grad, double* hess,
                                        int* return_code, char** err_msg,
                                        void** err_ptr);

/// See \link bs_log_density_hessian_vector_product() \endlink for more details.
BS_PUBLIC void bs_log_density_hessian_vector_product_R(
    bs_model** model, int* propto, int* jacobian, const double* theta_unc,
    const double* vector, double* val, double* Hvp, int* return_code,
    char** err_msg, void** err_ptr);

/// See \link bs_rng_construct() \endlink for more details.
BS_PUBLIC void bs_rng_construct_R(int* seed, bs_rng** ptr_out, char** err_msg,
                                  void** err_ptr);

/// See \link bs_rng_destruct() \endlink for more details.
BS_PUBLIC void bs_rng_destruct_R(bs_rng** rng);

#ifdef __cplusplus
}
#endif

#endif
