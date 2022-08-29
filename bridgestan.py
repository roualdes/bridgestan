import ctypes
import numpy as np
import numpy.typing as npt

from numpy.ctypeslib import ndpointer
from typing import Tuple, Optional

float_array = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))

__all__ = ["PyBridgeStan"]


class Bridge:
    def __init__(
        self, model_lib: str, model_data: str, seed: int = 204, chain_id: int = 0
    ) -> None:
        """Construct Stan model interface and PRNG."""
        self.stanlib = ctypes.CDLL(model_lib)
        self.seed = seed
        self.chain_id = chain_id

        self._construct = self.stanlib.construct
        self._construct.restype = ctypes.c_void_p
        self._construct.argtypes = [ctypes.c_char_p, ctypes.c_uint, ctypes.c_uint]

        self.model_rng = self._construct(
            str.encode(model_data), self.seed, self.chain_id
        )

        self._param_num = self.stanlib.param_num2
        self._param_num.restype = ctypes.c_int
        self._param_num.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]

        self._K = self._param_num(self.model_rng, 0, 0)  # redundant

        self._param_constrain = self.stanlib.param_constrain2
        self._param_constrain.restype = ctypes.c_void_p
        self._param_constrain.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            double_array,
        ]

        self._param_unc_num = self.stanlib.param_unc_num2
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        self._dims = self._param_unc_num(self.model_rng)  # redundant

        self._param_unconstrain = self.stanlib.param_unconstrain2
        self._param_unconstrain.restype = ctypes.c_void_p
        self._param_unconstrain.argtypes = [ctypes.c_void_p, double_array, double_array]

        self._param_unconstrain_json = self.stanlib.param_unconstrain_json
        self._param_unconstrain_json.restype = ctypes.c_void_p
        self._param_unconstrain_json.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            double_array,
        ]

        self._log_density = np.zeros(shape=1)  # remove if possible
        self._gradient = np.zeros(shape=self._dims)  # remove if possible

        self._log_density_gradient = self.stanlib.log_density_gradient2
        self._log_density_gradient.restype = ctypes.c_double
        self._log_density_gradient.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            double_array,
        ]

        self._log_density_hessian = self.stanlib.log_density_hessian
        self._log_density_hessian.restype = ctypes.c_double
        self._log_density_hessian.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            double_array,
            double_array,
        ]

        self._destruct = self.stanlib.destruct
        self._destruct.restype = ctypes.c_void_p
        self._destruct.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """Destroy Stan model and free memory"""
        self._destruct(self.model_rng)

    def K(self) -> int:
        """Number of constrained parameters"""
        return self._K

    def param_num(self, include_tp: int = 0, include_gq: int = 0) -> int:
        return self._param_num(self.model_rng, include_tp, include_gq)

    def param_constrain(
        self,
        theta_unc: float_array,
        include_tp: int,
        include_gq: int,
        theta: Optional[float_array] = None,
    ) -> float_array:
        if theta is None:
            theta = np.zeros(self.param_num(include_tp, include_gq))
        elif theta.size != self._dims:
            raise ValueError(
                "Out parameter must be at least the number of "
                f"constrained params: {self._K}"
            )
        self._param_constrain(self.model_rng, include_tp, include_gq, theta_unc, theta)
        return theta

    def dims(self) -> int:
        """Number of unconstrained parameters"""
        return self._dims

    def param_unc_num(self) -> int:
        return self._param_unc_num(self.model_rng)

    def param_unconstrain_json(
        self, theta_json: str, theta_unc: Optional[float_array] = None
    ) -> float_array:
        if theta_unc is None:
            theta_unc = np.zeros(shape=self._dims)
        elif theta_unc.size != self._dims:
            raise ValueError(
                f"theta_unc size = {theta_unc.size} != dims size = {self._dims}"
            )
        chars = theta_json.encode("UTF-8")
        self._param_unconstrain_json(self.model_rng, chars, theta_unc)
        return theta_unc

    def param_unconstrain(
        self, theta: float_array, theta_unc: Optional[float_array] = None
    ) -> float_array:
        if theta_unc is None:
            theta_unc = np.zeros(shape=self._dims)
        elif theta_unc.size != self._dims:
            raise ValueError(
                f"theta_unc size = {theta_unc.size} != dims size = {self._dims}"
            )
        self._param_unconstrain(self.model_rng, theta, theta_unc)
        return theta_unc

    def log_density(
        self, theta_unc: float_array, propto: int = 1, jacobian: int = 1
    ) -> float:
        return self._log_density_gradient(
            self.model_rng, int(propto), int(jacobian), theta_unc, self._gradient
        )

    def log_density_gradient(
        self,
        theta_unc: float_array,
        propto: int = 1,
        jacobian: int = 1,
        grad: Optional[float_array] = None,
    ) -> Tuple[float, float_array]:
        if grad is None:
            grad = np.zeros(shape=self._dims)
        elif grad.size != self._dims:
            raise ValueError(f"grad size = {grad.size} != dims size = {self._dims}")
        logp = self._log_density_gradient(
            self.model_rng, int(propto), int(jacobian), theta_unc, grad
        )
        return logp, grad

    def log_density_hessian(
        self,
        theta_unc: float_array,
        propto: int = 1,
        jacobian: int = 1,
        grad: Optional[float_array] = None,
        hess: Optional[float_array] = None,
    ) -> Tuple[float, float_array]:
        if grad is None:
            grad = np.zeros(shape=self._dims)
        elif grad.size != self._dims:
            raise ValueError(f"grad size = {grad.size} != dims size = {self._dims}")
        hess_size = self._dims * self._dims
        if hess is None:
            hess = np.zeros(shape=hess_size)
        elif hess.size != self._dims * self._dims:
            raise ValueError(f"hess size = {hess.size} != dims size^2 = {hess_size}")
        logp = self._log_density_hessian(
            self.model_rng, int(propto), int(jacobian), theta_unc, grad, hess
        )
        hess = hess.reshape(self._dims, self._dims)
        return logp, grad, hess


    # def log_density_hessian(
    #     self,
    #     theta_unc: float_array,
    #     propto: int = 1,
    #     jacobian: int = 1,
    #     grad: Optional[float_array] = None,
    #     hess: Optional[float_array] = None,
    # ) -> Tuple[float, float_array]:
    #     if grad is None:
    #         grad = np.zeros(shape=self._dims, dtype=np.float64)
    #     elif grad.size != self._dims:
    #         raise ValueError(f"grad size = {grad.size} != dims size = {self._dims}")
    #     hess_size = self._dims * self._dims
    #     if hess is None:
    #         hess = np.zeros(shape=self._dims * self._dims, dtype=np.float64)
    #     elif hess.size != hess_size:
    #         raise ValueError(
    #             f"hess size = {hess.size} != dims size squared = {hess_size}"
    #         )
    #     print("hess=", hess)
    #     logp = self._log_density_gradient(self.model_rng, int(propto), int(jacobian), theta_unc, grad)

    #     # logp = self._log_density_hessian(
    #     # self.model_rng, int(propto), int(jacobian), theta_unc, grad, hess
    #     # )
    #     hess.reshape(self._dims, self._dims)
    #     return logp, grad, hess
