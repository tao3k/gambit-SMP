(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <limits.h>

#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS) || ___MAX_PROCESSORS < 2
#error This fixture requires multiple VMs and multiple threaded VMs
#endif

extern ___SCMOBJ ___cleanup_owned_vmstate ___P((___virtual_machine_state), ());

static _Thread_local int fixture_vm_id;
static _Atomic unsigned fixture_ready;
static _Atomic unsigned fixture_done;
static _Atomic int fixture_failed;
static _Thread_local int fixture_cohort;
static int fixture_vm_count;
static int fixture_cycles;
static _Atomic int fixture_stop_interrupts;
static _Atomic unsigned fixture_interrupts;
static _Atomic int *fixture_phase;
static void fixture_mark(int owner, int phase, int cycle)
{
  if (owner <= 0 || owner > fixture_vm_count) _Exit(75);
  atomic_store(&fixture_phase[owner], cycle * 100 + phase);
}

static void *fixture_interrupt_main(void *unused)
{
  const struct timespec pause = {0, 1000000};
  struct timespec start, now;
  int reported = 0;
  (void)unused;
  clock_gettime(CLOCK_MONOTONIC, &start);
  while (!atomic_load(&fixture_stop_interrupts))
    {
      ___raise_interrupt(___INTR_HEARTBEAT);
      atomic_fetch_add(&fixture_interrupts, 1);
      nanosleep(&pause, NULL);
      clock_gettime(CLOCK_MONOTONIC, &now);
      if (!reported && now.tv_sec - start.tv_sec >= 10)
        {
          int i;
          fprintf(stderr, "topology=%d ready=%u done=%u phases=",
                  fixture_vm_count, atomic_load(&fixture_ready), atomic_load(&fixture_done));
          for (i = 1; i <= fixture_vm_count; ++i)
            fprintf(stderr, "%s%d:%d", i == 1 ? "" : ",", i, atomic_load(&fixture_phase[i]));
          fputc('\n', stderr);
          reported = 1;
        }
    }
  return NULL;
}
struct fixture_worker { int id; int processors; int accepted; };

static void *fixture_worker_main(void *argument)
{
  struct fixture_worker *worker = argument;
  ___virtual_machine_state vm = calloc(1, sizeof(*vm));
  ___processor_state ps;
  ___SCMOBJ thunk, module, err;
  if (!vm) { atomic_store(&fixture_failed, 1); return NULL; }
  fixture_vm_id = worker->id;
  fixture_cohort = worker->processors;
  module = ___GSTATE->vmstate0.main_module_ref;
  thunk = ___VECTORELEM(___VECTORELEM(___VECTORELEM(___GSTATE->program_descr, 0), 0),
                        ___MODULE_DESCR_THUNK);
  if (___HD_TYP(___HEADER(module)) != ___PERM || ___HD_TYP(___HEADER(thunk)) != ___PERM)
    { atomic_store(&fixture_failed, 1); free(vm); return NULL; }
  err = ___GSTATE->___setup_vmstate(vm);
  if (err != ___FIX(___NO_ERR))
    { atomic_store(&fixture_failed, 1); free(vm); return NULL; }
  ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  err = ___GSTATE->___thread_init_from_self(&ps->os_thread);
  if (err != ___FIX(___NO_ERR))
    { atomic_store(&fixture_failed, 1); return NULL; }
  ___SET_REAL_PSTATE(ps);
  vm->main_module_ref = module;
  err = ___GSTATE->___run(___PSA(ps) thunk);
  if (err != ___FIX(___NO_ERR) || vm->processor_count != 1)
    { atomic_store(&fixture_failed, 1); return NULL; }
  worker->accepted = 1;
  fixture_mark(worker->id, 9, 0);
  err = ___cleanup_owned_vmstate(vm);
  if (err != ___FIX(___NO_ERR))
    { atomic_store(&fixture_failed, 1); return NULL; }
  fixture_mark(worker->id, 10, 0);
  ___SET_REAL_PSTATE(NULL);
  free(vm);
  return NULL;
}

static int fixture_start(void)
{
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  int count, maximum, i;
  if (!capacity || *end || cpu < 6 || cpu > INT_MAX) return 0;
  maximum = (int)((cpu - 2) / 2);
  fixture_cycles = cpu > 16 ? (int)cpu : 16;
  for (count = 2; count <= maximum; ++count)
    {
      pthread_t interrupt_thread;
      pthread_t *threads = calloc(count, sizeof(*threads));
      struct fixture_worker *workers = calloc(count, sizeof(*workers));
      int launched = 0, base = (int)((cpu - 2) / count);
      int remainder = (int)((cpu - 2) % count);
      if (!threads || !workers) { free(threads); free(workers); return 0; }
      if (base + (remainder != 0) > ___MAX_PROCESSORS)
        { free(threads); free(workers); continue; }
      fixture_vm_count = count;
      fixture_phase = calloc(count + 1, sizeof(*fixture_phase));
      if (!fixture_phase) _Exit(76);
      atomic_store(&fixture_ready, 0);
      atomic_store(&fixture_done, 0);
      atomic_store(&fixture_failed, 0);
      atomic_store(&fixture_stop_interrupts, 0);
      atomic_store(&fixture_interrupts, 0);
      if (pthread_create(&interrupt_thread, NULL, fixture_interrupt_main, NULL) != 0)
        { free(threads); free(workers); return 0; }
      for (i = 0; i < count; ++i)
        {
          workers[i].id = i + 1;
          workers[i].processors = base + (i < remainder);
          if (pthread_create(&threads[i], NULL, fixture_worker_main, &workers[i]) != 0)
            { atomic_store(&fixture_failed, 1); break; }
          ++launched;
        }
      for (i = 0; i < launched; ++i)
        if (pthread_join(threads[i], NULL) != 0)
          { fputs("VM fixture join failed; resources retained\n", stderr); _Exit(70); }
      atomic_store(&fixture_stop_interrupts, 1);
      if (pthread_join(interrupt_thread, NULL) != 0)
        { fputs("Interrupt reader join failed; resources retained\n", stderr); _Exit(72); }
      if (atomic_load(&fixture_interrupts) == 0)
        { fputs("No global interrupt overlap observed\n", stderr); _Exit(73); }
      if (launched != count || atomic_load(&fixture_failed) ||
          atomic_load(&fixture_ready) != (unsigned)count ||
          atomic_load(&fixture_done) != (unsigned)count)
        { fputs("VM topology failed; resources retained\n", stderr); _Exit(71); }
      for (i = 0; i < count; ++i)
        if (!workers[i].accepted) _Exit(71);
      free(fixture_phase);
      fixture_phase = NULL;
      free(workers);
      free(threads);
    }
  return fixture_vm_count == maximum;
}

static void fixture_arrive(void)
{ atomic_fetch_add(&fixture_ready, 1); }
static int fixture_both_ready(void) { return atomic_load(&fixture_ready) == (unsigned)fixture_vm_count; }
static int fixture_aborted(void) { return atomic_load(&fixture_failed); }
static void fixture_complete(void)
{ atomic_fetch_add(&fixture_done, 1); }
c-end
)

