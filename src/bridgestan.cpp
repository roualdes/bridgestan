#include "bridgestan.h"
#include "model_rng.cpp"
#include "bridgestanR.cpp"

bs_model_rng* bs_construct(char* data_file, unsigned int seed,
                           unsigned int chain_id) {
  try {
    return new bs_model_rng(data_file, seed, chain_id);
  } catch (const std::exception& e) {
    std::cerr << "construct(" << data_file << ", " << seed << ", " << chain_id
              << ")"
              << " failed with exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "construct(" << data_file << ", " << seed << ", " << chain_id
              << ")"
              << " failed with unknown exception" << std::endl;
  }
  return nullptr;
}

int bs_destruct(bs_model_rng* mr) {
  try {
    delete (mr);
    return 0;
  } catch (...) {
    std::cerr << "destruct() failed." << std::endl;
  }
  return -1;
}

const char* bs_name(bs_model_rng* mr) { return mr->name(); }

const char* bs_model_info(bs_model_rng* mr) { return mr->model_info(); }

const char* bs_param_names(bs_model_rng* mr, bool include_tp, bool include_gq) {
  return mr->param_names(include_tp, include_gq);
}

const char* bs_param_unc_names(bs_model_rng* mr) {
  return mr->param_unc_names();
}

int bs_param_num(bs_model_rng* mr, bool include_tp, bool include_gq) {
  return mr->param_num(include_tp, include_gq);
}

int bs_param_unc_num(bs_model_rng* mr) { return mr->param_unc_num(); }

int bs_param_constrain(bs_model_rng* mr, bool include_tp, bool include_gq,
                       const double* theta_unc, double* theta) {
  try {
    mr->param_constrain(include_tp, include_gq, theta_unc, theta);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_constrain() exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_constrain() unknown exception" << std::endl;
  }
  return 1;
}

int bs_param_unconstrain(bs_model_rng* mr, const double* theta,
                         double* theta_unc) {
  try {
    mr->param_unconstrain(theta, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_unconstrain exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_unconstrain unknown exception" << std::endl;
  }
  return -1;
}

int bs_param_unconstrain_json(bs_model_rng* mr, const char* json,
                              double* theta_unc) {
  try {
    mr->param_unconstrain_json(json, theta_unc);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "param_unconstrain_json exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "param_unconstrain_json unknown exception" << std::endl;
  }
  return -1;
}

int bs_log_density(bs_model_rng* mr, bool propto, bool jacobian,
                   const double* theta_unc, double* val) {
  try {
    mr->log_density(propto, jacobian, theta_unc, val);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "log_density() exception: " << e.what() << std::endl;
  } catch (...) {
    std::cerr << "log_density() unknown exception" << std::endl;
  }
  return -1;
}

int bs_log_density_gradient(bs_model_rng* mr, bool propto, bool jacobian,
                            const double* theta_unc, double* val,
                            double* grad) {
  try {
    mr->log_density_gradient(propto, jacobian, theta_unc, val, grad);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "exception in C++ log_density_gradient(): " << e.what()
              << std::endl;
  } catch (...) {
    std::cerr << "unknown exception in C++ log_density_gradient()" << std::endl;
  }
  return -1;
}

int bs_log_density_hessian(bs_model_rng* mr, bool propto, bool jacobian,
                           const double* theta_unc, double* val, double* grad,
                           double* hessian) {
  try {
    mr->log_density_hessian(propto, jacobian, theta_unc, val, grad, hessian);
    return 0;
  } catch (const std::exception& e) {
    std::cerr << "exception in C++ log_density_hessian(): " << e.what()
              << std::endl;
  } catch (...) {
    std::cerr << "unknown exception in C++ log_density_hessian()" << std::endl;
  }
  return -1;
}
