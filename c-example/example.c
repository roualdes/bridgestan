#include "bridgestan.h"
#include <stdio.h>

int main(int argc, char** argv) {
  printf("Using BridgeStan version %d.%d.%d\n", bs_major_version,
         bs_minor_version, bs_patch_version);

  char* data;
  if (argc > 1) {
    data = argv[1];
  } else {
    data = NULL;
  }

  // this could potentially error, and we may get information back about why.
  char* err;
  bs_model_rng* model = bs_construct(data, 123, 0, &err);
  if (!model) {
    if (err) {
      printf("Error: %s", err);
      bs_free_error_msg(err);
    }
    return 1;
  }

  printf("This model's name is %s.\n", bs_name(model));
  printf("It has %d parameters.\n", bs_param_num(model, 0, 0));

  bs_destruct(model);
  return 0;
}
