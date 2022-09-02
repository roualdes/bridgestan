#include "model_functor.hpp"
#include <cmdstan/io/json/json_data.hpp>
#include <stan/math.hpp>
#include <stan/io/array_var_context.hpp>
#include <stan/io/empty_var_context.hpp>
#include <stan/model/model_base.hpp>

#include <algorithm>
#include <cmath>
#include <exception>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

extern "C" {

  /**
   * This structure holds a pointer to a model, holds a pseudorandom
   * number generator, and holds pointers to the parameter names in
   * CSV format.  Instances should be created using the `construct()`
   * function, which allocates all of the components.  Instances
   * should be destroyed using the `destruct()` function, which
   * frees all of the allocated components.
   */
  struct model_rng {
    /** Stan model */
    stan::model::model_base* model_;

    /** pseudorandom number generator */
    boost::ecuyer1988 rng_;

    /** number of unconstrained parameters */
    int param_unc_num_ = -1;

    /** number of parameters */
    int param_num_ = -1;

    /** number of parameters + transformed parameters */
    int param_tp_num_ = -1;

    /** number of parameters + generated quantities */
    int param_gq_num_ = -1;

    /** number of parameters + transformed parameters + generated quantities */
    int param_tp_gq_num_ = -1;

    /** name of the Stan model */
    char* name_ = nullptr;

    /** name of the Stan model */
    char* param_unc_names_ = nullptr;

    /** CSV list of parameter names */
    char* param_names_ = nullptr;

    /** CSV list of parameter, transformed parameter names */
    char* param_tp_names_ = nullptr;

    /** CSV list of parameter, generated quantity names */
    char* param_gq_names_ = nullptr;

    /**
     * CSV list of parameter, transformed parameters, generated
     * quantity names
     */
    char* param_tp_gq_names_ = nullptr;
  };


  /**
   * Construct an instance of a model and pseudorandom number
   * generator (PRNG) wrapper.  Data must be encoded in JSON as
   * indicated in the *CmdStan Reference Manual*.
   *
   * @param[in] data_file C-style path to JSON-encoded data file
   * @param[in] seed seed for PRNG
   * @param[in] chain_id identifier for concurrent sequence of PRNG
   * draws
   * @return pointer to constructed model or `nullptr` if construction
   * fails
   */
  model_rng* construct(char* data_file, unsigned int seed,
		       unsigned int chain_id);

  /**
   * Destroy the model and return 0 for success and -1 if there is an
   * exception while freeing memory.
   *
   * @param[in] mr pointer to model and RNG structure
   * @return 0 for success and -1 if there is an exception freeing one
   * of the model components.
   */
  int destruct(model_rng* mr);

  /**
   * Return the name of the specified model as a C-style string.
   *
   * The returned string should not be modified; it is freed when the
   * model and RNG wrapper is destroyed.
   *
   * @param[in] mr pointer to model and RNG structure
   * @return name of model
   */
  const char* name(model_rng* mr);


  /**
   * Return a comma-separated sequence of indexed parameter names,
   * including the transformed parameters and/or generated quantities
   * as specified.
   *
   * The parameters are returned in the order they are declared.
   * Multivariate parameters are return in column-major (more
   * generally last-index major) order.  Parameters are separated with
   * periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
   * 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
   *
   * The returned string should not be modified; it is freed when the
   * model and RNG wrapper is destroyed.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return CSV-separated, indexed, parameter names
   */
  const char* param_names(model_rng* mr, bool include_tp, bool include_gq);

  /**
   * Return a comma-separated sequence of unconstrained parameters.
   * Only parameters are unconstrained, so there are no unconstrained
   * transformed parameters or generated quantities.
   *
   * The parameters are returned in the order they are declared.
   * Multivariate parameters are return in column-major (more
   * generally last-index major) order.  Parameters are separated with
   * periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
   * 3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
   *
   * The returned string should not be modified; it is freed when the
   * model and RNG wrapper is destroyed.
   *
   * @param[in] mr pointer to model and RNG structure
   * @return CSV-separated, indexed, unconstrained parameter names
   */
  const char* param_unc_names(model_rng* mr);

  /**
   * Return the number of scalar parameters, optionally including the
   * number of transformed parameters and/or generated quantities.
   * For example, a 2 x 3 matrix counts as 6 scalar parameters.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @return number of parameters
   */
  int param_num(model_rng* mr, bool include_tp, bool include_gq);

  /**
   * Return the number of unconstrained parameters.  The number of
   * unconstrained parameters might be smaller than the number of
   * parameters if the unconstrained space has fewer dimensions than
   * the constrained (e.g., for simplexes or correlation matrices).
   *
   * @param[in] mr pointer to model and RNG structure
   * @return number of unconstrained parameters
   */
  int param_unc_num(model_rng* mr);


  /**
   * Set the sequence of constrained parameters based on the specified
   * unconstrained parameters, including transformed parameters and/or
   * generated quantities as specified, and return a return code of 0
   * for success and -1 for failure.  Parameter order is as declared
   * in the Stan program, with multivariate parameters given in
   * last-index-major order.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] include_tp `true` to include transformed parameters
   * @param[in] include_gq `true` to include generated quantities
   * @param[in] theta_unc sequence of unconstrained parameters
   * @param[out] theta sequence of constrained parameters
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int param_constrain(model_rng* mr, bool include_tp, bool include_gq,
		       const double* theta_unc, double* theta);


  /**
   * Set the sequence of unconstrained parameters based on the
   * specified constrained parameters, and return a return code of 0
   * for success and -1 for failure.  Parameter order is as declared
   * in the Stan program, with multivariate parameters given in
   * last-index-major order.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] theta sequence of constrained parameters
   * @param[out] theta_unc sequence of unconstrained parameters
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int param_unconstrain(model_rng* mr, const double* theta,
			 double* theta_unc);

  /**
   * Set the sequence of unconstrained parameters based on the JSON
   * specification of the constrained parameters, and return a return
   * code of 0 for success and -1 for failure.  Parameter order is as
   * declared in the Stan program, with multivariate parameters given
   * in last-index-major order.  The JSON schema assumed is fully
   * defined in the *CmdStan Reference Manual*.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] json json-encoded constrained parameters
   * @param[out] theta_unc sequence of unconstrained parameters
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int param_unconstrain_json(model_rng* mr, const char* json,
			     double* theta_unc);


  /**
   * Set the log density of the specified parameters, dropping
   * constants if `propto` is `true` and including the Jacobian terms
   * resulting from constraining parameters if `jacobian` is `true`,
   * and return a return code of 0 for success and -1 if there is an
   * exception executing the Stan program.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] propto `true` to discard constant terms
   * @param[in] jacobian `true` to include change-of-variables terms
   * @param[in] theta unconstrained parameters
   * @param[out] lp log density to be set
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int log_density(model_rng* mr, bool propto, bool jacobian,
		  const double* theta, double* lp);

  /**
   * Set the log density and gradient of the specified parameters,
   * dropping constants if `propto` is `true` and including the
   * Jacobian terms resulting from constraining parameters if
   * `jacobian` is `true`, and return a return code of 0 for success
   * and -1 if there is an exception executing the Stan program.  The
   * gradient must have enough space to hold the gradient.
   *
   * The gradients are computed using automatic differentiation.
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] propto `true` to discard constant terms
   * @param[in] jacobian `true` to include change-of-variables terms
   * @param[in] theta unconstrained parameters
   * @param[out] val log density to be set
   * @param[out] grad gradient to set
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int log_density_gradient(model_rng* mr, bool propto, bool jacobian,
			    const double* theta, double* val, double* grad);

  /**
   * Set the log density, gradient, and Hessian of the specified parameters,
   * dropping constants if `propto` is `true` and including the
   * Jacobian terms resulting from constraining parameters if
   * `jacobian` is `true`, and return a return code of 0 for success
   * and -1 if there is an exception executing the Stan program.  The
   * pointer `grad` must have enough space to hold the gradient.  The
   * pointer `Hessian` must have enough space to hold the Hessian.
   *
   * The gradients are computed using automatic differentiation.  the
   * Hessians are
   *
   * @param[in] mr pointer to model and RNG structure
   * @param[in] propto `true` to discard constant terms
   * @param[in] jacobian `true` to include change-of-variables terms
   * @param[in] theta unconstrained parameters
   * @param[out] lp log density to be set
   * @param[out] grad gradient to set
   * @return code 0 if successful and code -1 if there is an exception
   * in the underlying Stan code
   */
  int log_density_hessian(model_rng* mr, bool propto, bool jacobian,
			  const double* theta, double* val, double* grad,
			  double* hessian);
}


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
    if (i > 0) ss << ',';
    ss << names[i];
  }
  std::string s = ss.str();
  const char* s_c = s.c_str();
  return strdup(s_c);
}


