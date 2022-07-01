#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

  struct stanmodel_struct;
  typedef struct stanmodel_struct stanmodel;

  stanmodel* stanmodel_create(char* data_file_path_, unsigned int seed_);
  stanmodel* _stanmodel_create(char* data_file_path_, unsigned int seed_);

  void stanmodel_log_density(stanmodel* sm_, double* q_, int D_, double* log_density_, double* grad_, int propto_, int jacobian_);
  void _stanmodel_log_density(stanmodel* sm_, double* q_, int D_, double* log_density_, double* grad_, int propto_, int jacobian_);

  int stanmodel_get_num_unc_params(stanmodel* sm_);
  int _stanmodel_get_num_unc_params(stanmodel* sm_);

  void stanmodel_destroy(stanmodel* sm);
  void _stanmodel_destroy(stanmodel* sm);

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */
