/-
  GcFfiRootRefinement.lean
  Family 10 (10/12: gc-ffi) standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. W < R worker-to-root-domain partition conservation: when R frozen root domains
       are partitioned across W workers (even W < R), every domain is claimed and
       repaired exactly once.
    2. EntryRootSpec moving-argument coverage: every active moving FFI argument in
       the pinned bundle is relocated to the new GC epoch on round completion.
    3. Slot-oracle soundness: omitting any active moving root slot causes an epoch
       mismatch witness regardless of whether the referent stayed alive through an
       unrelated root.
-/

namespace GcFfiRootRefinement

/-- Partition of R root domains across W workers via round-robin/dynamic assignment. -/
def assignWorker (wCount domainId : Nat) : Nat :=
  domainId % wCount

theorem worker_assignment_in_bounds
    (wCount domainId : Nat) (hW : wCount > 0) :
    assignWorker wCount domainId < wCount :=
  Nat.mod_lt domainId hW

/-- Sum of repaired domains across all W workers equals total frozen domains R. -/
def countAssigned (wCount : Nat) (domains : List Nat) (w : Nat) : Nat :=
  (domains.filter (fun d => assignWorker wCount d == w)).length

def sumWorkerCounts (wCount : Nat) (domains : List Nat) : Nat → Nat
  | 0     => 0
  | k + 1 => sumWorkerCounts wCount domains k + countAssigned wCount domains k

theorem worker_partition_sum_append
    (wCount : Nat) (ds : List Nat) (d : Nat) :
    ∀ k, k ≤ wCount →
      sumWorkerCounts wCount (d :: ds) k =
        sumWorkerCounts wCount ds k + (if assignWorker wCount d < k then 1 else 0) := by
  intro k
  induction k with
  | zero =>
      intro _
      simp [sumWorkerCounts]
  | succ k ih =>
      intro hLe
      have hPrev := ih (Nat.le_of_succ_le hLe)
      simp only [sumWorkerCounts, countAssigned, List.filter]
      by_cases hEq : (assignWorker wCount d == k) = true
      · have hEqNat : assignWorker wCount d = k := beq_iff_eq.mp hEq
        have hNotLt : ¬ assignWorker wCount d < k := by omega
        have hLtSucc : assignWorker wCount d < k + 1 := by omega
        simp [hEq, hPrev, hNotLt, hLtSucc]
        omega
      · have hNeNat : assignWorker wCount d ≠ k := by
          intro h; exact hEq (beq_iff_eq.mpr h)
        have hIff : assignWorker wCount d < k + 1 ↔ assignWorker wCount d < k := by omega
        by_cases hLt : assignWorker wCount d < k
        · have hLt2 : assignWorker wCount d < k + 1 := hIff.mpr hLt
          simp [hEq, hPrev, hLt, hLt2]
          omega
        · have hNotLt2 : ¬ assignWorker wCount d < k + 1 := fun h => hLt (hIff.mp h)
          simp [hEq, hPrev, hLt, hNotLt2]

theorem w_less_than_r_conserves_all_domains
    (wCount : Nat) (domains : List Nat) (hW : wCount > 0) :
    sumWorkerCounts wCount domains wCount = domains.length := by
  induction domains with
  | nil =>
      suffices ∀ k, sumWorkerCounts wCount [] k = 0 from this wCount
      intro k
      induction k with
      | zero => rfl
      | succ k ih => simp [sumWorkerCounts, countAssigned, ih]
  | cons d ds ih =>
      have hStep := worker_partition_sum_append wCount ds d wCount (Nat.le_refl _)
      have hLt := worker_assignment_in_bounds wCount d hW
      rw [hStep, ih]
      simp [hLt]

structure FfiSlot where
  slotId        : Nat
  inRootBundle  : Bool
  slotEpoch     : Nat
  aliveByOther  : Bool
  deriving DecidableEq, Repr

def repairSlot (newEpoch : Nat) (sl : FfiSlot) : FfiSlot :=
  if sl.inRootBundle then { sl with slotEpoch := newEpoch } else sl