(define fixture-owner ((c-lambda () int "___return(fixture_vm_id);")))
(define fixture-target ((c-lambda () int "___return(fixture_cohort);")))
(define fixture-rounds ((c-lambda () int "___return(fixture_cycles);")))
(define arrive! (c-lambda () void "fixture_arrive"))
(define both-ready? (c-lambda () bool "fixture_both_ready"))
(define aborted? (c-lambda () bool "fixture_aborted"))
(define complete! (c-lambda () void "fixture_complete"))
(define mark! (c-lambda (int int int) void "fixture_mark"))

(define (require condition message)
  (if (not condition) (error message)))

(if (= fixture-owner 0)
    (begin
      (require ((c-lambda () bool "fixture_start")) "independent VM fixture failed")
      (display "REGISTRY-TOPOLOGY-GRID:PASS\n"))
    (let resize-cycle ((cycle 0))
      (mark! fixture-owner 1 cycle)
      (##current-vm-resize ##startup-processor! fixture-target)
      (mark! fixture-owner 2 cycle)
      (require (= (##current-vm-processor-count) fixture-target) "VM cohort mismatch")
      (if (= cycle 0) (arrive!))
      (let wait ()
        (require (not (aborted?)) "peer VM failed")
        (if (not (both-ready?)) (begin (thread-yield!) (wait))))
      (mark! fixture-owner 3 cycle)
      (let ((threads
              (map (lambda (index)
                     (let ((thread
                             (make-thread
                               (lambda ()
                                 (require (= (processor-id (current-processor)) index)
                                          "worker did not execute on its processor")
                                 (let loop ((round 0) (roots '()))
                                   (if (= round 8)
                                       (begin
                                         (for-each
                                           (lambda (root)
                                             (require (= (vector-ref root 0) fixture-owner)
                                                      "cross-VM root corruption"))
                                           roots)
                                         #t)
                                       (let ((payload (make-vector 256 fixture-owner)))
                                         (##gc)
                                         (require (= (vector-ref payload 255) fixture-owner)
                                                  "GC root corruption")
                                         (loop (+ round 1) (cons payload roots)))))))))
                       (##thread-pin! thread (##processor index))
                       (thread-start! thread)
                       thread))
                   (let indices ((index 0))
                     (if (= index fixture-target) '()
                         (cons index (indices (+ index 1))))))))
        (for-each (lambda (thread)
                    (require (eq? (thread-join! thread) #t) "worker did not complete"))
                  threads))
      (mark! fixture-owner 7 cycle)
      (##current-vm-resize ##startup-processor! 1)
      (mark! fixture-owner 8 cycle)
      (require (= (##current-vm-processor-count) 1) "VM cohort did not drain")
      (if (= (+ cycle 1) fixture-rounds) (complete!) (resize-cycle (+ cycle 1)))))
