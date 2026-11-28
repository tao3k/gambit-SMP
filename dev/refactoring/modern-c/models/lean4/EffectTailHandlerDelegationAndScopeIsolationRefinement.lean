-- Phase C52 Lean 4 Refinement Proofs:
-- 1. Tail-Resumptive Deep-Handler Delegation (Zero Self-Recursion)
-- 2. Dynamic Scope Isolation from Inner Handlers
-- 3. Zero-Allocation Same-Extent Restore & Cross-Extent Resumer Splicing
-- 4. Exception-Unwind & Continuable-Return Handler Stack Coherency

namespace EffectTailHandlerDelegationAndScopeIsolationRefinement

/-- Frame lookup by effect ID along handler stack `hs`. -/
def findHandler (eff : Nat) : List (Nat × Nat) → Option (Nat × List (Nat × Nat))
  | [] => none
  | (e, hid) :: rest =>
    if e == eff then some (hid, rest)
    else findHandler eff rest

/-- Theorem 1: When `perform eff` finds `(eff, hInner)` and shifts `st.handlers`
    to `outer`, a delegated `perform eff` inside `hInner` resolves to `(eff, hOuter)`
    in `outer` and NEVER self-recurses into `hInner`. -/
theorem tail_delegation_hits_outer_not_self (eff hInner hOuter : Nat) (rest : List (Nat × Nat)) :
    let hs := (eff, hInner) :: (eff, hOuter) :: rest
    match findHandler eff hs with
    | some (hid1, outer1) =>
      hid1 = hInner ∧
      match findHandler eff outer1 with
      | some (hid2, _) => hid2 = hOuter
      | none => False
    | none => False := by
  simp [findHandler]

/-- Theorem 2: When an inner handler `(e2, hInnerE2)` wraps `perform e1` handled
    by outer `(e1, hOuterE1)`, shifting `st.handlers` to `outer` ensures `(perform e2)`
    inside `hOuterE1` resolves to `(e2, hOuterE2)`, never hijacked by `hInnerE2`. -/
theorem tail_outer_handler_isolated_from_inner_handlers
    (e1 e2 hInnerE2 hOuterE1 hOuterE2 : Nat) (hNe : e2 ≠ e1) :
    let hs := [(e2, hInnerE2), (e1, hOuterE1), (e2, hOuterE2)]
    match findHandler e1 hs with
    | some (hid1, outer1) =>
      hid1 = hOuterE1 ∧
      match findHandler e2 outer1 with
      | some (hid2, _) => hid2 = hOuterE2
      | none => False
    | none => False := by
  have hbeq : (e2 == e1) = false := by
    cases h : (e2 == e1)
    · rfl
    · exact absurd (eq_of_beq h) hNe
  simp [findHandler, hbeq]

/-- Prefix splice matching `(if (eq? cur-h outer) handlers (append prefix cur-h))`. -/
def spliceRestored (prefixFrames outer curH : List Nat) : List Nat :=
  if curH == outer then prefixFrames ++ outer else prefixFrames ++ curH

/-- Theorem 3: On the common same-extent return (`curH = outer`), `spliceRestored`
    restores the exact original `handlers = prefixFrames ++ outer`. -/
theorem tail_return_same_extent_restores_exact_stack (prefixFrames outer : List Nat) :
    spliceRestored prefixFrames outer outer = prefixFrames ++ outer := by
  simp [spliceRestored]

/-- Theorem 4: When a suspended outer effect is resumed under an additional resumer
    handler stack `curH = outer ++ resumer`, `spliceRestored` preserves EVERY paused
    inner frame (`prefixFrames`), EVERY outer frame (`outer`), AND EVERY resumer frame. -/
theorem tail_return_cross_extent_preserves_resumer_handlers
    (prefixFrames outer resumer : List Nat) (x : Nat) :
    x ∈ spliceRestored prefixFrames outer (outer ++ resumer) ↔
      (x ∈ prefixFrames ∨ x ∈ outer ∨ x ∈ resumer) := by
  unfold spliceRestored
  by_cases h : (outer ++ resumer == outer) = true
  · have heq : outer ++ resumer = outer := eq_of_beq h
    have hlen : outer.length + resumer.length = outer.length := by
      simpa [List.length_append] using congrArg List.length heq
    have hr : resumer = [] := List.eq_nil_of_length_eq_zero (by omega)
    simp [hr]
  · simp [h, List.mem_append]

/-- Theorem 5: Restoring `prefixFrames ++ savedH` before delegating an exception to
    `cur-eh` ensures an inner catcher (popping `innerFrame`) leaves `tailFrame :: outer`
    intact, while a continuable return restores `savedH` (`outer`) for `proc` to resume. -/
theorem tail_exception_unwind_and_continuable_return_exact
    (innerFrame tailFrame outerFrame : Nat) :
    let handlers := [innerFrame, tailFrame, outerFrame]
    let outer := [outerFrame]
    let restoredBeforeEh := spliceRestored [innerFrame, tailFrame] outer outer
    let afterInnerPop := restoredBeforeEh.tail
    restoredBeforeEh = handlers ∧ afterInnerPop = [tailFrame, outerFrame] := by
  simp [spliceRestored]

end EffectTailHandlerDelegationAndScopeIsolationRefinement
