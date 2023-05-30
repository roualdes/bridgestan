#ifndef MODEL_RNG_H
#define MODEL_RNG_H

#include <stan/model/model_base.hpp>
#include <boost/random/additive_combine.hpp>
#include <string>
#include <vector>
#include <random>

/**
 * This structure holds a pointer to a model and holds pointers to the parameter
 * names in CSV format.  Instances can be constructed with the C function
 * `bs_construct()` and destroyed with the C function `bs_destruct()`.
 */
class bs_model {
 public:
  /**
   * Construct a model and random number generator with cached
   * parameter numbers and names.
   *
   * @param[in] data C-style string. This is either a
   * path to JSON-encoded data file (must end with ".json"),
   * a JSON string literal, or nullptr. An empty string or null
   * pointer are both interpreted as no data.
   * @param[in] seed pseudorandom number generator seed
   */
  bs_model(const char* data, unsigned int seed);

  /**
   * Destroy this object and free all of the memory allocated for it.
   */
  ~bs_model() noexcept;

  /**
   * Return the name of the model.  This class manages the memory,
   * so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* name() const;

  /**
   *  Return information about the compiled model. This class manages the
   * memory, so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* model_info() const;

  /**
   * Return the parameter names as a comma-separated list.  Indexes
   * are separted with periods. This class manages the memory, so
   * the returned string should not be freed.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return comma-separated parameter names with indexes
   */
  const char* param_names(bool include_tp, bool include_gq) const;

  /**
   * Return the unconstrained parameter names as a comma-separated
   * list.  This class manages the memory, so the returned string
   * should not be freed.
   *
   * @return comma-separated unconstrained parameter names with
   * indexes
   */
  const char* param_unc_names() const;

  /**
   * Return the number of unconstrianed parameters.
   *
   * @return number of unconstrained parameters
   */
  int param_unc_num() const;

  /**
   * Return the number of parameters, optionally including
   * transformed parameters and/or generated quantities.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return number of parameters
   */
  int param_num(bool include_tp, bool include_gq) const;

  /**
   * Unconstrain the specified parameters and write into the
   * specified unconstrained parameter array.
   *
   * @param[in] theta parameters to unconstrain
   * @param[out] theta_unc unconstrained parameters
   */
  void param_unconstrain(const double* theta, double* theta_unc) const;

  /**
   * Unconstrain the parameters specified as a JSON string and write
   * into the specified unconstrained parameter array.  See the
   * CmdStan Reference Manual for details of the JSON schema.
   *
   * @param[in] json JSON string representing parameters
   * @param[out] theta_unc unconstrained parameters generated
   */
  void param_unconstrain_json(const char* json, double* theta_unc) const;

  /**
   * Constrain the specified unconstrained parameters into the
   * specified array, optionally including transformed parameters
   * and generated quantities as specified.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @param[in] theta_unc unconstrained parameters to constrain
   * @param[out] theta constrained parameters generated
   */
  void param_constrain(bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta,
                       boost::ecuyer1988& rng) const;

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
   * @param[out] val log density produced
   */
  void log_density(bool propto, bool jacobian, const double* theta_unc,
                   double* val) const;

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
   * @param[out] val log density produced
   * @param[out] grad gradient produced
   */
  void log_density_gradient(bool propto, bool jacobian, const double* theta_unc,
                            double* val, double* grad) const;

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
   * @param[out] val log density produced
   * @param[out] grad gradient produced
   * @param[out] hess Hessian produced
   */
  void log_density_hessian(bool propto, bool jacobian, const double* theta_unc,
                           double* val, double* grad, double* hessian) const;

  /**
   * Calculate the log density and the product of the Hessian with the specified
   * vector for the specified unconstrain parameters and write it into the
   * specified value pointer and Hessian-vector product pointer, dropping
   * constants it `propto` is `true` and including the Jacobian adjustment if
   * `jacobian` is `true`.
   *
   * @note If `BRIDGESTAN_AD_HESSIAN` is not defined, the complexity of this
   * function goes from O(N^2) to O(N^3), and the accuracy of the result is
   * reduced.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   * @param[in] theta_unc unconstrained parameters
   * @param[in] vector vector to multiply Hessian by
   * @param[out] val log density produced
   * @param[out] hvp Hessian-vector product produced
   */
  void log_density_hessian_vector_product(bool propto, bool jacobian,
                                          const double* theta_unc,
                                          const double* vector, double* val,
                                          double* hvp) const;

  /**
   * Returns a lambda which calls the correct version of log_prob
   * depending on the values of propto and jacobian.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   */
  auto make_model_lambda(bool propto, bool jacobian) const;

 private:
  /** Stan model */
  stan::model::model_base* model_;

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

/**
 * A wrapper around the Boost random number generator required
 * by the Stan model's write_array methods. Instances can be
 * constructed with the C function `bs_construct_rng()` and destroyed
 * with the C function `bs_destruct_rng()`.
 */
class bs_rng {
 public:
  bs_rng(unsigned int seed) : rng_(seed) {
    // discard first value as workaround for
    // https://github.com/stan-dev/stan/issues/3167
    rng_.discard(1);
  }

  boost::ecuyer1988 rng_;
};

#endif
