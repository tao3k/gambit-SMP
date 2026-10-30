import ManifestScanQualification
namespace ManifestScanAst
open ManifestScanQualification DerivationReceiptEnvironment
set_option maxRecDepth 10000
def irScanGuard (q : PinFlat) : Prop := (q.frozen=true) ∧ (q.captured=true) ∧ (q.active0=true) ∧ (q.c0=(0))
def irScanNext (q : PinFlat) := {q with c0:=(1), debt:=(q.debt + (1))}
theorem scan0GuardMeaning (q : PinFlat) : irScanGuard q ↔ ManifestScanQualification.qScanGuard q := by simp [irScanGuard,ManifestScanQualification.qScanGuard,and_assoc]
theorem scan0NextMeaning (q : PinFlat) : irScanNext q=ManifestScanQualification.qScanNext q := rfl
def irDrainGuard (q : PinFlat) : Prop := (q.frozen=true) ∧ (q.ingressClosed=true) ∧ (q.c0=(1)) ∧ (q.c1=(1)) ∧ (q.c2=(1)) ∧ (q.debt=(0)) ∧ (¬(q.active0=true)) ∧ (¬(q.active1=true))
def irDrainNext (q : PinFlat) := {q with drained:=true}
theorem drainGuardMeaning (q : PinFlat) : irDrainGuard q ↔ ManifestScanQualification.qDrainGuard q := by simp [irDrainGuard,ManifestScanQualification.qDrainGuard,and_assoc]
theorem drainNextMeaning (q : PinFlat) : irDrainNext q=ManifestScanQualification.qDrainNext q := rfl
def irRetireGuard (q : PinFlat) : Prop := ( (q.captured=true)) ∧ ( (q.frozen=true)) ∧ ((q.joinedB=true) ∨ (q.rejectedB=true)) ∧ ( (q.quarantinedB=true))
def irRetireNext (q : PinFlat) := {q with retiredB:=true}
theorem retireBGuardMeaning (q : PinFlat) : irRetireGuard q ↔ ManifestScanQualification.qRetireGuard q := by simp [irRetireGuard,ManifestScanQualification.qRetireGuard,and_assoc]
theorem retireBNextMeaning (q : PinFlat) : irRetireNext q=ManifestScanQualification.qRetireNext q := rfl
def actualRows : List (Nat × Nat) := [(72,67),(77,67),(82,67),(87,67),(92,67),(97,67),(102,67),(105,67),(108,67),(112,67),(115,67),(121,67),(124,67),(127,67),(130,67),(136,67),(139,67),(142,67),(147,67),(150,67),(153,67),(156,67),(161,67),(164,67),(69,67),(68,65),(172,67),(176,67),(198,67),(180,67),(187,67),(202,67),(205,67),(208,67),(220,67),(212,67),(213,67),(224,67),(234,67),(228,67),(229,67),(238,67),(241,67),(244,67),(247,67),(251,67),(254,67),(258,67),(274,67),(263,67),(266,67),(278,67),(285,67),(281,67),(304,67),(290,67),(291,67),(321,67),(309,67),(310,67),(325,67),(342,67),(328,67),(329,67),(333,67),(358,67),(347,67),(348,67),(362,67),(365,67),(369,67),(379,67),(373,67),(374,67),(383,67),(386,67),(400,67),(390,67),(404,201),(405,223),(406,237),(407,277),(408,288),(409,307),(410,324),(411,345),(412,361),(413,382),(414,403),(416,67),(415,67)]
theorem actualRowsChecked : tableCheck actualRows=true := by decide
theorem actualEnvAgrees : Matches actualRows (buildEnv actualRows) := checkedEnvironment actualRows actualRowsChecked
end ManifestScanAst