def slotOracleOk (newEpoch : Nat) (sl : FfiSlot) : Prop :=
  sl.slotEpoch = newEpoch

theorem pinned_slot_repaired_to_new_epoch
    (newEpoch : Nat) (sl : FfiSlot) (hPin : sl.inRootBundle = true) :
    slotOracleOk newEpoch (repairSlot newEpoch sl) := by
  simp [slotOracleOk, repairSlot, hPin]

theorem slot_oracle_detects_omitted_root_even_if_object_survives
    (newEpoch : Nat) (sl : FfiSlot)
    (hOmitted : sl.inRootBundle = false)
    (hOldEpoch : sl.slotEpoch < newEpoch)
    (_hSurvives : sl.aliveByOther = true) :
    ¬ slotOracleOk newEpoch (repairSlot newEpoch sl) := by
  simp [slotOracleOk, repairSlot, hOmitted]
  omega

/-- Primary coordinator P0 unconditional live-worker accounting (`root-tasks.inc:640`):
    `launches[1..participants-1]` track spawned child carriers only; processor 0 is
    always live whenever `participants > 0`. -/
def liveCarriersFixed (participants childLive : Nat) : Nat :=
  if participants = 0 then 0 else 1 + childLive

def liveCarriersBuggyChildOnly (childLive : Nat) : Nat :=
  childLive

theorem primary_p0_counted_yields_full_smp_workers
    (n : Nat) (hSmp : n ≥ 1) :
    liveCarriersFixed n (n - 1) = n := by
  have hNe : n ≠ 0 := by omega
  simp [liveCarriersFixed, hNe]
  omega

theorem omitting_primary_p0_clamps_smp_workers
    (n : Nat) (hSmp : n ≥ 2) :
    liveCarriersBuggyChildOnly (n - 1) < n := by
  simp [liveCarriersBuggyChildOnly]
  omega

/-- Overflow group-demand retirement (`lib/_kernel.scm:380, 2559`):
    raising stack/heap overflow must clear `groupDemandActive` first so the
    exception handler / unwinder never trips `group_demand_blocked` fatal checks. -/
structure DemandOverflowState where
  groupDemandActive : Bool
  exceptionRaised   : Bool
  deriving DecidableEq, Repr

def retireOnOverflow (_st : DemandOverflowState) : DemandOverflowState :=
  { groupDemandActive := false, exceptionRaised := true }

def DemandOverflowSafe (st : DemandOverflowState) : Prop :=
  st.exceptionRaised = true → st.groupDemandActive = false

theorem overflow_retires_demand_before_raise (st : DemandOverflowState) :
    DemandOverflowSafe (retireOnOverflow st) := by
  intro _
  rfl

/-- Physical-exit SFUN borrow custody (`lib/_c_intf/sfun-entry.inc:32, 92-103`):
    `___begin_sfun` holds `base + 1` RC borrows through `___sfun_marker` and any
    intervening Scheme continuation escape, returning to `base` only when physical
    C exit (`___end_sfun`) unwinds the activation record. -/
structure SfunBorrowState where
  baseBorrows   : Nat
  activeBorrows : Nat
  cFrameLive    : Bool
  deriving DecidableEq, Repr

def beginSfunBorrow (base : Nat) : SfunBorrowState :=
  { baseBorrows := base, activeBorrows := base + 1, cFrameLive := true }

def endSfunBorrow (st : SfunBorrowState) : SfunBorrowState :=
  { st with activeBorrows := st.baseBorrows, cFrameLive := false }

def SfunBorrowInvariant (st : SfunBorrowState) : Prop :=
  (st.cFrameLive = true → st.activeBorrows = st.baseBorrows + 1) ∧
  (st.cFrameLive = false → st.activeBorrows = st.baseBorrows)

theorem sfun_begin_preserves_borrow_custody (base : Nat) :
    SfunBorrowInvariant (beginSfunBorrow base) := by
  constructor
  · intro _; rfl
  · intro h; cases h

