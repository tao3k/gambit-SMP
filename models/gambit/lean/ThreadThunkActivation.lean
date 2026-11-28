/- Conditional abstract ownership laws; not C/source simulation or a full Quint refinement. -/
namespace GambitSMP.ThreadThunkActivation
structure Custody where
  source : Bool
  descriptor : Bool
  activation : Bool
  needed : Bool
  deriving DecidableEq
def Covered (s : Custody) := s.needed=true → s.source=true ∨ s.descriptor=true ∨ s.activation=true
def register (s : Custody) := {s with descriptor:=true}
def accept (s : Custody) := {s with activation:=true}
def ack (s : Custody) := {s with source:=false,descriptor:=false}
theorem registerCovers (s : Custody) : Covered (register s) := by simp [Covered,register]
theorem acceptanceCovers (s : Custody) : Covered (accept s) := by simp [Covered,accept]
theorem ackRequiresAccepted (s : Custody) (h : s.activation=true) : Covered (ack s) := by simp [Covered,ack,h]
theorem noCoverageRejected (s : Custody) (n : s.needed=true) (a : s.source=false) (b : s.descriptor=false) (c : s.activation=false) : ¬ Covered s := by simp [Covered,n,a,b,c]
structure Reload where
  raw : Bool
  epoch : Nat
  loaded : Nat
  context : Bool
  synchronized : Bool
  deriving DecidableEq
def Fresh (s : Reload) := s.raw=true → s.loaded=s.epoch ∧ s.context=true ∧ s.synchronized=true
def move (s : Reload) := {s with epoch:=s.epoch+1,context:=false}
def reload (s : Reload) := {s with raw:=true,loaded:=s.epoch}
theorem stoppedMovePreserves (s : Reload) (h : s.raw=false) : Fresh (move s) := by simp [Fresh,move,h]
theorem reloadRequiresContext (s : Reload) (c : s.context=true) (b : s.synchronized=true) : Fresh (reload s) := by simp [Fresh,reload,c,b]
theorem cachedRawCannotMove (s : Reload) (r : s.raw=true) : ¬ Fresh (move s) := by simp [Fresh,move,r]
structure Spawn where
  unknown : Bool
  descriptor : Bool
  childMayExist : Bool
  storageFreed : Bool
  deriving DecidableEq
def SpawnSafe (s : Spawn) := (s.unknown=true → s.descriptor=true) ∧ (s.childMayExist=true → s.storageFreed=false)
theorem unknownRetainsDescriptor (s : Spawn) (h : SpawnSafe s) (u : s.unknown=true) : s.descriptor=true := h.1 u
theorem childPreventsRollback (s : Spawn) (h : SpawnSafe s) (c : s.childMayExist=true) : s.storageFreed=false := h.2 c
structure Exit where
  restored : Bool
  claimed : Bool
  unknown : Bool
  root : Bool
  marker : Nat
  clears : Nat
  drops : Nat
  returned : Bool
  deriving DecidableEq
def ExitSafe (s : Exit) := s.clears≤1 ∧ s.drops≤s.clears ∧ (s.unknown=true → s.root=true) ∧
 (s.returned=true → s.restored=true ∧ s.claimed=true ∧ s.unknown=false ∧ s.root=false ∧ (s.marker=0 ∨ s.marker=3))
theorem decrementAtMostOnce (s : Exit) (h : ExitSafe s) : s.drops≤1 := by have a:=h.1; have b:=h.2.1; omega
theorem unknownExitRetainsRoot (s : Exit) (h : ExitSafe s) (u : s.unknown=true) : s.root=true := h.2.2.1 u
theorem returnRequiresRestored (s : Exit) (h : ExitSafe s) (r : s.returned=true) : s.restored=true := (h.2.2.2 r).1
def duplicateBytes (workers word : Nat) := workers*word
def sharedBytes (word : Nat) := word
theorem eightWorkerSlotBound : duplicateBytes 8 8 - sharedBytes 8=56 := by decide
theorem supportThreshold (workers word support : Nat) (h : support+word < workers*word) : sharedBytes word + support < duplicateBytes workers word := by simp [sharedBytes,duplicateBytes]; omega
end GambitSMP.ThreadThunkActivation
