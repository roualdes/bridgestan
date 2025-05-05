#ifndef BRIDGESTAN_MODEL_RNG_HPP
#define BRIDGESTAN_MODEL_RNG_HPP

#include <stan/io/ends_with.hpp>
#include <stan/io/json/json_data.hpp>
#include <stan/io/empty_var_context.hpp>
#include <stan/io/var_context.hpp>
#include <stan/model/model_base.hpp>
#include <stan/services/util/create_rng.hpp>
#ifdef BRIDGESTAN_AD_HESSIAN
#include <stan/math/mix.hpp>
#endif
#include <stan/math.hpp>
#include <stan/version.hpp>

#include <cmath>
#include <fstream>
#include <iostream>
#include <ostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include "util.hpp"
#include "version.hpp"

// whenever we are doing autodiff in a threaded context, we need to
// ensure a thread-local ChainableStack exists. This macro is invoked in
// each function that could need it.
#ifdef STAN_THREADS
#define BRIDGESTAN_PREPARE_AD_FOR_THREADING() \
  static thread_local stan::math::ChainableStack thread_instance
#else
#define BRIDGESTAN_PREPARE_AD_FOR_THREADING()
#endif

/**
 * Allocate and return a new model as a reference given the specified
 * data context, seed, and message stream.
 * This function is defined in the generated model class.
 *
 * @param[in] data_context context for reading model data
 * @param[in] seed random seed for transformed data block
 * @param[in] msg_stream stream to which to send messages printed by the model
 */
stan::model::model_base& new_model(stan::io::var_context& data_context,
                                   unsigned int seed, std::ostream* msg_stream);

