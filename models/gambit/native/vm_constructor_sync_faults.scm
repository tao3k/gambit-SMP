(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#if !defined(___USE_POSIX_THREAD_SYSTEM) || defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error This fixture requires POSIX multiple threaded VMs
#endif
extern ___SCMOBJ ___cleanup_owned_vmstate ___P((___virtual_machine_state), ());
struct control {
  void *addresses[4];
  int active, fail_at, injected, initialized[4], destroyed[4], calls[4];
};
static _Thread_local struct control control;
static int (*mutex_init_real)(pthread_mutex_t *, const pthread_mutexattr_t *);
static int (*cond_init_real)(pthread_cond_t *, const pthread_condattr_t *);
static int (*mutex_destroy_real)(pthread_mutex_t *);
static int (*cond_destroy_real)(pthread_cond_t *);
static int index_of(void *address)
{
  int i;
  if (control.active)
    for (i = 0; i < 4; ++i)
      if (control.addresses[i] == address) return i;
  return -1;
}
#define RESOLVE(variable, name, type) do { \
  if (!variable) variable = (type)dlsym(RTLD_NEXT, name); \
  if (!variable) _Exit(80); \
} while (0)
int pthread_mutex_init(pthread_mutex_t *value, const pthread_mutexattr_t *attributes)
{
  int i = index_of(value), result;
  RESOLVE(mutex_init_real, "pthread_mutex_init", int (*)(pthread_mutex_t *, const pthread_mutexattr_t *));
  if (i >= 0 && (++control.calls[i], i == control.fail_at))
    { ++control.injected; return EINVAL; }
  result = mutex_init_real(value, attributes);
  if (i >= 0 && result == 0) control.initialized[i] = 1;
  return result;
}
int pthread_cond_init(pthread_cond_t *value, const pthread_condattr_t *attributes)
{
  int i = index_of(value), result;
  RESOLVE(cond_init_real, "pthread_cond_init", int (*)(pthread_cond_t *, const pthread_condattr_t *));
  if (i >= 0 && (++control.calls[i], i == control.fail_at))
    { ++control.injected; return EINVAL; }
  result = cond_init_real(value, attributes);
  if (i >= 0 && result == 0) control.initialized[i] = 1;
  return result;
}
int pthread_mutex_destroy(pthread_mutex_t *value)
{
  int i = index_of(value), result;
  RESOLVE(mutex_destroy_real, "pthread_mutex_destroy", int (*)(pthread_mutex_t *));
  if (i >= 0 && !control.initialized[i]) _Exit(81);
  result = mutex_destroy_real(value);
  if (i >= 0)
    {
      if (result) _Exit(82);
      control.initialized[i] = 0; ++control.destroyed[i];
    }
  return result;
}
int pthread_cond_destroy(pthread_cond_t *value)
{
  int i = index_of(value), result;
  RESOLVE(cond_destroy_real, "pthread_cond_destroy", int (*)(pthread_cond_t *));
  if (i >= 0 && !control.initialized[i]) _Exit(83);
  result = cond_destroy_real(value);
  if (i >= 0)
    {
      if (result) _Exit(84);
      control.initialized[i] = 0; ++control.destroyed[i];
    }
  return result;
}
static _Atomic int completed;
static void *owner(void *unused)
{
  int mode, i;
  (void)unused;
  for (mode = 0; mode < 4; ++mode)
    {
      ___virtual_machine_state vm = calloc(1, sizeof(*vm));
      ___processor_state ps;
      ___SCMOBJ result;
      if (!vm) _Exit(85);
      ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
      control = (struct control){0};
      control.addresses[0] = &vm->mem.scan_termination_mutex_;
      control.addresses[1] = &vm->mem.scan_termination_condvar_;
      control.addresses[2] = &ps->sync_mut;
      control.addresses[3] = &ps->sync_cv;
      control.fail_at = mode; control.active = 1;
      result = ___GSTATE->___setup_vmstate(vm);
      if (result != ___FIX(___UNKNOWN_ERR) || control.injected != 1 ||
          vm->processor_count != 0 || vm->glos || vm->mem.the_msections_ ||
          ps->sync_resources_ready || ps->procedural_interrupts_ready || vm->next || vm->prev)
        {
          fprintf(stderr, "constructor mode=%d error=%ld injected=%d count=%d sync=%d interrupt=%d\n",
                  mode, (long)___INT(result), control.injected, vm->processor_count,
                  ps->sync_resources_ready, ps->procedural_interrupts_ready);
          _Exit(86);
        }
      for (i = 0; i < 4; ++i)
        if (control.calls[i] != (i <= mode) || control.destroyed[i] != (i < mode) ||
            control.initialized[i]) _Exit(87);
      control.active = 0;
      /* Retry the same private storage with the actual successful constructor. */
      if (___GSTATE->___setup_vmstate(vm) != ___FIX(___NO_ERR) || vm->processor_count != 1)
        _Exit(88);
      ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
      if (___GSTATE->___thread_init_from_self(&ps->os_thread) != ___FIX(___NO_ERR)) _Exit(89);
      ___SET_REAL_PSTATE(ps);
      vm->main_module_ref = ___GSTATE->vmstate0.main_module_ref;
      if (___cleanup_owned_vmstate(vm) != ___FIX(___NO_ERR)) _Exit(90);
      ___SET_REAL_PSTATE(NULL);
      free(vm);
    }
  atomic_fetch_add(&completed, 1);
  return NULL;
}
static void start(void)
{
  const char *value = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = value ? strtol(value, &end, 10) : 0;
  int count, i;
  pthread_t *threads;
  if (!value || *end || cpu < 2 || cpu > INT_MAX) _Exit(91);
  count = (int)(cpu - 1);
  RESOLVE(mutex_init_real, "pthread_mutex_init", int (*)(pthread_mutex_t *, const pthread_mutexattr_t *));
  RESOLVE(cond_init_real, "pthread_cond_init", int (*)(pthread_cond_t *, const pthread_condattr_t *));
  RESOLVE(mutex_destroy_real, "pthread_mutex_destroy", int (*)(pthread_mutex_t *));
  RESOLVE(cond_destroy_real, "pthread_cond_destroy", int (*)(pthread_cond_t *));
  threads = calloc(count, sizeof(*threads));
  if (!threads) _Exit(92);
  for (i = 0; i < count; ++i)
    if (pthread_create(&threads[i], NULL, owner, NULL)) _Exit(93);
  for (i = 0; i < count; ++i)
    if (pthread_join(threads[i], NULL)) _Exit(94);
  free(threads);
  if (atomic_load(&completed) != count) _Exit(95);
  ___MUTEX_LOCK(___GSTATE->vm_list_mut);
  if (___GSTATE->vmstate0.next != &___GSTATE->vmstate0 ||
      ___GSTATE->vmstate0.prev != &___GSTATE->vmstate0) _Exit(96);
  ___MUTEX_UNLOCK(___GSTATE->vm_list_mut);
}
c-end
)
((c-lambda () void "start"))
(display "CONSTRUCTOR-SYNC-FAULTS:PASS\n")
