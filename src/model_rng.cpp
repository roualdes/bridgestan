#include "model_rng.hpp"
#include <cmdstan/io/json/json_data.hpp>
#include <stan/io/array_var_context.hpp>
#include <stan/io/empty_var_context.hpp>
#include <stan/io/var_context.hpp>
#include <stan/model/model_base.hpp>
#include <stan/math.hpp>
#include <stan/version.hpp>
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

model_rng::model_rng(const char* data_file, unsigned int seed,
                     unsigned int chain_id) {
  std::string data(data_file);
  if (data.empty()) {
    auto data_context = stan::io::empty_var_context();
    model_ = &new_model(data_context, seed, &std::cerr);
  } else {
    std::ifstream in(data);
    if (!in.good())
      throw std::runtime_error("Cannot read input file: " + data);
    auto data_context = cmdstan::json::json_data(in);
    in.close();
    model_ = &new_model(data_context, seed, &std::cerr);
  }
  boost::ecuyer1988 rng(seed);
  rng.discard(chain_id * 1000000000000L);
  rng_ = rng;

  std::string model_name = model_->model_name();
  const char* model_name_c = model_name.c_str();
  name_ = strdup(model_name_c);

  std::stringstream info;
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

model_rng::~model_rng() {
  delete (model_);
  free(name_);
  free(model_info_);
  free(param_unc_names_);
  free(param_names_);
  free(param_tp_names_);
  free(param_gq_names_);
  free(param_tp_gq_names_);
}

const char* model_rng::name() { return name_; }

const char* model_rng::model_info() { return model_info_; }

const char* model_rng::param_names(bool include_tp, bool include_gq) {
  if (include_tp && include_gq)
    return param_tp_gq_names_;
  if (include_tp)
    return param_tp_names_;
  if (include_gq)
    return param_gq_names_;
  return param_names_;
}

const char* model_rng::param_unc_names() { return param_unc_names_; }

int model_rng::param_unc_num() { return param_unc_num_; }

int model_rng::param_num(bool include_tp, bool include_gq) {
  if (include_tp && include_gq)
    return param_tp_gq_num_;
  if (include_tp)
    return param_tp_num_;
  if (include_gq)
    return param_gq_num_;
  return param_num_;
}

void model_rng::param_unconstrain(const double* theta, double* theta_unc) {
  using std::set;
  using std::string;
  using std::vector;
  vector<vector<size_t>> base_dims;
  model_->get_dims(base_dims);  // includes tp, gq
  vector<string> base_names;
  model_->get_param_names(base_names);
  vector<string> indexed_names;
  model_->constrained_param_names(indexed_names, false, false);
  set<string> names_used;
  for (const auto& name : indexed_names) {
    size_t index = name.find('.');
    if (index != std::string::npos)
      names_used.emplace(name.substr(0, index));
    else
      names_used.emplace(name);
  }
  vector<string> names;
  vector<vector<size_t>> dims;
  for (size_t i = 0; i < base_names.size(); ++i) {
    if (names_used.find(base_names[i]) != names_used.end()) {
      names.emplace_back(base_names[i]);
      dims.emplace_back(base_dims[i]);
    }
  }
  Eigen::VectorXd params = Eigen::VectorXd::Map(theta, param_num_);
  stan::io::array_var_context avc(names, params, dims);
  Eigen::VectorXd unc_params;
  model_->transform_inits(avc, unc_params, &std::cout);
  Eigen::VectorXd::Map(theta_unc, unc_params.size()) = unc_params;
}

void model_rng::param_unconstrain_json(const char* json, double* theta_unc) {
  std::stringstream in(json);
  cmdstan::json::json_data inits_context(in);
  Eigen::VectorXd params_unc;
  model_->transform_inits(inits_context, params_unc, &std::cerr);
  Eigen::VectorXd::Map(theta_unc, params_unc.size()) = params_unc;
}

void model_rng::param_constrain(bool include_tp, bool include_gq,
                                const double* theta_unc, double* theta) {
  using Eigen::VectorXd;
  VectorXd params_unc = VectorXd::Map(theta_unc, param_unc_num_);
  Eigen::VectorXd params;
  model_->write_array(rng_, params_unc, params, include_tp, include_gq,
                      &std::cerr);
  Eigen::VectorXd::Map(theta, params.size()) = params;
}

auto model_rng::make_model_lambda(bool propto, bool jacobian) {
  return [model = this->model_, propto, jacobian](auto& x) {
    if (propto) {
      if (jacobian) {
        return model->log_prob_propto_jacobian(x, &std::cerr);
      } else {
        return model->log_prob_propto(x, &std::cerr);
      }
    } else {
      if (jacobian) {
        return model->log_prob_jacobian(x, &std::cerr);
      } else {
        return model->log_prob(x, &std::cerr);
      }
    }
  };
}

void model_rng::log_density(bool propto, bool jacobian, const double* theta_unc,
                            double* val) {
  int N = param_unc_num_;
  if (propto) {
    Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
    auto logp = make_model_lambda(propto, jacobian);
    static thread_local stan::math::ChainableStack thread_instance;
    Eigen::VectorXd grad(N);
    stan::math::gradient(logp, params_unc, *val, grad);
  } else {
    Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, N);
    if (jacobian) {
      *val = model_->log_prob_jacobian(params_unc, &std::cerr);
    } else {
      *val = model_->log_prob(params_unc, &std::cerr);
    }
  }
}

void model_rng::log_density_gradient(bool propto, bool jacobian,
                                     const double* theta_unc, double* val,
                                     double* grad) {
  static thread_local stan::math::ChainableStack thread_instance;
  auto logp = make_model_lambda(propto, jacobian);
  int N = param_unc_num_;
  Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, N);
  Eigen::VectorXd grad_vec(N);
  stan::math::gradient(logp, params_unc, *val, grad_vec);
  Eigen::VectorXd::Map(grad, N) = grad_vec;
}

void model_rng::log_density_hessian(bool propto, bool jacobian,
                                    const double* theta_unc, double* val,
                                    double* grad, double* hessian) {
  static thread_local stan::math::ChainableStack thread_instance;
  auto logp = make_model_lambda(propto, jacobian);
  int N = param_unc_num_;
  Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
  Eigen::VectorXd grad_vec(N);
  Eigen::MatrixXd hess_mat(N, N);
  stan::math::internal::finite_diff_hessian_auto(logp, params_unc, *val,
                                                 grad_vec, hess_mat);
  Eigen::VectorXd::Map(grad, N) = grad_vec;
  Eigen::MatrixXd::Map(hessian, N, N) = hess_mat;
}
