import Std.Tactic
namespace VMArenaCollector
def history (base occupied : Int) := base+occupied
theorem rebasePreserves (base oldOccupancy newOccupancy : Int) :
 history (base+oldOccupancy-newOccupancy) newOccupancy=history base oldOccupancy := by simp [history]
theorem archivePreserves (archive base occupied rest : Int) :
 archive+(base+occupied)+rest=(archive+base+occupied)+rest := by omega
theorem transferNotAllocation (sourceBase targetBase sourceOccupancy targetOccupancy moved : Int) :
 history (sourceBase+moved) (sourceOccupancy-moved)+history (targetBase-moved) (targetOccupancy+moved)=
 history sourceBase sourceOccupancy+history targetBase targetOccupancy := by simp [history]; omega
theorem foldUnfold (base oldOccupancy newOccupancy : Int) :
 (base+oldOccupancy-newOccupancy)+newOccupancy=base+oldOccupancy := by omega
theorem signedBaselineRequired : (0:Int)-18<0 := by decide
theorem deferredOnce (charged deferred : Nat) : (charged+deferred)+0=charged+deferred := by omega
def quiescent (queued inflight : Nat) := queued=0 ∧ inflight=0
theorem emptyQueueInsufficient (inflight : Nat) (h : 0<inflight) : ¬quiescent 0 inflight := by simp [quiescent]; omega
theorem weakWorkBlocksSweep (q : Nat) (h : 0<q) (i : Nat) : ¬quiescent q i := by simp [quiescent]; omega
def complete (arenas swept : Nat → Prop) := ∀ a, arenas a → swept a
theorem sweepCoverage (arenas swept : Nat → Prop) (h : complete arenas swept) (a : Nat) (ha : arenas a) : swept a := h a ha
def included (active retired : Nat → Prop) (a : Nat) := active a ∨ retired a
theorem retiredStillCounted (active retired : Nat → Prop) (a : Nat) (h : retired a) : included active retired a := Or.inr h
def releaseFree (state : Nat) := state=4
theorem unknownRetains : ¬releaseFree 3 := by simp [releaseFree]
theorem chargeQuarantine (reachable quarantine reserve : Nat) : reachable+quarantine+reserve≥quarantine := by omega
theorem censusMustFollowSweep (done required : Nat) (h : done<required) : done≠required := by omega
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end VMArenaCollector
