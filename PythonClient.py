import ctypes
import numpy as np
import numpy.typing as npt

from numpy.ctypeslib import ndpointer
from typing import Any, Iterable, List, Mapping, Tuple, Union, Optional

class PyBridgeStan:
    def __init__(self, model_lib: str, model_data: str, seed: int = 204) -> None:
        """Create Stan Model thingy.
        """
        self.stanlib = ctypes.CDLL(model_lib)
        self.seed = seed

        self._create = self.stanlib.create
        self._create.restype = ctypes.c_void_p
        self._create.argtpyes = [ctypes.c_char_p,
                                 ctypes.c_uint]

        self.stanmodel = self._create(str.encode(model_data),
                                      self.seed)

        self._param_num = self.stanlib.param_num
        self._param_num.restype = ctypes.c_int
        self._param_num.argtypes = [ctypes.c_void_p]

        self._K = self._param_num(self.stanmodel)
        self._constrained_parameters = np.zeros(shape = self._K)

        self._param_constrain = self.stanlib.param_constrain
        self._param_constrain.restype = ctypes.c_void_p
        self._param_constrain.argtypes = [ctypes.c_void_p,
                                          ctypes.c_int,
                                          ndpointer(ctypes.c_double),
                                          ctypes.c_int,
                                          ndpointer(ctypes.c_double)]

        self._param_unc_num = self.stanlib.param_unc_num
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        self._dims = self._param_unc_num(self.stanmodel)
        self._unconstrained_parameters = np.zeros(shape = self._dims)

        self._param_unconstrain = self.stanlib.param_unconstrain
        self._param_unconstrain.restype = ctypes.c_void_p
        self._param_unconstrain.argtypes = [ctypes.c_void_p,
                                            ctypes.c_int,
                                            ndpointer(ctypes.c_double),
                                            ctypes.c_int,
                                            ndpointer(ctypes.c_double)]

        self._log_density = np.zeros(shape = 1)
        self._gradient = np.zeros(shape = self._dims)

        self._log_density_gradient = self.stanlib.log_density_gradient
        self._log_density_gradient.restype = ctypes.c_void_p
        self._log_density_gradient.argtypes = [ctypes.c_void_p,
                                               ctypes.c_int,
                                               ndpointer(ctypes.c_double),
                                               ndpointer(ctypes.c_double),
                                               ndpointer(ctypes.c_double),
                                               ctypes.c_int,
                                               ctypes.c_int]

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

    def param_constrain(self,
                        q: npt.NDArray[np.float64]) -> npt.NDArray[np.float64]:
        self._param_constrain(self.stanmodel,
                              self._dims,
                              q,
                              self._constrained_parameters.size,
                              self._constrained_parameters)
        return self._constrained_parameters

    def dims(self) -> int:
        """Number of unconstrained parameters"""
        return self._dims

    def param_unc_num(self) -> int:
        return self._param_unc_num(self.stanmodel)

    def param_unconstrain(self,
                          q: npt.NDArray[np.float64]) -> npt.NDArray[np.float64]:
        self._param_unconstrain(self.stanmodel,
                                self._K,
                                q,
                                self._dims,
                                self._unconstrained_parameters)
        return self._unconstrained_parameters

    def log_density(self, q: npt.NDArray[np.float64],
                             propto: Optional[int] = 1,
                             jacobian: Optional[int] = 1) -> float:
        self._log_density_gradient(self.stanmodel,
                                   self._dims,
                                   q,
                                   self._log_density,
                                   self._gradient,
                                   propto,
                                   jacobian)
        return self._log_density[0]


    def log_density_gradient(self, q: npt.NDArray[np.float64],
                             propto: Optional[int] = 1,
                             jacobian: Optional[int] = 1) -> Tuple[float, npt.NDArray[np.float64]]:
        self._log_density_gradient(self.stanmodel,
                                   self._dims,
                                   q,
                                   self._log_density,
                                   self._gradient,
                                   propto,
                                   jacobian)
        return self._log_density[0], self._gradient
