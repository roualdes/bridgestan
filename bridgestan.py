import ctypes
import numpy as np
import numpy.typing as npt
import os

from numpy.ctypeslib import ndpointer
from typing import List, Optional, Tuple

FloatArray = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))

__all__ = ["Bridge"]

def validate_readable(f: str) -> bool:
    if not os.path.isfile(f) or not os.access(f, os.R_OK):
        raise ValueError("could not open file f =", f)

class Bridge:
    def __init__(
        self, model_lib: str, model_data: str, *, seed: int = 1234, chain_id: int = 0
    ) -> None:
        """Construct Stan model interface and PRNG."""
        validate_readable(model_lib)
        validate_readable(model_data)
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

        self._name = self.stanlib.name
        self._name.restype = str
        self._name.argtypes = []

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
        self._param_unconstrain.restype = int
        self._param_unconstrain.argtypes = [ctypes.c_void_p, double_array, double_array]

        self._param_unconstrain_json = self.stanlib.param_unconstrain_json
        self._param_unconstrain_json.restype = int
        self._param_unconstrain_json.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            double_array,
        ]

        self._log_density = self.stanlib.log_density
        self._log_density.restype = ctypes.c_int
        self._log_density.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double)
        ]

        self._log_density_gradient = self.stanlib.log_density_gradient2
        self._log_density_gradient.restype = ctypes.c_int
        self._log_density_gradient.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            double_array,
        ]

        self._log_density_hessian = self.stanlib.log_density_hessian
        self._log_density_hessian.restype = int
        self._log_density_hessian.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            double_array,
            double_array,
        ]

        self._destruct = self.stanlib.destruct
        self._destruct.restype = int
        self._destruct.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """Destroy Stan model and free memory"""
        self._destruct(self.model_rng)

    def name(self) -> str:
        return self._name()

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
        out: Optional[FloatArray] = None,
    ) -> FloatArray:
        dims = self.param_num(include_tp = include_tp, include_gq = include_gq)
        if out is None:
            out = np.zeros(dims)
        elif out.size != dims:
            raise ValueError(
                "Error: out must be same size as number of constrained parameters"
                )
        rc = self._param_constrain(self.model_rng, int(include_tp), int(include_gq), theta_unc, out)
        if rc:
            raise ValueError("param_constrain failed on C++ side; see stderr for messages")
        return out

    def param_unconstrain(
        self, theta: FloatArray, *, out: Optional[FloatArray] = None
    ) -> FloatArray:
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)
        elif out.size != dims:
            raise ValueError(
                f"out size = {out.size} != unconstrained params size = {dims}"
            )
        rc = self._param_unconstrain(self.model_rng, theta, out)
        if rc:
            raise ValueError("param_unconstrain failed on C++ side; see stderr for messages")
        return out

    def param_unconstrain_json(
        self, theta_json: str, *, out: Optional[FloatArray] = None
    ) -> FloatArray:
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)
        elif out.size != dims:
            raise ValueError(
                f"out size = {out.size} != unconstrained params size = {dims}"
            )
        chars = theta_json.encode("UTF-8")
        rc = self._param_unconstrain_json(self.model_rng, chars, out)
        if rc:
            raise ValueErorr("param_unconstrain_json failed on C++ side; see stderr for messages")
        return out

    def log_density(
        self, theta_unc: FloatArray, *, propto: bool = True, jacobian: bool = True,
    ) -> float:
        lp = ctypes.pointer(ctypes.c_double())
        rc = self._log_density(self.model_rng, int(propto), int(jacobian), theta_unc, lp)
        if rc:
            raise ValueError("C++ exception in log_density(); see stderr for messages")
        return lp.contents.value
        
    def log_density_gradient(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        out: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray]:
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)
        elif out.size != dims:
            raise ValueError(f"out size = {out.size} != params size = {dims}")
        lp = ctypes.pointer(ctypes.c_double())
        rc = self._log_density_gradient(
            self.model_rng, int(propto), int(jacobian), theta_unc, lp, out
        )
        if rc:
            raise ValueError("C++ exception in log_density_gradient(); see stderr for messages")
        return lp.contents.value, out

    def log_density_hessian(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        out_grad: Optional[FloatArray] = None,
        out_hess: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray, FloatArray]:
        dims = self.param_unc_num()
        if out_grad is None:
            out_grad = np.zeros(shape=dims)
        elif out_grad.size != dims:
            raise ValueError(f"out_grad size = {out_grad.size} != params size = {dims}")
        hess_size = dims * dims
        if out_hess is None:
            out_hess = np.zeros(shape=hess_size)
        elif out_hess.size != hess_size:
            raise ValueError(f"out_hess size = {out_hess.size} != params size^2 = {hess_size}")
        lp = ctypes.pointer(ctypes.c_double())
        rc = self._log_density_hessian(
            self.model_rng, int(propto), int(jacobian), theta_unc, lp, out_grad, out_hess
        )
        if rc:
            raise ValueError("C++ exception in log_density_hessian(); see stderr for messages")
        out_hess = out_hess.reshape(dims, dims)
        return lp.contents.value, out_grad, out_hess
