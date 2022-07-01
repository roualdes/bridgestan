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

        self._create = self.stanlib.stanmodel_create
        self._create.restype = ctypes.c_void_p
        self._create.argtpyes = [ctypes.c_char_p,
                                 ctypes.c_uint]

        self.stanmodel = self._create(str.encode(model_data),
                                      self.seed)

        self._numparams = self.stanlib.stanmodel_get_num_unc_params
        self._numparams.restype = ctypes.c_int
        self._numparams.argtypes = [ctypes.c_void_p]
        self._D = self._numparams(self.stanmodel)

        self._logdensity = np.zeros(shape = 1)
        self._grad = np.zeros(shape = self._D)

        self._logdensity_grad = self.stanlib.stanmodel_log_density
        self._logdensity_grad.restype = ctypes.c_void_p
        self._logdensity_grad.argtypes = [ctypes.c_void_p,
                                          ndpointer(ctypes.c_double),
                                          ctypes.c_int,
                                          ndpointer(ctypes.c_double),
                                          ndpointer(ctypes.c_double),
                                          ctypes.c_int,
                                          ctypes.c_int]

    @property
    def D(self) -> int:
        return self._D

    @property
    def logdensity(self) -> npt.NDArray[np.float64]:
        return self._logdensity

    @property
    def grad(self) -> npt.NDArray[np.float64]:
        return self._grad

    def logdensity_grad(self, q: npt.NDArray[np.float64],
                        propto: Optional[int] = 1,
                        jacobian: Optional[int] = 1) -> None:
        self._logdensity_grad(self.stanmodel,
                              q, self._D,
                              self._logdensity, self._grad,
                              propto, jacobian)
