import SourceOwner
import SourcePin
namespace SourceOwnerBridge
-- Registry round, payload generation and relocation revision are distinct.
def PublishedSource (a : SourceOwnerAst.State) (p : SourcePinAst.State) : Prop :=
 a.owner=2 ∧ a.root=1 ∧ a.writer=0 ∧ p.gate=1 ∧ p.alive=1 ∧ p.accepted0=0 ∧ p.gc=0
theorem sourcePinAgreement (a : SourceOwnerAst.State) (p : SourcePinAst.State)
 (r : PublishedSource a p) : SourcePinAst.pinOuterGuard p := by
 simp_all [PublishedSource,SourcePinAst.pinOuterGuard]
def CurrentCarrier (a : SourceOwnerAst.State) (p : SourcePinAst.State) : Prop :=
 a.target0=1 ∧ a.ack0=a.round ∧ a.gc=0 ∧
 p.carrier0=2 ∧ p.guard0=0 ∧ p.gc=0
theorem carrierReservationAgreement (a : SourceOwnerAst.State) (p : SourcePinAst.State)
 (r : CurrentCarrier a p) : SourcePinAst.reserveGuard0Guard p := by
 simp_all [CurrentCarrier,SourcePinAst.reserveGuard0Guard]
theorem carrierReservationSafe (a : SourceOwnerAst.State) (p : SourcePinAst.State)
 (r : CurrentCarrier a p) (h : SourcePinAst.Safe p) :
 SourcePinAst.Safe (SourcePinAst.reserveGuard0Next p) :=
 SourcePin.reserveGuard0Preserves p h (carrierReservationAgreement a p r)
def ClosedSource (a : SourceOwnerAst.State) (p : SourcePinAst.State) : Prop :=
 a.owner=3 ∧ a.writer=0 ∧ a.manifest=1 ∧ a.storage=1 ∧
 p.gate=0 ∧ p.alive=1 ∧ p.pin0=0 ∧ p.pin1=0 ∧ p.gc=0
theorem cleanupAgreement (a : SourceOwnerAst.State) (p : SourcePinAst.State)
 (r : ClosedSource a p) : SourcePinAst.retireSourceGuard p := by
 simp_all [ClosedSource,SourcePinAst.retireSourceGuard]
def PersistentCarrier (a : SourceOwnerAst.State) (p : SourcePinAst.State) : Prop :=
 a.persistent=1 ∧ a.target0=1 ∧ a.gc=0 ∧ p.carrier0=2 ∧ p.guard0=0 ∧ p.gc=0
theorem persistentCarrierReservation (a : SourceOwnerAst.State) (p : SourcePinAst.State)
 (r : PersistentCarrier a p) : SourcePinAst.reserveGuard0Guard p := by
 simp_all [PersistentCarrier,SourcePinAst.reserveGuard0Guard]
end SourceOwnerBridge
