# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "BridgeStan"
copyright = "2022, BridgeStan Developers"
author = "BridgeStan Developers"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autosummary",
    "sphinx.ext.intersphinx",
    "sphinx.ext.viewcode",
    "sphinx.ext.napoleon",
    "sphinx.ext.autodoc",
    "sphinx.ext.githubpages",
    "nbsphinx",
    "sphinx.ext.mathjax",
    "myst_parser",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
html_css_files = [
    "css/Documenter.css",
]

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
}

html_context = {
    "github_user": "roualdes",
    "github_repo": "bridgestan",
    "github_version": "main",
    "doc_path": "docs",
}


intersphinx_mapping = {
    "python": (
        "https://docs.python.org/3/",
        None,
    ),
    "numpy": ("https://numpy.org/doc/stable/", None),
    "cmdstanpy": ("https://mc-stan.org/cmdstanpy/", None),
}

# julia doc build
import subprocess
import pathlib

try:
    print("Building Julia doc")
    subprocess.run(
        ["julia", '--project="."', "./make.jl"],
        cwd=pathlib.Path(__file__).parent.parent.parent / "julia" / "docs",
        check=True,
    )
except Exception as e:
    print("Failed to build julia docs!\n", e)
