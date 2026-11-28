namespace GambitSMP.RetainedRcScan

-- Parametric root coverage, not a claim that join failure stopped native writers.
theorem retainedEnrollmentCoverage {Slot Domain : Type}
    (live : Slot → Prop) (owner : Slot → Domain)
    (active frozenRetained enrolled : Domain → Prop)
    (census : ∀ r, live r → active (owner r) ∨ frozenRetained (owner r))
    (activeEnroll : ∀ d, active d → enrolled d)
    (retainedEnroll : ∀ d, frozenRetained d → enrolled d) :
    ∀ r, live r → enrolled (owner r) := by
  intro r hr
  rcases census r hr with ha | ht
  · exact activeEnroll _ ha
  · exact retainedEnroll _ ht

structure State where
  readers : Nat
  writer : Bool
  owner : Nat
  revision : Nat
  snapshotOwner : Nat
  snapshotRevision : Nat
  registered : Bool
  alive : Bool
  deriving DecidableEq

def Safe (s : State) : Prop :=
  s.registered = true ∧ s.alive = true ∧
  (s.readers > 0 → s.writer = false ∧ s.snapshotOwner = s.owner ∧
    s.snapshotRevision = s.revision) ∧ (s.writer = true → s.readers = 0)

-- A single GC epoch reader. Parallel workers share this epoch pin; not independent counts.
def pin (s : State) : State := { s with readers := 1, snapshotOwner := s.owner, snapshotRevision := s.revision }
def prepare (s : State) : State := { s with writer := true }
def commit (s : State) : State := { s with writer := false, owner := 0, revision := s.revision + 1 }
def release (s : State) : State := { s with readers := 0 }

theorem pinPreserves (s : State) (h : Safe s) (noWriter : s.writer = false) :
    Safe (pin s) := by
  rcases h with ⟨hr, ha, _, _⟩
  simp [Safe, pin, hr, ha, noWriter]

theorem preparePreserves (s : State) (h : Safe s) (noReaders : s.readers = 0) :
    Safe (prepare s) := by
  rcases h with ⟨hr, ha, _, _⟩
  simp [Safe, prepare, hr, ha, noReaders]

theorem commitPreserves (s : State) (h : Safe s) (ownsWriter : s.writer = true) :
    Safe (commit s) := by
  rcases h with ⟨hr, ha, _, hw⟩
  have hz := hw ownsWriter
  simp [Safe, commit, hr, ha, hz]

theorem releasePreserves (s : State) (h : Safe s) : Safe (release s) := by
  rcases h with ⟨hr, ha, _, _⟩
  simp [Safe, release, hr, ha]

inductive Step : State → State → Prop where
  | pin (s) (idle : s.writer = false) : Step s (pin s)
  | prepare (s) (drained : s.readers = 0) : Step s (prepare s)
  | commit (s) (owned : s.writer = true) : Step s (commit s)
  | release (s) : Step s (release s)

theorem stepPreserves {s t : State} (h : Safe s) (step : Step s t) : Safe t := by
  cases step with
  | pin idle => exact pinPreserves _ h idle
  | prepare drained => exact preparePreserves _ h drained
  | commit owned => exact commitPreserves _ h owned
  | release => exact releasePreserves _ h

inductive Trace : State → State → Prop where
  | refl (s) : Trace s s
  | snoc {s t u} : Trace s t → Step t u → Trace s u

theorem tracePreserves {s t : State} (h : Safe s) (trace : Trace s t) : Safe t := by
  induction trace with
  | refl => exact h
  | snoc _ step ih => exact stepPreserves ih step

theorem pinnedSnapshotStable (s : State) (h : Safe s) (hp : s.readers > 0) :
    s.snapshotOwner = s.owner ∧ s.snapshotRevision = s.revision := by
  exact ⟨(h.2.2.1 hp).2.1, (h.2.2.1 hp).2.2⟩

theorem readerExcludesTransfer (s : State) (h : Safe s) (hp : s.readers > 0) :
    s.writer = false := (h.2.2.1 hp).1

-- RC traversal completion is only one conjunct of the epoch-close obligation.
theorem fullPhaseClosure (pinReleased rcDone stillDone weakDone accountDone : Prop)
    (close : pinReleased → rcDone ∧ stillDone ∧ weakDone ∧ accountDone)
    (released : pinReleased) : stillDone ∧ accountDone :=
  ⟨(close released).2.1, (close released).2.2.2⟩

-- A lost acknowledgement does not roll back an already committed owner.
theorem committedOwnerSurvivesLostAck (s : State) : (commit s).owner = 0 := rfl

#print axioms retainedEnrollmentCoverage
#print axioms stepPreserves
#print axioms tracePreserves
#print axioms pinnedSnapshotStable
#print axioms readerExcludesTransfer
#print axioms fullPhaseClosure
#print axioms committedOwnerSurvivesLostAck

end GambitSMP.RetainedRcScan
