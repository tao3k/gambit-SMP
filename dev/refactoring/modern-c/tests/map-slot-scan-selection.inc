/* DEV test translation unit only. Include after mark_array is declared and
 * before the captured-frame and object scanners. The probe may exclude only
 * an explicitly armed, stationary fixture slot. Unarmed slots, frame links,
 * and the copy census keep their existing visitors. */
extern int map_slot_gc_visit(const ___WORD *slot);

static void map_slot_test_mark_array(___collector_worker *work,
                                     ___WORD *first, ___SIZE_TS count)
{
  if (work->census != 0) {
    mark_array(work, first, count);
    return;
  }

  ___WORD *run = first;
  ___WORD *past = first + count;
  for (___WORD *slot = first; slot != past; slot++) {
    if (!map_slot_gc_visit(slot)) {
      if (slot != run)
        mark_array(work, run, slot - run);
      run = slot + 1;
    }
  }
  if (run != past)
    mark_array(work, run, past - run);
}
