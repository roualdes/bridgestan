Implementation Details
======================


.. _log_density_propto:

``log_density`` with ``propto=true``
------------------------------------

The log density function provided by a Stan model has
the ability to be calculated up to an additive constant.
This is indicated by the ``propto`` ("``prop``\ortional  ``to``")
argument to function.
Usually, this is done for efficiency reasons, as the constant
terms may require computation that is not necessary for calculating
gradients or most sampling algorithms.

However, in the case of the ``log_density`` function (which does not calculate
derivatives), this argument may make the calculation **slower**. This is because
the implementation of this argument relies on the presence of autodiff types
(``var``\s, in the terminology of Stan's math library) to determine what is or
is not constant with respect to the parameters. If not for this (and indeed, if
the argument is set to ``false``), the calculation of the log density is able to be
computed using only primitive types (``double``\s).

The consequence of this is that, if the ``propto`` argument is set to ``true``,
the ``log_density`` function will at a minimum need to perform more allocations
than if it were set to ``false``. There may be an even higher cost, due to functions
such as |reduce_sum|_ or Stan's ODE integraters changing their behavior when applied
to autodiff types and performing additional work which is thrown away when gradients
are not needed.


.. |reduce_sum| replace:: ``reduce_sum``
.. _reduce_sum: https://mc-stan.org/docs/stan-users-guide/reduce-sum.html

