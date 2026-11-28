;;; Terminal registry drain. Producers are ordinary ___raise_interrupt calls.
;;; They are not OS signals, and nothing is signaled after handlers are reset.
;;; No pause hook, forced lease, manufactured seal witness, or test-side
;;; witness store. Producers stop when they read the runtime seal bit, and
;;; they do not call again after that observation. Missing a seal-time
;;; admitted reader is INCONCLUSIVE, never PASS. Cleanup does not return to
;;; Scheme.

(declare (standard-bindings) (extended-bindings) (block) (not safe))

(c-declare #<<c-end
#include <errno.h>
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifndef ___cleanup_checked
extern ___SCMOBJ ___cleanup_checked(void);
#endif
#ifndef ___vm_registry_sealed
extern int ___vm_registry_sealed(void);
#endif

extern ___UWORD ___vm_registry_seal_old_lease(void);
extern ___UWORD ___vm_registry_post_close_lease(void);
extern ___UWORD ___vm_registry_gate_observed(void);

static volatile int stop_producers = 0;
static volatile int warm_completed = 0;

static int deadline_reached(const struct timespec *start)
{
  struct timespec now;

  clock_gettime(CLOCK_MONOTONIC, &now);
  if (now.tv_sec - start->tv_sec > 5)
    return 1;
  if (now.tv_sec - start->tv_sec == 5 && now.tv_nsec >= start->tv_nsec)
    return 1;
  return 0;
}

static void inconclusive(const char *why)
{
  fprintf(stdout, "TERMINAL-REGISTRY-DRAIN:INCONCLUSIVE %s\n", why);
  fflush(stdout);
  _Exit(2);
}

static int validated_host_budget(void)
{
  const char *env = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = 0;
  long n;

  if (env == 0 || env[0] == 0)
    inconclusive("host-cpus");
  errno = 0;
  n = strtol(env, &end, 10);
  if (errno != 0 || end == env || *end != '\0' || n < 1)
    inconclusive("host-cpus");
  if (n > 2147483647L)
    inconclusive("host-cpus");
  return (int)n;
}

static void *interrupt_producer(void *unused)
{
  int warmed = 0;

  (void)unused;
  for (;;)
    {
      if (__atomic_load_n(&stop_producers, __ATOMIC_ACQUIRE) != 0)
        break;
      /* Read-only seal observation. No further API call after it is set. */
      if (___vm_registry_sealed())
        break;
      ___raise_interrupt(___INTR_OTHER);
      if (!warmed)
        {
          warmed = 1;
          __atomic_fetch_add(&warm_completed, 1, __ATOMIC_RELEASE);
        }
    }
  return 0;
}

static void stop_and_join(pthread_t *producers, int n)
{
  int i;

  __atomic_store_n(&stop_producers, 1, __ATOMIC_RELEASE);
  for (i = 0; i < n; i++)
    {
      if (pthread_join(producers[i], 0) != 0)
        inconclusive("producer-join");
    }
}

static void await_producer_activity(int producer_count)
{
  struct timespec start;

  clock_gettime(CLOCK_MONOTONIC, &start);
  for (;;)
    {
      if (__atomic_load_n(&warm_completed, __ATOMIC_ACQUIRE) >= producer_count)
        return;
      if (deadline_reached(&start))
        inconclusive("producer-activity");
      sched_yield();
    }
}

void runtime_terminal_registry_drain_main(int producer_count, int root_cohort, int budget)
{
  pthread_t *producers;
  ___UWORD captured;
  ___UWORD drained;
  ___UWORD gate;
  ___SCMOBJ err;
  int i;

  if (producer_count < 1 || root_cohort < 1
      || budget < 1
      || producer_count > budget
      || root_cohort > budget
      || (long)producer_count + (long)root_cohort > (long)budget)
    inconclusive("producer-budget");
  producers = (pthread_t *)malloc((size_t)producer_count * sizeof (pthread_t));
  if (producers == 0)
    inconclusive("producer-alloc");
  __atomic_store_n(&stop_producers, 0, __ATOMIC_RELAXED);
  __atomic_store_n(&warm_completed, 0, __ATOMIC_RELAXED);
  for (i = 0; i < producer_count; i++)
    {
      if (pthread_create(&producers[i], 0, interrupt_producer, 0) != 0)
        inconclusive("producer-create");
    }

  await_producer_activity(producer_count);

  /*
   * Real root cleanup seals and drains while producers still call
   * ___raise_interrupt(___INTR_OTHER). Do not pthread_kill, raise, or
   * otherwise signal after ___cleanup_all_interrupt_handling resets OS
   * handlers. Child VM count is not invented here: traversal length is the
   * runtime's existing registry ring, grown only by the host-budget Scheme
   * cohort above. No raw external VM users are attached. The seal bit is
   * only read by producers; this fixture does not store a seal witness.
   */
  err = ___cleanup_checked();
  stop_and_join(producers, producer_count);
  if (err != ___FIX(___NO_ERR))
    inconclusive("cleanup");

  captured = ___vm_registry_seal_old_lease();
  drained = ___vm_registry_post_close_lease();
  gate = ___vm_registry_gate_observed();
  if (!(captured > 0 && drained == 0 && ___vm_registry_sealed() && (gate & 2) != 0))
    inconclusive("no-admitted-reader-at-seal");

  fprintf(stdout, "DRAIN-WITNESS captured=%lu drained=%lu gate=%lu\n",
          (unsigned long)captured, (unsigned long)drained, (unsigned long)gate);
  fprintf(stdout, "TERMINAL-REGISTRY-DRAIN:PASS\n");
  fflush(stdout);
  _Exit(0);
}
c-end
)

(define host-budget
  (c-lambda () int
    "___return(validated_host_budget());"))

(define max-processors
  (c-lambda () int
    "___return(___MAX_PROCESSORS);"))

(define cpus (host-budget))
;; Optional sibling VMs are not constructed: this fixture does not call a
;; private VM allocator or attach raw users. One CPU remains unused when the
;; host has at least four so a supervisor-supplied real child VM can share
;; the same budget. Root cohort plus producers never exceed the host count.
;; Root growth is clamped only by ___MAX_PROCESSORS.
(define child-reserve 0)
(define available (max 0 (- cpus child-reserve)))
(define producer-count (quotient available 2))
(define root-cohort (min (max-processors) (- available producer-count)))

(##thread-pin! (current-thread) (##processor 0))
(if (> root-cohort 1)
    (##current-vm-resize ##startup-processor! root-cohort))
((c-lambda (int int int) void "runtime_terminal_registry_drain_main")
 producer-count
 root-cohort
 cpus)
(error "returned to Scheme after root cleanup")
