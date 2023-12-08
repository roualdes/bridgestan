import ctypes
import warnings
from os import PathLike, fspath
from pathlib import Path
from typing import List, Optional, Tuple, Union

import numpy as np
import numpy.typing as npt
from dllist import dllist
from numpy.ctypeslib import ndpointer

from .__version import __version_info__
from .compile import compile_model, windows_dll_path_setup
from .util import validate_readable


def array_ptr(*args, **kwargs):
    """
    Return a new class which can be used in a ctypes signature
    to accept either a numpy array or a compatible
    ``ctypes.POINTER`` instance.

    All arguments are forwarded to :func:`np.ctypeslib.ndpointer`.
    """
    np_type = ndpointer(*args, **kwargs)
    base = np.ctypeslib.as_ctypes_type(np_type._dtype_)
    ctypes_type = ctypes.POINTER(base)

    def from_param(cls, obj):
        if isinstance(obj, (ctypes_type, ctypes.Array)):
            return ctypes_type.from_param(obj)
        return np_type.from_param(obj)

    return type(np_type.__name__, (np_type,), {"from_param": classmethod(from_param)})


FloatArray = Union[
    npt.NDArray[np.float64],
    ctypes.POINTER(ctypes.c_double),
    ctypes.Array[ctypes.c_double],
]
double_array = array_ptr(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))
writeable_double_array = array_ptr(
    dtype=ctypes.c_double, flags=("C_CONTIGUOUS", "WRITEABLE")
)
star_star_char = ctypes.POINTER(ctypes.c_char_p)
c_print_callback = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_char), ctypes.c_int)


@c_print_callback
def _print_callback(s, n):
    print(ctypes.string_at(s, n).decode("utf-8"), end="")


