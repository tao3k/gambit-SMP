#include "tests/contracts/allocation-grant/support/lp64.h"
typedef long ___SCMOBJ;
#include "census.inc"

/* The common refusal epilogue's caller state is summarized explicitly.
 * Census traversal and the 37 predecessor conditions are outside this cut. */
typedef struct { ___gc_census *census; } worker_state;
typedef struct { void *collector; } processor_state;

int refusal_epilogue(worker_state *work,processor_state *ps,___gc_census *c)
{
#include "refusal.inc"

void refusal_contract(void)
{
  ___gc_census c;
  worker_state work;processor_state processor;
  long queue[2];
  c.queue=queue;c.replacement=0;c.retired=0;c.state=___GC_PLAN_READING;
  c.count=2;c.next=1;c.small_words=168633;c.small_max=131;
  work.census=&c;processor.collector=&work;
  int result=refusal_epilogue(&work,&processor,&c);
  CHECK(result==2 && c.state==___GC_PLAN_REFUSED,"refusal.publishes-refused-decision");
  CHECK(work.census==0 && processor.collector==0,"refusal.detaches-temporary-census-owner");
  CHECK(c.queue==queue && c.replacement==0 && c.retired==0,"refusal.retains-owned-storage");
  CHECK(c.small_words==168633 && c.small_max==131,"refusal.retains-measured-demand");
  CHECK(c.count==0 && c.next==0,"refusal.clears-traversal-cursors");
  /* This epilogue cannot prove the identity of a predecessor it never sees.
   * Branch causality remains an explicit source correspondence obligation. */
}
