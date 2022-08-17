#!/bin/bash

CMDSTAN="${CMDSTAN:-~/cmdstan/}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
BRIDGESTAN="${DIR%/*}"

cd "$BRIDGESTAN"

models=( bernoulli multi gaussian fr_gaussian)
for model in "${models[@]}"
do
    CMDSTAN="$CMDSTAN" make -j2 stan/"$model"/"$model"_model.so
done

cd "$BRIDGESTAN/test"
