import Std
namespace CatcherSettlementAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 prepared : Int
 escrow : Int
 issued : Int
 targetActive : Int
 errorClass : Int
 caught : Int
 current : Int
 validated : Int
 receipt : Int
 reply : Int
 refI : Int
 refO : Int
 doneI : Int
 doneO : Int
 effectsI : Int
 effectsO : Int
 critical : Int
 root : Int
 descriptor : Int
 captured : Int
 reader : Int
 copyReady : Int
 scanStage : Int
 slot : Int
 cache : Int
 borrow : Int
 version : Int
 shotActive : Int
 shotTicket : Int
 contextSlot : Int
 closed : Int
 rootRetired : Int
 grace : Int
 guard : Int
 unknown : Int
 leafPermit : Int
 validI : Int
 validO : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.prepared≥(0)) ∧ (q.escrow≥(0)) ∧ (q.issued≥(0)) ∧ (q.targetActive≥(0)) ∧ (q.errorClass≥(0)) ∧ (q.caught≥(0)) ∧ (q.current≥(0)) ∧ (q.validated≥(0)) ∧ (q.receipt≥(0)) ∧ (q.reply≥(0)) ∧ (q.refI≥(0)) ∧ (q.refO≥(0)) ∧ (q.doneI≥(0)) ∧ (q.doneO≥(0)) ∧ (q.effectsI≥(0)) ∧ (q.effectsO≥(0)) ∧ (q.critical≥(0)) ∧ (q.root≥(0)) ∧ (q.descriptor≥(0)) ∧ (q.captured≥(0)) ∧ (q.reader≥(0)) ∧ (q.copyReady≥(0)) ∧ (q.scanStage≥(0)) ∧ (q.slot≥(0)) ∧ (q.cache≥(0)) ∧ (q.borrow≥(0)) ∧ (q.version≥(0)) ∧ (q.shotActive≥(0)) ∧ (q.shotTicket≥(0)) ∧ (q.contextSlot≥(0)) ∧ (q.closed≥(0)) ∧ (q.rootRetired≥(0)) ∧ (q.grace≥(0)) ∧ (q.guard≥(0)) ∧ (q.unknown≥(0)) ∧ (q.leafPermit≥(0)) ∧ (q.validI≥(0)) ∧ (q.validO≥(0)) ∧ (q.phase≤(21)) ∧ (q.prepared≤(2)) ∧ (q.escrow≤(1)) ∧ (q.issued≤(1)) ∧ (q.targetActive≤(1)) ∧ (q.errorClass≤(2)) ∧ (q.caught≤(2)) ∧ (q.current≤(2)) ∧ (q.validated≤(1)) ∧ (q.receipt≤(1)) ∧ (q.reply≤(1)) ∧ (q.refI≤(1)) ∧ (q.refO≤(1)) ∧ (q.doneI≤(1)) ∧ (q.doneO≤(1)) ∧ (q.effectsI≤(1)) ∧ (q.effectsO≤(1)) ∧ (q.critical≤(2)) ∧ (q.root≤(1)) ∧ (q.descriptor≤(1)) ∧ (q.captured≤(1)) ∧ (q.reader≤(1)) ∧ (q.copyReady≤(1)) ∧ (q.scanStage≤(2)) ∧ (q.slot≤(2)) ∧ (q.cache≤(2)) ∧ (q.borrow≤(1)) ∧ (q.version≤(1)) ∧ (q.shotActive≤(1)) ∧ (q.shotTicket≤(2)) ∧ (q.contextSlot≤(2)) ∧ (q.closed≤(1)) ∧ (q.rootRetired≤(1)) ∧ (q.grace≤(1)) ∧ (q.guard≤(3)) ∧ (q.unknown≤(1)) ∧ (q.leafPermit≤(1)) ∧ (q.validI≤(1)) ∧ (q.validO≤(1)) ∧ (q.phase≠(20)) ∧ (q.leafPermit=(1)) ∧ (q.slot≥(1)) ∧ (q.guard≥(1)) ∧ (((q.phase≤(8)) ∨ (q.phase=(21))) → (q.targetActive=(1))) ∧ ((q.targetActive=(0)) → (q.receipt=(1))) ∧ ((q.effectsO=(1)) → (q.targetActive=(0))) ∧ ((q.guard=(3)) → (q.targetActive=(0))) ∧ ((q.phase=(0)) → ((q.prepared=(0)) ∧ (q.escrow=(0)))) ∧ (((q.phase=(1)) ∨ (q.phase=(21))) → ((q.prepared=(1)) ∧ (q.escrow=(0)))) ∧ ((q.phase=(2)) → ((q.prepared=(2)) ∧ (q.escrow=(0)))) ∧ ((q.escrow=(0)) → ((((q.phase=(0)) ∨ (q.phase=(1))) ∨ (q.phase=(2))) ∨ (q.phase=(21)))) ∧ ((q.escrow=(0)) → (((((((((q.issued=(0)) ∧ (q.receipt=(0))) ∧ (q.validI=(1))) ∧ (q.validO=(1))) ∧ (q.guard=(1))) ∧ (q.root=(1))) ∧ (q.descriptor=(1))) ∧ (q.captured=(1))) ∧ (q.critical=(0)))) ∧ ((q.borrow=(1)) → ((((((q.phase=(8)) ∨ (q.phase=(9))) ∨ (q.phase=(10))) ∨ (q.phase=(11))) ∨ (q.phase=(12))) ∨ (q.phase=(14)))) ∧ (((q.phase≥(16)) ∧ (q.phase≤(19))) → (q.closed=(1))) ∧ (((q.phase≥(17)) ∧ (q.phase≤(19))) → ((q.root=(0)) ∧ (q.rootRetired=(1)))) ∧ (((q.phase≥(18)) ∧ (q.phase≤(19))) → (q.grace=(1))) ∧ (((q.phase≥(4)) ∧ (q.phase≤(19))) → (q.errorClass≥(1))) ∧ (((q.phase≤(3)) ∨ (q.phase=(21))) → (q.errorClass=(0))) ∧ ((q.receipt=(1)) → (q.errorClass=(1))) ∧ (((q.phase≥(3)) ∧ (q.phase≤(19))) → (((((q.escrow=(1)) ∧ (q.prepared=(2))) ∧ (q.validI=(0))) ∧ (q.validO=(0))) ∧ (q.guard≥(2)))) ∧ ((q.escrow=(1)) → ((q.phase≥(3)) ∧ (q.phase≤(19)))) ∧ ((q.issued=(1)) → ((q.phase≥(4)) ∧ (q.phase≤(19)))) ∧ (((q.phase≥(4)) ∧ (q.phase≤(19))) → (q.issued=(1))) ∧ (((q.phase≤(4)) ∨ (q.phase=(21))) → ((q.caught=(0)) ∧ (q.current=(2)))) ∧ ((q.phase=(5)) → ((q.caught=(2)) ∧ (q.current=(2)))) ∧ ((q.phase=(6)) → ((q.caught=(2)) ∧ (q.current=(1)))) ∧ ((q.phase=(7)) → ((q.caught=(1)) ∧ (q.current=(1)))) ∧ (((q.phase≥(8)) ∧ (q.phase≤(19))) → ((q.caught=(1)) ∧ (q.current=(0)))) ∧ ((q.validated=(1)) → ((((((q.phase≥(8)) ∧ (q.phase≤(19))) ∧ (q.caught=(1))) ∧ (q.current=(0))) ∧ (q.issued=(1))) ∧ (q.errorClass=(1)))) ∧ ((q.receipt=(1)) → (((q.phase≥(9)) ∧ (q.phase≤(19))) ∧ (q.validated=(1)))) ∧ (((q.phase≥(9)) ∧ (q.phase≤(19))) → (q.receipt=(1))) ∧ (((q.phase≤(8)) ∨ (q.phase=(21))) → (((((((q.refI=(1)) ∧ (q.refO=(1))) ∧ (q.effectsI=(0))) ∧ (q.effectsO=(0))) ∧ (q.doneI=(0))) ∧ (q.doneO=(0))) ∧ (q.critical=(0)))) ∧ ((q.phase=(9)) → (((((((q.refI=(1)) ∧ (q.refO=(1))) ∧ (q.effectsI=(0))) ∧ (q.effectsO=(0))) ∧ (q.doneI=(0))) ∧ (q.doneO=(0))) ∧ (q.critical≤(1)))) ∧ ((q.phase=(10)) → (((((((q.refI=(0)) ∧ (q.effectsI=(1))) ∧ (q.doneI=(0))) ∧ (q.refO=(1))) ∧ (q.effectsO=(0))) ∧ (q.doneO=(0))) ∧ (q.critical=(1)))) ∧ ((q.phase=(11)) → (((((((q.refI=(0)) ∧ (q.effectsI=(1))) ∧ (q.doneI=(1))) ∧ (q.refO=(1))) ∧ (q.effectsO=(0))) ∧ (q.doneO=(0))) ∧ ((q.critical=(0)) ∨ (q.critical=(2))))) ∧ ((q.phase=(12)) → (((((((q.refI=(0)) ∧ (q.effectsI=(1))) ∧ (q.doneI=(1))) ∧ (q.refO=(0))) ∧ (q.effectsO=(1))) ∧ (q.doneO=(0))) ∧ (q.critical=(2)))) ∧ (((q.phase≥(13)) ∧ (q.phase≤(19))) → (((((((q.refI=(0)) ∧ (q.refO=(0))) ∧ (q.effectsI=(1))) ∧ (q.effectsO=(1))) ∧ (q.doneI=(1))) ∧ (q.doneO=(1))) ∧ (q.critical=(0)))) ∧ ((q.refI+q.effectsI)=(1)) ∧ ((q.refO+q.effectsO)=(1)) ∧ (q.doneI≤q.effectsI) ∧ (q.doneO≤q.effectsO) ∧ ((q.doneI=(1)) → (q.receipt=(1))) ∧ ((q.doneO=(1)) → ((q.doneI=(1)) ∧ (q.receipt=(1)))) ∧ ((q.critical=(1)) → ((((((q.phase=(9)) ∨ (q.phase=(10))) ∧ (q.borrow=(1))) ∧ (q.reader=(0))) ∧ (q.receipt=(1))) ∧ (q.reply=(0)))) ∧ ((q.copyReady=(0)) → (((((q.reader=(1)) ∧ (q.borrow=(0))) ∧ (q.critical=(0))) ∧ (q.root=(1))) ∧ (q.descriptor=(1)))) ∧ ((q.critical=(2)) → ((((((q.targetActive=(0)) ∧ ((q.phase=(11)) ∨ (q.phase=(12)))) ∧ (q.borrow=(1))) ∧ (q.reader=(0))) ∧ (q.receipt=(1))) ∧ (q.reply=(0)))) ∧ (((q.phase≥(14)) ∧ (q.phase≤(19))) → (q.guard=(3))) ∧ ((q.guard=(3)) → ((q.phase≥(14)) ∧ (q.phase≤(19)))) ∧ ((q.guard=(2)) → ((q.phase≥(3)) ∧ (q.phase≤(13)))) ∧ ((q.reply=(1)) → ((((((q.phase=(3)) ∨ (q.phase=(9))) ∨ (q.phase=(11))) ∨ (q.phase=(13))) ∧ (q.critical=(0))) ∧ (q.borrow=(0)))) ∧ ((q.unknown=(1)) → (q.phase=(21))) ∧ ((q.phase=(21)) → (q.unknown=(1))) ∧ ((q.root=(0)) → ((((((((q.phase≥(17)) ∧ (q.phase≤(19))) ∧ (q.rootRetired=(1))) ∧ (q.guard=(3))) ∧ (q.captured=(0))) ∧ (q.closed=(1))) ∧ (q.reader=(0))) ∧ (q.borrow=(0)))) ∧ ((q.rootRetired=(1)) → (((((q.root=(0)) ∧ (q.closed=(1))) ∧ (q.reader=(0))) ∧ (q.doneI=(1))) ∧ (q.doneO=(1)))) ∧ ((q.closed=(1)) → (((((((q.phase≥(16)) ∧ (q.phase≤(19))) ∧ (q.borrow=(0))) ∧ (q.critical=(0))) ∧ (q.captured=(0))) ∧ (q.shotActive=(0))) ∧ (q.guard=(3)))) ∧ ((q.descriptor=(0)) → (((((q.phase=(19)) ∧ (q.rootRetired=(1))) ∧ (q.grace=(1))) ∧ (q.reader=(0))) ∧ (q.captured=(0)))) ∧ ((q.grace=(1)) → ((((q.phase=(18)) ∨ (q.phase=(19))) ∧ (q.rootRetired=(1))) ∧ (q.reader=(0)))) ∧ ((q.captured=(0)) → (((q.phase≥(15)) ∧ (q.phase≤(19))) ∧ (q.shotActive=(0)))) ∧ (((q.phase≥(15)) ∧ (q.phase≤(19))) → (q.captured=(0))) ∧ ((q.shotActive=(1)) → ((((((((q.phase=(14)) ∧ (q.captured=(1))) ∧ (q.root=(1))) ∧ (q.descriptor=(1))) ∧ (q.guard=(3))) ∧ (q.contextSlot>(0))) ∧ (q.borrow=(0))) ∧ (q.shotTicket≥(1)))) ∧ ((q.shotActive=(0)) → (q.contextSlot=(0))) ∧ ((q.reader=(1)) → ((((q.root=(1)) ∧ (q.descriptor=(1))) ∧ (q.borrow=(0))) ∧ (q.critical=(0)))) ∧ ((q.borrow=(1)) → ((((((q.reader=(0)) ∧ (q.root=(1))) ∧ (q.descriptor=(1))) ∧ (q.cache=q.slot)) ∧ (q.closed=(0))) ∧ (q.reply=(0)))) ∧ (((q.shotActive=(1)) ∧ (((q.reader=(0)) ∨ (q.scanStage=(0))) ∨ (q.scanStage=(2)))) → (q.contextSlot=q.slot)) ∧ ((q.scanStage=(1)) → (((((q.reader=(1)) ∧ (q.shotActive=(1))) ∧ (q.slot=(2))) ∧ (q.contextSlot=(1))) ∧ (q.version=(1)))) ∧ ((q.scanStage=(2)) → (((q.reader=(1)) ∧ (q.slot=(2))) ∧ (q.version=(1)))) ∧ ((q.version=(0)) → (q.slot=(1))) ∧ ((q.version=(1)) → (q.slot=(2))) ∧ ((q.scanStage>(0)) → (q.reader=(1))) ∧ ((q.phase≤(16)) → ((q.root=(1)) ∧ (q.descriptor=(1)))) ∧ ((q.phase=(21)) → ((q.root=(1)) ∧ (q.descriptor=(1)))))
