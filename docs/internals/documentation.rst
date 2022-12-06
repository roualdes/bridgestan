Documentation
=============


Documenting a mixed-language project such as BridgeStan can be tricky.

We attempt to keep documentation in the natural place for each language: C/C++
code is documented with doxygen-style comments in the source, Python documentation
appears in docstrings, etc. With the exception of the R interface, our documentation
generation (powered by `Sphinx <https://www.sphinx-doc.org/en/master/>`__) automatically
combines these together into the documentation you are reading now.

To build the documentation, you can run ``make docs`` in the top-level directory.
This places the files in ``docs/_build/html``. At a minimum, the following must be installed:

* The Python interface to BridgeStan
* `Sphinx 5.0 or above <https://www.sphinx-doc.org/en/master/>`__
* `nbsphinx <https://nbsphinx.readthedocs.io/en/0.8.9/>`__
* `sphinx-copybutton <https://sphinx-copybutton.readthedocs.io/en/latest/>`__
* `pydata-sphinx-theme <https://pydata-sphinx-theme.readthedocs.io/en/stable/>`__
* `MySt-Parser <https://myst-parser.readthedocs.io/en/latest/>`__

There are also optional dependencies depending on which part of the documentation
you are updating.
If you wish to build the C++ portions of the documentation, you should also have:

* `Doxygen <https://doxygen.nl/>`__
* `Breathe <https://breathe.readthedocs.io/en/stable/index.html>`__

Similarly, the Julia documentation will only update if Julia is installed. Julia
documentation is written in ``julia/docs/src/julia.md``. We then build
this with `DocumenterMarkdown.jl <https://github.com/JuliaDocs/DocumenterMarkdown.jl>`__,
and the output is placed in ``docs/languages/julia.md``.
