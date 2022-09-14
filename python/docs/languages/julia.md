
<a id='Julia-Interface:-bridgestan.jl'></a>

<a id='Julia-Interface:-bridgestan.jl-1'></a>

# Julia Interface: bridgestan.jl


% NB: This file is generated from the one in julia/docs/src/julia.md

<a id='BridgeStan.StanModel' href='#BridgeStan.StanModel'>#</a>
**`BridgeStan.StanModel`** &mdash; *Type*.



```julia
StanModel(stanlib_, datafile_="", seed_=204, chain_id_=0)
```

A StanModel instance encapsulates a Stan model instantiated with data.

The constructor a Stan model from the supplied library file path and data file path. If seed or chain_id are supplied, these are used to initialize the RNG used by the model.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/b663d2c04fecb2d99dd35c4c7f5008c42c6b4346/julia/src/BridgeStan.jl#L23-L30' class='documenter-source'>source</a><br>

<a id='BridgeStan.name-Tuple{StanModel}' href='#BridgeStan.name-Tuple{StanModel}'>#</a>
**`BridgeStan.name`** &mdash; *Method*.



```julia
name(sm)
```

Return the name of the model `sm`


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/b663d2c04fecb2d99dd35c4c7f5008c42c6b4346/julia/src/BridgeStan.jl#L79-L83' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_num-Tuple{StanModel}' href='#BridgeStan.param_num-Tuple{StanModel}'>#</a>
**`BridgeStan.param_num`** &mdash; *Method*.



```julia
param_num(sm; include_tp=false, include_gq=false)
```

Return the number of (constrained) parameters in the model.

This is the total of all the sizes of items declared in the `parameters` block of the model. If `include_tp` or `include_gq` are true, items declared in the `transformed parameters` and `generate quantities` blocks are included, respectively.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/b663d2c04fecb2d99dd35c4c7f5008c42c6b4346/julia/src/BridgeStan.jl#L94-L103' class='documenter-source'>source</a><br>

<a id='BridgeStan.param_unc_num-Tuple{StanModel}' href='#BridgeStan.param_unc_num-Tuple{StanModel}'>#</a>
**`BridgeStan.param_unc_num`** &mdash; *Method*.



```julia
param_unc_num(sm)
```

Return the number of unconstrained parameters in the model.

This function is mainly different from `param_num` when variables are declared with constraints. For example, `simplex[5]` has a constrained size of 5, but an unconstrained size of 4.


<a target='_blank' href='https://github.com/roualdes/bridgestan/blob/b663d2c04fecb2d99dd35c4c7f5008c42c6b4346/julia/src/BridgeStan.jl#L116-L124' class='documenter-source'>source</a><br>

