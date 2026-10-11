#include <stdio.h>
#include "gambit.h"

int main(void) {
  ___SCMOBJ inputs[] = {___FIX(___MIN_FIX), ___FIX(___MAX_FIX),
    ___FIX(-1), ___FIX(0), ___FIX(1), ___FIX(___MIN_FIX + 1)};
  int failures = 0;
  for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
    for (int mode = 0; mode < 3; ++mode) {
      ___SCMOBJ input = inputs[i];
      ___SCMOBJ output = mode == 2 ? input : ___FIX(2);
      int success;
      if (mode == 0)
        success = ___FIXMULPCONSTY_NOTFALSEP(output, input, ___FIX(-1));
      else if (mode == 1)
        success = ___FIXMULPCONSTX_NOTFALSEP(output, ___FIX(-1), input);
      else
        success = ___FIXMULPCONSTY_NOTFALSEP(output, output, ___FIX(-1));
      int expected = input != ___FIX(___MIN_FIX);
      if (success != expected || (expected && output != ___FIXNEG(input))) {
        printf("CHECKED-NEGATE-FAIL INPUT %u MODE %d SUCCESS %d EXPECTED %d\n",
               i, mode, success, expected);
        ++failures;
      }
    }
  }
  if (failures) return 1;
  puts("CHECKED-NEGATE-OK 18 CASES");
  return 0;
}
