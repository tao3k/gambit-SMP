#ifndef GAMBIT_TEST_MAP_WORKER_RETENTION_H
#define GAMBIT_TEST_MAP_WORKER_RETENTION_H

/* The probe root observes the existing two-credit ledger's refusal.
 * It does not consume a separate fixture capacity credit. */
static struct {
  _Atomic(void *) pinned;
  _Atomic unsigned rejected;
  _Atomic unsigned census_objects;
  _Atomic bool exec_journal;
  ___SIZE_TS parity;
  int sections;
} map_worker_retention;

/* The journal outlives both reader threads. Reader 1 publishes its
 * result but the direct notification is deliberately withheld. */
struct map_bank_reader {
  pthread_t thread;
  const uintptr_t *bank;
  uintptr_t epoch;
  _Atomic bool ready;
  _Atomic bool release;
  uintptr_t receipt;
  bool notification;
  unsigned identity;
};

static void *map_bank_read(void *value)
{
  struct map_bank_reader *reader = value;
  if (*reader->bank != reader->epoch)
    abort();
  reader->ready = true;
  while (!reader->release)
    sched_yield();
  if (*reader->bank != reader->epoch)
    abort();
  reader->receipt = reader->epoch;
  reader->notification = reader->identity == 0;
  return NULL;
}

static void map_bank_start(struct map_bank_reader *reader, unsigned identity)
{
  reader->bank = map_worker_rounds.write_bank[0].storage;
  reader->epoch = map_worker_rounds.write_bank[0].epoch;
  reader->identity = identity;
  map_worker_rounds.write_bank[0].readers |= 1u << identity;
  if (pthread_create(&reader->thread, NULL, map_bank_read, reader) != 0)
    abort();
  while (!reader->ready)
    sched_yield();
}

static bool map_bank_join(struct map_bank_reader *reader)
{
  reader->release = true;
  if (pthread_join(reader->thread, NULL) != 0)
    abort();
  return reader->receipt == reader->epoch &&
    map_worker_ack_reader(reader->epoch, reader->identity);
}

/* Called only by the coordinator, after the original census has drained
 * and before any physical grants or forwarding. */
static bool map_worker_exec_terminal(void);

int map_worker_retention_refuse(void *value)
{
  ___root_round *round = value;
  if (!map_worker_retention.pinned)
    return 0;
  if (map_worker_retention.exec_journal
        ? map_worker_exec_terminal()
        : map_worker_rounds.bank_bytes < 2 * sizeof(uintptr_t))
    return 0;
  if (round->participants != 3 || round->collection.worker_count != 2 ||
      round->state != ___ROOT_ROUND_FROZEN ||
      round->collection.census.objects == 0)
    abort();
  map_worker_retention.census_objects = round->collection.census.objects;
  ++map_worker_retention.rejected;
  return 1;
}

#include "map-worker-process-readers.h"
#include "map-worker-exec-journal.h"
#include <errno.h>


/* The real planner reads the same recovered journal as the exec owner.
 * Any missing or nonterminal record keeps the old credit charged. */
static bool map_worker_exec_terminal(void)
{
  int fd = open("journal", O_RDONLY);
  if (fd < 0)
    return false;
  struct stat info;
  struct record last;
  bool settled = fstat(fd, &info) == 0 &&
    info.st_size >= (off_t)sizeof last && info.st_size % sizeof last == 0 &&
    pread(fd, &last, sizeof last, info.st_size - sizeof last) == sizeof last &&
    last.epoch == 17 && last.reader == 1 && last.event == retired;
  if (close(fd) != 0)
    return false;
  return settled && access("bank", F_OK) == -1 && errno == ENOENT;
}

static bool map_worker_exec_arm(___processor_state ps, ___SCMOBJ payload)
{
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  ___root_round *round = ___ROOT_UNION(vm);
  void *root = ___alloc_rc(___PSA(ps) 0);
  if (!root)
    return false;
  if (!___try_set_data_rc(ps, root, payload)) {
    ___release_rc(root);
    return false;
  }
  map_worker_retention.parity = round->members[0].owner->mem.tospace_offset_;
  map_worker_retention.sections = vm->mem.the_msections_->nb_sections;
  map_worker_retention.exec_journal = true;
  map_worker_retention.pinned = root;
  bool refused = ___garbage_collect(___PSA(ps) 0);
  return refused && !map_worker_exec_terminal() &&
    round->collection.decision == 2 && round->state == ___ROOT_ROUND_IDLE &&
    round->members[0].owner->mem.tospace_offset_ == map_worker_retention.parity &&
    vm->mem.the_msections_->nb_sections == map_worker_retention.sections &&
    map_worker_retention.rejected == 1 && map_worker_retention.census_objects > 0 &&
    ___data_rc(root) == payload;
}

