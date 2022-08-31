#!/home/brian/miniconda3/envs/r-env/bin/Rscript

dyn.load("./stan/simple/simple_model.so")

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


log_density <- function(ptr, theta, propto=TRUE, jacobian=TRUE){
    .C("log_density_R", as.raw(ptr),
            as.logical(propto), as.logical(jacobian), as.numeric(theta),
            val=double(1),
            return_code=as.integer(0))$val
    # todo return code handling
}

log_density_gradient <- function(ptr, theta, propto=TRUE, jacobian=TRUE){
    dims <- param_unc_num(ptr)
    vars <- .C("log_density_gradient_R", as.raw(ptr),
            as.logical(propto), as.logical(jacobian), as.numeric(theta),
            val=double(1), gradient=double(dims),
            return_code=as.integer(0))
    list(val=vars$val, grad=vars$gradient)
    # todo return code handling
}

log_density_hessian <- function(ptr, theta, propto=TRUE, jacobian=TRUE){
    dims <- param_unc_num(ptr)
    vars <- .C("log_density_hessian_R", as.raw(ptr),
            as.logical(propto), as.logical(jacobian), as.numeric(theta),
            val=double(1), gradient=double(dims), hess=double(dims*dims),
            return_code=as.integer(0))
    list(val=vars$val, grad=vars$gradient, hess=matrix(vars$hess,nrow=dims,byrow=TRUE))
    # todo return code handling
}

data <- "./stan/simple/simple.data.json"
ptr = construct(data, 1234, 0)

print(name(ptr))
print(param_names(ptr))

x <- runif(5)
print("grad(x) should be -x:", x)
print(x)
print(log_density_gradient(ptr,x)$grad)
print("Hessian should be -I:")
print(log_density_hessian(ptr,x)$hess)
