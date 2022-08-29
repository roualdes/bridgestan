import ctypes
import numpy as np
import numpy.typing as npt

from numpy.ctypeslib import ndpointer
from typing import Tuple, Optional

float_array = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))

__all__ = ["PyBridgeStan"]


class Bridge:
    def __init__(self, model_lib: str, model_data: str, seed: int = 204, chain_id: int = 0) -> None:
        """Construct Stan model interface and PRNG."""
        self.stanlib = ctypes.CDLL(model_lib)
        self.seed = seed
        self.chain_id = chain_id

        self._construct = self.stanlib.construct
        self._construct.restype = ctypes.c_void_p
        self._construct.argtypes = [ctypes.c_char_p, ctypes.c_uint, ctypes.c_uint]

        self.model_rng = self._construct(str.encode(model_data), self.seed, self.chain_id)

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
            double_array
        ]

        self._param_unc_num = self.stanlib.param_unc_num2
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        self._dims = self._param_unc_num(self.model_rng)  # redundant

        self._param_unconstrain = self.stanlib.param_unconstrain2
        self._param_unconstrain.restype = ctypes.c_void_p
        self._param_unconstrain.argtypes = [
            ctypes.c_void_p,
            double_array,
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
            double_array
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
        self, q: float_array, include_tp: int, include_gq: int, out: Optional[float_array] = None
    ) -> float_array:
        if out is not None:
            if out.size < self._dims:
                raise ValueError(
                    "Out parameter must be at least the number of "
                    f"constrained params: {self._K}"
                )
            constr_params = out
        else:
            constr_params = np.zeros(self.param_num(include_tp, include_gq))

        self._param_constrain(self.model_rng, include_tp, include_gq, q, constr_params)
        return constr_params

    def dims(self) -> int:
        """Number of unconstrained parameters"""
        return self._dims

    def param_unc_num(self) -> int:
        return self._param_unc_num(self.model_rng)

    def param_unconstrain(
        self,
        q: float_array,
        *,
        out: Optional[float_array] = None,
    ) -> float_array:
        if out is not None:
            if out.size < self._dims:
                raise ValueError(
                    f"Out parameter must be at least the size of dims: {self._dims}"
                )
            unc_params = out
        else:
            unc_params = np.zeros(shape=self._dims)

        self._param_unconstrain(self.model_rng, q, unc_params)
        return unc_params

    def log_density(
        self,
        q: float_array,
        propto: Optional[int] = 1,
        jacobian: Optional[int] = 1,
    ) -> float:
        return self._log_density_gradient(self.model_rng,
                                          int(propto), int(jacobian),
                                          q, self._gradient)

    def log_density_gradient(
        self,
        q: float_array,
        propto: Optional[int] = 1,
        jacobian: Optional[int] = 1,
        grad_out: Optional[float_array] = None,
    ) -> Tuple[float, float_array]:
        if grad_out is not None:
            if grad_out.size < self._dims:
                raise ValueError(
                    f"Out parameter must be at least the size of dims: {self._dims}"
                )
            gradient = grad_out
        else:
            gradient = np.zeros(shape=self._dims)

        logp = self._log_density_gradient(self.model_rng, int(propto), int(jacobian),
                                          q, gradient)
        return logp, gradient
