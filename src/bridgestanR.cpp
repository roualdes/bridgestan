#include "bridgestanR.h"

void construct_R(char** data, int* rng, int* chain, model_rng** ptr_out) {
  *ptr_out = construct(*data, *rng, *chain);
}
void destruct_R(model_rng** model, int* return_code) {
  *return_code = destruct(*model);
}
void name_R(model_rng** model, char const** name_out) {
  *name_out = name(*model);
}
void model_info_R(model_rng** model, char const** info_out){
  *info_out = model_info(*model);
}
void param_names_R(model_rng** model, int* include_tp, int* include_gq,
                   char const** names_out) {
  *names_out = param_names(*model, *include_tp, *include_gq);
}
void param_unc_names_R(model_rng** model, char const** names_out) {
  *names_out = param_unc_names(*model);
}
void param_num_R(model_rng** model, int* include_tp, int* include_gq,
                 int* num_out) {
  *num_out = param_num(*model, *include_tp, *include_gq);
}
void param_unc_num_R(model_rng** model, int* num_out) {
  *num_out = param_unc_num(*model);
}
void param_constrain_R(model_rng** model, int* include_tp, int* include_gq,
                       const double* theta_unc, double* theta,
                       int* return_code) {
  *return_code
      = param_constrain(*model, *include_tp, *include_gq, theta_unc, theta);
}
void param_unconstrain_R(model_rng** model, const double* theta,
                         double* theta_unc, int* return_code) {
  *return_code = param_unconstrain(*model, theta, theta_unc);
}
void param_unconstrain_json_R(model_rng** model, char const** json,
                              double* theta_unc, int* return_code) {
  *return_code = param_unconstrain_json(*model, *json, theta_unc);
}
void log_density_R(model_rng** model, int* propto, int* jacobian,
                   const double* theta, double* val, int* return_code) {
  *return_code = log_density(*model, *propto, *jacobian, theta, val);
}
void log_density_gradient_R(model_rng** model, int* propto, int* jacobian,
                            const double* theta, double* val, double* grad,
                            int* return_code) {
  *return_code
      = log_density_gradient(*model, *propto, *jacobian, theta, val, grad);
}
void log_density_hessian_R(model_rng** model, int* propto, int* jacobian,
                           const double* theta, double* val, double* grad,
                           double* hess, int* return_code) {
  *return_code
      = log_density_hessian(*model, *propto, *jacobian, theta, val, grad, hess);
}
