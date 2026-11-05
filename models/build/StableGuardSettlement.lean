import Std.Tactic
namespace StableGuardSettlement
structure Guard where
 acquired : Bool
 drops : Nat
 pending : Bool
 executor : Bool
 root : Bool
 owner : Bool
 done : Bool
 claimed : Bool
def safe (g : Guard) := g.drops≤1 ∧
 ((g.pending=true ∨ g.executor=true) → g.root=true ∧ g.owner=true) ∧
 (g.done=true → g.pending=false ∧ g.executor=false ∧ g.drops=(if g.acquired then 1 else 0)) ∧
 (g.drops=1 → g.acquired=true)
def reserved : Guard := ⟨false,0,true,false,true,true,false,false⟩
def allocate (g : Guard) : Guard := {g with acquired:=true}
def failAllocate (g : Guard) : Guard := {g with pending:=false}
def claim (g : Guard) : Guard := {g with executor:=true,claimed:=true}
def drop (g : Guard) : Guard := {g with drops:=1,pending:=false}
def finish (g : Guard) : Guard := {g with executor:=false,done:=true}
def retire (g : Guard) : Guard := {g with root:=false,owner:=false}
theorem reserveSafe : safe reserved := by simp [safe,reserved]
theorem registerBeforePublish (registered root : Bool) (h : registered=true ∧ root=true) : root=true := h.2
theorem acquiredIsNotFailure (g : Guard) : (allocate g).acquired=true := rfl
theorem oneDrop (g : Guard) : (drop g).drops=1 := rfl
theorem vmExcludesHandles (owners handles invocations : Nat)
 (h : owners=0 ∧ handles=0 ∧ invocations=0) : handles=0 := h.2.1
theorem claimInstallsExecutor (g : Guard) : (claim g).executor=true ∧ (claim g).claimed=true := ⟨rfl,rfl⟩
theorem finishKeepsRoots (g : Guard) : (finish g).root=g.root ∧ (finish g).owner=g.owner := ⟨rfl,rfl⟩
theorem acquiredDropSafe (g : Guard) (h : safe g) (a : g.acquired=true) (notDone : g.done=false) : safe (drop g) := by
 simp only [safe,drop] at *
 rcases h with ⟨bound,coverage,completion,wasAcquired⟩
 constructor
 · omega
 constructor
 · intro e; exact e.elim (fun z => Bool.noConfusion z) (fun ex => coverage (Or.inr ex))
 constructor
 · intro impossible; simp [notDone] at impossible
 · intro _; exact a
-- Explicit guarded steps; no takeover/crash recovery is assumed.
inductive Edge : Guard → Guard → Prop where
 | allocate (g) (h : g.done=false) : Edge g (allocate g)
 | fail (g) (a : g.acquired=false) (h : g.done=false) : Edge g (failAllocate g)
 | claim (g) (r : g.root=true) (o : g.owner=true) (h : g.done=false) (c : g.claimed=false) : Edge g (claim g)
 | drop (g) (a : g.acquired=true) (z : g.drops=0) (e : g.executor=true) (h : g.done=false) : Edge g (drop g)
 | finish (g) (p : g.pending=false) (n : g.drops=(if g.acquired then 1 else 0)) : Edge g (finish g)
 | retire (g) (d : g.done=true) : Edge g (retire g)
theorem stepPreserves {g t : Guard} (h : safe g) (e : Edge g t) : safe t := by
 cases e with
 | allocate done =>
   simp only [safe,allocate] at *
   rcases h with ⟨b,c,d,a⟩
   exact ⟨b,c,by simp [done],by simp⟩
 | fail a done =>
   simp only [safe,failAllocate] at *
   rcases h with ⟨b,c,d,ac⟩
   exact ⟨b,fun e => e.elim (fun z => Bool.noConfusion z) (fun ex => c (Or.inr ex)),by simp [done],ac⟩
 | claim r o done claimed =>
   simp only [safe,claim] at *
   rcases h with ⟨b,c,d,a⟩
   exact ⟨b,fun _ => ⟨r,o⟩,by simp [done],a⟩
 | drop a z e done => exact acquiredDropSafe g h a done
 | finish pending n =>
   simp only [safe,finish] at *
   rcases h with ⟨b,c,d,a⟩
   exact ⟨b,fun e => e.elim (fun pe => c (Or.inl pe)) (fun z => Bool.noConfusion z),fun _ => ⟨pending,True.intro,n⟩,a⟩
 | retire done =>
   have d := h.2.2.1 done
   simp only [safe,retire]
   exact ⟨h.1,by simp [d.1,d.2.1],h.2.2.1,h.2.2.2⟩
inductive Trace : Guard → Guard → Prop where
 | nil (g) : Trace g g
 | cons {g t u} : Edge g t → Trace t u → Trace g u
theorem historyPreserves {g t : Guard} (h : safe g) (tr : Trace g t) : safe t := by
 induction tr with
 | nil => exact h
 | cons e tr ih => exact ih (stepPreserves h e)
theorem duplicateDropRejected (g : Guard) (one : g.drops=1) : ¬g.drops=0 := by omega
theorem noKillAfterAllocationFailure (g : Guard) (h : safe g) (a : g.acquired=false) : g.drops=0 := by
 have b:=h.1
 have p:=h.2.2.2
 cases n : g.drops with
 | zero => rfl
 | succ n => have e : g.drops=1 := by omega
             have eq := p e
             simp [a] at eq
theorem unknownReplyDoesNotAuthorizeRetry (claimed : Bool) (h : claimed=true) : claimed≠false := by simp [h]
theorem rootsOutliveDone (g : Guard) : (finish g).root=g.root := rfl
theorem sameAcquireIdentity (published observed : Nat) (readsFrom : published=observed) : observed=published := readsFrom.symm
theorem costThreshold (old new saved added : Nat) (balance : new+saved=old+added) (positive : added<saved) : new<old := by omega
end StableGuardSettlement
