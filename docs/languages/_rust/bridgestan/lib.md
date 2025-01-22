# Crate `bridgestan`

:::::::{rust:crate} bridgestan
:index: 0

  :::
  :::
:::{rust:use} bridgestan
:used_name: self

:::
:::{rust:use} bridgestan
:used_name: crate

:::
:::{rust:use} bridgestan::BridgeStanError
:used_name: BridgeStanError

:::
:::{rust:use} bridgestan::Model
:used_name: Model

:::
:::{rust:use} bridgestan::Rng
:used_name: Rng

:::
:::{rust:use} bridgestan::StanLibrary
:used_name: StanLibrary

:::
:::{rust:use} bridgestan::compile_model
:used_name: compile_model

:::
:::{rust:use} bridgestan::download_bridgestan_src
:used_name: download_bridgestan_src

:::
:::{rust:use} bridgestan::open_library
:used_name: open_library

:::

:::{rubric} Variables
:::

::::::{rust:variable} bridgestan::VERSION
:index: 0
:vis: pub
:toc: const VERSION
:layout: [{"type":"keyword","value":"const"},{"type":"space"},{"type":"name","value":"VERSION"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"}]

  :::
  :::
::::::

:::{rubric} Functions
:::

::::::{rust:function} bridgestan::compile_model
:index: 0
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"compile_model"},{"type":"punctuation","value":"("},{"type":"name","value":"bs_path"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"link","value":"Path","target":"Path"},{"type":"punctuation","value":", "},{"type":"name","value":"stan_file"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"link","value":"Path","target":"Path"},{"type":"punctuation","value":", "},{"type":"name","value":"stanc_args"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"make_args"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"PathBuf","target":"PathBuf"},{"type":"punctuation","value":">"}]

  :::
  Compile a Stan Model. Requires a path to the BridgeStan sources (can be
  downloaded with [`download_bridgestan_src`](crate::download_bridgestan_src)
   if that feature is enabled), a path to the `.stan` file, and
  additional arguments for the Stan compiler and the `make` command.
  
  
  :::
::::::
::::::{rust:function} bridgestan::download_bridgestan_src
:index: 0
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"download_bridgestan_src"},{"type":"punctuation","value":"("},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"PathBuf","target":"PathBuf"},{"type":"punctuation","value":">"}]

  :::
  Download and unzip the BridgeStan source distribution for this version
  to `~/.bridgestan/bridgestan-$VERSION`.
  Requires feature `download-bridgestan-src`.
  
  
  :::