// Defined in bridgestan.cpp, this global is used for model output
// TODO(bmw): Next major version, move inside of the model object
extern std::ostream* outstream;

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
  bs_model(const char* data, unsigned int seed) {
    if (data == nullptr) {
      stan::io::empty_var_context data_context;
      model_ = &new_model(data_context, seed, outstream);
    } else {
      std::string data_str(data);
      if (data_str.empty()) {
        stan::io::empty_var_context data_context;
        model_ = &new_model(data_context, seed, outstream);
      } else {
        if (stan::io::ends_with(".json", data_str)) {
          std::ifstream in(data_str);
          if (!in.good())
            throw std::runtime_error("Cannot read input file: " + data_str);
          stan::json::json_data data_context(in);
          in.close();
          model_ = &new_model(data_context, seed, outstream);
        } else {
          std::istringstream json(data_str);
          stan::json::json_data data_context(json);
          model_ = &new_model(data_context, seed, outstream);
        }
      }
    }

    std::string model_name = model_->model_name();
    const char* model_name_c = model_name.c_str();
    name_ = strdup(model_name_c);

    std::stringstream info;
    info << "BridgeStan version: " << bridgestan::MAJOR_VERSION << '.'
         << bridgestan::MINOR_VERSION << '.' << bridgestan::PATCH_VERSION
         << std::endl;
    info << "Stan version: " << stan::MAJOR_VERSION << '.'
         << stan::MINOR_VERSION << '.' << stan::PATCH_VERSION << std::endl;

    info << "Stan C++ Defines:" << std::endl;
#ifdef STAN_THREADS
    info << "\tSTAN_THREADS=true" << std::endl;
#else
    info << "\tSTAN_THREADS=false" << std::endl;
#endif
#ifdef STAN_MPI
    info << "\tSTAN_MPI=true" << std::endl;
#else
    info << "\tSTAN_MPI=false" << std::endl;
#endif
#ifdef STAN_OPENCL
    info << "\tSTAN_OPENCL=true" << std::endl;
#else
    info << "\tSTAN_OPENCL=false" << std::endl;
#endif
#ifdef STAN_NO_RANGE_CHECKS
    info << "\tSTAN_NO_RANGE_CHECKS=true" << std::endl;
#else
    info << "\tSTAN_NO_RANGE_CHECKS=false" << std::endl;
#endif
#ifdef STAN_CPP_OPTIMS
    info << "\tSTAN_CPP_OPTIMS=true" << std::endl;
#else
    info << "\tSTAN_CPP_OPTIMS=false" << std::endl;
#endif
#ifdef BRIDGESTAN_AD_HESSIAN
    info << "\tBRIDGESTAN_AD_HESSIAN=true" << std::endl;
#else
    info << "\tBRIDGESTAN_AD_HESSIAN=false" << std::endl;
#endif

    info << "Stan Compiler Details:" << std::endl;
    for (auto s : model_->model_compile_info()) {
      info << '\t' << s << std::endl;
    }

    model_info_ = strdup(info.str().c_str());

    std::vector<std::string> names;
    model_->unconstrained_param_names(names, false, false);
    param_unc_names_ = bridgestan::to_csv(names);
    param_unc_num_ = names.size();

    names.clear();
    model_->constrained_param_names(names, false, false);
    param_names_ = bridgestan::to_csv(names);
    param_num_ = names.size();

    names.clear();
    model_->constrained_param_names(names, true, false);
    param_tp_names_ = bridgestan::to_csv(names);
    param_tp_num_ = names.size();

    names.clear();
    model_->constrained_param_names(names, false, true);
    param_gq_names_ = bridgestan::to_csv(names);
    param_gq_num_ = names.size();

    names.clear();
    model_->constrained_param_names(names, true, true);
    param_tp_gq_names_ = bridgestan::to_csv(names);
    param_tp_gq_num_ = names.size();
  }

  bs_model(bs_model const&) = delete;
  bs_model operator=(bs_model const&) = delete;
  bs_model(bs_model&&) = delete;
  bs_model operator=(bs_model&&) = delete;

  /**
   * Destroy this object and free all of the memory allocated for it.
   */
  ~bs_model() noexcept {
    delete (model_);
    free(name_);
    free(model_info_);
    free(param_unc_names_);
    free(param_names_);
    free(param_tp_names_);
    free(param_gq_names_);
    free(param_tp_gq_names_);
  }

  /**
   * Return the name of the model.  This class manages the memory,
   * so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* name() const { return name_; }

  /**
   *  Return information about the compiled model. This class manages the
   * memory, so the returned string should not be freed.
   *
   * @return name of model
   */
  const char* model_info() const { return model_info_; }

  /**
   * Return the parameter names as a comma-separated list.  Indexes
   * are separated with periods. This class manages the memory, so
   * the returned string should not be freed.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return comma-separated parameter names with indexes
   */
  const char* param_names(bool include_tp, bool include_gq) const {
    if (include_tp && include_gq)
      return param_tp_gq_names_;
    if (include_tp)
      return param_tp_names_;
    if (include_gq)
      return param_gq_names_;
    return param_names_;
  }

  /**
   * Return the unconstrained parameter names as a comma-separated
   * list.  This class manages the memory, so the returned string
   * should not be freed.
   *
   * @return comma-separated unconstrained parameter names with
   * indexes
   */
  const char* param_unc_names() const { return param_unc_names_; }

  /**
   * Return the number of unconstrianed parameters.
   *
   * @return number of unconstrained parameters
   */
  int param_unc_num() const { return param_unc_num_; }

  /**
   * Return the number of parameters, optionally including
   * transformed parameters and/or generated quantities.
   *
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return number of parameters
   */
  int param_num(bool include_tp, bool include_gq) const {
    if (include_tp && include_gq)
      return param_tp_gq_num_;
    if (include_tp)
      return param_tp_num_;
    if (include_gq)
      return param_gq_num_;
    return param_num_;
  }

  /**
   * Unconstrain the specified parameters and write into the
   * specified unconstrained parameter array.
   *
   * @param[in] theta parameters to unconstrain
   * @param[out] theta_unc unconstrained parameters
   */
  void param_unconstrain(const double* theta, double* theta_unc) const {
    Eigen::VectorXd params = Eigen::VectorXd::Map(theta, param_num_);
    Eigen::VectorXd unc_params;
    model_->unconstrain_array(params, unc_params, outstream);
    Eigen::VectorXd::Map(theta_unc, unc_params.size()) = unc_params;
  }

  /**
   * Unconstrain the parameters specified as a JSON string and write
   * into the specified unconstrained parameter array.  See the
   * CmdStan Reference Manual for details of the JSON schema.
   *
   * @param[in] json JSON string representing parameters
   * @param[out] theta_unc unconstrained parameters generated
   */
  void param_unconstrain_json(const char* json, double* theta_unc) const {
    std::stringstream in(json);
    stan::json::json_data inits_context(in);
    Eigen::VectorXd params_unc;
    model_->transform_inits(inits_context, params_unc, outstream);
    Eigen::VectorXd::Map(theta_unc, params_unc.size()) = params_unc;
  }

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
                       stan::rng_t& rng) const {
    Eigen::VectorXd params_unc
        = Eigen::VectorXd::Map(theta_unc, param_unc_num_);
    Eigen::VectorXd params;
    model_->write_array(rng, params_unc, params, include_tp, include_gq,
                        outstream);
    Eigen::VectorXd::Map(theta, params.size()) = params;
  }

 private:
  /**
   * Returns a lambda which calls the correct version of log_prob
   * depending on the values of propto and jacobian.
   *
   * @param[in] propto `true` to drop constant terms
   * @param[in] jacobian `true` to include Jacobian adjustment for
   * constrained parameter transforms
   */
  auto make_model_lambda(bool propto, bool jacobian) const {
    return [model = this->model_, propto, jacobian](auto& x) {
      // log_prob() requires non-const but doesn't modify its argument
      auto& params
          = const_cast<Eigen::Matrix<stan::scalar_type_t<decltype(x)>, -1, 1>&>(
              x);
      if (propto) {
        if (jacobian) {
          return model->log_prob_propto_jacobian(params, outstream);
        } else {
          return model->log_prob_propto(params, outstream);
        }
      } else {
        if (jacobian) {
          return model->log_prob_jacobian(params, outstream);
        } else {
          return model->log_prob(params, outstream);
        }
      }
    };
  }

 public:
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
                   double* val) const {
    Eigen::VectorXd params_unc
        = Eigen::VectorXd::Map(theta_unc, param_unc_num_);

    if (propto) {
      // need to have vars, otherwise the result is 0 since everything is
      // treated as a constant
      BRIDGESTAN_PREPARE_AD_FOR_THREADING();
      try {
        Eigen::Matrix<stan::math::var, Eigen::Dynamic, 1> params_unc_var(
            params_unc);
        if (jacobian) {
          *val = model_->log_prob_propto_jacobian(params_unc_var, outstream)
                     .val();
        } else {
          *val = model_->log_prob_propto(params_unc_var, outstream).val();
        }
      } catch (...) {
        // because we created vars on the stack, we need to recover memory
        stan::math::recover_memory();
        throw;  // re-caught by top level exception logic
      }
      // also recover memory if no exception was thrown
      stan::math::recover_memory();
    } else {
      if (jacobian) {
        *val = model_->log_prob_jacobian(params_unc, outstream);
      } else {
        *val = model_->log_prob(params_unc, outstream);
      }
    }
  }

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
                            double* val, double* grad) const {
    BRIDGESTAN_PREPARE_AD_FOR_THREADING();
    auto logp = make_model_lambda(propto, jacobian);
    int N = param_unc_num_;
    Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, N);
    stan::math::gradient(logp, params_unc, *val, grad, grad + N);
  }

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
                           double* val, double* grad, double* hessian) const {
    BRIDGESTAN_PREPARE_AD_FOR_THREADING();
    auto logp = make_model_lambda(propto, jacobian);
    int N = param_unc_num_;
    Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
    Eigen::VectorXd grad_vec(N);
    Eigen::MatrixXd hess_mat(N, N);

#ifdef BRIDGESTAN_AD_HESSIAN
    stan::math::hessian(logp, params_unc, *val, grad_vec, hess_mat);
#else
    stan::math::internal::finite_diff_hessian_auto(logp, params_unc, *val,
                                                   grad_vec, hess_mat);
#endif

    Eigen::VectorXd::Map(grad, N) = grad_vec;
    Eigen::MatrixXd::Map(hessian, N, N) = hess_mat;
  }

  /**
   * Calculate the log density and the product of the Hessian with the specified
   * vector for the specified unconstrain parameters and write it into the
   * specified value pointer and Hessian-vector product pointer, dropping
   * constants it `propto` is `true` and including the Jacobian adjustment if
   * `jacobian` is `true`.
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
                                          double* hvp) const {
    BRIDGESTAN_PREPARE_AD_FOR_THREADING();
    auto logp = make_model_lambda(propto, jacobian);
    int N = param_unc_num_;
    Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
    Eigen::Map<const Eigen::VectorXd> v(vector, N);
    Eigen::VectorXd hvp_vec(N);

#ifdef BRIDGESTAN_AD_HESSIAN
    stan::math::hessian_times_vector(logp, params_unc, v, *val, hvp_vec);
#else
    stan::math::internal::finite_diff_hessian_times_vector_auto(
        logp, params_unc, v, *val, hvp_vec);
#endif

    Eigen::VectorXd::Map(hvp, N) = hvp_vec;
  }

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

#endif