theorem sfun_physical_exit_drains_borrow_custody (base : Nat) :
    SfunBorrowInvariant (endSfunBorrow (beginSfunBorrow base)) := by
  constructor
  · intro h; cases h
  · intro _; rfl

/-- Contiguous live-carrier prefix starting at primary coordinator P0
    (`root-tasks.inc:640`): guarantees `round->members[i % count]` ALWAYS
    targets a live native carrier even under non-contiguous launch gaps. -/
def contiguousLivePrefix (isChildLive : Nat → Bool) : Nat → Nat
  | 0     => 0
  | 1     => 1
  | k + 1 =>
      let prev := contiguousLivePrefix isChildLive k
      if prev = k ∧ isChildLive k = true then k + 1 else prev

theorem contiguous_prefix_ge_one (isChildLive : Nat → Bool) (n : Nat) (h : n ≥ 1) :
    contiguousLivePrefix isChildLive n ≥ 1 := by
  induction n with
  | zero => omega
  | succ k ih =>
      cases k with
      | zero => simp [contiguousLivePrefix]
      | succ m =>
          have hPrev := ih (by omega)
          simp only [contiguousLivePrefix]
          split
          · omega
          · exact hPrev

theorem contiguous_prefix_all_healthy (n : Nat) (h : n ≥ 1) :
    contiguousLivePrefix (fun _ => true) n = n := by
  induction n with
  | zero => omega
  | succ k ih =>
      cases k with
      | zero => rfl
      | succ m =>
          have hPrev := ih (by omega)
          simp [contiguousLivePrefix, hPrev]

theorem contiguous_prefix_every_assigned_executor_is_live
    (isChildLive : Nat → Bool) (n : Nat) (h : n ≥ 1) :
    ∀ idx, idx < contiguousLivePrefix isChildLive n →
      idx = 0 ∨ isChildLive idx = true := by
  induction n with
  | zero => omega
  | succ k ih =>
      cases k with
      | zero =>
          intro idx hIdx
          simp [contiguousLivePrefix] at hIdx
          left; omega
      | succ m =>
          intro idx hIdx
          simp only [contiguousLivePrefix] at hIdx
          split at hIdx
          · rename_i hCond
            by_cases hEq : idx = m + 1
            · right; subst hEq; exact hCond.2
            · have hLt : idx < contiguousLivePrefix isChildLive (m + 1) := by omega
              exact ih (by omega) idx hLt
          · exact ih (by omega) idx hIdx

/-- Adversarial Gap Counterexample: non-contiguous `[P0=live, P1=dead, P2=live]`.
    Total-count yields `live = 2` and assigns `members[1]` (DEAD!), whereas
    contiguous-prefix clamps `live = 1` so every executor is guaranteed live. -/
theorem non_contiguous_gap_caught_by_contiguous_prefix :
    let gap : Nat → Bool := fun i => i == 2
    contiguousLivePrefix gap 3 = 1 ∧ gap 1 = false := by
  decide

/-- Adversarial Double-Retry Unboxed-Spill Challenge:
    Post-grant scrub preserves exact raw IEEE-754 payload across slow-path GC retries
    and leaves `Immediate` (`___FAL`) for subsequent `___POLL (0x3fL)`.
    Pre-enter scrub corrupts the reloaded F64 payload to `0` on the very first retry! -/
structure SpillRetryState where
  f64Val       : Nat
  carrierBits  : Nat
  carrierIsRaw : Bool
  deriving DecidableEq, Repr

def spillBeforeLabel (v : Nat) : SpillRetryState :=
  { f64Val := v, carrierBits := v, carrierIsRaw := true }

def slowPathRetry (st : SpillRetryState) : SpillRetryState :=
  -- handler_stack_limit resumes at ___DEF_SLBL and reloads F64 from carrierBits
  { st with f64Val := st.carrierBits }

def scrubPostGrant (st : SpillRetryState) : SpillRetryState :=
  { st with carrierBits := 0, carrierIsRaw := false }

