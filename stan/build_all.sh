#!/bin/bash

cd "$BRIDGESTAN"
models=( throw_tp throw_gq throw_lp throw_data jacobian matrix simplex full stdnormal bernoulli gaussian fr_gaussian simple)
for model in "${models[@]}"
do
    CMDSTAN="$CMDSTAN" make -j2 O=0 stan/"$model"/"$model"_model.so
done

CMDSTAN="$CMDSTAN" STAN_THREADS=True make -j2 O=0 stan/multi/multi_model.so
