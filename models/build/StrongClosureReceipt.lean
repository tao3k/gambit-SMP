import Std.Tactic
namespace StrongClosureReceipt
def covered (debt active : Nat → Prop) (owner : Nat → Nat) := ∀ d, debt d → active (owner d)
theorem zeroActiveCloses (debt active : Nat → Prop) (owner : Nat → Nat) (coverage : covered debt active owner)
 (none : ∀ w, ¬active w) : ∀ d, ¬debt d := by intro d hd; exact none (owner d) (coverage d hd)
theorem openRootRequiresActive (root active : Nat → Prop) (h : ∀ w, root w → active w) (w : Nat) (r : root w) : active w := h w r
theorem idleCannotOwnDebt (debt active : Nat → Prop) (owner : Nat → Nat) (h : covered debt active owner)
 (d : Nat) (n : ¬active (owner d)) : ¬debt d := by intro hd; exact n (h d hd)
theorem custodyAtDequeue (active : Nat → Prop) (target : Nat) (h : active target) : active target := h
def copyComplete (copied required : Nat) := copied=required
theorem forwardNotCompletion : ¬copyComplete 1 2 := by simp [copyComplete]
def mayIssue (zero census epoch : Bool) := zero=true ∧ census=true ∧ epoch=true
theorem incompleteCensusBlocks (zero epoch : Bool) : ¬mayIssue zero false epoch := by simp [mayIssue]
theorem staleBlocks (zero census : Bool) : ¬mayIssue zero census false := by simp [mayIssue]
def callbacksClosed (members returned : Nat → Prop) := ∀ w, members w → returned w
theorem oneReturnNotAll : ¬callbacksClosed (fun w => w=0 ∨ w=1) (fun w => w=0) := by
 intro h; have h1 := h 1 (Or.inr rfl); omega
theorem retirementNeedsPeer (members returned : Nat → Prop) (h : callbacksClosed members returned) (w : Nat) (m : members w) : returned w := h w m
def classifyPermit (receipt weakStarted : Bool) := receipt=true ∧ weakStarted=false
theorem classifyBeforeWeak : classifyPermit true false := by simp [classifyPermit]
theorem weakBlocksLateClassification (receipt : Bool) : ¬classifyPermit receipt true := by simp [classifyPermit]
theorem noExtraCreditForCoveredDebt (active : Nat → Prop) (owner : Nat) (h : active owner) : ∃ w, active w := ⟨owner,h⟩
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end StrongClosureReceipt
