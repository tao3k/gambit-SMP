/* Real production functions are projected verbatim. No allocator, collector,
 * section or runtime exception path is reimplemented by this environment. */
typedef long ___WORD;
typedef unsigned long ___UWORD;
typedef int ___BOOL;
long nondet_long(void);
#define CHECK(p,n) __CPROVER_assert((p),(n))
#define ASSUME(p) __CPROVER_assume(p)
#include "object-layout.inc"
#include "pair-layout.inc"
#include "native-limits.inc"
#include "signed-sum.inc"
#include "fast-demand.inc"
#include "batch-demand.inc"

void demand_contract(void)
{
  long pending=nondet_long(), prefix=nondet_long();
  long fast=-17, full=-19;
  int fast_ok=rest_fast_words(pending,&fast);
  int full_ok=rest_batch_words(pending,prefix,&full);
  CHECK(fast_ok || fast==-17,"demand.fast-failure-preserves-output");
  CHECK(full_ok || full==-19,"demand.full-failure-preserves-output");
  CHECK(pending>=0 || (!fast_ok && !full_ok),"demand.negative-pending-refused");
  CHECK(prefix>=0 || !full_ok,"demand.negative-prefix-refused");
  if (full_ok) {
    CHECK(fast_ok,"demand.full-implies-fast-representable");
    CHECK(full-fast==prefix+___VECTOR_BODY,"demand.path-specific-difference");
    CHECK(full>fast,"demand.full-is-not-fast");
  }
  /* Caller-domain restriction only for this reachability inequality. Native
   * admission, alignment, roots and the real callee constraints remain open. */
  if (pending>=0 && pending<=___MAX_NB_ARGS && prefix>=0 && prefix<=___MAX_NB_PARMS) {
    CHECK(fast_ok && full_ok,"demand.legal-domain-representable");
    CHECK(full<(___MSECTION_SIZE>>1)-___MSECTION_FUDGE,
          "demand.legal-domain-fits-fresh-soft-section");
  }
}

void conflated_budget_control(void)
{
  long fast=-17, full=-19;
  CHECK(rest_fast_words(2,&fast),"control.fast-defined");
  CHECK(rest_batch_words(2,1,&full),"control.full-defined");
  /* Deliberately false hypothesis. Its qualified counterexample is evidence
   * against budget conflation, not a report of production memory corruption. */
  CHECK(fast==full,"control.fast-equals-full");
}
