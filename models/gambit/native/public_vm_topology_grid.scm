(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <time.h>

#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS) || ___MAX_PROCESSORS < 2
#error Public topology qualification requires all concurrency flags
#endif

static _Thread_local int fixture_owner;
static _Thread_local int fixture_processors;
static int fixture_count;
static int fixture_cycles;
static _Atomic unsigned fixture_ready;
static _Atomic unsigned fixture_done;
static _Atomic int fixture_failed;
static _Atomic int fixture_stop;
static _Atomic unsigned fixture_interrupts;
struct fixture_worker { int id; int processors; int accepted; };

static void *fixture_interrupt_main(void *unused)
{
  const struct timespec pause = {0, 1000000};
  (void)unused;
  while (!atomic_load(&fixture_stop))
    {
      ___raise_interrupt(___INTR_HEARTBEAT);
      atomic_fetch_add(&fixture_interrupts, 1);
      nanosleep(&pause, NULL);
    }
  return NULL;
}

static void *fixture_worker_main(void *argument)
{
  struct fixture_worker *worker = argument;
  ___virtual_machine_state vm = calloc(1, sizeof(*vm));
  ___processor_state ps;
  ___SCMOBJ module, thunk, err;
  if (!vm) { atomic_store(&fixture_failed, 1); return NULL; }
  fixture_owner = worker->id;
  fixture_processors = worker->processors;
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
  /* Successful shrink must account for retired joins, not just public count. */
  if (err != ___FIX(___NO_ERR) || vm->processor_count != 1 ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 0 ||
      ___COMPARE_AND_SWAP_WORD(&ps->sfun_frame_count, 0, 0) != 0)
    { atomic_store(&fixture_failed, 1); return NULL; }
  /* Both supported public owner paths run while registry interrupts continue.
     Even owners clean P0 first; odd owners let VM cleanup own its OS resource.
     Direct Scheme users were joined before run returned. No private export. */
  if (worker->id % 2 == 0) ___GSTATE->___cleanup_pstate(ps);
  ___GSTATE->___cleanup_vmstate(vm);
  ___SET_REAL_PSTATE(NULL);
  free(vm);
  worker->accepted = 1;
  return NULL;
}

static int fixture_start(void)
{
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  int count, maximum, i;
  if (!capacity || *end || cpu < 6 || cpu > INT_MAX) return 0;
  /* Reserve root and interrupt reader; each child exercises at least two CPUs. */
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
        { free(threads); free(workers); return 0; }
      fixture_count = count;
      atomic_store(&fixture_ready, 0);
      atomic_store(&fixture_done, 0);
      atomic_store(&fixture_failed, 0);
      atomic_store(&fixture_stop, 0);
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
          { fputs("Public VM owner join failed; resources retained\n", stderr); _Exit(70); }
      atomic_store(&fixture_stop, 1);
      if (pthread_join(interrupt_thread, NULL) != 0) _Exit(72);
      if (launched != count || atomic_load(&fixture_failed) ||
          atomic_load(&fixture_ready) != (unsigned)count ||
          atomic_load(&fixture_done) != (unsigned)count ||
          atomic_load(&fixture_interrupts) == 0) _Exit(71);
      for (i = 0; i < count; ++i)
        if (!workers[i].accepted) _Exit(71);
      free(workers);
      free(threads);
    }
  return fixture_count == maximum;
}
c-end
)

(define owner ((c-lambda () int "___return(fixture_owner);")))
(define processors ((c-lambda () int "___return(fixture_processors);")))
(define cycles ((c-lambda () int "___return(fixture_cycles);")))
(define arrive! (c-lambda () void "atomic_fetch_add(&fixture_ready, 1);"))
(define complete! (c-lambda () void "atomic_fetch_add(&fixture_done, 1);"))
(define ready? (c-lambda () bool "___return(atomic_load(&fixture_ready) == (unsigned)fixture_count);"))
(define failed? (c-lambda () bool "___return(atomic_load(&fixture_failed));"))
(define (require condition message)
  (if (not condition) (error message)))

(if (= owner 0)
    (begin
      (require ((c-lambda () bool "fixture_start")) "public VM topology failed")
      (display "PUBLIC-VM-TOPOLOGY-GRID:PASS\n"))
    (let resize-cycle ((cycle 0))
      (##current-vm-resize ##startup-processor! processors)
      (require (= (##current-vm-processor-count) processors) "cohort mismatch")
      (if (= cycle 0) (arrive!))
      (let wait ()
        (require (not (failed?)) "peer VM failed")
        (if (not (ready?)) (begin (thread-yield!) (wait))))
      (let ((threads
              (map
                (lambda (index)
                  (let ((thread
                          (make-thread
                            (lambda ()
                              (require (= (processor-id (current-processor)) index)
                                       "processor pin mismatch")
                              (let loop ((round 0) (roots '()))
                                (if (= round 8)
                                    (begin
                                      (for-each
                                        (lambda (root)
                                          (require (= (vector-ref root 0) owner)
                                                   "cross-VM root corruption")) roots)
                                      #t)
                                    (let ((payload (make-vector 256 owner)))
                                      (##gc)
                                      (require (= (vector-ref payload 255) owner)
                                               "GC root corruption")
                                      (loop (+ round 1) (cons payload roots)))))))))
                    (##thread-pin! thread (##processor index))
                    (thread-start! thread)
                    thread))
                (let indices ((index 0))
                  (if (= index processors) '() (cons index (indices (+ index 1))))))))
        (for-each
          (lambda (thread) (require (eq? (thread-join! thread) #t) "worker failure"))
          threads))
      (##current-vm-resize ##startup-processor! 1)
      (require (= (##current-vm-processor-count) 1) "cohort did not drain")
      (if (= (+ cycle 1) cycles) (complete!) (resize-cycle (+ cycle 1)))))
