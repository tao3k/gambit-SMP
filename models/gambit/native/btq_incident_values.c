/* Classify captured words only; never dereference an incident address. */
#include "gambit.h"
#include <stdint.h>
#include <stdio.h>

#define CHILD UINT64_C(0xffffd4ffffffffff)
#define SIBLING UINT64_C(0x923e8b031)

_Static_assert(sizeof(___SCMOBJ) == 8, "incident word width");
_Static_assert(___TB == 3, "configured tag width");
_Static_assert(___tSTRUCTURE == 1, "configured structure reference tag");
_Static_assert(___TYP(SIBLING) == ___tSTRUCTURE, "sibling tag only, not object validity");
_Static_assert(___TYP(CHILD) == 7, "captured child tag");
_Static_assert(___TYP(CHILD) != ___tSTRUCTURE, "child cannot be a correctly tagged BTQ node");
_Static_assert(___TYP(CHILD) == ___tFLONUM, "same tag bits, not a valid flonum object");
_Static_assert((uint64_t)(___SCMOBJ)___ABSENT != CHILD, "not the ABSENT immediate");
_Static_assert(CHILD + 39 == UINT64_C(0xffffd50000000026), "captured fault address");
_Static_assert((SIBLING + 63) % 8 == 0, "preceding field load is word aligned");
_Static_assert(___HD_TYP(CHILD + ___FORW - ___tSTRUCTURE) != ___FORW,
               "reconstructing a forwarding header from this child is not FORW");
_Static_assert(___TYP(___FAL) != ___TYP(CHILD) &&
               ___TYP(___TRU) != ___TYP(CHILD) &&
               ___TYP(___ABSENT) != ___TYP(CHILD),
               "captured child is not an ordinary tree boolean or ABSENT");

int main(void)
{
  /* All valid relocation destinations preserve the reference's type tag.
     Even a wrong/stale destination alone cannot change STRUCTURE to tag 7. */
  const ___WORD headers[] = {
    ___TAG((___WORD *)UINT64_C(0x1000), ___FORW),
    ___TAG((___WORD *)UINT64_C(0x2000), ___FORW)
  };
  for (unsigned int i = 0; i < sizeof(headers) / sizeof(headers[0]); i++) {
    ___WORD rewritten = ___TAG(___UNTAG_AS(headers[i], ___FORW), ___TYP(SIBLING));
    if (___TYP(rewritten) != ___tSTRUCTURE)
      return 1;
  }
  puts("BTQ-INCIDENT-TAG-AND-FORWARDING-OK");
  return 0;
}