class StanModel:
    """
    A StanModel instance encapsulates a Stan model instantiated with data
    and provides methods to access parameter names, transforms, log
    densities, gradients, and Hessians.
    """

    def __init__(
        self,
        model_lib: Union[str, PathLike],
        data: Union[str, PathLike, None] = None,
        *,
        seed: int = 1234,
        stanc_args: List[str] = [],
        make_args: List[str] = [],
        capture_stan_prints: bool = True,
        model_data: Optional[str] = None,
    ) -> None:
        """
        Construct a StanModel object for a compiled Stan model and data given
        constructor arguments.

        :param model_lib: A system path to compiled shared object or a ``.stan``
            file to be compiled.
        :param data: Data for the model. Either a JSON string literal or a
            system path to a data file in JSON format ending in ``.json``.
            If the model does not require data, this can be either the
            empty string or ``None`` (the default).
        :param seed: A pseudo random number generator seed, used for RNG functions
            in the ``transformed data`` block.
        :param stanc_args: A list of arguments to pass to stanc3 if the
            model is not compiled. For example, ``["--O1"]`` will enable compiler
            optimization level 1.
        :param make_args: A list of additional arguments to pass to Make if the
            model is not compiled. For example, ``["STAN_THREADS=True"]`` will enable
            threading for the compiled model. If the same flags are defined
            in ``make/local``, the versions passed here will take precedent.
        :param capture_stan_prints: If ``True``, capture all ``print`` statements
            from the Stan model and print them from Python. This has no effect if
            the model does not contain any ``print`` statements, but may have
            a performance impact if it does. If ``False``, ``print`` statements
            from the Stan model will be sent to ``cout`` and will not be seen in
            Jupyter or capturable with :func:`contextlib.redirect_stdout`.

            **Note:** If this is set for a model, any other models instantiated
            from the *same shared library* will also have the callback set, even
            if they were created *before* this model.
        :param model_data: Deprecated former name for ``data``.
        :raises FileNotFoundError or PermissionError: If ``model_lib`` is not readable or
            ``data`` is specified and not a path to a readable file.
        :raises RuntimeError: If there is an error instantiating the
            model from C++.
        """
        validate_readable(model_lib)
        if model_data is not None:
            if data is not None:
                raise ValueError(
                    "Cannot specify both model_data and data arguments. "
                    "Please use only the data argument."
                )
            warnings.warn(
                "The model_data argument is deprecated and will be removed in a future "
                "release. Please use the data argument instead.",
                DeprecationWarning,
            )
            data = model_data
        if data is not None:
            data = fspath(data)
            if data.endswith(".json"):
                validate_readable(data)
                with open(data, "r", encoding="utf-8") as file:
                    data = file.read()

        windows_dll_path_setup()

        if str(model_lib).endswith(".stan"):
            model_lib = compile_model(
                model_lib, make_args=make_args, stanc_args=stanc_args
            )

        self.lib_path = fspath(Path(model_lib).absolute().resolve())
        if self.lib_path in dllist():
            warnings.warn(
                f"Loading a shared object {self.lib_path} that has already been loaded.\n"
                "If the file has changed since the last time it was loaded, this load may "
                "not update the library!"
            )
        self.stanlib = ctypes.CDLL(self.lib_path)

        self.data = data or ""
        self.seed = seed

        self._construct = self.stanlib.bs_model_construct
        self._construct.restype = ctypes.c_void_p
        self._construct.argtypes = [
            ctypes.c_char_p,
            ctypes.c_uint,
            star_star_char,
        ]

        self._free_error = self.stanlib.bs_free_error_msg
        self._free_error.restype = None
        self._free_error.argtypes = [ctypes.c_char_p]

        self._set_print_callback = self.stanlib.bs_set_print_callback
        self._set_print_callback.restype = None
        self._set_print_callback.argtypes = [c_print_callback, star_star_char]
        if capture_stan_prints:
            self._set_print_callback(_print_callback, None)

        err = ctypes.c_char_p()
        self.model = self._construct(
            str.encode(self.data), self.seed, ctypes.byref(err)
        )

        if not self.model:
            raise self._handle_error(err, "bs_model_construct")

        if self.model_version() != __version_info__:
            warnings.warn(
                "The version of the compiled model does not match the version of the "
                "Python package. Consider recompiling the model.",
                RuntimeWarning,
            )

        self._name = self.stanlib.bs_name
        self._name.restype = ctypes.c_char_p
        self._name.argtypes = [ctypes.c_void_p]

        self._model_info = self.stanlib.bs_model_info
        self._model_info.restype = ctypes.c_char_p
        self._model_info.argtypes = [ctypes.c_void_p]

        self._param_num = self.stanlib.bs_param_num
        self._param_num.restype = ctypes.c_int
        self._param_num.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]

        self._param_unc_num = self.stanlib.bs_param_unc_num
        self._param_unc_num.restype = ctypes.c_int
        self._param_unc_num.argtypes = [ctypes.c_void_p]

        num_params = self._param_unc_num(self.model)

        param_sized_out_array = array_ptr(
            dtype=ctypes.c_double,
            flags=("C_CONTIGUOUS", "WRITEABLE"),
            shape=(num_params,),
        )
        param_sqrd_sized_out_array = array_ptr(
            dtype=ctypes.c_double,
            flags=("C_CONTIGUOUS", "WRITEABLE"),
            shape=(num_params, num_params),
        )

        self._param_names = self.stanlib.bs_param_names
        self._param_names.restype = ctypes.c_char_p
        self._param_names.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
        ]

        self._param_unc_names = self.stanlib.bs_param_unc_names
        self._param_unc_names.restype = ctypes.c_char_p
        self._param_unc_names.argtypes = [ctypes.c_void_p]

        self._param_constrain = self.stanlib.bs_param_constrain
        self._param_constrain.restype = ctypes.c_int
        self._param_constrain.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            writeable_double_array,
            ctypes.c_void_p,
            star_star_char,
        ]

        self._param_unconstrain = self.stanlib.bs_param_unconstrain
        self._param_unconstrain.restype = ctypes.c_int
        self._param_unconstrain.argtypes = [
            ctypes.c_void_p,
            double_array,
            param_sized_out_array,
            star_star_char,
        ]

        self._param_unconstrain_json = self.stanlib.bs_param_unconstrain_json
        self._param_unconstrain_json.restype = ctypes.c_int
        self._param_unconstrain_json.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            param_sized_out_array,
            star_star_char,
        ]

        self._log_density = self.stanlib.bs_log_density
        self._log_density.restype = ctypes.c_int
        self._log_density.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            star_star_char,
        ]

        self._log_density_gradient = self.stanlib.bs_log_density_gradient
        self._log_density_gradient.restype = ctypes.c_int
        self._log_density_gradient.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            param_sized_out_array,
            star_star_char,
        ]

        self._log_density_hessian = self.stanlib.bs_log_density_hessian
        self._log_density_hessian.restype = ctypes.c_int
        self._log_density_hessian.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            param_sized_out_array,
            param_sqrd_sized_out_array,
            star_star_char,
        ]

        self._log_density_hvp = self.stanlib.bs_log_density_hessian_vector_product
        self._log_density_hvp.restype = ctypes.c_int
        self._log_density_hvp.argtypes = [
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_int,
            double_array,
            double_array,
            ctypes.POINTER(ctypes.c_double),
            param_sized_out_array,
            star_star_char,
        ]

        self._destruct = self.stanlib.bs_model_destruct
        self._destruct.restype = None
        self._destruct.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """
        Destroy the Stan model and free memory.
        """
        if hasattr(self, "model") and hasattr(self, "_destruct"):
            self._destruct(self.model)

    def __repr__(self) -> str:
        data = f"{self.data!r}, " if self.data else ""
        return f"StanModel({self.lib_path!r}, {data}, seed={self.seed})"

    def name(self) -> str:
        """
        Return the name of the Stan model.

        :return: The name of Stan model.
        """
        return self._name(self.model).decode("utf-8")

    def model_info(self) -> str:
        """
        Return compilation information about the model. For example,
        this includes the current Stan version and important
        compiler settings.

        :return: Information about the compiled Stan model.
        """
        return self._model_info(self.model).decode("utf-8")

    def model_version(self) -> Tuple[int, int, int]:
        """
        Return the BridgeStan version of the compiled model.
        """
        return (
            ctypes.c_int.in_dll(self.stanlib, "bs_major_version").value,
            ctypes.c_int.in_dll(self.stanlib, "bs_minor_version").value,
            ctypes.c_int.in_dll(self.stanlib, "bs_patch_version").value,
        )

    def param_num(self, *, include_tp: bool = False, include_gq: bool = False) -> int:
        """
        Return the number of parameters, including transformed
        parameters and/or generated quantities as indicated.

        :param include_tp: ``True`` to include the transformed parameters.
        :param include_gq: ``True`` to include the generated quantities.
        :return: The number of parameters.
        """
        return self._param_num(self.model, int(include_tp), int(include_gq))

    def param_unc_num(self) -> int:
        """
        Return the number of unconstrained parameters.

        :return: The number of unconstrained parameters.
        """
        return self._param_unc_num(self.model)

    def param_names(
        self, *, include_tp: bool = False, include_gq: bool = False
    ) -> List[str]:
        """
        Return the indexed names of the parameters, including transformed
        parameters and/or generated quantities as indicated.  For
        containers, indexes are separated by periods (`.`).
        For example, the scalar ``a`` has
        indexed name ``a``, the vector entry ``a[1]`` has indexed name ``a.1``
        and the matrix entry ``a[2, 3]`` has indexed name ``a.2.3``.
        Parameter order of the output is column major and more
        generally last-index major for containers.

        :param include_tp: ``True`` to include transformed parameters.
        :param include_gq: ``True`` to include generated quantities.
        :return: The indexed names of the parameters.
        """
        return (
            self._param_names(self.model, int(include_tp), int(include_gq))
            .decode("utf-8")
            .split(",")
        )

    def param_unc_names(self) -> List[str]:
        """
        Return the indexed names of the unconstrained parameters.
        For example, a scalar unconstrained parameter ``b`` has indexed
        name ``b`` and a vector entry ``b[3]`` has indexed name ``b.3``.

        :return: The indexed names of the unconstrained parameters.
        """
        return self._param_unc_names(self.model).decode("utf-8").split(",")

    def param_constrain(
        self,
        theta_unc: FloatArray,
        *,
        include_tp: bool = False,
        include_gq: bool = False,
        out: Optional[FloatArray] = None,
        rng: Optional["StanRNG"] = None,
    ) -> FloatArray:
        """
        Return the constrained parameters derived from the specified
        unconstrained parameters as an array, optionally including the
        transformed parameters and/or generated quantitities as specified.
        Including generated quantities uses the PRNG and may update its state.
        Setting ``out`` avoids allocation of a new array for the return value.

        :param theta_unc: Unconstrained parameter array.
        :param include_tp: ``True`` to include transformed parameters.
        :param include_gq: ``True`` to include generated quantities.
        :param out: A location into which the result is stored.  If
            provided, it must have shape ``(D, )``, where ``D`` is the number of
            constrained parameters.  If not provided or ``None``, a freshly
            allocated array is returned.
        :param rng: A ``StanRNG`` object to use for generating random
            numbers, see :meth:`~StanModel.new_rng``. Must be specified
            if ``include_gq`` is ``True``.
        :return: The constrained parameter array.
        :raises ValueError: If ``out`` is specified and is not the same
            shape as the return.
        :raises ValueError: If ``rng`` is ``None`` and ``include_gq`` is ``True``.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        if rng is None:
            if include_gq:
                raise ValueError(
                    "Error: must specify rng when including generated quantities"
                )
            rng_ptr = None
        else:
            rng_ptr = rng.ptr

        dims = self.param_num(include_tp=include_tp, include_gq=include_gq)
        if out is None:
            out = np.zeros(dims)
        elif hasattr(out, "shape") and out.shape != (dims,):
            raise ValueError(
                "Error: out must be same size as number of constrained parameters"
            )

        err = ctypes.c_char_p()

        rc = self._param_constrain(
            self.model,
            int(include_tp),
            int(include_gq),
            theta_unc,
            out,
            rng_ptr,
            ctypes.byref(err),
        )

        if rc:
            raise self._handle_error(err, "param_constrain")
        return out

    def new_rng(self, seed) -> "StanRNG":
        """
        Return a new PRNG for use in :meth:`~StanModel.param_constrain``.

        :param seed: A seed for the PRNG.
        :return: A new PRNG wrapper.
        """
        return StanRNG(self.stanlib, seed)

    def param_unconstrain(
        self, theta: FloatArray, *, out: Optional[FloatArray] = None
    ) -> FloatArray:
        """
        Return the unconstrained parameters derived from the specified
        constrained parameters.  Setting ``out`` avoids allocation of a
        new array for the return value.

        :param theta: Constrained parameter array.
        :param out: A location into which the result is stored.  If
            provided, it must have shape ``(D, )``, where ``D`` is the number of
            unconstrained parameters.  If not provided or ``None``, a freshly
            allocated array is returned.
        :raises ValueError: If ``out`` is specified and is not the same
            shape as the return.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)

        err = ctypes.c_char_p()
        rc = self._param_unconstrain(self.model, theta, out, ctypes.byref(err))

        if rc:
            raise self._handle_error(err, "param_unconstrain")
        return out

    def param_unconstrain_json(
        self, theta_json: str, *, out: Optional[FloatArray] = None
    ) -> FloatArray:
        """
        Return an array of the unconstrained parameters derived from the
        specified JSON formatted data.  See the *CmdStan Reference
        Manual* for the schema definition used.

        :param theta_json: The JSON encoded constrained parameters.
        :param out: A location into which the result is stored.  If
            provided, it must have shape ``(D, )``, where ``D`` is the number of
            unconstrained parameters.  If not provided or ``None``, a freshly
            allocated array is returned.
        :return: The unconstrained parameter array.
        :raises ValueError: If ``out`` is specified and is not the same
            shape as the return value.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)

        chars = theta_json.encode("UTF-8")
        err = ctypes.c_char_p()
        rc = self._param_unconstrain_json(self.model, chars, out, ctypes.byref(err))
        if rc:
            raise self._handle_error(err, "param_unconstrain_json")
        return out

    def log_density(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
    ) -> float:
        """
        Return the log density of the specified unconstrained
        parameters, dropping constant terms that do not depend on the
        parameters if ``propto`` is ``True`` and including change of
        variables terms for constrained parameters if ``jacobian`` is ``True``.

        :param theta_unc: Unconstrained parameter array.
        :param propto: ``True`` if constant terms should be dropped from the log density.
        :param jacobian: ``True`` if change-of-variables terms for
            constrained parameters should be included in the log density.
        :return: The log density.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        lp = ctypes.c_double()
        err = ctypes.c_char_p()
        rc = self._log_density(
            self.model,
            int(propto),
            int(jacobian),
            theta_unc,
            ctypes.byref(lp),
            ctypes.byref(err),
        )
        if rc:
            raise self._handle_error(err, "log_density")
        return lp.value

    def log_density_gradient(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        out: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray]:
        """
        Return a tuple of the log density and gradient of the specified
        unconstrained parameters, dropping constant terms that do not depend
        on the parameters if ``propto`` is ``True`` and including change of
        variables terms for constrained parameters if ``jacobian``
        is ``True``.

        :param theta_unc: Unconstrained parameter array.
        :param propto: ``True`` if constant terms should be dropped from the log density.
        :param jacobian: ``True`` if change-of-variables terms for
            constrained parameters should be included in the log density.
        :param out: A location into which the gradient is stored.  If
            provided, it must have shape `(D, )` where ``D`` is the number
            of parameters.  If not provided, a freshly allocated array
            is returned.
        :return: A tuple consisting of log density and gradient.
        :raises ValueError: If ``out`` is specified and is not the same
            shape as the gradient.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)

        lp = ctypes.c_double()
        err = ctypes.c_char_p()

        rc = self._log_density_gradient(
            self.model,
            int(propto),
            int(jacobian),
            theta_unc,
            ctypes.byref(lp),
            out,
            ctypes.byref(err),
        )
        if rc:
            raise self._handle_error(err, "log_density_gradient")
        return lp.value, out

    def log_density_hessian(
        self,
        theta_unc: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        out_grad: Optional[FloatArray] = None,
        out_hess: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray, FloatArray]:
        """
        Return a tuple of the log density, gradient, and Hessian of the
        specified unconstrained parameters, dropping constant terms that do
        not depend on the parameters if ``propto`` is ``True`` and including
        change of variables terms for constrained parameters if
        ``jacobian`` is ``True``.

        :param theta_unc: Unconstrained parameter array.
        :param propto: ``True`` if constant terms should be dropped from the log density.
        :param jacobian: ``True`` if change-of-variables terms for
            constrained parameters should be included in the log density.
        :param out_grad: A location into which the gradient is stored.  If
            provided, it must have shape `(D, )` where ``D`` is the number
            of parameters.  If not provided, a freshly allocated array
            is returned.
        :param out_hess: A location into which the Hessian is stored. If
            provided, it must have shape `(D, D)`, where ``D`` is the
            number of parameters.  If not provided, a freshly allocated
            array is returned.
        :return: A tuple consisting of the log density, gradient, and Hessian.
        :raises ValueError: If ``out_grad`` is specified and is not the
            same shape as the gradient or if ``out_hess`` is specified and it
            is not the same shape as the Hessian.
        :raises RuntimeError: If the C++ Stan model throws an exception.
        """
        dims = self.param_unc_num()
        if out_grad is None:
            out_grad = np.zeros(shape=dims)

        if out_hess is None:
            out_hess = np.zeros(shape=(dims, dims))

        lp = ctypes.c_double()
        err = ctypes.c_char_p()

        rc = self._log_density_hessian(
            self.model,
            int(propto),
            int(jacobian),
            theta_unc,
            ctypes.byref(lp),
            out_grad,
            out_hess,
            ctypes.byref(err),
        )
        if rc:
            raise self._handle_error(err, "log_density_hessian")
        out_hess = out_hess.reshape(dims, dims)
        return lp.value, out_grad, out_hess

    def log_density_hessian_vector_product(
        self,
        theta_unc: FloatArray,
        v: FloatArray,
        *,
        propto: bool = True,
        jacobian: bool = True,
        out: Optional[FloatArray] = None,
    ) -> Tuple[float, FloatArray]:
        """
        Return a tuple of the log density and the product of the Hessian
        with the specified vector.

        :param theta_unc: Unconstrained parameter array.
        :param v: Vector to multiply by the Hessian.
        :param propto: ``True`` if constant terms should be dropped from the log density.
        :param jacobian: ``True`` if change-of-variables terms for
            constrained parameters should be included in the log density.
        :param out: A location into which the product is stored.  If
            provided, it must have shape `(D, )` where ``D`` is the number
            of parameters.  If not provided, a freshly allocated array
            is returned.
        :return: A tuple consisting of the log density and the product.
        :raises ValueError: If ``out`` is specified and is not the same
            shape as the product.
        """
        dims = self.param_unc_num()
        if out is None:
            out = np.zeros(shape=dims)
        lp = ctypes.c_double()
        err = ctypes.c_char_p()

        rc = self._log_density_hvp(
            self.model,
            int(propto),
            int(jacobian),
            theta_unc,
            v,
            ctypes.byref(lp),
            out,
            ctypes.byref(err),
        )
        if rc:
            raise self._handle_error(err, "log_density_hessian_vector_product")

        return lp.value, out

    def _handle_error(self, err: ctypes.c_char_p, method: str) -> Exception:
        """
        Creates an exception based on a string from C++,
        frees the string, and returns the exception.

        :param err: A C string containing an error message, or nullptr.
        :param method: The name of the method that threw the error.
        :return: An exception based on the.
        """
        if err:
            string = ctypes.string_at(err).decode("utf-8")
            self._free_error(err)
            return RuntimeError(string)

        return RuntimeError(f"Unknown error in {method}. ")

    @classmethod
    def from_stan_file(
        cls,
        stan_file: str,
        model_data: Optional[str] = None,
        *,
        stanc_args: List[str] = [],
        make_args: List[str] = [],
        seed: int = 1234,
        capture_stan_prints: bool = True,
    ):
        """
        Construct a StanModel instance from a ``.stan`` file, compiling if necessary.

        DEPRECATED: You should use the constructor on a ``.stan`` file instead.

        :param stan_file: A path to a Stan model file.
        :param model_data: A path to data in JSON format.
        :param stanc_args: A list of arguments to pass to stanc3.
            For example, ``["--O1"]`` will enable compiler optimization level 1.
        :param make_args: A list of additional arguments to pass to Make.
            For example, ``["STAN_THREADS=True"]`` will enable
            threading for the compiled model. If the same flags are defined
            in ``make/local``, the versions passed here will take precedent.
        :param seed: A pseudo random number generator seed, used for RNG functions
            in the ``transformed data`` block.
        :param capture_stan_prints: If ``True``, capture all ``print`` statements
            from the Stan model and print them from Python. This has no effect if
            the model does not contain any ``print`` statements, but may have
            a performance impact if it does. If ``False``, ``print`` statements
            from the Stan model will be sent to ``cout`` and will not be seen in
            Jupyter or capturable with ``contextlib.redirect_stdout``.
        :raises FileNotFoundError or PermissionError: If ``stan_file`` does not exist
            or is not readable.
        :raises ValueError: If BridgeStan cannot be located.
        :raises RuntimeError: If compilation fails.
        """
        warnings.warn(
            "The from_stan_file method is deprecated and will be removed in a future "
            "release. The constructor can be used instead.",
            DeprecationWarning,
        )
        return cls(
            stan_file,
            model_data,
            seed=seed,
            stanc_args=stanc_args,
            make_args=make_args,
            capture_stan_prints=capture_stan_prints,
        )


class StanRNG:
    def __init__(self, lib: ctypes.CDLL, seed: int) -> None:
        """
        Construct a Stan random number generator.
        This should not be called directly. Instead, use
        :meth:`StanModel.new_rng`.
        """
        self.stanlib = lib

        construct = self.stanlib.bs_rng_construct
        construct.restype = ctypes.c_void_p
        construct.argtypes = [ctypes.c_uint, star_star_char]
        self.ptr = construct(seed, None)

        if not self.ptr:
            raise RuntimeError("Failed to construct RNG.")

        self._destruct = self.stanlib.bs_rng_destruct
        self._destruct.restype = None
        self._destruct.argtypes = [ctypes.c_void_p]

    def __del__(self) -> None:
        """
        Destroy the Stan model and free memory.
        """
        if hasattr(self, "ptr") and hasattr(self, "_destruct"):
            self._destruct(self.ptr)
