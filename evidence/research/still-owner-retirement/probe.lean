import Std.Tactic
namespace GambitSMP.StillOwnerRetirement
structure Isolation where
  nativeOnly : Bool
  rootsRegistered : Bool
  registryIndependent : Bool
  resourcesIndependent : Bool
  rawHeapAlias : Bool
  pendingNativeWrites : Nat
  ownerUnknown : Bool
  deriving DecidableEq

def gcReady (i : Isolation) : Prop := i.nativeOnly=true ∧ i.rootsRegistered=true ∧
  i.registryIndependent=true ∧ i.resourcesIndependent=true ∧ i.rawHeapAlias=false

theorem unknownOwnerDoesNotChangeGate (i : Isolation) :
    gcReady {i with ownerUnknown:=true}=gcReady i := rfl
theorem pendingNativeWritesDoNotChangeGate (i : Isolation) (n : Nat) :
    gcReady {i with pendingNativeWrites:=n}=gcReady i := rfl
theorem isolationRequiresRoots (i : Isolation) (h : gcReady i) : i.rootsRegistered=true := h.2.1
theorem isolationRequiresIndependentResources (i : Isolation) (h : gcReady i) :
    i.resourcesIndependent=true := h.2.2.2.1
theorem isolationRejectsRawAlias (i : Isolation) (raw : i.rawHeapAlias=true) : ¬gcReady i := by
  intro h; simp [gcReady,raw] at h

structure Takeover where
  stopConfirmed : Bool
  allWritersClosed : Bool
  privateUnpublished : Bool
  effectFree : Bool
  inputStable : Bool

def mayTakeover (t : Takeover) : Prop := t.stopConfirmed=true ∧ t.allWritersClosed=true ∧
  t.privateUnpublished=true ∧ t.effectFree=true ∧ t.inputStable=true
theorem stopAloneInsufficient (t : Takeover) (openWriters : t.allWritersClosed=false) : ¬mayTakeover t := by
  simp [mayTakeover,openWriters]
theorem sideEffectsForbidReplay (t : Takeover) (effects : t.effectFree=false) : ¬mayTakeover t := by
  simp [mayTakeover,effects]
theorem noPublishedReplay (t : Takeover) (published : t.privateUnpublished=false) : ¬mayTakeover t := by
  simp [mayTakeover,published]
theorem oldGenerationRevoked (old : Nat) : old≠old+1 := by omega
theorem prefixPreserved (committed pending : Nat) :
    (committed+pending)-pending=committed := by omega

structure Receipt where
  closed : Bool
  acknowledged : Bool
  readers : Nat
  callbacks : Nat
  earlierGap : Bool

def mayRetire (r : Receipt) : Prop := r.closed=true ∧ r.acknowledged=true ∧
  r.readers=0 ∧ r.callbacks=0 ∧ r.earlierGap=false
inductive DrainStep : Receipt → Receipt → Prop where
  | read (r) (hasReader : r.readers>0) : DrainStep r {r with readers:=r.readers-1}
  | callbackToChild (r) (hasCallback : r.callbacks>0) :
      DrainStep r {r with callbacks:=r.callbacks-1,readers:=r.readers+1}
  | close (r) : DrainStep r {r with closed:=true}
-- This finite debt kernel is separate from the QNT initializer/GC state.
inductive DrainTrace : Receipt → Receipt → Prop where
  | refl (r) : DrainTrace r r
  | next {r q t} : DrainTrace r q → DrainStep q t → DrainTrace r t
def debt (r : Receipt) : Nat := r.readers+r.callbacks
theorem drainStepDoesNotIncreaseDebt {r q : Receipt} (step : DrainStep r q) : debt q≤debt r := by
  cases step with
  | read h => dsimp [debt]; omega
  | callbackToChild h => dsimp [debt]; omega
  | close => exact Nat.le_refl _
theorem drainTraceDoesNotIncreaseDebt {r q : Receipt} (trace : DrainTrace r q) : debt q≤debt r := by
  induction trace with
  | refl => exact Nat.le_refl _
  | next _ step ih => exact Nat.le_trans (drainStepDoesNotIncreaseDebt step) ih
theorem closedNeverReopens {r q : Receipt} (step : DrainStep r q) (h : r.closed=true) : q.closed=true := by
  cases step <;> simp_all
theorem childHandoffConservesDebt (r : Receipt) (hasCallback : r.callbacks>0) :
    debt {r with callbacks:=r.callbacks-1,readers:=r.readers+1}=debt r := by
  simp only [debt]; omega
theorem outstandingDebtBlocksRetire (r : Receipt) (d : debt r>0) : ¬mayRetire r := by
  intro h; simp only [mayRetire] at h; simp [debt,h.2.2.1,h.2.2.2.1] at d
theorem childHandoffStillBlocks (r : Receipt) :
    ¬mayRetire {r with callbacks:=r.callbacks-1,readers:=r.readers+1} := by
  simp [mayRetire]
