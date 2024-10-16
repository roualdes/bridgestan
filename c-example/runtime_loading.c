#include "bridgestan.h"
#include <stdio.h>

#ifdef _WIN32
// hacky way to get dlopen and friends on Windows

#include <libloaderapi.h>
#include <errhandlingapi.h>
#define dlopen(lib, flags) LoadLibraryA(lib)
#define dlsym(handle, sym) GetProcAddress(handle, sym)

char* dlerror() {
  DWORD err = GetLastError();
  int length = snprintf(NULL, 0, "%d", err);
  char* str = malloc(length + 1);
  snprintf(str, length + 1, "%d", err);
  return str;
}
#else
#include <dlfcn.h>
#endif

#if __STDC_VERSION__ < 202000
#define typeof __typeof__
#endif

int main(int argc, char** argv) {
  char* lib;
  char* data;

  // require at least the library name
  if (argc > 2) {
    lib = argv[1];
    data = argv[2];
  } else if (argc > 1) {
    lib = argv[1];
    data = NULL;
  } else {
    fprintf(stderr, "Usage: %s <library> [data]\n", argv[0]);
    return 1;
  }

  // load the shared library
  void* handle = dlopen(lib, RTLD_LAZY);
  if (!handle) {
    fprintf(stderr, "Error: %s\n", dlerror());
    return 1;
  }

  int major = *(int*)dlsym(handle, "bs_major_version");
  int minor = *(int*)dlsym(handle, "bs_minor_version");
  int patch = *(int*)dlsym(handle, "bs_patch_version");
  fprintf(stderr, "Using BridgeStan version %d.%d.%d\n", major, minor, patch);

  // Get function pointers. Uses C23's typeof to re-use bridgestan.h
  // definitions. We could also write out the types and not include bridgestan.h
  typeof(&bs_model_construct) bs_model_construct
      = dlsym(handle, "bs_model_construct");
  typeof(&bs_free_error_msg) bs_free_error_msg
      = dlsym(handle, "bs_free_error_msg");
  typeof(&bs_model_destruct) bs_model_destruct
      = dlsym(handle, "bs_model_destruct");
  typeof(&bs_name) bs_name = dlsym(handle, "bs_name");
  typeof(&bs_param_num) bs_param_num = dlsym(handle, "bs_param_num");

  if (!bs_model_construct || !bs_free_error_msg || !bs_model_destruct ||
      !bs_name || !bs_param_num) {
    fprintf(stderr, "Error: %s\n", dlerror());
    return 1;
  }

  // from here on, the code is exactly the same as example.c

  // this could potentially error, and we may get information back about why.
  char* err;
  bs_model* model = bs_model_construct(data, 123, &err);
  if (!model) {
    if (err) {
      printf("Error: %s", err);
      bs_free_error_msg(err);
    }
    return 1;
  }

  printf("This model's name is %s.\n", bs_name(model));
  printf("It has %d parameters.\n", bs_param_num(model, 0, 0));

  bs_model_destruct(model);
  return 0;
}
