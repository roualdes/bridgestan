struct HMCDiag
    model::BridgeStan.StanModel
    stepsize::Float64
    steps::Int64
    metric::Vector{Float64}
    theta::Vector{Float64}
end

function HMCDiag(model, stepsize, steps)
    return HMCDiag(
        model,
        stepsize,
        steps,
        ones(BridgeStan.param_unc_num(model)),
        randn(BridgeStan.param_unc_num(model)),
    )
end

function joint_logp(hmc::HMCDiag, theta, rho)
    logp, _ = BridgeStan.log_density_gradient(hmc.model, theta)
    return logp - 0.5 * rho' * (hmc.metric .* rho)
end

function leapfrog(hmc::HMCDiag, theta, rho)
    e = hmc.stepsize .* hmc.metric
    lp, grad = BridgeStan.log_density_gradient(hmc.model, theta)
    rho_p = rho + 0.5 * hmc.stepsize .* grad
    for n = 1:hmc.steps
        theta .+= e .* rho_p
        lp, grad = BridgeStan.log_density_gradient(hmc.model, theta)
        if n != hmc.steps
            rho_p .+= e .* grad
        end
    end
    rho_p .+= 0.5 .* e .* grad
    return theta, rho_p
end

function sample(hmc::HMCDiag)
    rho = randn(BridgeStan.param_unc_num(model))
    logp = joint_logp(hmc, hmc.theta, rho)
    theta_prop, rho_prop = leapfrog(hmc, hmc.theta, rho)
    logp_prop = joint_logp(hmc, theta_prop, rho_prop)
    if log(rand()) < logp_prop - logp
        hmc.theta .= theta_prop
        return hmc.theta
    end
    return hmc.theta
end
