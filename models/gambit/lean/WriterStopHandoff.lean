/- Conditional laws; native witnesses and source simulation remain open. -/
namespace GambitSMP.WriterStopHandoff
structure State where
  generation : Nat
  receiptGeneration : Nat
  closing : Bool
  dataClosed : Bool
  controlClosed : Bool
  dataInFlight : Bool
  controlInFlight : Bool
  borrows : Nat
  cleanupDebt : Nat
  readers : Nat
  census : Bool
  exitWitness : Bool
  rootHeld : Bool
  rootEpoch : Nat
  resultAck : Bool
  terminal : Bool
  reclaimed : Bool
  deriving DecidableEq

def DataClosed (s : State) := s.closing=true ∧ s.dataClosed=true ∧ s.dataInFlight=false ∧ s.borrows=0 ∧ s.cleanupDebt=0 ∧ s.census=true ∧ s.exitWitness=true ∧ s.receiptGeneration=s.generation
def ControlClosed (s : State) := s.closing=true ∧ s.controlClosed=true ∧ s.controlInFlight=false ∧ s.cleanupDebt=0 ∧ s.census=true ∧ s.exitWitness=true ∧ s.receiptGeneration=s.generation
def Stopped (s : State) := DataClosed s ∧ ControlClosed s
def CanHandoff (s : State) := Stopped s ∧ s.readers=0
def next (s : State) := {s with generation:=s.generation+1, closing:=false, dataClosed:=false, controlClosed:=false, census:=false, exitWitness:=false}
def repairPrivate (s : State) := s

theorem exitObservationInsufficient (s : State) (h : s.exitWitness=false) : ¬ Stopped s := by simp [Stopped,DataClosed,h]
theorem censusRequired (s : State) (h : s.census=false) : ¬ Stopped s := by simp [Stopped,DataClosed,h]
theorem inFlightDataBlocksSeal (s : State) (h : s.dataInFlight=true) : ¬ DataClosed s := by simp [DataClosed,h]
theorem inFlightControlBlocksSeal (s : State) (h : s.controlInFlight=true) : ¬ ControlClosed s := by simp [ControlClosed,h]
theorem cleanupDebtBlocksSeal (s : State) (h : s.cleanupDebt≠0) : ¬ Stopped s := by simp [Stopped,DataClosed,h]
theorem borrowBlocksSeal (s : State) (h : s.borrows≠0) : ¬ Stopped s := by simp [Stopped,DataClosed,h]
theorem staleGenerationBlocksSeal (s : State) (h : s.receiptGeneration≠s.generation) : ¬ Stopped s := by simp [Stopped,DataClosed,h]
theorem readerBlocksHandoff (s : State) (h : s.readers≠0) : ¬ CanHandoff s := by simp [CanHandoff,h]
theorem handoffRequiresBoth (s : State) (h : CanHandoff s) : DataClosed s ∧ ControlClosed s := h.1
theorem oldSealCannotAuthorizeNewHelper (s : State) : ¬ Stopped (next s) := by simp [Stopped,DataClosed,next]
theorem successorAdvancesIdentity (s : State) : (next s).generation=s.generation+1 := rfl
theorem successorPreservesRoot (s : State) : (next s).rootHeld=s.rootHeld := rfl
theorem successorPreservesMovedRoot (s : State) : (next s).rootEpoch=s.rootEpoch := rfl
theorem repairPreservesRoot (s : State) : (repairPrivate s).rootEpoch=s.rootEpoch := rfl

def CanRelease (s : State) := Stopped s ∧ s.terminal=true ∧ s.resultAck=true ∧ s.readers=0
theorem unknownResultBlocksRelease (s : State) (h : s.resultAck=false) : ¬ CanRelease s := by simp [CanRelease,h]
theorem unknownStopRetainsCustody (s : State) (h : ¬ Stopped s) : ¬ CanRelease s := by simp [CanRelease,h]
def Custody (s : State) := s.reclaimed=false → s.rootHeld=true
theorem nextRetainsCustody (s : State) (h : Custody s) : Custody (next s) := h
theorem repairRetainsCustody (s : State) (h : Custody s) : Custody (repairPrivate s) := h
-- These are total conditional laws only. No theorem turns a catcher/join flag into a real C/OS stop.
def CanEnter (s : State) := s.closing=false
theorem openGateNeeded (s : State) (h : s.closing=true) : ¬ CanEnter s := by simp [CanEnter,h]
end GambitSMP.WriterStopHandoff
