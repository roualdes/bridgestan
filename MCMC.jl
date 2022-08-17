struct HMCDiag
    model::JBS.StanModel
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
        ones(model.dims),
        randn(model.dims))
end

function joint_logp(hmc::HMCDiag, theta, rho)
    JBS.log_density_gradient!(hmc.model, theta)
    return hmc.model.log_density[1] - 0.5 * rho' * (hmc.metric .* rho)
end

function leapfrog(hmc::HMCDiag, theta, rho)
    e = hmc.stepsize .* hmc.metric
    JBS.log_density_gradient!(hmc.model, theta)
    lp = hmc.model.log_density[1]
    grad = hmc.model.gradient
    rho_p = rho + 0.5 * hmc.stepsize .* grad
    for n in 1:hmc.steps
        theta .+= e .* rho_p
        JBS.log_density_gradient!(hmc.model, theta)
        lp = hmc.model.log_density[1]
        grad = hmc.model.gradient
        if n != hmc.steps
            rho_p .+= e .* grad
        end
    end
    rho_p .+= 0.5 .* e .* grad
    return theta, rho_p
end

function sample(hmc::HMCDiag)
    rho = randn(hmc.model.dims)
    logp = joint_logp(hmc, hmc.theta, rho)
    theta_prop, rho_prop = leapfrog(hmc, hmc.theta, rho)
    logp_prop = joint_logp(hmc, theta_prop, rho_prop)
    if log(rand()) < logp_prop - logp
        hmc.theta .= theta_prop
        return hmc.theta
    end
    return hmc.theta
end
