import os
from unittest import mock

import bridgestan as bs


@mock.patch.dict(os.environ, {"BRIDGESTAN": ""})
def test_download_bridgestan():
    bs.compile.verify_bridgestan_path(bs.compile.get_bridgestan_path())
