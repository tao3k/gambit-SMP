import Std.Tactic

namespace ReaderSpanCustody

-- Custody moves a pending segment without erasing its contents.
theorem handoffConserves {A : Type} (done pending rest : List A) :
    done ++ (pending ++ rest) = (done ++ pending) ++ rest := by simp
theorem partitionPrefix {A : Type} (xs : List A) (n : Nat) :
    xs.take n ++ xs.drop n = xs := List.take_append_drop n xs

structure Storage where
  original : List Nat
  exposed : List Nat
def mutateCallback (s : Storage) (replacement : List Nat) : Storage :=
  { s with exposed := replacement }
theorem stableSourceSurvivesCallback (s : Storage) (replacement : List Nat) :
    (mutateCallback s replacement).original = s.original := rfl

inductive Route where | original | translated
  deriving DecidableEq
def exceptionRoute (inBody isParseError : Bool) : Route :=
  if inBody && isParseError then .translated else .original
theorem bodyCatchOnly (isParseError : Bool) :
    exceptionRoute false isParseError = .original := by cases isParseError <;> decide

def resumeDomain (current : Nat) (_saved : Nat) : Nat := current
theorem liveResume (current saved : Nat) : resumeDomain current saved = current := rfl
def mayRetire (captures errors aliases pending : Nat) : Prop :=
  captures = 0 ∧ errors = 0 ∧ aliases = 0 ∧ pending = 0
theorem noRetirePending (captures errors aliases pending : Nat)
    (unsettled : pending > 0) : ¬ mayRetire captures errors aliases pending := by
  intro h
  have zero := h.2.2.2
  omega
theorem netBenefit (required avoided storage records adapter roots : Nat)
    (positive : storage + records + adapter + roots < avoided) :
    required + (storage + records + adapter + roots) < required + avoided :=
  Nat.add_lt_add_left positive required

-- The isolation premise requires distinct/protected native storage; this
-- theorem does not prove real Scheme string aliases isolated or callbacks pure.
-- No theorem here proves arbitrary continuation replay, C atomics or GC pinning.
end ReaderSpanCustody
