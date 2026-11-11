import Std
namespace CapacityChargeAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 capacity : Int
 limitWords : Int
 visitBudget : Int
 visits : Int
 thresholds : Int
 early : Int
 openCount : Int
 starts : Int
 markers : Int
 committed : Int
 closedSpan : Int
 span : Int
 grant : Int
 cancelled : Int
 cutStarts : Int
 cutWords : Int
 cutVisits : Int
 cutSpan : Int
 forwarded : Bool
 noFit : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(2)) ∧ (q.limitWords≥(0)) ∧ (q.visitBudget≥(1)) ∧ (q.capacity≥q.visitBudget) ∧ (q.limitWords<((255)*((q.capacity-q.visitBudget)+(1)))) ∧ (q.visits≥(1)) ∧ (q.visits≤q.visitBudget) ∧ (q.thresholds≥(0)) ∧ (q.early≥(0)) ∧ (q.openCount≥(0)) ∧ (q.openCount≤(1)) ∧ (q.visits=(q.early+q.openCount)) ∧ (q.starts=(q.thresholds+q.visits)) ∧ (q.markers=(q.thresholds+q.early)) ∧ (q.starts≤q.capacity) ∧ (q.committed≥(0)) ∧ (q.committed≤q.limitWords) ∧ (q.closedSpan≥(0)) ∧ (q.span≥(0)) ∧ (q.committed=(q.closedSpan+q.span)) ∧ (((255)*q.thresholds)≤q.closedSpan) ∧ ((((q.grant=(0)) ∨ (q.grant=(1))) ∨ (q.grant=(254))) ∨ (q.grant=(257))) ∧ (q.cancelled≥(0)) ∧ ((q.grant>(0)) → ((((q.openCount=(1)) ∧ (q.span<(255))) ∧ (¬(q.noFit=true))) ∧ ((q.committed+q.grant)≤q.limitWords))) ∧ ((q.forwarded=true) → (q.grant>(0))) ∧ ((q.openCount=(0)) → (((q.span=(0)) ∧ (q.grant=(0))) ∧ (q.noFit=true))) ∧ ((q.noFit=true) → (q.grant=(0))) ∧ ((q.phase=(0)) → ((((q.cutStarts=(0)) ∧ (q.cutWords=(0))) ∧ (q.cutVisits=(0))) ∧ (q.cutSpan=(0)))) ∧ ((q.phase≥(1)) → ((((((((q.cutStarts≥(1)) ∧ (q.cutStarts≤q.starts)) ∧ (q.cutWords≥(0))) ∧ (q.cutWords≤q.committed)) ∧ (q.cutVisits≥(1))) ∧ (q.cutVisits≤q.visits)) ∧ (q.cutSpan≥(0))) ∧ (q.cutSpan<(255)))) ∧ ((q.phase=(2)) → ((((q.grant=(0)) ∧ (q.openCount=(1))) ∧ (¬(q.noFit=true))) ∧ (q.span<(255)))))
def initial : State := {phase:=(0), capacity:=(7), limitWords:=(1020), visitBudget:=(3), visits:=(1), thresholds:=(0), early:=(0), openCount:=(1), starts:=(1), markers:=(0), committed:=(0), closedSpan:=(0), span:=(0), grant:=(0), cancelled:=(0), cutStarts:=(0), cutWords:=(0), cutVisits:=(0), cutSpan:=(0), forwarded:=false, noFit:=false}
def reserveOneGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.span<(255)) ∧ (¬(q.noFit=true)) ∧ ((q.committed+(1))≤q.limitWords)
def reserveOneNext (q : State) : State := {q with grant:=(1)}
def reserveNearGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.span<(255)) ∧ (¬(q.noFit=true)) ∧ ((q.committed+(254))≤q.limitWords)
def reserveNearNext (q : State) : State := {q with grant:=(254)}
def reserveOvershootGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.span<(255)) ∧ (¬(q.noFit=true)) ∧ ((q.committed+(257))≤q.limitWords)
def reserveOvershootNext (q : State) : State := {q with grant:=(257)}
def publishForwardGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.grant>(0)) ∧ (¬(q.forwarded=true))
def publishForwardNext (q : State) : State := {q with forwarded:=true}
def commitGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.grant>(0)) ∧ (q.forwarded=true)
def commitNext (q : State) : State := {q with committed:=(q.committed+q.grant), span:=(q.span+q.grant), grant:=(0), forwarded:=false}
def cancelGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.grant>(0)) ∧ (¬(q.forwarded=true))
def cancelNext (q : State) : State := {q with cancelled:=(q.cancelled+q.grant), grant:=(0)}
def closeThresholdGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.span≥(255))
def closeThresholdNext (q : State) : State := {q with thresholds:=(q.thresholds+(1)), markers:=(q.markers+(1)), starts:=(q.starts+(1)), closedSpan:=(q.closedSpan+q.span), span:=(0)}
def observeNoFitGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.span<(255)) ∧ (¬(q.noFit=true))
def observeNoFitNext (q : State) : State := {q with noFit:=true}
def closeEarlyGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(1)) ∧ (q.grant=(0)) ∧ (q.noFit=true)
def closeEarlyNext (q : State) : State := {q with early:=(q.early+(1)), markers:=(q.markers+(1)), closedSpan:=(q.closedSpan+q.span), span:=(0), openCount:=(0)}
def advanceVisitGuard (q : State) : Prop := (q.phase<(2)) ∧ (q.openCount=(0)) ∧ (q.visits<q.visitBudget)
def advanceVisitNext (q : State) : State := {q with visits:=(q.visits+(1)), starts:=(q.starts+(1)), openCount:=(1), noFit:=false}
def cutToWeakGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.grant=(0)) ∧ (q.openCount=(1)) ∧ (¬(q.noFit=true)) ∧ (q.span<(255))
def cutToWeakNext (q : State) : State := {q with phase:=(1), cutStarts:=q.starts, cutWords:=q.committed, cutVisits:=q.visits, cutSpan:=q.span}
def closeCapacityGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.grant=(0)) ∧ (q.openCount=(1)) ∧ (¬(q.noFit=true)) ∧ (q.span<(255))
def closeCapacityNext (q : State) : State := {q with phase:=(2)}
def Step (q r : State) : Prop := (reserveOneGuard q ∧ r=reserveOneNext q) ∨ (reserveNearGuard q ∧ r=reserveNearNext q) ∨ (reserveOvershootGuard q ∧ r=reserveOvershootNext q) ∨ (publishForwardGuard q ∧ r=publishForwardNext q) ∨ (commitGuard q ∧ r=commitNext q) ∨ (cancelGuard q ∧ r=cancelNext q) ∨ (closeThresholdGuard q ∧ r=closeThresholdNext q) ∨ (observeNoFitGuard q ∧ r=observeNoFitNext q) ∨ (closeEarlyGuard q ∧ r=closeEarlyNext q) ∨ (advanceVisitGuard q ∧ r=advanceVisitNext q) ∨ (cutToWeakGuard q ∧ r=cutToWeakNext q) ∨ (closeCapacityGuard q ∧ r=closeCapacityNext q) ∨ r=q
end CapacityChargeAst
