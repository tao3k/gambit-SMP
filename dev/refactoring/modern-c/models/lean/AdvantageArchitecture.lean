import Std
namespace AdvantageArchitecture
-- Typed abstract laws. No theorem below claims Scheme/C observational simulation.
structure Cohort where
 frame : Nat
 code : Nat
 moduleAbi : Nat
def compatible (c : Cohort) := c.frame=c.code ∧ c.code=c.moduleAbi
def bind (abi : Nat) : Cohort := ⟨abi,abi,abi⟩
theorem bindCompatible (abi : Nat) : compatible (bind abi) := ⟨rfl,rfl⟩
theorem moduleMismatchRejected (a b : Nat) (h : a≠b) : ¬compatible ⟨a,b,b⟩ := fun hc => h hc.1
structure Plan where
 semantic : Nat
 source : Nat
 closed : Bool
 sealed : Bool
def reusable (p : Plan) (sem src : Nat) := p.semantic=sem ∧ p.source=src ∧ p.closed=true ∧ p.sealed=true
theorem sealNeedsSnapshot (p : Plan) (sem src : Nat) (h : reusable p sem src) : p.closed=true ∧ p.sealed=true := h.2.2
theorem backendDoesNotChangePlan (p : Plan) (sem src oldTool newTool : Nat) (h : reusable p sem src) : reusable p sem src ∧ (p,newTool).1=(p,oldTool).1 := ⟨h,rfl⟩
theorem semanticChangeRejects (p : Plan) (sem src : Nat) (h : reusable p sem src) : ¬reusable p (sem+1) src := by
 intro bad; have h1:=h.1; have h2:=bad.1; omega
theorem sourceChangeRejects (p : Plan) (sem src : Nat) (h : reusable p sem src) : ¬reusable p sem (src+1) := by
 intro bad; have h1:=h.2.1; have h2:=bad.2.1; omega
structure Snapshot where
 identity : Nat
 captured : Bool
 roots : Bool
 shots : Nat
def resume (x : Snapshot) := {x with shots:=x.shots+1}
def captureSafe (x : Snapshot) := x.captured=true → x.roots=true
theorem resumeKeepsIdentity (x : Snapshot) : (resume x).identity=x.identity := rfl
theorem captureRequiresRoot (x : Snapshot) (h : captureSafe x) (c : x.captured=true) : x.roots=true := h c
theorem resumeRemainsCaptured (x : Snapshot) : (resume x).captured=x.captured := rfl
theorem resumePreserves (x : Snapshot) (h : captureSafe x) : captureSafe (resume x) := h
def repeatResume : Nat → Snapshot → Snapshot
 | 0,x => x
 | n+1,x => resume (repeatResume n x)
theorem repeatedResumeSafe (x : Snapshot) (n : Nat) (h : captureSafe x) : captureSafe (repeatResume n x) := by
 induction n with
 | zero => exact h
 | succ n ih => simpa only [repeatResume] using resumePreserves _ ih
theorem repeatedIdentity (x : Snapshot) (n : Nat) : (repeatResume n x).identity=x.identity := by
 induction n with
 | zero => rfl
 | succ n ih => simpa only [repeatResume,resume] using ih
theorem repeatedCapture (x : Snapshot) (n : Nat) : (repeatResume n x).captured=x.captured := by
 induction n with
 | zero => rfl
 | succ n ih => simpa only [repeatResume,resume] using ih
structure Barrier where
 edge : Bool
 remembered : Bool
 reserved : Bool
def covered (b : Barrier) := b.edge=true → b.remembered=true ∨ b.reserved=true
def store (_b : Barrier) : Barrier := ⟨true,true,false⟩
theorem storePreserves (b : Barrier) (_capacity : b.reserved=true) : covered (store b) := by simp [covered,store]
theorem missingBarrierRejected : ¬covered ⟨true,false,false⟩ := by simp [covered]
structure Work where
 queued : Nat
 privateCopy : Nat
 finished : Nat
