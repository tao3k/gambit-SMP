import Std
namespace ChunkCoverageAst
set_option maxRecDepth 10000
structure State where
 lo : Int
 hi : Int
 ha : Int
 hb : Int
 fsa : Int
 fsb : Int
 la : Int
 lb : Int
 term : Int
 custody : Int
 ai : Bool
 bi : Bool
 ar : Bool
 br : Bool
 aseal : Bool
 bseal : Bool
 closed : Bool
 marker : Bool
 deferred : Bool
 aliasesClosed : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.lo=q.ha) ∧ (q.hb=((q.ha+q.fsa)+(2))) ∧ (q.term=((q.hb+q.fsb)+(2))) ∧ (q.hi=(q.term+(1))) ∧ (q.fsa>(0)) ∧ (q.fsb>(0)) ∧ (q.la≥(0)) ∧ (q.la<q.fsa) ∧ (q.lb≥(0)) ∧ (q.lb<q.fsb) ∧ (q.custody≥(0)) ∧ (q.custody≤(3)) ∧ ((q.aseal=true) → ((q.ai=true) ∧ (q.ar=true))) ∧ ((q.bseal=true) → ((q.bi=true) ∧ (q.br=true))) ∧ ((q.ar=true) → (q.ai=true)) ∧ ((q.br=true) → (q.bi=true)) ∧ ((q.closed=true) → (((q.ai=true) ∧ (q.bi=true)) ∧ (q.marker=true))) ∧ ((q.deferred=true) → ((q.closed=true) ∧ (q.custody=(0)))) ∧ ((q.custody≥(1)) → ((((((q.aseal=true) ∧ (q.bseal=true)) ∧ (q.closed=true)) ∧ (q.marker=true)) ∧ (q.aliasesClosed=true)) ∧ (¬(q.deferred=true)))))
def initial : State := {lo:=(101), hi:=(112), ha:=(101), hb:=(107), fsa:=(4), fsb:=(2), la:=(1), lb:=(0), term:=(111), custody:=(0), ai:=false, bi:=false, ar:=false, br:=false, aseal:=false, bseal:=false, closed:=false, marker:=false, deferred:=false, aliasesClosed:=false}
def initializeAGuard (q : State) : Prop := (q.custody=(0)) ∧ (¬(q.ai=true))
def initializeANext (q : State) : State := {q with ai:=true}
def initializeBGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.ai=true) ∧ (¬(q.bi=true))
def initializeBNext (q : State) : State := {q with bi:=true}
def registerAGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.ai=true)
def registerANext (q : State) : State := {q with ar:=true}
def registerBGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.bi=true)
def registerBNext (q : State) : State := {q with br:=true}
def sealAGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.ai=true) ∧ (q.ar=true) ∧ (q.bi=true)
def sealANext (q : State) : State := {q with aseal:=true}
def sealBGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.bi=true) ∧ (q.br=true)
def sealBNext (q : State) : State := {q with bseal:=true}
def closeChunkGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.ai=true) ∧ (q.bi=true)
def closeChunkNext (q : State) : State := {q with closed:=true, marker:=true}
def deferClosedGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.closed=true)
def deferClosedNext (q : State) : State := {q with deferred:=true}
def closeAliasesGuard (q : State) : Prop := (q.custody=(0))
def closeAliasesNext (q : State) : State := {q with aliasesClosed:=true}
def mutateAGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.ai=true) ∧ (¬(q.aliasesClosed=true))
def mutateANext (q : State) : State := {q with aseal:=false}
def publishChunkGuard (q : State) : Prop := (q.custody=(0)) ∧ (q.closed=true) ∧ (q.marker=true) ∧ (q.aseal=true) ∧ (q.bseal=true) ∧ (q.aliasesClosed=true)
def publishChunkNext (q : State) : State := {q with custody:=(1), deferred:=false}
def claimGuard (q : State) : Prop := (q.custody=(1))
def claimNext (q : State) : State := {q with custody:=(2)}
def completeScanGuard (q : State) : Prop := (q.custody=(2))
def completeScanNext (q : State) : State := {q with custody:=(3)}
def Step (q r : State) : Prop := (initializeAGuard q ∧ r=initializeANext q) ∨ (initializeBGuard q ∧ r=initializeBNext q) ∨ (registerAGuard q ∧ r=registerANext q) ∨ (registerBGuard q ∧ r=registerBNext q) ∨ (sealAGuard q ∧ r=sealANext q) ∨ (sealBGuard q ∧ r=sealBNext q) ∨ (closeChunkGuard q ∧ r=closeChunkNext q) ∨ (deferClosedGuard q ∧ r=deferClosedNext q) ∨ (closeAliasesGuard q ∧ r=closeAliasesNext q) ∨ (mutateAGuard q ∧ r=mutateANext q) ∨ (publishChunkGuard q ∧ r=publishChunkNext q) ∨ (claimGuard q ∧ r=claimNext q) ∨ (completeScanGuard q ∧ r=completeScanNext q) ∨ r=q
end ChunkCoverageAst
