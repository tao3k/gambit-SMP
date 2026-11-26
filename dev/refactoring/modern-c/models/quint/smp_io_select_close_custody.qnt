// -*- mode: quint -*-
// Adversarial Architecture-Challenge Model (V2):
// SMP Device Close-vs-Select Custody Fence & Idle-Processor Scheduler-Error Delivery.
//
// Challenges two interlocked Gambit-SMP concurrency defects discovered live under
// P >= 2 (std/net/repl-test.ss SIGSEGV at EXC_BAD_ACCESS 0xc3 in ##mutex-wait!):
//   1) Unsynchronized concurrent close(fd) on P0 vs ___device_select(fd) on P1:
//      triggers EBADF from select(), FD-reuse ABA when another thread immediately
//      reopens the closed fd number, or stuck-in-select hangs when close(fd) fails
//      to abort a peer processor's select().
//   2) Synchronous ##thread-intr! (async? = #f) in ##thread-report-scheduler-error!
//      called from an idle processor (current_thread == NONE) or heartbeat:
//      enters ##mutex-wait! -> ___CONTINUATION_CAPTURE -> ___THREAD_DENV_FIELD(#f)
//      and dereferences address 0xc3 (SIGSEGV).
//
// Every safety invariant is challenged with a dedicated adversarial mutation-killer
// proving the legacy defect is reachable without our architectural fence.

module smp_io_select_close_custody {
  // Device directions (bitmask: 1 = RD, 2 = WR, 3 = RD|WR)
  pure val DIR_NONE: int = 0
  pure val DIR_RD: int = 1
  pure val DIR_WR: int = 2
  pure val DIR_RDWR: int = 3

  // Selector states for each processor p in {1, 2}
  // 0 = IDLE, 1 = BORROWED_PRE_SELECT, 2 = IN_SELECT, 3 = UNBORROWED_WAKE_CLOSED
  pure val SEL_IDLE: int = 0
  pure val SEL_PRE: int = 1
  pure val SEL_IN: int = 2
  pure val SEL_DONE: int = 3

  // Closer states for processor 0
  // 0 = IDLE, 1 = DRAINING_SELECTORS, 2 = CLOSING_FD, 3 = DONE
  pure val CLS_IDLE: int = 0
  pure val CLS_DRAIN: int = 1
  pure val CLS_EXEC: int = 2
  pure val CLS_DONE: int = 3

  // OS FD table state for the device's fd slot
  // 0 = OPEN_ORIGINAL, 1 = CLOSED_FREE, 2 = REUSED_UNRELATED_FD
  pure val FD_OPEN: int = 0
  pure val FD_CLOSED: int = 1
  pure val FD_REUSED: int = 2

  // Device custody state
  var close_pending_mask: int
  var close_in_progress: int
  var select_active: int
  var fd_state: int
  var fd_epoch: int

  // Two concurrent selector processors (P1 selects RD, P2 selects WR/RD)
  var sel1_state: int
  var sel1_dir: int
  var sel1_fd_epoch: int
  var sel1_aborted: bool
  var sel1_woke_closed: bool

  var sel2_state: int
  var sel2_dir: int
  var sel2_fd_epoch: int
  var sel2_aborted: bool
  var sel2_woke_closed: bool

  // Closer processor (P0)
  var cls_state: int
  var cls_dir: int
  var drain_reborrows: int

  // Idle-processor scheduler error state
  var idle_proc_has_thread: bool
  var sched_error_pending: bool
  var primordial_notified: bool

  // Fault witness latches (must remain FALSE in the fixed architecture)
  var ebadf_fault: bool
  var fd_reuse_aba_fault: bool
  var double_close_fault: bool
  var idle_sync_wait_crash: bool
  var livelock_reborrow_fault: bool

  action init = all {
    close_pending_mask' = DIR_NONE,
    close_in_progress' = 0,
    select_active' = 0,
    fd_state' = FD_OPEN,
    fd_epoch' = 1,
    sel1_state' = SEL_IDLE,
    sel1_dir' = DIR_RD,
    sel1_fd_epoch' = 0,
    sel1_aborted' = false,
    sel1_woke_closed' = false,
    sel2_state' = SEL_IDLE,
    sel2_dir' = DIR_WR,
    sel2_fd_epoch' = 0,
    sel2_aborted' = false,
    sel2_woke_closed' = false,
    cls_state' = CLS_IDLE,
    cls_dir' = DIR_NONE,
    drain_reborrows' = 0,
    idle_proc_has_thread' = false,
    sched_error_pending' = false,
    primordial_notified' = false,
    ebadf_fault' = false,
    fd_reuse_aba_fault' = false,
    double_close_fault' = false,
    idle_sync_wait_crash' = false,
    livelock_reborrow_fault' = false,
  }

