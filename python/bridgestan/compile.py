import os
import platform
import subprocess
import warnings
from pathlib import Path
from typing import List, Union

from .__version import __version__
from .download import CURRENT_BRIDGESTAN, HOME_BRIDGESTAN, get_bridgestan_src
from .util import validate_readable


def verify_bridgestan_path(path: Union[str, os.PathLike]) -> None:
    folder = Path(path).resolve()
    if not folder.exists():
        raise ValueError(
            f"BridgeStan folder '{folder}' does not exist!\n"
            "If you need to set a different location, call 'set_bridgestan_path()'"
        )
    makefile = folder / "Makefile"
    if not makefile.exists():
        raise ValueError(
            f"BridgeStan folder '{folder}' does not "
            "contain file 'Makefile', please ensure it is built properly!\n"
            "If you need to set a different location, call 'set_bridgestan_path()'"
        )


IS_WINDOWS = platform.system() == "Windows"
WINDOWS_PATH_SET = False

MAKE = os.getenv(
    "MAKE",
    "make" if not IS_WINDOWS else "mingw32-make",
)


def set_bridgestan_path(path: Union[str, os.PathLike]) -> None:
    """
    Set the path to BridgeStan.

    This should point to the top-level folder of the repository.
    """
    path = os.path.abspath(path)
    verify_bridgestan_path(path)
    os.environ["BRIDGESTAN"] = path


def get_bridgestan_path() -> str:
    """
    Get the path to BridgeStan.

    By default this is set to the value of the environment
    variable ``BRIDGESTAN``.

    If there is no path set, this function will download
    a matching version of BridgeStan to a folder called
    ``.bridgestan`` in the user's home directory.

    See also :func:`set_bridgestan_path`
    """
    path = os.getenv("BRIDGESTAN", "")
    if path == "":
        try:
            path = os.fspath(CURRENT_BRIDGESTAN)
            verify_bridgestan_path(path)
        except ValueError:
            print(
                "BridgeStan not found at location specified by $BRIDGESTAN "
                f"environment variable, downloading version {__version__} to {path}"
            )
            get_bridgestan_src()
            num_files = len(list(HOME_BRIDGESTAN.iterdir()))
            if num_files >= 5:
                warnings.warn(
                    f"Found {num_files} different versions of BridgeStan in {HOME_BRIDGESTAN}. "
                    "Consider deleting old versions to save space."
                )
            print("Done!")

    return path


def generate_so_name(model: Path) -> Path:
    name = model.stem
    return model.with_stem(f"{name}_model").with_suffix(".so")


def compile_model(
    stan_file: Union[str, os.PathLike],
    *,
    stanc_args: List[str] = [],
    make_args: List[str] = [],
) -> Path:
    """
    Run BridgeStan's Makefile on a ``.stan`` file, creating the ``.so``
    used by the StanModel class.

    This function checks that the path to BridgeStan is valid and will
    error if not. This can be set with :func:`set_bridgestan_path`.

    :param stan_file: A path to a Stan model file.
    :param stanc_args: A list of arguments to pass to stanc3.
        For example, ``["--O1"]`` will enable compiler optimization level 1.
    :param make_args: A list of additional arguments to pass to Make.
        For example, ``["STAN_THREADS=True"]`` will enable
        threading for the compiled model. If the same flags are defined
        in ``make/local``, the versions passed here will take precedent.
    :raises FileNotFoundError or PermissionError: If `stan_file` does not exist
        or is not readable.
    :raises ValueError: If BridgeStan cannot be located.
    :raises RuntimeError: If compilation fails.
    """
    verify_bridgestan_path(get_bridgestan_path())
    file_path = Path(stan_file).resolve()
    validate_readable(file_path)
    if file_path.suffix != ".stan":
        raise ValueError(f"File '{stan_file}' does not end in .stan")

    output = generate_so_name(file_path)
    cmd = (
        [MAKE]
        + make_args
        + ["STANCFLAGS=" + " ".join(["--include-paths=."] + stanc_args)]
        + [os.fspath(output)]
    )
    proc = subprocess.run(
        cmd, cwd=get_bridgestan_path(), capture_output=True, text=True, check=False
    )

    if proc.returncode:
        error = (
            f"Command {' '.join(cmd)} failed with code {proc.returncode}.\n"
            f"stdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
        )

        raise RuntimeError(error)
    return output


def windows_dll_path_setup() -> None:
    """Add tbb.dll to %PATH% on Windows."""
    global WINDOWS_PATH_SET
    if IS_WINDOWS and not WINDOWS_PATH_SET:
        try:
            out = subprocess.run(
                ["where.exe", "tbb.dll"], check=True, capture_output=True
            )
            tbb_path = os.path.dirname(out.stdout.decode().splitlines()[0])
            os.add_dll_directory(tbb_path)
        except:
            try:
                tbb_path = os.path.abspath(
                    os.path.join(
                        get_bridgestan_path(), "stan", "lib", "stan_math", "lib", "tbb"
                    )
                )
                os.environ["PATH"] = tbb_path + ";" + os.environ["PATH"]
                os.add_dll_directory(tbb_path)
                WINDOWS_PATH_SET = True
            except:
                warnings.warn(
                    "Unable to set path to TBB's DLL. Loading BridgeStan models may fail. "
                    f"Tried path '{tbb_path}'",
                    RuntimeWarning,
                )
                WINDOWS_PATH_SET = False
        try:
            out = subprocess.run(
                [
                    "where.exe",
                    "libwinpthread-1.dll",
                    "libgcc_s_seh-1.dll",
                    "libstdc++-6.dll",
                ],
                check=True,
                capture_output=True,
            )
            mingw_dir = os.path.abspath(
                os.path.dirname(out.stdout.decode().splitlines()[0])
            )
            os.add_dll_directory(mingw_dir)
        except:
            # no default location
            warnings.warn(
                "Unable to find MinGW's DLL location. Loading BridgeStan models may fail.",
                RuntimeWarning,
            )
            WINDOWS_PATH_SET = False
