import Std
namespace SlotMappingAst
set_option maxRecDepth 10000
structure State where
 alias : Int
 d0 : Int
 d1 : Int
 mem0 : Int
 mem1 : Int
 store0 : Int
 store1 : Int
 lookup0 : Int
 lookup1 : Int
 borrow0 : Int
 borrow1 : Int
 gc : Int
 round : Int
 m0 : Int
 m1 : Int
 task0 : Int
 task1 : Int
 updated0 : Int
 updated1 : Int
 word0 : Int
 word1 : Int
 processors : Int
 rejected : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.alias≥(0)) ∧ (q.alias≤(1)) ∧ (q.mem0≥(0)) ∧ (q.mem0≤(1)) ∧ (q.mem1≥(0)) ∧ (q.mem1≤(1)) ∧ (q.store0≥(0)) ∧ (q.store0≤(1)) ∧ (q.store1≥(0)) ∧ (q.store1≤(1)) ∧ (q.borrow0≥(0)) ∧ (q.borrow0≤(1)) ∧ (q.borrow1≥(0)) ∧ (q.borrow1≤(1)) ∧ (q.gc≥(0)) ∧ (q.gc≤(1)) ∧ (q.m0≥(0)) ∧ (q.m0≤(1)) ∧ (q.m1≥(0)) ∧ (q.m1≤(1)) ∧ (q.d0≥(2)) ∧ (q.d0≤(4)) ∧ ((((q.d1=(0)) ∨ (q.d1=(2))) ∨ (q.d1=(3))) ∨ (q.d1=(4))) ∧ (q.lookup0≥(0)) ∧ (q.lookup0≤(2)) ∧ (q.task0≥(0)) ∧ (q.task0≤(4)) ∧ (q.updated0≥(-(1))) ∧ (q.updated0≤q.round) ∧ (q.word0≥(0)) ∧ (((q.d0=(2)) ∨ (q.d0=(3))) → (q.mem0=(1))) ∧ ((q.d0=(4)) → (q.mem0=(0))) ∧ (((q.lookup0>(0)) ∨ (q.borrow0=(1))) → (((q.d0=(2)) ∨ (q.d0=(3))) ∧ (q.mem0=(1)))) ∧ (((q.gc=(1)) ∧ (q.m0=(1))) → ((q.store0=(1)) ∧ (q.task0≥(1)))) ∧ ((q.task0>(0)) → (((q.gc=(1)) ∧ (q.m0=(1))) ∧ (q.store0=(1)))) ∧ ((q.task0=(4)) → (q.updated0=q.round)) ∧ (q.lookup1≥(0)) ∧ (q.lookup1≤(2)) ∧ (q.task1≥(0)) ∧ (q.task1≤(4)) ∧ (q.updated1≥(-(1))) ∧ (q.updated1≤q.round) ∧ (q.word1≥(0)) ∧ (((q.d1=(2)) ∨ (q.d1=(3))) → (q.mem1=(1))) ∧ ((q.d1=(4)) → (q.mem1=(0))) ∧ (((q.lookup1>(0)) ∨ (q.borrow1=(1))) → (((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.mem1=(1)))) ∧ (((q.gc=(1)) ∧ (q.m1=(1))) → ((q.store1=(1)) ∧ (q.task1≥(1)))) ∧ ((q.task1>(0)) → (((q.gc=(1)) ∧ (q.m1=(1))) ∧ (q.store1=(1)))) ∧ ((q.task1=(4)) → (q.updated1=q.round)) ∧ (q.round≥(0)) ∧ (q.rejected≥(0)) ∧ ((q.processors=(1)) ∨ (q.processors=(2))) ∧ ((q.d1=(0)) → ((q.mem1=(0)) ∧ (q.store1=(0)))) ∧ (((q.d0=(2)) ∨ (q.d0=(3))) → (q.store0=(1))) ∧ ((((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.alias=(1))) → (q.store0=(1))) ∧ ((((q.d1=(2)) ∨ (q.d1=(3))) ∧ (q.alias=(0))) → (q.store1=(1))) ∧ ((q.gc=(1)) → (((q.m0=(1)) → (((q.d0=(2)) ∨ (q.d0=(3))) ∨ ((q.alias=(1)) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))))) ∧ ((((q.d0=(2)) ∨ (q.d0=(3))) ∨ ((q.alias=(1)) ∧ ((q.d1=(2)) ∨ (q.d1=(3))))) → (q.m0=(1))))) ∧ ((q.gc=(1)) → (((q.m1=(1)) → ((q.alias=(0)) ∧ ((q.d1=(2)) ∨ (q.d1=(3))))) ∧ (((q.alias=(0)) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))) → (q.m1=(1))))) ∧ ((q.gc=(0)) → ((((q.m0=(0)) ∧ (q.m1=(0))) ∧ (q.task0=(0))) ∧ (q.task1=(0)))))
