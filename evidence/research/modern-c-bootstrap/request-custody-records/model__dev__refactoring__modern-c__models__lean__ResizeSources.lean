import Std
namespace Gambit.ResizeSources
structure Source where
  phase : Nat
  serial : Nat
  rooted : Bool
  transport : Bool
  address : Nat
  epoch : Nat
  loaded : Nat
  member : Bool

def Safe (s : Source) : Prop :=
  (s.phase ≠ 0 → s.rooted = true) ∧
  (s.transport = true → s.rooted = true) ∧
  (s.phase = 3 → s.loaded = s.address) ∧
  (s.rooted = true → s.address = s.epoch) ∧
  (s.member = false → s.phase = 0)
theorem pendingNeedsRoot (s : Source) (h : Safe s) (hp : s.phase ≠ 0) :
    s.rooted = true := h.1 hp
theorem transportPreventsRootAck (s : Source) (h : Safe s)
    (ht : s.transport = true) : s.rooted = true := h.2.1 ht
theorem reloadUsesRelocatedCell (s : Source) (h : Safe s) (hl : s.phase = 3) :
    s.loaded = s.address := h.2.2.1 hl
theorem movingRootPreservesScan (s : Source) (h : Safe s) (e : Nat) :
    Safe {s with
      address := e
      epoch := e
      loaded := if s.phase = 3 then e else s.loaded} := by
  rcases h with ⟨hp, ht, hl, he, hm⟩
  refine ⟨hp, ht, ?_, ?_, hm⟩
  · intro hh
    change s.phase = 3 at hh
    simp [hh]
  · intro _; rfl
theorem pendingOriginCannotRetire (s : Source) (h : Safe s) (hp : s.phase ≠ 0) :
    s.member ≠ false := by intro hm; exact hp (h.2.2.2.2 hm)
theorem boundedTokenInjective (a b i j : Nat) (hi : i < 64) (hj : j < 64)
    (eq : a*64+i=b*64+j) : a=b ∧ i=j := by omega
theorem exhaustionCannotWrap (serial limit : Nat) (h : serial ≥ limit) :
    ¬serial < limit := by omega
-- The C adapter must refine publication, old-set freezing and collective drain.
-- No C proof, OS fairness, arbitrary native unwind or whole-round capacity claim.
end Gambit.ResizeSources
