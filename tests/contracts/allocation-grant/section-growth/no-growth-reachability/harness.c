/* Fix one external allocator outcome; the native resize body is unchanged. */
#define nondet_bool controlled_allocation_failure
#include "tests/contracts/allocation-grant/support/growth-fixture.h"

int failure_after;
_Bool controlled_allocation_failure(void)
{
  return section_requests == failure_after;
}

void reachability_contract(void)
{
  failure_after = -1;
  resize_contract(1);
  /* A deliberate failure witnesses this outcome, not a source defect. */
  CHECK(section_requests != 0,"witness.no-growth");
}
