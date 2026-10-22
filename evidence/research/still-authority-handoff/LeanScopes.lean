namespace GambitSMP.StillAuthorityHandoff
structure Gate where
  ingress : Bool
  pending : Nat
  active : Nat
def debt (g : Gate) : Nat := g.pending + g.active
inductive Step : Gate → Gate → Prop
  | reserve (g : Gate) (h : g.ingress = true) : Step g {g with pending := g.pending + 1}
  | admit (g : Gate) (h : g.ingress = true) (p : 0 < g.pending) :
      Step g {g with pending := g.pending - 1, active := g.active + 1}
  | withdraw (g : Gate) (p : 0 < g.pending) : Step g {g with pending := g.pending - 1}
  | finish (g : Gate) (p : 0 < g.active) : Step g {g with active := g.active - 1}
  | close (g : Gate) : Step g {g with ingress := false}
  | stay (g : Gate) : Step g g
theorem reserveAddsDebt (g : Gate) : debt {g with pending := g.pending + 1} = debt g + 1 := by
  simp [debt] <;> omega
theorem admitConservesDebt (g : Gate) (h : 0 < g.pending) :
    debt {g with pending := g.pending - 1, active := g.active + 1} = debt g := by
  simp [debt] <;> omega
theorem closePreservesDebt (g : Gate) : debt {g with ingress := false} = debt g := rfl
theorem noReopenStep {a b : Gate} (s : Step a b) (h : a.ingress = false) : b.ingress = false := by
  cases s with
  | reserve ho => simp_all
  | admit ho _ => simp_all
  | withdraw => exact h
  | finish => exact h
  | close => rfl
  | stay => exact h
theorem closedDebtNonincreasing {a b : Gate} (s : Step a b) (h : a.ingress = false) : debt b ≤ debt a := by
  cases s with
  | reserve ho => simp_all
  | admit ho _ => simp_all
  | withdraw => simp [debt] <;> omega
  | finish => simp [debt] <;> omega
  | close => exact Nat.le_refl _
  | stay => exact Nat.le_refl _
inductive Trace : Gate → Gate → Prop
  | refl (g : Gate) : Trace g g
  | next {a b c : Gate} : Step a b → Trace b c → Trace a c
theorem noReopenTrace {a b : Gate} (t : Trace a b) (h : a.ingress = false) : b.ingress = false := by
  induction t with
  | refl => exact h
  | next s _ ih => exact ih (noReopenStep s h)
theorem closedTraceDebt {a b : Gate} (t : Trace a b) (h : a.ingress = false) : debt b ≤ debt a := by
  induction t with
  | refl => exact Nat.le_refl _
  | next s _ ih => exact Nat.le_trans (ih (noReopenStep s h)) (closedDebtNonincreasing s h)
theorem pendingBlocksClosure (g : Gate) (h : 0 < g.pending) : ¬ debt g = 0 := by
  simp [debt] <;> omega
theorem activeBlocksClosure (g : Gate) (h : 0 < g.active) : ¬ debt g = 0 := by
  simp [debt] <;> omega
structure Stop where
  rawReturn : Nat
  identityMatches : Bool
  receipt : Bool
  borrowers : Nat
  integral : Bool
def recoverable (s : Stop) : Prop := s.receipt = true ∧ s.borrowers = 0 ∧ s.integral = true ∧ s.rawReturn = 0 ∧ s.identityMatches = true
theorem stopDoesNotCloseBorrower (s : Stop) (h : 0 < s.borrowers) : ¬ recoverable s := by
  simp [recoverable]; omega
theorem lostReceiptInsufficient (s : Stop) (h : s.receipt = false) : ¬ recoverable s := by
  simp [recoverable, h]
theorem rawErrorRefused (s : Stop) (h : 0 < s.rawReturn) : ¬ recoverable s := by
  simp [recoverable]; omega
theorem staleIdentityRefused (s : Stop) (h : s.identityMatches = false) : ¬ recoverable s := by
  simp [recoverable, h]
structure Account where

  booked : Nat
  deferred : Nat
def charge (a : Account) : Nat := a.booked + a.deferred
theorem foldPreservesCharge (a : Account) : charge ⟨a.booked+a.deferred,0⟩ = charge a := by
  simp [charge]
theorem duplicateDeferredOvercounts (a : Account) (h : 0 < a.deferred) :
    charge a < charge ⟨a.booked+a.deferred,a.deferred⟩ := by simp [charge]; omega
