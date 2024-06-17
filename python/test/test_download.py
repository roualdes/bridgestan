import os
import shutil
from unittest import mock

import bridgestan as bs


@mock.patch.dict(os.environ, {"BRIDGESTAN": ""})
def test_download_bridgestan():
    if bs.download.CURRENT_BRIDGESTAN.is_dir():
        shutil.rmtree(bs.download.CURRENT_BRIDGESTAN)

    # first call doesn't download
    assert bs.compile.get_bridgestan_path(download=False) == ""
    bs.compile.verify_bridgestan_path(bs.compile.get_bridgestan_path())
    bs.compile.verify_bridgestan_path(bs.compile.get_bridgestan_path(download=False))
