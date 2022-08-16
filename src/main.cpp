#include <cmdstan/io/json/json_data.hpp>
#include <stan/math.hpp>
#include <stan/io/empty_var_context.hpp>
#include <stan/io/array_var_context.hpp>
#include <stan/model/model_base.hpp>

#include <algorithm>
#include <exception>
#include <cmath>
#include <vector>
#include <string>
#include <stdexcept>
#include <fstream>
#include <iostream>
#include <sstream>

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

/**
 * Functor for a model of the specified template type and its log
 * density configuration in terms of dropping constants and/or the
 * change-of-variables adjustment.
 *
 * @tparam M type of model
 */
template <class M>
struct model_functor {
  /** Stan model */
  const M& model_;

  /** `true` if including constant terms */
  const bool propto_;

  /** `true` if including change-of-variables terms */
  const bool jacobian_;

  /** Output stream for messages from Stan model */
  std::ostream& out_;

  /**
   * Construct a model functor from the specified model, output
   * stream, and specification of whether constants should be dropped
   * and whether the change-of-variables terms should be dropped.
   *
   * @param[in] m Stan model
   * @param[in] propto `true` if log density drops constant terms
   * @param[in] jacobian `true` if log density includes change-of-variables
   * terms
   * @param[in] out output stream for messages from model
   */
  model_functor(const M& m, bool propto, bool jacobian, std::ostream& out)
    : model_(m), propto_(propto), jacobian_(jacobian), out_(out) { }

  /**
   * Return the log density for the specified unconstrained
   * parameters, including normalizing terms and change-of-variables
   * terms as specified in the constructor.
   *
   * @tparam T real scalar type for the arguments and return
   * @param theta unconstrained parameters
   * @throw std::exception if model throws exception evaluating log density
   */
  template <typename T>
  T operator()(const Eigen::Matrix<T, Eigen::Dynamic, 1>& theta) const {
    // const cast is safe---theta not modified
    auto params_r = const_cast<Eigen::Matrix<T, Eigen::Dynamic, 1>&>(theta);
    return propto_
      ? (jacobian_
         ? model_->template log_prob<true, true, T>(params_r, &out_)
         : model_->template log_prob<true, false, T>(params_r, &out_))
      : (jacobian_
         ? model_->template log_prob<false, true, T>(params_r, &out_)
         : model_->template log_prob<false, false, T>(params_r, &out_));
  }
};

/**
 * Return an appropriately typed model functor from the specified model, given
 * the specified output stream and flags indicating whether to drop constant
 * terms and include change-of-variables terms.  Unlike the `model_functor`
 * constructor, this factory function provides type inference for `M`.
 *
 * @tparam M type of Stan model
 * @param[in] m Stan model
 * @param[in] propto `true` if log density drops constant terms
 * @param[in] jacobian `true` if log density includes change-of-variables terms
 * @param[in] out output stream for messages from model
 */
template <typename M>
model_functor<M> create_model_functor(const M& m, bool propto, bool jacobian,
                                      std::ostream& out) {
  return model_functor<M>(m, propto, jacobian, out);
}

struct stanmodel_struct;
typedef struct stanmodel_struct stanmodel;

extern "C" {

  struct stanmodel_struct {
    void* model_;
    boost::ecuyer1988 base_rng_;
  };

  stanmodel* create(char* data_file_path_, unsigned int seed_);

  void log_density_gradient(stanmodel* sm_, int D_, double* q_, double* log_density_, double* grad_, int propto_, int jacobian_);

  int get_num_unc_params(stanmodel* sm_);

  int param_num(stanmodel* sm_);

  void param_constrain(stanmodel* sm_, int D_, double* q_, int K_, double* params_);

  int param_unc_num(stanmodel* sm_);

  void param_unconstrain(stanmodel* sm_, int D_, double* q_, int K_, double* unc_params_);

  void destroy(stanmodel* sm_);
}

/**
 * Create and return a pointer to a Stan model struct using specified data and seed.
 *
 * @param[in] sm_ Stan model
 * @param[in] data_file_path_ path at which data for model is found
 * @param[in] seed_ seed to initialize base rng
 * @return pointer to Stan model struct
 */
stanmodel* create(char* data_file_path_, unsigned int seed_) {
  stanmodel* sm = new stanmodel();
  std::string data_file_path(data_file_path_);

  if (data_file_path == "") {
    stan::io::empty_var_context empty_data;
    sm->model_ = &new_model(empty_data, seed_, &std::cerr);
  } else {
    std::ifstream in(data_file_path);
    if (!in.good())
      throw std::runtime_error("Cannot read input file: " + data_file_path);
    cmdstan::json::json_data data(in);
    in.close();
    sm->model_ = &new_model(data, seed_, &std::cerr);
    boost::ecuyer1988 rng(seed_);
    sm->base_rng_ = rng;
    sm->base_rng_.discard(1000000000000L);
  }

  return sm;
}

/**
 * Compute the log density and gradient of the underlying Stan model.
 *
 * @param[in] sm_ Stan model
 * @param[in] D_ number of unconstrained parameters
 * @param[in] q_ pointer to unconstrained parameters
 * @param[out] log_density_ pointer to log density
 * @param[out] grad_ pointer to gradient
 * @param[in] propto_ `true` if log density drops constant terms
 * @param[in] jacobian_ `true` if log density includes change-of-variables terms
 * @return number of unconstrained parameters
 */
