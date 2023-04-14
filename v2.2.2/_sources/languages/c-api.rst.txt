C API
=====

----

Installation
------------

Please follow the :doc:`Getting Started guide <../getting-started>` to install
BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.


Example Program
---------------

An example program is provided alongside the BridgeStan source in :file:`c-example/`.
Details for building the example can be found in :file:`c-example/Makefile`.

.. raw:: html

   <details>
   <summary><a>Show example.c</a></summary>


.. literalinclude:: ../../c-example/example.c
   :language: c

.. raw:: html

   </details>


API Reference
-------------

The following are the C functions exposed by the BridgeStan library in :file:`bridgestan.h`.
These are wrapped in the various high-level interfaces.

These functions are implemented in C++, see :doc:`../internals` for more details.

.. autodoxygenfile:: bridgestan.h
    :project: bridgestan
    :sections: func typedef var

R-compatible functions
----------------------

To support calling these functions from R without including R-specific headers
into the project, the following functions are exposed in :file:`bridgestanR.h`.

These are small shims which call the above functions. All arguments and return values
must be handled via pointers.

.. autodoxygenfile:: bridgestanR.h
    :project: bridgestan
    :sections: func

