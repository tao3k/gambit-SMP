/* Family 8 (8/12: registry) CBMC Contract:
 * Verifies C-level VM registry incarnation-guard bounds, live-borrower
 * non-reclamation, and stale-token refusal before first occupant load.
 */
#include <stdint.h>

#define CHECK(p, n) __CPROVER_assert((p), (n))
extern unsigned int nondet_uint(void);
extern int nondet_int(void);

enum { SLOT_EMPTY = 0, SLOT_ACTIVE = 1, SLOT_DRAINING = 2 };

typedef struct {
  uint32_t incarnation;
  int phase;
  uint32_t borrowers;
  int occupant_tag;
} registry_slot;

static int borrow_slot(registry_slot *s, uint32_t token, int *out_tag) {
  if (s->phase != SLOT_ACTIVE || s->incarnation != token)
    return 0;
  if (s->borrowers == UINT32_MAX)
    return 0;
  s->borrowers += 1;
  *out_tag = s->occupant_tag;
  return 1;
}

static int reclaim_slot(registry_slot *s) {
  if (s->phase != SLOT_DRAINING || s->borrowers != 0)
    return 0;
  if (s->incarnation >= UINT32_MAX - 2u)
    return 0; /* generation exhaustion refuses reuse */
  s->incarnation += 1;
  s->phase = SLOT_EMPTY;
  s->occupant_tag = 0;
  return 1;
}

static int activate_slot(registry_slot *s, int new_tag) {
  if (s->phase != SLOT_EMPTY || s->borrowers != 0)
    return 0;
  if (s->incarnation >= UINT32_MAX - 1u)
    return 0;
  s->incarnation += 1;
  s->phase = SLOT_ACTIVE;
  s->occupant_tag = new_tag;
  return 1;
}

int main(void) {
  registry_slot slot;
  slot.incarnation = nondet_uint();
  __CPROVER_assume(slot.incarnation >= 1u && slot.incarnation <= 1000u);
  slot.phase = SLOT_ACTIVE;
  slot.borrowers = 0;
  slot.occupant_tag = 42;

  uint32_t old_token = slot.incarnation;
  int observed = -1;

  /* Live borrower blocks reclamation */
  CHECK(borrow_slot(&slot, old_token, &observed) == 1 && observed == 42,
        "f8.borrow-valid-incarnation");
  slot.phase = SLOT_DRAINING;
  CHECK(reclaim_slot(&slot) == 0, "f8.reclaim-refused-with-live-borrower");
  CHECK(slot.phase == SLOT_DRAINING && slot.occupant_tag == 42,
        "f8.occupant-preserved-while-borrowed");

  /* Release borrower, reclaim, and reuse slot */
  slot.borrowers -= 1;
  CHECK(reclaim_slot(&slot) == 1, "f8.reclaim-succeeds-when-drained");
  CHECK(activate_slot(&slot, 99) == 1, "f8.reuse-advances-incarnation");
  CHECK(slot.incarnation > old_token, "f8.incarnation-strictly-monotonic");

  /* Stale token refused BEFORE loading new occupant */
  observed = -1;
  CHECK(borrow_slot(&slot, old_token, &observed) == 0 && observed == -1,
        "f8.stale-token-refused-before-load");

  /* Exhausted generation refuses reuse */
  registry_slot exhausted = { UINT32_MAX - 1u, SLOT_DRAINING, 0u, 7 };
  CHECK(reclaim_slot(&exhausted) == 0, "f8.generation-exhaustion-refuses-reuse");

  return 0;
}
