/* The maintained body is included verbatim; this declaration supplies ACSL. */
/*@ requires roots > 0 && roots < 0;
    assigns \nothing;
    ensures unreachable_postcondition: \result == 1;
*/
static inline int ___gc_copy_plan_fits(int roots,int copies,int pool);
#include "fits.inc"
