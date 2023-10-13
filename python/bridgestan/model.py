import ctypes
import warnings
from pathlib import Path
from typing import List, Optional, Tuple

import numpy as np
import numpy.typing as npt
from dllist import dllist
from numpy.ctypeslib import ndpointer

from .__version import __version_info__
from .compile import compile_model, windows_dll_path_setup
from .util import validate_readable

FloatArray = npt.NDArray[np.float64]
double_array = ndpointer(dtype=ctypes.c_double, flags=("C_CONTIGUOUS"))
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
        model_lib: str,
        model_data: Optional[str] = None,
        *,
        seed: int = 1234,
        capture_stan_prints: bool = True,
    ) -> None:
        """
        Construct a StanModel object for a compiled Stan model and data given
        constructor arguments.

        :param model_lib: A system path to compiled shared object.
        :param model_data: Either a JSON string literal, a
            system path to a data file in JSON format ending in ``.json``,
            or the empty string.
        :param seed: A pseudo random number generator seed, used for RNG functions
            in the ``transformed data`` block.
        :param capture_stan_prints: If ``True``, capture all ``print`` statements
            from the Stan model and print them from Python. This has no effect if
            the model does not contain any ``print`` statements, but may have
            a performance impact if it does. If ``False``, ``print`` statements
            from the Stan model will be sent to ``cout`` and will not be seen in
            Jupyter or capturable with :func:`contextlib.redirect_stdout`.

            **Note:** If this is set for a model, any other models instantiated
            from the *same shared library* will also have the callback set, even
            if they were created *before* this model.
        :raises FileNotFoundError or PermissionError: If ``model_lib`` is not readable or
            ``model_data`` is specified and not a path to a readable file.
        :raises RuntimeError: If there is an error instantiating the
            model from C++.
        """
        validate_readable(model_lib)
        if model_data is not None and model_data.endswith(".json"):
            validate_readable(model_data)
            with open(model_data, "r") as f:
                model_data = f.read()

        windows_dll_path_setup()
        self.lib_path = str(Path(model_lib).absolute().resolve())
        if self.lib_path in dllist():
            warnings.warn(
                f"Loading a shared object {self.lib_path} that has already been loaded.\n"
                "If the file has changed since the last time it was loaded, this load may not update the library!"
            )
        self.stanlib = ctypes.CDLL(self.lib_path)

        self.data = model_data or ""
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

        err = ctypes.pointer(ctypes.c_char_p())
        self.model = self._construct(str.encode(self.data), self.seed, err)

        if not self.model:
            raise self._handle_error(err.contents, "bs_model_construct")

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
            double_array,
            ctypes.c_void_p,
            star_star_char,
        ]

        self._param_unconstrain = self.stanlib.bs_param_unconstrain
        self._param_unconstrain.restype = ctypes.c_int
        self._param_unconstrain.argtypes = [
            ctypes.c_void_p,
            double_array,
            double_array,
            star_star_char,
        ]

        self._param_unconstrain_json = self.stanlib.bs_param_unconstrain_json
        self._param_unconstrain_json.restype = ctypes.c_int
        self._param_unconstrain_json.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            double_array,
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
            double_array,
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
            double_array,
            double_array,
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
            double_array,
            star_star_char,
        ]

        self._destruct = self.stanlib.bs_model_destruct
        self._destruct.restype = None
        self._destruct.argtypes = [ctypes.c_void_p]

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

        This is equivalent to calling :func:`bridgestan.compile_model`` and then the
        constructor of this class.

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
        result = compile_model(stan_file, stanc_args=stanc_args, make_args=make_args)
        return cls(
            str(result), model_data, seed=seed, capture_stan_prints=capture_stan_prints
        )

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
        elif out.size != dims:
            raise ValueError(
                "Error: out must be same size as number of constrained parameters"
            )

        err = ctypes.pointer(ctypes.c_char_p())

        rc = self._param_constrain(
            self.model,
            int(include_tp),
            int(include_gq),
            theta_unc,
            out,
            rng_ptr,
            err,
        )

        if rc:
            raise self._handle_error(err.contents, "param_constrain")
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
        elif out.size != dims:
            raise ValueError(
                f"out size = {out.size} != unconstrained params size = {dims}"
            )
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._param_unconstrain(self.model, theta, out, err)
        if rc:
            raise self._handle_error(err.contents, "param_unconstrain")
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
        elif out.size != dims:
            raise ValueError(
                f"out size = {out.size} != unconstrained params size = {dims}"
            )
        chars = theta_json.encode("UTF-8")
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._param_unconstrain_json(self.model, chars, out, err)
        if rc:
            raise self._handle_error(err.contents, "param_unconstrain_json")
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
        lp = ctypes.pointer(ctypes.c_double())
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._log_density(
            self.model, int(propto), int(jacobian), theta_unc, lp, err
        )
        if rc:
            raise self._handle_error(err.contents, "log_density")
        return lp.contents.value

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
        elif out.size != dims:
            raise ValueError(f"out size = {out.size} != params size = {dims}")
        lp = ctypes.pointer(ctypes.c_double())
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._log_density_gradient(
            self.model, int(propto), int(jacobian), theta_unc, lp, out, err
        )
        if rc:
            raise self._handle_error(err.contents, "log_density_gradient")
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
        elif out_grad.shape != (dims,):
            raise ValueError(f"out_grad size = {out_grad.size} != params size = {dims}")
        hess_size = dims * dims
        if out_hess is None:
            out_hess = np.zeros(shape=hess_size)
        elif out_hess.shape != (dims, dims):
            raise ValueError(
                f"out_hess size = {out_hess.size} != params size^2 = {hess_size}"
            )
        lp = ctypes.pointer(ctypes.c_double())
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._log_density_hessian(
            self.model,
            int(propto),
            int(jacobian),
            theta_unc,
            lp,
            out_grad,
            out_hess,
            err,
        )
        if rc:
            raise self._handle_error(err.contents, "log_density_hessian")
        out_hess = out_hess.reshape(dims, dims)
        return lp.contents.value, out_grad, out_hess

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
        elif out.size != dims:
            raise ValueError(f"out size = {out.size} != params size = {dims}")
        lp = ctypes.pointer(ctypes.c_double())
        err = ctypes.pointer(ctypes.c_char_p())
        rc = self._log_density_hvp(
            self.model, int(propto), int(jacobian), theta_unc, v, lp, out, err
        )
        if rc:
            raise self._handle_error(err.contents, "log_density_hessian_vector_product")

        return lp.contents.value, out

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
        else:
            return RuntimeError(f"Unknown error in {method}. ")


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
