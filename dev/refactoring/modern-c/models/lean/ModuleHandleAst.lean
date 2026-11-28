import Std
namespace ModuleHandleAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 ticket : Int
 stage : Int
 aliases : Int
 loans : Int
 entry : Int
 reply : Int
 leaf : Bool
 edges : Bool
 hasOpaque : Bool
 qualified : Bool
 sealed : Bool
 handle : Bool
 raw : Bool
 effects : Bool
 unknown : Bool
 privateRoot : Bool
 publishedRoot : Bool
 payloadRetired : Bool
 receipt : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(2)) ∧ (q.ticket≥(0)) ∧ (q.ticket≤(4)) ∧ (q.stage≥(0)) ∧ (q.stage≤(5)) ∧ (q.aliases≥(0)) ∧ (q.aliases≤(2)) ∧ (q.loans≥(0)) ∧ (q.loans≤(1)) ∧ (q.entry≥(0)) ∧ (q.entry≤(1)) ∧ (q.reply≥(0)) ∧ (q.reply≤(1)) ∧ ((q.sealed=true) → (((q.leaf=true) ∧ (q.edges=true)) ∧ ((¬(q.hasOpaque=true)) ∨ (q.qualified=true)))) ∧ ((q.ticket=(2)) → (q.handle=true)) ∧ (((q.ticket=(2)) ∧ (¬(q.payloadRetired=true))) → (q.publishedRoot=true)) ∧ ((q.reply=(1)) → (q.ticket=(2))) ∧ (((q.stage=(1)) ∨ (q.stage=(3))) → (q.entry=(1))) ∧ (((q.ticket=(1)) ∧ (q.effects=true)) → (q.privateRoot=true)) ∧ ((q.payloadRetired=true) → ((((((((q.phase≥(1)) ∧ (q.stage=(4))) ∧ (q.aliases=(0))) ∧ (q.loans=(0))) ∧ (q.entry=(0))) ∧ (¬(q.privateRoot=true))) ∧ (¬(q.unknown=true))) ∧ (¬(q.raw=true)))) ∧ ((q.receipt=true) → (((((((((q.phase≥(1)) ∧ (q.sealed=true)) ∧ (q.aliases=(0))) ∧ (q.loans=(0))) ∧ (q.entry=(0))) ∧ (¬(q.privateRoot=true))) ∧ (¬(q.raw=true))) ∧ (¬(q.unknown=true))) ∧ ((q.ticket=(3)) ∨ ((q.ticket=(2)) ∧ (q.payloadRetired=true))))) ∧ ((q.phase=(2)) → (q.receipt=true)) ∧ ((q.effects=true) → (q.ticket≥(1))) ∧ ((q.payloadRetired=true) → (q.ticket=(2))))
