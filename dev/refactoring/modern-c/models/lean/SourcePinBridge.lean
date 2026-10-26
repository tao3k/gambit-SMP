import SourcePin
import RestoreIssuer
namespace SourcePinBridge
-- Source admission and collector enrollment are trusted provenance inputs.
def CarrierAdmission (a : SourcePinAst.State) (b : RestoreIssuerAst.State) : Prop :=
 a.carrier0=2 ∧ b.carrier=1 ∧ b.guard=0 ∧ b.intent=4 ∧
 b.version=a.epoch ∧ b.copiedVersion=a.value0
theorem guardReservationAgreement (a : SourcePinAst.State) (b : RestoreIssuerAst.State)
 (r : CarrierAdmission a b) : RestoreIssuerAst.reserveGuardGuard b := by
 simp_all [CarrierAdmission,RestoreIssuerAst.reserveGuardGuard]
theorem collectorRevisionAgreement (a : SourcePinAst.State) (b : RestoreIssuerAst.State)
 (r : CarrierAdmission a b) (h : SourcePinAst.Safe a) : b.copiedVersion=b.version := by
 have e := SourcePin.enrolledCarrierFresh a h r.1
 simp_all [CarrierAdmission]
theorem reservationSuccessorSafe (a : SourcePinAst.State) (b : RestoreIssuerAst.State)
 (r : CarrierAdmission a b) (h : RestoreIssuerAst.Safe b) :
 RestoreIssuerAst.Safe (RestoreIssuerAst.reserveGuardNext b) :=
 RestoreIssuer.reserveGuardPreserves b h (guardReservationAgreement a b r)
end SourcePinBridge
