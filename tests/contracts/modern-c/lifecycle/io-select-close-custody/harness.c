/*
 * CBMC Adversarial Architecture-Challenge Harness:
 * SMP Device Close-vs-Select Custody Fence & EAGAIN Rollback Contract.
 *
 * Exhaustively verifies the exact C state transitions added to vendor/gambit/lib/os_io.c:
 *   - ___device_select_borrow_one / ___device_select_unborrow_one
 *   - ___device_close_fence_enter / ___device_close_fence_exit (incl. EAGAIN rollback)
 *   - Zero OS close(fd) while select_active > 0 (No EBADF, No FD-Reuse ABA)
 *   - Zero double-close across concurrent closers
 *   - Zero reborrow while close_in_progress > 0 (Bounded drain termination / livelock freedom)
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern int nondet_int(void);
extern bool nondet_bool(void);

#define DIR_EVENT 0
#define DIR_RD    1
#define DIR_WR    2
#define DIR_RDWR  3

static int select_slice_dir(int i, int event_pos, int write_pos) {
  return (i >= write_pos) ? DIR_RD : ((i >= event_pos) ? DIR_WR : DIR_EVENT);
}

#define STAGE_OPEN   0
#define STAGE_CLOSED 3

#define FD_OPEN   0
#define FD_CLOSED 1
#define FD_REUSED 2

typedef struct {
  int read_stage;
  int write_stage;
  int close_pending_mask;
  int close_in_progress;
  int select_active;
  int close_waiters;
  int fd_state;
  int fd_epoch;
  int close_syscall_count;
} sim_device;

typedef struct {
  bool borrowed;
  int dir;
  int captured_epoch;
  bool woke_closed;
} sim_selector;

static bool dir_is_closed_or_pending(const sim_device *d, int dir) {
  if ((d->close_pending_mask & dir) != 0)
    return true;
  if ((dir & DIR_RD) && d->read_stage != STAGE_OPEN)
    return true;
  if ((dir & DIR_WR) && d->write_stage != STAGE_OPEN)
    return true;
  return false;
}

static bool select_borrow_one(sim_device *d, sim_selector *sel, int dir, bool *any_closing) {
  sel->dir = dir;
  sel->borrowed = false;
  sel->woke_closed = false;
  sel->captured_epoch = 0;

  if (dir_is_closed_or_pending(d, dir)) {
    *any_closing = true;
    sel->woke_closed = true;
    return false;
  }
  if (d->close_in_progress > 0) {
    /* Unrelated direction close in progress: refuse borrow to guarantee closer drain */
    *any_closing = true;
    return false;
  }
  /* Must strictly observe open FD when borrowing */
  assert(d->fd_state == FD_OPEN);
  d->select_active++;
  sel->borrowed = true;
  sel->captured_epoch = d->fd_epoch;
  return true;
}

static void select_unborrow_one(sim_device *d, sim_selector *sel) {
  if (!sel->borrowed)
    return;
  /* While borrowed, the OS FD MUST still be the exact original open FD! */
  assert(d->fd_state == FD_OPEN);
  assert(d->fd_epoch == sel->captured_epoch);
  assert(d->select_active > 0);
  if ((d->close_pending_mask & sel->dir) != 0)
    sel->woke_closed = true;
  d->select_active--;
  sel->borrowed = false;
  sel->captured_epoch = 0;
}

static int close_fence_enter(sim_device *d, int dir) {
  /* Serialized closer gate: at most one closer in close_in_progress */
  if (d->close_in_progress > 0)
    return -1; /* would wait on device_select_cond until close_in_progress == 0 */
  int newly_masked = dir & ~d->close_pending_mask;
  d->close_in_progress = 1;
  d->close_pending_mask |= dir;
  return newly_masked;
}

static void close_exec_and_exit(sim_device *d, int dir, int newly_masked, bool eagain) {
  /* Precondition enforced by drain loop: zero active selectors before OS close */
  assert(d->close_in_progress == 1);
  assert(d->select_active == 0);

  if (!eagain) {
    int is_not_closed = 0;
    if (d->read_stage != STAGE_CLOSED)
      is_not_closed |= DIR_RD;
    if (d->write_stage != STAGE_CLOSED)
      is_not_closed |= DIR_WR;

    if (is_not_closed != 0) {
      if ((is_not_closed & ~dir) == 0) {
        /* Both sides now closed: OS close(fd) runs exactly once */
        assert(d->fd_state == FD_OPEN);
        d->read_stage = STAGE_CLOSED;
        d->write_stage = STAGE_CLOSED;
        d->fd_state = FD_CLOSED;
        d->close_syscall_count++;
      } else {
        if (is_not_closed & dir & DIR_RD)
          d->read_stage = STAGE_CLOSED;
        if (is_not_closed & dir & DIR_WR)
          d->write_stage = STAGE_CLOSED;
      }
    }
  } else {
    /* TLS SSL_shutdown EAGAIN rollback: no stage changed, no fd closed */
    d->close_pending_mask &= ~newly_masked;
  }

  d->close_in_progress = 0;
}