static bool map_worker_exec_retry(___processor_state ps)
{
  ___root_round *round = ___ROOT_UNION(___VMSTATE_FROM_PSTATE(ps));
  void *root = map_worker_retention.pinned;
  bool ok = map_worker_exec_terminal() && !___garbage_collect(___PSA(ps) 0) &&
    round->collection.decision == 1 && map_worker_retention.rejected == 1 &&
    ___VECTORELEM(___data_rc(root), 0) == ___FIX(89);
  map_worker_retention.pinned = NULL;
  ___release_rc(root);
  return ok;
}

static bool map_worker_retention_control(___processor_state ps, ___SCMOBJ payload, bool cross_process)
{
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  ___root_round *round = ___ROOT_UNION(vm);
  void *root = ___alloc_rc(___PSA(ps) 0);
  if (!root)
    return false;
  if (!___try_set_data_rc(ps, root, payload)) {
    ___release_rc(root);
    return false;
  }
  ___processor_state coordinator = round->members[0].owner;
  ___SIZE_TS parity = coordinator->mem.tospace_offset_;
  int sections = vm->mem.the_msections_->nb_sections;
  struct map_bank_reader readers[2] = {0};
  struct map_process_readers processes = {0};
  if (cross_process)
    map_process_start(&processes);
  else {
    map_bank_start(&readers[0], 0);
    map_bank_start(&readers[1], 1);
  }
  map_worker_retention.pinned = root;
  bool refused = ___garbage_collect(___PSA(ps) 0);
  bool kept = refused && map_worker_retention.pinned == root &&
    map_worker_rounds.bank_used == 2 &&
    map_worker_rounds.write_bank[0].readers == 3 &&
    map_worker_retention.rejected == 1 && map_worker_retention.census_objects > 0 &&
    round->state == ___ROOT_ROUND_IDLE && round->collection.decision == 2 &&
    coordinator->mem.tospace_offset_ == parity &&
    vm->mem.the_msections_->nb_sections == sections &&
    ___data_rc(root) == payload;
  for (int i = 0; i < 3; ++i) {
    ___rc_domain *domain = round->members[i].rc;
    kept = kept && domain->phase == ___RC_OPEN && !domain->joined_round &&
      domain->task.state == ___ROOT_REFUSED && domain->task.scan_leases == 0;
  }
  uintptr_t epoch = map_worker_rounds.write_bank[0].epoch;
  bool retired;
  if (cross_process) {
    bool early = map_worker_retire_bank(epoch);
    bool settled = map_process_finish(&processes);
    retired = kept && !early && settled &&
      map_worker_retire_bank(epoch) && !map_worker_retire_bank(epoch) &&
      map_worker_rounds.bank_bytes == sizeof(uintptr_t);
  } else {
  bool early = map_worker_retire_bank(epoch);
  bool ack0 = map_bank_join(&readers[0]);
  bool premature = map_worker_retire_bank(epoch);
  bool kept_after_first = map_worker_rounds.bank_bytes == 2 * sizeof(uintptr_t) &&
    !readers[1].release && map_worker_rounds.write_bank[0].readers == 2;
  bool unknown = !map_worker_ack_reader(epoch, 2) &&
    !map_worker_ack_reader(map_worker_rounds.write_bank[1].epoch, 1);
  bool ack1 = map_bank_join(&readers[1]);
  retired = kept && !early && ack0 && readers[0].notification &&
    !premature && kept_after_first && unknown && ack1 && !readers[1].notification &&
    map_worker_retire_bank(epoch) && !map_worker_retire_bank(epoch) &&
    !map_worker_ack_reader(epoch, 1) &&
    map_worker_rounds.bank_bytes == sizeof(uintptr_t);
  }
  /* Keep the probe armed. Recovery must be admitted by freed credit. */
  bool resumed = retired && !___garbage_collect(___PSA(ps) 0) &&
    round->collection.decision == 1 &&
    map_worker_retention.rejected == 1 &&
    ___VECTORELEM(___data_rc(root), 0) == ___FIX(89);
  map_worker_retention.pinned = NULL;
  ___release_rc(root);
  free(map_worker_rounds.write_bank[1].storage);
  map_worker_rounds.write_bank[1].storage = NULL;
  map_worker_rounds.bank_bytes = 0;
  return resumed;
}

#endif
