/* The maintained body is included verbatim; this declaration supplies ACSL. */
/*@ requires \true;
    assigns \nothing;
    ensures capacity_equivalence: (\result != 0) <==> (roots > 0 && copies > 0 && (integer)roots + copies <= pool);
*/
static inline int ___gc_copy_plan_fits(int roots,int copies,int pool);
#include "fits.inc"
