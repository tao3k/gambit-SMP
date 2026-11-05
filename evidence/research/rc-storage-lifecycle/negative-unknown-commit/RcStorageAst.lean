import Std
namespace RcStorageAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 generation : Int
 operation : Int
 bytes : Int
 checked : Int
 owned : Int
 index : Int
 root : Int
 sourceHold : Int
 known : Int
 owner : Int
 contextClosing : Int
 contextGone : Int
 base : Int
 extra : Int
 extraSeen : Int
 borrow : Int
 scan : Int
 native : Int
 grace : Int
 effects : Int
 savedGeneration : Int
 keyGeneration : Int
 committed : Int
 oldResult : Int
 oldKnown : Int
 frees : Int
 rejections : Int
 deriving DecidableEq
def Safe (q : State) : Prop := (((q.phase=(0)) → ((((((((q.generation=(1)) ∧ (q.operation=(0))) ∧ (q.checked=(0))) ∧ (q.index=(0))) ∧ (q.root=(0))) ∧ (q.sourceHold=(0))) ∧ (q.base=(0))) ∧ (q.known=(0)))) ∧ ((q.phase=(1)) → ((q.index=(0)) ∧ (q.base=(0)))) ∧ (q.phase≥(0)) ∧ (q.phase≤(10)) ∧ (q.generation≥(1)) ∧ (q.generation≤(2)) ∧ (q.operation≥(0)) ∧ (q.operation≤(2)) ∧ (q.bytes≥(0)) ∧ (q.bytes≤(9)) ∧ (q.index≥(0)) ∧ (q.index≤(4)) ∧ (q.owned≥(0)) ∧ (q.owned≤(2)) ∧ (q.owner≥(0)) ∧ (q.owner≤(2)) ∧ (q.savedGeneration≥(0)) ∧ (q.savedGeneration≤q.generation) ∧ (q.keyGeneration≥(0)) ∧ (q.keyGeneration≤q.generation) ∧ (q.oldResult≥(0)) ∧ (q.oldResult≤(2)) ∧ (q.frees≥(0)) ∧ (q.frees≤(2)) ∧ (q.rejections≥(0)) ∧ (q.checked≥(0)) ∧ (q.checked≤(1)) ∧ (q.root≥(0)) ∧ (q.root≤(1)) ∧ (q.sourceHold≥(0)) ∧ (q.sourceHold≤(1)) ∧ (q.known≥(0)) ∧ (q.known≤(1)) ∧ (q.contextClosing≥(0)) ∧ (q.contextClosing≤(1)) ∧ (q.contextGone≥(0)) ∧ (q.contextGone≤(1)) ∧ (q.base≥(0)) ∧ (q.base≤(1)) ∧ (q.extra≥(0)) ∧ (q.extra≤(1)) ∧ (q.extraSeen≥(0)) ∧ (q.extraSeen≤(1)) ∧ (q.borrow≥(0)) ∧ (q.borrow≤(1)) ∧ (q.scan≥(0)) ∧ (q.scan≤(1)) ∧ (q.native≥(0)) ∧ (q.native≤(1)) ∧ (q.grace≥(0)) ∧ (q.grace≤(1)) ∧ (q.effects≥(0)) ∧ (q.effects≤(1)) ∧ (q.committed≥(0)) ∧ (q.committed≤(1)) ∧ (q.oldKnown≥(0)) ∧ (q.oldKnown≤(1)) ∧ ((q.phase>(0)) → (q.operation=q.generation)) ∧ ((q.checked=(1)) → (q.bytes≤(8))) ∧ (((q.phase≥(2)) ∧ (q.phase≤(7))) → ((q.owned=(1)) ∧ (q.keyGeneration=q.generation))) ∧ ((q.owned=(1)) → ((q.phase≥(2)) ∧ (q.phase≤(7)))) ∧ ((q.owned=(2)) → (q.phase=(9))) ∧ ((q.phase=(9)) → ((q.owned=(2)) ∧ (q.owner=(2)))) ∧ (((((q.phase=(0)) ∨ (q.phase=(1))) ∨ (q.phase=(8))) ∨ (q.phase=(10))) → (q.owned=(0))) ∧ (((q.phase=(1)) ∨ (q.phase=(2))) → (q.sourceHold=(1))) ∧ ((q.phase=(3)) → ((q.sourceHold=(1)) ∧ (q.index=(1)))) ∧ ((q.phase=(4)) → (((q.root=(1)) ∧ (q.index=(2))) ∧ (q.committed=(1)))) ∧ ((q.phase=(5)) → (((q.root=(1)) ∧ (q.index=(3))) ∧ (q.committed=(1)))) ∧ (((q.phase≥(6)) ∧ (q.phase≤(9))) → ((((((q.root=(0)) ∧ (q.sourceHold=(0))) ∧ (q.index=(4))) ∧ (q.base=(0))) ∧ (q.extra=(0))) ∧ (q.known=(1)))) ∧ ((((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.known=(0))) → (q.sourceHold=(1))) ∧ ((q.sourceHold=(1)) → (q.owner≥(1))) ∧ ((q.root=(1)) → ((q.phase≥(3)) ∧ (q.phase≤(5)))) ∧ (((q.borrow=(1)) ∨ (q.native=(1))) → ((q.phase=(4)) ∨ (q.phase=(5)))) ∧ ((q.scan=(1)) → (((q.root=(1)) ∧ (q.phase≥(3))) ∧ (q.phase≤(5)))) ∧ ((q.extra=(1)) → (((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.extraSeen=(0)))) ∧ ((q.extraSeen=(1)) → (q.extra=(0))) ∧ ((q.contextGone=(1)) → ((q.contextClosing=(1)) ∧ (((q.owned=(0)) ∧ (q.sourceHold=(0))) ∨ (q.owner=(2))))) ∧ ((q.phase=(10)) → (((q.root=(0)) ∧ (q.sourceHold=(0))) ∧ (q.base=(0)))) ∧ ((q.oldKnown=(1)) → (q.oldResult>(0))))
def initial : State := {phase:=(0), generation:=(1), operation:=(0), bytes:=(8), checked:=(0), owned:=(0), index:=(0), root:=(0), sourceHold:=(0), known:=(0), owner:=(0), contextClosing:=(0), contextGone:=(0), base:=(0), extra:=(0), extraSeen:=(0), borrow:=(0), scan:=(0), native:=(0), grace:=(0), effects:=(0), savedGeneration:=(0), keyGeneration:=(0), committed:=(0), oldResult:=(0), oldKnown:=(0), frees:=(0), rejections:=(0)}
def beginGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.contextClosing=(0))
def beginNext (q : State) : State := {q with phase:=(1), operation:=(1), bytes:=(8), sourceHold:=(1), owner:=(1)}
def beginZeroGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.contextClosing=(0))
def beginZeroNext (q : State) : State := {q with phase:=(1), operation:=(1), bytes:=(0), sourceHold:=(1), owner:=(1)}
def beginTooLargeGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.contextClosing=(0))
def beginTooLargeNext (q : State) : State := {q with phase:=(1), operation:=(1), bytes:=(9), sourceHold:=(1), owner:=(1)}
def ticketFailureGuard (q : State) : Prop := (q.phase=(0))
def ticketFailureNext (q : State) : State := {q with phase:=(10), operation:=(1), known:=(1)}
def checkSizeGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.bytes≤(8))
def checkSizeNext (q : State) : State := {q with checked:=(1)}
def rejectSizeGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.bytes>(8))
def rejectSizeNext (q : State) : State := {q with phase:=(10), sourceHold:=(0), known:=(1)}
def allocNullGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.checked=(1))
def allocNullNext (q : State) : State := {q with phase:=(10), sourceHold:=(0), known:=(1)}
def allocSuccessGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.checked=(1))
def allocSuccessNext (q : State) : State := {q with phase:=(2), owned:=(1), base:=(1), keyGeneration:=q.generation}
def saveKeyGuard (q : State) : Prop := (q.owned=(1)) ∧ (q.savedGeneration=(0))
def saveKeyNext (q : State) : State := {q with savedGeneration:=q.keyGeneration}
def reserveIndexGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.contextClosing=(0))
def reserveIndexNext (q : State) : State := {q with phase:=(3), index:=(1)}
def prepareRootGuard (q : State) : Prop := (q.phase=(3))
def prepareRootNext (q : State) : State := {q with root:=(1)}
def publishGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.root=(1))
def publishNext (q : State) : State := {q with phase:=(4), index:=(2), committed:=(1)}
def queryCommitGuard (q : State) : Prop := ((q.phase=(4)) ∨ (q.phase=(5)))
def queryCommitNext (q : State) : State := {q with known:=(1)}
def releaseSourceGuard (q : State) : Prop := ((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.known=(1)) ∧ (q.root=(1))
def releaseSourceNext (q : State) : State := {q with sourceHold:=(0)}
def retainExtraGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.extra=(0)) ∧ (q.extraSeen=(0))
def retainExtraNext (q : State) : State := {q with extra:=(1)}
def releaseExtraGuard (q : State) : Prop := ((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.extra=(1)) ∧ (q.known=(1))
def releaseExtraNext (q : State) : State := {q with extra:=(0), extraSeen:=(1)}
def releaseBaseGuard (q : State) : Prop := ((q.phase=(4)) ∨ (q.phase=(5))) ∧ (q.base=(1))
def releaseBaseNext (q : State) : State := {q with base:=(0), phase:=(5), index:=(3)}
def borrowGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.borrow=(0))
def borrowNext (q : State) : State := {q with borrow:=(1)}
def returnBorrowGuard (q : State) : Prop := (q.borrow=(1))
def returnBorrowNext (q : State) : State := {q with borrow:=(0)}
def nativePinGuard (q : State) : Prop := (q.phase=(4)) ∧ (q.native=(0))
def nativePinNext (q : State) : State := {q with native:=(1)}
def nativeReturnGuard (q : State) : Prop := (q.native=(1))
def nativeReturnNext (q : State) : State := {q with native:=(0)}
def scanGuard (q : State) : Prop := (q.phase≥(3)) ∧ (q.phase≤(5)) ∧ (q.root=(1)) ∧ (q.scan=(0))
def scanNext (q : State) : State := {q with scan:=(1)}
def finishScanGuard (q : State) : Prop := (q.scan=(1))
def finishScanNext (q : State) : State := {q with scan:=(0)}
def closeEntryGuard (q : State) : Prop := (q.phase=(4))
def closeEntryNext (q : State) : State := {q with phase:=(5), index:=(3)}
def requestCleanupGuard (q : State) : Prop := (q.contextClosing=(0))
def requestCleanupNext (q : State) : State := {q with contextClosing:=(1)}
def handoffVMGuard (q : State) : Prop := (q.contextClosing=(1)) ∧ (q.owner=(1))
def handoffVMNext (q : State) : State := {q with owner:=(2)}
def exitContextGuard (q : State) : Prop := (q.contextClosing=(1)) ∧ ((q.owner=(2)) ∨ ((q.owned=(0)) ∧ (q.sourceHold=(0))))
def exitContextNext (q : State) : State := {q with contextGone:=(1)}
def settleEffectsGuard (q : State) : Prop := (q.phase≥(2)) ∧ (q.phase≤(6)) ∧ (q.native=(0))
def settleEffectsNext (q : State) : State := {q with effects:=(1)}
def abortPrivateGuard (q : State) : Prop := ((q.phase=(2)) ∨ (q.phase=(3))) ∧ (q.scan=(0)) ∧ (q.effects=(1))
def abortPrivateNext (q : State) : State := {q with phase:=(6), index:=(4), root:=(0), sourceHold:=(0), base:=(0), known:=(1)}
def unpublishGuard (q : State) : Prop := (q.phase=(5)) ∧ True ∧ (q.base=(0)) ∧ (q.extra=(0)) ∧ (q.borrow=(0)) ∧ (q.scan=(0)) ∧ (q.native=(0)) ∧ (q.effects=(1))
def unpublishNext (q : State) : State := {q with phase:=(6), index:=(4), root:=(0), sourceHold:=(0)}
def scanGraceGuard (q : State) : Prop := (q.phase=(6))
def scanGraceNext (q : State) : State := {q with grace:=(1)}
def startFreeGuard (q : State) : Prop := (q.phase=(6)) ∧ (q.grace=(1)) ∧ (q.effects=(1))
def startFreeNext (q : State) : State := {q with phase:=(7)}
def finishFreeGuard (q : State) : Prop := (q.phase=(7)) ∧ (q.frees<(2))
def finishFreeNext (q : State) : State := {q with phase:=(8), owned:=(0), frees:=(q.frees+(1))}
def loseFreeOutcomeGuard (q : State) : Prop := (q.phase=(7))
def loseFreeOutcomeNext (q : State) : State := {q with phase:=(9), owned:=(2), owner:=(2)}
def reuseAddressGuard (q : State) : Prop := (q.phase=(8)) ∧ (q.generation<(2)) ∧ (q.contextClosing=(0))
def reuseAddressNext (q : State) : State := {q with phase:=(1), generation:=(q.generation+(1)), operation:=(q.operation+(1)), bytes:=(8), checked:=(0), index:=(0), root:=(0), sourceHold:=(1), known:=(0), owner:=(1), base:=(0), extra:=(0), extraSeen:=(0), grace:=(0), effects:=(0), keyGeneration:=(0), oldResult:=(q.committed+(1)), committed:=(0)}
def queryOldGuard (q : State) : Prop := (q.oldResult>(0))
def queryOldNext (q : State) : State := {q with oldKnown:=(1)}
def rejectOldReleaseGuard (q : State) : Prop := (q.savedGeneration>(0)) ∧ (q.savedGeneration≠q.generation)
def rejectOldReleaseNext (q : State) : State := {q with rejections:=(q.rejections+(1))}
def Step (q r : State) : Prop := (beginGuard q ∧ r=beginNext q) ∨ (beginZeroGuard q ∧ r=beginZeroNext q) ∨ (beginTooLargeGuard q ∧ r=beginTooLargeNext q) ∨ (ticketFailureGuard q ∧ r=ticketFailureNext q) ∨ (checkSizeGuard q ∧ r=checkSizeNext q) ∨ (rejectSizeGuard q ∧ r=rejectSizeNext q) ∨ (allocNullGuard q ∧ r=allocNullNext q) ∨ (allocSuccessGuard q ∧ r=allocSuccessNext q) ∨ (saveKeyGuard q ∧ r=saveKeyNext q) ∨ (reserveIndexGuard q ∧ r=reserveIndexNext q) ∨ (prepareRootGuard q ∧ r=prepareRootNext q) ∨ (publishGuard q ∧ r=publishNext q) ∨ (queryCommitGuard q ∧ r=queryCommitNext q) ∨ (releaseSourceGuard q ∧ r=releaseSourceNext q) ∨ (retainExtraGuard q ∧ r=retainExtraNext q) ∨ (releaseExtraGuard q ∧ r=releaseExtraNext q) ∨ (releaseBaseGuard q ∧ r=releaseBaseNext q) ∨ (borrowGuard q ∧ r=borrowNext q) ∨ (returnBorrowGuard q ∧ r=returnBorrowNext q) ∨ (nativePinGuard q ∧ r=nativePinNext q) ∨ (nativeReturnGuard q ∧ r=nativeReturnNext q) ∨ (scanGuard q ∧ r=scanNext q) ∨ (finishScanGuard q ∧ r=finishScanNext q) ∨ (closeEntryGuard q ∧ r=closeEntryNext q) ∨ (requestCleanupGuard q ∧ r=requestCleanupNext q) ∨ (handoffVMGuard q ∧ r=handoffVMNext q) ∨ (exitContextGuard q ∧ r=exitContextNext q) ∨ (settleEffectsGuard q ∧ r=settleEffectsNext q) ∨ (abortPrivateGuard q ∧ r=abortPrivateNext q) ∨ (unpublishGuard q ∧ r=unpublishNext q) ∨ (scanGraceGuard q ∧ r=scanGraceNext q) ∨ (startFreeGuard q ∧ r=startFreeNext q) ∨ (finishFreeGuard q ∧ r=finishFreeNext q) ∨ (loseFreeOutcomeGuard q ∧ r=loseFreeOutcomeNext q) ∨ (reuseAddressGuard q ∧ r=reuseAddressNext q) ∨ (queryOldGuard q ∧ r=queryOldNext q) ∨ (rejectOldReleaseGuard q ∧ r=rejectOldReleaseNext q) ∨ r=q
end RcStorageAst
