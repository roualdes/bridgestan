#include "bridgestan.h"
#include "model_rng.cpp"
#include "bridgestanR.cpp"
#include "version.hpp"

int bs_major_version = BRIDGESTAN_MAJOR;
int bs_minor_version = BRIDGESTAN_MINOR;
int bs_patch_version = BRIDGESTAN_PATCH;

#include <sstream>

bs_model_rng* bs_construct(const char* data, unsigned int seed,
                           unsigned int chain_id, char** error_msg) {
  try {
    return new bs_model_rng(data, seed, chain_id);
  } catch (const std::exception& e) {
    if (error_msg) {
      std::stringstream error;
      error << "construct(" << data << ", " << seed << ", " << chain_id
            << ")"
            << " failed with exception: " << e.what() << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  } catch (...) {
    if (error_msg) {
      std::stringstream error;

      error << "construct(" << data << ", " << seed << ", " << chain_id
            << ")"
            << " failed with unknown exception" << std::endl;
      *error_msg = strdup(error.str().c_str());
    }
  }
  return nullptr;
}

void bs_destruct(bs_model_rng* mr) { delete (mr); }

void bs_free_error_msg(char* error_msg) { free(error_msg); }

const char* bs_name(const bs_model_rng* mr) { return mr->name(); }

const char* bs_model_info(const bs_model_rng* mr) { return mr->model_info(); }

const char* bs_param_names(const bs_model_rng* mr, bool include_tp,
                           bool include_gq) {
  return mr->param_names(include_tp, include_gq);
}

const char* bs_param_unc_names(const bs_model_rng* mr) {
  return mr->param_unc_names();
}

int bs_param_num(const bs_model_rng* mr, bool include_tp, bool include_gq) {
  return mr->param_num(include_tp, include_gq);
}

int bs_param_unc_num(const bs_model_rng* mr) { return mr->param_unc_num(); }

int bs_param_constrain(bs_model_rng* mr, bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta,
                       char** error_msg) {
  try {
    mr->param_constrain(include_tp, include_gq, theta_unc, theta);
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

int bs_param_unconstrain(const bs_model_rng* mr, const double* theta,
                         double* theta_unc, char** error_msg) {
  try {
    mr->param_unconstrain(theta, theta_unc);
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

int bs_param_unconstrain_json(const bs_model_rng* mr, const char* json,
                              double* theta_unc, char** error_msg) {
  try {
    mr->param_unconstrain_json(json, theta_unc);
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

int bs_log_density(const bs_model_rng* mr, bool propto, bool jacobian,
                   const double* theta_unc, double* val, char** error_msg) {
  try {
    mr->log_density(propto, jacobian, theta_unc, val);
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

int bs_log_density_gradient(const bs_model_rng* mr, bool propto, bool jacobian,
                            const double* theta_unc, double* val, double* grad,
                            char** error_msg) {
  try {
    mr->log_density_gradient(propto, jacobian, theta_unc, val, grad);
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

int bs_log_density_hessian(const bs_model_rng* mr, bool propto, bool jacobian,
                           const double* theta_unc, double* val, double* grad,
                           double* hessian, char** error_msg) {
  try {
    mr->log_density_hessian(propto, jacobian, theta_unc, val, grad, hessian);
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
