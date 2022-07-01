#include "juliabridge.h"

extern stanmodel* stanmodel_create(char* data_file_path_, unsigned int seed_) {
  return _stanmodel_create(data_file_path_, seed_);
}

extern void stanmodel_log_density(stanmodel* sm_, double* q_, int D_, double* log_density_, double* grad_, int propto_, int jacobian_) {
  _stanmodel_log_density(sm_, q_, D_, log_density_, grad_, propto_, jacobian_);
}

extern int stanmodel_get_num_unc_params(stanmodel* sm_) {
  return _stanmodel_get_num_unc_params(sm_);
}

extern void stanmodel_destroy(stanmodel* sm) {
  _stanmodel_destroy(sm);
}
