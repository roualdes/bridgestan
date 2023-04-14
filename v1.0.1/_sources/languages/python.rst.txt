.. py:currentmodule:: bridgestan

Python Interface
================

----

Installation
------------

From PyPI
_________

For convience, BridgeStan is uploaded to the Python Package Index each release.

.. code-block:: shell

    pip install bridgestan

Currently, this package does **not** come with a copy of the BridgeStan C++
source code, so you will need to follow the instructions from the
:doc:`Getting Started guide <../getting-started>` to download this, and use
:func:`set_bridgestan_path` or the ``$BRIDGESTAN`` environment variable.

From Source
___________
This assumes you have followed the :doc:`Getting Started guide <../getting-started>` to install
BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.

To install the Python interface, you can either install it directly from Github with

.. code-block:: shell

    pip install "git+https://github.com/roualdes/bridgestan.git#egg=bridgestan&subdirectory=python"

Or, since you have already downloaded the repository, you can run

.. code-block:: shell

    pip install -e python/

from the BridgeStan folder.

Note that the Python package depends on Python 3.9+ and NumPy, and will install
NumPy if it is not already installed.

Example Program
---------------

An example program is provided alongside the Python interface code in ``example.py``:

.. raw:: html

   <details>
   <summary><a>Show example.py</a></summary>


.. literalinclude:: ../../python/example.py
   :language: python

.. raw:: html

   </details>

API Reference
-------------

StanModel interface
___________________

.. autoclass:: bridgestan.StanModel
   :members:


Compilation utilities
_____________________

.. autofunction:: bridgestan.compile_model
.. autofunction:: bridgestan.set_bridgestan_path
