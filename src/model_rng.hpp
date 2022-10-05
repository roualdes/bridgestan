#ifndef MODEL_RNG_H
#define MODEL_RNG_H

#include <stan/model/model_base.hpp>
#include <boost/random/additive_combine.hpp>
#include <string>
#include <vector>

/**
 * This structure holds a pointer to a model, holds a pseudorandom
 * number generator, and holds pointers to the parameter names in
 * CSV format.  Instances can be constructed with the C function
 * `construct()` and destroyed with the C function `destruct()`.
 */
class model_rng {
 public:
  /**
   * Construct a model and random number generator with cached
   * parameter numbers and names.
   *
   * @param[in] data_file file from which to read data or "" if none
   * @param[in] seed pseudorandom number generator seed
   * @param[in] chain_id number of gaps to skip in the pseudorandom
   * number generator for concurrent computations
   */
  model_rng(const char* data_file, unsigned int seed, unsigned int chain_id);

  /**
   * Destroy this object and free all of the memory allocated for it.
   */
  ~model_rng();

  /**
   * Return the name of the model.  This class manages the memory,
   * so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* name();

  /**
   *  Return information about the compiled model. This class manages the
   * memory, so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* model_info();

  /**
   * Return the parameter names as a comma-separated list.  Indexes
   * are separted with periods. This class manages the memory, so
   * the returned string should not be freed.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return comma-separated parameter names with indexes
   */
  const char* param_names(bool include_tp, bool include_gq);

  /**
   * Return the unconstrained parameter names as a comma-separated
   * list.  This class manages the memory, so the returned string
   * should not be freed.
   *
   * @return comma-separated unconstrained parameter names with
   * indexes
   */
  const char* param_unc_names();

  /**
   * Return the number of unconstrianed parameters.
   *
   * @return number of unconstrained parameters
   */
  int param_unc_num();

  /**
   * Return the number of parameters, optionally including
   * transformed parameters and/or generated quantities.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return number of parameters
   */
  int param_num(bool include_tp, bool include_gq);

  /**
   * Unconstrain the specified parameters and write into the
   * specified unconstrained parameter array.
   *
   * @param[in] theta parameters to unconstrain
   * @param[in,out] theta_unc unconstrained parameters
   */
  void param_unconstrain(const double* theta, double* theta_unc);

  /**
   * Unconstrain the parameters specified as a JSON string and write
   * into the specified unconstrained parameter array.  See the
   * CmdStan Reference Manual for details of the JSON schema.
   *
   * @param[in] json JSON string representing parameters
   * @param[in,out] theta_unc unconstrained parameters generated
   */
  void param_unconstrain_json(const char* json, double* theta_unc);

  /**
   * Constrain the specified unconstrained parameters into the
   * specified array, optionally including transformed parameters
   * and generated quantities as specified.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @param[in] theta_unc unconstrained parameters to constrain
   * @param[in,out] theta constrained parameters generated
   */
  void param_constrain(bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta);

  /**
   * Calculate the log density for the specified unconstrain
   * parameters and write it into the specified value pointer,
   * dropping constants it `propto` is `true` and including the
   * Jacobian adjustment if `jacobian` is `true`.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   * @param[in] theta_unc unconstrained parameters
   * @param[in,out] val log density produced
   */
  void log_density(bool propto, bool jacobian, const double* theta_unc,
                   double* val);

  /**
   * Calculate the log density and gradient for the specified
   * unconstrain parameters and write it into the specified value
   * pointer and gradient pointer, dropping constants it `propto` is
   * `true` and including the Jacobian adjustment if `jacobian` is
   * `true`.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   * @param[in] theta_unc unconstrained parameters
   * @param[in,out] val log density produced
   * @param[in,out] grad gradient produced
   */
  void log_density_gradient(bool propto, bool jacobian, const double* theta_unc,
                            double* val, double* grad);

  /**
   * Calculate the log density, gradient, and Hessian for the
   * specified unconstrain parameters and write it into the
   * specified value pointer, gradient pointer, and Hessian pointer,
   * dropping constants it `propto` is `true` and including the
   * Jacobian adjustment if `jacobian` is `true`.  The Hessian is
   * symmetric so row-major vs. column-major are identical.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   * @param[in] theta_unc unconstrained parameters
   * @param[in,out] val log density produced
   * @param[in,out] grad gradient produced
   * @param[in,out] hess Hessian produced
   */
  void log_density_hessian(bool propto, bool jacobian, const double* theta_unc,
                           double* val, double* grad, double* hessian);

  /**
   * Returns a lambda which calls the correct version of log_prob
   * depending on the values of propto and jacobian.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   */
  auto make_model_lambda(bool propto, bool jacobian);

 private:
  /** Stan model */
  stan::model::model_base* model_;

  /** pseudorandom number generator */
  boost::ecuyer1988 rng_;

  /** name of the Stan model */
  char* name_ = nullptr;

  /** Model compile info */
  char* model_info_ = nullptr;

  /** CSV list of parameter names */
  char* param_names_ = nullptr;

  /** CSV list of parameter, transformed parameter names */
  char* param_tp_names_ = nullptr;

  /** CSV list of parameter, generated quantity names */
  char* param_gq_names_ = nullptr;

  /** number of parameters */
  int param_num_ = -1;

  /** number of parameters + transformed parameters */
  int param_tp_num_ = -1;

  /** number of parameters + generated quantities */
  int param_gq_num_ = -1;

  /** number of parameters + transformed parameters + generated quantities */
  int param_tp_gq_num_ = -1;

  /**
   * CSV list of parameter, transformed parameters, generated
   * quantity names
   */
  char* param_tp_gq_names_ = nullptr;

  /** name of the Stan model */
  char* param_unc_names_ = nullptr;

  /** number of unconstrained parameters */
  int param_unc_num_ = -1;
};

#endif
