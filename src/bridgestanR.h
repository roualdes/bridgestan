#ifndef BRIDGESTANR_H
#define BRIDGESTANR_H

#ifdef __cplusplus
#include "model_rng.hpp"
extern "C" {
#else
typedef struct model_rng model_rng;
typedef int bool;
#endif

// Shim to convert to R interface requirement of void with pointer args
// All calls directly delegated to versions without _R suffix
void construct_R(char** data, int* rng, int* chain, model_rng** ptr_out);

void destruct_R(model_rng** model, int* return_code);

void name_R(model_rng** model, char const** name_out);

void model_info_R(model_rng** model, char const** info_out);

void param_names_R(model_rng** model, int* include_tp, int* include_gq,
                   char const** name_out);

void param_unc_names_R(model_rng** model, char const** name_out);

void param_num_R(model_rng** model, int* include_tp, int* include_gq,
                 int* num_out);

void param_unc_num_R(model_rng** model, int* num_out);

void param_constrain_R(model_rng** model, int* include_tp, int* include_gq,
                       const double* theta_unc, double* theta,
                       int* return_code);

void param_unconstrain_R(model_rng** model, const double* theta,
                         double* theta_unc, int* return_code);

void param_unconstrain_json_R(model_rng** model, char const** json,
                              double* theta_unc, int* return_code);

void log_density_R(model_rng** model, int* propto, int* jacobian,
                   const double* theta, double* val, int* return_code);

void log_density_gradient_R(model_rng** model, int* propto, int* jacobian,
                            const double* theta, double* val, double* grad,
                            int* return_code);

void log_density_hessian_R(model_rng** model, int* propto, int* jacobian,
                           const double* theta, double* val, double* grad,
                           double* hess, int* return_code);

#ifdef __cplusplus
}
#endif

#endif
