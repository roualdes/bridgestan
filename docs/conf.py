# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import datetime

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "BridgeStan"
year = datetime.date.today().year
copyright = f"{year}, BridgeStan Developers"
author = "BridgeStan Developers"

import os

import bridgestan


most_recent_release = "v" + bridgestan.__version__
version = os.getenv("BS_DOCS_VERSION", most_recent_release)
if version == "latest":
    # don't display a version number for "latest" docs
    switcher_version = "latest"
    release = ""
else:
    release = version.strip("v")
    switcher_version = version

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autosummary",
    "sphinx.ext.intersphinx",
    "sphinx.ext.viewcode",
    "sphinx.ext.napoleon",
    "sphinx.ext.autodoc",
    "sphinx.ext.githubpages",
    "sphinx_copybutton",
    "nbsphinx",
    "sphinx.ext.mathjax",
    "myst_parser",
]

myst_enable_extensions = ["substitution"]
myst_substitutions = {"most_recent_release": most_recent_release}

suppress_warnings = ["myst.xref_missing"]  # Julia doc generates raw html links

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store", "README.md", "languages/_*"]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
html_css_files = [
    "css/Documenter.css",
    "css/custom.css",
]
html_favicon = "_static/image/favicon.ico"

html_show_sphinx = False

html_theme_options = {
    "icon_links": [
        {
            "name": "GitHub",
            "url": "https://github.com/roualdes/bridgestan",
            "icon": "fab fa-github",
        },
        {
            "name": "Forums",
            "url": "https://discourse.mc-stan.org/",
            "icon": "fas fa-users",
        },
    ],
    "use_edit_page_button": True,
    "switcher": {
        "json_url": "https://roualdes.github.io/bridgestan/latest/_static/switcher.json",
        "version_match": switcher_version,
    },
    "logo": {
        "text": "BridgeStan v" + release if release else "BridgeStan",
        "image_light": "_static/image/icon.png",
        "image_dark": "_static/image/icon_w.png",
        "alt_text": "BridgeStan - Home",
    },
    "navbar_end": ["theme-switcher", "navbar-icon-links", "version-switcher"],
}

html_context = {
    "github_user": "roualdes",
    "github_repo": "bridgestan",
    "github_version": "main",
    "doc_path": "docs",
}

latex_logo = "_static/image/logo.pdf"

intersphinx_mapping = {
    "python": (
        "https://docs.python.org/3/",
        None,
    ),
    "numpy": ("https://numpy.org/doc/stable/", None),
    "cmdstanpy": ("https://mc-stan.org/cmdstanpy/", None),
}


breathe_projects = {"bridgestan": "./_build/cppxml/"}
breathe_projects_source = {"bridgestan": ("../src/", ["bridgestan.h", "bridgestanR.h"])}
breathe_default_project = "bridgestan"
# doxygen doesn't like  __attribute and __declspec
# https://www.doxygen.nl/manual/preprocessing.html
breathe_doxygen_config_options = {
    "ENABLE_PREPROCESSING": "YES",
    "MACRO_EXPANSION": "YES",
    "EXPAND_ONLY_PREDEF": "YES",
    "PREDEFINED": "BS_PUBLIC=",
}

autoclass_content = "both"

# Other languages doc build
import os
import subprocess
import pathlib

RUNNING_IN_CI = os.environ.get("CI") or os.environ.get("READTHEDOCS")
BASE_DIR = pathlib.Path(__file__).parent.parent

try:
    print("Building Julia doc")
    subprocess.run(
        ["julia", "--project=.", "./make.jl"],
        cwd=BASE_DIR / "julia" / "docs",
        check=True,
    )
except Exception as e:
    # fail loudly in Github Actions
    if RUNNING_IN_CI:
        raise e
    else:
        print("Failed to build julia docs!\n", e)

try:
    print("Building R doc")
    subprocess.run(
        ["Rscript", "convert_docs.R"],
        cwd=BASE_DIR / "R",
        check=True,
    )

    # delete some broken links in the generated R docs
    StanModel = pathlib.Path(__file__).parent / "languages" / "_r" / "StanModel.md"
    text = StanModel.read_text()
    start = text.find("### Public methods")
    end = text.find("### Method `")
    text = text[:start] + text[end:]
    StanModel.write_text(text)


except Exception as e:
    # fail loudly in Github Actions
    if RUNNING_IN_CI:
        raise e
    else:
        print("Failed to build R docs!\n", e)


try:
    print("Checking C++ doc availability")
    import breathe

    subprocess.run(["doxygen", "-v"], check=True, capture_output=True)
except Exception as e:
    if RUNNING_IN_CI:
        raise e
    else:
        print("Breathe/doxygen not installed, skipping C++ Doc")
        exclude_patterns += ["languages/c-api.rst"]
else:
    extensions.append("breathe")


try:
    print("Checking Rust doc availability")
    subprocess.run(["cargo", "--version"], check=True, capture_output=True)
except Exception as e:
    if RUNNING_IN_CI:
        raise e
    else:
        print("Rust not installed, skipping Rust Doc")
        exclude_patterns += ["languages/rust.md", "languages/_rust"]
else:
    extensions.append("sphinxcontrib_rust")
    myst_enable_extensions += ["colon_fence", "attrs_block"]
    rust_crates = {
        "bridgestan": str(BASE_DIR / "rust"),
    }
    rust_doc_dir = "languages/_rust"
    rust_rustdoc_fmt = "md"
    rust_generate_mode = "changed" if not RUNNING_IN_CI else "always"
