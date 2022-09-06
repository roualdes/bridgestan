/**
Unlike Python or Julia, dynamic loading in R is not namespaced
by default. All DLL objects are loaded into the global namespace,
meaning collisions are possible if you are not careful.

This exists so we can call dyn.load('./test_collisions.so')
in R. If we were not careful (e.g. did not use the PACKAGE argument
religiously) then this would overwrite the function exposed
by BridgeStan.

*/

#include <string.h>

const char *out = "test me";

void name_R(void **unused, char const **name_out)
{
  *name_out = out;
}