/**
 * Allocate and return a new model as a reference given the specified
 * data context, seed, and message stream.  This function is defined
 * in the generated model class.
 *
 * @param[in] data_context context for reading model data
 * @param[in] seed random seed for transformed data block
 * @param[in] msg_stream stream to which to send messages printed by the model
 */
stan::model::model_base& new_model(stan::io::var_context &data_context,
                                   unsigned int seed, std::ostream *msg_stream);

model_rng* construct_impl(char* data_file, unsigned int seed, unsigned int chain_id) {
  // enforce math lib thread locality for multi-threading
  static thread_local stan::math::ChainableStack dummy;

  model_rng* mr = new model_rng();
  std::string data(data_file);
  if (data.empty()) {
    auto data_context = stan::io::empty_var_context();
    mr->model_ = &new_model(data_context, seed, &std::cerr);
  } else {
    std::ifstream in(data);
    if (!in.good())
      throw std::runtime_error("Cannot read input file: " + data);
    auto data_context = cmdstan::json::json_data(in);
    in.close();
    mr->model_ = &new_model(data_context, seed, &std::cerr);
  }
  boost::ecuyer1988 rng(seed);
  rng.discard(chain_id * 1000000000000L);
  mr->rng_ = rng;

  std::string model_name = mr->model_->model_name();
  const char* model_name_c = model_name.c_str();
  mr->name_ = strdup(model_name_c);

  std::vector<std::string> names;
  mr->model_->unconstrained_param_names(names, false, false);
  mr->param_unc_names_ = to_csv(names);
  mr->param_unc_num_ = names.size();

  names.clear();
  mr->model_->constrained_param_names(names, false, false);
  mr->param_names_ = to_csv(names);
  mr->param_num_ = names.size();

  names.clear();
  mr->model_->constrained_param_names(names, true, false);
  mr->param_tp_names_ = to_csv(names);
  mr->param_tp_num_ = names.size();

  names.clear();
  mr->model_->constrained_param_names(names, false, true);
  mr->param_gq_names_ = to_csv(names);
  mr->param_gq_num_ = names.size();

  names.clear();
  mr->model_->constrained_param_names(names, true, true);
  mr->param_tp_gq_names_ = to_csv(names);
  mr->param_tp_gq_num_ = names.size();

  return  mr;
}

