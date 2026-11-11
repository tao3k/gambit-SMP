/- Selective conditional preservation laws within a live VM; not complete Quint/source/C refinement. -/
namespace GambitSMP.BootstrapRootRecovery
structure RootState where
  needValue : Bool
  sourcePin : Bool
  sourceLease : Bool
  root : Bool
  sourceReaders : Bool
  borrow : Bool
  naturalMap : Bool
  newParentPin : Bool
  ackCount : Nat
  deriving DecidableEq
def Covered (s : RootState) := s.needValue=true → s.sourcePin=true ∨ s.root=true
def logicalAck (s : RootState) := {s with sourceLease:=false,ackCount:=s.ackCount+1}
def releaseSource (s : RootState) := {s with sourcePin:=false}
theorem ackPreservesCoverage (s : RootState) (h : Covered s) : Covered (logicalAck s) := h
theorem ackDoesNotEraseSchemeMap (s : RootState) : (logicalAck s).naturalMap=s.naturalMap := rfl
theorem ackDoesNotDropRestoredPin (s : RootState) : (logicalAck s).newParentPin=s.newParentPin := rfl
theorem releaseDoesNotDropRestoredPin (s : RootState) : (releaseSource s).newParentPin=s.newParentPin := rfl
theorem releasedPinNeedsRootOrNoValue (s : RootState) (r : s.root=true ∨ s.needValue=false) : Covered (releaseSource s) := by
  rcases r with hr | hn
  · simp [Covered,releaseSource,hr]
  · simp [Covered,releaseSource,hn]
theorem oneGuardedAck (s : RootState) (h : s.ackCount=0) : (logicalAck s).ackCount=1 := by simp [logicalAck,h]
def PinSafe (s : RootState) := s.sourceReaders=true → s.sourcePin=true
theorem readerPreventsPhysicalRelease (s : RootState) (r : s.sourceReaders=true) : ¬ PinSafe (releaseSource s) := by simp [PinSafe,releaseSource,r]
structure Receipt where
  key : Nat
  descriptor : Nat
  seenRevision : Nat
  canonicalRevision : Nat
  rootEpoch : Nat
  currentEpoch : Nat
  pinned : Bool
  deriving DecidableEq
def AckReceipt (r : Receipt) := r.key=0 ∧ r.descriptor=0 ∧ r.seenRevision=r.canonicalRevision ∧ r.rootEpoch=r.currentEpoch ∧ r.pinned=true
theorem wrongKeyRejected (r : Receipt) (h : r.key≠0) : ¬ AckReceipt r := by simp_all [AckReceipt]
theorem staleRevisionRejected (r : Receipt) (h : r.seenRevision≠r.canonicalRevision) : ¬ AckReceipt r := by simp_all [AckReceipt]
theorem oldValueEpochRejected (r : Receipt) (h : r.rootEpoch≠r.currentEpoch) : ¬ AckReceipt r := by simp_all [AckReceipt]
structure Parent where
  alive : Bool
  generation : Nat
  loadedGeneration : Nat
  epoch : Nat
  loadedEpoch : Nat
  raw : Bool
  escrow : Bool
  entryClosed : Bool
  deriving DecidableEq
def ParentSafe (p : Parent) := (p.raw=true → p.alive=true ∧ p.generation=p.loadedGeneration ∧ p.epoch=p.loadedEpoch) ∧
 (p.alive=false → p.escrow=true ∧ p.entryClosed=true)
def restore (p : Parent) := {p with generation:=p.generation+1,raw:=false}
def exit (p : Parent) := {p with alive:=false,raw:=false,entryClosed:=true}
theorem restoreStopsOldBorrow (p : Parent) (h : ParentSafe p) : ParentSafe (restore p) := by simp_all [ParentSafe,restore]
theorem exitRequiresEscrow (p : Parent) (h : p.escrow=true) : ParentSafe (exit p) := by simp [ParentSafe,exit,h]
theorem deadParentNeedsClosedGate (p : Parent) (h : ParentSafe p) (d : p.alive=false) : p.entryClosed=true := (h.2 d).2
structure KeyCell where
  allocated : Bool
  allocations : Nat
  frontier : Bool
  rootCount : Nat
  deriving DecidableEq
def reserve (k : KeyCell) := if k.frontier then k else if k.allocated then k else {k with allocated:=true,allocations:=k.allocations+1}
theorem reserveDuplicateIdempotent (k : KeyCell) (a : k.allocated=true) : reserve k=k := by simp [reserve,a]
theorem retiredKeyNeverAllocates (k : KeyCell) (f : k.frontier=true) : reserve k=k := by simp [reserve,f]
theorem noRecordBeforeArrivalIsNotTerminal : ∃ k : KeyCell, k.allocated=false ∧ k.frontier=false := ⟨⟨false,0,false,0⟩,by simp⟩
def candidateRootBytes (retries word : Nat) := retries*word
theorem eightRepliesOneCellPayload : candidateRootBytes 8 8 - candidateRootBytes 1 8=56 := by decide
theorem ackKeepsPhysicalPinUntilDrain (s : RootState) : (logicalAck s).sourcePin=s.sourcePin := rfl
end GambitSMP.BootstrapRootRecovery
