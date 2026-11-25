/* A typed view of the existing physical allocation, not another allocator.
 * The native prefix, bitmap formula, claims and extent macros are vendor text.
 * The geometry branch checks this view against the actual address producer. */
#ifndef CONTRACT_SECTION_STORAGE_H
#define CONTRACT_SECTION_STORAGE_H
#include "tests/contracts/allocation-grant/support/lp64.h"
#include "vendor/gambit/lib/_mem/section-claim.inc"

typedef struct contract_section_storage {
  ___msection prefix;
  ___WORD payload_and_scan[___MSECTION_SIZE-1+___msection_scan_words(___MSECTION_SIZE)];
  section_claim claims[2];
  unsigned char raw_maps[2*RAW_STACK_MAP_BYTES];
} contract_section_storage;

typedef struct contract_section_index_storage {
  ___msections prefix;
  ___msection *remaining_slots[6];
} contract_section_index_storage;

_Static_assert(sizeof(contract_section_storage)==SECTION_BYTES,"full native section extent");
_Static_assert(___WORDS(SECTION_BYTES)*___WS==SECTION_BYTES,"native allocation word rounding");
_Static_assert(sizeof(contract_section_index_storage)==___sizeof_msections(7),"native seven-slot index extent");

void *__CPROVER_allocate(size_t bytes,_Bool zero);
size_t __CPROVER_OBJECT_SIZE(const void *pointer);
#endif