model_rng* construct(char* data_file, unsigned int seed,
		     unsigned int chain_id) {
  try {
    return construct_impl(data_file, seed, chain_id);
  } catch (const std::exception& e) {
    std::cerr << "construct(" << data_file
	      << ", " << seed
	      << ", " << chain_id << ")"
	      << " failed with exception: " << e.what()
	      << std::endl;
  } catch (...) {
    std::cerr << "construct(" << data_file
	      << ", " << seed << ", " << chain_id << ")"
	      << " failed with unknwon exception" << std::endl;
  }
  return nullptr;
}

int destruct(model_rng* mr) {
  try {
    free(mr->model_);
    free(mr->name_);
    free(mr->param_unc_names_);
    free(mr->param_names_);
    free(mr->param_tp_names_);
    free(mr->param_gq_names_);
    free(mr->param_tp_gq_names_);
    return 0;
  } catch (...) {
    std::cerr << "destruct() failed." << std::endl;
  }
  return -1;
}

const char* name(model_rng* mr) {
  return mr->name_;
}

const char* param_names(model_rng* mr, bool include_tp, bool include_gq) {
  // first branch used most of the time
  if (include_tp && include_gq) return mr->param_tp_gq_names_;
  if (include_tp) return mr->param_tp_names_;
  if (include_gq) return mr->param_gq_names_;
  return mr->param_names_;
}

const char* param_unc_names(model_rng* mr) {
  return mr->param_unc_names_;
}

int param_num(model_rng* mr, bool include_tp, bool include_gq) {
  // first branch used most of the time
  if (include_tp && include_gq) return mr->param_tp_gq_num_;
  if (include_tp) return mr->param_tp_num_;
  if (include_gq) return mr->param_gq_num_;
  return mr->param_num_;
}

int param_unc_num(model_rng* mr) {
  return mr->param_unc_num_;
}

void param_constrain2_impl(model_rng* mr, bool include_tp, bool include_gq,
			  const double* theta_unc, double* theta) {
  using Eigen::VectorXd;
  VectorXd params_unc = VectorXd::Map(theta_unc, param_unc_num(mr));
  Eigen::VectorXd params;
  mr->model_->write_array(mr->rng_, params_unc, params,
			  include_tp, include_gq, &std::cerr);
  Eigen::VectorXd::Map(theta, params.size()) = params;
}

int param_constrain(model_rng* mr, bool include_tp, bool include_gq,
                      const double* theta_unc, double* theta) {
  try {
    param_constrain2_impl(mr, include_tp, include_gq, theta_unc, theta);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_constrain() exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_constrain() unknown exception" << std::endl;
  }
  return 1;
}

