import os
import platform
import subprocess
from pathlib import Path
from typing import List

from .__version import __version__
from .download import CURRENT_BRIDGESTAN, get_bridgestan_src
from .util import validate_readable


def verify_bridgestan_path(path: str) -> None:
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


PYTHON_FOLDER = Path(__file__).parent.parent

MAKE = os.getenv(
    "MAKE",
    "make" if platform.system() != "Windows" else "mingw32-make",
)


def set_bridgestan_path(path: str) -> None:
    """Set the path to BridgeStan.

    This should point to the top-level folder of the repository.

    By default this is set to the value of the environment
    variable ``BRIDGESTAN``, or to the folder above the location
    of this package (which, assuming a source installation, corresponds
    to the repository root).
    """
    verify_bridgestan_path(path)
    os.environ["BRIDGESTAN"] = path


def get_bridgestan_path():
    path = os.getenv("BRIDGESTAN", "")
    if path == "":
        try:
            path = str(CURRENT_BRIDGESTAN)
            verify_bridgestan_path(path)
        except ValueError:
            print(
                "Bridgestan not found at location specified by $BRIDGESTAN "
                f"environment variable, downloading version {__version__} to {path}"
            )
            get_bridgestan_src()
            print("Done!")

    return path


def generate_so_name(model: Path):
    name = model.stem
    return model.with_stem(f"{name}_model").with_suffix(".so")


def compile_model(
    stan_file: str, *, stanc_args: List[str] = [], make_args: List[str] = []
) -> Path:
    """
    Run BridgeStan's Makefile on a ``.stan`` file, creating the ``.so``
    used by the StanModel class.

    This function assumes that the path to BridgeStan is valid.
    This can be set with :func:`set_bridgestan_path`.

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
    validate_readable(str(file_path))
    if file_path.suffix != ".stan":
        raise ValueError(f"File '{stan_file}' does not end in .stan")

    stanc_args
    output = generate_so_name(file_path)
    cmd = (
        [MAKE]
        + make_args
        + ["STANCFLAGS=" + " ".join(["--include-paths=."] + stanc_args)]
        + [str(output)]
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
