import Std.Tactic
namespace MarkerAliasRevocation
structure Counter where
 count : Nat
 drops : Nat
 extra : Nat
def safe (c : Counter) := c.count+c.drops=1+c.extra ∧ c.drops≤1
def initial : Counter := ⟨1,0,0⟩
def addForeign (c : Counter) : Counter := {c with count:=c.count+1,extra:=c.extra+1}
def ownDrop (c : Counter) : Counter := {c with count:=c.count-1,drops:=c.drops+1}
theorem initialSafe : safe initial := by simp [safe,initial]
theorem zeroUnderSingleCredit (c : Counter) (h : safe c) (single : c.extra=0) (zero : c.count=0) : c.drops=1 := by simp only [safe] at h; omega
theorem oneUnderSingleCredit (c : Counter) (h : safe c) (single : c.extra=0) (one : c.count=1) : c.drops=0 := by simp only [safe] at h; omega
theorem dropPreserves (c : Counter) (h : safe c) (single : c.extra=0) (one : c.count=1) : safe (ownDrop c) := by
 simp only [safe,ownDrop] at *; omega
theorem addPreserves (c : Counter) (h : safe c) : safe (addForeign c) := by simp only [safe,addForeign] at *; omega
inductive Edge : Counter → Counter → Prop where
 | own (c) (single : c.extra=0) (one : c.count=1) : Edge c (ownDrop c)
 | foreign (c) : Edge c (addForeign c)
 | query (c) : Edge c c
theorem stepPreserves {c d : Counter} (h : safe c) (e : Edge c d) : safe d := by
 cases e with
 | own single one => exact dropPreserves c h single one
 | foreign => exact addPreserves c h
 | query => exact h
inductive Trace : Counter → Counter → Prop where
 | nil (c) : Trace c c
 | cons {c d e} : Edge c d → Trace d e → Trace c e
theorem historyPreserves {c d : Counter} (h : safe c) (t : Trace c d) : safe d := by
 induction t with
 | nil => exact h
 | cons e t ih => exact ih (stepPreserves h e)
theorem extraCreditDefeatsInference : safe ⟨1,1,1⟩ ∧ ¬((⟨1,1,1⟩ : Counter).drops=0) := by simp [safe]
theorem zeroDoesNotPermitDrop (c : Counter) (zero : c.count=0) : c.count≠1 := by omega
structure Fence where
 closed : Bool
 stopped : Bool
 drained : Bool
 arena : Bool
 gc : Bool
 visible : Bool
 generation : Bool
 root : Bool
def qualified (f : Fence) := f.closed=true ∧ f.stopped=true ∧ f.drained=true ∧ f.arena=true ∧ f.gc=true ∧ f.visible=true ∧ f.generation=true ∧ f.root=true
theorem qualificationNeedsAll (f : Fence) (h : qualified f) : f.arena=true ∧ f.root=true := ⟨h.2.2.2.1,h.2.2.2.2.2.2.2⟩
theorem closingDoesNotDrain : ¬qualified ⟨true,true,false,true,true,true,true,true⟩ := by simp [qualified]
theorem joinDoesNotTransferArena : ¬qualified ⟨true,true,true,false,true,true,true,true⟩ := by simp [qualified]
theorem staleGenerationRejected : ¬qualified ⟨true,true,true,true,true,true,false,true⟩ := by simp [qualified]
structure Keeper where
 root : Bool
 session : Bool
 callerDebt : Bool
def covered (k : Keeper) := k.callerDebt=true → k.root=true ∧ k.session=true
def loseAuditor (k : Keeper) := k
theorem unknownKeepsCustody (k : Keeper) (h : covered k) : covered (loseAuditor k) := h
def retire (k : Keeper) : Keeper := {k with root:=false,session:=false}
theorem retirementNeedsCallerDone (k : Keeper) (done : k.callerDebt=false) : covered (retire k) := by simp [covered,retire,done]
theorem accountingIsNotCallerDone (k : Keeper) (c : Counter) : (k,c).1.callerDebt=k.callerDebt := rfl
def scanAllowed (auditLease : Bool) := auditLease=false
theorem exclusiveAuditExcludesScan : ¬scanAllowed true := by simp [scanAllowed]
theorem leaseLostReplyNotExit (live lease : Bool) (h : live=true ∧ lease=true) : lease≠false := by simp [h.2]
theorem costThreshold (old new saved added : Nat) (balance : new+saved=old+added) (win : added<saved) : new<old := by omega
-- Lease projection: these are typed transition proofs, not the full QNT simulation.
structure Admission where
 epoch : Nat
 stamp : Nat
 writers : Nat
 audit : Bool
 closed : Bool
 revoke : Bool
 raw : Bool
 root : Bool
 session : Bool
