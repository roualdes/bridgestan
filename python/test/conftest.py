"""The global configuration for the test suite

This test primarily handles the process by which we can run tests in
different runtimes. This is important, because DLLs compiled with different
flags cannot be loaded into the same Python instances.

This sets up a command line argument to pytest called --run-type. By
default, all tests have the "default" type, but some, such as the BRIDGESTAN_AD
tests, have a different type. These types are mutually exclusive -
one is selected each run, and any others are marked to be skipped.

To create a new runtime environment, add it to the list of types below
and then mark any tests with `@pytest.mark.TYPE_NAME_HERE`.
"""

import pytest

types = ("default", "ad_hessian")

def pytest_addoption(parser):
    parser.addoption(
        "--run-type",
        action="store",
        default="default",
        help="Some tests cannot be run in the same Python runtime",
        choices=types,
    )


def pytest_configure(config):
    for type in types[1:]:
        config.addinivalue_line("markers", f"{type}: mark test as needing a seperate process in group {type}")



def pytest_collection_modifyitems(config, items):
    type_to_run = config.getoption("--run-type")
    skip_type = pytest.mark.skip(reason="--run-type has selected other tests")
    if type_to_run == "default":
        for type in types[1:]:
            for item in items:
                if type in item.keywords:
                    item.add_marker(skip_type)
    else:
        for item in items:
            if type_to_run not in item.keywords:
                item.add_marker(skip_type)
