/* Directly expands the locked generated-code macro with a stub handler.
 * No allocation writes, production runtime, or actual GC are executed. */
#include "gambit.h"
#undef ___LBL
#undef ___JUMPEXTPRM
#define ___LBL(x) (x)
#define ___JUMPEXTPRM(a,b) do { ++handler_calls; } while (0);

struct processor { ___WORD *heap_limit; int temp1; int handler_heap_limit; };

int main(void)
{
  ___WORD words[8] = {0};
  struct processor processor = {words + 4, 0, 0};
  struct processor *___ps = &processor;
  ___WORD *___hp = words + 4;
  int handler_calls = 0;
  int size_evaluations = 0;

  /* The real macro expands without evaluating m. The physical remainder in
   * this fixture is four words, smaller than the 8,195-word test request. */
  ___CHECK_HEAP(7, (++size_evaluations, 8195))
  if (handler_calls != 0 || size_evaluations != 0) return 1;

  /* Calibration: moving the cursor past the poll limit takes the handler. */
  ___hp = words + 5;
  ___CHECK_HEAP(9, (++size_evaluations, 1))
  if (handler_calls != 1 || ___ps->temp1 != 9 || size_evaluations != 0) return 2;
  return 0;
}
