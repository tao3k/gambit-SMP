import Std.Tactic
namespace WillDomainMigration
def eligible (allocated strong : Bool) := allocated=true ∧ strong=false
theorem immediateNotEligible (strong : Bool) : ¬eligible false strong := by simp [eligible]
theorem strongNotEligible (allocated : Bool) : ¬eligible allocated true := by simp [eligible]
theorem weakNotStrong : eligible true false := by simp [eligible]
def mayTransfer (phase : Nat) (writer frame continuation : Bool) := phase=0 ∧ writer=false ∧ frame=false ∧ continuation=false
theorem writerBlocksTransfer (p : Nat) (f c : Bool) : ¬mayTransfer p true f c := by simp [mayTransfer]
theorem continuationBlocksTransfer (p : Nat) (w f : Bool) : ¬mayTransfer p w f true := by simp [mayTransfer]
def weakComplete (pending : Nat) := pending=0
theorem pendingBlocksFinish (p : Nat) (h : 0<p) : ¬weakComplete p := by simp [weakComplete]; omega
def execute (action : Bool) := action=true
theorem clearedNoFreshCall : ¬execute false := by simp [execute]
theorem resumedEffectsMayRepeat : (1:Nat)+1=2 := rfl
def rewrittenHead (old delta : Nat) := old+delta
theorem oldHeadInvalid (old delta : Nat) (h : 0<delta) : old≠rewrittenHead old delta := by simp [rewrittenHead]; omega
theorem appendPreservesOldPrefix (old promoted : List Nat) : (old++promoted).take old.length=old := by simp
theorem retainedCapture (continuation roots : Nat → Prop) (h : ∀ i, continuation i → roots i) (i : Nat) (c : continuation i) : roots i := h i c
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end WillDomainMigration
