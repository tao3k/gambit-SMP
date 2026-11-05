import RestoreIssuer
import RestoreEntry
import RestoreGuardAlgebra
namespace RestoreIngressBridge
-- This relation connects an admitted bootstrap to the earlier two-ticket entry.
-- Source origin validity, owner identity and outer witness provenance remain inputs.
def Admission (a : RestoreIssuerAst.State) (p : RestoreEntryAst.State) : Prop :=
 a.guard=2 ∧ a.carrier=1 ∧ p.t1phase=1 ∧ p.t1roots=true ∧
 p.t1guard=true ∧ p.current=p.parent1 ∧
 ((a.intent=1 ∧ p.kind1=1) ∨
  (a.intent=4 ∧ p.kind1=2 ∧ (a.marker=1 → p.markerLive1=true)))
theorem entryAgreement (a : RestoreIssuerAst.State) (p : RestoreEntryAst.State)
 (r : Admission a p) (g : RestoreIssuerAst.enterGuard a) : RestoreEntryAst.enter1Guard p := by
 rcases r with ⟨h0,h1,h2,h3,h4,h5,h6⟩
 rcases h6 with fresh | foreign
 · simp_all [RestoreIssuerAst.enterGuard,RestoreEntryAst.enter1Guard]
 · simp_all [RestoreIssuerAst.enterGuard,RestoreEntryAst.enter1Guard]
   omega
theorem admittedSuccessorSafe (a : RestoreIssuerAst.State) (p : RestoreEntryAst.State)
 (r : Admission a p) (g : RestoreIssuerAst.enterGuard a)
 (h : RestoreEntryAst.Safe p) : RestoreEntryAst.Safe (RestoreEntryAst.enter1Next p) :=
 RestoreEntry.enter1Preserves p h (entryAgreement a p r g)
theorem admittedRoots (a : RestoreIssuerAst.State) (p : RestoreEntryAst.State)
 (r : Admission a p) : a.carrier=1 ∧ p.t1roots=true := by
 simp_all [Admission]
theorem oldWitnessDoesNotFollowAmbient (records : RestoreGuardAlgebra.GuardId → RestoreGuardAlgebra.GuardRecord)
 (a b : Option RestoreGuardAlgebra.GuardId) (w : RestoreGuardAlgebra.ExitWitness) :
 RestoreGuardAlgebra.dispatch records a w=RestoreGuardAlgebra.dispatch records b w :=
 RestoreGuardAlgebra.ambientCannotRetarget records a b w
end RestoreIngressBridge
