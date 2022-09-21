cd $env:BRIDGESTAN

$models = "throw_tp",  "throw_gq",  "throw_lp",  "throw_data",  "jacobian",  "matrix",  "simplex",  "full",  "stdnormal",  "bernoulli",  "multi",  "gaussian",  "fr_gaussian",  "simple"

$cmdstanfixed = $env:CMDSTAN.replace('\', '/')
foreach ($model in $models) {
    mingw32-make.exe CMDSTAN="$($cmdstanfixed)/" STAN_THREADS="True" -j4 O=0 "test_models/$($model)/$($model)_model.so"
}
