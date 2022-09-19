# BridgeStan from C

This shows how one could write a C program which calls BridgeStan.

Any compiled language with a C foreign function interface and
the ability to link against C libraries should be able to work similarly.

## Usage - dynamic linking

It is possible to link against the same `name_model.so` object used by the other
BridgeStan interfaces. This creates a dynamic link.

```shell
make example
./example
```

This should output:

```
This model's name is full_model.
It has 1 parameters.
```

### Notes

The basic steps for using with a generic BridgeStan model are

1. Include `bridgestan.h` in your source.
2. At compile time, provide a path the model you need and link against it.
   On some most platforms, this will require renaming to comply with certain naming
   conventions. For example, `gcc` requires the library be prefixed with "lib".
   The Makefile in this folder does that by making a copy.

This dynamic linking will work on Windows, but Windows does not record the paths
of shared libraries in executables. As such, `full_model.so` will need to be
in the same folder as the executable, or on your `PATH`.

On all platforms, dynamic linking requires that the original `name_model.so` object
still exist when the executable is run.

## Usage - static linking

The makefile here also shows how to create a `.a` static library using the BridgeStan
source, and then compiling an executable which is independent of the location of the model.
This can use the same source file as dynamic linking, it is just the build which differs.

```shell
make example_static
rm ../stan/full/full_model.a # statically linked executable doesn't need library around
./example_static
```

Will output the same as the above. Note that some Stan libraries such as TBB
are still dynamically linked.
