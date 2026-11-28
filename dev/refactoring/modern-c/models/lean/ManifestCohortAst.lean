import ManifestScanQualification
namespace ManifestCohortAst
open ManifestScanQualification DerivationReceiptEnvironment
set_option maxRecDepth 10000
def irAdoptGuard (q : PendingStartComposition.PinFlat) : Prop := (q.phase=(0)) ∧ (q.pendingA=true) ∧ (¬(q.contextA=true)) ∧ (q.launchA=true) ∧ (q.startA=true) ∧ (q.readyA=true) ∧ (q.memberA=true) ∧ (q.ackA=true)
def irAdoptNext (q : PendingStartComposition.PinFlat) := {q with pendingA:=false, contextA:=true}
theorem adoptAGuardMeaning (q : PendingStartComposition.PinFlat) : irAdoptGuard q ↔ PendingStartComposition.qAdoptGuard q := by simp [irAdoptGuard,PendingStartComposition.qAdoptGuard,and_assoc]
theorem adoptANextMeaning (q : PendingStartComposition.PinFlat) : irAdoptNext q=PendingStartComposition.qAdoptNext q := rfl
end ManifestCohortAst
