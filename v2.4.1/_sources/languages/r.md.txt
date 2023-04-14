# R Interface

---

## Installation

```{note}
Mac users have reported issues when using a copy of R installed from [conda-forge](https://conda-forge.org/). If you encounter an issue, you may need to use R from the official [R project website](https://www.r-project.org/) or a system package manager like `brew`.
```

### From inside R

While BridgeStan is not available on CRAN, you can install the R package from the source code
using the `remotes` package:

```R
remotes::install_github("https://github.com/roualdes/bridgestan", subdir="R")
```

To install a specific version of BridgeStan you can use the argument `ref`,
for example, {{ "`ref=\"vVERSION\"`".replace("VERSION", env.config.version) }}.

The first time you compile a model, the BridgeStan source code for your current version
will be downloaded and placed in :file:`~/.bridgestan/`.
If you prefer to use a source distribution of BridgeStan, consult the following section.

Note that the system pre-requisites from the [Getting Started guide](../getting-started.rst)
are still required and will not be automatically installed by this method.

### From Source

This assumes you have followed the [Getting Started guide](../getting-started.rst)
to install BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.

To install the R package from the source code, run:
```R
install.packages(file.path(getwd(),"R"), repos=NULL, type="source")
```
from the BridgeStan folder.

To use the BridgeStan source you've manually downloaded instead of
one the package will download for you, you must use
[`set_bridgestan_path()`](#function-set-bridgestan-path) or the `$BRIDGESTAN`
environment variable.

Note that the R package depends on R 3+ and R6, and will install R6 if it is not
already installed.

## Example Program

An example program is provided alongside the R interface code in `example.R`:

<details>
<summary><a>Show example.R</a></summary>

```{literalinclude} ../../R/example.R
:language: R
```

</details>

## API Reference


```{include} ./_r/StanModel.md
```

### Compilation utilities

```{include} ./_r/compile_model.md
```

```{include} ./_r/set_bridgestan_path.md
```
