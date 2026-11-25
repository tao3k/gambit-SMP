#ifndef GAMBIT_TEST_MAP_WORKER_STOP_GC_CUTS_H
#define GAMBIT_TEST_MAP_WORKER_STOP_GC_CUTS_H

#include <stdatomic.h>
#include <sched.h>
#include <sys/mman.h>

#include "mem.h"
#include "rc.h"
#include "root.h"
#include "map-slot-gc-cuts.h"
#include "map-worker-stop-overlay.h"

/* Read-only observer. Processor 0 calls both cuts while all three
 * carriers are held in the existing collective. Arm/disarm on the
 * caller between synchronous collections, before inspecting results. */
static struct {
  _Atomic(___virtual_machine_state) vm;
  _Atomic uintptr_t pending;
  _Atomic uintptr_t last;
  _Atomic unsigned completed;
  _Atomic bool failed;
  _Atomic(void *) weak_root;
  _Atomic(void *) strong_root;
  void *prefix_root;
  int strong_source;
  uintptr_t transfer_epoch;
  unsigned transfers;
  ___rc_header *frontier;
  unsigned suffix_scans;
  unsigned write_queries;
  ___WORD before_write;
  struct {
    uintptr_t epoch;
    bool settled;
    unsigned readers;
    uintptr_t *storage;
    size_t mapping_bytes;
  } write_bank[2];
  unsigned bank_used;
  size_t bank_bytes;
  _Atomic bool frontier_ready;
  ___WORD strong_before; /* diagnostic word, never traced */
  _Atomic unsigned strong_repaired;
  _Atomic uintptr_t weak_receipt;
  _Atomic unsigned weak_observed;
  _Atomic unsigned weak_queried;
} map_worker_rounds;

/* Admit a real external helper before GC. Its write permit crosses
 * the collector cuts, but its effect is limited to this fixture record.
 * Neither callback joins the helper or waits for a GC participant. */
static struct map_worker_stop cut_helper;
static pthread_t cut_helper_thread;
static _Atomic unsigned cut_helper_phase;

static bool map_worker_arm_helper(void)
{
  cut_helper = (struct map_worker_stop){.generation = 1};
  if (pthread_mutex_init(&cut_helper.lock, NULL) != 0)
    return false;
  if (pthread_cond_init(&cut_helper.changed, NULL) != 0) {
    pthread_mutex_destroy(&cut_helper.lock);
    return false;
  }
  if (pthread_create(&cut_helper_thread, NULL, map_worker_helper, &cut_helper) != 0) {
    pthread_cond_destroy(&cut_helper.changed);
    pthread_mutex_destroy(&cut_helper.lock);
    return false;
  }
  pthread_mutex_lock(&cut_helper.lock);
  while (!cut_helper.admitted)
    pthread_cond_wait(&cut_helper.changed, &cut_helper.lock);
  cut_helper_phase = 1;
  pthread_mutex_unlock(&cut_helper.lock);
  return true;
}

static bool map_worker_finish_helper(void)
{
  pthread_mutex_lock(&cut_helper.lock);
  bool crossed = cut_helper_phase == 3;
  cut_helper.release_helper = true;
  pthread_cond_signal(&cut_helper.changed);
  pthread_mutex_unlock(&cut_helper.lock);
  if (pthread_join(cut_helper_thread, NULL) != 0)
    abort();
  /* No collector callback touches this record after phase 3. */
  bool settled = crossed && cut_helper.permits == 0 && cut_helper.repaired_slots == 1;
  if (settled) {
    cut_helper.generation = 2;
    cut_helper.closed = false;
    settled = !map_worker_acquire(&cut_helper, 1);
  }
  cut_helper_phase = 0;
  pthread_cond_destroy(&cut_helper.changed);
  pthread_mutex_destroy(&cut_helper.lock);
  return settled;
}

/* Test observer invoked immediately after the real intrusive-list write
 * in the staged scanner. Each active worker writes only its own records.
 * The post-weak collective publishes these records to processor 0. */
