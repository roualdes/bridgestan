#ifndef MODEL_FUNCTOR_HPP
#define MODEL_FUNCTOR_HPP

#include <Eigen/Dense>
#include <ostream>

/**
 * Functor for a model of the specified template type and its log
 * density configuration in terms of dropping constants and/or the
 * change-of-variables adjustment.
 *
 * @tparam M type of model
 */
template <class M>
class model_functor {
 private:
  /** Stan model */
  const M& model_;

  /** `true` if including constant terms */
  const bool propto_;

  /** `true` if including change-of-variables terms */
  const bool jacobian_;

  /** Output stream for messages from Stan model */
  std::ostream& out_;

 public:
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
      : model_(m), propto_(propto), jacobian_(jacobian), out_(out) {}

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
    return propto_ ? (
               jacobian_
                   ? model_->template log_prob<true, true, T>(params_r, &out_)
                   : model_->template log_prob<true, false, T>(params_r, &out_))
                   : (jacobian_ ? model_->template log_prob<false, true, T>(
                          params_r, &out_)
                                : model_->template log_prob<false, false, T>(
                                    params_r, &out_));
  }
};

/**
 * Return an appropriately typed model functor from the specified
 * model, given the specified output stream and flags indicating
 * whether to drop constant terms and include change-of-variables
 * terms.  Unlike the `model_functor` constructor, this factory
 * function provides type inference for `M`.
 *
 * @tparam M type of Stan model
 * @param[in] m Stan model
 * @param[in] propto `true` if log density drops constant terms
 * @param[in] jacobian `true` if log density includes
 * change-of-variables terms
 * @param[in] out output stream for messages from model
 */
template <typename M>
model_functor<M> create_model_functor(const M& m, bool propto, bool jacobian,
                                      std::ostream& out) {
  return model_functor<M>(m, propto, jacobian, out);
}

#endif
