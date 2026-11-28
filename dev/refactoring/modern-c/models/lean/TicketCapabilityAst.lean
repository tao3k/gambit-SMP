import Std
namespace TicketCapabilityAst
set_option maxRecDepth 10000
structure State where
 t0phase : Int
 t0exit : Int
 t0outcome : Int
 t0enters : Int
 t0settles : Int
 t0ack : Bool
 t0unknown : Bool
 t1phase : Int
 t1exit : Int
 t1outcome : Int
 t1enters : Int
 t1settles : Int
 t1ack : Bool
 t1unknown : Bool
 cap : Int
 messageGeneration : Int
 rejected : Int
 duplicateReplies : Int
 h0open : Bool
 h1issued : Bool
 h1open : Bool
 b0issued : Bool
 b0open : Bool
 b1issued : Bool
 b1open : Bool
 s0issued : Bool
 s0open : Bool
 s1issued : Bool
 s1open : Bool
 rawEscape : Bool
 aliasCensus : Bool
 maps : Bool
 maintenanceClosed : Bool
 rootRetired : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.t0phase≥(0)) ∧ (q.t0phase≤(4)) ∧ (q.t0exit≥(0)) ∧ (q.t0exit≤(2)) ∧ (q.t0enters≥(0)) ∧ (q.t0enters≤(1)) ∧ (q.t0settles≥(0)) ∧ (q.t0settles≤(1)) ∧ ((q.t0phase<(2)) → (q.t0enters=(0))) ∧ ((q.t0phase≥(2)) → (q.t0enters=(1))) ∧ ((q.t0phase<(3)) → ((q.t0settles=(0)) ∧ (q.t0outcome=(0)))) ∧ ((q.t0phase≥(3)) → (((q.t0settles=(1)) ∧ (q.t0outcome=q.t0exit)) ∧ (q.t0exit>(0)))) ∧ ((q.t0exit>(0)) → (q.t0phase≥(2))) ∧ (q.t1phase≥(0)) ∧ (q.t1phase≤(4)) ∧ (q.t1exit≥(0)) ∧ (q.t1exit≤(2)) ∧ (q.t1enters≥(0)) ∧ (q.t1enters≤(1)) ∧ (q.t1settles≥(0)) ∧ (q.t1settles≤(1)) ∧ ((q.t1phase<(2)) → (q.t1enters=(0))) ∧ ((q.t1phase≥(2)) → (q.t1enters=(1))) ∧ ((q.t1phase<(3)) → ((q.t1settles=(0)) ∧ (q.t1outcome=(0)))) ∧ ((q.t1phase≥(3)) → (((q.t1settles=(1)) ∧ (q.t1outcome=q.t1exit)) ∧ (q.t1exit>(0)))) ∧ ((q.t1exit>(0)) → (q.t1phase≥(2))) ∧ (q.cap≥(1)) ∧ (q.cap≤(3)) ∧ ((q.messageGeneration=(6)) ∨ (q.messageGeneration=(7))) ∧ (q.rejected≥(0)) ∧ (q.duplicateReplies≥(0)) ∧ ((q.h1open=true) → (q.h1issued=true)) ∧ ((q.b0open=true) → (q.b0issued=true)) ∧ ((q.b1open=true) → (q.b1issued=true)) ∧ ((q.s0open=true) → (q.s0issued=true)) ∧ ((q.s1open=true) → (q.s1issued=true)) ∧ ((q.aliasCensus=true) → (¬(q.rawEscape=true))) ∧ ((q.cap=(3)) → (((((((((q.aliasCensus=true) ∧ (q.maps=true)) ∧ (¬(q.rawEscape=true))) ∧ (¬(q.h0open=true))) ∧ (¬(q.h1open=true))) ∧ (¬(q.b0open=true))) ∧ (¬(q.b1open=true))) ∧ ((q.t0phase=(0)) ∨ (q.t0phase≥(3)))) ∧ ((q.t1phase=(0)) ∨ (q.t1phase≥(3))))) ∧ ((q.maintenanceClosed=true) → (q.cap=(3))) ∧ ((q.rootRetired=true) → ((((q.cap=(3)) ∧ (q.maintenanceClosed=true)) ∧ (¬(q.s0open=true))) ∧ (¬(q.s1open=true)))))