def debt (w : Work) := w.queued+w.privateCopy
def total (w : Work) := debt w+w.finished
def reserve (w : Work) : Work := {w with privateCopy:=w.privateCopy+1}
def publish (w : Work) : Work := {w with privateCopy:=w.privateCopy-1,queued:=w.queued+1}
theorem copyReservation (w : Work) : debt (reserve w)=debt w+1 := by simp [debt,reserve]; omega
theorem copyPublicationConserves (w : Work) (h : w.privateCopy>0) : total (publish w)=total w := by simp [total,debt,publish]; omega
theorem finishNeedsNoPrivate (w : Work) (h : debt w=0) : w.privateCopy=0 := by simp [debt] at h; omega
-- This projection uses no additional set library.
structure Grant where
 epoch : Nat
 restored : Nat
 runnable : Bool
 roots : Bool
def runnableSafe (g : Grant) := g.runnable=true → g.restored=g.epoch ∧ g.roots=true
def reload (g : Grant) := {g with restored:=g.epoch}
theorem reloadMatches (g : Grant) : (reload g).restored=g.epoch := rfl
def start (g : Grant) := {g with runnable:=true}
theorem startPreserves (g : Grant) (h : g.restored=g.epoch) (r : g.roots=true) : runnableSafe (start g) := fun _ => ⟨h,r⟩
theorem staleReloadRejected : ¬runnableSafe ⟨1,0,true,true⟩ := by simp [runnableSafe]
structure NativeCustody where
 debt : Bool
 root : Bool
 arena : Bool
def custodySafe (n : NativeCustody) := n.debt=true → n.root=true ∧ n.arena=true
def loseReply (n : NativeCustody) := n
theorem unknownRetainsCustody (n : NativeCustody) (h : custodySafe n) : custodySafe (loseReply n) := h
structure Membership where
 closed : Bool
 first : Bool
 second : Bool
def cutReady (m : Membership) := m.closed=true ∧ m.first=true ∧ m.second=true
theorem minorNeedsCompleteCut (m : Membership) (h : cutReady m) : m.first=true ∧ m.second=true := h.2
theorem incompleteCutRejected : ¬cutReady ⟨true,true,false⟩ := by simp [cutReady]
structure Product where
 snap : Snapshot
 barrier : Barrier
 grant : Grant
 native : NativeCustody
def productSafe (p : Product) := captureSafe p.snap ∧ covered p.barrier ∧ runnableSafe p.grant ∧ custodySafe p.native
inductive Step : Product → Product → Prop where
 | resume (p) : Step p {p with snap:=AdvantageArchitecture.resume p.snap}
 | store (p) (reserved : p.barrier.reserved=true) : Step p {p with barrier:=AdvantageArchitecture.store p.barrier}
 | start (p) (same : p.grant.restored=p.grant.epoch) (root : p.grant.roots=true) : Step p {p with grant:=AdvantageArchitecture.start p.grant}
 | lose (p) : Step p {p with native:=loseReply p.native}
theorem stepPreserves {p q : Product} (h : productSafe p) (e : Step p q) : productSafe q := by
 rcases h with ⟨hs,hb,hg,hn⟩
 cases e with
 | resume => exact ⟨resumePreserves _ hs,hb,hg,hn⟩
 | store capacity => exact ⟨hs,storePreserves _ capacity,hg,hn⟩
 | start same root => exact ⟨hs,hb,startPreserves _ same root,hn⟩
 | lose => exact ⟨hs,hb,hg,unknownRetainsCustody _ hn⟩
inductive History : Product → Product → Prop where
 | nil (p) : History p p
 | cons {p q r} : Step p q → History q r → History p r
theorem historyPreserves {p q : Product} (h : productSafe p) (t : History p q) : productSafe q := by
 induction t with
 | nil => exact h
 | cons e _ ih => exact ih (stepPreserves h e)
theorem parallelBranchBound (u b : Nat) : u+b-max u b=min u b := by omega
theorem netBenefit (old new saved added : Nat) (balance : new+saved=old+added) (positive : added<saved) : new<old := by omega
end AdvantageArchitecture
