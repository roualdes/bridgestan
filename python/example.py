
# REQUIRED IMPORTS
import bridgestan as bs
import numpy as np

# COMPILE AND CONSTRUCT MODEL
stan = "../test_models/regression/regression.stan"
data = "../test_models/regression/regression.data.json"
model = bs.StanModel.from_stan_file(stan, data)

print("MODEL NAME: name")
name = model.name()
print(f"model name = {name}\n")

print("NUMBER OF PARAMETERS: param_num")
for tp in [True, False]:
    for gq in [True, False]:
        D = model.param_num(include_tp=tp, include_gq=gq)
        print(f"tp = {tp:b}, gq = {gq:b}, number of parameters = {D}\n")

print("PARAMETER NAMES: param_names")
for tp in [True, False]:
    for gq in [True, False]:
        names = model.param_names(include_tp=tp, include_gq=gq)
        print(f"tp = {tp:b}, gq = {gq:b}, parameter names = {names}\n")

print("NUMBER OF UNCONSTRAINED PARAMETERS: param_unc_num")
D = model.param_unc_num()
print(f"number of unconstrained paramerers = {D}\n")

print("UNCONSTRAINED PARAMETER NAMES: param_unc_names")
names = model.param_unc_names()
print(f"unconstrained parameter names = {names}\n")

print("SET UNCONSTRAINED PARAMETERS TO TEST")
alpha = 0.2
beta = 0.9
log_sigma = np.log(0.25)
theta_unc = np.array([alpha, beta, log_sigma])
print(f"theta_unc = {theta_unc}\n")

print("LOG DENSITY: log_density")
for propto in [True, False]:
    for jacobian in [True, False]:
        log_p = model.log_density(theta_unc, propto=propto, jacobian=jacobian)
        print(f"propto = {propto:b}, jacobian = {jacobian:b}, log density = {log_p}\n")

print("LOG DENSITY & GRADIENT: log_density_gradient")
for propto in [True, False]:
    for jacobian in [True, False]:
        log_p, grad = model.log_density_gradient(
            theta_unc, propto=propto, jacobian=jacobian
        )
        print(f"propto = {propto:b}; jacobian = {jacobian:b}; log density = {log_p}")
        print(f"  gradient = {grad}\n")

print("LOG DENSITY & GRADIENT & HESSIAN: log_density_hessian")
for propto in [True, False]:
    for jacobian in [True, False]:
        log_p, grad, hess = model.log_density_hessian(
            theta_unc, propto=propto, jacobian=jacobian
        )
        print(f"propto = {propto:b}; jacobian = {jacobian:b}; log density = {log_p}")
        print(f"  gradient = {grad}")
        print(f"  hessian = {hess}\n")

print(
    "CONSTRAINING TRANSFORM & TRANSFORMED PARAMETERS & GENERATED QUANTITIES: param_constrain"
)
for tp in [True, False]:
    for gq in [True, False]:
        # each eval generates random generated quantities
        theta = model.param_constrain(theta_unc, include_tp=tp, include_gq=gq)
        print(f"tp = {tp:b}, gq = {gq:b}, params = {theta}\n")

print("UNCONSTRAINING TRANSFORM: param_unconstrain")
theta = model.param_constrain(theta_unc, include_tp=False, include_gq=False)
theta_unc_roundtrip = model.param_unconstrain(theta)
print(f"unconstrained parameters = {theta_unc_roundtrip}\n")

print("UNCONSTRAINING TRANSFORM FROM JSON: param_unconstrain_json")
theta_json = '{ "alpha": 0.2, "beta": 0.9, "sigma": 0.25 }'
theta_unc_roundtrip_json = model.param_unconstrain_json(theta_json)
print(f"unconstrained parameters from JSON = {theta_unc_roundtrip_json}\n")
