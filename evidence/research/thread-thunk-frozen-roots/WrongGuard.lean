import ThreadThunkFrozenRoots
namespace ThreadThunkFrozenAst
open ThreadThunkFrozenRoots DerivationReceiptEnvironment
set_option maxRecDepth 10000
def irRegisterGuard (q : PinFlat) : Prop := (q.phase=(0)) ∧ (q.source=true) ∧ (q.staged=true) ∧ (¬(q.target=true))
def irRegisterNext (q : PinFlat) := {q with target:=true, future:=true, receipt:=true, targetStamp:=q.sourceStamp}
theorem activateGuardMeaning (q : PinFlat) : irRegisterGuard q ↔ ThreadThunkFrozenRoots.qRegisterGuard q := by simp [irRegisterGuard,ThreadThunkFrozenRoots.qRegisterGuard,and_assoc]
theorem activateNextMeaning (q : PinFlat) : irRegisterNext q=ThreadThunkFrozenRoots.qRegisterNext q := rfl
def irRestoreGuard (q : PinFlat) : Prop := (q.phase=(2)) ∧ (¬(q.scanBorrow=true))
def irRestoreNext (q : PinFlat) := {q with phase:=(0), sourceView:=false, targetView:=false}
theorem restoreGuardMeaning (q : PinFlat) : irRestoreGuard q ↔ ThreadThunkFrozenRoots.qRestoreGuard q := by simp [irRestoreGuard,ThreadThunkFrozenRoots.qRestoreGuard,and_assoc]
theorem restoreNextMeaning (q : PinFlat) : irRestoreNext q=ThreadThunkFrozenRoots.qRestoreNext q := rfl
def irReleaseGuard (q : PinFlat) : Prop := (q.phase=(0)) ∧ (q.source=true) ∧ (q.target=true) ∧ (q.future=true) ∧ (q.receipt=true) ∧ ( (q.unknown=true)) ∧ (q.targetStamp=q.epoch)
def irReleaseNext (q : PinFlat) := {q with source:=false}
theorem releaseSourceGuardMeaning (q : PinFlat) : irReleaseGuard q ↔ ThreadThunkFrozenRoots.qReleaseGuard q := by simp [irReleaseGuard,ThreadThunkFrozenRoots.qReleaseGuard,and_assoc]
theorem releaseSourceNextMeaning (q : PinFlat) : irReleaseNext q=ThreadThunkFrozenRoots.qReleaseNext q := rfl
def actualRows : List (Nat × Nat) := [(72,67),(77,67),(82,67),(87,67),(92,67),(97,67),(102,67),(105,67),(108,67),(112,67),(115,67),(121,67),(124,67),(127,67),(130,67),(136,67),(139,67),(142,67),(147,67),(150,67),(153,67),(156,67),(161,67),(164,67),(69,67),(68,65),(172,67),(176,67),(198,67),(180,67),(187,67),(202,67),(205,67),(208,67),(220,67),(212,67),(213,67),(224,67),(234,67),(228,67),(229,67),(238,67),(241,67),(244,67),(247,67),(251,67),(254,67),(258,67),(274,67),(263,67),(266,67),(278,67),(285,67),(281,67),(304,67),(290,67),(291,67),(321,67),(309,67),(310,67),(325,67),(342,67),(328,67),(329,67),(333,67),(358,67),(347,67),(348,67),(362,67),(365,67),(369,67),(379,67),(373,67),(374,67),(383,67),(386,67),(400,67),(390,67),(404,201),(405,223),(406,237),(407,277),(408,288),(409,307),(410,324),(411,345),(412,361),(413,382),(414,403),(416,67),(415,67)]
theorem actualRowsChecked : tableCheck actualRows=true := by decide
theorem actualEnvAgrees : Matches actualRows (buildEnv actualRows) := checkedEnvironment actualRows actualRowsChecked
end ThreadThunkFrozenAst