static struct {
  uintptr_t bodies[64];
  unsigned count;
  bool overflow;
} map_worker_weak_links[2];

void map_worker_weak_link(unsigned worker, uintptr_t body)
{
  if (!map_worker_rounds.weak_root || worker >= 2)
    return;
  unsigned next = map_worker_weak_links[worker].count;
  if (next == sizeof(map_worker_weak_links[worker].bodies) / sizeof(uintptr_t)) {
    map_worker_weak_links[worker].overflow = true;
    return;
  }
  map_worker_weak_links[worker].bodies[next] = body;
  map_worker_weak_links[worker].count = next+1;
  /* No receipt is delivered here. The fixture queries after the join. */
}

/* DEV authorization only, scoped to the selected source and epoch. */
int map_worker_transferred_source(void *value, uintptr_t epoch)
{
  ___root_round *round = value;
  if (round->vm == map_worker_rounds.vm &&
      map_worker_rounds.transfer_epoch == epoch)
    return map_worker_rounds.strong_source;
  return -1;
}

unsigned map_worker_rc_executor(void *value, unsigned source, uintptr_t epoch)
{
  ___root_round *round = value;
  unsigned initial = source % round->collection.worker_count;
  return map_worker_transferred_source(round, epoch) == (int)source
           ? 1u - initial : initial;
}

/* Same-node checkpoint: the primary write is visible, argument slots
 * are pending. The successor must query the effect before scanning them. */
int map_worker_is_prefix(void *node)
{
  return map_worker_rounds.prefix_root &&
    node == (___rc_header *)map_worker_rounds.prefix_root - 1;
}

/* Reserve the bank credit and save intent before the actual mark. The
 * original worker never records the returned value in the receipt. */
void map_worker_begin_primary(uintptr_t epoch, uintptr_t before)
{
  unsigned i = map_worker_rounds.bank_used;
  if (i >= 2 || !epoch)
    abort();
  if (!map_worker_rounds.write_bank[i].storage)
    abort();
  *map_worker_rounds.write_bank[i].storage = epoch;
  map_worker_rounds.write_bank[i].epoch = epoch;
  ++map_worker_rounds.bank_used;
  map_worker_rounds.before_write = before;
}

static bool map_worker_retire_bank(uintptr_t epoch)
{
  if (map_worker_rounds.bank_used != 2)
    return false;
  if (map_worker_rounds.write_bank[0].epoch != epoch ||
      !map_worker_rounds.write_bank[0].settled ||
      !map_worker_rounds.write_bank[1].settled ||
      map_worker_rounds.write_bank[0].readers)
    return false;
  size_t mapped = map_worker_rounds.write_bank[0].mapping_bytes;
  if (mapped) {
    if (munmap(map_worker_rounds.write_bank[0].storage, mapped) != 0)
      abort();
  } else
    free(map_worker_rounds.write_bank[0].storage);
  map_worker_rounds.write_bank[0].storage = NULL;
  map_worker_rounds.bank_bytes -= mapped ? mapped : sizeof(uintptr_t);
  map_worker_rounds.write_bank[0].epoch = 0;
  --map_worker_rounds.bank_used;
  return true;
}

static bool map_worker_ack_reader(uintptr_t epoch, unsigned reader)
{
  if (map_worker_rounds.write_bank[0].epoch != epoch || reader >= 2)
    return false;
  unsigned bit = 1u << reader;
  if (!(map_worker_rounds.write_bank[0].readers & bit))
    return false;
  map_worker_rounds.write_bank[0].readers &= ~bit;
  return true;
}

