import Std.Tactic
namespace BundleRootPublication
def gcLive (live roots : Nat → Bool) (id : Nat) := live id && roots id
theorem gcKeepsRoot (live roots : Nat → Bool) (id : Nat) (l : live id=true) (r : roots id=true) : gcLive live roots id=true := by simp [gcLive,l,r]
def mayPublish (initialized rooted ready : Bool) := initialized && rooted && ready
theorem initializedBeforePublish (rooted ready : Bool) : mayPublish false rooted ready=false := by simp [mayPublish]
structure Commit where
 bundle : Nat
 receipt : Nat
def commit : Commit := ⟨1,1⟩
theorem receiptCommit : commit.bundle=1 ∧ commit.receipt=1 := by decide
def mayRetire (reader saved : Nat) (old : Nat) := reader≠old ∧ saved≠old
theorem gateBlocksRetire (reader saved old : Nat) (h : reader=old) : ¬mayRetire reader saved old := by simp [mayRetire,h]
def abort (authority _candidate : Nat) := authority
theorem abortKeepsAuthority (authority candidate : Nat) : abort authority candidate=authority := rfl
def resolve (slots : Nat → Nat) (handle : Nat) := slots handle
theorem handleResolution (slots : Nat → Nat) (handle address : Nat) (h : slots handle=address) : resolve slots handle=address := h
-- This requires a separately proved C happens-before relation; a root is not a fence.
def visibilityPremise (initialized releaseObserved acquireExecuted : Bool) := initialized && releaseObserved && acquireExecuted
theorem releaseAcquirePremise (initialized acquireExecuted : Bool) : visibilityPremise initialized false acquireExecuted=false := by simp [visibilityPremise]
def retain (pending saved : Bool) := pending || saved
theorem retainedCustody (pending saved : Bool) (h : pending=true ∨ saved=true) : retain pending saved=true := by rcases h with h|h <;> simp [retain,h]
def afterReplyLoss (c : Commit) := c
theorem noRollback (c : Commit) : (afterReplyLoss c).bundle=c.bundle ∧ (afterReplyLoss c).receipt=c.receipt := by simp [afterReplyLoss]
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end BundleRootPublication
