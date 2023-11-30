import os
from typing import Union


def validate_readable(f: Union[str, os.PathLike]) -> None:
    """
    Raise an error if the specified file is not readable.

    :param f: The file name.
    :raises FileNotFoundError: If the file is not found.
    :raises PermissionError: If the file is not readable.
    """
    if not os.path.isfile(f):
        raise FileNotFoundError(f"File '{f}' does not exist")
    if not os.access(f, os.R_OK):
        raise PermissionError(f"File '{f}' is not readable")
