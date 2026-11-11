/- Conditional entry/publication/stop laws. No instruction-level Gambit/C or whole-QNT simulation. -/
import Std
namespace GambitSMP.OriginBindCommit
structure State where
  port : Bool
  registered : Bool
  frozen : Bool
  admitted : Bool
  source : Bool
  needed : Bool
  intent : Bool
  owned : Bool
  dataClosed : Bool
  controlClosed : Bool
  dataInFlight : Bool
  controlInFlight : Bool
  fieldA : Bool
  fieldB : Bool
  locator : Bool
  root : Bool
  rootEpoch : Nat
  epoch : Nat
  committed : Bool
  sourceScan : Bool
  terminal : Bool
  resultAck : Bool
  queryPin : Bool
  deriving DecidableEq

def CanAdmit (s : State) := s.port=true ∧ s.registered=true ∧ s.frozen=true ∧ s.source=true
def admit (s : State) : State := {s with admitted:=true}
def AdmissionSafe (s : State) := s.admitted=true → s.port=true ∧ s.registered=true ∧ s.frozen=true
theorem admissionNeedsExistingRootView (s : State) (h : CanAdmit s) : AdmissionSafe (admit s) := by
  simp_all [CanAdmit,AdmissionSafe,admit]
theorem missingPortRejects (s : State) (h : s.port=false) : ¬ CanAdmit s := by simp [CanAdmit,h]
theorem unregisteredHostRejects (s : State) (h : s.registered=false) : ¬ CanAdmit s := by simp [CanAdmit,h]
def Stopped (s : State) := s.dataClosed=true ∧ s.controlClosed=true ∧ s.dataInFlight=false ∧ s.controlInFlight=false
def CanHelp (s : State) := Stopped s ∧ s.intent=true
theorem outstandingControlRejectsHelper (s : State) (h : s.controlInFlight=true) : ¬ CanHelp s := by simp [CanHelp,Stopped,h]
theorem outstandingDataRejectsHelper (s : State) (h : s.dataInFlight=true) : ¬ CanHelp s := by simp [CanHelp,Stopped,h]
theorem dataCloseAloneIsNotEnough (s : State) (h : s.controlClosed=false) : ¬ CanHelp s := by simp [CanHelp,Stopped,h]
theorem controlCloseAloneIsNotEnough (s : State) (h : s.dataClosed=false) : ¬ CanHelp s := by simp [CanHelp,Stopped,h]
-- Repair only idempotent private control metadata, never a collector-updated root value.
def repairA (s : State) : State := {s with fieldA:=true}
def repairB (s : State) : State := {s with fieldB:=true}
def installLocator (s : State) : State := {s with locator:=true}
theorem repairAIdempotent (s : State) : repairA (repairA s)=repairA s := rfl
theorem repairBIdempotent (s : State) : repairB (repairB s)=repairB s := rfl
theorem locatorIdempotent (s : State) : installLocator (installLocator s)=installLocator s := rfl
theorem repairKeepsMovedRoot (s : State) : (repairB (repairA s)).rootEpoch=s.rootEpoch := rfl
def CanCommit (s : State) := s.owned=true ∧ s.fieldA=true ∧ s.fieldB=true ∧ s.locator=true ∧ s.root=true ∧ s.rootEpoch=s.epoch ∧ s.dataInFlight=false ∧ s.controlInFlight=false
def commit (s : State) : State := {s with committed:=true}
def CommittedSafe (s : State) := s.committed=true → s.fieldA=true ∧ s.fieldB=true ∧ s.locator=true ∧ s.root=true ∧ s.rootEpoch=s.epoch
theorem commitNeedsCompleteRootAndMetadata (s : State) (h : CanCommit s) : CommittedSafe (commit s) := by simp_all [CanCommit,CommittedSafe,commit]
theorem missingLocatorRejectsCommit (s : State) (h : s.locator=false) : ¬ CanCommit s := by simp [CanCommit,h]
theorem staleRootRejectsCommit (s : State) (h : s.rootEpoch≠s.epoch) : ¬ CanCommit s := by simp [CanCommit,h]
def PrivateRepairable (s : State) := CanHelp s ∧ s.owned=true
theorem competitorSlotRejectsRepair (s : State) (h : s.owned=false) : ¬ PrivateRepairable s := by simp [PrivateRepairable,h]
def Covered (s : State) := s.needed=true → s.source=true ∨ s.root=true
theorem privateRepairPreservesCoverage (s : State) (h : Covered s) : Covered (repairB (repairA s)) := h
def releaseSource (s : State) := {s with source:=false}
def SourceScanSafe (s : State) := s.sourceScan=true → s.source=true
theorem scannerPreventsSourceRelease (s : State) (h : s.sourceScan=true) : ¬ SourceScanSafe (releaseSource s) := by simp [SourceScanSafe,releaseSource,h]
def CanRecycle (s : State) := Stopped s ∧ s.terminal=true ∧ s.resultAck=true ∧ s.queryPin=false ∧ s.source=false ∧ s.sourceScan=false
theorem unknownResultRetainsJournal (s : State) (h : s.resultAck=false) : ¬ CanRecycle s := by simp [CanRecycle,h]
theorem queryPinRetainsJournal (s : State) (h : s.queryPin=true) : ¬ CanRecycle s := by simp [CanRecycle,h]
theorem sourceScanRetainsJournal (s : State) (h : s.sourceScan=true) : ¬ CanRecycle s := by simp [CanRecycle,h]
def extraBytes (ports journalBytes cells progressBytes : Nat) := ports*journalBytes+cells*progressBytes
theorem boundedJournalNotRetryHistory (ports journalBytes cells progressBytes attempts : Nat) : extraBytes ports journalBytes cells progressBytes+0*attempts=extraBytes ports journalBytes cells progressBytes := by simp
end GambitSMP.OriginBindCommit
