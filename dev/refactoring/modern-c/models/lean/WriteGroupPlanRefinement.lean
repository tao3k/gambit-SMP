/-
  WriteGroupPlanRefinement.lean
  Axis 1 Refactoring (Decision C1): Formal Lean 4 proof of WriteGroupPlan
  monotonic pre-commit expansion, post-commit immutability, and emitSpec
  coverage soundness (connecting gsc/_t-c-2.scm to EmissionView.lean).
-/

inductive PlanPhase where
  | openPhase
  | committedPhase
  deriving DecidableEq, Repr

structure WriteGroupPlan where
  entryFp      : Nat
  codeStart    : Nat
  codeEnd      : Option Nat
  stackWords   : Nat
  heapWords    : Nat
  obsStack     : Nat
  obsHeap      : Nat
  phase        : PlanPhase

def CoverageSafe (p : WriteGroupPlan) : Prop :=
  p.phase = PlanPhase.committedPhase ∧
  (∃ e, p.codeEnd = some e ∧ p.codeStart ≤ e) ∧
  p.obsStack ≤ p.stackWords ∧
  p.obsHeap ≤ p.heapWords

def openPlan (fp codeStart stack heap : Nat) : WriteGroupPlan :=
  { entryFp := fp
    codeStart := codeStart
    codeEnd := none
    stackWords := stack
    heapWords := heap
    obsStack := 0
    obsHeap := 0
    phase := PlanPhase.openPhase }

def expandPlan (p : WriteGroupPlan) (fp : Nat) (rootsFit : Bool) (needStack needHeap : Nat) :
    Option WriteGroupPlan :=
  if p.phase = PlanPhase.openPhase ∧ fp = p.entryFp ∧ rootsFit = true then
    some { p with
      stackWords := Nat.max needStack p.stackWords
      heapWords := Nat.max needHeap p.heapWords }
  else
    none

def recordAdmittedEffect (p : WriteGroupPlan) (stackDelta heapDelta : Nat) :
    Option WriteGroupPlan :=
  if p.phase = PlanPhase.openPhase ∧
     stackDelta ≤ p.stackWords ∧
     p.obsHeap + heapDelta ≤ p.heapWords then
    some { p with
      obsStack := Nat.max stackDelta p.obsStack
      obsHeap := p.obsHeap + heapDelta }
  else
    none

def commitPlan (p : WriteGroupPlan) (codeEnd : Nat) : Option WriteGroupPlan :=
  if p.phase = PlanPhase.openPhase ∧ p.codeStart ≤ codeEnd then
    some { p with codeEnd := some codeEnd, phase := PlanPhase.committedPhase }
  else
    none

theorem expand_monotonic
    (p p' : WriteGroupPlan) (fp : Nat) (rootsFit : Bool) (ns nh : Nat)
    (hExp : expandPlan p fp rootsFit ns nh = some p') :
    p.stackWords ≤ p'.stackWords ∧
    p.heapWords ≤ p'.heapWords ∧
    p'.entryFp = p.entryFp ∧
    p'.obsStack = p.obsStack ∧
    p'.obsHeap = p.obsHeap := by
  unfold expandPlan at hExp
  split at hExp
  · injection hExp with hEq
    subst hEq
    exact ⟨Nat.le_max_right ns p.stackWords,
           Nat.le_max_right nh p.heapWords,
           rfl, rfl, rfl⟩
  · contradiction

theorem committed_rejects_expansion
    (p : WriteGroupPlan) (fp : Nat) (rootsFit : Bool) (ns nh : Nat)
    (hCom : p.phase = PlanPhase.committedPhase) :
    expandPlan p fp rootsFit ns nh = none := by
  unfold expandPlan
  simp [hCom]

theorem open_to_commit_coverage_safe
    (fp cs ce s h : Nat)
    (hOrder : cs ≤ ce) :
    ∃ p', commitPlan (openPlan fp cs s h) ce = some p' ∧ CoverageSafe p' := by
  refine ⟨{ openPlan fp cs s h with codeEnd := some ce, phase := PlanPhase.committedPhase }, ?_, ?_⟩
  · unfold commitPlan openPlan
    simp [hOrder]
  · unfold CoverageSafe openPlan
    exact ⟨rfl, ⟨ce, rfl, hOrder⟩, Nat.zero_le s, Nat.zero_le h⟩

theorem admitted_effects_preserve_bounds
    (p p' : WriteGroupPlan) (sd hd : Nat)
    (hInv : p.obsStack ≤ p.stackWords ∧ p.obsHeap ≤ p.heapWords)
    (hEff : recordAdmittedEffect p sd hd = some p') :
    p'.obsStack ≤ p'.stackWords ∧ p'.obsHeap ≤ p'.heapWords := by
  unfold recordAdmittedEffect at hEff
  split at hEff
  · rename_i hCond
    injection hEff with hEq
    subst hEq
    exact ⟨Nat.max_le.mpr ⟨hCond.2.1, hInv.1⟩, hCond.2.2⟩
  · contradiction

def groupHeapDemand (reserved committed dirtyFlonums flonumSpace : Nat) : Nat :=
  (reserved - committed) + dirtyFlonums * flonumSpace

theorem dirty_flush_conserves_group_heap_demand
    (reserved committed dirty flonumSpace : Nat)
    (hWater : committed ≤ reserved)
    (hDirty : 0 < dirty) :
    groupHeapDemand (reserved + flonumSpace) committed (dirty - 1) flonumSpace =
      groupHeapDemand reserved committed dirty flonumSpace := by
  unfold groupHeapDemand
  cases dirty with
  | zero => contradiction
  | succ d =>
    rw [Nat.succ_sub_one, Nat.succ_mul]
    omega

theorem mid_block_commit_eliminates_recharging
    (reserved delta2 flonumSpace : Nat) :
    groupHeapDemand reserved reserved 0 flonumSpace = 0 ∧
    groupHeapDemand reserved 0 0 flonumSpace +
      groupHeapDemand (reserved + delta2) reserved 0 flonumSpace = reserved + delta2 := by
  unfold groupHeapDemand
  simp