theorem unacknowledgedRetains (r : Receipt) (h : r.acknowledged=false) : ¬mayRetire r := by
  simp [mayRetire,h]
theorem earlierGapBlocksFloor (r : Receipt) (h : r.earlierGap=true) : ¬mayRetire r := by
  simp [mayRetire,h]

def rejectRetired (floor serial : Nat) : Bool := decide (serial≤floor)
theorem retiredRetryRejected (floor serial : Nat) (h : serial≤floor) :
    rejectRetired floor serial=true := by simp [rejectRetired,h]
theorem floorNeverForgets (old next serial : Nat) (monotone : old≤next) (oldRejected : serial≤old) :
    rejectRetired next serial=true := by simp [rejectRetired]; omega

theorem stagingPeakIncludesBoth (stage shell metaBytes : Nat) :
    stage+shell≤stage+shell+metaBytes := by omega
theorem sentinelAddsWrites (fields : Nat) : fields+fields=2*fields := by omega
end GambitSMP.StillOwnerRetirement

#check GambitSMP.StillOwnerRetirement.unknownOwnerDoesNotChangeGate
#print axioms GambitSMP.StillOwnerRetirement.unknownOwnerDoesNotChangeGate

#check GambitSMP.StillOwnerRetirement.pendingNativeWritesDoNotChangeGate
#print axioms GambitSMP.StillOwnerRetirement.pendingNativeWritesDoNotChangeGate

#check GambitSMP.StillOwnerRetirement.isolationRequiresRoots
#print axioms GambitSMP.StillOwnerRetirement.isolationRequiresRoots

#check GambitSMP.StillOwnerRetirement.isolationRequiresIndependentResources
#print axioms GambitSMP.StillOwnerRetirement.isolationRequiresIndependentResources

#check GambitSMP.StillOwnerRetirement.isolationRejectsRawAlias
#print axioms GambitSMP.StillOwnerRetirement.isolationRejectsRawAlias

#check GambitSMP.StillOwnerRetirement.stopAloneInsufficient
#print axioms GambitSMP.StillOwnerRetirement.stopAloneInsufficient

#check GambitSMP.StillOwnerRetirement.sideEffectsForbidReplay
#print axioms GambitSMP.StillOwnerRetirement.sideEffectsForbidReplay

#check GambitSMP.StillOwnerRetirement.noPublishedReplay
#print axioms GambitSMP.StillOwnerRetirement.noPublishedReplay

#check GambitSMP.StillOwnerRetirement.oldGenerationRevoked
#print axioms GambitSMP.StillOwnerRetirement.oldGenerationRevoked

#check GambitSMP.StillOwnerRetirement.prefixPreserved
#print axioms GambitSMP.StillOwnerRetirement.prefixPreserved

#check GambitSMP.StillOwnerRetirement.drainStepDoesNotIncreaseDebt
#print axioms GambitSMP.StillOwnerRetirement.drainStepDoesNotIncreaseDebt

#check GambitSMP.StillOwnerRetirement.drainTraceDoesNotIncreaseDebt
#print axioms GambitSMP.StillOwnerRetirement.drainTraceDoesNotIncreaseDebt

#check GambitSMP.StillOwnerRetirement.closedNeverReopens
#print axioms GambitSMP.StillOwnerRetirement.closedNeverReopens

#check GambitSMP.StillOwnerRetirement.childHandoffConservesDebt
#print axioms GambitSMP.StillOwnerRetirement.childHandoffConservesDebt

#check GambitSMP.StillOwnerRetirement.outstandingDebtBlocksRetire
#print axioms GambitSMP.StillOwnerRetirement.outstandingDebtBlocksRetire

#check GambitSMP.StillOwnerRetirement.childHandoffStillBlocks
#print axioms GambitSMP.StillOwnerRetirement.childHandoffStillBlocks

#check GambitSMP.StillOwnerRetirement.unacknowledgedRetains
#print axioms GambitSMP.StillOwnerRetirement.unacknowledgedRetains

#check GambitSMP.StillOwnerRetirement.earlierGapBlocksFloor
#print axioms GambitSMP.StillOwnerRetirement.earlierGapBlocksFloor

#check GambitSMP.StillOwnerRetirement.retiredRetryRejected
#print axioms GambitSMP.StillOwnerRetirement.retiredRetryRejected

#check GambitSMP.StillOwnerRetirement.floorNeverForgets
#print axioms GambitSMP.StillOwnerRetirement.floorNeverForgets

#check GambitSMP.StillOwnerRetirement.stagingPeakIncludesBoth
#print axioms GambitSMP.StillOwnerRetirement.stagingPeakIncludesBoth

#check GambitSMP.StillOwnerRetirement.sentinelAddsWrites
#print axioms GambitSMP.StillOwnerRetirement.sentinelAddsWrites