void param_unconstrain2_impl(model_rng* mr, const double* theta,
			     double* theta_unc) {

  using std::set;
  using std::string;
  using std::vector;
  vector<vector<size_t>> base_dims;
  mr->model_->get_dims(base_dims);  // includes tp, gq
  vector<string> base_names;
  mr->model_->get_param_names(base_names);
  vector<string> indexed_names;
  mr->model_->constrained_param_names(indexed_names, false, false);
  set<string> names_used;
  for (const auto& name: indexed_names) {
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
  Eigen::VectorXd params = Eigen::VectorXd::Map(theta, mr->param_num_);
  stan::io::array_var_context avc(names, params, dims);
  Eigen::VectorXd unc_params;
  mr->model_->transform_inits(avc, unc_params, &std::cout);
  Eigen::VectorXd::Map(theta_unc, unc_params.size()) = unc_params;
}

int param_unconstrain(model_rng* mr, const double* theta,
			double* theta_unc) {
  try {
    param_unconstrain2_impl(mr, theta, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_unconstrain exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_unconstrain unknown exception" << std::endl;
  }
  return -1;
}

void param_unconstrain_json_impl(model_rng* mr, const char* json,
				 double* theta_unc) {
  std::stringstream in(json);
  cmdstan::json::json_data inits_context(in);
  Eigen::VectorXd params_unc;
  mr->model_->transform_inits(inits_context, params_unc, &std::cerr);
  Eigen::VectorXd::Map(theta_unc, params_unc.size()) = params_unc;
}

int param_unconstrain_json(model_rng* mr, const char* json,
                            double* theta_unc) {
  try {
    param_unconstrain_json_impl(mr, json, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_unconstrain_json exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_unconstrain_json unknown exception" << std::endl;
  }
  return -1;
}

void log_density_impl(model_rng* mr, bool propto, bool jacobian,
		      const double* theta_unc, double* val) {
  auto logp
      = create_model_functor(mr->model_, propto, jacobian,
                             std::cerr);
  int N = param_unc_num(mr);
  Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
  if (propto) {
    // TODO(carpenter): avoid reverse pass for efficiency
    double lp;
    Eigen::VectorXd grad_vec(N);
    stan::math::gradient(logp, params_unc, lp, grad_vec);
    *val = lp;
    return;
  }
  *val = logp(params_unc.eval());
}

int log_density(model_rng* mr, bool propto, bool jacobian,
		const double* theta_unc, double* val) {
  try {
    log_density_impl(mr, propto, jacobian, theta_unc, val);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "log_density() exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "log_density() unknown exception" << std::endl;
  }
  return -1;
}

double log_density_gradient_impl(model_rng* mr, bool propto, bool jacobian,
				 const double* theta_unc, double* grad) {
  auto logp
      = create_model_functor(mr->model_, propto, jacobian,
                             std::cerr);
  int N = param_unc_num(mr);
  Eigen::VectorXd params_unc = Eigen::VectorXd::Map(theta_unc, N);
  double lp;
  Eigen::VectorXd grad_vec(N);
  stan::math::gradient(logp, params_unc, lp, grad_vec);
  Eigen::VectorXd::Map(grad, N) = grad_vec;
  return lp;
}


int log_density_gradient(model_rng* mr, bool propto, bool jacobian,
			  const double* theta_unc, double* val, double* grad) {
  try {
    *val = log_density_gradient_impl(mr, propto, jacobian, theta_unc, grad);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "exception in C++ log_density_gradient(): " << e.what()
	      << std::endl;
  } catch (...) {
    std::cerr << "unknown exception in C++ log_density_gradient()"
	      << std::endl;
  }
  return -1;
}

double log_density_hessian_impl(model_rng* mr, bool propto, bool jacobian,
				const double* theta_unc, double* grad,
				double* hessian) {
  auto logp
      = create_model_functor(mr->model_, propto, jacobian,
                             std::cerr);
  int N = param_unc_num(mr);
  Eigen::Map<const Eigen::VectorXd> params_unc(theta_unc, N);
  double lp;
  Eigen::VectorXd grad_vec;
  Eigen::MatrixXd hess_mat;
  stan::math::internal::finite_diff_hessian_auto(logp, params_unc, lp,
                                                 grad_vec, hess_mat);
  Eigen::VectorXd::Map(grad, N) = grad_vec;
  Eigen::MatrixXd::Map(hessian, N, N) = hess_mat;
  return lp;
}

int log_density_hessian(model_rng* mr, bool propto, bool jacobian,
			const double* theta_unc, double* val, double* grad,
			double* hessian) {
  try {
    *val = log_density_hessian_impl(mr, propto, jacobian, theta_unc, grad,
				    hessian);
    return 0;
  } catch (const std::exception & e) {
    std::cerr << "exception in C++ log_density_hessian(): " << e.what()
	      << std::endl;
  } catch (...) {
    std::cerr << "unknown exception in C++ log_density_hessian()" << std::endl;
  }
  return -1;
}
