import ctypes
import numpy as np
import numpy.typing as npt

from numpy.ctypeslib import ndpointer
from typing import Tuple, Optional

FloatArray = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))

__all__ = ["PyBridgeStan"]


class PyBridgeStan:
    def __init__(self, model_lib: str, model_data: str, seed: int = 204) -> None:
        """Create Stan Model thingy."""
        self.stanlib = ctypes.CDLL(model_lib)
        self.seed = seed

        self._create = self.stanlib.create
        self._create.restype = ctypes.c_void_p
        self._create.argtpyes = [ctypes.c_char_p, ctypes.c_uint]

        self.stanmodel = self._create(str.encode(model_data), self.seed)

        self._param_num = self.stanlib.param_num
        self._param_num.restype = ctypes.c_int
        self._param_num.argtypes = [ctypes.c_void_p]

        self._K = self._param_num(self.stanmodel)

        self._param_constrain = self.stanlib.param_constrain
        self._param_constrain.restype = ctypes.c_void_p
        self._param_constrain.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            double_array,
            ctypes.c_int,
            double_array,
        ]

        self._param_unc_num = self.stanlib.param_unc_num
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        self._dims = self._param_unc_num(self.stanmodel)

        self._param_unconstrain = self.stanlib.param_unconstrain
        self._param_unconstrain.restype = ctypes.c_void_p
        self._param_unconstrain.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            double_array,
            ctypes.c_int,
            double_array,
        ]

        self._log_density = np.zeros(shape=1)
        self._gradient = np.zeros(shape=self._dims)

        self._log_density_gradient = self.stanlib.log_density_gradient
        self._log_density_gradient.restype = ctypes.c_void_p
        self._log_density_gradient.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            double_array,
            double_array,
            double_array,
            ctypes.c_int,
            ctypes.c_int,
        ]

        self._destroy = self.stanlib.destroy
        self._destroy.restype = ctypes.c_void_p
        self._destroy.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """Destroy Stan model and free memory"""
        self._destroy(self.stanmodel)

    def K(self) -> int:
        """Number of constrained parameters"""
        return self._K

    def param_num(self) -> int:
        return self._param_num(self.stanmodel)

    def param_constrain(
        self, q: FloatArray, *, out: Optional[FloatArray] = None
    ) -> FloatArray:
        if out is not None:
            if out.size < self._dims:
                raise ValueError(
                    "Out parameter must be at least the number of "
                    f"constrained params: {self._K}"
                )
            constr_params = out
        else:
            constr_params = np.zeros(shape=self._K)

        self._param_constrain(
            self.stanmodel,
            self._dims,
            q,
            self._K,
            constr_params,
        )
        return constr_params

    def dims(self) -> int:
        """Number of unconstrained parameters"""
        return self._dims

    def param_unc_num(self) -> int:
        return self._param_unc_num(self.stanmodel)

    def param_unconstrain(
        self,
        q: FloatArray,
        *,
        out: Optional[FloatArray] = None,
    ) -> FloatArray:
        if out is not None:
            if out.size < self._dims:
                raise ValueError(
                    f"Out parameter must be at least the size of dims: {self._dims}"
                )
            unc_params = out
        else:
            unc_params = np.zeros(shape=self._dims)

        self._param_unconstrain(self.stanmodel, self._K, q, self._dims, unc_params)
        return unc_params

    def log_density(
        self,
        q: FloatArray,
        propto: Optional[int] = 1,
        jacobian: Optional[int] = 1,
    ) -> float:
        self._log_density_gradient(
            self.stanmodel,
            self._dims,
            q,
            self._log_density,
            self._gradient,
            int(propto),
            int(jacobian),
        )
        return self._log_density[0]

    def log_density_gradient(
        self,
        q: FloatArray,
        propto: Optional[int] = 1,
        jacobian: Optional[int] = 1,
        *,
        grad_out: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray]:
        if grad_out is not None:
            if grad_out.size < self._dims:
                raise ValueError(
                    f"Out parameter must be at least the size of dims: {self._dims}"
                )
            gradient = grad_out
        else:
            gradient = np.zeros(shape=self._dims)

        self._log_density_gradient(
            self.stanmodel,
            self._dims,
            q,
            self._log_density,
            gradient,
            int(propto),
            int(jacobian),
        )
        return self._log_density[0], gradient