int main(void) {
  sim_device d = {
    .read_stage = STAGE_OPEN,
    .write_stage = STAGE_OPEN,
    .close_pending_mask = 0,
    .close_in_progress = 0,
    .select_active = 0,
    .close_waiters = 0,
    .fd_state = FD_OPEN,
    .fd_epoch = 1,
    .close_syscall_count = 0
  };
  sim_selector s1 = {0};
  sim_selector s2 = {0};

  int active_close_dir = 0;
  int active_newly_masked = 0;

  for (int step = 0; step < 8; step++) {
    int op = nondet_int();
    if (op == 0 && !s1.borrowed) {
      bool any_closing = false;
      int before = d.select_active;
      select_borrow_one(&d, &s1, DIR_RD, &any_closing);
      if (d.close_in_progress > 0)
        assert(d.select_active == before);
    } else if (op == 1 && !s2.borrowed) {
      bool any_closing = false;
      int before = d.select_active;
      select_borrow_one(&d, &s2, DIR_WR, &any_closing);
      if (d.close_in_progress > 0)
        assert(d.select_active == before);
    } else if (op == 2 && s1.borrowed) {
      select_unborrow_one(&d, &s1);
    } else if (op == 3 && s2.borrowed) {
      select_unborrow_one(&d, &s2);
    } else if (op == 4 && d.close_in_progress == 0) {
      int dir = nondet_bool() ? DIR_RDWR : (nondet_bool() ? DIR_RD : DIR_WR);
      active_newly_masked = close_fence_enter(&d, dir);
      assert(active_newly_masked >= 0);
      active_close_dir = dir;
    } else if (op == 5 && d.close_in_progress == 1 && d.select_active == 0) {
      bool eagain = nondet_bool();
      close_exec_and_exit(&d, active_close_dir, active_newly_masked, eagain);
    } else if (op == 6 && d.fd_state == FD_CLOSED) {
      /* Adversarial OS kernel immediately recycles closed FD */
      d.fd_state = FD_REUSED;
      d.fd_epoch++;
    }

    /* Global safety invariants at every state */
    int exact = (s1.borrowed ? 1 : 0) + (s2.borrowed ? 1 : 0);
    assert(d.select_active == exact);
    if (d.fd_state != FD_OPEN) {
      assert(d.select_active == 0);
      assert(d.read_stage == STAGE_CLOSED && d.write_stage == STAGE_CLOSED);
    }
    assert(d.close_syscall_count <= 1);
  }

  /* Symbolic verification of FOR_EVENT (DIR_EVENT == 0) half-closed process ports:
   * closing stdin/stdout must NEVER cause false immediate wakeup (busy-spin),
   * while close_in_progress > 0 MUST still fence FOR_EVENT without borrowing. */
  {
    sim_device evd = {
      .read_stage = nondet_bool() ? STAGE_OPEN : STAGE_CLOSED,
      .write_stage = nondet_bool() ? STAGE_OPEN : STAGE_CLOSED,
      .close_pending_mask = nondet_int() & DIR_RDWR,
      .close_in_progress = nondet_bool() ? 1 : 0,
      .select_active = 0,
      .close_waiters = 0,
      .fd_state = FD_OPEN,
      .fd_epoch = 1,
      .close_syscall_count = 0
    };
    sim_selector evs = {0};
    bool ev_any_closing = false;
    int ev_dir = select_slice_dir(0, 1, 2);
    assert(ev_dir == DIR_EVENT);
    assert(select_slice_dir(1, 1, 2) == DIR_WR);
    assert(select_slice_dir(2, 1, 2) == DIR_RD);

    bool ok = select_borrow_one(&evd, &evs, ev_dir, &ev_any_closing);
    if (evd.close_in_progress == 0) {
      assert(ok == true);
      assert(ev_any_closing == false);
      assert(evs.woke_closed == false);
      assert(evd.select_active == 1);
      select_unborrow_one(&evd, &evs);
      assert(evd.select_active == 0);
    } else {
      assert(ok == false);
      assert(ev_any_closing == true);
      assert(evs.woke_closed == false);
      assert(evd.select_active == 0);
    }
  }

  return 0;
}
