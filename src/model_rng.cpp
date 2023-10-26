#include "model_rng.hpp"
#include "version.hpp"
#include <stan/io/ends_with.hpp>
#include <stan/io/json/json_data.hpp>
#include <stan/io/empty_var_context.hpp>
#include <stan/io/var_context.hpp>
#include <stan/model/model_base.hpp>
#include <stan/services/util/create_rng.hpp>
#include <stan/math.hpp>
#include <stan/math/prim/meta.hpp>
#include <stan/version.hpp>
#ifdef BRIDGESTAN_AD_HESSIAN
#include <stan/math/mix.hpp>
#endif
#include <algorithm>
#include <cmath>
#include <exception>
#include <fstream>
#include <iostream>
#include <ostream>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

// globals for Stan model output
std::streambuf* buf = nullptr;
std::ostream* outstream = &std::cout;

/**
 * Allocate and return a new model as a reference given the specified
 * data context, seed, and message stream.  This function is defined
 * in the generated model class.
 *
 * @param[in] data_context context for reading model data
 * @param[in] seed random seed for transformed data block
 * @param[in] msg_stream stream to which to send messages printed by the model
 */
stan::model::model_base& new_model(stan::io::var_context& data_context,
                                   unsigned int seed, std::ostream* msg_stream);

/**
 * Convert the specified sequence of names to comma-separated value
 * format.  This does a heap allocation, so the resulting string
 * must be freed to prevent a memory leak.  The CSV is output
 * without additional space around the commas.
 *
 * @param names sequence of names to convert
 * @return CSV formatted sequence of names
 */
char* to_csv(const std::vector<std::string>& names) {
  std::stringstream ss;
  for (size_t i = 0; i < names.size(); ++i) {
    if (i > 0)
      ss << ',';
    ss << names[i];
  }
  std::string s = ss.str();
  const char* s_c = s.c_str();
  return strdup(s_c);
}

bs_model::bs_model(const char* data, unsigned int seed) {
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
  info << "Stan version: " << stan::MAJOR_VERSION << '.' << stan::MINOR_VERSION
       << '.' << stan::PATCH_VERSION << std::endl;

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
  param_unc_names_ = to_csv(names);
  param_unc_num_ = names.size();

  names.clear();
  model_->constrained_param_names(names, false, false);
  param_names_ = to_csv(names);
  param_num_ = names.size();

  names.clear();
  model_->constrained_param_names(names, true, false);
  param_tp_names_ = to_csv(names);
  param_tp_num_ = names.size();

  names.clear();
  model_->constrained_param_names(names, false, true);
  param_gq_names_ = to_csv(names);
  param_gq_num_ = names.size();

  names.clear();
  model_->constrained_param_names(names, true, true);
  param_tp_gq_names_ = to_csv(names);
  param_tp_gq_num_ = names.size();
}

bs_model::~bs_model() noexcept {
  delete (model_);
  free(name_);
  free(model_info_);
  free(param_unc_names_);
  free(param_names_);
  free(param_tp_names_);
  free(param_gq_names_);
  free(param_tp_gq_names_);
}

const char* bs_model::name() const { return name_; }

const char* bs_model::model_info() const { return model_info_; }

const char* bs_model::param_names(bool include_tp, bool include_gq) const {
  if (include_tp && include_gq)
    return param_tp_gq_names_;
  if (include_tp)
    return param_tp_names_;
  if (include_gq)
    return param_gq_names_;
  return param_names_;
}

const char* bs_model::param_unc_names() const { return param_unc_names_; }

int bs_model::param_unc_num() const { return param_unc_num_; }

int bs_model::param_num(bool include_tp, bool include_gq) const {
  if (include_tp && include_gq)
    return param_tp_gq_num_;
  if (include_tp)
    return param_tp_num_;
  if (include_gq)
    return param_gq_num_;
  return param_num_;
}

void bs_model::param_unconstrain(const double* theta, double* theta_unc) const {
  Eigen::VectorXd params = Eigen::VectorXd::Map(theta, param_num_);
  Eigen::VectorXd unc_params;
  model_->unconstrain_array(params, unc_params, outstream);
  Eigen::VectorXd::Map(theta_unc, unc_params.size()) = unc_params;
}

void bs_model::param_unconstrain_json(const char* json,
                                      double* theta_unc) const {
  std::stringstream in(json);
  stan::json::json_data inits_context(in);
  Eigen::VectorXd params_unc;
  model_->transform_inits(inits_context, params_unc, outstream);
  Eigen::VectorXd::Map(theta_unc, params_unc.size()) = params_unc;
}

void bs_model::param_constrain(bool include_tp, bool include_gq,
                               const double* theta_unc, double* theta,
                               boost::ecuyer1988& rng) const {
  Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, param_unc_num_);
  Eigen::VectorXd params;
  model_->write_array(rng, params_unc, params, include_tp, include_gq,
                      outstream);
  Eigen::VectorXd::Map(theta, params.size()) = params;
}

auto bs_model::make_model_lambda(bool propto, bool jacobian) const {
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

void bs_model::log_density(bool propto, bool jacobian, const double* theta_unc,
                           double* val) const {
  Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, param_unc_num_);

  if (propto) {
    // need to have vars, otherwise the result is 0 since everything is
    // treated as a constant
    try {
      Eigen::Matrix<stan::math::var, Eigen::Dynamic, 1> params_unc_var(
          params_unc);
      if (jacobian) {
        *val
            = model_->log_prob_propto_jacobian(params_unc_var, outstream).val();
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

void bs_model::log_density_gradient(bool propto, bool jacobian,
                                    const double* theta_unc, double* val,
                                    double* grad) const {
#ifdef STAN_THREADS
  static thread_local stan::math::ChainableStack thread_instance;
#endif
  auto logp = make_model_lambda(propto, jacobian);
  int N = param_unc_num_;
  Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, N);
  stan::math::gradient(logp, params_unc, *val, grad, grad + N);
}

void bs_model::log_density_hessian(bool propto, bool jacobian,
                                   const double* theta_unc, double* val,
                                   double* grad, double* hessian) const {
#ifdef STAN_THREADS
  static thread_local stan::math::ChainableStack thread_instance;
#endif
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

void bs_model::log_density_hessian_vector_product(bool propto, bool jacobian,
                                                  const double* theta_unc,
                                                  const double* vector,
                                                  double* val,
                                                  double* hvp) const {
#ifdef STAN_THREADS
  static thread_local stan::math::ChainableStack thread_instance;
#endif
  auto logp = make_model_lambda(propto, jacobian);

  int N = param_unc_num_;
  Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
  Eigen::Map<const Eigen::VectorXd> v(vector, N);
  Eigen::VectorXd hvp_vec(N);

#ifdef BRIDGESTAN_AD_HESSIAN
  stan::math::hessian_times_vector(logp, params_unc, v, *val, hvp_vec);
#else
  stan::math::internal::finite_diff_hessian_times_vector_auto(logp, params_unc,
                                                              v, *val, hvp_vec);
#endif

  Eigen::VectorXd::Map(hvp, N) = hvp_vec;
}
