import Std

namespace ResearchFunnel

inductive Kind where
  | model | bootstrap | diagnostic | nativeGate
  deriving DecidableEq

inductive Probe where
  | unknown | failed | passed
  deriving DecidableEq

structure Receipt where
  kind : Kind
  gate : Nat
  source : Nat
  product : Nat
  generation : Nat
  exit : Int
  complete : Bool
  provenanceChecked : Bool

structure State where
  source : Nat
  product : Nat
  generation : Nat
  probe : Probe
  launched : Bool
  receipts : List Receipt

-- The host must establish provenanceChecked from original receipts and bytes.
def Supports (s : State) (r : Receipt) (gate : Nat) : Prop :=
  r.kind = .nativeGate ∧ r.gate = gate ∧ r.source = s.source ∧
  r.product = s.product ∧ r.generation = s.generation ∧ r.exit = 0 ∧
  r.complete = true ∧ r.provenanceChecked = true

def Accepted (s : State) (gate : Nat) : Prop :=
  ∃ r ∈ s.receipts, Supports s r gate

instance (s : State) (r : Receipt) (gate : Nat) : Decidable (Supports s r gate) := by
  unfold Supports
  infer_instance

instance (s : State) (gate : Nat) : Decidable (Accepted s gate) := by
  unfold Accepted
  infer_instance

def acceptedCount (s : State) (gates : List Nat) : Nat :=
  (gates.eraseDups.filter fun gate => decide (Accepted s gate)).length

theorem duplicateGateCannotInflateCount (s : State) (gate : Nat) (rest : List Nat) :
    acceptedCount s (gate :: gate :: rest) = acceptedCount s (gate :: rest) := by
  simp [acceptedCount, List.eraseDups_cons]

def append (s : State) (r : Receipt) : State :=
  { s with receipts := r :: s.receipts }

theorem nonNativeCannotAdvance (s : State) (r : Receipt) (gate : Nat)
    (notNative : r.kind ≠ .nativeGate) :
    Accepted (append s r) gate ↔ Accepted s gate := by
  constructor
  · rintro ⟨w, member, support⟩
    rcases List.mem_cons.mp member with same | prior
    · subst w
      exact False.elim (notNative support.1)
    · exact ⟨w, prior, support⟩
  · rintro ⟨w, member, support⟩
    exact ⟨w, List.mem_cons_of_mem r member, support⟩

theorem nonNativeCannotChangeCount (s : State) (r : Receipt) (gates : List Nat)
    (notNative : r.kind ≠ .nativeGate) :
    acceptedCount (append s r) gates = acceptedCount s gates := by
  simp [acceptedCount, nonNativeCannotAdvance s r _ notNative]

theorem acceptedHasOwnReceipt (s : State) (gate : Nat) (h : Accepted s gate) :
    ∃ r ∈ s.receipts, r.kind = .nativeGate ∧ r.gate = gate ∧
      r.source = s.source ∧ r.product = s.product ∧
      r.generation = s.generation ∧ r.exit = 0 ∧
      r.complete = true ∧ r.provenanceChecked = true := h

def advance (s : State) (source product : Nat) : State :=
  { s with source := source, product := product, generation := s.generation + 1,
           probe := .unknown, launched := false }

theorem advanceRetainsReceipts (s : State) (source product : Nat) :
    (advance s source product).receipts = s.receipts := rfl

theorem staleReceiptCannotSupport (s : State) (r : Receipt) (gate source product : Nat)
    (old : r.generation ≤ s.generation) :
    ¬ Supports (advance s source product) r gate := by
  intro h
  have current := h.2.2.2.2.1
  simp only [advance] at current
  omega

theorem abaCannotRestoreReceipt (s : State) (r : Receipt) (gate otherSource otherProduct : Nat)
    (old : r.generation ≤ s.generation) :
    ¬ Supports (advance (advance s otherSource otherProduct) s.source s.product) r gate := by
  apply staleReceiptCannotSupport
  simp only [advance]
  omega

def launch (s : State) (authorized : Bool) : Option State :=
  if authorized = true ∧ s.probe = .passed then some { s with launched := true } else none

theorem failedProbeCannotLaunch (s : State) (authorized : Bool) (failed : s.probe = .failed) :
    launch s authorized = none := by simp [launch, failed]

theorem missingAuthorizationCannotLaunch (s : State) :
    launch s false = none := by simp [launch]

inductive LaunchObservation where
  | unknown | notStarted | started
  deriving DecidableEq

def UnstartedSupported (observation : LaunchObservation) (closedInventory : Bool) : Prop :=
  observation = .notStarted ∧ closedInventory = true

theorem unknownCannotBecomeUnstarted (closedInventory : Bool) :
    ¬ UnstartedSupported .unknown closedInventory := by simp [UnstartedSupported]

def emptyState : State := ⟨0, 0, 0, .unknown, false, []⟩
def bootstrapReceipt : Receipt := ⟨.bootstrap, 1, 0, 0, 0, 0, true, true⟩

theorem bootstrapCreditCounterexample :
    (append emptyState bootstrapReceipt).receipts.length = 1 ∧
    ¬ Accepted (append emptyState bootstrapReceipt) 1 := by
  simp [append, emptyState, bootstrapReceipt, Accepted, Supports]

theorem sameBoundaryNotSameSignature :
    ("processor-probe", "SIGABRT/tag0").1 = ("processor-probe", "SIGSEGV/unknown").1 ∧
    ("processor-probe", "SIGABRT/tag0").2 ≠ ("processor-probe", "SIGSEGV/unknown").2 := by
  decide

-- Conditional on an early falsifier actually rejecting the candidate.
theorem earlyRejectionAvoidsRemainingCost (early remaining : Nat)
    (positive : 0 < remaining) : early < early + remaining := by omega

