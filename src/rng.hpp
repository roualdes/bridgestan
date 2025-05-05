#ifndef BRIDGESTAN_RNG_HPP
#define BRIDGESTAN_RNG_HPP

#include <stan/services/util/create_rng.hpp>

/**
 * A wrapper around the Boost random number generator required
 * by the Stan model's write_array methods. Instances can be
 * constructed with the C function `bs_construct_rng()` and destroyed
 * with the C function `bs_destruct_rng()`.
 */
class bs_rng {
 public:
  bs_rng(unsigned int seed) : rng_(stan::services::util::create_rng(seed, 0)) {}

  stan::rng_t rng_;
};

#endif