def initial : State := {t0phase:=(0), t0exit:=(0), t0outcome:=(0), t0enters:=(0), t0settles:=(0), t0ack:=false, t0unknown:=false, t1phase:=(0), t1exit:=(0), t1outcome:=(0), t1enters:=(0), t1settles:=(0), t1ack:=false, t1unknown:=false, cap:=(1), messageGeneration:=(7), rejected:=(0), duplicateReplies:=(0), h0open:=true, h1issued:=false, h1open:=false, b0issued:=false, b0open:=false, b1issued:=false, b1open:=false, s0issued:=false, s0open:=false, s1issued:=false, s1open:=false, rawEscape:=false, aliasCensus:=false, maps:=false, maintenanceClosed:=false, rootRetired:=false}
def reserve0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.t0phase=(0)) ∧ (q.cap=(1)) ∧ ((q.h0open=true) ∨ (q.h1open=true))
def reserve0Next (q : State) : State := {q with t0phase:=(1)}
def enter0Guard (q : State) : Prop := (q.t0phase=(1))
def enter0Next (q : State) : State := {q with t0phase:=(2), t0enters:=(1)}
def observeSuccess0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.t0exit=(0))
def observeSuccess0Next (q : State) : State := {q with t0exit:=(1)}
def observeFailure0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.t0exit=(0))
def observeFailure0Next (q : State) : State := {q with t0exit:=(2)}
def commit0Guard (q : State) : Prop := (q.t0phase=(2)) ∧ (q.t0exit>(0))
def commit0Next (q : State) : State := {q with t0phase:=(3), t0outcome:=q.t0exit, t0settles:=(1)}
def query0Guard (q : State) : Prop := (q.t0phase≥(3)) ∧ (q.messageGeneration=(7))
def query0Next (q : State) : State := {q with t0ack:=true, t0unknown:=false}
def queryPending0Guard (q : State) : Prop := ((q.t0phase=(1)) ∨ (q.t0phase=(2))) ∧ (q.messageGeneration=(7))
def queryPending0Next (q : State) : State := {q with duplicateReplies:=(q.duplicateReplies+(1))}
def conflictingSettle0Guard (q : State) : Prop := (q.t0phase≥(3))
def conflictingSettle0Next (q : State) : State := {q with rejected:=(q.rejected+(1))}
def loseReply0Guard (q : State) : Prop := (q.t0phase≥(1))
def loseReply0Next (q : State) : State := {q with t0ack:=false, t0unknown:=true}
def retainTombstone0Guard (q : State) : Prop := (q.t0phase=(3))
def retainTombstone0Next (q : State) : State := {q with t0phase:=(4)}
def reserve1Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.t1phase=(0)) ∧ (q.cap=(1)) ∧ ((q.h0open=true) ∨ (q.h1open=true))
def reserve1Next (q : State) : State := {q with t1phase:=(1)}
def enter1Guard (q : State) : Prop := (q.t1phase=(1))
def enter1Next (q : State) : State := {q with t1phase:=(2), t1enters:=(1)}
def observeSuccess1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.t1exit=(0))
def observeSuccess1Next (q : State) : State := {q with t1exit:=(1)}
def observeFailure1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.t1exit=(0))
def observeFailure1Next (q : State) : State := {q with t1exit:=(2)}
def commit1Guard (q : State) : Prop := (q.t1phase=(2)) ∧ (q.t1exit>(0))
def commit1Next (q : State) : State := {q with t1phase:=(3), t1outcome:=q.t1exit, t1settles:=(1)}
def query1Guard (q : State) : Prop := (q.t1phase≥(3)) ∧ (q.messageGeneration=(7))
def query1Next (q : State) : State := {q with t1ack:=true, t1unknown:=false}
def queryPending1Guard (q : State) : Prop := ((q.t1phase=(1)) ∨ (q.t1phase=(2))) ∧ (q.messageGeneration=(7))
def queryPending1Next (q : State) : State := {q with duplicateReplies:=(q.duplicateReplies+(1))}
def conflictingSettle1Guard (q : State) : Prop := (q.t1phase≥(3))
def conflictingSettle1Next (q : State) : State := {q with rejected:=(q.rejected+(1))}
def loseReply1Guard (q : State) : Prop := (q.t1phase≥(1))
def loseReply1Next (q : State) : State := {q with t1ack:=false, t1unknown:=true}
def retainTombstone1Guard (q : State) : Prop := (q.t1phase=(3))
def retainTombstone1Next (q : State) : State := {q with t1phase:=(4)}
def cloneHandle1Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.cap=(1)) ∧ (q.h0open=true) ∧ (¬(q.h1issued=true))
def cloneHandle1Next (q : State) : State := {q with h1issued:=true, h1open:=true}
def dropHandle0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.h0open=true)
def dropHandle0Next (q : State) : State := {q with h0open:=false}
def dropHandle1Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.h1open=true)
def dropHandle1Next (q : State) : State := {q with h1open:=false}
def duplicateDrop0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (¬(q.h0open=true))
def duplicateDrop0Next (q : State) : State := {q with duplicateReplies:=(q.duplicateReplies+(1))}
def borrowNative0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.cap=(1)) ∧ (¬(q.b0issued=true)) ∧ ((q.h0open=true) ∨ (q.h1open=true))
def borrowNative0Next (q : State) : State := {q with b0issued:=true, b0open:=true}
def returnNative0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.b0open=true)
def returnNative0Next (q : State) : State := {q with b0open:=false}
def borrowNative1Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.cap=(1)) ∧ (¬(q.b1issued=true)) ∧ ((q.h0open=true) ∨ (q.h1open=true))
def borrowNative1Next (q : State) : State := {q with b1issued:=true, b1open:=true}
def returnNative1Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.b1open=true)
def returnNative1Next (q : State) : State := {q with b1open:=false}
def duplicateNativeReturn0Guard (q : State) : Prop := (q.messageGeneration=(7)) ∧ (q.b0issued=true) ∧ (¬(q.b0open=true))
def duplicateNativeReturn0Next (q : State) : State := {q with duplicateReplies:=(q.duplicateReplies+(1))}
def closeCapabilityGuard (q : State) : Prop := (q.cap=(1))
def closeCapabilityNext (q : State) : State := {q with cap:=(2)}
def discoverRawEscapeGuard (q : State) : Prop := (q.cap<(3))
def discoverRawEscapeNext (q : State) : State := {q with rawEscape:=true, aliasCensus:=false}
def attestAliasCensusGuard (q : State) : Prop := (q.cap=(2)) ∧ (¬(q.rawEscape=true)) ∧ (¬(q.h0open=true)) ∧ (¬(q.h1open=true)) ∧ (¬(q.b0open=true)) ∧ (¬(q.b1open=true)) ∧ ((q.t0phase=(0)) ∨ (q.t0phase≥(3))) ∧ ((q.t1phase=(0)) ∨ (q.t1phase≥(3)))
def attestAliasCensusNext (q : State) : State := {q with aliasCensus:=true}
def attestRootMapsGuard (q : State) : Prop := True
def attestRootMapsNext (q : State) : State := {q with maps:=true}
def closeAuthorityGuard (q : State) : Prop := (q.cap=(2)) ∧ (q.aliasCensus=true) ∧ (q.maps=true) ∧ (¬(q.rawEscape=true)) ∧ (¬(q.h0open=true)) ∧ (¬(q.h1open=true)) ∧ (¬(q.b0open=true)) ∧ (¬(q.b1open=true)) ∧ ((q.t0phase=(0)) ∨ (q.t0phase≥(3))) ∧ ((q.t1phase=(0)) ∨ (q.t1phase≥(3)))
def closeAuthorityNext (q : State) : State := {q with cap:=(3)}
def pinScanner0Guard (q : State) : Prop := (¬(q.maintenanceClosed=true)) ∧ (¬(q.rootRetired=true)) ∧ (¬(q.s0issued=true))
def pinScanner0Next (q : State) : State := {q with s0issued:=true, s0open:=true}
def unpinScanner0Guard (q : State) : Prop := (q.s0open=true)
def unpinScanner0Next (q : State) : State := {q with s0open:=false}
def pinScanner1Guard (q : State) : Prop := (¬(q.maintenanceClosed=true)) ∧ (¬(q.rootRetired=true)) ∧ (¬(q.s1issued=true))
def pinScanner1Next (q : State) : State := {q with s1issued:=true, s1open:=true}
def unpinScanner1Guard (q : State) : Prop := (q.s1open=true)
def unpinScanner1Next (q : State) : State := {q with s1open:=false}
def closeMaintenanceGuard (q : State) : Prop := (q.cap=(3))
def closeMaintenanceNext (q : State) : State := {q with maintenanceClosed:=true}
def retireRootGuard (q : State) : Prop := (q.cap=(3)) ∧ (q.maintenanceClosed=true) ∧ (¬(q.s0open=true)) ∧ (¬(q.s1open=true))
def retireRootNext (q : State) : State := {q with rootRetired:=true}
def selectStaleGenerationGuard (q : State) : Prop := True
def selectStaleGenerationNext (q : State) : State := {q with messageGeneration:=(6)}
def selectCurrentGenerationGuard (q : State) : Prop := True
def selectCurrentGenerationNext (q : State) : State := {q with messageGeneration:=(7)}
def rejectStaleRequestGuard (q : State) : Prop := (q.messageGeneration≠(7))
def rejectStaleRequestNext (q : State) : State := {q with rejected:=(q.rejected+(1))}
def Step (q r : State) : Prop := (reserve0Guard q ∧ r=reserve0Next q) ∨ (enter0Guard q ∧ r=enter0Next q) ∨ (observeSuccess0Guard q ∧ r=observeSuccess0Next q) ∨ (observeFailure0Guard q ∧ r=observeFailure0Next q) ∨ (commit0Guard q ∧ r=commit0Next q) ∨ (query0Guard q ∧ r=query0Next q) ∨ (queryPending0Guard q ∧ r=queryPending0Next q) ∨ (conflictingSettle0Guard q ∧ r=conflictingSettle0Next q) ∨ (loseReply0Guard q ∧ r=loseReply0Next q) ∨ (retainTombstone0Guard q ∧ r=retainTombstone0Next q) ∨ (reserve1Guard q ∧ r=reserve1Next q) ∨ (enter1Guard q ∧ r=enter1Next q) ∨ (observeSuccess1Guard q ∧ r=observeSuccess1Next q) ∨ (observeFailure1Guard q ∧ r=observeFailure1Next q) ∨ (commit1Guard q ∧ r=commit1Next q) ∨ (query1Guard q ∧ r=query1Next q) ∨ (queryPending1Guard q ∧ r=queryPending1Next q) ∨ (conflictingSettle1Guard q ∧ r=conflictingSettle1Next q) ∨ (loseReply1Guard q ∧ r=loseReply1Next q) ∨ (retainTombstone1Guard q ∧ r=retainTombstone1Next q) ∨ (cloneHandle1Guard q ∧ r=cloneHandle1Next q) ∨ (dropHandle0Guard q ∧ r=dropHandle0Next q) ∨ (dropHandle1Guard q ∧ r=dropHandle1Next q) ∨ (duplicateDrop0Guard q ∧ r=duplicateDrop0Next q) ∨ (borrowNative0Guard q ∧ r=borrowNative0Next q) ∨ (returnNative0Guard q ∧ r=returnNative0Next q) ∨ (borrowNative1Guard q ∧ r=borrowNative1Next q) ∨ (returnNative1Guard q ∧ r=returnNative1Next q) ∨ (duplicateNativeReturn0Guard q ∧ r=duplicateNativeReturn0Next q) ∨ (closeCapabilityGuard q ∧ r=closeCapabilityNext q) ∨ (discoverRawEscapeGuard q ∧ r=discoverRawEscapeNext q) ∨ (attestAliasCensusGuard q ∧ r=attestAliasCensusNext q) ∨ (attestRootMapsGuard q ∧ r=attestRootMapsNext q) ∨ (closeAuthorityGuard q ∧ r=closeAuthorityNext q) ∨ (pinScanner0Guard q ∧ r=pinScanner0Next q) ∨ (unpinScanner0Guard q ∧ r=unpinScanner0Next q) ∨ (pinScanner1Guard q ∧ r=pinScanner1Next q) ∨ (unpinScanner1Guard q ∧ r=unpinScanner1Next q) ∨ (closeMaintenanceGuard q ∧ r=closeMaintenanceNext q) ∨ (retireRootGuard q ∧ r=retireRootNext q) ∨ (selectStaleGenerationGuard q ∧ r=selectStaleGenerationNext q) ∨ (selectCurrentGenerationGuard q ∧ r=selectCurrentGenerationNext q) ∨ (rejectStaleRequestGuard q ∧ r=rejectStaleRequestNext q) ∨ r=q
end TicketCapabilityAst
