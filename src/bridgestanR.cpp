#include "bridgestanR.h"
#include "bridgestan.h"

void bs_construct_R(char** data, int* rng, bs_model** ptr_out, char** err_msg,
                    void** err_ptr) {
  *ptr_out = bs_construct(*data, *rng, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_free_error_msg_R(void** err_msg) {
  bs_free_error_msg(static_cast<char*>(*err_msg));
}
void bs_version_R(int* major, int* minor, int* patch) {
  *major = bs_major_version;
  *minor = bs_minor_version;
  *patch = bs_patch_version;
}
void bs_destruct_R(bs_model** model) { bs_destruct(*model); }
void bs_name_R(bs_model** model, char const** name_out) {
  *name_out = bs_name(*model);
}
void bs_model_info_R(bs_model** model, char const** info_out) {
  *info_out = bs_model_info(*model);
}
void bs_param_names_R(bs_model** model, int* include_tp, int* include_gq,
                      char const** names_out) {
  *names_out = bs_param_names(*model, *include_tp, *include_gq);
}
void bs_param_unc_names_R(bs_model** model, char const** names_out) {
  *names_out = bs_param_unc_names(*model);
}
void bs_param_num_R(bs_model** model, int* include_tp, int* include_gq,
                    int* num_out) {
  *num_out = bs_param_num(*model, *include_tp, *include_gq);
}
void bs_param_unc_num_R(bs_model** model, int* num_out) {
  *num_out = bs_param_unc_num(*model);
}
void bs_param_constrain_R(bs_model** model, int* include_tp, int* include_gq,
                          const double* theta_unc, double* theta, bs_rng** rng,
                          int* return_code, char** err_msg, void** err_ptr) {
  *return_code = bs_param_constrain(*model, *include_tp, *include_gq, theta_unc,
                                    theta, *rng, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_param_constrain_seeded_R(bs_model** model, int* include_tp,
                                 int* include_gq, const double* theta_unc,
                                 double* theta, int* seed, int* chain_id,
                                 int* return_code, char** err_msg,
                                 void** err_ptr) {
  *return_code
      = bs_param_constrain_seeded(*model, *include_tp, *include_gq, theta_unc,
                                  theta, *seed, *chain_id, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_param_unconstrain_R(bs_model** model, const double* theta,
                            double* theta_unc, int* return_code, char** err_msg,
                            void** err_ptr) {
  *return_code = bs_param_unconstrain(*model, theta, theta_unc, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_param_unconstrain_json_R(bs_model** model, char const** json,
                                 double* theta_unc, int* return_code,
                                 char** err_msg, void** err_ptr) {
  *return_code = bs_param_unconstrain_json(*model, *json, theta_unc, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_log_density_R(bs_model** model, int* propto, int* jacobian,
                      const double* theta_unc, double* val, int* return_code,
                      char** err_msg, void** err_ptr) {
  *return_code
      = bs_log_density(*model, *propto, *jacobian, theta_unc, val, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_log_density_gradient_R(bs_model** model, int* propto, int* jacobian,
                               const double* theta_unc, double* val,
                               double* grad, int* return_code, char** err_msg,
                               void** err_ptr) {
  *return_code = bs_log_density_gradient(*model, *propto, *jacobian, theta_unc,
                                         val, grad, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_log_density_hessian_R(bs_model** model, int* propto, int* jacobian,
                              const double* theta_unc, double* val,
                              double* grad, double* hess, int* return_code,
                              char** err_msg, void** err_ptr) {
  *return_code = bs_log_density_hessian(*model, *propto, *jacobian, theta_unc,
                                        val, grad, hess, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_construct_rng_R(int* seed, int* chain_id, bs_rng** ptr_out,
                        char** err_msg, void** err_ptr) {
  *ptr_out = bs_construct_rng(*seed, *chain_id, err_msg);
  *err_ptr = static_cast<void*>(*err_msg);
}
void bs_destruct_rng_R(bs_rng** rng) { bs_destruct_rng(*rng); }
