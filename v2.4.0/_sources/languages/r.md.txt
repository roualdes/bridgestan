# R Interface

---

## Installation

This assumes you have followed the [Getting Started guide](../getting-started.rst)
to install BridgeStan's pre-requisites and downloaded a copy of the BridgeStan source code.


```R
devtools::install_github("https://github.com/roualdes/bridgestan", subdir="R")
```

Or, since you have already downloaded the repository, you can run

```R
install.packages(file.path(getwd(),"R"), repos=NULL, type="source")
```
from the BridgeStan folder.

Note that the R package depends on R 3+ and R6, and will install R6 if it is not
already installed.

```{note}
Mac users have reported issues when using a copy of R installed from [conda-forge](https://conda-forge.org/). If you encounter an issue, you may need to use R from the official [R project website](https://www.r-project.org/) or a system package manager like `brew`.
```

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
