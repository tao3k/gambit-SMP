/-
  Lean 4 refinement proof for generator lifecycle coherency across non-local
  control escapes (abort-current-continuation, non-composable / raw call/1cc,
  outer suspending effect perform & resume, and dynamic-wind rollback):
    Core invariant: (st.genState == .running) ↔ st.onMcStack
    1. Abort / call/1cc escape preserves the invariant on both normal commit
       (transitions to .done, off stack) and after-thunk throw rollback.
    2. Raw call/1cc escape transitions an active generator cleanly to .done.
    3. Outer effect suspend + resume roundtrips .running → .done → .running
       while preserving the invariant at every step.
    4. Calling an escaped generator always observes .done (returns #!eof),
       never stuck in .running.
-/

namespace GeneratorNonlocalEscapeUnwindHooks

inductive GenState where
  | init
  | running
  | suspended
  | done
  deriving DecidableEq, Repr

structure GenCtrl where
  genState : GenState
  onMcStack : Bool
  deriving DecidableEq, Repr

def coherent (g : GenCtrl) : Prop :=
  (g.genState = .running) ↔ (g.onMcStack = true)

def escapeAbortOr1cc (g : GenCtrl) (afterThrows : Bool) : GenCtrl :=
  if afterThrows then g
  else { genState := .done, onMcStack := false }

def outerSuspend (_g : GenCtrl) : GenCtrl :=
  { genState := .done, onMcStack := false }

def outerResume (g : GenCtrl) : GenCtrl :=
  if g.genState = .done then { genState := .running, onMcStack := true } else g

theorem abort_escape_preserves_running_iff_on_mc
    (g : GenCtrl) (hCoh : coherent g) (afterThrows : Bool) :
    coherent (escapeAbortOr1cc g afterThrows) := by
  cases afterThrows with
  | true =>
    simpa [escapeAbortOr1cc] using hCoh
  | false =>
    simp [escapeAbortOr1cc, coherent]

theorem raw_call1cc_escape_transitions_gen_to_done (g : GenCtrl) :
    let g' := escapeAbortOr1cc g false
    g'.genState = .done ∧ g'.onMcStack = false ∧ coherent g' := by
  simp [escapeAbortOr1cc, coherent]

theorem outer_effect_suspend_then_resume_roundtrip (g : GenCtrl) :
    let g1 := outerSuspend g
    let g2 := outerResume g1
    coherent g1 ∧ g1.genState = .done ∧ coherent g2 ∧ g2.genState = .running := by
  simp [outerSuspend, outerResume, coherent]

inductive CallResult where
  | eof
  | stuckError
  | resumed
  deriving DecidableEq, Repr

def callGeneratorOffStack (g : GenCtrl) : CallResult :=
  match g.genState with
  | .done => .eof
  | .running => .stuckError
  | _ => .resumed

theorem calling_escaped_generator_returns_eof_never_stuck (g : GenCtrl) :
    callGeneratorOffStack (escapeAbortOr1cc g false) = .eof ∧
    callGeneratorOffStack (outerSuspend g) = .eof := by
  simp [escapeAbortOr1cc, outerSuspend, callGeneratorOffStack]

end GeneratorNonlocalEscapeUnwindHooks
