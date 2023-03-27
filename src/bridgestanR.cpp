#include "bridgestanR.h"
#include "bridgestan.h"

void bs_construct_R(char** data, int* rng, int* chain, bs_model_rng** ptr_out) {
  *ptr_out = bs_construct(*data, *rng, *chain, nullptr);
}
void bs_destruct_R(bs_model_rng** model, int* return_code) {
  *return_code = bs_destruct(*model, nullptr);
}
void bs_name_R(bs_model_rng** model, char const** name_out) {
  *name_out = bs_name(*model);
}
void bs_model_info_R(bs_model_rng** model, char const** info_out) {
  *info_out = bs_model_info(*model);
}
void bs_param_names_R(bs_model_rng** model, int* include_tp, int* include_gq,
                      char const** names_out) {
  *names_out = bs_param_names(*model, *include_tp, *include_gq);
}
void bs_param_unc_names_R(bs_model_rng** model, char const** names_out) {
  *names_out = bs_param_unc_names(*model);
}
void bs_param_num_R(bs_model_rng** model, int* include_tp, int* include_gq,
                    int* num_out) {
  *num_out = bs_param_num(*model, *include_tp, *include_gq);
}
void bs_param_unc_num_R(bs_model_rng** model, int* num_out) {
  *num_out = bs_param_unc_num(*model);
}
void bs_param_constrain_R(bs_model_rng** model, int* include_tp,
                          int* include_gq, const double* theta_unc,
                          double* theta, int* return_code) {
  *return_code = bs_param_constrain(*model, *include_tp, *include_gq, theta_unc,
                                    theta, nullptr);
}
void bs_param_unconstrain_R(bs_model_rng** model, const double* theta,
                            double* theta_unc, int* return_code) {
  *return_code = bs_param_unconstrain(*model, theta, theta_unc, nullptr);
}
void bs_param_unconstrain_json_R(bs_model_rng** model, char const** json,
                                 double* theta_unc, int* return_code) {
  *return_code = bs_param_unconstrain_json(*model, *json, theta_unc, nullptr);
}
void bs_log_density_R(bs_model_rng** model, int* propto, int* jacobian,
                      const double* theta, double* val, int* return_code) {
  *return_code
      = bs_log_density(*model, *propto, *jacobian, theta, val, nullptr);
}
void bs_log_density_gradient_R(bs_model_rng** model, int* propto, int* jacobian,
                               const double* theta, double* val, double* grad,
                               int* return_code) {
  *return_code = bs_log_density_gradient(*model, *propto, *jacobian, theta, val,
                                         grad, nullptr);
}
void bs_log_density_hessian_R(bs_model_rng** model, int* propto, int* jacobian,
                              const double* theta, double* val, double* grad,
                              double* hess, int* return_code) {
  *return_code = bs_log_density_hessian(*model, *propto, *jacobian, theta, val,
                                        grad, hess, nullptr);
}
