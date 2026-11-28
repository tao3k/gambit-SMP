#ifndef GAMBIT_TEST_COMPLETION_WAIT_TRANSFER_H
#define GAMBIT_TEST_COMPLETION_WAIT_TRANSFER_H

/* DEV-owned conversion record only. RC storage and all collections below are
 * real Gambit operations. This does not implement the proposed static S emitter
 * or change a scheduler field. Calls run on the Scheme controller, outside GC. */
#include "rc.h"
static struct {
  void *source;
  void *target;
  unsigned generation, state, cached, source_releases, target_releases, readers;
} wait_transfer;

static int wait_transfer_init(___processor_state ps, ___SCMOBJ source)
{
  if (wait_transfer.source || wait_transfer.target || wait_transfer.cached || wait_transfer.readers)
    return 0;
  if (wait_transfer.generation == INT_MAX)
    return 0;
  ++wait_transfer.generation;
  wait_transfer.source_releases = wait_transfer.target_releases = 0;
  wait_transfer.source = ___alloc_rc(___PSA(ps) 0);
  if (!wait_transfer.source)
    return 0;
  if (!___try_set_data_rc(ps, wait_transfer.source, source)) {
    ___release_rc(wait_transfer.source);
    wait_transfer.source = NULL;
    return 0;
  }
  wait_transfer.state = 1;
  return wait_transfer.generation;
}
static int wait_transfer_prepare(___processor_state ps, ___SCMOBJ target)
{
  if (wait_transfer.state != 1 || wait_transfer.target)
    return 0;
  wait_transfer.target = ___alloc_rc(___PSA(ps) 0);
  if (!wait_transfer.target)
    return 0;
  if (!___try_set_data_rc(ps, wait_transfer.target, target)) {
    ___release_rc(wait_transfer.target);
    wait_transfer.target = NULL;
    return 0;
  }
  return 1;
}
static int wait_transfer_commit(int generation, int lost)
{
  if ((unsigned)generation != wait_transfer.generation || !wait_transfer.target)
    return 0;
  if (wait_transfer.state == 1)
    wait_transfer.state = 2;
  if (wait_transfer.state != 2)
    return 0;
  return lost ? -1 : 2;
}
static int wait_transfer_query(int generation)
{
  return (unsigned)generation == wait_transfer.generation
           ? (int)wait_transfer.state : -2;
}
static int wait_transfer_ack(int generation, int lost)
{
  if ((unsigned)generation != wait_transfer.generation)
    return 0;
  if (wait_transfer.state == 2) {
    ___release_rc(wait_transfer.source);
    wait_transfer.source = NULL;
    ++wait_transfer.source_releases;
    wait_transfer.state = 3;
  }
  if (wait_transfer.state != 3)
    return 0;
  return lost ? -1 : 3;
}
static int wait_transfer_retire(int generation, int omit_reader)
{
  if ((unsigned)generation != wait_transfer.generation)
    return 0;
  if (wait_transfer.state == 4)
    return 1;
  if (wait_transfer.state != 3 || ((wait_transfer.cached || wait_transfer.readers) && !omit_reader))
    return 0;
  ___release_rc(wait_transfer.target);
  wait_transfer.target = NULL;
  ++wait_transfer.target_releases;
  wait_transfer.state = 4;
  return 1;
}
#endif