void map_worker_publish_frontier(void *value, void *next, uintptr_t epoch)
{
  ___rc_domain *domain = value;
  ___root_round *round = domain->joined_round;
  ___rc_header *frontier = next;
  if (!round || map_worker_transferred_source(round, epoch) != map_worker_rounds.strong_source ||
      domain != round->members[map_worker_rounds.strong_source].rc ||
      frontier == &domain->head || domain->task.state != ___ROOT_SCANNING ||
      domain->task.scan_leases != 1)
    abort();
  map_worker_rounds.frontier = frontier;
  domain->task.executor = round->members[
    map_worker_rc_executor(round, map_worker_rounds.strong_source, epoch)].owner;
  domain->task.state = ___ROOT_CLAIMED;
  ++map_worker_rounds.transfers;
  atomic_store_explicit(&map_worker_rounds.frontier_ready, true, memory_order_release);
}

void map_worker_await_frontier(void)
{
  while (!atomic_load_explicit(&map_worker_rounds.frontier_ready, memory_order_acquire))
    sched_yield();
}

void *map_worker_scan_frontier(void *value, uintptr_t epoch)
{
  ___rc_domain *domain = value;
  ___root_round *round = domain->joined_round;
  if (round && map_worker_transferred_source(round, epoch) == map_worker_rounds.strong_source &&
      domain == round->members[map_worker_rounds.strong_source].rc &&
      atomic_load_explicit(&map_worker_rounds.frontier_ready, memory_order_acquire)) {
    ___rc_header *node = map_worker_rounds.frontier;
    ___WORD old = map_worker_rounds.before_write;
    ___WORD head = ___HEADER(old);
    if (!map_worker_is_prefix(node) || node->root_count != 1 ||
        !___TESTTYPE(head, ___FORW) || node->data == old ||
        node->data != ___TAG(___UNTAG_AS(head, ___FORW), ___TYP(old)) ||
        ___VECTORELEM(node->data, 0) != ___FIX(74))
      abort();
    unsigned bank = map_worker_rounds.bank_used - 1;
    if (bank >= 2 || map_worker_rounds.write_bank[bank].epoch != epoch ||
        map_worker_rounds.write_bank[bank].settled)
      abort();
    map_worker_rounds.write_bank[bank].settled = true;
    ++map_worker_rounds.write_queries;
    ++map_worker_rounds.suffix_scans;
    return map_worker_rounds.frontier;
  }
  return NULL;
}

void map_slot_gc_frozen(void *carrier, uintptr_t epoch)
{
  ___processor_state ps = carrier;
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  if (vm != map_worker_rounds.vm)
    return;
  ___root_round *round = ___ROOT_UNION(vm);
  if (map_worker_rounds.pending || epoch <= map_worker_rounds.last ||
      round->state != ___ROOT_ROUND_FROZEN || round->epoch != epoch ||
      round->participants != 3 || round->collection.worker_count != 2 ||
      round->members[2].rc->task.executor != round->members[0].owner ||
      round->members[2].rc->task.state != ___ROOT_READY)
    map_worker_rounds.failed = true;
  map_worker_rounds.pending = epoch;
  for (unsigned w = 0; w < 2; ++w) {
    map_worker_weak_links[w].count = 0;
    map_worker_weak_links[w].overflow = false;
  }
  void *strong = map_worker_rounds.strong_root;
  if (strong) {
    map_worker_rounds.strong_before = ___VECTORELEM(___data_rc(strong), 0);
    int source = map_worker_rounds.strong_source;
    ___rc_domain *domain = round->members[source].rc;
    ___RC_LOCK(domain);
    if (domain->task.state != ___ROOT_READY || domain->task.scan_leases != 1 ||
        domain->task.executor != round->members[source % 2].owner) {
      map_worker_rounds.failed = true;
    } else {
      map_worker_rounds.transfer_epoch = epoch;
      map_worker_rounds.frontier = NULL;
      map_worker_rounds.frontier_ready = false;
    }
    ___RC_UNLOCK(domain);
  }
  if (cut_helper_phase == 1) {
    pthread_mutex_lock(&cut_helper.lock);
    cut_helper.closed = true;
    if (cut_helper.permits != 1 || cut_helper.repaired_slots ||
        map_worker_acquire(&cut_helper, 1))
      map_worker_rounds.failed = true;
    cut_helper_phase = 2;
    pthread_mutex_unlock(&cut_helper.lock);
  }
}

