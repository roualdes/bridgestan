import numpy as np

class Metropolis:
    def __init__(self, model, init=None):
        self._model = model
        self._dim = self._model.dims()
        self._theta = init if init is not None else np.random.normal(size=self._dim)
        self._log_p_theta = self._model.log_density(self._theta)

    def sample(self):
        theta_star = self._theta + np.random.normal(size = self._dim)
        log_p_theta_star = self._model.log_density(theta_star)
        if np.log(np.random.uniform()) < log_p_theta_star - self._log_p_theta:
            self._theta = theta_star
            self._log_p_theta = log_p_theta_star
        return self._theta, self._log_p_theta


class HMCDiag:
    def __init__(
        self, model, stepsize, steps, metric_diag=None, init=None
    ):
        self._model = model
        self._dim = self._model.dims()
        self._stepsize = stepsize
        self._steps = steps
        self._metric = metric_diag if metric_diag is not None else np.ones(self._dim)
        self._theta = init if init is not None else np.random.normal(size = self._dim)

    def joint_logp(self, theta, rho):
        return self._model.log_density(theta) - 0.5 * np.dot(
            rho, np.multiply(self._metric, rho))

    def leapfrog(self, theta, rho):
        e = self._stepsize * self._metric
        lp, grad = self._model.log_density_gradient(theta)
        rho_p = rho + 0.5 * self._stepsize * grad
        for n in range(1, self._steps + 1):
            theta += e * rho_p
            lp, grad = self._model.log_density_gradient(theta)
            if n != self._steps:
                rho_p += e * grad
        rho_p += 0.5 * e * grad
        return theta, rho_p

    def sample(self):
        rho = np.random.normal(size = self._dim)
        logp = self.joint_logp(self._theta, rho)
        theta_prop, rho_prop = self.leapfrog(self._theta, rho)
        logp_prop = self.joint_logp(theta_prop, rho_prop)
        if np.log(np.random.uniform()) < logp_prop - logp:
          self._theta = theta_prop
          return self._theta
        return self._theta
