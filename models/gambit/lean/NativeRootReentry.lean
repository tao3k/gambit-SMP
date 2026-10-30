namespace GambitSMP.NativeRootReentry
def Covered (live described : Nat → Prop) := ∀ r, live r → described r
theorem coverageTransitive (live described scanned : Nat → Prop)
 (a : Covered live described) (b : Covered described scanned) : Covered live scanned := by
 intro r h; exact b r (a r h)
theorem missingRootRejects (live described : Nat → Prop) (r : Nat)
 (present : live r) (missing : ¬ described r) : ¬ Covered live described := by
 intro h; exact missing (h r present)
structure ScanState where
 writerDebt : Nat
 borrowDebt : Nat
 unknownWriter : Bool
 frozen : Bool
 covered : Bool
 nativeOutcomeKnown : Bool
def CanScan (s : ScanState) := s.writerDebt=0 ∧ s.borrowDebt=0 ∧ s.unknownWriter=false ∧ s.frozen=true ∧ s.covered=true
theorem writerDebtRejectsScan (s : ScanState) (h : 0<s.writerDebt) : ¬ CanScan s := by
 intro p; have z:=p.1; omega
theorem borrowDebtRejectsScan (s : ScanState) (h : 0<s.borrowDebt) : ¬ CanScan s := by
 intro p; have z:=p.2.1; omega
theorem unknownWriterRejectsScan (s : ScanState) (h : s.unknownWriter=true) : ¬ CanScan s := by simp [CanScan,h]
theorem rawOutcomeNotScanAuthority (s : ScanState) (k : Bool) :
 CanScan {s with nativeOutcomeKnown:=k} ↔ CanScan s := by rfl
structure Duty where
 activeAcks : Nat
 frozenRoots : Nat
def total (d : Duty) := d.activeAcks+d.frozenRoots
def leave (d : Duty) : Duty := ⟨d.activeAcks-1,d.frozenRoots+1⟩
def join (d : Duty) : Duty := ⟨d.activeAcks+1,d.frozenRoots-1⟩
theorem entryConservesDuties (d : Duty) (h : 0<d.activeAcks) : total (leave d)=total d := by simp [total,leave] <;> omega
theorem reentryConservesDuties (d : Duty) (h : 0<d.frozenRoots) : total (join d)=total d := by simp [total,join] <;> omega
inductive DutyStep : Duty → Duty → Prop
 | leave (d : Duty) (h : 0<d.activeAcks) : DutyStep d (NativeRootReentry.leave d)
 | join (d : Duty) (h : 0<d.frozenRoots) : DutyStep d (NativeRootReentry.join d)
 | stay (d : Duty) : DutyStep d d
theorem dutyStepConserves {a b : Duty} (h : DutyStep a b) : total a=total b := by
 cases h with
 | leave p => exact (entryConservesDuties _ p).symm
 | join p => exact (reentryConservesDuties _ p).symm
 | stay => rfl
inductive DutyTrace : Duty → Duty → Prop
 | nil (d : Duty) : DutyTrace d d
 | cons {a b c : Duty} : DutyStep a b → DutyTrace b c → DutyTrace a c
theorem dutyTraceConserves {a b : Duty} (h : DutyTrace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (dutyStepConserves h).trans ih
structure Reentry where
 epoch : Nat
 completed : Nat
 rootEpoch : Nat
 scanning : Bool
 active : Bool
 binding : Bool
def CanGrant (s : Reentry) := s.completed=s.epoch ∧ s.rootEpoch=s.epoch ∧ s.scanning=false ∧ s.binding=true
def CanStartScan (s : Reentry) := s.active=false
def grant (s : Reentry) : Reentry := {s with active:=true}
theorem scanBlocksGrant (s : Reentry) (h : s.scanning=true) : ¬ CanGrant s := by simp [CanGrant,h]
theorem staleEpochRejectsGrant (s : Reentry) (h : s.completed≠s.epoch) : ¬ CanGrant s := by simp [CanGrant,h]
theorem grantClosesNewScan (s : Reentry) : ¬ CanStartScan (grant s) := by simp [CanStartScan,grant]
def ResumeSafe (localEpoch canonicalEpoch : Nat) := localEpoch=canonicalEpoch
theorem movingRootMustReload (old current : Nat) (h : old≠current) : ¬ ResumeSafe old current := h
theorem reloadRestoresEpoch (current : Nat) : ResumeSafe current current := rfl
structure Callback where
 protectedProc : Bool
 outerPinned : Bool
 depth : Nat
def CallbackSafe (c : Callback) := c.protectedProc=true ∧ (c.depth=2 → c.outerPinned=true)
theorem unrootedCallbackRejects (c : Callback) (h : c.protectedProc=false) : ¬ CallbackSafe c := by simp [CallbackSafe,h]
theorem nestedNeedsOuterPin (c : Callback) (d : c.depth=2) (p : c.outerPinned=false) : ¬ CallbackSafe c := by simp [CallbackSafe,d,p]
theorem freshParentView (parent latest : Nat) (h : parent≤latest) : parent<latest+1 := by omega
theorem oldActivationRejected (expected actual : Nat) (h : expected≠actual) : ¬ expected=actual := h
structure ScanPermit where
 workerId : Nat
 contextId : Nat
 generation : Nat
 expectedGeneration : Nat
 roleGranted : Bool
def PermitValid (p : ScanPermit) := p.generation=p.expectedGeneration ∧ p.roleGranted=true
theorem workerContextDistinctWitness : ∃ p : ScanPermit, PermitValid p ∧ p.workerId≠p.contextId := by
 exact ⟨⟨2,7,1,1,true⟩,⟨rfl,rfl⟩,by decide⟩
def ReclaimView (scanPins returnPins : Nat) := scanPins=0 ∧ returnPins=0
theorem reclaimBlockedByScanner (s r : Nat) (h : 0<s) : ¬ ReclaimView s r := by simp [ReclaimView] <;> omega
theorem rootTaskCountPreserved (n k : Nat) (h : k≤n) : (n-k)+k=n := by omega
end GambitSMP.NativeRootReentry
