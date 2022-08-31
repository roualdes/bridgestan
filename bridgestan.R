#!/home/brian/miniconda3/envs/r-env/bin/Rscript

dyn.load("./stan/bernoulli/bernoulli_model.so")

construct <- function(data, rng_seed, chain_id) {
    .C("construct_R",
        as.character(data), as.integer(rng_seed), as.integer(chain_id),
        ptr_out=as.raw(rep(0:8)))$ptr_out

}

name <- function(ptr){
    .C("name_R", as.raw(ptr),
        name_out=as.character(""))$name_out
}
param_names <- function(ptr, include_tp=FALSE, include_gq=FALSE){
    .C("param_names_R", as.raw(ptr),
        as.logical(include_tp), as.logical(include_gq),
        names_out=as.character(""))$names_out -> names
    strsplit(names, ",")
}
param_unc_names <- function(ptr){
    .C("param_unc_names_R", as.raw(ptr),
        names_out=as.character(""))$names_out -> names
    strsplit(names, ",")
}

param_num <- function(ptr, include_tp=FALSE, include_gq=FALSE){
    .C("param_num_R", as.raw(ptr),
        as.logical(include_tp), as.logical(include_gq),
        num=as.integer(0))$num
}
param_unc_num <- function(ptr){
    .C("param_unc_num_R", as.raw(ptr),
        num=as.integer(0))$num
}

data <- "./stan/bernoulli/bernoulli.data.json"
ptr = construct(data, 1234, 0)
print(name(ptr))
print(param_names(ptr))
print(param_unc_num(ptr))
