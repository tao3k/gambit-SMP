import Std.Tactic
namespace SignalGateMailbox
structure Gate where
 enabled : Bool
 generation : Nat
 count : Nat
 deriving DecidableEq
def entryAllowed (g expected : Gate) (capacity : Nat) := g=expected ∧ g.enabled=true ∧ g.count<capacity
instance (g e : Gate) (c : Nat) : Decidable (entryAllowed g e c) := by unfold entryAllowed; infer_instance
def enterCount (g expected : Gate) (cap : Nat) := if entryAllowed g expected cap then g.count+1 else g.count
theorem failedCasNoPin (g e : Gate) (cap : Nat) (fail : ¬entryAllowed g e cap) : enterCount g e cap=g.count := by simp [enterCount,fail]
theorem fullCountDenied (g e : Gate) (cap : Nat) (full : cap≤g.count) : ¬entryAllowed g e cap := by intro h; have room:=h.2.2; omega
theorem closedDenied (g e : Gate) (cap : Nat) (closed : g.enabled=false) : ¬entryAllowed g e cap := by simp [entryAllowed,closed]
theorem staleSnapshotDenied (g e : Gate) (cap : Nat) (stale : g.generation≠e.generation) : ¬entryAllowed g e cap := by
 intro h; apply stale; exact congrArg Gate.generation h.1
theorem incrementNoCarry (count capacity : Nat) (h : count<capacity) : count+1<capacity+1 := by omega
theorem noGenerationWrap (g maximum : Nat) (h : g=maximum) : ¬g<maximum := by omega
inductive Outcome where
 | acquired | mismatch | closed | full | stale
 deriving DecidableEq
def permitsRoute (o : Outcome) := o=Outcome.acquired
theorem mismatchNotAuthority : ¬permitsRoute .mismatch := by simp [permitsRoute]
theorem fullNotAuthority : ¬permitsRoute .full := by simp [permitsRoute]
structure Mailbox where
 pending : Nat → Prop
 flight : Nat → Prop
 done : Nat → Prop
def covered (m : Mailbox) (i : Nat) := m.pending i ∨ m.flight i ∨ m.done i
def take (m : Mailbox) : Mailbox := ⟨fun _=>False,m.pending,m.done⟩
def finish (m : Mailbox) : Mailbox := ⟨m.pending,fun _=>False,fun i=>m.flight i ∨ m.done i⟩
def publish (m : Mailbox) (i : Nat) : Mailbox := ⟨fun j=>j=i ∨ m.pending j,m.flight,m.done⟩
theorem takePreservesCoverage (m : Mailbox) (i : Nat) (empty : ∀ j, ¬m.flight j) (h : covered m i) : covered (take m) i := by
 rcases h with p | f | d
 · exact Or.inr (Or.inl p)
 · exact False.elim (empty i f)
 · exact Or.inr (Or.inr d)
theorem finishPreservesCoverage (m : Mailbox) (i : Nat) (h : covered m i) : covered (finish m) i := by
 rcases h with p | f | d
 · exact Or.inl p
 · exact Or.inr (Or.inr (Or.inl f))
 · exact Or.inr (Or.inr (Or.inr d))
theorem publishPreservesCoverage (m : Mailbox) (i j : Nat) (h : covered m j) : covered (publish m i) j := by
 rcases h with p | f | d
 · exact Or.inl (Or.inr p)
 · exact Or.inr (Or.inl f)
 · exact Or.inr (Or.inr d)
theorem concurrentPublishSurvivesFinish (m : Mailbox) (i : Nat) : (finish (publish m i)).pending i := Or.inl rfl
inductive Step : Mailbox → Mailbox → Prop where
 | enqueue (m i) : Step m (publish m i)
 | exchange (m) (empty : ∀ j, ¬m.flight j) : Step m (take m)
 | complete (m) : Step m (finish m)
theorem mailboxStepPreserves (m n : Mailbox) (edge : Step m n) (i : Nat) (h : covered m i) : covered n i := by
 cases edge with
 | enqueue j => exact publishPreservesCoverage m j i h
 | exchange empty => exact takePreservesCoverage m i empty h
 | complete => exact finishPreservesCoverage m i h
def admissibleReason (processScope coalescible nativePayload policyInvariant : Bool) := processScope=true ∧ coalescible=true ∧ nativePayload=true ∧ policyInvariant=true
theorem vmSpecificNotReason (c n p : Bool) : ¬admissibleReason false c n p := by simp [admissibleReason]
theorem policyChangeNotAdmitted (s c n : Bool) : ¬admissibleReason s c n false := by simp [admissibleReason]
def bindingAllowed (vmLive lease known policy : Bool) := vmLive=true ∧ lease=true ∧ known=true ∧ policy=true
theorem retiredVmNotTarget (l k p : Bool) : ¬bindingAllowed false l k p := by simp [bindingAllowed]
theorem unknownLeaseNotCommit (v l p : Bool) : ¬bindingAllowed v l false p := by simp [bindingAllowed]
theorem noPolicyNotCommit (v l k : Bool) : ¬bindingAllowed v l k false := by simp [bindingAllowed]
def canRetire (pins work leases : Nat) := pins=0 ∧ work=0 ∧ leases=0
theorem leaseBlocksRetirement (p w l : Nat) (h : 0<l) : ¬canRetire p w l := by intro a; have z:=a.2.2; omega
def allJoined (members joined : Nat → Prop) := ∀ p, members p → joined p
theorem rosterEveryParticipant (m j : Nat → Prop) (h : allJoined m j) (p : Nat) (member : m p) : j p := h p member
theorem netBenefit (oldWork newWork saved added : Nat) (balance : newWork+saved=oldWork+added) (gain : added<saved) : newWork<oldWork := by omega
end SignalGateMailbox