def leaseSafe (a : Admission) : Prop :=
 (a.audit=true → a.writers=0 ∧ a.closed=true ∧ a.stamp=a.epoch ∧ a.raw=false) ∧
 (a.revoke=true → a.closed=true) ∧ a.root=true ∧ a.session=true
def close (a : Admission) := {a with closed:=true}
def revokeRequest (a : Admission) := {a with revoke:=true}
def invalidateReceipt (a : Admission) := {a with audit:=false, stamp:=0}
def openNext (a : Admission) := {a with closed:=false,revoke:=false,epoch:=a.epoch+1}
def auditAllowed (a : Admission) := a.audit=true ∧ a.revoke=false ∧ a.stamp=a.epoch
theorem closePreserves (a : Admission) (h : leaseSafe a) : leaseSafe (close a) := by
 rcases h with ⟨ha,hr,hroot,hs⟩
 exact ⟨fun x => ⟨(ha x).1, rfl, (ha x).2.2.1, (ha x).2.2.2⟩,fun _ => rfl,hroot,hs⟩
theorem revokePreserves (a : Admission) (h : leaseSafe a) (hc : a.closed=true) : leaseSafe (revokeRequest a) := by
 exact ⟨h.1,fun _ => hc,h.2.2.1,h.2.2.2⟩
theorem revocationBlocksUse (a : Admission) : ¬auditAllowed (revokeRequest a) := by simp [auditAllowed,revokeRequest]
theorem revokeDoesNotDrain (a : Admission) : (revokeRequest a).audit=a.audit := rfl
theorem revocationNeedsDrain (a : Admission) (h : a.audit=false) : (invalidateReceipt a).audit=false ∧ a.audit=false := ⟨rfl,h⟩
theorem receiptNeedsEpoch (a : Admission) (h : auditAllowed a) : a.stamp=a.epoch := h.2.2
theorem staleEpochFails (a : Admission) (h : a.stamp≠a.epoch) : ¬auditAllowed a := fun good => h good.2.2
theorem exclusiveExcludesWriters (a : Admission) (h : leaseSafe a) (ha : a.audit=true) : a.writers=0 := (h.1 ha).1
theorem rawExcludesAudit (a : Admission) (h : leaseSafe a) (raw : a.raw=true) : a.audit=false := by
 cases ha : a.audit with
 | false => rfl
 | true => have impossible := (h.1 ha).2.2.2; simp [raw] at impossible
theorem invalidatePreserves (a : Admission) (h : leaseSafe a) : leaseSafe (invalidateReceipt a) := by
 exact ⟨by simp [invalidateReceipt],h.2.1,h.2.2.1,h.2.2.2⟩
theorem reopenPreserves (a : Admission) (h : leaseSafe a) (drained : a.audit=false) : leaseSafe (openNext a) := by
 exact ⟨by simp [openNext,drained],by simp [openNext],h.2.2.1,h.2.2.2⟩
inductive LeaseEdge : Admission → Admission → Prop where
 | close (a) : LeaseEdge a (MarkerAliasRevocation.close a)
 | revoke (a) (closed : a.closed=true) : LeaseEdge a (revokeRequest a)
 | invalidate (a) (drained : a.audit=false) : LeaseEdge a (invalidateReceipt a)
 | reopen (a) (drained : a.audit=false) (invalid : a.stamp=0) : LeaseEdge a (openNext a)
theorem leaseStepPreserves {a b : Admission} (h : leaseSafe a) (edge : LeaseEdge a b) : leaseSafe b := by
 cases edge with
 | close => exact closePreserves _ h
 | revoke closed => exact revokePreserves _ h closed
 | invalidate _ => exact invalidatePreserves _ h
 | reopen drained _ => exact reopenPreserves _ h drained
inductive LeaseTrace : Admission → Admission → Prop where
 | nil (a) : LeaseTrace a a
 | cons {a b c} : LeaseEdge a b → LeaseTrace b c → LeaseTrace a c
theorem leaseHistoryPreserves {a b : Admission} (h : leaseSafe a) (t : LeaseTrace a b) : leaseSafe b := by
 induction t with
 | nil => exact h
 | cons edge _ ih => exact ih (leaseStepPreserves h edge)
theorem readAliasDoesNotAddCredit (c : Counter) : (id c).count=c.count := rfl
end MarkerAliasRevocation
