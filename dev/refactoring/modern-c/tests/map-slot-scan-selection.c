#include <assert.h>
#include <stddef.h>
#include <stdio.h>

/* Record visits made by the production-shaped test fragment. This test
 * isolates range splitting; it does not emulate Gambit object relocation. */
typedef long ___WORD;
typedef ptrdiff_t ___SIZE_TS;
typedef struct {void *census;} ___collector_worker;

static const ___WORD *excluded;
static ___WORD *start;
static unsigned visited;
static unsigned runs;

int map_slot_gc_visit(const ___WORD *slot)
{
  return slot != excluded;
}

static void mark_array(___collector_worker *work, ___WORD *slot, ___SIZE_TS count)
{
  (void)work;
  runs++;
  for (___SIZE_TS i = 0; i < count; i++) {
    unsigned bit = 1u << (&slot[i] - start);
    assert(!(visited & bit));
    visited |= bit;
  }
}

#include "map-slot-scan-selection.inc"

int main(void)
{
  ___WORD slots[4];
  ___collector_worker worker = {0};
  start = slots;
  excluded = slots + 1;
  map_slot_test_mark_array(&worker, slots, 4);
  assert(visited == 13 && runs == 2);
  visited = runs = 0;
  excluded = slots;
  map_slot_test_mark_array(&worker, slots, 4);
  assert(visited == 14 && runs == 1);
  visited = runs = 0;
  excluded = slots + 3;
  map_slot_test_mark_array(&worker, slots, 4);
  assert(visited == 7 && runs == 1);
  visited = runs = 0;
  worker.census = &worker;
  map_slot_test_mark_array(&worker, slots, 4);
  assert(visited == 15 && runs == 1);
  puts("MAP-SLOT-SCAN-SELECTION-PASS first middle last census");
}
