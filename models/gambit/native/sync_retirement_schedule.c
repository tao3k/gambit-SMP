/* Unchanged source macros with deterministic mocked resource scheduling.
 * No pthread destruction is attempted on a busy or invalid resource. */
#include <stdio.h>
#include <stdlib.h>
typedef struct { int live, held; } resource;
typedef struct processor {
  int sync_id0, sync_id1, sync_id2;
  resource sync_mut, sync_cv;
} *___processor_state;
static struct processor child;
static int mode, trigger, fired, receiving, receiver_done;
static int invalid, busy_destroy, signals, receiver_locks, pending, destroyed;
static int attempts, fail_at, barriers;
static int initialize(resource *r) {
  if (++attempts == fail_at) return 0;
  r->live = 1;
  return 1;
}
static void destroy_resources(void) {
  if (child.sync_mut.held) ++busy_destroy;
  child.sync_mut.live = child.sync_cv.live = 0;
  destroyed += 2;
}
static void receive(void);
static void checkpoint(int point) {
  if (receiving || fired || trigger != point) return;
  fired = receiving = 1;
  receive();
  receiving = 0;
}
static void lock(resource *r) {
  if (!r->live) ++invalid;
  if (receiving) ++receiver_locks;
  r->held = 1;
}
static void unlock(resource *r) {
  if (!r->live) ++invalid;
  r->held = 0;
  checkpoint(2);
}
static void signal_resource(resource *r) {
  if (!r->live) ++invalid;
  ++signals;
}
static void barrier(void) {
  if (!receiving && ++barriers == 2) checkpoint(1);
}
#define ___P(args, old) args
#define ___HIDDEN static
#define ___EXP_FUNC(type, name) type name
#define ___MUTEX_INIT(r) initialize(&(r))
#define ___CONDVAR_INIT(r) initialize(&(r))
#define ___MUTEX_LOCK(r) lock(&(r))
#define ___MUTEX_UNLOCK(r) unlock(&(r))
#define ___CONDVAR_SIGNAL(r) signal_resource(&(r))
#define ___SHARED_MEMORY_BARRIER() barrier()
#define WASTE_TIME() ((void)0)
static void ___sync_wait(___processor_state ps) { (void)ps; ++invalid; }
static void cleanup_interrupts_pstate(___processor_state ps) { (void)ps; }
static void cleanup_os_and_mem_pstate(___processor_state ps) { (void)ps; }
#include "sync-schedule-source.inc"
static void receive(void) {
  ___processor_state ___ps = &child;
  int sid;
  SYNC_GET_MSG(sid = ___ps->sync_id0);
  if (sid != 7) ++invalid;
  receiver_done = 1;
  ___cleanup_pstate(___ps);
  if (mode == 1) destroy_resources(); /* proposed naive repair, not source */
  if (mode == 2) pending = 1; /* proposed drain contract, not source */
}
int main(int argc, char **argv) {
  if (argc != 3) return 2;
  mode = atoi(argv[1]);
  trigger = atoi(argv[2]);
  if (mode == 3) fail_at = trigger;
  setup_sync_op_pstate(&child);
  if (mode != 3) {
    ___processor_state ps = &child;
    SYNC_SEND_MSG(ps, sync_id0, 7);
    /* In this single-sender fixture return is the explicit drain point.
     * Production must establish global quiescence, not just this return. */
    if (pending) destroy_resources();
  }
  printf("{\"invalid\":%d,\"busyDestroy\":%d,\"signals\":%d,"
         "\"receiverDone\":%d,\"receiverLocks\":%d,\"destroyed\":%d,"
         "\"mutexLive\":%d,\"cvLive\":%d,\"attempts\":%d}\n",
         invalid, busy_destroy, signals, receiver_done, receiver_locks,
         destroyed, child.sync_mut.live, child.sync_cv.live, attempts);
  return 0;
}