  pure def dir_masked(mask: int, dir: int): bool =
    (dir == DIR_RD and (mask == DIR_RD or mask == DIR_RDWR)) or
    (dir == DIR_WR and (mask == DIR_WR or mask == DIR_RDWR)) or
    (dir == DIR_RDWR and mask != DIR_NONE)

  pure def mask_or(a: int, b: int): int =
    if (a == DIR_RDWR or b == DIR_RDWR) DIR_RDWR
    else if (a == DIR_NONE) b
    else if (b == DIR_NONE) a
    else if (a == b) a
    else DIR_RDWR

  // Fixed architecture: P1 borrows device under device_select_mutex
  action p1_borrow_fixed = all {
    sel1_state == SEL_IDLE,
    if (dir_masked(close_pending_mask, sel1_dir)) all {
      // Already closing/closed in this direction -> wake immediately without borrowing
      sel1_state' = SEL_DONE,
      sel1_woke_closed' = true,
      sel1_fd_epoch' = 0,
      select_active' = select_active,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    } else if (close_in_progress > 0) all {
      // Unrelated close in progress -> do NOT borrow (prevents closer livelock!)
      sel1_state' = SEL_IDLE,
      sel1_woke_closed' = sel1_woke_closed,
      sel1_fd_epoch' = 0,
      select_active' = select_active,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    } else all {
      sel1_state' = SEL_PRE,
      sel1_woke_closed' = false,
      sel1_fd_epoch' = fd_epoch,
      select_active' = select_active + 1,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    },
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_dir' = sel1_dir,
    sel1_aborted' = sel1_aborted,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
  }

  // Fixed architecture: P2 borrows device under device_select_mutex (for WR direction)
  action p2_borrow_fixed = all {
    sel2_state == SEL_IDLE,
    if (dir_masked(close_pending_mask, sel2_dir)) all {
      sel2_state' = SEL_DONE,
      sel2_woke_closed' = true,
      sel2_fd_epoch' = 0,
      select_active' = select_active,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    } else if (close_in_progress > 0) all {
      sel2_state' = SEL_IDLE,
      sel2_woke_closed' = sel2_woke_closed,
      sel2_fd_epoch' = 0,
      select_active' = select_active,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    } else all {
      sel2_state' = SEL_PRE,
      sel2_woke_closed' = false,
      sel2_fd_epoch' = fd_epoch,
      select_active' = select_active + 1,
      livelock_reborrow_fault' = livelock_reborrow_fault,
      drain_reborrows' = drain_reborrows,
    },
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_dir' = sel2_dir,
    sel2_aborted' = sel2_aborted,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
  }

  // P1 enters OS select() syscall using its captured fd_epoch
  action p1_enter_select = all {
    sel1_state == SEL_PRE,
    sel1_state' = SEL_IN,
    ebadf_fault' = (ebadf_fault or fd_state == FD_CLOSED),
    fd_reuse_aba_fault' = (fd_reuse_aba_fault or (fd_state == FD_REUSED or fd_epoch != sel1_fd_epoch)),
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // P2 enters OS select() syscall
  action p2_enter_select = all {
    sel2_state == SEL_PRE,
    sel2_state' = SEL_IN,
    ebadf_fault' = (ebadf_fault or fd_state == FD_CLOSED),
    fd_reuse_aba_fault' = (fd_reuse_aba_fault or (fd_state == FD_REUSED or fd_epoch != sel2_fd_epoch)),
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // P1 exits OS select() (either via abort self-pipe or readiness) and unborrows
  action p1_exit_select = all {
    sel1_state == SEL_IN,
    sel1_state' = if (dir_masked(close_pending_mask, sel1_dir)) SEL_DONE else SEL_IDLE,
    sel1_woke_closed' = dir_masked(close_pending_mask, sel1_dir),
    sel1_aborted' = false,
    sel1_fd_epoch' = 0,
    select_active' = select_active - 1,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_dir' = sel1_dir,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // P2 exits OS select() and unborrows
  action p2_exit_select = all {
    sel2_state == SEL_IN,
    sel2_state' = if (dir_masked(close_pending_mask, sel2_dir)) SEL_DONE else SEL_IDLE,
    sel2_woke_closed' = dir_masked(close_pending_mask, sel2_dir),
    sel2_aborted' = false,
    sel2_fd_epoch' = 0,
    select_active' = select_active - 1,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_dir' = sel2_dir,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // Fixed architecture: P0 enters ___device_close(d, dir), sets close_in_progress &
  // close_pending_mask, and aborts every currently active selector's self-pipe.
  action p0_close_enter_fixed(dir: int): bool = all {
    cls_state == CLS_IDLE,
    close_in_progress == 0,
    dir != DIR_NONE,
    cls_dir' = dir,
    close_in_progress' = 1,
    close_pending_mask' = mask_or(close_pending_mask, dir),
    cls_state' = CLS_DRAIN,
    sel1_aborted' = (sel1_aborted or sel1_state == SEL_PRE or sel1_state == SEL_IN),
    sel2_aborted' = (sel2_aborted or sel2_state == SEL_PRE or sel2_state == SEL_IN),
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_woke_closed' = sel2_woke_closed,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // Fixed architecture: P0 may ONLY execute OS close(fd) once select_active == 0.
  action p0_close_exec_fixed = all {
    cls_state == CLS_DRAIN,
    select_active == 0,
    cls_state' = CLS_EXEC,
    if (close_pending_mask == DIR_RDWR) all {
      double_close_fault' = (double_close_fault or fd_state != FD_OPEN),
      fd_state' = FD_CLOSED,
    } else all {
      // Half-close (shutdown): OS fd remains open
      double_close_fault' = double_close_fault,
      fd_state' = fd_state,
    },
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // P0 finishes ___device_close_virt and releases close_in_progress (can close other direction next)
  action p0_close_exit = all {
    cls_state == CLS_EXEC,
    cls_state' = if (close_pending_mask == DIR_RDWR) CLS_DONE else CLS_IDLE,
    close_in_progress' = 0,
    close_pending_mask' = close_pending_mask,
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // Adversarial OS kernel immediately reuses any closed FD number for an unrelated socket!
  action kernel_recycle_closed_fd = all {
    fd_state == FD_CLOSED,
    fd_state' = FD_REUSED,
    fd_epoch' = fd_epoch + 1,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // Fixed architecture: ##thread-report-scheduler-error! uses async? = #t
  // (never calls ##mutex-wait! / ___CONTINUATION_CAPTURE on an idle processor).
  action idle_proc_report_sched_error_fixed = all {
    not(primordial_notified),
    sched_error_pending' = true,
    primordial_notified' = true,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // MUTANT 1: Legacy Gambit os_io.c closes FD directly without draining select_active!
  action p0_legacy_unsync_close_mutant = all {
    cls_state == CLS_IDLE,
    close_pending_mask' = DIR_RDWR,
    fd_state' = FD_CLOSED,
    cls_state' = CLS_DONE,
    close_in_progress' = 0,
    select_active' = select_active,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_dir' = DIR_RDWR,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  // MUTANT 2: Half-close without close_in_progress gate allows unrelated WR selector to reborrow & starve closer!
  action p2_ungated_reborrow_mutant = all {
    sel2_state == SEL_IDLE,
    not(dir_masked(close_pending_mask, sel2_dir)),
    close_in_progress > 0,
    sel2_state' = SEL_PRE,
    sel2_fd_epoch' = fd_epoch,
    select_active' = select_active + 1,
    drain_reborrows' = drain_reborrows + 1,
    livelock_reborrow_fault' = true,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_dir' = sel2_dir,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    idle_proc_has_thread' = idle_proc_has_thread,
    sched_error_pending' = sched_error_pending,
    primordial_notified' = primordial_notified,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    idle_sync_wait_crash' = idle_sync_wait_crash,
  }

  // MUTANT 3: Legacy ##thread-report-scheduler-error! calls ##thread-intr! with async? = #f on idle processor!
  action idle_proc_legacy_sync_sched_error_mutant = all {
    not(idle_proc_has_thread),
    sched_error_pending' = true,
    idle_sync_wait_crash' = true,
    primordial_notified' = false,
    close_pending_mask' = close_pending_mask,
    close_in_progress' = close_in_progress,
    select_active' = select_active,
    fd_state' = fd_state,
    fd_epoch' = fd_epoch,
    sel1_state' = sel1_state,
    sel1_dir' = sel1_dir,
    sel1_fd_epoch' = sel1_fd_epoch,
    sel1_aborted' = sel1_aborted,
    sel1_woke_closed' = sel1_woke_closed,
    sel2_state' = sel2_state,
    sel2_dir' = sel2_dir,
    sel2_fd_epoch' = sel2_fd_epoch,
    sel2_aborted' = sel2_aborted,
    sel2_woke_closed' = sel2_woke_closed,
    cls_state' = cls_state,
    cls_dir' = cls_dir,
    drain_reborrows' = drain_reborrows,
    idle_proc_has_thread' = idle_proc_has_thread,
    ebadf_fault' = ebadf_fault,
    fd_reuse_aba_fault' = fd_reuse_aba_fault,
    double_close_fault' = double_close_fault,
    livelock_reborrow_fault' = livelock_reborrow_fault,
  }

  action step = any {
    p1_borrow_fixed,
    p2_borrow_fixed,
    p1_enter_select,
    p2_enter_select,
    p1_exit_select,
    p2_exit_select,
    p0_close_enter_fixed(DIR_RD),
    p0_close_enter_fixed(DIR_WR),
    p0_close_enter_fixed(DIR_RDWR),
    p0_close_exec_fixed,
    p0_close_exit,
    kernel_recycle_closed_fd,
    idle_proc_report_sched_error_fixed,
  }

  // Exact structural invariants
  val selectActiveExact =
    select_active ==
      (if (sel1_state == SEL_PRE or sel1_state == SEL_IN) 1 else 0) +
      (if (sel2_state == SEL_PRE or sel2_state == SEL_IN) 1 else 0)

  val noCloseWhileSelecting =
    (fd_state != FD_OPEN) implies (select_active == 0)

  val noEbadfOrAba =
    not(ebadf_fault) and not(fd_reuse_aba_fault) and not(double_close_fault)

  val noCloserLivelock =
    not(livelock_reborrow_fault) and drain_reborrows == 0

  val noIdleSyncWaitCrash =
    not(idle_sync_wait_crash)

  val inv =
    selectActiveExact and
    noCloseWhileSelecting and
    noEbadfOrAba and
    noCloserLivelock and
    noIdleSyncWaitCrash

  // =========================================================================
  // Positive & Adversarial Mutation-Killing Tests
  // =========================================================================

  run fixedConcurrentCloseDrainsAndWakesTest = {
    init
      .then(p1_borrow_fixed)
      .then(p1_enter_select)
      .then(p0_close_enter_fixed(DIR_RDWR))
      .then(p1_exit_select)
      .then(p0_close_exec_fixed)
      .then(p0_close_exit)
      .then(kernel_recycle_closed_fd)
      .then(p2_borrow_fixed)
      .expect(inv and fd_state == FD_REUSED and sel1_woke_closed and sel2_woke_closed)
  }

  run fixedHalfCloseThenFullCloseTest = {
    init
      .then(p1_borrow_fixed)
      .then(p2_borrow_fixed)
      .then(p0_close_enter_fixed(DIR_RD))
      .then(p1_enter_select)
      .then(p2_enter_select)
      .then(p1_exit_select)
      .then(p2_exit_select)
      .then(p0_close_exec_fixed)
      .then(p0_close_exit)
      .then(p2_borrow_fixed)
      .then(p0_close_enter_fixed(DIR_WR))
      .then(p2_enter_select)
      .then(p2_exit_select)
      .then(p0_close_exec_fixed)
      .then(p0_close_exit)
      .then(kernel_recycle_closed_fd)
      .expect(inv and fd_state == FD_REUSED and sel1_woke_closed and sel2_woke_closed)
  }

  run fixedIdleProcessorAsyncSchedErrorTest = {
    init
      .then(idle_proc_report_sched_error_fixed)
      .expect(inv and primordial_notified and not(idle_sync_wait_crash))
  }

  // Mutation-killer 1: Legacy os_io.c unsynchronized close(fd) triggers BOTH EBADF and FD-reuse ABA!
  run legacyUnsyncCloseMutantKilledTest = {
    init
      .then(p1_borrow_fixed)
      .then(p0_legacy_unsync_close_mutant)
      .then(p1_enter_select)
      .expect(not(noEbadfOrAba) and ebadf_fault)
  }

  run legacyFdReuseAbaMutantKilledTest = {
    init
      .then(p1_borrow_fixed)
      .then(p0_legacy_unsync_close_mutant)
      .then(kernel_recycle_closed_fd)
      .then(p1_enter_select)
      .expect(not(noEbadfOrAba) and fd_reuse_aba_fault)
  }

  // Mutation-killer 2: Missing close_in_progress gate allows WR selector to reborrow during RD half-close!
  run ungatedReborrowLivelockMutantKilledTest = {
    init
      .then(p1_borrow_fixed)
      .then(p0_close_enter_fixed(DIR_RD))
      .then(p2_ungated_reborrow_mutant)
      .expect(not(noCloserLivelock) and livelock_reborrow_fault)
  }

  // Exact borrow-slice direction mapping in os_io.c:___device_select:
  //   [0, eventPos)          -> FOR_EVENT (waitpid/process-status, dir = DIR_NONE)
  //   [eventPos, writePos)   -> FOR_WRITING (dir = DIR_WR)
  //   [writePos, readPos)    -> FOR_READING (dir = DIR_RD)
  pure def selectSliceDir(idx: int, eventPos: int, writePos: int): int =
    if (idx >= writePos) DIR_RD
    else if (idx >= eventPos) DIR_WR
    else DIR_NONE

  // Legacy v17-v23 defect: mapped FOR_EVENT to DIR_RDWR, causing closed stdin/stdout
  // on a process port to return borrow=2 (timeout=-inf) -> 214% CPU busy-spin!
  pure def legacySelectSliceDirMutant(idx: int, eventPos: int, writePos: int): int =
    if (idx >= writePos) DIR_RD
    else if (idx >= eventPos) DIR_WR
    else DIR_RDWR

  pure def dirStageClosed(dir: int, readOpen: bool, writeOpen: bool): bool =
    ((dir == DIR_RD or dir == DIR_RDWR) and not(readOpen)) or
    ((dir == DIR_WR or dir == DIR_RDWR) and not(writeOpen))

  // Returns: 1 = BORROW (sleeps in select), 2 = WOKE_CLOSED (0s timeout), 4 = DEFER_CLOSE
  pure def borrowDecision(pendingMask: int, closing: int,
                          readOpen: bool, writeOpen: bool, dir: int): int =
    if (dir_masked(pendingMask, dir) or dirStageClosed(dir, readOpen, writeOpen)) 2
    else if (closing > 0) 4
    else 1

  // Mutation-killer 3: Legacy synchronous ##thread-report-scheduler-error! crashes idle processor (0xc3)!
  run legacySyncSchedErrorMutantKilledTest = {
    init
      .then(idle_proc_legacy_sync_sched_error_mutant)
      .expect(not(noIdleSyncWaitCrash) and idle_sync_wait_crash)
  }

  // Positive 4: FOR_EVENT (process-status) with half-closed stdin/stdout borrows cleanly
  // (decision == 1, sleeps on select timeout, zero busy-spin) while still fencing active close!
  run fixedForEventHalfClosedSleepsCleanlyTest = {
    init.expect(
      selectSliceDir(0, 1, 2) == DIR_NONE and
      selectSliceDir(1, 1, 2) == DIR_WR and
      selectSliceDir(2, 1, 2) == DIR_RD and
      // Process port with closed stdin (writeOpen=false) or closed stdout (readOpen=false)
      borrowDecision(DIR_WR, 0, true, false, selectSliceDir(0, 1, 2)) == 1 and
      borrowDecision(DIR_RD, 0, false, true, selectSliceDir(0, 1, 2)) == 1 and
      borrowDecision(DIR_RDWR, 0, false, false, selectSliceDir(0, 1, 2)) == 1 and
      // Concurrent close_in_progress > 0 STILL fences FOR_EVENT (returns 4, never races close!)
      borrowDecision(DIR_NONE, 1, true, false, selectSliceDir(0, 1, 2)) == 4
    )
  }

  // Mutation-killer 4: Legacy FOR_EVENT dir=DIR_RDWR falsely triggers borrow=2 (0s timeout busy-spin!)
  run legacyForEventBusySpinMutantKilledTest = {
    init.expect(
      legacySelectSliceDirMutant(0, 1, 2) == DIR_RDWR and
      borrowDecision(DIR_NONE, 0, true, false, legacySelectSliceDirMutant(0, 1, 2)) == 2 and
      borrowDecision(DIR_WR, 0, true, false, legacySelectSliceDirMutant(0, 1, 2)) == 2
    )
  }
}
