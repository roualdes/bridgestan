from .__version import __version__
from .compile import compile_model, set_bridgestan_path
from .model import StanModel

__all__ = ["StanModel", "set_bridgestan_path", "compile_model"]

import platform as _plt


if _plt.system() == "Windows":

    def _windows_path_setup():
        """Add tbb.dll to %PATH% on Windows."""
        import os
        import subprocess
        import warnings
        from .compile import get_bridgestan_path

        try:
            out = subprocess.run(
                ["where.exe", "tbb.dll"], check=True, capture_output=True
            )
            tbb_path = os.path.dirname(out.stdout.decode().splitlines()[0])
            os.add_dll_directory(tbb_path)
        except:
            tbb_path = os.path.join(
                get_bridgestan_path(), "stan", "lib", "stan_math", "lib", "tbb"
            )
            os.environ["PATH"] = tbb_path + ";" + os.environ["PATH"]
            os.add_dll_directory(tbb_path)

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
            mingw_dir = os.path.dirname(out.stdout.decode().splitlines()[0])
            os.add_dll_directory(mingw_dir)
        except:
            # no default location
            warnings.warn(
                "Unable to find MinGW's DLL location. Loading BridgeStan models may fail.",
                RuntimeWarning,
            )

    _windows_path_setup()
