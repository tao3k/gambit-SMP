/* The production note is projected verbatim. This harness only states the
 * frame condition: the note copies the two construction counters and does
 * not assign the separate frame sentinel. */
typedef long ___WORD;
___WORD restobs_frame_sentinel;
#include "collect-note.inc"

void collect_note_contract(void)
{
  ___WORD pops=___rest_fallback_pops;
  ___WORD writes=___rest_fallback_pair_writes;
  restobs_frame_sentinel=0x4652;
  ___rest_note_before_collect();
  __CPROVER_assert(___rest_before_collect_pops==pops,
                   "note.copies-pops");
  __CPROVER_assert(___rest_before_collect_writes==writes,
                   "note.copies-writes");
  __CPROVER_assert(restobs_frame_sentinel==0x4652,
                   "note.leaves-frame-sentinel");
}