/* The RC slot has already been repaired. Compare the actual backing table
 * against the worker-owned cleanup lists at the all-worker cut. The epoch
 * receipt belongs only to the fixture; the collector list is read-only. */
static void map_worker_observe_weak(___root_round *round, uintptr_t epoch)
{
  void *root = map_worker_rounds.weak_root;
  if (!root)
    return;
  ___WORD *target = ___BODY0(___data_rc(root));
  unsigned seen = 0;
  unsigned committed = 0;
  for (int w = 0; w < round->collection.worker_count; ++w) {
    if (map_worker_weak_links[w].overflow) {
      map_worker_rounds.failed = true;
      return;
    }
    for (unsigned i = 0; i < map_worker_weak_links[w].count; ++i)
      committed += map_worker_weak_links[w].bodies[i] == (uintptr_t)target;
    ___WORD *fast = (___WORD *)round->workers[w].reached_gc_hash_tables_;
    ___WORD *slow = fast;
    while (fast) {
      seen += fast == target;
      fast = (___WORD *)fast[___GCHASHTABLE_NEXT];
      if (!fast)
        break;
      seen += fast == target;
      fast = (___WORD *)fast[___GCHASHTABLE_NEXT];
      slow = (___WORD *)slow[___GCHASHTABLE_NEXT];
      if (fast && fast == slow) {
        map_worker_rounds.failed = true;
        return;
      }
    }
  }
  if (seen != 1 || committed != 1) {
    map_worker_rounds.failed = true;
    return;
  }
  ++map_worker_rounds.weak_observed;
  map_worker_rounds.weak_receipt = epoch;
}

void map_slot_gc_repaired(void *carrier, uintptr_t epoch)
{
  ___processor_state ps = carrier;
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  if (vm != map_worker_rounds.vm)
    return;
  ___root_round *round = ___ROOT_UNION(vm);
  if (map_worker_rounds.pending != epoch ||
      round->state != ___ROOT_ROUND_DRAINING ||
      round->members[2].rc->task.state != ___ROOT_DONE ||
      round->members[2].rc->task.scan_leases != 0)
    map_worker_rounds.failed = true;
  if (cut_helper_phase == 2) {
    pthread_mutex_lock(&cut_helper.lock);
    if (cut_helper.permits != 1 || cut_helper.repaired_slots ||
        !cut_helper.closed)
      map_worker_rounds.failed = true;
    cut_helper_phase = 3;
    pthread_mutex_unlock(&cut_helper.lock);
  }
  map_worker_observe_weak(round, epoch);
  void *strong = map_worker_rounds.strong_root;
  if (strong) {
    ___WORD before = map_worker_rounds.strong_before;
    ___WORD after = ___VECTORELEM(___data_rc(strong), 0);
    ___WORD head = ___HEADER(before);
    ___rc_domain *domain = round->members[map_worker_rounds.strong_source].rc;
    unsigned executor = map_worker_rc_executor(round, map_worker_rounds.strong_source, epoch);
    if (map_worker_rounds.transfer_epoch != epoch ||
        domain->task.state != ___ROOT_DONE || domain->task.scan_leases != 0 ||
        domain->task.executor != round->members[executor].owner ||
        after == before || !___TESTTYPE(head, ___FORW) ||
        after != ___TAG(___UNTAG_AS(head, ___FORW), ___TYP(before)) ||
        ___VECTORELEM(after, 0) != ___FIX(73))
      map_worker_rounds.failed = true;
    else
      ++map_worker_rounds.strong_repaired;
  }
  map_worker_rounds.pending = 0;
  map_worker_rounds.last = epoch;
  ++map_worker_rounds.completed;
}

#endif
