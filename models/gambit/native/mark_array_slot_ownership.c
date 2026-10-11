#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef intptr_t ___WORD;
typedef uintptr_t ___UWORD;
typedef uintptr_t ___SIZE_TS;
typedef int ___BOOL;
typedef struct processor {
  ___WORD *alloc;
  ___WORD *limit;
  ___WORD *chunk_limit;
  ___WORD still;
} processor;

#define ___HIDDEN static
#define ___P(parameters, legacy) parameters
#define ___PSD processor *___ps,
#define ___PSV processor *___ps,
#define ___PSDKR
#define ___PSP ___ps,
#define ___PSGET
#define ___CAST(type, value) ((type)(value))
#define ___WS 8
#define ___REFERENCE_TO_BODY 1
#define ___MOVABLE0 0
#define ___FORW 3
#define ___STILL 5
#define ___PERM 6
#define ___sBOXVALUES 5
#define ___sS64VECTOR 27
#define ___HD_TYP(head) ((head) & 7)
#define ___HD_SUBTYPE(head) (((head) >> 3) & 31)
#define ___HD_WORDS(head) (((___UWORD)(head) + 1792) >> 11)
#define ___MEM_ALLOCATED(obj) ((obj) & 1)
#define ___TYP(obj) ((obj) & 7)
#define ___TAG(pointer, tag) ((___WORD)(pointer) + (tag))
#define ___UNTAG_AS(obj, tag) ((___WORD *)((obj) - (tag)))
#define ___UNTAG(obj) ((___WORD *)((obj) & ~(___WORD)7))
#define ___BODY0(obj) (___UNTAG(obj) + 1)
#define ___TESTTYPE(value, type) ((((uint32_t)(value) - (type)) & 7) == 0)
#define ___STILL_MARK 0
#define ___STILL_BODY 5
#define alloc_heap_ptr (___ps->alloc)
#define alloc_heap_limit (___ps->limit)
#define alloc_heap_chunk_limit (___ps->chunk_limit)
#define still_objs_to_scan (___ps->still)
#define gc_scan_reference_observe(cell, obj) ((void)0)
#define gc_old_space_reference_observe(ps, cell, obj) ((void)0)

static ___WORD *race_destination;
static int inject_loser;
static ___WORD compare_swap(___WORD *address, ___WORD expected, ___WORD desired)
{
  ___WORD observed;
  if (inject_loser) {
    inject_loser = 0;
    *address = ___TAG(race_destination, ___FORW);
  }
  observed = *address;
  if (observed == expected)
    *address = desired;
  return observed;
}
#define ___COMPARE_AND_SWAP_WORD(address, expected, desired) \
  compare_swap(address, expected, desired)
static void end_heap_chunk(processor *ps) { (void)ps; abort(); }
static void next_heap_msection(processor *ps) { (void)ps; abort(); }
static void prepare_heap_msection(processor *ps) { (void)ps; abort(); }
static void start_heap_chunk(processor *ps) { (void)ps; abort(); }

#include "mark-source.inc"

int main(int argc, char **argv)
{
  _Alignas(8) ___WORD old[16] = {0};
  _Alignas(8) ___WORD heap[64] = {0};
  _Alignas(8) ___WORD prepared[16] = {0};
  processor ps = {heap, heap+64, heap+32, 0};
  ___WORD roots[2];
  int scenario = argc == 2 ? atoi(argv[1]) : -1;
  int words = scenario == 3 ? 2 : 7;
  int subtype = scenario == 3 ? 0 : 13;
  int same, destination_forwarded, self_relocated;
  int i;
  if (scenario < 0 || scenario > 4)
    return 2;
  old[0] = (words << 11) | (subtype << 3);
  for (i=1; i<=words; i++)
    old[i] = i << 3;
  roots[0] = roots[1] = ___TAG(old, 5);
  if (scenario == 3)
    old[1] = roots[0];
  if (scenario == 2) {
    memcpy(prepared, old, (words+1)*sizeof(___WORD));
    race_destination = prepared;
    inject_loser = 1;
  }
  mark_array(&ps, roots, 1);
  if (scenario == 0)
    mark_array(&ps, roots+1, 1);
  else if (scenario == 1)
    mark_array(&ps, roots, 1);
  else if (scenario == 4) {
    roots[1] = roots[0];
    mark_array(&ps, roots+1, 1);
  }

  same = roots[0] == roots[1];
  destination_forwarded = ___TESTTYPE(heap[0], ___FORW);
  self_relocated = scenario == 3 && heap[1] == roots[0];
  printf("{\"sameReference\":%d,\"destinationForwarded\":%d,"
         "\"allocatedWords\":%ld,\"selfRelocated\":%d}\n",
         same, destination_forwarded, (long)(ps.alloc-heap), self_relocated);
  return 0;
}