void log_density_gradient(stanmodel* sm_, int D_, double* q_, double* log_density_, double* grad_, int propto_, int jacobian_) {
  const Eigen::Map<Eigen::VectorXd> params_unc(q_, D_);
  Eigen::VectorXd grad(D_);
  std::ostream& err_ = std::cout;

  static thread_local stan::math::ChainableStack thread_instance;
  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  auto model_functor = create_model_functor(model, propto_, jacobian_, err_);
  stan::math::gradient(model_functor, params_unc, *log_density_, grad);

  for (Eigen::VectorXd::Index d = 0; d < D_; ++d) {
    grad_[d] = grad(d);
  }
}

/**
 * Return the number of unconstrained parameters.
 *
 * TODO deprecate this function in favor of param_unc_num()
 *
 * @param[in] sm_ Stan model
 * @return number of unconstrained parameters
 */
int get_num_unc_params(stanmodel* sm_) {
  bool include_generated_quantities = false;
  bool include_transformed_parameters = false;
  std::vector<std::string> names;

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->unconstrained_param_names(names, include_generated_quantities,
                                   include_transformed_parameters);
  return names.size();
}

/**
 * Return the names of the constrained parameters.
 *
 * @param[in] sm_ Stan model
 * @return vector of the names of the constrained parameters
 */
// TODO do we need this to return into Python/Julia?
std::vector<std::string> param_names_(stanmodel* sm_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::vector<std::string> names;

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->constrained_param_names(names,
                                 include_transformed_parameters,
                                 include_generated_quantities);
  return names;
}

/**
 * Return the number of constrained parameters.
 *
 * @param[in] sm_ Stan model
 * @return number of constrained parameters
 */
int param_num(stanmodel* sm_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::vector<std::string> names = param_names_(sm_);
  return names.size();
}

/**
 * Transform unconstrained parameters into constrained parameters.  The
 * constrained and unconstrained parameters need not have the same length.
 *
 * @param[in] sm_ Stan model
 * @param[in] D_ number of unconstrained parameters
 * @param[in] q_ pointer to unconstrained parameters
 * @param[in] K_ number of constrained parameters
 * @param[out] params_ pointer to constrained parameters
 */
void param_constrain(stanmodel* sm_, int D_, double* q_, int K_, double* params_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::ostream& err_ = std::cout;

  Eigen::VectorXd params_unc(D_);
  for (Eigen::VectorXd::Index d = 0; d < D_; ++d) {
    params_unc(d) = q_[d];
  }

  Eigen::VectorXd params;
  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->write_array(sm_->base_rng_, params_unc, params,
                     include_transformed_parameters,
                     include_generated_quantities,
                     &err_);

  for (Eigen::VectorXd::Index k = 0; k < K_; ++k) {
    params_[k] = params(k);
  }
}

/**
 * Return the names of the unconstrained parameters.
 *
 * @param[in] sm_ Stan model
 * @return vector of the names of the unconstrained parameters
 */
// TODO do we need this to return into Python/Julia?
std::vector<std::string> param_unc_names_(stanmodel* sm_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::vector<std::string> names;

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->unconstrained_param_names(names,
                                   include_transformed_parameters,
                                   include_generated_quantities);
  return names;
}

/**
 * Return the number of unconstrained parameters.
 *
 * @param[in] sm_ Stan model
 * @return number of unconstrained parameters
 */
int param_unc_num(stanmodel* sm_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::vector<std::string> names = param_unc_names_(sm_);
  return names.size();
}

/**
 * Transform constrained parameters into unconstrained parameters.  The
 * constrained and unconstrained parameters need not have the same length.
 *
 // TODO Which means I don't know where the input argument is coming from, Python?  or
 // the output of param_constrain.
 *
 * @param[in] sm_ Stan model
 * @param[in] K_ number of constrained parameters
 * @param[in] q_ pointer to constrained parameters
 * @param[in] D_ number of unconstrained parameters
 * @param[out] unc_params_ pointer to unconstrained parameters
 */
void param_unconstrain(stanmodel* sm_, int K_, double* q_, int D_, double* unc_params_) {

  std::vector<std::string> indexed_names = param_names_(sm_);

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);

  std::vector<std::string> base_names;
  model->get_param_names(base_names);

  std::vector<std::vector<size_t>> base_dims;
  model->get_dims(base_dims);

  // Stan's model class does not have the means to return
  // unindexed parameter names which exclude
  // generated quantities and transformed parameter names
  // nor dims
  std::vector<std::string> names;
  std::vector<std::vector<size_t>> dims;

  for (int b = 0; b < base_names.size(); ++b) {

    std::string bname = base_names[b];

    for (int i = 0; i < indexed_names.size(); ++i) {

      std::string iname = indexed_names[i];
      bool found = iname.find(bname) != std::string::npos;

      if (found) {
        names.push_back(bname);
        dims.push_back(base_dims[b]);
        break;
      }
    }
  }

  Eigen::VectorXd params_unc(K_);
  for (Eigen::VectorXd::Index k = 0; k < K_; ++k) {
    params_unc(k) = q_[k];
  }

  stan::io::array_var_context avc(names, params_unc, dims);

  Eigen::VectorXd unc_params;
  std::ostream& err_ = std::cout;
  model->transform_inits(avc, unc_params, &err_);

  for (Eigen::VectorXd::Index d = 0; d < D_; ++d) {
    unc_params_[d] = unc_params(d);
  }
}

/**
 * Destroy Stan model struct and free appropriate memory.
 *
 * @param[in] sm_ Stan model
 */
void destroy(stanmodel* sm_) {
  if (sm_ == NULL) return;
  delete static_cast<stan::model::model_base*>(sm_->model_);
  delete sm_;
}
