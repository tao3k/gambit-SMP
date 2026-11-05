import TclRefusalAccess
import TclRefusalMutation
import TclRefusalPublication
import TclRefusalTransfer
import TclRefusalRetirement
open TclRefusalAst
namespace TclRefusal
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17
 · rcases h0 with ⟨g,rfl⟩
   exact beginEvalPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact beginNestedPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact recordOuterRefusalPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact recordChildRefusalPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact publishOuterDiagnosticPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact publishChildDiagnosticPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact catchOrResetResultPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact ordinaryTclErrorPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact mergeChildRefusalPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact popNestedPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact finishEvalPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact deliverRefusalPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact deliverOrdinaryNativeErrorPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact translateOrdinaryErrorPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact deliverSuccessPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact closeVmPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact resumeVmPreserves q h g
 · rcases h17 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance h step ih => exact stepPreserves _ _ ih step
theorem deliveredRefusalCannotTranslate (q : State) (h : Safe q) (e : q.eventSeen=1) (d : q.delivered=1) : q.origin=1 ∧ q.translated=0 := by
 unfold Safe at h
 grind
theorem translatedOnlyOpenOrdinary (q : State) (h : Safe q) (t : q.translated=1) : q.vmOpen=1 ∧ q.eventSeen=0 := by
 unfold Safe at h
 grind
theorem caughtCodeKeepsRefusal (q : State) : (catchOrResetResultNext q).eventSeen=q.eventSeen ∧ (catchOrResetResultNext q).outerSticky=q.outerSticky := by
 exact ⟨rfl,rfl⟩
theorem childMergeBeforePop (q : State) (h : Safe q) (g : popNestedGuard q) (e : q.eventSeen=1) : (popNestedNext q).outerSticky=1 := by
 unfold Safe at h
 simp only [popNestedGuard] at g
 dsimp only [popNestedNext]
 grind
end TclRefusal
