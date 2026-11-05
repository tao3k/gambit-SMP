import PendingStartComposition
namespace PendingStartupAst
open PendingStartComposition DerivationReceiptEnvironment
set_option maxRecDepth 10000
def irEnterGuard (q : StartupFlat) : Prop := (q.registered=true) ∧ (q.future=true) ∧ (q.syncDone=true) ∧ (¬(q.unknown=true))
def irEnterNext (q : StartupFlat) := {q with entered:=true}
theorem enterFromHandleGuardMeaning (q : StartupFlat) : irEnterGuard q ↔ PendingStartComposition.qEnterGuard q := by simp [irEnterGuard,PendingStartComposition.qEnterGuard,and_assoc]
theorem enterFromHandleNextMeaning (q : StartupFlat) : irEnterNext q=PendingStartComposition.qEnterNext q := rfl
end PendingStartupAst