-- The runner publishes good+failed counts. Without the split, PASS is unknown.
theorem aggregateCompletionCannotDeterminePasses (n : Nat) (positive : 0 < n) :
    ∃ good₁ failed₁ good₂ failed₂ : Nat,
      good₁ + failed₁ = n ∧ good₂ + failed₂ = n ∧ good₁ ≠ good₂ := by
  exact ⟨n, 0, 0, n, by omega, by omega, by omega⟩

structure ExecutionObservation where
  providerReturned : Bool
  nativePresent : Bool
  completed : Nat

-- Observation updates neither native receipts nor their source/product identity.
def observeExecution (s : State) (_observation : ExecutionObservation) : State := s

theorem executionProjectionCannotAdvance (s : State) (o : ExecutionObservation) (gates : List Nat) :
    acceptedCount (observeExecution s o) gates = acceptedCount s gates := rfl

structure Investigation where
  retained : List Nat
  shown : List Nat

def restoreInvestigation (j : Investigation) : Investigation := { j with shown := j.retained }
def clearReadHint (j : Investigation) : Investigation := { j with shown := [] }

theorem restoreRetainsConclusions (j : Investigation) :
    (restoreInvestigation j).retained = j.retained := rfl

theorem clearHintRetainsConclusions (j : Investigation) :
    (clearReadHint j).retained = j.retained := rfl

-- Conclusions remain separate from the source-bound native receipt inventory.
def restoreWithState (s : State) (j : Investigation) : State × Investigation :=
  (s, restoreInvestigation j)

theorem investigationRestoreCannotGrantNativeCredit (s : State) (j : Investigation) (gates : List Nat) :
    acceptedCount (restoreWithState s j).1 gates = acceptedCount s gates := rfl

structure FailedPrefixPremises where
  allRecorded : Prop
  failed : Prop
  quiescent : Prop
  changed : Prop
  sameGraph : Prop
  budgetsPreserved : Prop

def FreshRetryAllowed (p : FailedPrefixPremises) : Prop :=
  p.allRecorded ∧ p.failed ∧ p.quiescent ∧ p.changed ∧ p.sameGraph ∧ p.budgetsPreserved

theorem freshRetryRequiresQuiescence (p : FailedPrefixPremises) (h : FreshRetryAllowed p) :
    p.quiescent := h.2.2.1

theorem freshRetryPreservesBudgetContract (p : FailedPrefixPremises) (h : FreshRetryAllowed p) :
    p.budgetsPreserved := h.2.2.2.2.2

theorem unchangedFailureCannotRetry (p : FailedPrefixPremises) (h : ¬ p.changed) :
    ¬ FreshRetryAllowed p := fun allowed => h allowed.2.2.2.1

-- A discriminating observation is weaker than a causal/native repair proof.
-- The host owns the authenticated meaning of these identity tokens.
structure MechanismObservation where
  source : Nat
  observedSource : Nat
  product : Nat
  observedProduct : Nat
  hypothesis : Nat
  alternative : Nat
  fixture : Nat
  observedFixture : Nat
  configuration : Nat
  observedConfiguration : Nat
  generation : Nat
  observedGeneration : Nat
  prediction : Nat
  alternativePrediction : Nat
  outcome : Nat
  complete : Bool

def Distinguishes (o : MechanismObservation) : Prop :=
  o.hypothesis ≠ o.alternative ∧ o.prediction ≠ o.alternativePrediction ∧
  o.source = o.observedSource ∧ o.product = o.observedProduct ∧
  o.fixture = o.observedFixture ∧ o.configuration = o.observedConfiguration ∧
  o.generation = o.observedGeneration ∧ o.complete = true ∧
  (o.outcome = o.prediction ∨ o.outcome = o.alternativePrediction)

theorem equalPredictionsCannotDiscriminate (o : MechanismObservation)
    (same : o.prediction = o.alternativePrediction) : ¬ Distinguishes o :=
  fun h => h.2.1 same

theorem staleObservationCannotDiscriminate (o : MechanismObservation)
    (stale : o.generation ≠ o.observedGeneration) : ¬ Distinguishes o :=
  fun h => stale h.2.2.2.2.2.2.1

theorem discriminationStillCannotAdvance (s : State) (r : Receipt) (gate : Nat)
    (_o : MechanismObservation) (_checked : Distinguishes _o)
    (diagnostic : r.kind = .diagnostic) :
    Accepted (append s r) gate ↔ Accepted s gate := by
  apply nonNativeCannotAdvance
  simp [diagnostic]

#print axioms equalPredictionsCannotDiscriminate
#print axioms staleObservationCannotDiscriminate
#print axioms discriminationStillCannotAdvance
#print axioms nonNativeCannotAdvance
#print axioms nonNativeCannotChangeCount
#print axioms duplicateGateCannotInflateCount
#print axioms acceptedHasOwnReceipt
#print axioms advanceRetainsReceipts
#print axioms staleReceiptCannotSupport
#print axioms abaCannotRestoreReceipt
#print axioms failedProbeCannotLaunch
#print axioms missingAuthorizationCannotLaunch
#print axioms unknownCannotBecomeUnstarted
#print axioms bootstrapCreditCounterexample
#print axioms sameBoundaryNotSameSignature
#print axioms earlyRejectionAvoidsRemainingCost
#print axioms aggregateCompletionCannotDeterminePasses
#print axioms executionProjectionCannotAdvance
#print axioms restoreRetainsConclusions
#print axioms clearHintRetainsConclusions
#print axioms investigationRestoreCannotGrantNativeCredit
#print axioms freshRetryRequiresQuiescence
#print axioms freshRetryPreservesBudgetContract
#print axioms unchangedFailureCannotRetry

end ResearchFunnel
