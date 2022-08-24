#!/bin/bash

# First set the paths as environment variables before running.

# $ export CMDSTAN=~/github/stan-dev/cmdstan/
# $ export BRIDGESTAN=~/gitlab/roualdes/bridgestan/

cd "$BRIDGESTAN"
models=( bernoulli multi gaussian fr_gaussian)
for model in "${models[@]}"
do
    CMDSTAN="$CMDSTAN" make -j4 stan/"$model"/"$model"_model.so
done
cd "$BRIDGESTAN/test"