::::::
::::::{rust:function} bridgestan::open_library
:index: 0
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"open_library"},{"type":"punctuation","value":"<"},{"type":"name","value":"P"},{"type":"punctuation","value":": "},{"type":"link","value":"AsRef","target":"AsRef"},{"type":"punctuation","value":"<"},{"type":"link","value":"OsStr","target":"OsStr"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"punctuation","value":"("},{"type":"name","value":"path"},{"type":"punctuation","value":": "},{"type":"link","value":"P","target":"P"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"}]

  :::
  Open a compiled Stan library.
  
  The library should have been compiled with BridgeStan,
  with the same version as the Rust library.
  
  
  :::
::::::

:::{rubric} Enums
:::

::::::{rust:enum} bridgestan::BridgeStanError
:index: 1
:vis: pub
:layout: [{"type":"keyword","value":"enum"},{"type":"space"},{"type":"name","value":"BridgeStanError"}]

  :::
  Error type for bridgestan interface
  
  
  :::
:::::{rust:struct} bridgestan::BridgeStanError::InvalidLibrary
:index: 2
:vis: pub
:toc: InvalidLibrary
:layout: [{"type":"name","value":"InvalidLibrary"},{"type":"punctuation","value":"("},{"type":"link","value":"LoadingError","target":"LoadingError"},{"type":"punctuation","value":")"}]

  :::
  The provided library could not be loaded.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::BadLibraryVersion
:index: 2
:vis: pub
:toc: BadLibraryVersion
:layout: [{"type":"name","value":"BadLibraryVersion"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":", "},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  The version of the Stan library does not match the version of the rust crate.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::StanThreads
:index: 2
:vis: pub
:toc: StanThreads
:layout: [{"type":"name","value":"StanThreads"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  The Stan library could not be loaded because it was compiled without threading support.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::InvalidString
:index: 2
:vis: pub
:toc: InvalidString
:layout: [{"type":"name","value":"InvalidString"},{"type":"punctuation","value":"("},{"type":"link","value":"Utf8Error","target":"Utf8Error"},{"type":"punctuation","value":")"}]

  :::
  Stan returned a string that couldn't be decoded using UTF8.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::ConstructFailed
:index: 2
:vis: pub
:toc: ConstructFailed
:layout: [{"type":"name","value":"ConstructFailed"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  The model could not be instantiated, possibly because if incorrect data.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::EvaluationFailed
:index: 2
:vis: pub
:toc: EvaluationFailed
:layout: [{"type":"name","value":"EvaluationFailed"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  Stan returned an error while computing the density.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::SetCallbackFailed
:index: 2
:vis: pub
:toc: SetCallbackFailed
:layout: [{"type":"name","value":"SetCallbackFailed"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  Setting a print-callback failed.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::ModelCompilingFailed
:index: 2
:vis: pub
:toc: ModelCompilingFailed
:layout: [{"type":"name","value":"ModelCompilingFailed"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  Compilation of the Stan model shared object failed.
  :::
:::::
:::::{rust:struct} bridgestan::BridgeStanError::DownloadFailed
:index: 2
:vis: pub
:toc: DownloadFailed
:layout: [{"type":"name","value":"DownloadFailed"},{"type":"punctuation","value":"("},{"type":"link","value":"String","target":"String"},{"type":"punctuation","value":")"}]

  :::
  Downloading BridgeStan's C++ source code from GitHub failed.
  :::
:::::
::::::

:::{rubric} Structs and Unions
:::

::::::{rust:struct} bridgestan::Model
:index: 1
:vis: pub
:toc: struct Model
:layout: [{"type":"keyword","value":"struct"},{"type":"space"},{"type":"name","value":"Model"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"}]

  :::
  A Stan model instance with data
  
  
  :::

:::{rubric} Implementations
:::

:::::{rust:impl} bridgestan::Model
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Model","target":"Model"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Model

  :::
  :::

:::{rubric} Functions
:::

::::{rust:function} bridgestan::Model::info
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"info"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"punctuation","value":"&"},{"type":"link","value":"CStr","target":"CStr"}]

  :::
  Return information about the compiled model
  :::
::::
::::{rust:function} bridgestan::Model::log_density
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"log_density"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"propto"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"jacobian"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":">"}]

  :::
  Compute the log of the prior times likelihood density
  
  Drop jacobian determinant terms of the transformation from unconstrained
  to the constrained space if `jacobian == false` and drop terms
  of the density that do not depend on the parameters if `propto == true`.
  :::
::::
::::{rust:function} bridgestan::Model::log_density_gradient
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"log_density_gradient"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"propto"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"jacobian"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"grad"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":">"}]

  :::
  Compute the log of the prior times likelihood density and its gradient
  
  Drop jacobian determinant terms of the transformation from unconstrained
  to the constrained space if `jacobian == false` and drop terms
  of the density that do not depend on the parameters if `propto == true`.
  
  The gradient of the log density will be stored in `grad`.
  
  *Panics* if the provided buffer has incorrect shape. The gradient buffer `grad`
  must have length [`self.param_unc_num()`](Model::param_unc_num).
  :::
::::
::::{rust:function} bridgestan::Model::log_density_hessian
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"log_density_hessian"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"propto"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"jacobian"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"grad"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"hessian"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":">"}]

  :::
  Compute the log of the prior times likelihood density and its gradient and hessian.
  
  Drop jacobian determinant terms of the transformation from unconstrained
  to the constrained space if `jacobian == false` and drop terms
  of the density that do not depend on the parameters if `propto == true`.
  
  The gradient of the log density will be stored in `grad`, the
  hessian is stored in `hessian`.
  
  *Panics* if the provided buffers have incorrect shapes. The gradient buffer `grad`
  must have length [`self.param_unc_num()`](Model::param_unc_num) and the `hessian`
  buffer must have length [`self.param_unc_num()`](Model::param_unc_num) `*`
  [`self.param_unc_num()`](Model::param_unc_num).
  :::
::::
::::{rust:function} bridgestan::Model::log_density_hessian_vector_product
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"log_density_hessian_vector_product"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"v"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"propto"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"jacobian"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"hvp"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":">"}]

  :::
  Compute the log of the prior times likelihood density the product of
  the Hessian and specified vector.
  
  Drop jacobian determinant terms of the transformation from unconstrained
  to the constrained space if `jacobian == false` and drop terms
  of the density that do not depend on the parameters if `propto == true`.
  
  The product of the Hessian of the log density and the provided vector
   will be stored in `hvp`.
  
  *Panics* if the provided buffer has incorrect shape. The buffer `hvp`
  must have length [`self.param_unc_num()`](Model::param_unc_num).
  :::
::::
::::{rust:function} bridgestan::Model::name
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"name"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"},{"type":"punctuation","value":">"}]

  :::
  Return the name of the model or error if UTF decode fails
  :::
::::
::::{rust:function} bridgestan::Model::new
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"new"},{"type":"punctuation","value":"<"},{"type":"name","value":"D"},{"type":"punctuation","value":": "},{"type":"link","value":"AsRef","target":"AsRef"},{"type":"punctuation","value":"<"},{"type":"link","value":"CStr","target":"CStr"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"punctuation","value":"("},{"type":"name","value":"lib"},{"type":"punctuation","value":": "},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":", "},{"type":"name","value":"data"},{"type":"punctuation","value":": "},{"type":"link","value":"Option","target":"Option"},{"type":"punctuation","value":"<"},{"type":"link","value":"D","target":"D"},{"type":"punctuation","value":">"},{"type":"punctuation","value":", "},{"type":"name","value":"seed"},{"type":"punctuation","value":": "},{"type":"link","value":"u32","target":"u32"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"Self","target":"Self"},{"type":"punctuation","value":">"}]

  :::
  Create a new instance of the compiled Stan model.
  
  Data is specified as a JSON file at the given path, a JSON string literal,
  or empty for no data. The seed is used if the model has RNG functions in
  the `transformed data` section.
  :::
::::
::::{rust:function} bridgestan::Model::new_rng
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"new_rng"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"seed"},{"type":"punctuation","value":": "},{"type":"link","value":"u32","target":"u32"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"&"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"}]

  :::
  Create a new [`Rng`] random number generator from the library underlying this model.
  
  This can be used in [`param_constrain()`](Model::param_constrain()) when values
  from the `generated quantities` block are desired.
  
  This instance can only be used with models from the same
  Stan library. Invalid usage will otherwise result in a
  panic.
  :::
::::
::::{rust:function} bridgestan::Model::param_constrain
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_constrain"},{"type":"punctuation","value":"<"},{"type":"name","value":"R"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"include_tp"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"include_gq"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"out"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"rng"},{"type":"punctuation","value":": "},{"type":"link","value":"Option","target":"Option"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"link","value":"R","target":"R"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"("},{"type":"punctuation","value":")"},{"type":"punctuation","value":">"}]

  :::
  Map a point in unconstrained parameter space to the constrained space.
  
  `theta_unc` must contain the point in the unconstrained parameter space.
  
  If `include_tp` is set the output will also include the transformed
  parameters of the Stan model after the parameters. If `include_gq` is
  set, we also include the generated quantities at the very end.
  
  *Panics* if the provided buffer has incorrect shape. The length of the `out` buffer
  must be [`self.param_num(include_tp, include_gq)`](Model::param_num).
  
  *Panics* if `include_gq` is set but no random number generator is provided.
  :::
::::
::::{rust:function} bridgestan::Model::param_names
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_names"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"include_tp"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"include_gq"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"}]

  :::
  Return a comma-separated sequence of indexed parameter names,
  including the transformed parameters and/or generated quantities
  as specified.
  
  The parameters are returned in the order they are declared.
  Multivariate parameters are return in column-major (more
  generally last-index major) order.  Parameter indices are separated
  with periods (`.`).  For example, `a[3]` is written `a.3` and `b[2, 3]`
  as `b.2.3`.  The numbering follows Stan and is indexed from 1.
  
  If `include_tp` is set the names will also include the transformed
  parameters of the Stan model after the parameters. If `include_gq` is
  set, we also include the names of the generated quantities at
  the very end.
  :::
::::
::::{rust:function} bridgestan::Model::param_num
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_num"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"include_tp"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":", "},{"type":"name","value":"include_gq"},{"type":"punctuation","value":": "},{"type":"link","value":"bool","target":"bool"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"usize","target":"usize"}]

  :::
  Number of parameters in the model on the constrained scale.
  
  Will also count transformed parameters (`include_tp`) and generated
  quantities (`include_gq`) if requested.
  :::
::::
::::{rust:function} bridgestan::Model::param_unc_names
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_unc_names"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"punctuation","value":"&"},{"type":"link","value":"str","target":"str"}]

  :::
  Return a comma-separated sequence of unconstrained parameters.
  Only parameters are unconstrained, so there are no unconstrained
  transformed parameters or generated quantities.
  
  The parameters are returned in the order they are declared.
  Multivariate parameters are return in column-major (more
  generally last-index major) order.  Parameter indices are separated with
  periods (`.`).  For example, `a[3]` is written `a.3` and `b[2,
  3]` as `b.2.3`.  The numbering follows Stan and is indexed from 1.
  :::
::::
::::{rust:function} bridgestan::Model::param_unc_num
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_unc_num"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"usize","target":"usize"}]

  :::
  Return the number of parameters on the unconstrained scale.
  
  In particular, this is the size of the slice required by the `log_density` functions.
  :::
::::
::::{rust:function} bridgestan::Model::param_unconstrain
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_unconstrain"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"theta"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"("},{"type":"punctuation","value":")"},{"type":"punctuation","value":">"}]

  :::
  Map a point in constrained parameter space to the unconstrained space.
  :::
::::
::::{rust:function} bridgestan::Model::param_unconstrain_json
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"param_unconstrain_json"},{"type":"punctuation","value":"<"},{"type":"name","value":"S"},{"type":"punctuation","value":": "},{"type":"link","value":"AsRef","target":"AsRef"},{"type":"punctuation","value":"<"},{"type":"link","value":"CStr","target":"CStr"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"json"},{"type":"punctuation","value":": "},{"type":"link","value":"S","target":"S"},{"type":"punctuation","value":", "},{"type":"name","value":"theta_unc"},{"type":"punctuation","value":": "},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"punctuation","value":"["},{"type":"link","value":"f64","target":"f64"},{"type":"punctuation","value":"]"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"("},{"type":"punctuation","value":")"},{"type":"punctuation","value":">"}]

  :::
  Map a constrained point in json format to the unconstrained space.
  
  The JSON is expected to be in the
  [JSON Format for CmdStan](https://mc-stan.org/docs/cmdstan-guide/json.html).
  A value for each parameter in the Stan program should be provided, with
  dimensions and size corresponding to the Stan program declarations.
  :::
::::
::::{rust:function} bridgestan::Model::ref_library
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"ref_library"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"punctuation","value":"&"},{"type":"link","value":"StanLibrary","target":"StanLibrary"}]

  :::
  Return a reference to the underlying Stan library
  :::
::::
:::::
:::::{rust:impl} bridgestan::Model
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":" + "},{"type":"link","value":"Clone","target":"Clone"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Model","target":"Model"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Model

  :::
  :::

:::{rubric} Functions
:::

::::{rust:function} bridgestan::Model::clone_library_ref
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"clone_library_ref"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"T","target":"T"}]

  :::
  Return a clone of the underlying Stan library
  :::
::::
:::::

:::{rubric} Traits implemented
:::

:::::{rust:impl} bridgestan::Model::Sync
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Sync","target":"Sync"},{"type":"punctuation","value":" + "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Sync","target":"Sync"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Model","target":"Model"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Sync for Model

  :::
  :::
:::::
:::::{rust:impl} bridgestan::Model::Send
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Send","target":"Send"},{"type":"punctuation","value":" + "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Send","target":"Send"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Model","target":"Model"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Send for Model

  :::
  :::
:::::
:::::{rust:impl} bridgestan::Model::Drop
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Drop","target":"Drop"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Model","target":"Model"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Drop for Model

  :::
  :::
:::::
::::::
::::::{rust:struct} bridgestan::Rng
:index: 1
:vis: pub
:toc: struct Rng
:layout: [{"type":"keyword","value":"struct"},{"type":"space"},{"type":"name","value":"Rng"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"}]

  :::
  A random number generator for Stan models.
  This is only used in the [`Model::param_constrain()`](Model::param_constrain) method
  of the model when requesting values from the `generated quantities` block.
  Different threads should use different instances.
  
  
  :::

:::{rubric} Implementations
:::

:::::{rust:impl} bridgestan::Rng
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Rng

  :::
  :::

:::{rubric} Functions
:::

::::{rust:function} bridgestan::Rng::new
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"new"},{"type":"punctuation","value":"("},{"type":"name","value":"lib"},{"type":"punctuation","value":": "},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":", "},{"type":"name","value":"seed"},{"type":"punctuation","value":": "},{"type":"link","value":"u32","target":"u32"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"link","value":"Self","target":"Self"},{"type":"punctuation","value":">"}]

  :::
  :::
::::
:::::

:::{rubric} Traits implemented
:::

:::::{rust:impl} bridgestan::Rng::Sync
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Sync","target":"Sync"},{"type":"punctuation","value":" + "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Sync","target":"Sync"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Sync for Rng

  :::
  :::
:::::
:::::{rust:impl} bridgestan::Rng::Send
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Send","target":"Send"},{"type":"punctuation","value":" + "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Send","target":"Send"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Send for Rng

  :::
  :::
:::::
:::::{rust:impl} bridgestan::Rng::Drop
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"punctuation","value":"<"},{"type":"name","value":"T"},{"type":"punctuation","value":": "},{"type":"link","value":"Borrow","target":"Borrow"},{"type":"punctuation","value":"<"},{"type":"link","value":"StanLibrary","target":"StanLibrary"},{"type":"punctuation","value":">"},{"type":"punctuation","value":">"},{"type":"space"},{"type":"link","value":"Drop","target":"Drop"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"Rng","target":"Rng"},{"type":"punctuation","value":"<"},{"type":"link","value":"T","target":"T"},{"type":"punctuation","value":">"}]
:toc: impl Drop for Rng

  :::
  :::
:::::
::::::
::::::{rust:struct} bridgestan::StanLibrary
:index: 1
:vis: pub
:toc: struct StanLibrary
:layout: [{"type":"keyword","value":"struct"},{"type":"space"},{"type":"name","value":"StanLibrary"}]

  :::
  A loaded shared library for a Stan model
  
  
  :::

:::{rubric} Implementations
:::

:::::{rust:impl} bridgestan::StanLibrary
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"space"},{"type":"link","value":"StanLibrary","target":"StanLibrary"}]
:toc: impl StanLibrary

  :::
  :::

