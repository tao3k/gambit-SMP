#include "tests/contracts/allocation-grant/support/capacity-environment.h"

/* Witnessed header-overflow geometry: roots=6, copies=9, pool=14.
 * copies exceeds pool-roots, so the plan does not fit. An unlimited heap
 * must request n+k sections. A byte cap with no remaining section must
 * refuse without growth. The planner body is the projected source block. */

static void shortage_unlimited(void)
{
  int n=6, k=9;
  ___msections pool;
  pool.nb_sections=14;
  the_msections=&pool;
  global.setup_params.max_heap=0;
  occupied_words_still=0;
  growth_called=0;growth_request=0;
  CHECK(!___gc_copy_plan_fits(n,k,14),"shortage.fourteen-does-not-fit");
#include "capacity.inc"
  CHECK(growth_called && growth_request==15,"shortage.unlimited-requests-fifteen");
  CHECK(___gc_copy_plan_fits(n,k,pool.nb_sections),"shortage.granted-need-fits");
  return;
refuse:
  CHECK(growth_called && growth_request==15,"shortage.unlimited-requests-fifteen");
}

static void shortage_tight(void)
{
  int n=6, k=9;
  ___msections pool;
  ___SIZE_TS words;
  pool.nb_sections=14;
  the_msections=&pool;
  words=(___SIZE_TS)14*___MSECTION_SIZE;
  global.setup_params.max_heap=words<<___LWS;
  occupied_words_still=(long)words;
  growth_called=0;growth_request=0;
#include "capacity.inc"
  CHECK(0,"shortage.tight-must-refuse");
  return;
refuse:
  CHECK(!growth_called,"shortage.tight-no-growth");
}

void shortage_contract(void)
{
  shortage_unlimited();
  shortage_tight();
}
