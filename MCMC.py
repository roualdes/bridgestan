# copy and pasted from https://github.com/bob-carpenter/stan-model-server/blob/main/MCMC.py
import numpy as np


class Metropolis:
    def __init__(self, model, proposal_rng, init=[]):
        self._model = model
        self._dim = self._model.dims()
        self._q_rng = proposal_rng
        self._theta = init or np.random.normal(size=self._dim)
        self._log_p_theta = self._model.log_density(self._theta)

    def __iter__(self):
        return self

    def __next__(self):
        return self.sample()

    def sample(self):
        # does not include initial value as first draw
        theta_star = self._theta + self._q_rng()
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
        self._metric = metric_diag or np.ones(self._dim)
        self._theta = init or np.random.normal(size=self._dim)

    def __iter__(self):
        return self

    def __next__(self):
        return self.sample()

    def joint_logp(self, theta, rho):
        return self._model.log_density(theta) + 0.5 * np.dot(
            rho, np.multiply(self._metric, rho)
    )

    def leapfrog(self, theta, rho):
        # TODO(bob-carpenter): refactor to share non-initial and non-final updates
        for n in range(self._steps):
            lp, grad = self._model.log_density_gradient(theta)
            rho_mid = rho - 0.5 * self._stepsize * np.multiply(self._metric, grad)
            theta = theta + self._stepsize * rho_mid
            lp, grad = self._model.log_density_gradient(theta)
            rho = rho_mid - 0.5 * self._stepsize * np.multiply(self._metric, grad)
        return (theta, rho)

    def sample(self):
        rho = np.random.normal(size=self._dim)
        logp = self.joint_logp(self._theta, rho)
        theta_prop, rho_prop = self.leapfrog(self._theta, rho)
        logp_prop = self.joint_logp(theta_prop, rho_prop)
        if np.log(np.random.uniform()) < (logp - logp_prop):
          self._theta = theta_prop
          return self._theta, logp_prop
        return self._theta, logp
