/* The maintained body is included verbatim; this declaration supplies ACSL. */
/*@ requires roots == 1 && copies == 1 && pool == 1;
    assigns \nothing;
    ensures deliberately_wrong_postcondition: \result == 1;
*/
static inline int ___gc_copy_plan_fits(int roots,int copies,int pool);
#include "fits.inc"