:::{rubric} Functions
:::

::::{rust:function} bridgestan::StanLibrary::set_print_callback
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"set_print_callback"},{"type":"punctuation","value":"("},{"type":"punctuation","value":"&"},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"keyword","value":"self"},{"type":"punctuation","value":", "},{"type":"name","value":"callback"},{"type":"punctuation","value":": "},{"type":"link","value":"StanPrintCallback","target":"StanPrintCallback"},{"type":"punctuation","value":")"},{"type":"space"},{"type":"returns"},{"type":"space"},{"type":"link","value":"Result","target":"Result"},{"type":"punctuation","value":"<"},{"type":"punctuation","value":"("},{"type":"punctuation","value":")"},{"type":"punctuation","value":">"}]

  :::
  Provide a callback function to be called when Stan prints a message
  
  ## Safety
  
  The provided function must never panic.
  
  Since the call is protected by a mutex internally, it does not
  need to be thread safe.
  :::
::::
::::{rust:function} bridgestan::StanLibrary::unload_library
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"fn"},{"type":"space"},{"type":"name","value":"unload_library"},{"type":"punctuation","value":"("},{"type":"keyword","value":"mut"},{"type":"space"},{"type":"keyword","value":"self"},{"type":"punctuation","value":")"}]

  :::
  Unload the Stan library.
  
  ## Safety
  
  There seem to be issues around unloading libraries in threaded
  code that are not fully understood:
  <https://github.com/roualdes/bridgestan/issues/111>
  :::
::::
:::::

:::{rubric} Traits implemented
:::

:::::{rust:impl} bridgestan::StanLibrary::Send
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"space"},{"type":"link","value":"Send","target":"Send"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"StanLibrary","target":"StanLibrary"}]
:toc: impl Send for StanLibrary

  :::
  :::
:::::
:::::{rust:impl} bridgestan::StanLibrary::Sync
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"unsafe"},{"type":"space"},{"type":"keyword","value":"impl"},{"type":"space"},{"type":"link","value":"Sync","target":"Sync"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"StanLibrary","target":"StanLibrary"}]
:toc: impl Sync for StanLibrary

  :::
  :::
:::::
:::::{rust:impl} bridgestan::StanLibrary::Drop
:index: -1
:vis: pub
:layout: [{"type":"keyword","value":"impl"},{"type":"space"},{"type":"link","value":"Drop","target":"Drop"},{"type":"space"},{"type":"keyword","value":"for"},{"type":"space"},{"type":"link","value":"StanLibrary","target":"StanLibrary"}]
:toc: impl Drop for StanLibrary

  :::
  :::
:::::
::::::
