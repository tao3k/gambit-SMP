#include "tests/contracts/allocation-grant/support/capacity-environment.h"

void capacity_contract(void)
{
  int n=nondet_int(), k=nondet_int();
  ___msections pool;
  ASSUME(n>=1 && n<=8 && k>=1 && k<=32);
  pool.nb_sections=nondet_int();ASSUME(pool.nb_sections>=n && pool.nb_sections<=40);
  the_msections=&pool;
  global.setup_params.max_heap=nondet_long();
  ASSUME(global.setup_params.max_heap>=0 && global.setup_params.max_heap<=64L*___MSECTION_SIZE*___WS);
  occupied_words_still=nondet_long();
  ASSUME(occupied_words_still>=0 && occupied_words_still<=___MSECTION_SIZE);
  if(global.setup_params.max_heap!=0) {
    long cap=global.setup_params.max_heap>>___LWS;
    ASSUME(cap>=occupied_words_still);
    ASSUME(pool.nb_sections<=(cap-occupied_words_still)/___MSECTION_SIZE);
  }
  growth_called=0;growth_request=0;
  /* Exact source block. Local refuse label retains the real decision branch. */
#include "capacity.inc"
  CHECK(___gc_copy_plan_fits(n,k,pool.nb_sections),"capacity.success-covers-roots-and-copies");
refuse:
  if(growth_called && global.setup_params.max_heap!=0) {
    long cap=global.setup_params.max_heap>>___LWS;
    CHECK(cap>=occupied_words_still &&
          growth_request<=(cap-occupied_words_still)/___MSECTION_SIZE,
          "capacity.growth-respects-byte-limit-and-still-custody");
  }
}

