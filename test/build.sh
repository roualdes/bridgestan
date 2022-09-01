#!/bin/bash

cd "$BRIDGESTAN"
models=( throw_tp throw_gq throw_lp throw_data jacobian matrix simplex full stdnormal bernoulli multi gaussian fr_gaussian simple)
for model in "${models[@]}"
do
    CMDSTAN="$CMDSTAN" make -j4 O=0 stan/"$model"/"$model"_model.so &
done
wait
cd "$BRIDGESTAN/test"
