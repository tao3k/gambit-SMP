/* Locked full constructor/abort/publication bodies; allocator/OS primitives injected. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef int ___BOOL;
typedef size_t ___SIZE_T;
typedef long ___SIZE_TS;
typedef double ___F64;
typedef struct resource { int role, live, held; } resource;
typedef struct ___msections { int nb_sections; } ___msections;
typedef struct roots { unsigned mask; } roots;
typedef struct vm {
  int processor_count, failure, p0_ready;
  struct vm *prev, *next;
  roots *glos;
  struct { struct { int tospace_offset_; } mem; } p0;
  struct {
    int target_processor_count_;
    ___msections *sections;
    resource misc, alloc, scan_mutex, scan_cond;
    long normal_reserve, reserve, heap, movable, still, assigned, stacks;
    double gcs, user, sys, real, latest_real, latest_heap, latest_live, latest_movable, latest_still;
    int custom;
  } mem;
} *___virtual_machine_state;
static struct {
  struct vm vmstate0;
  resource vm_list_mut;
  struct { struct { size_t count; } glo_list; } mem;
  struct { long min_heap, max_heap; } setup_params;
} global;
static ___virtual_machine_state current;
static int invalid, descriptors, root_tables, publishing;
#define ___GSTATE (&global)
#define ___P(args, old) args
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___UNKNOWN_ERR -1
#define ___HEAP_OVERFLOW_ERR 17
#define ___PSTATE_FROM_PROCESSOR_ID(id, vm) (&(vm)->p0)
#define ___CAST(type, value) ((type)(value))
#define ___WS 8
#define ___LWS 3
#define ___DEFAULT_NORMAL_OVERFLOW_RESERVE 16
#define ___GLO_SEGMENT_SHIFT 1
#define ___GLO_SEGMENT_MASK 1
#define ___TARGET_HEAP_SPACE_HIST_LENGTH 0
#define SET_MIN(x, y) do { if ((x) > (y)) (x) = (y); } while (0)
#define SET_MAX(x, y) do { if ((x) < (y)) (x) = (y); } while (0)
#define compute_nb_msections_needed(words) ((words) / 16)
#define compute_nb_msections_min(count) ((count) * 2)
#define compute_nb_msections_allocation_headroom() 1
#define compute_heap_size() ((long)the_msections->nb_sections * 16)
#define the_msections ___VMSTATE_MEM(sections)
#define misc_mem_lock ___VMSTATE_MEM(misc)
#define alloc_mem_lock ___VMSTATE_MEM(alloc)
#define scan_termination_mutex ___VMSTATE_MEM(scan_mutex)
#define scan_termination_condvar ___VMSTATE_MEM(scan_cond)
#define normal_overflow_reserve ___VMSTATE_MEM(normal_reserve)
#define overflow_reserve ___VMSTATE_MEM(reserve)
#define heap_size ___VMSTATE_MEM(heap)
#define occupied_words_movable ___VMSTATE_MEM(movable)
#define occupied_words_still ___VMSTATE_MEM(still)
#define nb_msections_assigned ___VMSTATE_MEM(assigned)
#define nb_msections_stacks ___VMSTATE_MEM(stacks)
#define nb_gcs ___VMSTATE_MEM(gcs)
#define gc_user_time ___VMSTATE_MEM(user)
#define gc_sys_time ___VMSTATE_MEM(sys)
#define gc_real_time ___VMSTATE_MEM(real)
#define latest_gc_real_time ___VMSTATE_MEM(latest_real)
#define latest_gc_heap_size ___VMSTATE_MEM(latest_heap)
#define latest_gc_live ___VMSTATE_MEM(latest_live)
#define latest_gc_movable ___VMSTATE_MEM(latest_movable)
#define latest_gc_still ___VMSTATE_MEM(latest_still)
#define custom_msection_alloc ___VMSTATE_MEM(custom)
static int initialize(resource *r, int can_fail) {
  if (r->live) ++invalid;
  if (can_fail && current->failure == r->role) return 0;
  r->live = 1;
  return 1;
}
static void release(resource *r) {
  if (!r->live || r->held) ++invalid;
  r->live = 0;
}
static void lock(resource *r) {
  if (!r->live || r->held) ++invalid;
  r->held = 1;
}
static void unlock(resource *r) {
  if (!r->live || !r->held) ++invalid;
  if (publishing && current->processor_count == 1) {
    if (!current->p0_ready || !current->glos || current->glos->mask != 7u) ++invalid;
  }
  r->held = 0;
}
#define ___MUTEX_LOCK(r) lock(&(r))
#define ___MUTEX_UNLOCK(r) unlock(&(r))
#define ___MUTEX_DESTROY(r) release(&(r))
#define ___CONDVAR_DESTROY(r) release(&(r))
#define ___SPINLOCK_DESTROY(r) release(&(r))
#ifdef MODE_VOID
static void initialize_void(resource *r) { (void)initialize(r, 0); }
#define ___MUTEX_INIT(r) initialize_void(&(r))
#define ___CONDVAR_INIT(r) initialize_void(&(r))
#define ___SPINLOCK_INIT(r) initialize_void(&(r))
#else
#define ___USE_POSIX_THREAD_SYSTEM
#define ___MUTEX_INIT(r) initialize(&(r), 1)
#define ___CONDVAR_INIT(r) initialize(&(r), 1)
#ifdef MODE_MUTEX
#define ___USE_MUTEX_FOR_SPINLOCK
#define ___SPINLOCK_INIT(r) initialize(&(r), 1)
#else
#define ___SPINLOCK_INIT(r) initialize(&(r), 0)
#endif
#endif
static int ensure_glo_segment(___virtual_machine_state vm, size_t index) {
  if (!global.vm_list_mut.held || vm->processor_count != 0) ++invalid;
  if (vm->failure == 5 && index == (publishing ? 4u : 2u)) return 17;
  if (!vm->glos) {
    vm->glos = calloc(1, sizeof *vm->glos);
    if (!vm->glos) exit(2);
    ++root_tables;
  }
  vm->glos->mask |= 1u << (index >> 1);
  return 0;
}
static void free_glo_tables(___virtual_machine_state vm) {
  if (vm->glos) { free(vm->glos); vm->glos = NULL; --root_tables; }
}
static void adjust_msections(___msections **out, int count) {
  if (*out || count != 3 || current->processor_count != 0) ++invalid;
  if (current->failure == 6) return;
  *out = malloc(sizeof **out);
  if (!*out) exit(2);
  ++descriptors;
  (*out)->nb_sections = current->failure == 7 ? 0 : current->failure == 8 ? 1 : count;
}
static void free_msections(___msections **out) {
  if (*out) { free(*out); *out = NULL; --descriptors; }
}
#include "vm-memory-source.inc"
static int expected_failure(int failure) {
  if (failure >= 6) return 17;
#ifndef ___SINGLE_VM
  if (failure == 5) return 17;
#endif
#ifndef ___SINGLE_THREADED_VMS
#ifndef MODE_VOID
  if (failure == 3 || failure == 4) return -1;
#ifdef MODE_MUTEX
  if (failure == 1 || failure == 2) return -1;
#endif
#endif
#endif
  return 0;
}
static void fresh(struct vm *vm, int failure) {
  memset(vm, 0, sizeof *vm);
  vm->failure = failure;
  vm->mem.target_processor_count_ = 1;
  vm->mem.misc.role = 1; vm->mem.alloc.role = 2;
  vm->mem.scan_mutex.role = 3; vm->mem.scan_cond.role = 4;
  global.vmstate0.prev = global.vmstate0.next = &global.vmstate0;
  global.vm_list_mut.live = 1; global.vm_list_mut.held = 0;
  global.mem.glo_list.count = 3;
  global.setup_params.min_heap = 16; global.setup_params.max_heap = 0;
  current = vm; publishing = 0;
}
static void check_empty(struct vm *vm) {
  if (vm->processor_count || vm->glos || vm->mem.sections || descriptors || root_tables ||
      vm->mem.misc.live || vm->mem.alloc.live || vm->mem.scan_mutex.live || vm->mem.scan_cond.live ||
      global.vm_list_mut.held) ++invalid;
}
int main(void) {
  struct vm other;
  int checks = 0;
  for (int context = 0; context < 2; ++context) {
    for (int failure = 0; failure < 9; ++failure) {
      struct vm *vm = context ? &other : &global.vmstate0;
      fresh(vm, failure);
      int result = ___setup_mem_vmstate(vm);
      if (result != expected_failure(failure)) ++invalid;
      if (vm->processor_count || global.vmstate0.prev != &global.vmstate0 ||
          global.vmstate0.next != &global.vmstate0) ++invalid;
      if (result == 0) ___abort_mem_vmstate(vm);
      check_empty(vm);
      ++checks;
    }
#ifndef ___SINGLE_VM
    for (int publication_failure = 0; publication_failure < 2; ++publication_failure) {
      struct vm *vm = context ? &other : &global.vmstate0;
      fresh(vm, 0);
      if (___setup_mem_vmstate(vm) != 0) ++invalid;
      vm->p0_ready = 1;
      global.mem.glo_list.count = 5; /* A writer registered globals after private preparation. */
      vm->failure = publication_failure ? 5 : 0;
      publishing = 1;
      int result = ___publish_mem_vmstate(vm);
      if (result != (publication_failure ? 17 : 0)) ++invalid;
      if (publication_failure) {
        if (vm->processor_count || global.vmstate0.prev != &global.vmstate0 ||
            global.vmstate0.next != &global.vmstate0) ++invalid;
      } else {
        if (vm->processor_count != 1 || !vm->glos || vm->glos->mask != 7u) ++invalid;
        /* Test teardown after publication; not the normal runtime cleanup protocol. */
        vm->processor_count = 0;
        global.vmstate0.prev = global.vmstate0.next = &global.vmstate0;
      }
      ___abort_mem_vmstate(vm);
      check_empty(vm);
      ++checks;
    }
#endif
  }
  printf("{\"checks\":%d,\"invalid\":%d}\n", checks, invalid);
  return invalid ? 1 : 0;
}