def initial : State := {phase:=(0), ticket:=(0), stage:=(0), aliases:=(0), loans:=(0), entry:=(0), reply:=(0), leaf:=false, edges:=false, hasOpaque:=false, qualified:=false, sealed:=false, handle:=false, raw:=false, effects:=false, unknown:=false, privateRoot:=false, publishedRoot:=false, payloadRetired:=false, receipt:=false}
def recordLeafGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.sealed=true))
def recordLeafNext (q : State) : State := {q with leaf:=true}
def recordEdgesGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.sealed=true))
def recordEdgesNext (q : State) : State := {q with edges:=true}
def declareOpaqueGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.sealed=true))
def declareOpaqueNext (q : State) : State := {q with hasOpaque:=true}
def qualifyNativeGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.sealed=true))
def qualifyNativeNext (q : State) : State := {q with qualified:=true}
def sealSpecGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.leaf=true) ∧ (q.edges=true) ∧ ((¬(q.hasOpaque=true)) ∨ (q.qualified=true))
def sealSpecNext (q : State) : State := {q with sealed:=true}
def reserveGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.ticket=(0))
def reserveNext (q : State) : State := {q with ticket:=(1)}
def protectCandidateGuard (q : State) : Prop := (q.ticket=(1)) ∧ (q.phase≤(1))
def protectCandidateNext (q : State) : State := {q with privateRoot:=true}
def startEffectsGuard (q : State) : Prop := (q.ticket=(1)) ∧ (q.privateRoot=true) ∧ (q.phase≤(1))
def startEffectsNext (q : State) : State := {q with effects:=true}
def commitGuard (q : State) : Prop := (q.ticket=(1)) ∧ (q.sealed=true) ∧ (q.privateRoot=true) ∧ (q.phase≤(1))
def commitNext (q : State) : State := {q with ticket:=(2), handle:=true, publishedRoot:=true, aliases:=(2)}
def acknowledgeGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.phase≤(1))
def acknowledgeNext (q : State) : State := {q with reply:=(1)}
def retryReplyGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.reply=(1)) ∧ (q.phase≤(1))
def retryReplyNext (q : State) : State := {q with reply:=(1)}
def dropCandidateGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.publishedRoot=true) ∧ (q.phase≤(1))
def dropCandidateNext (q : State) : State := {q with privateRoot:=false}
def abortBeforeEffectsGuard (q : State) : Prop := (q.ticket=(1)) ∧ (¬(q.effects=true)) ∧ (q.phase≤(1))
def abortBeforeEffectsNext (q : State) : State := {q with ticket:=(3), privateRoot:=false}
def unknownReservedGuard (q : State) : Prop := (q.ticket=(1)) ∧ (q.phase≤(1))
def unknownReservedNext (q : State) : State := {q with ticket:=(4), unknown:=true}
def unknownCommittedGuard (q : State) : Prop := (q.ticket=(2)) ∧ (¬(q.payloadRetired=true)) ∧ (q.phase≤(1))
def unknownCommittedNext (q : State) : State := {q with unknown:=true}
def exposeRawGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.phase=(0))
def exposeRawNext (q : State) : State := {q with raw:=true}
def borrowNativeGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.phase=(0)) ∧ (q.loans=(0))
def borrowNativeNext (q : State) : State := {q with loans:=(1)}
def returnBorrowGuard (q : State) : Prop := (q.loans=(1))
def returnBorrowNext (q : State) : State := {q with loans:=(0)}
def beginNativeInitGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.stage=(0)) ∧ (q.entry=(0)) ∧ (q.phase≤(1))
def beginNativeInitNext (q : State) : State := {q with stage:=(1), entry:=(1)}
def returnNativeInitGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.stage=(1)) ∧ (q.entry=(1))
def returnNativeInitNext (q : State) : State := {q with stage:=(2), entry:=(0)}
def beginSchemeInitGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.stage=(2)) ∧ (q.entry=(0)) ∧ (q.phase≤(1))
def beginSchemeInitNext (q : State) : State := {q with stage:=(3), entry:=(1)}
def returnSchemeInitGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.stage=(3)) ∧ (q.entry=(1))
def returnSchemeInitNext (q : State) : State := {q with stage:=(4), entry:=(0)}
def failInitGuard (q : State) : Prop := (q.ticket=(2)) ∧ ((q.stage=(1)) ∨ (q.stage=(3))) ∧ (q.phase≤(1))
def failInitNext (q : State) : State := {q with stage:=(5), entry:=(0), unknown:=true}
def removeAliasGuard (q : State) : Prop := (q.aliases>(0)) ∧ (q.phase=(1))
def removeAliasNext (q : State) : State := {q with aliases:=(q.aliases-(1))}
def publishAliasGuard (q : State) : Prop := (q.ticket=(2)) ∧ (q.phase=(0)) ∧ (q.aliases<(2))
def publishAliasNext (q : State) : State := {q with aliases:=(q.aliases+(1))}
def closeGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.sealed=true)
def closeNext (q : State) : State := {q with phase:=(1)}
def retirePayloadGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.ticket=(2)) ∧ (q.stage=(4)) ∧ (q.aliases=(0)) ∧ (q.loans=(0)) ∧ (q.entry=(0)) ∧ (¬(q.privateRoot=true)) ∧ (¬(q.unknown=true)) ∧ (¬(q.raw=true))
def retirePayloadNext (q : State) : State := {q with publishedRoot:=false, payloadRetired:=true}
def issueGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.sealed=true) ∧ (q.aliases=(0)) ∧ (q.loans=(0)) ∧ (q.entry=(0)) ∧ (¬(q.privateRoot=true)) ∧ (¬(q.raw=true)) ∧ (¬(q.unknown=true)) ∧ ((q.ticket=(3)) ∨ ((q.ticket=(2)) ∧ (q.payloadRetired=true)))
def issueNext (q : State) : State := {q with receipt:=true}
def permitGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.receipt=true)
def permitNext (q : State) : State := {q with phase:=(2)}
def rejectLateGuard (q : State) : Prop := (q.phase≥(1))
def rejectLateNext (q : State) : State := {q with phase:=q.phase}
def Step (q r : State) : Prop := (recordLeafGuard q ∧ r=recordLeafNext q) ∨ (recordEdgesGuard q ∧ r=recordEdgesNext q) ∨ (declareOpaqueGuard q ∧ r=declareOpaqueNext q) ∨ (qualifyNativeGuard q ∧ r=qualifyNativeNext q) ∨ (sealSpecGuard q ∧ r=sealSpecNext q) ∨ (reserveGuard q ∧ r=reserveNext q) ∨ (protectCandidateGuard q ∧ r=protectCandidateNext q) ∨ (startEffectsGuard q ∧ r=startEffectsNext q) ∨ (commitGuard q ∧ r=commitNext q) ∨ (acknowledgeGuard q ∧ r=acknowledgeNext q) ∨ (retryReplyGuard q ∧ r=retryReplyNext q) ∨ (dropCandidateGuard q ∧ r=dropCandidateNext q) ∨ (abortBeforeEffectsGuard q ∧ r=abortBeforeEffectsNext q) ∨ (unknownReservedGuard q ∧ r=unknownReservedNext q) ∨ (unknownCommittedGuard q ∧ r=unknownCommittedNext q) ∨ (exposeRawGuard q ∧ r=exposeRawNext q) ∨ (borrowNativeGuard q ∧ r=borrowNativeNext q) ∨ (returnBorrowGuard q ∧ r=returnBorrowNext q) ∨ (beginNativeInitGuard q ∧ r=beginNativeInitNext q) ∨ (returnNativeInitGuard q ∧ r=returnNativeInitNext q) ∨ (beginSchemeInitGuard q ∧ r=beginSchemeInitNext q) ∨ (returnSchemeInitGuard q ∧ r=returnSchemeInitNext q) ∨ (failInitGuard q ∧ r=failInitNext q) ∨ (removeAliasGuard q ∧ r=removeAliasNext q) ∨ (publishAliasGuard q ∧ r=publishAliasNext q) ∨ (closeGuard q ∧ r=closeNext q) ∨ (retirePayloadGuard q ∧ r=retirePayloadNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (permitGuard q ∧ r=permitNext q) ∨ (rejectLateGuard q ∧ r=rejectLateNext q) ∨ r=q
end ModuleHandleAst
