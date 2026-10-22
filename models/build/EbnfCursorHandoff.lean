import Std.Tactic

namespace EbnfCursorHandoff

theorem remainderConserved {A : Type} (suffix : List A) (probed : Nat) :
    suffix.take probed ++ suffix.drop probed = suffix := by
  exact List.take_append_drop probed suffix
theorem emptyBufferAgreement {A : Type} (suffix : List A) : ([] : List A) ++ suffix = suffix := rfl

inductive Datum where
  | rawPair
  | quotedPair
  deriving DecidableEq
def rawPairCodes : List Nat := [40, 84, 32, 52, 50, 41, 10]
def selectedDatum (codes : List Nat) : Option Datum :=
  if codes = 39 :: rawPairCodes then some .quotedPair
  else if codes = rawPairCodes then some .rawPair else none
theorem quoteLossDistinct :
    selectedDatum (39 :: rawPairCodes) = some .quotedPair ∧
    selectedDatum rawPairCodes = some .rawPair ∧ Datum.rawPair ≠ Datum.quotedPair := by decide

-- Identical token payloads can come from distinct raw spans/trivia.
def tokenPayload (source : List Nat) : List Nat := source.filter (· != 32)
theorem tokenPayloadNotSource :
    tokenPayload [84] = tokenPayload [32, 84] ∧ ([84] : List Nat) ≠ [32, 84] := by decide
def legacyFreshOff (start : Int) : Int := 0 - start + 0
theorem negativeFreshOff : legacyFreshOff 17 = -17 := by decide

inductive Owner where | source | target
  deriving DecidableEq
def commit (_ : Owner) : Owner := .target
theorem commitRetainsSingleOwner (owner : Owner) : commit owner = .target ∧ commit owner ≠ .source := by
  cases owner <;> decide
theorem workThreshold (required avoided spans owner roots validation : Nat)
    (positive : spans + owner + roots + validation < avoided) :
    required + (spans + owner + roots + validation) < required + avoided :=
  Nat.add_lt_add_left positive required

-- These kernels do not prove a native reader/adapter, span identity,
-- exception equivalence, QNT simulation or a linearizable C ownership protocol.
end EbnfCursorHandoff
