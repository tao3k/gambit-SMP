import Std.Tactic
namespace SignalRouteRetirement
structure Gate where
 enabled : Bool
 generation : Nat
 count : Nat
 routeAlive : Bool
 deriving DecidableEq
def inv (g : Gate) := (g.enabled=true → g.routeAlive=true) ∧ (0<g.count → g.routeAlive=true)
def admit (g : Gate) := {g with count:=g.count+1}
def revoke (g : Gate) := {g with enabled:=false}
def leave (g : Gate) := {g with count:=g.count-1}
def retire (g : Gate) := {g with routeAlive:=false}
def entryAllowed (g : Gate) (seen capacity : Nat) := g.enabled=true ∧ g.generation=seen ∧ g.count<capacity
def retireAllowed (g : Gate) := g.enabled=false ∧ g.count=0
theorem admitPreserves (g : Gate) (seen cap : Nat) (h : inv g) (allowed : entryAllowed g seen cap) : inv (admit g) := by
 have alive : g.routeAlive=true := h.1 allowed.1
 exact ⟨by intro _; exact alive, by intro _; exact alive⟩
theorem revokePreserves (g : Gate) (h : inv g) : inv (revoke g) := by
 constructor
 · intro impossible; simp [revoke] at impossible
 · exact h.2
theorem leavePreserves (g : Gate) (h : inv g) : inv (leave g) := by
 constructor
 · exact h.1
 · intro positive; apply h.2; simp only [leave] at positive; omega
theorem retirePreserves (g : Gate) (h : retireAllowed g) : inv (retire g) := by
 constructor
 · intro impossible; simp only [retire] at impossible; have closed:=h.1; simp [closed] at impossible
 · intro positive; simp only [retire] at positive; have zero:=h.2; omega
inductive Step : Gate → Gate → Prop where
 | enter (g seen cap) (allowed : entryAllowed g seen cap) : Step g (admit g)
 | withdraw (g) : Step g (revoke g)
 | exit (g) : Step g (leave g)
 | free (g) (allowed : retireAllowed g) : Step g (retire g)
theorem gateStepPreserves (g t : Gate) (h : inv g) (edge : Step g t) : inv t := by
 cases edge with
 | enter seen cap allowed => exact admitPreserves g seen cap h allowed
 | withdraw => exact revokePreserves g h
 | exit => exact leavePreserves g h
 | free allowed => exact retirePreserves g allowed
theorem revokedEntryDenied (g : Gate) (seen cap : Nat) : ¬entryAllowed (revoke g) seen cap := by simp [entryAllowed,revoke]
theorem pinnedBlocksRetire (g : Gate) (positive : 0<g.count) : ¬retireAllowed g := by intro h; have zero:=h.2; omega
theorem staleGenerationDenied (g : Gate) (seen cap : Nat) (stale : g.generation≠seen) : ¬entryAllowed g seen cap := by intro h; exact stale h.2.1
theorem overflowDenied (g : Gate) (seen cap : Nat) (full : cap≤g.count) : ¬entryAllowed g seen cap := by intro h; have room:=h.2.2; omega
-- Source-to-SC CAS correspondence remains an explicit refinement obligation.
theorem twoLinearizations (entry closeCut : Nat) (different : entry≠closeCut) : entry<closeCut ∨ closeCut<entry := by omega
structure Masks where
 first : Bool
 second : Bool
def allMasked (m : Masks) := m.first=true ∧ m.second=true
theorem oneThreadNotGlobal : ¬allMasked ⟨true,false⟩ := by simp [allMasked]
theorem masksNotGate (g : Gate) : (revoke g).count=g.count := rfl
structure Work where
 accepted : Nat
 settled : Nat
 held : Nat
def balanced (w : Work) := w.accepted=w.settled+w.held
def accept (w : Work) := {w with accepted:=w.accepted+1,held:=w.held+1}
def complete (w : Work) := {w with settled:=w.settled+1,held:=w.held-1}
theorem publicationConserves (w : Work) (h : balanced w) : balanced (accept w) := by simp only [balanced,accept] at *; omega
theorem completionConserves (w : Work) (h : balanced w) (p : 0<w.held) : balanced (complete w) := by simp only [balanced,complete] at *; omega
def receipt (g : Gate) (workZero notificationKnown rosterClosed : Bool) := retireAllowed g ∧ workZero=true ∧ notificationKnown=true ∧ rosterClosed=true
theorem workOutlivesHandler : ∃ g : Gate, retireAllowed g ∧ ¬receipt g false true true := by
 exact ⟨⟨false,1,0,true⟩,by simp [retireAllowed,receipt]⟩
theorem unknownNotificationBlocks (g : Gate) (w r : Bool) : ¬receipt g w false r := by simp [receipt]
def mailboxSafe (pending custodian : Bool) := pending=true → custodian=true
theorem deniedNeedsCustodian (c : Bool) (h : mailboxSafe true c) : c=true := h rfl
def rosterComplete (members joined : Nat → Prop) := ∀ p, members p → joined p
theorem rosterEveryParticipant (m j : Nat → Prop) (h : rosterComplete m j) (p : Nat) (member : m p) : j p := h p member
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end SignalRouteRetirement
