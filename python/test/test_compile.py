from pathlib import Path

import pytest

import bridgestan as bs

STAN_FOLDER = Path(__file__).parent.parent.parent / "test_models"


def test_compile_good():
    stanfile = STAN_FOLDER / "multi" / "multi.stan"
    lib = bs.compile.generate_so_name(stanfile)
    lib.unlink(missing_ok=True)
    res = bs.compile_model(stanfile)
    assert lib.samefile(res)
    lib.unlink()
    res = bs.compile_model(stanfile, args=["STAN_THREADS=true"])
    assert lib.samefile(res)


def test_compile_bad_ext():
    not_stanfile = STAN_FOLDER / "multi" / "multi.data.json"
    with pytest.raises(ValueError, match=r".stan"):
        bs.compile_model(not_stanfile)


def test_compile_nonexistant():
    not_stanfile = STAN_FOLDER / "multi" / "multi-nothere.data.json"
    with pytest.raises(FileNotFoundError):
        bs.compile_model(not_stanfile)


def test_compile_syntax_error():
    stanfile = STAN_FOLDER / "syntax_error" / "syntax_error.stan"
    with pytest.raises(RuntimeError, match=r"Syntax error"):
        bs.compile_model(stanfile)


def test_compile_bad_cmdstan():
    stanfile = STAN_FOLDER / "multi" / "multi.stan"
    old_path = bs.compile.CMDSTAN_PATH
    bs.compile.set_cmdstan_path("dummy")
    with pytest.raises(RuntimeError, match=r"Make sure CmdStan is installed"):
        bs.compile_model(stanfile)
    bs.compile.set_cmdstan_path(old_path)


def test_compile_bad_bridgestan():
    old_path = bs.compile.BRIDGESTAN_PATH
    with pytest.raises(ValueError, match=r"does not exist"):
        bs.compile.set_bridgestan_path("dummy")
    with pytest.raises(ValueError, match=r"does not contain file 'Makefile'"):
        bs.compile.set_bridgestan_path(str(STAN_FOLDER))
    bs.compile.set_bridgestan_path(old_path)
