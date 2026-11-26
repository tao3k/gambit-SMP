/-
  VmRegistryRefinement.lean
  Family 8 (8/12: registry) standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. Incarnation monotonicity across slot reuse.
    2. Borrower non-reclamation: a registry slot cannot transition to reclaimed/reused
       while any live reader holds a borrow count > 0.
    3. Stale-token refusal before first load: any borrower presenting an older
       incarnation token is deterministically rejected after slot retirement/reuse.
-/

namespace VmRegistryRefinement

inductive SlotPhase where
  | empty
  | active
  | draining
  deriving DecidableEq, Repr

structure RegistrySlot where
  incarnation : Nat
  phase       : SlotPhase
  borrowers   : Nat
  deriving DecidableEq, Repr

def SlotValid (s : RegistrySlot) : Prop :=
  (s.phase = SlotPhase.empty → s.borrowers = 0)

def tryBorrow (s : RegistrySlot) (token : Nat) : Option RegistrySlot :=
  if s.phase = SlotPhase.active ∧ s.incarnation = token then
    some { s with borrowers := s.borrowers + 1 }
  else
    none

def releaseBorrow (s : RegistrySlot) : Option RegistrySlot :=
  if s.borrowers > 0 then
    some { s with borrowers := s.borrowers - 1 }
  else
    none

def beginDrain (s : RegistrySlot) : Option RegistrySlot :=
  if s.phase = SlotPhase.active then
    some { s with phase := SlotPhase.draining }
  else
    none

def reclaimSlot (s : RegistrySlot) : Option RegistrySlot :=
  if s.phase = SlotPhase.draining ∧ s.borrowers = 0 then
    some { incarnation := s.incarnation + 1, phase := SlotPhase.empty, borrowers := 0 }
  else
    none

def activateSlot (s : RegistrySlot) : Option RegistrySlot :=
  if s.phase = SlotPhase.empty ∧ s.borrowers = 0 then
    some { incarnation := s.incarnation + 1, phase := SlotPhase.active, borrowers := 0 }
  else
    none

theorem reclaim_refused_with_live_borrowers
    (s : RegistrySlot) (hLive : s.borrowers > 0) :
    reclaimSlot s = none := by
  unfold reclaimSlot
  have hNe : s.borrowers ≠ 0 := Nat.ne_of_gt hLive
  simp [hNe]

theorem reclaim_strictly_advances_incarnation
    (s s' : RegistrySlot) (h : reclaimSlot s = some s') :
    s.incarnation < s'.incarnation ∧ s'.phase = SlotPhase.empty ∧ s'.borrowers = 0 := by
  unfold reclaimSlot at h
  split at h
  · injection h with hEq
    subst hEq
    exact ⟨Nat.lt_succ_self _, rfl, rfl⟩
  · contradiction

theorem activate_strictly_advances_incarnation
    (s s' : RegistrySlot) (h : activateSlot s = some s') :
    s.incarnation < s'.incarnation ∧ s'.phase = SlotPhase.active := by
  unfold activateSlot at h
  split at h
  · injection h with hEq
    subst hEq
    exact ⟨Nat.lt_succ_self _, rfl⟩
  · contradiction

theorem stale_token_rejected_after_reclaim_and_reuse
    (s0 s1 s2 : RegistrySlot) (oldToken : Nat)
    (hOld : oldToken = s0.incarnation)
    (hRec : reclaimSlot s0 = some s1)
    (hAct : activateSlot s1 = some s2) :
    tryBorrow s2 oldToken = none := by
  have h1 := reclaim_strictly_advances_incarnation s0 s1 hRec
  have h2 := activate_strictly_advances_incarnation s1 s2 hAct
  have hLt : oldToken < s2.incarnation := by omega
  have hNe : s2.incarnation ≠ oldToken := Nat.ne_of_gt hLt
  unfold tryBorrow
  simp [hNe]

theorem tryBorrow_preserves_valid
    (s s' : RegistrySlot) (tok : Nat)
    (h : tryBorrow s tok = some s') :
    SlotValid s' := by
  unfold tryBorrow at h
  split at h
  · rename_i hCond
    injection h with hEq
    subst hEq
    intro hEmpty
    rw [hCond.1] at hEmpty
    cases hEmpty
  · contradiction

theorem reclaim_preserves_valid
    (s s' : RegistrySlot) (h : reclaimSlot s = some s') :
    SlotValid s' := by
  have h1 := reclaim_strictly_advances_incarnation s s' h
  intro _
  exact h1.2.2

end VmRegistryRefinement
