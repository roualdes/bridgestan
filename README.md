# BridgeStan

A bridge from Julia/Python to log density and gradients from Stan programs via C.

## Use

First compile a Stan model, as

```
$ cd bridgestan
$ CMDSTAN=/Users/ez/cmdstan/ make -j2 stan/multi/multi
```

To get the lastest `develop` version of the CmdStan repo run

```
$ clone https://github.com/stan-dev/cmdstan.git
$ cd cmdstan
$ make stan-update
```

Then follow along in either `example.py` or `example.jl`, updating paths within
the Python or Julia code as necessary.


## Acknowledgements

Much of this project came from Bob Carpenter's [Stan Model
Server](https://github.com/bob-carpenter/stan-model-server/).
