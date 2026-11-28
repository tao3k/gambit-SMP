;;; Public loader/FFI only; never call destruction with unjoined direct users.
(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <time.h>
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error Multiple threaded VMs required
#endif
struct item { ___procedural_interrupt_header header; int hold; };
static ___processor_state target;
static _Atomic int callback_entered, callback_release, callback_returned;
static _Atomic int executed, released, wrong_release, broadcasting, broadcasts;
static _Atomic int producers_ready, producers_begin;
static void tick(void) {
  const struct timespec delay = {0, 1000000};
  nanosleep(&delay, NULL);
}
static ___SCMOBJ invoke(void *self, ___SCMOBJ op) {
  struct item *item = self;
  if (op == ___TRU) {
    if (item->hold) {
      atomic_store(&callback_entered, 1);
      while (!atomic_load(&callback_release)) tick();
      atomic_store(&callback_returned, 1);
    }
    atomic_fetch_add(&executed, 1);
  } else {
    if (op != ___FAL || !target->procedural_interrupts_ready)
      atomic_fetch_add(&wrong_release, 1);
    atomic_fetch_add(&released, 1);
  }
  return ___FIX(___NO_ERR);
}
static void *consume(void *ignored) {
  (void)ignored;
  if (___GSTATE->___thread_init_from_self(&target->os_thread) != ___FIX(___NO_ERR))
    _Exit(71);
  ___SET_REAL_PSTATE(target);
  ___GSTATE->___enable_interrupts_pstate(target);
  if (___GSTATE->___service_interrupts_pstate(target) != ___FIX(___INTR_OTHER))
    _Exit(72);
  ___SET_REAL_PSTATE(NULL);
  return NULL;
}
static void *produce(void *argument) {
  atomic_fetch_add(&producers_ready, 1);
  while (!atomic_load(&producers_begin)) tick();
  ___GSTATE->___raise_procedural_interrupt_pstate(target, argument);
  return NULL;
}
static void *broadcast(void *ignored) {
  (void)ignored;
  while (atomic_load(&broadcasting)) {
    ___GSTATE->___raise_interrupt(___INTR_OTHER);
    atomic_fetch_add(&broadcasts, 1);
    tick();
  }
  return NULL;
}
static int queue_count(void) {
  ___procedural_interrupt_header *p;
  int count = 0;
  ___MUTEX_LOCK(target->procedural_interrupts_mut);
  for (p = target->procedural_interrupts_head; p; p = p->next) ++count;
  ___MUTEX_UNLOCK(target->procedural_interrupts_mut);
  return count;
}
static int check(void) {
  const char *value = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = value ? strtol(value, &end, 10) : 0;
  ___virtual_machine_state vm;
  struct item held = {0}, *items;
  pthread_t consumer, global, *threads;
  int count, i, broadcasts_before_cleanup;
  if (!value || *end || cpu < 2 || cpu > INT_MAX / 2) return 0;
  count = (int)cpu - 1;
  vm = calloc(1, sizeof(*vm));
  items = calloc(2 * count, sizeof(*items));
  threads = calloc(count, sizeof(*threads));
  if (!vm || !items || !threads) _Exit(73);
  if (___GSTATE->___setup_vmstate(vm) != ___FIX(___NO_ERR)) _Exit(74);
  target = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  held.hold = 1;
  ___GSTATE->___init_procedural_interrupt(&held, invoke);
  for (i = 0; i < 2 * count; ++i)
    ___GSTATE->___init_procedural_interrupt(&items[i], invoke);
  ___GSTATE->___raise_procedural_interrupt_pstate(target, &held);
  if (pthread_create(&consumer, NULL, consume, NULL)) _Exit(75);
  while (!atomic_load(&callback_entered)) tick();
  if (queue_count() != 0 || atomic_load(&callback_returned) ||
      !target->procedural_interrupts_ready) _Exit(76);
  for (i = 0; i < count; ++i)
    if (pthread_create(&threads[i], NULL, produce, &items[i])) _Exit(77);
  while (atomic_load(&producers_ready) != count) tick();
  atomic_store(&producers_begin, 1);
  for (i = 0; i < count; ++i)
    if (pthread_join(threads[i], NULL)) _Exit(78);
  if (queue_count() != count || atomic_load(&callback_returned)) _Exit(79);
  atomic_store(&callback_release, 1);
  if (pthread_join(consumer, NULL) || atomic_load(&executed) != count + 1 ||
      queue_count() != 0) _Exit(80);
  // Consumers and producers are joined before cleanup; resources stay alive.
  for (i = count; i < 2 * count; ++i)
    ___GSTATE->___raise_procedural_interrupt_pstate(target, &items[i]);
  if (queue_count() != count) _Exit(81);
  atomic_store(&broadcasting, 1);
  if (pthread_create(&global, NULL, broadcast, NULL)) _Exit(82);
  while (!atomic_load(&broadcasts)) tick();
  broadcasts_before_cleanup = atomic_load(&broadcasts);
  ___GSTATE->___cleanup_vmstate(vm);
  // Keep global broadcasts alive after child unlink, without any stale pointer.
  while (atomic_load(&broadcasts) <= broadcasts_before_cleanup) tick();
  atomic_store(&broadcasting, 0);
  if (pthread_join(global, NULL) || target->procedural_interrupts_ready ||
      atomic_load(&released) != count || atomic_load(&wrong_release) ||
      ___GSTATE->vmstate0.next != &___GSTATE->vmstate0) _Exit(83);
  free(threads); free(items); free(vm);
  return 1;
}
c-end
)
(if (not ((c-lambda () bool "check"))) (error "procedural interrupt retirement failed"))
(display "PROCEDURAL-INTERRUPT-RETIREMENT:PASS\n")
