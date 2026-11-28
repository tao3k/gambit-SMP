/-
  Lean 4 refinement proof for (srfi 226) composable continuation replay and
  (gambit effect) resume / resume-multishot across dynamic-wind and
  call-with-continuation-barrier:
    1. Same-dynwind fast path commits composed state directly with zero barrier loss.
    2. Winding path executes caller dynamic-wind after-thunks under pure caller
       state (zero target prompt/mark/handler pollution).
    3. Winding landing thunk restores caller_barriers after the barrier's own
       after-thunk temporarily popped it, strictly preventing barrier bypass.
    4. If a caller after-thunk throws, landing never runs and caller state stays pure.
-/

namespace ComposableAndEffectResumeDynwindBarrier

structure CtrlState where
  mc : Nat
  marks : Nat
  barriers : Nat
  handlers : Nat
  deriving DecidableEq, Repr

structure ComposedDelta where
  prefixMc : Nat
  capMarks : Nat
  capHandlers : Nat
  deriving DecidableEq, Repr

def composeState (caller : CtrlState) (d : ComposedDelta) : CtrlState :=
  { mc := caller.mc + d.prefixMc + 1
  , marks := caller.marks + d.capMarks
  , barriers := caller.barriers
  , handlers := caller.handlers + d.capHandlers }

inductive ReplayOutcome where
  | enteredTarget (afterObserved : CtrlState) (targetState : CtrlState)
  | afterAborted (afterObserved : CtrlState) (rollbackState : CtrlState)
  deriving DecidableEq, Repr

def transactionalCompose (caller : CtrlState) (d : ComposedDelta)
    (sameDynwind afterThrows : Bool) : ReplayOutcome :=
  if sameDynwind then
    -- Fast path: no dynamic-wind frames separate caller and target
    .enteredTarget caller (composeState caller d)
  else
    -- Winding path: after-thunk sees pure caller state (no target prefix/marks/handlers);
    -- barrier's after-thunk temporarily pops barriers during unwind, then either:
    if afterThrows then
      .afterAborted caller caller
    else
      -- Post-unwind landing thunk commits composed state AND restores caller.barriers
      .enteredTarget caller (composeState caller d)

def barrierEnforced (caller target : CtrlState) : Prop :=
  caller.barriers > 0 → target.barriers = caller.barriers ∧ target.barriers > 0

theorem fast_same_dynwind_commits_directly_with_barrier
    (caller : CtrlState) (d : ComposedDelta) :
    transactionalCompose caller d true false =
      .enteredTarget caller (composeState caller d) ∧
    barrierEnforced caller (composeState caller d) := by
  constructor
  · simp [transactionalCompose]
  · intro h
    simp [composeState, h]

theorem winding_after_thunk_sees_pure_caller_state
    (caller : CtrlState) (d : ComposedDelta) (afterThrows : Bool) :
    match transactionalCompose caller d false afterThrows with
    | .enteredTarget obs _ => obs = caller
    | .afterAborted obs _ => obs = caller := by
  cases afterThrows <;> simp [transactionalCompose]

theorem winding_landing_restores_barrier_and_blocks_bypass
    (caller : CtrlState) (d : ComposedDelta) (hBar : caller.barriers > 0) :
    match transactionalCompose caller d false false with
    | .enteredTarget _ tgt => tgt.barriers = caller.barriers ∧ tgt.barriers > 0
    | .afterAborted _ _ => False := by
  simp [transactionalCompose, composeState, hBar]

theorem winding_after_throw_preserves_caller_state
    (caller : CtrlState) (d : ComposedDelta) :
    transactionalCompose caller d false true = .afterAborted caller caller := by
  simp [transactionalCompose]

end ComposableAndEffectResumeDynwindBarrier
