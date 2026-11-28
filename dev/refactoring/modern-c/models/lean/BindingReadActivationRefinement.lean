/-
  BindingReadActivationRefinement.lean
  P0-2 Binding-Read Activation standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. Single-page `primitive_value` lookup observational equivalence against
       the dual-page `primitive_cell` + `primitive_flag` implementation.
    2. Fast-path `___primitive_ref` / `___GLOBALVARPRIMREF` dispatch soundness
       when `binding_view.vm` matches the active VM incarnation, with exact
       equivalence to `root_writer_open` fallback when cleared (`none`).
    3. Freeze-before-relocation non-interference: once root freeze clears
       `binding_view.vm := none`, no fast-path load can observe a stale cell.
-/

namespace BindingReadActivationRefinement

structure GlobalPage where
  pageId    : Nat
  primFlag  : Nat → Bool
  primCell  : Nat → Nat
  deriving Inhabited

structure GlobalDirectory where
  lookupPage : Nat → Option GlobalPage

/-- Original dual-page lookup: calls `lookupPage` twice (once for flag, once for cell). -/
def dualPagePrimitiveValue (dir : GlobalDirectory) (idx : Nat) (slot : Nat) (fallback : Nat) : Nat :=
  match dir.lookupPage idx with
  | none => fallback
  | some flagPage =>
      if flagPage.primFlag slot then
        match dir.lookupPage idx with
        | none => fallback
        | some cellPage => cellPage.primCell slot
      else
        fallback

/-- P0-2 single-page lookup: calls `lookupPage` once, then checks flag and reads cell on the same page. -/
def singlePagePrimitiveValue (dir : GlobalDirectory) (idx : Nat) (slot : Nat) (fallback : Nat) : Nat :=
  match dir.lookupPage idx with
  | none => fallback
  | some page =>
      if page.primFlag slot then
        page.primCell slot
      else
        fallback

theorem singlePage_equiv_dualPage
    (dir : GlobalDirectory) (idx slot fallback : Nat) :
    singlePagePrimitiveValue dir idx slot fallback =
      dualPagePrimitiveValue dir idx slot fallback := by
  unfold singlePagePrimitiveValue dualPagePrimitiveValue
  cases h : dir.lookupPage idx with
  | none => rfl
  | some page =>
      by_cases hf : page.primFlag slot <;> simp [hf]

structure BindingContext where
  vmId           : Nat
  entryCount     : Nat
  frozenForGc    : Bool
  bindingViewVm  : Option Nat
  deriving DecidableEq, Repr

def ContextWellFormed (ctx : BindingContext) : Prop :=
  (ctx.frozenForGc = true → ctx.bindingViewVm = none) ∧
  (ctx.entryCount = 0 → ctx.bindingViewVm = none) ∧
  (∀ v, ctx.bindingViewVm = some v → v = ctx.vmId ∧ ctx.entryCount > 0 ∧ ctx.frozenForGc = false)

def fastOrSlowDispatch (ctx : BindingContext) (readForVm : Nat → Nat) : Option Nat :=
  match ctx.bindingViewVm with
  | some v =>
      if v = ctx.vmId then some (readForVm v) else none
  | none =>
      if ctx.entryCount > 0 ∧ ctx.frozenForGc = false then
        some (readForVm ctx.vmId)
      else
        none

def slowOnlyDispatch (ctx : BindingContext) (readForVm : Nat → Nat) : Option Nat :=
  if ctx.entryCount > 0 ∧ ctx.frozenForGc = false then
    some (readForVm ctx.vmId)
  else
    none

theorem fast_dispatch_equiv_slow_dispatch
    (ctx : BindingContext) (readForVm : Nat → Nat)
    (hWf : ContextWellFormed ctx) :
    fastOrSlowDispatch ctx readForVm = slowOnlyDispatch ctx readForVm := by
  unfold fastOrSlowDispatch slowOnlyDispatch
  cases hView : ctx.bindingViewVm with
  | none => rfl
  | some v =>
      have hProps := hWf.2.2 v hView
      rcases hProps with ⟨hEq, hPos, hNotFrozen⟩
      simp [hEq, hPos, hNotFrozen]

def freezeContext (ctx : BindingContext) : BindingContext :=
  { ctx with frozenForGc := true, bindingViewVm := none }

theorem freeze_preserves_wellFormed (ctx : BindingContext) :
    ContextWellFormed (freezeContext ctx) := by
  unfold ContextWellFormed freezeContext
  refine ⟨fun _ => rfl, fun _ => rfl, ?_⟩
  intro v h
  contradiction

theorem freeze_blocks_fast_read
    (ctx : BindingContext) (readForVm : Nat → Nat) :
    fastOrSlowDispatch (freezeContext ctx) readForVm = none := by
  simp [fastOrSlowDispatch, freezeContext]

def safeCloseContext (ctx : BindingContext) : BindingContext :=
  { ctx with bindingViewVm := none, entryCount := 0 }

theorem safeClose_preserves_wellFormed (ctx : BindingContext) :
    ContextWellFormed (safeCloseContext ctx) := by
  unfold ContextWellFormed safeCloseContext
  refine ⟨fun _ => rfl, fun _ => rfl, ?_⟩
  intro v h
  contradiction

end BindingReadActivationRefinement
