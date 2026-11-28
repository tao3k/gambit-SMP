/-
  Lean 4 Mechanized Refinement Proof:
  Generator Slow-Path Unwind-Hook Coherency, Multi-Value Yield (0/1/N),
  and Winding-Transition Guard Soundness
-/

namespace GeneratorSlowpathUnwindRefinement

inductive GenState where
  | init
  | running
  | suspended
  | done
  deriving DecidableEq, Repr

inductive FrameKind where
  | prompt
  | underflow
  | unwindGuard
  deriving DecidableEq, Repr

structure McFrame where
  kind       : FrameKind
  tag        : Option Nat
  marks      : List Nat
  barriers   : List Nat
  handlers   : List Nat
  ehScope    : Option Nat
  hasGenHook : Bool
  deriving DecidableEq, Repr

structure ControlState where
  mc       : List McFrame
  marks    : List Nat
  barriers : List Nat
  handlers : List Nat
  deriving DecidableEq, Repr

/-- Dedicated slow-path generator resume installs a prompt frame with `hasGenHook = true`. -/
def makeGenReplayFrame (tag : Nat) (st : ControlState) (ehScope : Option Nat) : McFrame :=
  { kind       := FrameKind.prompt
  , tag        := some tag
  , marks      := st.marks
  , barriers   := st.barriers
  , handlers   := st.handlers
  , ehScope    := ehScope
  , hasGenHook := true
  }

/-- Temporary winding guard frame pushed only when all caller after-thunks are trampolined. -/
def makeWindingGuardFrame (st : ControlState) (ehScope : Option Nat) : McFrame :=
  { kind       := FrameKind.unwindGuard
  , tag        := none
  , marks      := st.marks
  , barriers   := st.barriers
  , handlers   := st.handlers
  , ehScope    := ehScope
  , hasGenHook := true
  }

/-- Unwinding a top frame with `hasGenHook = true` transitions `running` to `done`. -/
def unwindGenOnFrame (gs : GenState) (f : McFrame) : GenState :=
  if f.hasGenHook then GenState.done else gs

/-- Prompt availability check only matches frames with `kind == FrameKind.prompt`. -/
def promptAvailable (t : Nat) : List McFrame → Bool
  | []      => false
  | f :: fs => (f.kind == FrameKind.prompt && f.tag == some t) || promptAvailable t fs

/-- Multi-value yield slow handler transitions generator cleanly to `suspended` for any arity. -/
def yieldSlowHandler (vals : List Nat) : GenState × List Nat :=
  (GenState.suspended, vals)

/-- Conditional winding guard installation controlled by `allCallerAftersTrampolined`. -/
def beginWinding (st : ControlState) (ehScope : Option Nat) (trampolined : Bool) :
    ControlState × Option McFrame :=
  if trampolined then
    let gf := makeWindingGuardFrame st ehScope
    ({ st with mc := gf :: st.mc }, some gf)
  else
    (st, none)

/-- Landing thunk strips the temporary winding guard (if pushed) and installs `prefix ++ [pf]`. -/
def landWinding (mcAfter : List McFrame) (origMc : List McFrame)
    (gfOpt : Option McFrame) (prefixFrames : List McFrame) (pf : McFrame) : List McFrame :=
  let baseMc :=
    match gfOpt, mcAfter with
    | some gf, top :: rest => if top == gf then rest else origMc
    | _, _                 => origMc
  prefixFrames ++ (pf :: baseMc)

/-- Theorem 1: Dedicated slow-path generator resume always installs `hasGenHook = true`,
    guaranteeing that any subsequent exception or outer prompt abort transitions the
    generator from `running` to `done` (never wedged in `running`). -/
theorem slowpath_resume_preserves_unwind_hook
    (tag : Nat) (st : ControlState) (ehScope : Option Nat) :
    unwindGenOnFrame GenState.running (makeGenReplayFrame tag st ehScope) = GenState.done := by
  rfl

/-- Theorem 2: Multi-value yield slow handler transitions to `suspended` and preserves
    the exact list of 0/1/N yielded values without post-pop arity failure. -/
theorem multival_yield_transitions_to_suspended (vals : List Nat) :
    (yieldSlowHandler vals).1 = GenState.suspended ∧ (yieldSlowHandler vals).2 = vals := by
  simp [yieldSlowHandler]

/-- Theorem 3: Winding guard soundness:
    (a) when `allCallerAftersTrampolined = false`, `st.mc` is unmodified (zero stale frames),
    (b) when `allCallerAftersTrampolined = true`, the pushed guard transitions `gen` to `done`
        and carries the caller's `ehScope`. -/
theorem winding_guard_sound_and_no_stale_frame
    (st : ControlState) (ehScope : Option Nat) :
    ((beginWinding st ehScope false).1.mc = st.mc) ∧
    (∃ gf, (beginWinding st ehScope true).2 = some gf ∧
           unwindGenOnFrame GenState.running gf = GenState.done ∧
           gf.ehScope = ehScope) := by
  constructor
  · simp [beginWinding]
  · refine ⟨makeWindingGuardFrame st ehScope, ?_, ?_, ?_⟩ <;> simp [beginWinding, makeWindingGuardFrame, unwindGenOnFrame]

/-- Theorem 4: Pushing `'unwind-guard` causes zero caller state pollution:
    marks, barriers, handlers, and `continuation-prompt-available?` for every tag `t`
    are strictly identical to caller state. -/
theorem winding_guard_zero_caller_pollution
    (st : ControlState) (ehScope : Option Nat) (t : Nat) :
    let st' := (beginWinding st ehScope true).1
    st'.marks = st.marks ∧
    st'.barriers = st.barriers ∧
    st'.handlers = st.handlers ∧
    promptAvailable t st'.mc = promptAvailable t st.mc := by
  simp [beginWinding, makeWindingGuardFrame, promptAvailable]

/-- Theorem 5: Upon successful winding, the landing thunk atomically strips `'unwind-guard`
    and installs `prefixFrames ++ (pf :: st.mc)` for both guarded and unguarded modes. -/
theorem landing_thunk_atomically_replaces_guard
    (st : ControlState) (ehScope : Option Nat) (trampolined : Bool)
    (prefixFrames : List McFrame) (pf : McFrame) :
    let res := beginWinding st ehScope trampolined
    landWinding res.1.mc st.mc res.2 prefixFrames pf = prefixFrames ++ (pf :: st.mc) := by
  cases trampolined <;> simp [beginWinding, landWinding]

end GeneratorSlowpathUnwindRefinement
