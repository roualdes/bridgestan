#include "bridgestan.h"
#include <stdio.h>

int main() {
  model_rng* model = construct("", 123, 0);
  if (!model){
    return 1;
  }
  printf("This model's name is %s.\n", name(model));
  printf("It has %d parameters.\n", param_num(model, 0, 0));
  return destruct(model);
}
