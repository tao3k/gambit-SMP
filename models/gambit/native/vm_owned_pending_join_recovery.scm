(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <limits.h>

#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error This fixture requires multiple threaded VMs
#endif
extern ___SCMOBJ ___cleanup_owned_vmstate ___P((___virtual_machine_state), ());
extern ___SCMOBJ ___cleanup_checked ___PVOID;
static _Thread_local int owner_id, cohort;
struct worker {
  int id, processors, accepted;
  _Atomic(___virtual_machine_state) vm;
  _Atomic int armed, injected;
};
static struct worker *all_workers;
static int worker_count;
static struct worker *current_worker(void)
{
  ___processor_state ps = ___PSTATE;
  int i;
  if (!ps) return NULL;
  for (i = 0; i < worker_count; ++i)
    if (atomic_load(&all_workers[i].vm) == ___VMSTATE_FROM_PSTATE(ps))
      return &all_workers[i];
  return NULL;
}
static void arm_current_vm(void)
{
  struct worker *w = current_worker();
  if (!w) _Exit(95);
  atomic_store(&w->armed, 1);
}
static int (*real_join)(pthread_t, void **);
static _Atomic int ready, release_owners, failed, stop_interrupts;
static _Atomic unsigned interrupts;

/* Interpose only this executable. Assertions below reject an ineffective hook. */
int pthread_join(pthread_t thread, void **result)
{
  struct worker *w = current_worker();
  if (w && atomic_exchange(&w->armed, 0))
    { atomic_fetch_add(&w->injected, 1); return EINVAL; }
  if (!real_join) _Exit(80);
  return real_join(thread, result);
}

static void *interrupt_main(void *unused)
{
  const struct timespec pause = {0, 1000000};
  (void)unused;
  while (!atomic_load(&stop_interrupts))
    {
      ___raise_interrupt(___INTR_HEARTBEAT);
      atomic_fetch_add(&interrupts, 1);
      nanosleep(&pause, NULL);
    }
  return NULL;
}

static void *worker_main(void *argument)
{
  struct worker *w = argument;
  ___virtual_machine_state vm = calloc(1, sizeof(*vm));
  ___processor_state ps;
  ___SCMOBJ module, thunk, err;
  if (!vm) _Exit(81);
  owner_id = w->id; cohort = w->processors;
  module = ___GSTATE->vmstate0.main_module_ref;
  thunk = ___VECTORELEM(___VECTORELEM(___VECTORELEM(___GSTATE->program_descr, 0), 0),
                        ___MODULE_DESCR_THUNK);
  if (___HD_TYP(___HEADER(module)) != ___PERM || ___HD_TYP(___HEADER(thunk)) != ___PERM)
    _Exit(82);
  err = ___GSTATE->___setup_vmstate(vm);
  if (err != ___FIX(___NO_ERR)) _Exit(83);
  ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  err = ___GSTATE->___thread_init_from_self(&ps->os_thread);
  if (err != ___FIX(___NO_ERR)) _Exit(84);
  ___SET_REAL_PSTATE(ps);
  vm->main_module_ref = module;
  atomic_store(&w->vm, vm);
  err = ___GSTATE->___run(___PSA(ps) thunk);
  if (err != ___FIX(___NO_ERR) || vm->processor_count != 1 || atomic_load(&w->injected) != 1 ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 1)
    {
      fprintf(stderr, "post-run err=%ld processors=%d injected=%d pending=%d\n",
              (long)___INT(err), vm->processor_count, atomic_load(&w->injected),
              __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE));
      _Exit(85);
    }
  atomic_fetch_add(&ready, 1);
  while (!atomic_load(&release_owners))
    { const struct timespec pause = {0, 1000000}; nanosleep(&pause, NULL); }
  atomic_store(&w->armed, 1);
  err = ___cleanup_owned_vmstate(vm);
  if (err == ___FIX(___NO_ERR) || atomic_load(&w->injected) != 2 ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 1)
    _Exit(86);
  err = ___cleanup_owned_vmstate(vm);
  if (err != ___FIX(___NO_ERR) || atomic_load(&w->injected) != 2 ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 0)
    _Exit(87);
  w->accepted = 1;
  atomic_store(&w->vm, NULL);
  ___SET_REAL_PSTATE(NULL);
  free(vm);
  return NULL;
}

static int start(void)
{
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  int count, i, launched = 0;
  pthread_t interrupt_thread, *threads;
  struct worker *workers;
  if (!capacity || *end || cpu < 6 || cpu > INT_MAX) return 0;
  count = (int)((cpu - 2) / 2);
  real_join = (int (*)(pthread_t, void **))dlsym(RTLD_NEXT, "pthread_join");
  if (!real_join || real_join == pthread_join) return 0;
  threads = calloc(count, sizeof(*threads));
  workers = calloc(count, sizeof(*workers));
  if (!threads || !workers) _Exit(88);
  all_workers = workers; worker_count = count;
  if (pthread_create(&interrupt_thread, NULL, interrupt_main, NULL)) _Exit(89);
  for (i = 0; i < count; ++i)
    {
      workers[i].id = i + 1;
      workers[i].processors = (int)((cpu - 2) / count) + (i < (cpu - 2) % count);
      if (workers[i].processors > ___MAX_PROCESSORS) _Exit(90);
      if (pthread_create(&threads[i], NULL, worker_main, &workers[i])) _Exit(91);
      ++launched;
    }
  while (atomic_load(&ready) != count)
    { const struct timespec pause = {0, 1000000}; nanosleep(&pause, NULL); }
  /* Reject while pending cohorts are published; do not enter global teardown. */
  if (___cleanup_checked() == ___FIX(___NO_ERR) || ___GSTATE->setup_state != 1)
    _Exit(92);
  atomic_store(&release_owners, 1);
  for (i = 0; i < launched; ++i)
    if (pthread_join(threads[i], NULL) || !workers[i].accepted) _Exit(93);
  atomic_store(&stop_interrupts, 1);
  if (pthread_join(interrupt_thread, NULL) || atomic_load(&interrupts) == 0) _Exit(94);
  free(workers); free(threads);
  return !atomic_load(&failed);
}
c-end
)

(define owner ((c-lambda () int "___return(owner_id);")))
(define processors ((c-lambda () int "___return(cohort);")))
(define arm! (c-lambda () void "arm_current_vm();"))
(define (require condition message) (if (not condition) (error message)))

(if (= owner 0)
    (begin
      (require ((c-lambda () bool "start")) "join recovery fixture failed")
      (display "PENDING-JOIN-RECOVERY:PASS\n"))
    (begin
      (##current-vm-resize ##startup-processor! processors)
      (let ((threads
             (map (lambda (index)
                    (let ((t (make-thread
                               (lambda ()
                                 (require (= (processor-id (current-processor)) index)
                                          "worker processor mismatch")
                                 (let ((root (make-vector 256 owner)))
                                   (##gc)
                                   (require (= (vector-ref root 255) owner)
                                            "cross-VM root corruption"))
                                 #t))))
                      (##thread-pin! t (##processor index))
                      (thread-start! t)
                      t))
                  (let loop ((i 0))
                    (if (= i processors) '() (cons i (loop (+ i 1))))))))
        (for-each (lambda (t) (require (eq? (thread-join! t) #t) "worker incomplete"))
                  threads))
      (arm!)
      (require
        (with-exception-catcher (lambda (e) #t)
          (lambda () (##current-vm-resize ##startup-processor! 1) #f))
        "injected resize join must fail")))