def initial : State := {alias:=(1), d0:=(2), d1:=(0), mem0:=(1), mem1:=(0), store0:=(1), store1:=(0), lookup0:=(0), lookup1:=(0), borrow0:=(0), borrow1:=(0), gc:=(0), round:=(0), m0:=(0), m1:=(0), task0:=(0), task1:=(0), updated0:=(-(1)), updated1:=(-(1)), word0:=(7), word1:=(7), processors:=(2), rejected:=(0)}
def registerAliasGuard (q : State) : Prop := (q.d0=(2)) ∧ (q.d1=(0)) ∧ (q.gc=(0))
def registerAliasNext (q : State) : State := {q with d1:=(2), mem1:=(1), alias:=(1)}
def registerCopyGuard (q : State) : Prop := (q.d0=(2)) ∧ (q.d1=(0)) ∧ (q.gc=(0))
def registerCopyNext (q : State) : State := {q with d1:=(2), mem1:=(1), store1:=(1), alias:=(0), word1:=q.word0}
def beginLookup0Guard (q : State) : Prop := (q.d0=(2)) ∧ (q.lookup0=(0)) ∧ (q.borrow0=(0))
def beginLookup0Next (q : State) : State := {q with lookup0:=(1)}
def acceptBorrow0Guard (q : State) : Prop := (q.d0=(2)) ∧ (q.lookup0=(1)) ∧ (q.borrow0=(0))
def acceptBorrow0Next (q : State) : State := {q with lookup0:=(0), borrow0:=(1)}
def lookupUnknown0Guard (q : State) : Prop := (q.lookup0=(1))
def lookupUnknown0Next (q : State) : State := {q with lookup0:=(2)}
def resolveLookup0Guard (q : State) : Prop := (q.lookup0=(2))
def resolveLookup0Next (q : State) : State := {q with lookup0:=(1)}
def rejectLookup0Guard (q : State) : Prop := (q.lookup0=(1)) ∧ (q.d0=(3))
def rejectLookup0Next (q : State) : State := {q with lookup0:=(0)}
def returnBorrow0Guard (q : State) : Prop := (q.borrow0=(1))
def returnBorrow0Next (q : State) : State := {q with borrow0:=(0)}
def close0Guard (q : State) : Prop := (q.d0=(2))
def close0Next (q : State) : State := {q with d0:=(3)}
def retire0Guard (q : State) : Prop := (q.d0=(3)) ∧ (q.lookup0=(0)) ∧ (q.borrow0=(0)) ∧ (q.gc=(0))
def retire0Next (q : State) : State := {q with d0:=(4), mem0:=(0)}
def lateRequest0Guard (q : State) : Prop := ((q.d0=(3)) ∨ (q.d0=(4)))
def lateRequest0Next (q : State) : State := {q with rejected:=(q.rejected+(1))}
def claim0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task0=(1))
def claim0Next (q : State) : State := {q with task0:=(2)}
def scan0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task0=(2))
def scan0Next (q : State) : State := {q with task0:=(4), updated0:=q.round, word0:=(q.round+(100))}
def scanUnknown0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task0=(2))
def scanUnknown0Next (q : State) : State := {q with task0:=(3)}
def resolveScan0Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task0=(3))
def resolveScan0Next (q : State) : State := {q with task0:=(4), updated0:=q.round, word0:=(q.round+(100))}
def beginLookup1Guard (q : State) : Prop := (q.d1=(2)) ∧ (q.lookup1=(0)) ∧ (q.borrow1=(0))
def beginLookup1Next (q : State) : State := {q with lookup1:=(1)}
def acceptBorrow1Guard (q : State) : Prop := (q.d1=(2)) ∧ (q.lookup1=(1)) ∧ (q.borrow1=(0))
def acceptBorrow1Next (q : State) : State := {q with lookup1:=(0), borrow1:=(1)}
def lookupUnknown1Guard (q : State) : Prop := (q.lookup1=(1))
def lookupUnknown1Next (q : State) : State := {q with lookup1:=(2)}
def resolveLookup1Guard (q : State) : Prop := (q.lookup1=(2))
def resolveLookup1Next (q : State) : State := {q with lookup1:=(1)}
def rejectLookup1Guard (q : State) : Prop := (q.lookup1=(1)) ∧ (q.d1=(3))
def rejectLookup1Next (q : State) : State := {q with lookup1:=(0)}
def returnBorrow1Guard (q : State) : Prop := (q.borrow1=(1))
def returnBorrow1Next (q : State) : State := {q with borrow1:=(0)}
def close1Guard (q : State) : Prop := (q.d1=(2))
def close1Next (q : State) : State := {q with d1:=(3)}
def retire1Guard (q : State) : Prop := (q.d1=(3)) ∧ (q.lookup1=(0)) ∧ (q.borrow1=(0)) ∧ (q.gc=(0))
def retire1Next (q : State) : State := {q with d1:=(4), mem1:=(0)}
def lateRequest1Guard (q : State) : Prop := ((q.d1=(3)) ∨ (q.d1=(4)))
def lateRequest1Next (q : State) : State := {q with rejected:=(q.rejected+(1))}
def claim1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task1=(1))
def claim1Next (q : State) : State := {q with task1:=(2)}
def scan1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task1=(2))
def scan1Next (q : State) : State := {q with task1:=(4), updated1:=q.round, word1:=(q.round+(100))}
def scanUnknown1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task1=(2))
def scanUnknown1Next (q : State) : State := {q with task1:=(3)}
def resolveScan1Guard (q : State) : Prop := (q.gc=(1)) ∧ (q.task1=(3))
def resolveScan1Next (q : State) : State := {q with task1:=(4), updated1:=q.round, word1:=(q.round+(100))}
def freeze000Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(0)) ∧ ((q.d0=(0)) ∨ (q.d0=(4))) ∧ ((q.d1=(0)) ∨ (q.d1=(4)))
def freeze000Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(0), m1:=(0), task0:=(0), task1:=(0)}
def freeze001Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(0)) ∧ ((q.d0=(0)) ∨ (q.d0=(4))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freeze001Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(0), m1:=(1), task0:=(0), task1:=(1)}
def freeze010Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(0)) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1=(0)) ∨ (q.d1=(4)))
def freeze010Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(1), m1:=(0), task0:=(1), task1:=(0)}
def freeze011Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(0)) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freeze011Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(1), m1:=(0), task0:=(1), task1:=(0)}
def freeze100Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(1)) ∧ ((q.d0=(0)) ∨ (q.d0=(4))) ∧ ((q.d1=(0)) ∨ (q.d1=(4)))
def freeze100Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(0), m1:=(0), task0:=(0), task1:=(0)}
def freeze101Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(1)) ∧ ((q.d0=(0)) ∨ (q.d0=(4))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freeze101Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(1), m1:=(0), task0:=(1), task1:=(0)}
def freeze110Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(1)) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1=(0)) ∨ (q.d1=(4)))
def freeze110Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(1), m1:=(0), task0:=(1), task1:=(0)}
def freeze111Guard (q : State) : Prop := (q.gc=(0)) ∧ (q.alias=(1)) ∧ ((q.d0=(2)) ∨ (q.d0=(3))) ∧ ((q.d1=(2)) ∨ (q.d1=(3)))
def freeze111Next (q : State) : State := {q with gc:=(1), round:=(q.round+(1)), m0:=(1), m1:=(0), task0:=(1), task1:=(0)}
def finishRoundGuard (q : State) : Prop := (q.gc=(1)) ∧ ((q.task0=(0)) ∨ (q.task0=(4))) ∧ ((q.task1=(0)) ∨ (q.task1=(4)))
def finishRoundNext (q : State) : State := {q with gc:=(0), m0:=(0), m1:=(0), task0:=(0), task1:=(0)}
def freeStore0Guard (q : State) : Prop := (q.store0=(1)) ∧ (q.d0=(4)) ∧ (((q.d1=(0)) ∨ (q.d1=(4))) ∨ (q.alias=(0))) ∧ (q.gc=(0))
def freeStore0Next (q : State) : State := {q with store0:=(0)}
def freeStore1Guard (q : State) : Prop := (q.store1=(1)) ∧ (q.d1=(4)) ∧ (q.alias=(0)) ∧ (q.gc=(0))
def freeStore1Next (q : State) : State := {q with store1:=(0)}
def exitProcessorGuard (q : State) : Prop := (q.processors=(2)) ∧ (q.gc=(0))
def exitProcessorNext (q : State) : State := {q with processors:=(1)}
def Step (q r : State) : Prop := (registerAliasGuard q ∧ r=registerAliasNext q) ∨ (registerCopyGuard q ∧ r=registerCopyNext q) ∨ (beginLookup0Guard q ∧ r=beginLookup0Next q) ∨ (acceptBorrow0Guard q ∧ r=acceptBorrow0Next q) ∨ (lookupUnknown0Guard q ∧ r=lookupUnknown0Next q) ∨ (resolveLookup0Guard q ∧ r=resolveLookup0Next q) ∨ (rejectLookup0Guard q ∧ r=rejectLookup0Next q) ∨ (returnBorrow0Guard q ∧ r=returnBorrow0Next q) ∨ (close0Guard q ∧ r=close0Next q) ∨ (retire0Guard q ∧ r=retire0Next q) ∨ (lateRequest0Guard q ∧ r=lateRequest0Next q) ∨ (claim0Guard q ∧ r=claim0Next q) ∨ (scan0Guard q ∧ r=scan0Next q) ∨ (scanUnknown0Guard q ∧ r=scanUnknown0Next q) ∨ (resolveScan0Guard q ∧ r=resolveScan0Next q) ∨ (beginLookup1Guard q ∧ r=beginLookup1Next q) ∨ (acceptBorrow1Guard q ∧ r=acceptBorrow1Next q) ∨ (lookupUnknown1Guard q ∧ r=lookupUnknown1Next q) ∨ (resolveLookup1Guard q ∧ r=resolveLookup1Next q) ∨ (rejectLookup1Guard q ∧ r=rejectLookup1Next q) ∨ (returnBorrow1Guard q ∧ r=returnBorrow1Next q) ∨ (close1Guard q ∧ r=close1Next q) ∨ (retire1Guard q ∧ r=retire1Next q) ∨ (lateRequest1Guard q ∧ r=lateRequest1Next q) ∨ (claim1Guard q ∧ r=claim1Next q) ∨ (scan1Guard q ∧ r=scan1Next q) ∨ (scanUnknown1Guard q ∧ r=scanUnknown1Next q) ∨ (resolveScan1Guard q ∧ r=resolveScan1Next q) ∨ (freeze000Guard q ∧ r=freeze000Next q) ∨ (freeze001Guard q ∧ r=freeze001Next q) ∨ (freeze010Guard q ∧ r=freeze010Next q) ∨ (freeze011Guard q ∧ r=freeze011Next q) ∨ (freeze100Guard q ∧ r=freeze100Next q) ∨ (freeze101Guard q ∧ r=freeze101Next q) ∨ (freeze110Guard q ∧ r=freeze110Next q) ∨ (freeze111Guard q ∧ r=freeze111Next q) ∨ (finishRoundGuard q ∧ r=finishRoundNext q) ∨ (freeStore0Guard q ∧ r=freeStore0Next q) ∨ (freeStore1Guard q ∧ r=freeStore1Next q) ∨ (exitProcessorGuard q ∧ r=exitProcessorNext q) ∨ r=q
end SlotMappingAst
