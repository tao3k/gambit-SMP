#include "tests/contracts/allocation-grant/support/capacity-environment.h"

void capacity_overflow_contract(void)
{
  int n=nondet_int(), k=nondet_int();
  ___msections pool;
  ASSUME(n>=1 && n<=8 && k>=1);
  pool.nb_sections=n;
  the_msections=&pool;
  global.setup_params.max_heap=0;
#include "capacity.inc"
refuse:;
}
