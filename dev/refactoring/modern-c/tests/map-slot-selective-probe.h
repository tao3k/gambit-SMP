#ifndef GAMBIT_TEST_MAP_SLOT_SELECTIVE_PROBE_H
#define GAMBIT_TEST_MAP_SLOT_SELECTIVE_PROBE_H

/* Serialized DEV p1 probe. The enclosing fixture owns the stationary
 * objects. Only the fault control uses independent RC roots. Positive
 * controls qualify the repaired value through the from-space header. */
static struct {
  ___processor_state owner;
  ___WORD *slots[2];
  void *expected[2];
  ___WORD before[2];
  unsigned visited[2];
  unsigned skipped[2];
  struct mature_slot_log current;
  struct mature_slot_log next;
  uintptr_t epoch;
  bool force_scan;
  bool omit_record;
  bool omit_rearm;
  bool frozen;
  bool repaired;
} map_slot_selective_probe;

static unsigned map_slot_bounded_visits;

static bool map_slot_selected(size_t index)
{
  const struct mature_slot_log *log = &map_slot_selective_probe.current;
  if (log->overflow)
    return true;
  for (size_t i = 0; i < log->count; i++)
    if (log->indices[i] == index)
      return true;
  return false;
}

int map_slot_gc_visit(const ___WORD *slot)
{
  if (map_slot_selective_probe.frozen) {
    for (size_t i = 0; i < 2; i++)
      if (slot == map_slot_selective_probe.slots[i]) {
        if (map_slot_selective_probe.force_scan || map_slot_selected(i)) {
          map_slot_selective_probe.visited[i]++;
          return 1;
        }
        map_slot_selective_probe.skipped[i]++;
        return 0;
      }
  }
  return 1;
}

static void map_slot_selective_frozen(void *ps, uintptr_t epoch)
{
  if (ps != map_slot_selective_probe.owner)
    return;
  map_slot_selective_probe.epoch = epoch;
  map_slot_selective_probe.frozen = true;
}

static void map_slot_selective_repaired(void *ps, uintptr_t epoch)
{
  if (ps != map_slot_selective_probe.owner || !map_slot_selective_probe.frozen)
    return;
  map_slot_selective_probe.frozen = false;
  struct mature_slot_log *next = &map_slot_selective_probe.next;
  next->count = 0;
  next->overflow = false;
  bool ok = epoch == map_slot_selective_probe.epoch;
  for (size_t i = 0; i < 2; i++) {
    ___WORD *slot = map_slot_selective_probe.slots[i];
    ___WORD expected = ___FAL;
    if (map_slot_selective_probe.omit_record)
      expected = ___data_rc(map_slot_selective_probe.expected[i]);
    else if (map_slot_selected(i)) {
      ___WORD old = map_slot_selective_probe.before[i];
      ___WORD head = ___HEADER(old);
      if (___TESTTYPE(head, ___FORW)) {
        expected = ___TAG(___UNTAG_AS(head, ___FORW), ___TYP(old));
        ok = ok && ___VECTORELEM(expected, 0) == ___FIX(i == 0 ? 17 : 29);
      } else
        ok = false;
    }
    if (map_slot_selected(i)) {
      ok = ok && map_slot_selective_probe.visited[i] > 0 &&
           *slot == expected && expected != map_slot_selective_probe.before[i];
    } else if (map_slot_selective_probe.omit_record) {
      ok = ok && map_slot_selective_probe.skipped[i] > 0 &&
           *slot == map_slot_selective_probe.before[i] && *slot != expected;
    } else if (map_slot_selective_probe.omit_rearm && i == 0) {
      ___WORD old = map_slot_selective_probe.before[i];
      ok = ok && map_slot_selective_probe.skipped[i] > 0 &&
           *slot == old && ___HD_TYP(___HEADER(old)) == ___MOVABLE0;
    } else {
      unsigned decisions = map_slot_selective_probe.force_scan
        ? map_slot_selective_probe.visited[i]
        : map_slot_selective_probe.skipped[i];
      ok = ok && decisions > 0 && *slot == ___FAL && expected == ___FAL;
    }
    /* Repair the injected fault or clear an unforwarded value on failure
     * before thaw. Leave the collector's successful repair untouched. */
    if (*slot != expected)
      *slot = expected;
    if (___MEM_ALLOCATED(expected) && ___HD_TYP(___HEADER(expected)) == ___MOVABLE0)
      mature_slot_record(next, i);
  }
  map_slot_selective_probe.repaired = ok;
}

