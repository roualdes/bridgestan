import tarfile
import urllib.error
import urllib.request
from pathlib import Path
from time import sleep

from .__version import __version__

HOME_BRIDGESTAN = Path("~").expanduser() / ".bridgestan"
CURRENT_BRIDGESTAN = HOME_BRIDGESTAN / f"bridgestan-{__version__}"

RETRIES = 5


def get_bridgestan_src() -> None:
    """
    Download and unzip the BridgeStan source distribution for this version

    Based on similar code from cmdstanpy's install_cmdstan script
    """
    url = (
        "https://github.com/roualdes/bridgestan/releases/download/"
        + f"v{__version__}/bridgestan-{__version__}.tar.gz"
    )
    HOME_BRIDGESTAN.mkdir(exist_ok=True)

    err_text = f"Failed to download BridgeStan {__version__} from github.com."
    for i in range(1, 1 + RETRIES):
        try:
            file_tmp, _ = urllib.request.urlretrieve(url, filename=None)
            break
        except urllib.error.HTTPError as e:
            # not recoverable
            raise ValueError(err_text) from e
        except urllib.error.URLError as e:
            print(err_text)
            if i == RETRIES:
                raise ValueError(err_text) from e

            print("Retrying ({i+1}/{RETRIES})...")
            sleep(1)

    try:
        with tarfile.open(file_tmp) as tar:
            tar.extractall(path=HOME_BRIDGESTAN)
    except Exception as e:
        raise ValueError(f"Failed to unpack {file_tmp} during installation") from e
