#include "tests/contracts/allocation-grant/support/lp64.h"
#include "certificate.inc"

void certificate_contract(void)
{
  int workers=nondet_int(), sections=-17;
  long small=nondet_long(), maximum=nondet_long(), large=nondet_long();
  long capacity=nondet_long(), chunk=nondet_long();
  /* Finite resource domain, machine-width arithmetic remains real C. */
  ASSUME(workers>=1 && workers<=8);
  ASSUME(capacity>=1 && capacity<=65536);
  ASSUME(chunk>=1 && chunk<=255);
  ASSUME(maximum>=0 && maximum<=capacity);
  ASSUME(small>=0 && small<=16*capacity);
  ASSUME(large>=0 && large<=16);
  int ok=___gc_copy_section_bound(workers,small,maximum,large,capacity,chunk,&sections);
  CHECK(ok || sections==-17,"certificate.failure-preserves-output");
  CHECK(!ok || sections>=workers,"certificate.reserves-every-worker");
  CHECK(!ok || sections>=workers+2*large,"certificate.large-request-reservation");
  /* Deliberately separate plan arithmetic from packing-algorithm soundness. */
}
