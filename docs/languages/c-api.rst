C API
=======

----

Core API
--------

The following are the C functions exposed by the BridgeStan library in ``bridgestan.h``.
These are wrapped in the various high-level interfaces. An example calling
these functions from pure-C can be found in the ``c-example/`` subdirectory
of the repository.

These functions are actually implemented in C++, see :doc:`../how-it-works` for more details.

.. autodoxygenfile:: bridgestan.h
    :project: bridgestan
    :sections: func

R-compatible functions
----------------------

To support calling these functions from R without including R-specific headers
into the project, the following functions are exposed in ``bridgestanR.h``.

These are small shims which call the above functions. All arguments and return values
must be handeled via pointers.

.. autodoxygenfile:: bridgestanR.h
    :project: bridgestan
    :sections: func

