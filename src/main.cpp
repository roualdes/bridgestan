#include <cmdstan/io/json/json_data.hpp>
#include <stan/math.hpp>
#include <stan/io/empty_var_context.hpp>
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

stan::model::model_base& new_model(stan::io::var_context &data_context,
                                   unsigned int seed, std::ostream *msg_stream);

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

  model_functor(const M& m, bool propto, bool jacobian, std::ostream& out)
    : model_(m), propto_(propto), jacobian_(jacobian), out_(out) { }

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

  void destroy(stanmodel* sm_);
}

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

int get_num_unc_params(stanmodel* sm_) {
  bool include_generated_quantities = false;
  bool include_transformed_parameters = false;
  std::vector<std::string> names;

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->unconstrained_param_names(names, include_generated_quantities,
                                   include_transformed_parameters);
  return names.size();
}

int param_num(stanmodel* sm_) {
  bool include_transformed_parameters = false;
  bool include_generated_quantities = false;
  std::vector<std::string> names;

  stan::model::model_base* model = static_cast<stan::model::model_base*>(sm_->model_);
  model->constrained_param_names(names,
                                 include_transformed_parameters,
                                 include_generated_quantities);
  return names.size();
}

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

void param_unconstrain(stanmodel* sm_, int D_, double* params_, double* q_) {

}

void destroy(stanmodel* sm_) {
  if (sm_ == NULL) return;
  delete static_cast<stan::model::model_base*>(sm_->model_);
  delete sm_;
}
