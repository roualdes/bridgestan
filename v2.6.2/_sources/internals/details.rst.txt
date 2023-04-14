Stan Implementation Details
===========================


.. _log_density_propto:

Speed of the ``propto`` argument
--------------------------------

The log density function provided by a Stan model has
the ability to drop additive constants from the calculation.
This is indicated by the ``propto`` ("``prop``\ortional  ``to``")
argument to function.

If you are using an application such as an MCMC algorithm which requires
gradients and only needs the log density up to a proportion, setting
``propto=True`` will be at least as fast as setting ``propto=False``
and is generally recommended (and the default value).

However, in the case of the ``log_density`` function (which does not calculate
derivatives), this argument has the potential to *slow down* computation, and we
recommend setting it to ``False`` or timing it for your model of interest before
proceeding. Note that the default value of ``propto`` is ``True`` for consistency
with the versions of the function that do calculate gradients, so extra care is needed.

Why is ``log_density`` different?
_________________________________

The implementation of the ``propto`` argument relies on the presence
of autodiff types (``var``\s, in the terminology of Stan's math library)
to determine what is or is not constant with respect to the parameters.
When the argument is ``False``, the calculation of the log density is able to be
computed using only variables of type ``double``.

The consequence of this is that, if the ``propto`` argument is set to ``true``,
the ``log_density`` function will at a minimum need to perform more allocations
than if it were set to ``false``. There may be an even higher cost, due to functions
such as |reduce_sum|_ or Stan's ODE integraters changing their behavior when applied
to autodiff types and performing additional work which is thrown away when gradients
are not needed. These additional computations can quickly overwhelm any speed up
received by dropping additive constants in practice.


.. |reduce_sum| replace:: ``reduce_sum``
.. _reduce_sum: https://mc-stan.org/docs/stan-users-guide/reduce-sum.html

