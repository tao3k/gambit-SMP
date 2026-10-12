#include <stdio.h>
#include <stdlib.h>

typedef int ___SCMOBJ;
typedef struct { int unused; } ___actlog_activity;
typedef struct vm_state {
  int processor_count;
  struct { int mut; ___actlog_activity *activities;
    int nb_activities, auto_dump, max_processor_count; } actlog;
} *___virtual_machine_state;

#define ___P(args, old) args
#define ___FIX(x) (x)
#define ___CAST(type, value) ((type)(value))
#define ___NO_ERR 0
#define ___UNKNOWN_ERR 1
#define ___HEAP_OVERFLOW_ERR 2
#define ___MAX_NB_ACTLOG_ACTIVITIES 4
#ifdef TEST_ENABLED
#define ___ACTIVITY_LOG
#endif
#ifdef TEST_POSIX
#define ___USE_POSIX_THREAD_SYSTEM
#endif

int alloc_fail, mutex_fail, array_live, mutex_live, allocations, frees, destroys;
___actlog_activity storage[4];
void require(int condition, const char *message) {
  if (!condition) { puts(message); exit(1); }
}
void *allocate(size_t bytes) {
  (void)bytes;
  if (alloc_fail) return NULL;
  require(!array_live, "DOUBLE-ALLOCATION");
  array_live = 1; allocations++; return storage;
}
void release(void *pointer) {
  require(array_live && pointer == storage, "INVALID-ARRAY-RELEASE");
  array_live = 0; frees++;
}
int initialize_mutex(int *mutex) {
  require(!mutex_live, "LIVE-MUTEX-REINITIALIZATION");
  if (mutex_fail) return 0;
  *mutex = 1; mutex_live = 1; return 1;
}
void initialize_void_mutex(int *mutex) { (void)initialize_mutex(mutex); }
void destroy_mutex(int *mutex) {
  require(mutex_live && *mutex == 1, "INVALID-MUTEX-DESTRUCTION");
  mutex_live = 0; *mutex = 0; destroys++;
}
#define ___ALLOC_MEM(bytes) allocate(bytes)
#define ___FREE_MEM(pointer) release(pointer)
#ifdef TEST_POSIX
#define ___MUTEX_INIT(mutex) initialize_mutex(&(mutex))
#else
#define ___MUTEX_INIT(mutex) initialize_void_mutex(&(mutex))
#endif
#define ___MUTEX_DESTROY(mutex) destroy_mutex(&(mutex))

#include "vm-actlog-source.inc"

int main(void) {
  struct vm_state vm = {0};
  int checks = 0;
#ifdef TEST_ENABLED
  vm.actlog.activities = (___actlog_activity *)1;
  alloc_fail = 1;
  require(___setup_actlog_vmstate(&vm) == ___HEAP_OVERFLOW_ERR, "EXPECTED-ALLOCATION-ERROR");
  require(vm.actlog.activities == (___actlog_activity *)1 && !array_live && !mutex_live,
          "FAILED-SETUP-PUBLISHED-RESOURCES");
  checks++;
  alloc_fail = 0;
#ifdef TEST_POSIX
  mutex_fail = 1;
  require(___setup_actlog_vmstate(&vm) == ___UNKNOWN_ERR, "EXPECTED-MUTEX-ERROR");
  require(vm.actlog.activities == (___actlog_activity *)1 && !array_live && !mutex_live && frees == 1,
          "MUTEX-FAILURE-DID-NOT-UNWIND");
  checks++;
  mutex_fail = 0;
#endif
  require(___setup_actlog_vmstate(&vm) == ___NO_ERR, "SUCCESSFUL-SETUP-FAILED");
  require(array_live && mutex_live && vm.actlog.auto_dump == 1, "SUCCESS-NOT-PUBLISHED");
  ___abort_actlog_vmstate(&vm);
  require(!array_live && !mutex_live && vm.actlog.activities == NULL &&
          vm.actlog.nb_activities == 0 && vm.actlog.auto_dump == 0 && destroys == 1,
          "ABORT-RETAINED-OWNED-RESOURCES");
  checks++;
#else
  require(___setup_actlog_vmstate(&vm) == ___NO_ERR, "DISABLED-SETUP-FAILED");
  ___abort_actlog_vmstate(&vm);
  require(!allocations && !frees && !destroys, "DISABLED-LOG-TOUCHED-RESOURCES");
  checks++;
#endif
  printf("{\"checks\":%d,\"arrayLive\":%d,\"mutexLive\":%d}\n", checks, array_live, mutex_live);
  return 0;
}
