import Std

namespace NumericCompilerExperiment

-- Abstract observation only; host owns dump bytes, compiler and source identity.
structure Observation where
  exit : Int
  warnings : Bool
  functions : Nat
  requested : Nat
  dumps : List Nat
  source : Nat
  observedSource : Nat
  compiler : Nat
  observedCompiler : Nat

def Exercised (o : Observation) : Prop :=
  o.exit = 0 ∧ o.warnings = false ∧ o.functions > 0 ∧
  o.requested ∈ o.dumps ∧ o.source = o.observedSource ∧ o.compiler = o.observedCompiler

theorem noFunctionCannotExercise (o : Observation) (empty : o.functions = 0) :
    ¬ Exercised o := by
  intro h
  have positive := h.2.2.1
  omega

theorem absentRequestedPassCannotExercise (o : Observation) (absent : o.requested ∉ o.dumps) :
    ¬ Exercised o := fun h => absent h.2.2.2.1

theorem phaseAbsenceCanCoexistWithSuccessfulCompile :
    ∃ o : Observation, o.exit = 0 ∧ ¬ Exercised o := by
  refine ⟨⟨0, false, 1, 1, [], 1, 1, 1, 1⟩, rfl, ?_⟩
  exact absentRequestedPassCannotExercise _ (by simp)

#print axioms noFunctionCannotExercise
#print axioms absentRequestedPassCannotExercise
#print axioms phaseAbsenceCanCoexistWithSuccessfulCompile

-- Host must establish identical predecessor support, as the IR parser checks.
-- Counts describe representation; no timing or points-to cardinality follows.
def sharedJoinOperandUnits (variables incomingEdges : Nat) : Nat :=
  variables * incomingEdges

theorem sharedJoinDoesNotShrinkEdges (variables incomingEdges : Nat)
    (nonempty : 1 ≤ variables) :
    incomingEdges ≤ sharedJoinOperandUnits variables incomingEdges := by
  simpa [sharedJoinOperandUnits] using Nat.mul_le_mul_right incomingEdges nonempty

theorem eightLiveValuesRepeatEdges (incomingEdges : Nat) :
    sharedJoinOperandUnits 8 incomingEdges = 8 * incomingEdges := rfl

#print axioms sharedJoinDoesNotShrinkEdges
#print axioms eightLiveValuesRepeatEdges

structure RecoveredSource where
  expected : String
  observed : String
  expectedBytes : Nat
  bytes : Nat
  exit : Int
  timeout : Bool

def Recovered (r : RecoveredSource) : Prop :=
  r.exit = 0 ∧ r.timeout = false ∧ r.bytes = r.expectedBytes ∧
  r.observed = r.expected ∧ r.bytes > 0

theorem wrongSourceCannotRecover (r : RecoveredSource) (wrong : r.observed ≠ r.expected) :
    ¬ Recovered r := fun h => wrong h.2.2.2.1

structure AliasSolution where
  hasSection : Bool
  closed : Bool
  malformed : Nat
  partialLine : Bool
  memberships : Nat

def SolutionKnown (p : AliasSolution) : Prop :=
  p.hasSection = true ∧ p.closed = true ∧ p.malformed = 0 ∧ p.partialLine = false

theorem unclosedSolutionIsUnknown (p : AliasSolution) (unfinished : p.closed = false) :
    ¬ SolutionKnown p := by
  intro h
  have := h.2.1
  simp [unfinished] at this

#print axioms wrongSourceCannotRecover
#print axioms unclosedSolutionIsUnknown

-- Ordered source indices: host reader/manifest establish this premise.
-- Full numeric/continuation semantics still require actual execution evidence.
def OrderedFormPartition (original : List Nat) (parts : List (List Nat)) : Prop :=
  parts.flatten = original

theorem partitionPreservesFormCount (original : List Nat) (parts : List (List Nat))
    (h : OrderedFormPartition original parts) : parts.flatten.length = original.length :=
  congrArg List.length h

theorem partitionPreservesFormMembership (original : List Nat) (parts : List (List Nat))
    (h : OrderedFormPartition original parts) (index : Nat) :
    index ∈ parts.flatten ↔ index ∈ original := by
  rw [show parts.flatten = original from h]

#print axioms partitionPreservesFormCount
#print axioms partitionPreservesFormMembership
end NumericCompilerExperiment
