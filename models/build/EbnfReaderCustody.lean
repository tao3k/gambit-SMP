import Std.Tactic

namespace EbnfReaderCustody

def remaining {A : Type} (buffer port : List A) := buffer ++ port
theorem bufferHead {A : Type} (head : A) (buffer port : List A) :
    remaining (head :: buffer) port = head :: remaining buffer port := rfl
theorem handoffIfEmpty {A : Type} (port : List A) : remaining [] port = port := rfl
theorem bufferLossCounterexample : remaining ([17] : List Nat) [18] ≠ [18] := by decide

structure State where
  heap : Nat
  portOpen : Bool
  root : Bool
  suspended : Bool
  deriving DecidableEq
def resume (s : State) : State := { s with suspended := false }
def exit (s : State) : State := { s with suspended := true }
def reclaimable (s : State) : Prop := s.root = false
theorem resumeRetainsMutation (s : State) : (resume s).heap = s.heap := rfl
theorem exitRetainsPort (s : State) : (exit s).portOpen = s.portOpen := rfl
theorem rootBlocksReclaim (s : State) (live : s.root = true) : ¬ reclaimable s := by
  simp [reclaimable, live]
theorem workThreshold (required avoided owner identity roots validation : Nat)
    (positive : owner + identity + roots + validation < avoided) :
    required + (owner + identity + roots + validation) < required + avoided :=
  Nat.add_lt_add_left positive required

-- Conditional observation/custody kernels only. Not a source interpreter,
-- native closed-port error proof, dynamic-wind simulation or liveness theorem.
end EbnfReaderCustody
