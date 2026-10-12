(c-declare #<<end-of-code
#include <stdatomic.h>
static atomic_int observed_markers_made;
static atomic_int observed_markers_killed;

static ___SCMOBJ observed_make_marker(___processor_state ps,
                                      ___SCMOBJ *marker, ___SCMOBJ proc) {
  ___SCMOBJ error = ___make_sfun_stack_marker(ps, marker, proc);
  if (error == ___FIX(___NO_ERR))
    atomic_fetch_add_explicit(&observed_markers_made, 1, memory_order_relaxed);
  return error;
}
static void observed_kill_marker(___SCMOBJ marker) {
  atomic_fetch_add_explicit(&observed_markers_killed, 1, memory_order_relaxed);
  ___kill_sfun_stack_marker(marker);
}
int nested_markers_made(void) {
  return atomic_load_explicit(&observed_markers_made, memory_order_relaxed);
}
int nested_markers_killed(void) {
  return atomic_load_explicit(&observed_markers_killed, memory_order_relaxed);
}
#define ___make_sfun_stack_marker observed_make_marker
#define ___kill_sfun_stack_marker observed_kill_marker
end-of-code
)

(include "nestedunwind.scm")
