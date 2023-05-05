from .__version import __version__
from .compile import compile_model, set_bridgestan_path
from .model import StanModel

__all__ = ["StanModel", "set_bridgestan_path", "compile_model"]

import platform as _plt

if _plt.system() == "Windows":

    def _windows_tbb_setup():
        """Add tbb.dll to %PATH% on Windows."""
        import os
        import subprocess
        from .compile import get_bridgestan_path

        try:
            subprocess.run(["where.exe", "tbb.dll"], check=True, capture_output=True)
        except:
            os.environ["PATH"] = (
                os.path.join(
                    get_bridgestan_path(), "stan", "lib", "stan_math", "lib", "tbb"
                )
                + ";"
                + os.environ["PATH"]
            )

    _windows_tbb_setup()
