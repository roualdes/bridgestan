#include "bridgestan.h"
#include "model.hpp"
#include "rng.hpp"
#include "callback_stream.hpp"
#include "version.hpp"
#include "util.hpp"

#include "bridgestanR.cpp"

using bridgestan::handle_errors;

const int bs_major_version = BRIDGESTAN_MAJOR;
const int bs_minor_version = BRIDGESTAN_MINOR;
const int bs_patch_version = BRIDGESTAN_PATCH;

bs_model* bs_model_construct(const char* data, unsigned int seed,
                             char** error_msg) {
  return handle_errors("construct", error_msg,
                       [&]() { return new bs_model(data, seed); });
}

void bs_model_destruct(bs_model* m) { delete (m); }

void bs_free_error_msg(char* error_msg) { free(error_msg); }

const char* bs_name(const bs_model* m) { return m->name(); }

const char* bs_model_info(const bs_model* m) { return m->model_info(); }

const char* bs_param_names(const bs_model* m, bool include_tp,
                           bool include_gq) {
  return m->param_names(include_tp, include_gq);
}

const char* bs_param_unc_names(const bs_model* m) {
  return m->param_unc_names();
}

int bs_param_num(const bs_model* m, bool include_tp, bool include_gq) {
  return m->param_num(include_tp, include_gq);
}

int bs_param_unc_num(const bs_model* m) { return m->param_unc_num(); }

int bs_param_constrain(const bs_model* m, bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta, bs_rng* rng,
                       char** error_msg) {
  return handle_errors("param_constrain", error_msg, [&]() {
    if (rng == nullptr) {
      // If RNG is not provided (e.g., we are not using include_gq), use a dummy
      // RNG.
      // SAFETY: this can be static because we know the rng is never advanced.
      static stan::rng_t dummy_rng(0);

      if (include_gq)
        throw std::invalid_argument("include_gq=true but rng=nullptr");

      m->param_constrain(include_tp, include_gq, theta_unc, theta, dummy_rng);
    } else
      m->param_constrain(include_tp, include_gq, theta_unc, theta, rng->rng_);
    return 0;
  });
}

int bs_param_unconstrain(const bs_model* m, const double* theta,
                         double* theta_unc, char** error_msg) {
  return handle_errors("param_unconstrain", error_msg, [&]() {
    m->param_unconstrain(theta, theta_unc);
    return 0;
  });
}

int bs_param_unconstrain_json(const bs_model* m, const char* json,
                              double* theta_unc, char** error_msg) {
  return handle_errors("param_unconstrain_json", error_msg, [&]() {
    m->param_unconstrain_json(json, theta_unc);
    return 0;
  });
}

int bs_log_density(const bs_model* m, bool propto, bool jacobian,
                   const double* theta_unc, double* val, char** error_msg) {
  return handle_errors("log_density", error_msg, [&]() {
    m->log_density(propto, jacobian, theta_unc, val);
    return 0;
  });
}

int bs_log_density_gradient(const bs_model* m, bool propto, bool jacobian,
                            const double* theta_unc, double* val, double* grad,
                            char** error_msg) {
  return handle_errors("log_density_gradient", error_msg, [&]() {
    m->log_density_gradient(propto, jacobian, theta_unc, val, grad);
    return 0;
  });
}

int bs_log_density_hessian(const bs_model* m, bool propto, bool jacobian,
                           const double* theta_unc, double* val, double* grad,
                           double* hessian, char** error_msg) {
  return handle_errors("log_density_hessian", error_msg, [&]() {
    m->log_density_hessian(propto, jacobian, theta_unc, val, grad, hessian);
    return 0;
  });
}

int bs_log_density_hessian_vector_product(const bs_model* m, bool propto,
                                          bool jacobian,
                                          const double* theta_unc,
                                          const double* v, double* val,
                                          double* Hvp, char** error_msg) {
  return handle_errors("log_density_hessian_vector_product", error_msg, [&]() {
    m->log_density_hessian_vector_product(propto, jacobian, theta_unc, v, val,
                                          Hvp);
    return 0;
  });
}

bs_rng* bs_rng_construct(unsigned int seed, char** error_msg) {
  return handle_errors("construct_rng", error_msg,
                       [&]() { return new bs_rng(seed); });
}

void bs_rng_destruct(bs_rng* rng) { delete (rng); }

// global for Stan model output
// TODO(bmw): Next major version, move inside of the model object
std::ostream* outstream = &std::cout;

int bs_set_print_callback(STREAM_CALLBACK callback, char** error_msg) {
  return handle_errors("set_print_callback", error_msg, [&]() {
    std::ostream* old_outstream = outstream;

    if (callback == nullptr) {
      outstream = &std::cout;
    } else {
      outstream
          = new std::ostream(new bridgestan::callback_ostreambuf(callback));
    }
    if (old_outstream != &std::cout) {
      // clean up old memory
      std::streambuf* buf = old_outstream->rdbuf();
      delete old_outstream;
      delete buf;
    }
    return 0;
  });
}
