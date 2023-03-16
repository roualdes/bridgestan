from ast import literal_eval
from setuptools import setup
from pathlib import Path


VERSIONFILE = Path(__file__).parent / "bridgestan" / "__version.py"
with open(VERSIONFILE, "rt") as f:
    version = literal_eval(f.readline().split("= ")[1])

# remainder of setup in setup.cfg
setup(version=version)
