/* Source-component test. Registry functions are included byte-for-byte from
 * the selected current setup.c. The fixture substitutes delivery destinations,
 * not admission/drain/replay logic. This is not full VM/GC qualification. */
#include <assert.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>
#define ___USE_sync_builtins 1
#define ___HIDDEN static
#define ___VOLATILE volatile
#define ___PVOID (void)
#define ___P(ansi, kr) ansi
#define ___EXP_FUNC(type,name) type name
#define ___NB_INTRS 6
#define ___COMPARE_AND_SWAP_WORD(ptr,a,b) __sync_val_compare_and_swap(ptr,a,b)
#define ___FETCH_AND_ADD_WORD(ptr,n) __sync_fetch_and_add(ptr,n)
#define ___FETCH_AND_CLEAR_WORD(ptr) __sync_fetch_and_and(ptr,0)
typedef uintptr_t ___UWORD;
typedef intptr_t ___WORD;
struct fixture_vm {struct fixture_vm *prev; int generation;};
typedef struct fixture_vm *___virtual_machine_state;
static struct {struct fixture_vm vmstate0;} state;
#define ___GSTATE (&state)
static atomic_int delivered, phase, release_replay;
static atomic_int block_delivery;
static void ___raise_interrupt_vmstate(___virtual_machine_state vm,int code) {
  assert(vm == &state.vmstate0); assert(code>=0 && code<___NB_INTRS);
  int generation=vm->generation;
  if(atomic_load(&block_delivery)) {
    atomic_store(&phase,1);
    while(!atomic_load(&release_replay)) sched_yield();
  }
  assert(generation==vm->generation); /* no mutation while leased */
  atomic_fetch_add(&delivered,1);
}
#include "registry.inc"
static void timeout_handler(int code) {(void)code; _Exit(124);}
static void reset_fixture(void) {
  vm_registry_gate=0; vm_registry_pending=0;
  state.vmstate0.prev=&state.vmstate0; state.vmstate0.generation=1;
  atomic_store(&delivered,0); atomic_store(&phase,0);
  atomic_store(&block_delivery,0); atomic_store(&release_replay,0);
}
static void *close_and_reuse(void *unused) {
  (void)unused;
  ___vm_registry_close();
  atomic_store(&phase,2);
  state.vmstate0.generation++;
  ___vm_registry_open();
  return NULL;
}
static void wait_closed(void) {
  while(!( __atomic_load_n(&vm_registry_gate,__ATOMIC_SEQ_CST)&1) && atomic_load(&phase)!=2) sched_yield();
}
static void captured_reader(void) {
  reset_fixture();
  assert(vm_registry_enter());
  struct fixture_vm *captured=&state.vmstate0;
  int original=captured->generation;
  pthread_t writer; assert(!pthread_create(&writer,NULL,close_and_reuse,NULL));
  wait_closed();
  assert(atomic_load(&phase)==0); assert(captured->generation==original);
  vm_registry_leave();
  assert(!pthread_join(writer,NULL));
  assert(captured==&state.vmstate0 && captured->generation==original+1);
  assert(vm_registry_enter()); assert(captured->generation==2); vm_registry_leave();
  puts("CAPTURED-READER-OK same-slot reuse-after-drain");
}
static void *replay(void *unused) {(void)unused; ___vm_registry_replay();return NULL;}
static void replay_reader(void) {
  reset_fixture();vm_registry_pending=1;
  atomic_store(&block_delivery,1);
  pthread_t reader,writer;
  assert(!pthread_create(&reader,NULL,replay,NULL));
  while(atomic_load(&phase)!=1) sched_yield();
  assert(!pthread_create(&writer,NULL,close_and_reuse,NULL));
  wait_closed();
  assert(atomic_load(&phase)==1);assert(state.vmstate0.generation==1);
  atomic_store(&release_replay,1);
  assert(!pthread_join(reader,NULL));assert(!pthread_join(writer,NULL));
  assert(atomic_load(&delivered)==1);assert(state.vmstate0.generation==2);
  puts("REPLAY-READER-OK writer-cannot-reuse-during-delivery");
}
static void late_pending(void) {
  reset_fixture();___vm_registry_close();
  assert(!vm_registry_enter());
  /* Closed-path publisher pauses; writer reopens and flushes zero pending. */
  ___vm_registry_open();___vm_registry_replay();
  __sync_fetch_and_or(&vm_registry_pending,1);
  /* Exact source's post-publication flush needs no later writer to rescue it. */
  vm_registry_flush();
  assert(atomic_load(&delivered)==1); assert(vm_registry_pending==0);
  assert(vm_registry_gate==0);
  puts("LATE-PENDING-OK delivery-without-future-writer");
}
static void terminal(void) {
  reset_fixture();vm_registry_seal();assert(___vm_registry_sealed());
  ___vm_registry_open();assert(!vm_registry_enter());
  ___raise_interrupt(0);assert(atomic_load(&delivered)==0);
  assert(___vm_registry_sealed());
  puts("TERMINAL-OK ordinary-open-cannot-reuse-runtime");
}
int main(void) {
  setbuf(stdout,NULL);signal(SIGALRM,timeout_handler);alarm(5);
  captured_reader(); replay_reader(); late_pending(); terminal();
  reset_fixture();
  for(int i=0;i<1000;i++) {
    assert(vm_registry_enter());vm_registry_leave();
    ___vm_registry_close();state.vmstate0.generation++;___vm_registry_open();
    ___raise_interrupt(0);assert(atomic_load(&delivered)==i+1);
    assert(state.vmstate0.generation==i+2);
  }
  puts("REGISTRY-SOURCE-COMPONENT-OK cycles=1000");return 0;
}
