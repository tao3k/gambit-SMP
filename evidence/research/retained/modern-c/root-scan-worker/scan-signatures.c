/* Compile-only consumer of the actual private root API. */
#include "root.h"
void scan_signatures(___root_task *task, ___rc_domain *rc,
                     ___processor_state ps, ___collector_worker *work,
                     ___UWORD epoch)
{
#ifdef LEGACY_SCAN
  ___root_task_scan(rc, ps, epoch);
  ___root_task_scan_vm(task, ps, epoch);
  ___root_task_scan_bank(task, ps, epoch);
  ___root_task_scan_stack(task, ps, epoch);
  ___root_task_scan_symkey(task, ps, epoch);
  ___root_task_scan_globals(task, ps, epoch);
#else
  ___root_task_scan(rc, ps, work, epoch);
  ___root_task_scan_vm(task, ps, work, epoch);
  ___root_task_scan_bank(task, ps, work, epoch);
  ___root_task_scan_stack(task, ps, work, epoch);
  ___root_task_scan_symkey(task, ps, work, epoch);
  ___root_task_scan_globals(task, ps, work, epoch);
#endif
}