theorem omittingDeferredUndercounts (a : Account) (h : 0 < a.deferred) :
    charge ⟨a.booked,0⟩ < charge a := by simp [charge]; omega
structure Domain where
  owner : Nat
  account : Account
  backing : Bool
  roots : Bool
def transfer (d : Domain) : Domain := {d with owner := 1}
theorem transferPreservesCharge (d : Domain) : charge (transfer d).account = charge d.account := rfl
theorem transferPreservesBacking (d : Domain) : (transfer d).backing = d.backing := rfl
theorem transferPreservesRoots (d : Domain) : (transfer d).roots = d.roots := rfl
theorem transferIdempotent (d : Domain) : transfer (transfer d) = transfer d := rfl
theorem pinBlocksCleanup (readers : Nat) (h : 0 < readers) : ¬ readers = 0 := by omega
theorem metadataPeak (body metadata : Nat) : body ≤ body + metadata := Nat.le_add_right _ _
end GambitSMP.StillAuthorityHandoff

#check GambitSMP.StillAuthorityHandoff.reserveAddsDebt
#print axioms GambitSMP.StillAuthorityHandoff.reserveAddsDebt
#check GambitSMP.StillAuthorityHandoff.admitConservesDebt
#print axioms GambitSMP.StillAuthorityHandoff.admitConservesDebt
#check GambitSMP.StillAuthorityHandoff.closePreservesDebt
#print axioms GambitSMP.StillAuthorityHandoff.closePreservesDebt
#check GambitSMP.StillAuthorityHandoff.noReopenStep
#print axioms GambitSMP.StillAuthorityHandoff.noReopenStep
#check GambitSMP.StillAuthorityHandoff.closedDebtNonincreasing
#print axioms GambitSMP.StillAuthorityHandoff.closedDebtNonincreasing
#check GambitSMP.StillAuthorityHandoff.noReopenTrace
#print axioms GambitSMP.StillAuthorityHandoff.noReopenTrace
#check GambitSMP.StillAuthorityHandoff.closedTraceDebt
#print axioms GambitSMP.StillAuthorityHandoff.closedTraceDebt
#check GambitSMP.StillAuthorityHandoff.pendingBlocksClosure
#print axioms GambitSMP.StillAuthorityHandoff.pendingBlocksClosure
#check GambitSMP.StillAuthorityHandoff.activeBlocksClosure
#print axioms GambitSMP.StillAuthorityHandoff.activeBlocksClosure
#check GambitSMP.StillAuthorityHandoff.stopDoesNotCloseBorrower
#print axioms GambitSMP.StillAuthorityHandoff.stopDoesNotCloseBorrower
#check GambitSMP.StillAuthorityHandoff.lostReceiptInsufficient
#print axioms GambitSMP.StillAuthorityHandoff.lostReceiptInsufficient
#check GambitSMP.StillAuthorityHandoff.rawErrorRefused
#print axioms GambitSMP.StillAuthorityHandoff.rawErrorRefused
#check GambitSMP.StillAuthorityHandoff.staleIdentityRefused
#print axioms GambitSMP.StillAuthorityHandoff.staleIdentityRefused
#check GambitSMP.StillAuthorityHandoff.foldPreservesCharge
#print axioms GambitSMP.StillAuthorityHandoff.foldPreservesCharge
#check GambitSMP.StillAuthorityHandoff.duplicateDeferredOvercounts
#print axioms GambitSMP.StillAuthorityHandoff.duplicateDeferredOvercounts
#check GambitSMP.StillAuthorityHandoff.omittingDeferredUndercounts
#print axioms GambitSMP.StillAuthorityHandoff.omittingDeferredUndercounts
#check GambitSMP.StillAuthorityHandoff.transferPreservesCharge
#print axioms GambitSMP.StillAuthorityHandoff.transferPreservesCharge
#check GambitSMP.StillAuthorityHandoff.transferPreservesBacking
#print axioms GambitSMP.StillAuthorityHandoff.transferPreservesBacking
#check GambitSMP.StillAuthorityHandoff.transferPreservesRoots
#print axioms GambitSMP.StillAuthorityHandoff.transferPreservesRoots
#check GambitSMP.StillAuthorityHandoff.transferIdempotent
#print axioms GambitSMP.StillAuthorityHandoff.transferIdempotent
#check GambitSMP.StillAuthorityHandoff.pinBlocksCleanup
#print axioms GambitSMP.StillAuthorityHandoff.pinBlocksCleanup
#check GambitSMP.StillAuthorityHandoff.metadataPeak
#print axioms GambitSMP.StillAuthorityHandoff.metadataPeak
