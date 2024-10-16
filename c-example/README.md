# BridgeStan from C

[View the C API documentation online](https://roualdes.github.io/bridgestan/latest/languages/c-api.html).

This shows how one could write a C program which calls BridgeStan.

Any compiled language with a C foreign function interface and
the ability to link against C libraries should be able to work similarly.

## Binding a specific model at build time

### Dynamic linking

It is possible to link against the same `name_model.so` object used by the other
BridgeStan interfaces. This creates a dynamic link.

```shell
make example # by default links against full_model
./example
```

This should output:

```
This model's name is full_model.
It has 1 parameters.
```

You can change the test model by specifying `MODEL` on the command line.
Models which require data can have a path passed in as the first argument.

```shell
make MODEL=multi example
./example ../test_models/multi/multi.data.json
```

This will output

```
This model's name is multi_model.
It has 10 parameters.
```

#### Notes

The basic steps for using with a generic BridgeStan model are

1. Include `bridgestan.h` in your source.
2. At compile time, provide a path to the folder containing the model you need,
   and link against it. On most platforms, this will require renaming the shared object
   file to comply with certain naming conventions. For example, `gcc` requires the library
   be prefixed with "lib".
   The Makefile in this folder does that by making a copy.

This dynamic linking will work on Windows, but Windows does not record the paths
of shared libraries in executables. As such, `libNAME_model.dll` will need to be
in the same folder as the executable, or on your `PATH`.

On all platforms, dynamic linking requires that the original `libNAME_model.(so|dll)` object
still exist when the executable is run.

### Static linking

The makefile here also shows how to create a `.a` static library using the BridgeStan
source, and then compiling an executable which is independent of the location of the model.
This can use the same source file as dynamic linking, it is just the build which differs.

```shell
make example_static
rm ../test_models/full/full_model.a # statically linked executable doesn't need library around
./example_static
```

Will output the same as the above. Note that some Stan libraries such as TBB
are still dynamically linked.

`MODEL` can also be used to specify which model to statically link.

## Loading a model at runtime

The `runtime_loading.c` file shows how to use `dlfcn.h` on Unix and
`libloaderapi.h` on Windows to load a model at runtime.
This is useful if you want to load a model based on user input, or if you want to
load different models in the same executable.

```shell
make example_runtime
./example_runtime ../test_models/full/full_model.so
```

will output

```
This model's name is full_model.
It has 1 parameters.
```

The same executable can be passed different models without recompiling.
