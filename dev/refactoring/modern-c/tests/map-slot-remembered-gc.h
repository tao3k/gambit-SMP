#ifndef GAMBIT_TEST_MAP_SLOT_REMEMBERED_GC_H
#define GAMBIT_TEST_MAP_SLOT_REMEMBERED_GC_H

#include <stdio.h>

#include "rc.h"
#include "mature-slot-remembered.h"

/* Stationary native slots for the DEV experiment. The selected references
 * enter the full collector through RC. Generation retention is an explicit
 * fixture input; no product minor or mature heap membership is inferred. */
struct map_remembered_probe {
  ___processor_state owner;
  uintptr_t values[2];
  void *roots[2];
  bool keep_young;
  bool stage_ok;
  unsigned moved;
};

static unsigned map_remembered_index(const struct map_remembered_probe *probe,
                                     const uintptr_t *slot)
{
  return slot == &probe->values[0] ? 0 : 1;
}

static bool map_remembered_stage(uintptr_t *slot, void *context)
{
  struct map_remembered_probe *probe = context;
  unsigned i = map_remembered_index(probe, slot);
  if (!___try_set_data_rc(probe->owner, probe->roots[i], (___SCMOBJ)*slot))
    probe->stage_ok = false;
  return false;
}

static bool map_remembered_reload(uintptr_t *slot, void *context)
{
  struct map_remembered_probe *probe = context;
  unsigned i = map_remembered_index(probe, slot);
  uintptr_t value = (uintptr_t)___data_rc(probe->roots[i]);
  if (*slot != value)
    probe->moved++;
  *slot = value;
  return probe->keep_young;
}

/* A negative control inspects only the still-held from-space header at
 * the joined repaired cut. It never consumes a dead pointer after GC. */
static struct {
  ___processor_state owner;
  ___WORD *header;
  ___WORD repaired_header;
  bool observed;
} map_remembered_omission;

static void map_remembered_after(void *ps)
{
  if (ps == map_remembered_omission.owner) {
    map_remembered_omission.repaired_header = *map_remembered_omission.header;
    map_remembered_omission.observed = true;
  }
}

static int map_remembered_gc(___processor_state ps, bool overflow_case,
                             bool omit_rearm)
{
  struct map_remembered_probe probe = {.owner = ps, .keep_young = true};
  uintptr_t *domain[] = {&probe.values[0], &probe.values[1]};
  size_t current_index[1], next_index[1];
  struct mature_slot_log current = {current_index, 1, 0, false};
  struct mature_slot_log next = {next_index, 1, 0, false};
  int ok = 0;
  const size_t selected = overflow_case ? 2 : 1;

  if (___VMSTATE_FROM_PSTATE(ps)->processor_count != 1)
    return 0;

  for (int i = 0; i < 2; i++) {
    probe.roots[i] = ___alloc_rc(___PSA(ps) 0);
    if (!probe.roots[i])
      goto done;
  }
  /* Allocate without exposing the referents to Scheme arguments or a
   * managed container. Reserve only within the already available tail. */
  ___WORD *hp = ps->context->hp;
  if (ps->mem.alloc_heap_limit_ - hp < (___SIZE_TS)(2 * selected))
    goto done;
  for (size_t i = 0; i < selected; i++) {
    hp[0] = ___MAKE_HD_WORDS(1, ___sVECTOR);
    hp[1] = ___FIX(i == 0 ? 17 : 29);
    mature_slot_store(&current, domain, i,
                      (uintptr_t)___VECTOR_FROM_BODY(hp+1));
    hp += 2;
  }
  ps->context->hp = hp;
  if (current.overflow != overflow_case)
    goto done;
  for (int round = 0; round < 2; round++) {
    probe.stage_ok = true;
    probe.moved = 0;
    probe.keep_young = round == 0;
    if (round == 1 && omit_rearm) {
      if (current.count != 1 || current.overflow ||
          ___data_rc(probe.roots[0]) != ___FAL ||
          ___data_rc(probe.roots[1]) != ___FAL)
        goto done;
      /* Drop the record without staging its reference. Only the raw
       * native fixture word remains. */
      map_remembered_omission.header =
        &___SUBTYPED_HEADER((___SCMOBJ)probe.values[0]);
      ___WORD original_header = *map_remembered_omission.header;
      map_remembered_omission.owner = ps;
      map_remembered_omission.observed = false;
      int refused = ___garbage_collect(___PSA(ps) 0);
      ok = !refused && map_remembered_omission.observed &&
           map_remembered_omission.repaired_header == original_header &&
           ___HD_TYP(original_header) == ___MOVABLE0;
      if (!ok)
        fprintf(stderr, "omitted rearm: refused=%d observed=%d before=%jx after=%jx\n",
                refused, map_remembered_omission.observed,
                (uintmax_t)original_header,
                (uintmax_t)map_remembered_omission.repaired_header);
      map_remembered_omission.owner = 0;
      map_remembered_omission.header = 0;
      goto done;
    }
    if (mature_slot_scan(&current, &next, domain, 2,
                         map_remembered_stage, &probe) != selected ||
        !probe.stage_ok || ___garbage_collect(___PSA(ps) 0))
      goto done;
    if (mature_slot_scan(&current, &next, domain, 2,
                         map_remembered_reload, &probe) != selected ||
        probe.moved != selected ||
        next.overflow != (probe.keep_young && overflow_case) ||
        next.count != (probe.keep_young ? 1 : 0) ||
        ___VECTORELEM((___SCMOBJ)probe.values[0], 0) != ___FIX(17) ||
        (overflow_case &&
         ___VECTORELEM((___SCMOBJ)probe.values[1], 0) != ___FIX(29)))
      goto done;
    for (int i = 0; i < 2; i++)
      if (!___try_set_data_rc(ps, probe.roots[i], ___FAL))
        goto done;
    /* No logical slot write occurs between rounds. Only rearm survives. */
    struct mature_slot_log old = current;
    current = next;
    next = old;
  }
  ok = !current.overflow && current.count == 0;
done:
  for (int i = 0; i < 2; i++)
    if (probe.roots[i])
      ___release_rc(probe.roots[i]);
  return ok;
}
#endif
