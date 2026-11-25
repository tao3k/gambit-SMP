#ifndef GAMBIT_TEST_MATURE_SLOT_ORACLE_H
#define GAMBIT_TEST_MATURE_SLOT_ORACLE_H

#include <stdint.h>

/* Test-only diagnostic words. Never put this record in a traced root span.
 * The collector adapter must capture the words at joined phase boundaries.
 * The expected value comes from an independently rooted reference or from
 * qualified forwarding metadata, never from the selected remembered slot. */
struct mature_slot_sample {
  uintptr_t epoch;
  uintptr_t owner;
  uintptr_t slot;
  uintptr_t value;
};

enum mature_slot_result {
  MATURE_SLOT_MATCH,
  MATURE_SLOT_UNQUALIFIED,
  MATURE_SLOT_WRONG_SOURCE,
  MATURE_SLOT_STALE,
  MATURE_SLOT_WRONG_VALUE
};

static inline enum mature_slot_result
mature_slot_compare(struct mature_slot_sample before,
                    struct mature_slot_sample after,
                    int expected_known,
                    uintptr_t expected)
{
  if (!expected_known || before.epoch == 0 || before.owner == 0 ||
      before.slot == 0)
    return MATURE_SLOT_UNQUALIFIED;
  if (after.epoch != before.epoch || after.owner != before.owner ||
      after.slot != before.slot)
    return MATURE_SLOT_WRONG_SOURCE;
  if (after.value == expected)
    return MATURE_SLOT_MATCH;
  if (after.value == before.value)
    return MATURE_SLOT_STALE;
  return MATURE_SLOT_WRONG_VALUE;
}

#endif
