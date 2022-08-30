import ctypes
import numpy as np
import numpy.typing as npt

from numpy.ctypeslib import ndpointer
from typing import List, Optional, Tuple

FloatArray = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))

__all__ = ["Bridge"]

class Bridge:
    def __init__(
        self, model_lib: str, model_data: str, *, seed: int = 1234, chain_id: int = 0
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
        if not self.model_rng:
            raise ValueError("could not construct model RNG")

        self._param_num = self.stanlib.param_num2
        self._param_num.restype = ctypes.c_int
        self._param_num.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]

        self._param_unc_num = self.stanlib.param_unc_num2
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        self._param_names = self.stanlib.param_names
        self._param_names.restype = ctypes.c_char_p
        self._param_names.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
        ]

        self._param_unc_names = self.stanlib.param_unc_names
        self._param_unc_names.restype = ctypes.c_char_p
        self._param_unc_names.argtypes = [ctypes.c_void_p]

        self._param_constrain = self.stanlib.param_constrain2
        self._param_constrain.restype = int
        self._param_constrain.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            double_array,
        ]

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
        self._destruct.restype = int
        self._destruct.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """Destroy Stan model and free memory"""
        self._destruct(self.model_rng)

    def param_num(self, *, include_tp: bool = False, include_gq: bool = False) -> int:
        return self._param_num(self.model_rng, int(include_tp), int(include_gq))

    def param_unc_num(self) -> int:
        return self._param_unc_num(self.model_rng)

    def param_names(self, *, include_tp: bool = False, include_gq: bool = False) -> List[str]:
        return self._param_names(self.model_rng, int(include_tp), int(include_gq)).decode('utf-8').split(',')

    def param_unc_names(self) -> List[str]:
        return self._param_unc_names(self.model_rng).decode('utf-8').split(',')

    def param_constrain(
        self,
        theta_unc: FloatArray,
        *,
        include_tp: bool,
        include_gq: bool,
        theta: Optional[FloatArray] = None,
    ) -> FloatArray:
        dims = self.param_num(include_tp = include_tp, include_gq = include_gq)
        if theta is None:
            theta = np.zeros(dims)
        elif theta.size != dims:
            raise ValueError(
                "Out parameter must be same size as the number of "
                f"constrained params: {dims}"
            )
        rc = self._param_constrain(self.model_rng, int(include_tp), int(include_gq), theta_unc, theta)
        if rc:
            raise ValueError("param_constrain failed on C++ side; see stderr for messages")
        return theta

    def param_unconstrain(
        self, theta: FloatArray, theta_unc: Optional[FloatArray] = None
    ) -> FloatArray:
        dims = self.param_unc_num()
        if theta_unc is None:
            theta_unc = np.zeros(shape=dims)
        elif theta_unc.size != dims:
            raise ValueError(
                f"theta_unc size = {theta_unc.size} != dims size = {dims}"
            )
        self._param_unconstrain(self.model_rng, theta, theta_unc)
        return theta_unc

    def param_unconstrain_json(
        self, theta_json: str, theta_unc: Optional[FloatArray] = None
    ) -> FloatArray:
        dims = self.param_unc_num()
        if theta_unc is None:
            theta_unc = np.zeros(shape=dims)
        elif theta_unc.size != dims:
            raise ValueError(
                f"theta_unc size = {theta_unc.size} != dims size = {dims}"
            )
        chars = theta_json.encode("UTF-8")
        self._param_unconstrain_json(self.model_rng, chars, theta_unc)
        return theta_unc

    def log_density(
        self, theta_unc: FloatArray, *, propto: bool = True, jacobian: bool = True,
    ) -> float:
        return self._log_density(
            self.model_rng, int(propto), int(jacobian), theta_unc
        )

    def log_density_gradient(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        grad: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray]:
        dims = self.param_unc_num()
        if grad is None:
            grad = np.zeros(shape=dims)
        elif grad.size != dims:
            raise ValueError(f"grad size = {grad.size} != dims size = {dims}")
        logp = self._log_density_gradient(
            self.model_rng, int(propto), int(jacobian), theta_unc, grad
        )
        return logp, grad

    def log_density_hessian(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        grad: Optional[FloatArray] = None,
        hess: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray, FloatArray]:
        dims = self.param_unc_num()
        if grad is None:
            grad = np.zeros(shape=dims)
        elif grad.size != dims:
            raise ValueError(f"grad size = {grad.size} != dims size = dims")
        hess_size = dims * dims
        if hess is None:
            hess = np.zeros(shape=hess_size)
        elif hess.size != hess_size:
            raise ValueError(f"hess size = {hess.size} != dims size^2 = {hess_size}")
        logp = self._log_density_hessian(
            self.model_rng, int(propto), int(jacobian), theta_unc, grad, hess
        )
        hess = hess.reshape(dims, dims)
        return logp, grad, hess
