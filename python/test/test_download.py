import os

import bridgestan as bs
from unittest import mock


@mock.patch.dict(os.environ, {"BRIDGESTAN": ""})
def test_download_bridgestan():
    bs.compile.verify_bridgestan_path(bs.compile.get_bridgestan_path())
