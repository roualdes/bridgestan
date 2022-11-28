#ifndef BRIDGESTANR_H
#define BRIDGESTANR_H

#ifdef __cplusplus
#include "model_rng.hpp"
extern "C" {
#else
typedef struct bs_model_rng bs_model_rng;
typedef int bool;
#endif

// Shim to convert to R interface requirement of void with pointer args
// All calls directly delegated to versions without _R suffix
void bs_construct_R(char** data, int* rng, int* chain, bs_model_rng** ptr_out);

void bs_destruct_R(bs_model_rng** model, int* return_code);

void bs_name_R(bs_model_rng** model, char const** name_out);

void bs_model_info_R(bs_model_rng** model, char const** info_out);

void bs_param_names_R(bs_model_rng** model, int* include_tp, int* include_gq,
                      char const** name_out);

void bs_param_unc_names_R(bs_model_rng** model, char const** name_out);

void bs_param_num_R(bs_model_rng** model, int* include_tp, int* include_gq,
                    int* num_out);

void bs_param_unc_num_R(bs_model_rng** model, int* num_out);

void bs_param_constrain_R(bs_model_rng** model, int* include_tp,
                          int* include_gq, const double* theta_unc,
                          double* theta, int* return_code);

void bs_param_unconstrain_R(bs_model_rng** model, const double* theta,
                            double* theta_unc, int* return_code);

void bs_param_unconstrain_json_R(bs_model_rng** model, char const** json,
                                 double* theta_unc, int* return_code);

void bs_log_density_R(bs_model_rng** model, int* propto, int* jacobian,
                      const double* theta, double* val, int* return_code);

void bs_log_density_gradient_R(bs_model_rng** model, int* propto, int* jacobian,
                               const double* theta, double* val, double* grad,
                               int* return_code);

void bs_log_density_hessian_R(bs_model_rng** model, int* propto, int* jacobian,
                              const double* theta, double* val, double* grad,
                              double* hess, int* return_code);

#ifdef __cplusplus
}
#endif

#endif
