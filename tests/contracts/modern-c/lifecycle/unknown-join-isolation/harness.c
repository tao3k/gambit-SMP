/* Family 9 (9/12: lifecycle) CBMC Contract:
 * Verifies C-level unknown-join quarantine retention, healthy-VM GC independence,
 * and stale-generation rollback refusal.
 */
#include <stdint.h>

#define CHECK(p, n) __CPROVER_assert((p), (n))
extern unsigned int nondet_uint(void);

enum { VM_HEALTHY = 0, VM_UNKNOWN_JOIN = 1, VM_RECLAIMED = 2 };

typedef struct {
  uint32_t generation;
  int custody;
  uint32_t retained_roots;
  uint32_t retained_threads;
  uint32_t gc_epoch;
} vm_custody_record;

static void mark_unknown_join(vm_custody_record *v, uint32_t pending_roots, uint32_t pending_threads) {
  v->custody = VM_UNKNOWN_JOIN;
  v->retained_roots += pending_roots;
  v->retained_threads += pending_threads;
}

static int try_reclaim_vm(vm_custody_record *v, uint32_t req_gen) {
  if (v->generation != req_gen)
    return 0;
  if (v->custody != VM_HEALTHY)
    return 0;
  if (v->retained_roots != 0u || v->retained_threads != 0u)
    return 0;
  v->generation += 1u;
  v->custody = VM_RECLAIMED;
  return 1;
}

static int run_gc_on_vm(vm_custody_record *target) {
  if (target->custody != VM_HEALTHY)
    return 0;
  target->gc_epoch += 1u;
  return 1;
}

int main(void) {
  vm_custody_record vm_a = { 1u, VM_HEALTHY, 0u, 0u, 10u };
  vm_custody_record vm_b = { 1u, VM_HEALTHY, 0u, 0u, 20u };

  uint32_t pending_roots = nondet_uint();
  uint32_t pending_threads = nondet_uint();
  __CPROVER_assume(pending_roots >= 1u && pending_roots <= 16u);
  __CPROVER_assume(pending_threads >= 1u && pending_threads <= 8u);

  /* Fault: unknown join on VM A quarantines A without freeing its debt */
  mark_unknown_join(&vm_a, pending_roots, pending_threads);
  CHECK(try_reclaim_vm(&vm_a, 1u) == 0, "f9.unknown-join-blocks-reclaim");
  CHECK(vm_a.retained_roots == pending_roots && vm_a.retained_threads == pending_threads,
        "f9.unknown-join-retains-exact-debt");

  /* Disjoint healthy VM B still completes GC */
  CHECK(run_gc_on_vm(&vm_b) == 1 && vm_b.gc_epoch == 21u,
        "f9.healthy-vm-gc-progress-isolated");

  /* Stale generation cannot reclaim a newer VM generation */
  vm_custody_record vm_c = { 5u, VM_HEALTHY, 0u, 0u, 1u };
  uint32_t stale_gen = nondet_uint();
  __CPROVER_assume(stale_gen < 5u);
  CHECK(try_reclaim_vm(&vm_c, stale_gen) == 0 && vm_c.custody == VM_HEALTHY,
        "f9.stale-generation-reclaim-refused");

  return 0;
}
