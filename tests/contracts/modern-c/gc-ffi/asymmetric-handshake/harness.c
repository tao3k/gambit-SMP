/*
 * CBMC C23 Contract Harness for Phase C:
 * Asymmetric Per-Processor Handshake Safepoints & FFI Safe-Zone Isolation
 *
 * Verifies:
 *   1. Coordinator never scans a processor that is RUNNING mutator code.
 *   2. Per-processor self-handshake advances ack_epoch independently without global STW.
 *   3. Coordinator non-blocking scan of SAFE_FFI processors maintains strict lease coupling
 *      and monotonic bounded epochs.
 */
#include <stdint.h>
#include <stdbool.h>

extern unsigned int nondet_uint(void);

enum { P_RUNNING = 0, P_SAFE_FFI = 1, P_IN_HANDSHAKE = 2 };
enum { N_PROCS = 3, MAX_EPOCH = 4 };

static unsigned int p_state[N_PROCS];
static unsigned int req_epoch;
static unsigned int ack_epoch[N_PROCS];
static bool coord_scanning[N_PROCS];

static void check_invariants(void) {
  for (int p = 0; p < N_PROCS; p++) {
    if (coord_scanning[p]) {
      __CPROVER_assert(p_state[p] == P_IN_HANDSHAKE, "coordinator scan requires IN_HANDSHAKE");
      __CPROVER_assert(p_state[p] != P_RUNNING, "mutator cannot run during coordinator scan");
    }
    __CPROVER_assert((p_state[p] == P_IN_HANDSHAKE) == coord_scanning[p],
                     "IN_HANDSHAKE state strictly coupled with scan lease");
    __CPROVER_assert(ack_epoch[p] <= req_epoch, "ack_epoch must never exceed req_epoch");
  }
}

int main(void) {
  req_epoch = 0u;
  for (int p = 0; p < N_PROCS; p++) {
    p_state[p] = P_RUNNING;
    ack_epoch[p] = 0u;
    coord_scanning[p] = false;
  }

  for (unsigned int step = 0u; step < 6u; step++) {
    unsigned int op = nondet_uint() % 6u;
    unsigned int p = nondet_uint() % N_PROCS;

    if (op == 0u && req_epoch < MAX_EPOCH) {
      /* Coordinator advances epoch once all processors have acked previous epoch */
      bool all_done = true;
      for (int i = 0; i < N_PROCS; i++) {
        if (ack_epoch[i] != req_epoch || coord_scanning[i]) all_done = false;
      }
      if (all_done) {
        req_epoch++;
      }
    } else if (op == 1u && p_state[p] == P_RUNNING && !coord_scanning[p]) {
      /* Enter FFI safe zone */
      p_state[p] = P_SAFE_FFI;
    } else if (op == 2u && p_state[p] == P_SAFE_FFI && !coord_scanning[p]) {
      /* Exit FFI safe zone */
      p_state[p] = P_RUNNING;
    } else if (op == 3u && p_state[p] == P_RUNNING && !coord_scanning[p] && ack_epoch[p] < req_epoch) {
      /* Independent mutator self-handshake (no global STW wait) */
      ack_epoch[p] = req_epoch;
    } else if (op == 4u && p_state[p] == P_SAFE_FFI && !coord_scanning[p] && ack_epoch[p] < req_epoch) {
      /* Coordinator claims exclusive FFI safe-zone scan lease */
      p_state[p] = P_IN_HANDSHAKE;
      coord_scanning[p] = true;
    } else if (op == 5u && p_state[p] == P_IN_HANDSHAKE && coord_scanning[p]) {
      /* Coordinator finishes FFI scan and releases lease */
      p_state[p] = P_SAFE_FFI;
      coord_scanning[p] = false;
      ack_epoch[p] = req_epoch;
    }

    check_invariants();
  }
  return 0;
}
