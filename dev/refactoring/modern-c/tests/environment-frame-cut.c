/* Independent coordinates for the frozen req1 heap-check label6 descriptor.
 * The descriptor comes from generated _eval.c, not CHECK_HEAP's unused mask.
 * This qualifies one configured layout, not arbitrary modules or C pointers. */
#define ___VERSION 409008
#include "gambit.h"

#define CUT_FS ___RETI_CFS_TO_FS(0)
#define CUT_MAP 0x3fUL
#define CUT_REG(i) (___FRAME_SPACE(CUT_FS) + ___RETI_RA - ___NB_GVM_REGS + (i))
#define CUT_LIVE(i) ((CUT_MAP >> (CUT_REG(i)-1)) & 1UL)

_Static_assert(___NB_GVM_REGS == 5, "selected generated register cohort");
_Static_assert(CUT_REG(0) == 1, "saved R0 is the separately traversed link");
_Static_assert(CUT_REG(1) == 2, "environment R1 reaches ordinary stack slot2");
_Static_assert(CUT_REG(4) <= CUT_FS, "saved registers stay inside the frame");
_Static_assert(CUT_LIVE(1), "environment root is in the label6 map");
_Static_assert(CUT_LIVE(2), "body code root is in the label6 map");
_Static_assert(CUT_LIVE(3), "self root is in the label6 map");
_Static_assert(CUT_LIVE(4), "parent root is in the label6 map");
