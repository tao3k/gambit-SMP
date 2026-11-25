#include "tests/contracts/allocation-grant/support/lp64.h"
#include "vendor/gambit/lib/_mem/section-claim.inc"

void *__CPROVER_allocate(size_t bytes,_Bool zero);
void *alloc_mem_aligned(long words,int alignment,int modulus)
{
  if(nondet_bool())return 0;
  return __CPROVER_allocate((size_t)words*___WS,0);
}
void *alloc_mem_aligned_heap(long words,int alignment,int modulus)
{
  if(nondet_bool())return 0;
  return __CPROVER_allocate((size_t)words*___WS,0);
}
void free_mem_aligned(void *p) { free(p); }
void free_mem_aligned_heap(void *p) { free(p); }

#include "find-section.inc"
#include "resize.inc"

void resize_contract(void)
{
  ___msections *pool=__CPROVER_allocate(___sizeof_msections(7),0);
  ASSUME(pool!=0);
  pool->max_nb_sections=7;pool->nb_sections=0;pool->head=0;pool->tail=0;
  adjust_msections(&pool,1);
  /* Start the second request from one actually constructed live section. */
  ASSUME(pool->nb_sections==1);
  ___msection *old=pool->head;
  old->base[0]=123;
  int need=nondet_int();ASSUME(need>=1 && need<=3);
  adjust_msections(&pool,need);
  CHECK(pool->nb_sections>=1 && pool->nb_sections<=need,"resize.partial-failure-retains-old-count");
  CHECK(pool->head==old && old->base[0]==123,"resize.retains-old-section-and-payload");
  CHECK(pool->head->prev==0 && pool->tail->next==0,"resize.list-endpoints-consistent");
  int count=0;___msection *p=pool->head,*previous=0;
  while(p) {
    CHECK(p->prev==previous,"resize.bidirectional-links");
    previous=p;p=p->next;count++;
  }
  CHECK(count==pool->nb_sections && previous==pool->tail,"resize.published-count-matches-list");
}