static int map_slot_selective_control(___processor_state ps,
                                      ___WORD *frame_slot,
                                      ___WORD *denv_slot,
                                      ___SCMOBJ value,
                                      int mode)
{
  if (map_slot_selective_probe.owner ||
      ___VMSTATE_FROM_PSTATE(ps)->processor_count != 1 ||
      frame_slot == denv_slot)
    return 0;
  map_slot_selective_probe.slots[0] = frame_slot;
  map_slot_selective_probe.slots[1] = denv_slot;
  map_slot_selective_probe.force_scan = mode == 4;
  map_slot_selective_probe.omit_record = mode == 0;
  map_slot_selective_probe.omit_rearm = false;
  size_t current_indices[1], next_indices[1];
  map_slot_selective_probe.current = (struct mature_slot_log){current_indices, 1, 0, false};
  map_slot_selective_probe.next = (struct mature_slot_log){next_indices, 1, 0, false};
  int allocated = 0;
  int ok = 0;
  unsigned visits = 0;
  ___WORD values[] = {___FAL, ___FAL};
  if (mode == 0) {
    for (size_t i = 0; i < 2; i++) {
      void *root = ___alloc_rc(___PSA(ps) 0);
      if (!root)
        goto done;
      map_slot_selective_probe.expected[i] = root;
      allocated++;
      values[i] = value;
      if (!___try_set_data_rc(ps, root, value))
        goto done;
    }
  } else {
    /* No managed argument or RC root contains these referents. Their only
     * strong incoming edges are the fixture slots we are about to write. */
    size_t count = mode == 2 ? 2 : 1;
    ___WORD *hp = ps->context->hp;
    if (ps->mem.alloc_heap_limit_ - hp < (___SIZE_TS)(2 * count))
      goto done;
    for (size_t i = 0; i < count; i++) {
      hp[0] = ___MAKE_HD_WORDS(1, ___sVECTOR);
      hp[1] = ___FIX(i == 0 ? 17 : 29);
      values[i] = ___VECTOR_FROM_BODY(hp+1);
      hp += 2;
    }
    ps->context->hp = hp;
  }
  for (size_t i = 0; i < 2; i++) {
    if (mode != 0 && values[i] != ___FAL)
      mature_slot_record(&map_slot_selective_probe.current, i);
    *map_slot_selective_probe.slots[i] = values[i];
  }
  for (int round = 0; round < (mode == 0 ? 1 : 2); round++) {
    for (size_t i = 0; i < 2; i++) {
      map_slot_selective_probe.before[i] = *map_slot_selective_probe.slots[i];
      map_slot_selective_probe.visited[i] = 0;
      map_slot_selective_probe.skipped[i] = 0;
    }
    if (mode == 3 && round == 1) {
      if (map_slot_selective_probe.current.count != 1 ||
          map_slot_selective_probe.current.overflow) {
        ok = 0;
        goto done;
      }
      map_slot_selective_probe.current.count = 0;
      map_slot_selective_probe.omit_rearm = true;
    }
    map_slot_selective_probe.owner = ps;
    map_slot_selective_probe.repaired = false;
    ok = !___garbage_collect(___PSA(ps) 0) && map_slot_selective_probe.repaired;
    map_slot_selective_probe.owner = 0;
    map_slot_selective_probe.frozen = false;
    if (!ok)
      goto done;
    visits += map_slot_selective_probe.visited[0] +
              map_slot_selective_probe.visited[1];
    /* The actual repaired reference determines next-round membership.
     * Do not write either logical slot between these two collections. */
    struct mature_slot_log old = map_slot_selective_probe.current;
    map_slot_selective_probe.current = map_slot_selective_probe.next;
    map_slot_selective_probe.next = old;
  }
  if (mode == 1)
    map_slot_bounded_visits = visits;
  if (mode == 4) {
    ok = visits > map_slot_bounded_visits && map_slot_bounded_visits > 0;
    if (ok)
      printf("MAP-SLOT-SCAN-COST bounded=%u forced=%u rounds=2 log-bytes=%zu\n",
             map_slot_bounded_visits, visits,
             sizeof(struct mature_slot_log) * 2 + sizeof(size_t) * 2);
  }
done:
  while (allocated > 0)
    ___release_rc(map_slot_selective_probe.expected[--allocated]);
  return ok;
}

#endif
