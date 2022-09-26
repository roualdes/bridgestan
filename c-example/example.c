#include "bridgestan.h"
#include <stdio.h>

int main(int argc, char** argv) {
  char* data;
  if (argc > 1) {
    data = argv[1];
  } else {
    data = "";
  }
  model_rng* model = construct(data, 123, 0);
  if (!model) {
    return 1;
  }
  printf("This model's name is %s.\n", name(model));
  printf("It has %d parameters.\n", param_num(model, 0, 0));
  return destruct(model);
}
