namespace GambitSMP.RcFreezePublication

structure State where
  initialized : Bool
  published : Bool
  closed : Bool
  knownWriters : Bool
  writers : Nat
  rawBorrows : Nat
  storageLeases : Nat
  generation : Nat
  receiptGeneration : Nat
  deriving DecidableEq

def CanIssue (s : State) : Prop :=
  s.initialized = true ∧ s.published = true ∧ s.closed = true ∧
  s.knownWriters = true ∧ s.writers = 0 ∧ s.rawBorrows = 0

def issue (s : State) : State := { s with receiptGeneration := s.generation }

theorem issueRequiresFinalValues (s : State) (h : CanIssue s) :
    s.writers = 0 ∧ s.rawBorrows = 0 ∧ s.knownWriters = true :=
  ⟨h.2.2.2.2.1, h.2.2.2.2.2, h.2.2.2.1⟩

theorem issueBindsGeneration (s : State) : (issue s).receiptGeneration = s.generation := rfl

theorem storageLeaseDoesNotBlockFreeze (s : State) (h : CanIssue s) (n : Nat) :
    CanIssue { s with storageLeases := n } := h

theorem publicationPrecedesReceipt (s : State) (h : CanIssue s) :
    s.initialized = true ∧ s.published = true := ⟨h.1, h.2.1⟩

-- The collector owns relocation; mutator permission is intentionally not required.
def CollectorMayRelocate (s : State) : Prop := CanIssue s ∧ s.receiptGeneration = s.generation

theorem collectorCanUpdateFrozenRoots (s : State) (h : CanIssue s) :
    CollectorMayRelocate (issue s) := by
  exact ⟨h, rfl⟩

-- Protocol rule: the collector cannot await a task which needs its own pin released.
-- Natural ranks rule out all finite wait cycles only if EVERY real wait edge refines this relation.
inductive WaitEdge : Nat → Nat → Prop where
  | ordered {a b} : a < b → WaitEdge a b

inductive WaitPath : Nat → Nat → Prop where
  | edge {a b} : WaitEdge a b → WaitPath a b
  | snoc {a b c} : WaitPath a b → WaitEdge b c → WaitPath a c

theorem waitPathIncreases {a b : Nat} (p : WaitPath a b) : a < b := by
  induction p with
  | edge h => cases h with | ordered lt => exact lt
  | snoc _ e ih => cases e with | ordered lt => exact Nat.lt_trans ih lt

theorem noRankedWaitCycle {a : Nat} (p : WaitPath a a) : False :=
  Nat.lt_irrefl a (waitPathIncreases p)

#print axioms issueRequiresFinalValues
#print axioms issueBindsGeneration
#print axioms storageLeaseDoesNotBlockFreeze
#print axioms publicationPrecedesReceipt
#print axioms collectorCanUpdateFrozenRoots
#print axioms waitPathIncreases
#print axioms noRankedWaitCycle
end GambitSMP.RcFreezePublication
