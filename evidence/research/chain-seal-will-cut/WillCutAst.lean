import Std
namespace WillCutAst
set_option maxRecDepth 10000
structure State where
 managed : Bool
 strongLive : Bool
 live : Bool
 da : Bool
 db : Bool
 ea : Bool
 eb : Bool
 cut : Bool
 finished : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.managed=true) → (((q.da=true) → ((q.ea=true) ↔ (¬(q.strongLive=true)))) ∧ ((q.db=true) → ((q.eb=true) ↔ (¬(q.strongLive=true)))) ∧ ((q.cut=true) → ((q.da=true) ∧ (q.db=true))) ∧ (((q.live=true) ∧ (¬(q.strongLive=true))) → (q.cut=true)) ∧ ((q.finished=true) → ((q.cut=true) ∧ (q.live=true))) ∧ (((q.da=true) ∧ (q.db=true)) → ((q.ea=true) ↔ (q.eb=true)))))
def initial : State := {managed:=true, strongLive:=false, live:=false, da:=false, db:=false, ea:=false, eb:=false, cut:=false, finished:=false}
def strongReachableGuard (q : State) : Prop := (¬(q.da=true)) ∧ (¬(q.db=true)) ∧ (¬(q.cut=true)) ∧ (¬(q.live=true))
def strongReachableNext (q : State) : State := {q with strongLive:=true, live:=true}
def decideAGuard (q : State) : Prop := (q.managed=true) ∧ (¬(q.da=true)) ∧ (¬(q.cut=true))
def decideANext (q : State) : State := {q with da:=true, ea:=(decide (¬(q.strongLive=true)))}
def decideBGuard (q : State) : Prop := (q.managed=true) ∧ (¬(q.db=true)) ∧ (¬(q.cut=true))
def decideBNext (q : State) : State := {q with db:=true, eb:=(decide (¬(q.strongLive=true)))}
def legacyDecideAGuard (q : State) : Prop := (¬(q.managed=true)) ∧ (¬(q.da=true))
def legacyDecideANext (q : State) : State := {q with da:=true, ea:=(decide (¬(q.live=true)))}
def legacyDecideBGuard (q : State) : Prop := (¬(q.managed=true)) ∧ (¬(q.db=true))
def legacyDecideBNext (q : State) : State := {q with db:=true, eb:=(decide (¬(q.live=true)))}
def classifyCutGuard (q : State) : Prop := (q.managed=true) ∧ (q.da=true) ∧ (q.db=true)
def classifyCutNext (q : State) : State := {q with cut:=true}
def weakMarkGuard (q : State) : Prop := (((q.managed=true) ∧ (q.cut=true)) ∨ ((¬(q.managed=true)) ∧ ((q.da=true) ∨ (q.db=true))))
def weakMarkNext (q : State) : State := {q with live:=true}
def finishGuard (q : State) : Prop := (q.managed=true) ∧ (q.cut=true) ∧ (q.live=true)
def finishNext (q : State) : State := {q with finished:=true}
def Step (q r : State) : Prop := (strongReachableGuard q ∧ r=strongReachableNext q) ∨ (decideAGuard q ∧ r=decideANext q) ∨ (decideBGuard q ∧ r=decideBNext q) ∨ (legacyDecideAGuard q ∧ r=legacyDecideANext q) ∨ (legacyDecideBGuard q ∧ r=legacyDecideBNext q) ∨ (classifyCutGuard q ∧ r=classifyCutNext q) ∨ (weakMarkGuard q ∧ r=weakMarkNext q) ∨ (finishGuard q ∧ r=finishNext q) ∨ r=q
end WillCutAst
