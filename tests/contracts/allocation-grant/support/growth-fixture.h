#ifndef CONTRACT_GROWTH_FIXTURE_H
#define CONTRACT_GROWTH_FIXTURE_H
#include "tests/contracts/allocation-grant/support/section-storage.h"

/* The required geometry proof establishes this exact address equality for
 * both native call arguments. Keep every native initialization store, using
 * its proved typed address to avoid whole-byte-array updates in the checker. */
#define section_claim_at(section,offset) \
  (&((contract_section_storage *)(section))->claims[(offset)!=0])

void *__CPROVER_allocate(size_t bytes,_Bool zero);
contract_section_storage *prepared_sections[2];
int section_requests;
void *alloc_mem_aligned(long words,int alignment,int modulus)
{
  if(nondet_bool())return 0;
  return __CPROVER_allocate((size_t)words*___WS,0);
}
void *alloc_mem_aligned_heap(long words,int alignment,int modulus)
{
  CHECK((size_t)words*___WS==sizeof(contract_section_storage),"resize.full-native-allocation-request");
  CHECK(section_requests<2,"resize.request-count-within-original-growth-bound");
  if(nondet_bool())return 0;
  return &prepared_sections[section_requests++]->prefix;
}
void free_mem_aligned(void *p) { free(p); }
void free_mem_aligned_heap(void *p) { free(p); }

#include "find-section.inc"
#include "resize.inc"

void resize_contract(int need)
{
  contract_section_index_storage *index=__CPROVER_allocate(sizeof(*index),0);
  ___msections *pool=&index->prefix;
  contract_section_storage *old_storage=__CPROVER_allocate(sizeof(*old_storage),0);
  prepared_sections[0]=__CPROVER_allocate(sizeof(contract_section_storage),0);
  prepared_sections[1]=__CPROVER_allocate(sizeof(contract_section_storage),0);
  ___msection *old=&old_storage->prefix;
  pool->max_nb_sections=7;pool->nb_sections=1;pool->head=old;pool->tail=old;
  pool->sections[0]=old;
  old->index=0;old->pos=0;old->prev=0;old->next=0;old->copy_gate=0;
  section_requests=0;
  CHECK(old!=&prepared_sections[0]->prefix && old!=&prepared_sections[1]->prefix &&
        prepared_sections[0]!=prepared_sections[1],"resize.prepared-grants-are-fresh-and-disjoint");
  old->base[0]=123;
  CHECK(need>=1 && need<=3,"resize.caller-demand-in-original-domain");
  adjust_msections(&pool,need);
  CHECK(pool->nb_sections>=1 && pool->nb_sections<=need,"resize.partial-failure-retains-old-count");
  CHECK(pool->nb_sections==1+section_requests,"resize.every-granted-section-published-once");
  CHECK(pool->head==old && old->base[0]==123,"resize.retains-old-section-and-payload");
  CHECK(pool->head->prev==0 && pool->tail->next==0,"resize.list-endpoints-consistent");
  int count=0;___msection *p=pool->head,*previous=0;
  while(p) {
    CHECK(p->prev==previous,"resize.bidirectional-links");
    previous=p;p=p->next;count++;
  }
  CHECK(count==pool->nb_sections && previous==pool->tail,"resize.published-count-matches-list");
  for(int i=0;i<count;i++) {
    CHECK(pool->sections[i]->pos==i,"resize.address-index-position-consistent");
    if(i+1<count)CHECK(pool->sections[i]>pool->sections[i+1],"resize.descending-address-index");
  }
}

#endif
