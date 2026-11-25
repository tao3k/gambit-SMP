#ifndef GAMBIT_TEST_MAP_WORKER_CARRIER_EXIT_H
#define GAMBIT_TEST_MAP_WORKER_CARRIER_EXIT_H

#include <stdio.h>
#include <time.h>

/* Included by the DEV fixture after the GC-cut observer. Only the isolated
 * negative process arms this probe. Its monitor is not a Gambit participant. */
static struct {
  _Atomic bool armed;
  _Atomic bool announced;
  _Atomic unsigned waiting;
  pthread_t carrier;
  bool retained_at_exit;
  bool source_done;
} map_carrier_exit;

static void *map_carrier_exit_monitor(void *unused)
{
  (void)unused;
  const struct timespec tick = {.tv_nsec = 1000000};
  while (!map_carrier_exit.announced)
    nanosleep(&tick, NULL);
  if (pthread_join(map_carrier_exit.carrier, NULL) != 0 ||
      !map_carrier_exit.retained_at_exit)
    _Exit(71);
  while (map_carrier_exit.waiting != 3)
    nanosleep(&tick, NULL);
  if (!map_carrier_exit.source_done)
    _Exit(71);

  /* Allow peers to enter the actual all-R rendezvous. An unexpected
   * return from it terminates the negative as a failure at stage 2. */
  const struct timespec observation = {.tv_nsec = 20000000};
  nanosleep(&observation, NULL);
  fputs("MAP-WORKER-CARRIER-EXIT-RETAINED R=3 W=2 joined=2 "
        "source-task=done peers=0,1 reopened=0\n", stdout);
  fflush(stdout);
  _Exit(0);
}

static bool map_carrier_arm_exit(void)
{
  pthread_t monitor;
  if (pthread_create(&monitor, NULL, map_carrier_exit_monitor, NULL) != 0)
    return false;
  map_carrier_exit.armed = true;
  return true;
}

void map_worker_carrier_cut(void *carrier, unsigned stage)
{
  if (!map_carrier_exit.armed)
    return;
  ___processor_state ps = carrier;
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(ps);
  ___root_round *round = ___ROOT_UNION(vm);
  unsigned id = ___PROCESSOR_ID(ps,vm);
  if (round->participants != 3 || round->collection.worker_count != 2)
    _Exit(71);
  if (stage == 0 && id == 2) {
    map_carrier_exit.retained_at_exit =
      round->state == ___ROOT_ROUND_FROZEN &&
      round->members[2].rc->joined_round == round &&
      round->members[2].rc->phase == ___RC_FROZEN &&
      !round->resume[2].restored;
    map_carrier_exit.carrier = pthread_self();
    map_carrier_exit.announced = true;
    pthread_exit(NULL);
  }
  if (stage == 1 && id < 2) {
    if (id == 0)
      map_carrier_exit.source_done =
        round->members[2].rc->task.state == ___ROOT_DONE &&
        round->members[2].rc->task.scan_leases == 0;
    atomic_fetch_or(&map_carrier_exit.waiting, 1u << id);
  }
  if (stage == 2)
    _Exit(71);
}

#endif
