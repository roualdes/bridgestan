#include <string.h>

// compile: gcc -fpic -shared -o test.so test.c
// something like this is why we need to set PACKAGE in R
// dyn.load('./test.so') would break all calls to name() otherwise

const char* out = "test me";

void name_R(void** unused, char const** name_out){
  *name_out = out;
}