theorem post_grant_scrub_survives_double_retry_and_cleans_carrier (v : Nat) :
    let s0 := spillBeforeLabel v
    let s1 := slowPathRetry s0
    let s2 := slowPathRetry s1
    let s3 := scrubPostGrant s2
    s3.f64Val = v ∧ s3.carrierIsRaw = false := by
  simp [spillBeforeLabel, slowPathRetry, scrubPostGrant]

theorem pre_enter_scrub_corrupts_retry_witness (v : Nat) (hNz : v ≠ 0) :
    let s0 := spillBeforeLabel v
    let sBad := scrubPostGrant s0        -- BUG: scrubbed BEFORE ___group_demand_enter!
    let sRetry := slowPathRetry sBad
    sRetry.f64Val ≠ v := by
  simp [spillBeforeLabel, scrubPostGrant, slowPathRetry]
  exact Ne.symm hNz

/-- Adversarial Post-GC Owner Foreign-Finalizer Drain Challenge
    (`vm-registry.inc`, `rc-allocation.inc`, `setup.c`, `collection-round.inc`, `c_intf.c`):
    After `reopen_rc_roots`, `vmLive = true`, `rcOpen = true`, and `joinedRound = false`,
    yet `execute_sync_op_loop` enters `___lifecycle_drain` (`draining = true`).
    Every Scheme entry, RC writer/borrow, and collective GC gate MUST reject while
    `draining || uncertain`, whereas small non-GC still foreign allocations remain allowed. -/
structure OwnerDrainState where
  vmLive               : Bool
  rcOpen               : Bool
  joinedRound          : Bool
  draining             : Bool
  uncertain            : Bool
  hasFreeHeap          : Bool
  cClosureSelfNonNull  : Bool
  deriving DecidableEq, Repr

def lifecycleEnterAdmitted (st : OwnerDrainState) : Bool :=
  st.vmLive && !st.draining && !st.uncertain

def rootWriterOpen (st : OwnerDrainState) : Bool :=
  st.rcOpen && !st.joinedRound && !st.draining && !st.uncertain

def gcCollectiveAdmitted (st : OwnerDrainState) : Bool :=
  st.vmLive && !st.draining && !st.uncertain

def smallStillAllocAllowed (st : OwnerDrainState) : Bool :=
  st.hasFreeHeap

def naiveV12LifecycleEnter (st : OwnerDrainState) : Bool :=
  st.vmLive

def naiveV12RootWriterOpen (st : OwnerDrainState) : Bool :=
  st.rcOpen && !st.joinedRound

def sfunMarkerSelfAdmitted (procIsFalse : Bool) (selfNonNull : Bool) : Bool :=
  !procIsFalse || selfNonNull

theorem draining_blocks_all_reentry_and_gc (st : OwnerDrainState)
    (hDrain : st.draining = true ∨ st.uncertain = true) :
    lifecycleEnterAdmitted st = false ∧
    rootWriterOpen st = false ∧
    gcCollectiveAdmitted st = false := by
  rcases hDrain with hD | hU
  · simp [lifecycleEnterAdmitted, rootWriterOpen, gcCollectiveAdmitted, hD]
  · simp [lifecycleEnterAdmitted, rootWriterOpen, gcCollectiveAdmitted, hU]

theorem draining_preserves_small_still_foreign_alloc (st : OwnerDrainState)
    (hFree : st.hasFreeHeap = true) :
    smallStillAllocAllowed st = true := by
  simp [smallStillAllocAllowed, hFree]

theorem naive_v12_gate_falsely_admits_during_drain :
    let st : OwnerDrainState :=
      { vmLive := true, rcOpen := true, joinedRound := false,
        draining := true, uncertain := false, hasFreeHeap := true,
        cClosureSelfNonNull := false }
    naiveV12LifecycleEnter st = true ∧
    naiveV12RootWriterOpen st = true ∧
    lifecycleEnterAdmitted st = false ∧
    rootWriterOpen st = false ∧
    gcCollectiveAdmitted st = false := by
  decide

theorem null_c_closure_self_refused_safely :
    sfunMarkerSelfAdmitted true false = false := by
  decide

end GcFfiRootRefinement
