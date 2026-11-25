#include "tests/contracts/allocation-grant/support/section-storage.h"

void section_geometry_contract(void)
{
  contract_section_storage *storage=__CPROVER_allocate(sizeof(*storage),0);
  ___msection *s=&storage->prefix;
  section_claim *first=section_claim_at(s,0);
  section_claim *second=section_claim_at(s,___MSECTION_SIZE>>1);
  CHECK(__CPROVER_OBJECT_SIZE(storage)==SECTION_BYTES,"geometry.full-physical-extent");
  CHECK(first==&storage->claims[0] && second==&storage->claims[1],"geometry.native-claim-addresses");
  size_t first_offset=(unsigned char*)first-(unsigned char*)storage;
  size_t second_offset=(unsigned char*)second-(unsigned char*)storage;
  CHECK(first_offset<=sizeof(*storage)-sizeof(*first) &&
        second_offset<=sizeof(*storage)-sizeof(*second),"geometry.complete-claim-spans-writable");
  CHECK(first+1==second,"geometry.claims-disjoint-and-adjacent");
  long payload=nondet_long(), raw=nondet_long();
  ASSUME(payload>=0 && payload<___MSECTION_SIZE-1+___msection_scan_words(___MSECTION_SIZE));
  ASSUME(raw>=0 && raw<2*RAW_STACK_MAP_BYTES);
  storage->prefix.index=17;storage->prefix.base[0]=123;
  storage->payload_and_scan[payload]=456;storage->raw_maps[raw]=73;
  /* Both stores are verbatim statements from the production resize body. */
#include "claim-initialize.inc"
  CHECK(first->stack_owner==0 && second->stack_owner==0 &&
        first->stack_state==STACK_UNCLAIMED && second->stack_state==STACK_UNCLAIMED &&
        first->source_pins==0 && second->source_pins==0,"geometry.actual-claim-initialization");
  CHECK(storage->prefix.index==17 && storage->prefix.base[0]==123 &&
        storage->payload_and_scan[payload]==456 && storage->raw_maps[raw]==73,
        "geometry.claim-stores-preserve-header-payload-bitmap-and-raw-maps");
}
