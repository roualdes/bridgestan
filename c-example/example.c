#include "bridgestan.h"
#include <stdio.h>

int main(int argc, char** argv) {
  printf("Using BridgeStan version %d.%d.%d\n", bs_major_version,
         bs_minor_version, bs_patch_version);

  char* data;
  if (argc > 1) {
    data = argv[1];
  } else {
    data = "";
  }
  bs_model_rng* model = bs_construct(data, 123, 0);
  if (!model) {
    return 1;
  }
  printf("This model's name is %s.\n", bs_name(model));
  printf("It has %d parameters.\n", bs_param_num(model, 0, 0));
  return bs_destruct(model);
}
