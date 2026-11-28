#include <assert.h>
#include <stdio.h>

#include "mature-slot-oracle.h"
#include "mature-slot-remembered.h"

/* Controlled relocation, independent of Gambit's production collector. */
struct relocation {
  uintptr_t from;
  uintptr_t to;
  bool remains_young;
};

static bool repair(uintptr_t *slot, void *context)
{
  const struct relocation *move = context;
  if (*slot != move->from)
    return false;
  *slot = move->to;
  return move->remains_young;
}

int main(void)
{
  uintptr_t frame = 0, denv = 0;
  uintptr_t *domain[] = {&frame, &denv};
  size_t first_index[1], second_index[1];
  struct mature_slot_log first = {first_index, 1, 0, false};
  struct mature_slot_log second = {second_index, 1, 0, false};
  struct relocation move = {16, 32, true};

  /* The independent root is repaired. An omitted store record leaves the
   * mature slot stale even though the referent has a live destination. */
  uintptr_t independent = move.from;
  frame = move.from;
  assert(repair(&independent, &move));
  assert(mature_slot_scan(&first, &second, domain, 2, repair, &move) == 0);
  struct mature_slot_sample before = {1, 1, 1, move.from};
  struct mature_slot_sample after = {1, 1, 1, frame};
  assert(mature_slot_compare(before, after, 1, independent) == MATURE_SLOT_STALE);

  mature_slot_store(&first, domain, 0, move.from);
  mature_slot_store(&first, domain, 0, move.from);
  assert(first.count == 1 && !first.overflow);
  mature_slot_store(&first, domain, 1, move.from);
  assert(first.overflow);
  assert(mature_slot_scan(&first, &second, domain, 2, repair, &move) == 2);
  assert(frame == 32 && denv == 32 && second.overflow);

  /* No writes between rounds. Rebuilding the next bank overflowed, so the
   * next cut must visit the domain again. Promotion discharges both edges. */
  move = (struct relocation){32, 48, false};
  assert(mature_slot_scan(&second, &first, domain, 2, repair, &move) == 2);
  assert(frame == 48 && denv == 48 && first.count == 0 && !first.overflow);
  assert(mature_slot_scan(&first, &second, domain, 2, repair, &move) == 0);

  /* A non-overflow residual must also be revisited without another store. */
  move = (struct relocation){64, 80, true};
  mature_slot_store(&first, domain, 0, move.from);
  assert(mature_slot_scan(&first, &second, domain, 2, repair, &move) == 1);
  assert(frame == 80 && second.count == 1 && !second.overflow);
  move = (struct relocation){80, 96, false};
  assert(mature_slot_scan(&second, &first, domain, 2, repair, &move) == 1);
  assert(frame == 96 && denv == 48 && first.count == 0);
  puts("MATURE-SLOT-REMEMBERED-PASS stale overflow residual next-overflow");
}