def initial : State := {phase:=(0), prepared:=(0), escrow:=(0), issued:=(0), targetActive:=(1), errorClass:=(0), caught:=(0), current:=(2), validated:=(0), receipt:=(0), reply:=(0), refI:=(1), refO:=(1), doneI:=(0), doneO:=(0), effectsI:=(0), effectsO:=(0), critical:=(0), root:=(1), descriptor:=(1), captured:=(1), reader:=(0), copyReady:=(1), scanStage:=(0), slot:=(1), cache:=(0), borrow:=(0), version:=(0), shotActive:=(0), shotTicket:=(0), contextSlot:=(0), closed:=(0), rootRetired:=(0), grace:=(0), guard:=(1), unknown:=(0), leafPermit:=(1), validI:=(1), validO:=(1)}
def prepareFirstGuard (q : State) : Prop := (q.phase=(0))
def prepareFirstNext (q : State) : State := {q with phase:=(1), prepared:=(1)}
def prepareSecondGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.unknown=(0)))
def prepareSecondNext (q : State) : State := {q with phase:=(2), prepared:=(2)}
def rollbackPartialGuard (q : State) : Prop := ((q.phase=(1)) ∧ (q.unknown=(0)))
def rollbackPartialNext (q : State) : State := {q with phase:=(0), prepared:=(0)}
def rollbackReadyGuard (q : State) : Prop := (q.phase=(2))
def rollbackReadyNext (q : State) : State := {q with phase:=(0), prepared:=(0)}
def preparationUnknownGuard (q : State) : Prop := (q.phase=(1))
def preparationUnknownNext (q : State) : State := {q with phase:=(21), unknown:=(1)}
def auditPreparationGuard (q : State) : Prop := (q.phase=(21))
def auditPreparationNext (q : State) : State := {q with phase:=(1), unknown:=(0)}
def publishEscrowGuard (q : State) : Prop := (((q.phase=(2)) ∧ (q.reader=(0))) ∧ (q.borrow=(0)))
def publishEscrowNext (q : State) : State := {q with phase:=(3), escrow:=(1), guard:=(2), validI:=(0), validO:=(0)}
def escrowReplyLostGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.reply=(0)))
def escrowReplyLostNext (q : State) : State := {q with reply:=(1)}
def queryEscrowGuard (q : State) : Prop := ((q.phase=(3)) ∧ (q.reply=(1)))
def queryEscrowNext (q : State) : State := {q with reply:=(0)}
def issueTransferGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.reply=(0))) ∧ (q.reader=(0)))
def issueTransferNext (q : State) : State := {q with phase:=(4), issued:=(1), errorClass:=(1)}
def issueOtherErrorGuard (q : State) : Prop := (((q.phase=(3)) ∧ (q.reply=(0))) ∧ (q.reader=(0)))
def issueOtherErrorNext (q : State) : State := {q with phase:=(4), issued:=(1), errorClass:=(2)}
def catchInnerGuard (q : State) : Prop := (q.phase=(4))
def catchInnerNext (q : State) : State := {q with phase:=(5), caught:=(2)}
def restoreInnerCatcherGuard (q : State) : Prop := (q.phase=(5))
def restoreInnerCatcherNext (q : State) : State := {q with phase:=(6), current:=(1)}
def catchOuterGuard (q : State) : Prop := (q.phase=(6))
def catchOuterNext (q : State) : State := {q with phase:=(7), caught:=(1)}
def restoreOuterCatcherGuard (q : State) : Prop := (q.phase=(7))
def restoreOuterCatcherNext (q : State) : State := {q with phase:=(8), current:=(0)}
def borrowFreshGuard (q : State) : Prop := (((((((((((q.phase=(8)) ∨ (q.phase=(9))) ∨ (q.phase=(11))) ∨ (q.phase=(14))) ∧ (q.reply=(0))) ∧ (q.reader=(0))) ∧ (q.borrow=(0))) ∧ (q.critical=(0))) ∧ (q.root=(1))) ∧ (q.closed=(0))) ∧ (q.shotActive=(0)))
def borrowFreshNext (q : State) : State := {q with borrow:=(1), cache:=q.slot}
def releaseBorrowGuard (q : State) : Prop := (((q.borrow=(1)) ∧ (q.critical=(0))) ∧ (q.shotActive=(0)))
def releaseBorrowNext (q : State) : State := {q with borrow:=(0)}
def validateLandingGuard (q : State) : Prop := ((((((((q.phase=(8)) ∧ (q.errorClass=(1))) ∧ (q.caught=(1))) ∧ (q.current=(0))) ∧ (q.issued=(1))) ∧ (q.borrow=(1))) ∧ (q.cache=q.slot)) ∧ (q.reader=(0)))
def validateLandingNext (q : State) : State := {q with validated:=(1)}
def publishLandingGuard (q : State) : Prop := ((((q.phase=(8)) ∧ (q.validated=(1))) ∧ (q.borrow=(1))) ∧ (q.cache=q.slot))
def publishLandingNext (q : State) : State := {q with phase:=(9), receipt:=(1), borrow:=(0)}
def landingReplyLostGuard (q : State) : Prop := ((((q.phase=(9)) ∧ (q.reply=(0))) ∧ (q.critical=(0))) ∧ (q.borrow=(0)))
def landingReplyLostNext (q : State) : State := {q with reply:=(1)}
def queryLandingGuard (q : State) : Prop := ((q.phase=(9)) ∧ (q.reply=(1)))
def queryLandingNext (q : State) : State := {q with reply:=(0)}
def beginInnerReleaseGuard (q : State) : Prop := (((((((q.phase=(9)) ∧ (q.receipt=(1))) ∧ (q.reply=(0))) ∧ (q.borrow=(1))) ∧ (q.reader=(0))) ∧ (q.critical=(0))) ∧ (q.leafPermit=(1)))
def beginInnerReleaseNext (q : State) : State := {q with critical:=(1)}
def decrementInnerGuard (q : State) : Prop := ((((q.phase=(9)) ∧ (q.critical=(1))) ∧ (q.refI=(1))) ∧ (q.doneI=(0)))
def decrementInnerNext (q : State) : State := {q with phase:=(10), refI:=(0), effectsI:=(1)}
def commitInnerReleaseGuard (q : State) : Prop := (((q.phase=(10)) ∧ (q.critical=(1))) ∧ (q.refI=(0)))
def commitInnerReleaseNext (q : State) : State := {q with phase:=(11), doneI:=(1), critical:=(0), borrow:=(0)}
def innerReplyLostGuard (q : State) : Prop := ((((q.phase=(11)) ∧ (q.reply=(0))) ∧ (q.critical=(0))) ∧ (q.borrow=(0)))
def innerReplyLostNext (q : State) : State := {q with reply:=(1)}
def queryInnerReleaseGuard (q : State) : Prop := ((q.phase=(11)) ∧ (q.reply=(1)))
def queryInnerReleaseNext (q : State) : State := {q with reply:=(0)}
def nativeTargetReturnedGuard (q : State) : Prop := (((((((q.phase=(9)) ∨ (q.phase=(11))) ∧ (q.receipt=(1))) ∧ (q.targetActive=(1))) ∧ (q.critical=(0))) ∧ (q.borrow=(0))) ∧ (q.reader=(0)))
def nativeTargetReturnedNext (q : State) : State := {q with targetActive:=(0)}
def beginOuterReleaseGuard (q : State) : Prop := (((((((True ∧ (q.phase=(11))) ∧ (q.doneI=(1))) ∧ (q.reply=(0))) ∧ (q.borrow=(1))) ∧ (q.reader=(0))) ∧ (q.critical=(0))) ∧ (q.leafPermit=(1)))
def beginOuterReleaseNext (q : State) : State := {q with critical:=(2)}
def decrementOuterGuard (q : State) : Prop := ((((q.phase=(11)) ∧ (q.critical=(2))) ∧ (q.refO=(1))) ∧ (q.doneO=(0)))
def decrementOuterNext (q : State) : State := {q with phase:=(12), refO:=(0), effectsO:=(1)}
def commitOuterReleaseGuard (q : State) : Prop := (((q.phase=(12)) ∧ (q.critical=(2))) ∧ (q.refO=(0)))
def commitOuterReleaseNext (q : State) : State := {q with phase:=(13), doneO:=(1), critical:=(0), borrow:=(0)}
def outerReplyLostGuard (q : State) : Prop := ((q.phase=(13)) ∧ (q.reply=(0)))
def outerReplyLostNext (q : State) : State := {q with reply:=(1)}
def queryOuterReleaseGuard (q : State) : Prop := ((q.phase=(13)) ∧ (q.reply=(1)))
def queryOuterReleaseNext (q : State) : State := {q with reply:=(0)}
def settleGuardsGuard (q : State) : Prop := ((((q.phase=(13)) ∧ (q.doneI=(1))) ∧ (q.doneO=(1))) ∧ (q.reply=(0)))
def settleGuardsNext (q : State) : State := {q with phase:=(14), guard:=(3)}
def resumeCapturedGuard (q : State) : Prop := (((((((q.phase=(14)) ∧ (q.captured=(1))) ∧ (q.borrow=(1))) ∧ (q.cache=q.slot)) ∧ (q.reader=(0))) ∧ (q.shotActive=(0))) ∧ (q.shotTicket<(2)))
def resumeCapturedNext (q : State) : State := {q with shotActive:=(1), shotTicket:=(q.shotTicket+(1)), contextSlot:=q.slot, borrow:=(0)}
def finishResumptionGuard (q : State) : Prop := ((((q.phase=(14)) ∧ (q.shotActive=(1))) ∧ (q.reader=(0))) ∧ (q.contextSlot=q.slot))
def finishResumptionNext (q : State) : State := {q with shotActive:=(0), contextSlot:=(0)}
def dropCapturedGuard (q : State) : Prop := (((q.phase=(14)) ∧ (q.shotActive=(0))) ∧ (q.borrow=(0)))
def dropCapturedNext (q : State) : State := {q with phase:=(15), captured:=(0)}
def startGcGuard (q : State) : Prop := ((((((q.root=(1)) ∧ (q.descriptor=(1))) ∧ (q.closed=(0))) ∧ (q.borrow=(0))) ∧ (q.critical=(0))) ∧ (q.reader=(0)))
def startGcNext (q : State) : State := {q with reader:=(1)}
def rewriteRootOnlyGuard (q : State) : Prop := (((q.reader=(1)) ∧ (q.version=(0))) ∧ (q.shotActive=(0)))
def rewriteRootOnlyNext (q : State) : State := {q with slot:=(2), version:=(1), scanStage:=(2), copyReady:=(0)}
def rewriteRegistryFirstGuard (q : State) : Prop := (((q.reader=(1)) ∧ (q.version=(0))) ∧ (q.shotActive=(1)))
def rewriteRegistryFirstNext (q : State) : State := {q with slot:=(2), version:=(1), scanStage:=(1), copyReady:=(0)}
def rewriteContextSlotGuard (q : State) : Prop := ((q.reader=(1)) ∧ (q.scanStage=(1)))
def rewriteContextSlotNext (q : State) : State := {q with contextSlot:=(2), scanStage:=(2)}
def initializeCopiedObjectGuard (q : State) : Prop := (((q.reader=(1)) ∧ (q.version=(1))) ∧ (q.copyReady=(0)))
def initializeCopiedObjectNext (q : State) : State := {q with copyReady:=(1)}
def finishGcGuard (q : State) : Prop := ((((q.copyReady=(1)) ∧ (q.reader=(1))) ∧ (q.scanStage≠(1))) ∧ ((q.shotActive=(0)) ∨ (q.contextSlot=q.slot)))
def finishGcNext (q : State) : State := {q with reader:=(0), scanStage:=(0)}
def closeRootAdmissionGuard (q : State) : Prop := (((q.phase=(15)) ∧ (q.borrow=(0))) ∧ (q.critical=(0)))
def closeRootAdmissionNext (q : State) : State := {q with phase:=(16), closed:=(1)}
def retireRootsGuard (q : State) : Prop := ((q.phase=(16)) ∧ (q.reader=(0)))
def retireRootsNext (q : State) : State := {q with phase:=(17), root:=(0), rootRetired:=(1)}
def ackDescriptorGraceGuard (q : State) : Prop := ((q.phase=(17)) ∧ (q.reader=(0)))
def ackDescriptorGraceNext (q : State) : State := {q with phase:=(18), grace:=(1)}
def retireDescriptorGuard (q : State) : Prop := (((((q.phase=(18)) ∧ (q.root=(0))) ∧ (q.captured=(0))) ∧ (q.reader=(0))) ∧ (q.grace=(1)))
def retireDescriptorNext (q : State) : State := {q with phase:=(19), descriptor:=(0)}
def Step (q r : State) : Prop := (prepareFirstGuard q ∧ r=prepareFirstNext q) ∨ (prepareSecondGuard q ∧ r=prepareSecondNext q) ∨ (rollbackPartialGuard q ∧ r=rollbackPartialNext q) ∨ (rollbackReadyGuard q ∧ r=rollbackReadyNext q) ∨ (preparationUnknownGuard q ∧ r=preparationUnknownNext q) ∨ (auditPreparationGuard q ∧ r=auditPreparationNext q) ∨ (publishEscrowGuard q ∧ r=publishEscrowNext q) ∨ (escrowReplyLostGuard q ∧ r=escrowReplyLostNext q) ∨ (queryEscrowGuard q ∧ r=queryEscrowNext q) ∨ (issueTransferGuard q ∧ r=issueTransferNext q) ∨ (issueOtherErrorGuard q ∧ r=issueOtherErrorNext q) ∨ (catchInnerGuard q ∧ r=catchInnerNext q) ∨ (restoreInnerCatcherGuard q ∧ r=restoreInnerCatcherNext q) ∨ (catchOuterGuard q ∧ r=catchOuterNext q) ∨ (restoreOuterCatcherGuard q ∧ r=restoreOuterCatcherNext q) ∨ (borrowFreshGuard q ∧ r=borrowFreshNext q) ∨ (releaseBorrowGuard q ∧ r=releaseBorrowNext q) ∨ (validateLandingGuard q ∧ r=validateLandingNext q) ∨ (publishLandingGuard q ∧ r=publishLandingNext q) ∨ (landingReplyLostGuard q ∧ r=landingReplyLostNext q) ∨ (queryLandingGuard q ∧ r=queryLandingNext q) ∨ (beginInnerReleaseGuard q ∧ r=beginInnerReleaseNext q) ∨ (decrementInnerGuard q ∧ r=decrementInnerNext q) ∨ (commitInnerReleaseGuard q ∧ r=commitInnerReleaseNext q) ∨ (innerReplyLostGuard q ∧ r=innerReplyLostNext q) ∨ (queryInnerReleaseGuard q ∧ r=queryInnerReleaseNext q) ∨ (nativeTargetReturnedGuard q ∧ r=nativeTargetReturnedNext q) ∨ (beginOuterReleaseGuard q ∧ r=beginOuterReleaseNext q) ∨ (decrementOuterGuard q ∧ r=decrementOuterNext q) ∨ (commitOuterReleaseGuard q ∧ r=commitOuterReleaseNext q) ∨ (outerReplyLostGuard q ∧ r=outerReplyLostNext q) ∨ (queryOuterReleaseGuard q ∧ r=queryOuterReleaseNext q) ∨ (settleGuardsGuard q ∧ r=settleGuardsNext q) ∨ (resumeCapturedGuard q ∧ r=resumeCapturedNext q) ∨ (finishResumptionGuard q ∧ r=finishResumptionNext q) ∨ (dropCapturedGuard q ∧ r=dropCapturedNext q) ∨ (startGcGuard q ∧ r=startGcNext q) ∨ (rewriteRootOnlyGuard q ∧ r=rewriteRootOnlyNext q) ∨ (rewriteRegistryFirstGuard q ∧ r=rewriteRegistryFirstNext q) ∨ (rewriteContextSlotGuard q ∧ r=rewriteContextSlotNext q) ∨ (initializeCopiedObjectGuard q ∧ r=initializeCopiedObjectNext q) ∨ (finishGcGuard q ∧ r=finishGcNext q) ∨ (closeRootAdmissionGuard q ∧ r=closeRootAdmissionNext q) ∨ (retireRootsGuard q ∧ r=retireRootsNext q) ∨ (ackDescriptorGraceGuard q ∧ r=ackDescriptorGraceNext q) ∨ (retireDescriptorGuard q ∧ r=retireDescriptorNext q) ∨ r=q
end CatcherSettlementAst
