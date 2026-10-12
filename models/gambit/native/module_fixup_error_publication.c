/* Compile against the exact locked setup.c through the configured GNU driver.
   No setup or allocation is performed: each first call rejects metadata. */
#include "setup.c"
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  fem_context context;
  ___module_struct module;
  memset(&context, 0, sizeof context);
  memset(&module, 0, sizeof module);
  ___SCMOBJ expected;
  if (strcmp(argv[1], "old-version") == 0) {
    module.version = ___VERSION - 1;
    expected = ___FIX(___MODULE_VERSION_TOO_OLD_ERR);
  } else if (strcmp(argv[1], "new-version") == 0) {
    module.version = ___VERSION + 1;
    expected = ___FIX(___MODULE_VERSION_TOO_NEW_ERR);
  } else if (strcmp(argv[1], "layout") == 0) {
    module.version = ___VERSION;
    expected = ___FIX(___MODULE_INCOMPATIBILITY_ERR);
  } else return 2;
  ___SCMOBJ first = setup_module_fixup(&context, &module);
  int published = (module.flags & ___SETUP_FIXUP_DONE) != 0;
  ___SCMOBJ second = setup_module_fixup(&context, &module);
  printf("FIXUP-OBSERVATION:case=%s,first=%ld,expected=%ld,done=%d,second=%ld\n",
    argv[1], (long)___INT(first), (long)___INT(expected), published,
    (long)___INT(second));
  if (first != expected) return 3;
  if (published || second != expected) return 4;
  return 0;
}
