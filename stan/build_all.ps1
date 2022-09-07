cd $env:BRIDGESTAN

$models = "throw_tp",  "throw_gq",  "throw_lp",  "throw_data",  "jacobian",  "matrix",  "simplex",  "full",  "stdnormal",  "bernoulli",  "multi",  "gaussian",  "fr_gaussian",  "simple"

$cmdstanfixed = $env:CMDSTAN.replace('\', '/')
foreach ($model in $models) {
    mingw32-make.exe CMDSTAN="$($cmdstanfixed)/" -j4 O=0 "stan/$($model)/$($model)_model.so"
}

cd "$($env:BRIDGESTAN)/R/test"
gcc.exe -fpic -shared -o test_collisions.dll test_collisions.c
