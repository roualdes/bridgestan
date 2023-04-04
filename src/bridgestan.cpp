#include "bridgestan.h"
#include "model_rng.cpp"
#include "bridgestanR.cpp"
#include "version.hpp"

int bs_major_version = BRIDGESTAN_MAJOR;
int bs_minor_version = BRIDGESTAN_MINOR;
int bs_patch_version = BRIDGESTAN_PATCH;

#include <sstream>

bs_model* bs_construct(const char* data_file, unsigned int seed,
                       char** error_msg) {
  try {
    return new bs_model(data_file, seed);
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "construct(" << data_file << ", " << seed << ")"
            << " failed with exception: " << e.what() << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;

      error << "construct(" << data_file << ", " << seed << ")"
            << " failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return nullptr;
}

void bs_destruct(bs_model* m) { delete (m); }

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
  try {
    m->param_constrain(include_tp, include_gq, theta_unc, theta, rng->rng_);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "param_constrain() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "param_constrain() failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return 1;
}

int bs_param_constrain_seeded(const bs_model* m, bool include_tp,
                              bool include_gq, const double* theta_unc,
                              double* theta, unsigned int seed,
                              unsigned int chain_id, char** error_msg) {
  bs_rng rng(seed, chain_id);
  return bs_param_constrain(m, include_tp, include_gq, theta_unc, theta, &rng,
                            error_msg);
}

int bs_param_unconstrain(const bs_model* m, const double* theta,
                         double* theta_unc, char** error_msg) {
  try {
    m->param_unconstrain(theta, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "param_unconstrain() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "param_unconstrain() failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}

int bs_param_unconstrain_json(const bs_model* m, const char* json,
                              double* theta_unc, char** error_msg) {
  try {
    m->param_unconstrain_json(json, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "param_unconstrain_json() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "param_unconstrain_json() failed with unknown exception"
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}

int bs_log_density(const bs_model* m, bool propto, bool jacobian,
                   const double* theta_unc, double* val, char** error_msg) {
  try {
    m->log_density(propto, jacobian, theta_unc, val);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density() failed with exception: " << e.what() << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density() failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}

int bs_log_density_gradient(const bs_model* m, bool propto, bool jacobian,
                            const double* theta_unc, double* val, double* grad,
                            char** error_msg) {
  try {
    m->log_density_gradient(propto, jacobian, theta_unc, val, grad);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density_gradient() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density_gradient() failed with unknown exception"
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}

int bs_log_density_hessian(const bs_model* m, bool propto, bool jacobian,
                           const double* theta_unc, double* val, double* grad,
                           double* hessian, char** error_msg) {
  try {
    m->log_density_hessian(propto, jacobian, theta_unc, val, grad, hessian);
    return 0;
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density_hessian() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "log_density_hessian() failed with unknown exception"
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}

bs_rng* bs_construct_rng(unsigned int seed, unsigned int chain_id,
                         char** error_msg) {
  try {
    return new bs_rng(seed, chain_id);
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "construct_rng() failed with exception: " << e.what()
            << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "construct_rng() failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }

  return nullptr;
}

int bs_destruct_rng(bs_rng* mr, char** error_msg) {
  try {
    delete (mr);
    return 0;
  } catch (...) {
    if (error_msg) {
      std::stringstream error;
      error << "destruct_rng() failed." << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return -1;
}
