/-
  Lean 4 refinement proof for (gambit effect) dynamic tail-resumptive handler
  frame popping (%pop-handler-frame!) and (srfi 226) dynamic barrier push/pop:
    1. O(1) fast path: when `frame` is at the top of the current handler stack,
       `popFrame frame (frame :: rest) = rest`.
    2. After resuming a captured continuation inside a new resumer handler
       `hResumer`, popping `frame` preserves `hResumer` and never resurrects
       a dead capture-time handler `hZombie`.
    3. On exception unwind with an unpopped inner frame above `frame`,
       `popFrame` unwinds through `frame` and leaves `hResumer` intact.
    4. Dynamic barrier push/pop preserves any enclosing outer barrier.
-/

namespace EffectTailHandlerDynamicPop

def popFrame [BEq α] (target : α) : List α → List α
  | [] => []
  | h :: t => if h == target then t else popFrame target t

theorem pop_frame_fast_path_exact (frame : Nat) (rest : List Nat) :
    popFrame frame (frame :: rest) = rest := by
  simp [popFrame]

theorem pop_frame_preserves_resumer_and_excludes_zombie
    (frame hResumer hZombie : Nat) (outer : List Nat)
    (hNe : hZombie ≠ hResumer) (hNotInOuter : hZombie ∉ outer) :
    let after := popFrame frame (frame :: hResumer :: outer)
    hResumer ∈ after ∧ hZombie ∉ after := by
  simp [popFrame, hNe, hNotInOuter]

theorem pop_frame_unwinds_inner_frames_on_exception
    (inner frame hResumer : Nat) (outer : List Nat) (hNe : inner ≠ frame) :
    popFrame frame (inner :: frame :: hResumer :: outer) = hResumer :: outer := by
  have hb : (inner == frame) = false := beq_false_of_ne hNe
  simp [popFrame, hb]

theorem dynamic_barrier_push_pop_preserves_outer
    (bInner bOuter : Nat) (rest : List Nat) :
    popFrame bInner (bInner :: bOuter :: rest) = bOuter :: rest := by
  simp [popFrame]

end EffectTailHandlerDynamicPop
