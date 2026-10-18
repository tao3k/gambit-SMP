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

end ResearchFunnel
