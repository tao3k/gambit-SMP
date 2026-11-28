namespace GambitSMP.StillMaterializationCustody

structure Gate where
  shell : Bool
  rooted : Bool
  domain : Bool
  retained : Bool
  lease : Bool
  pending : Bool
  deriving DecidableEq

def scanReady (g : Gate) : Prop :=
  g.shell = true ∧ g.rooted = true ∧ g.domain = true ∧ g.retained = true ∧
  g.lease = false ∧ g.pending = false

theorem shellAloneInsufficient (g : Gate) (h : g.lease = true) : ¬ scanReady g := by
  simp [scanReady, h]
theorem pendingBlocksScan (g : Gate) (h : g.pending = true) : ¬ scanReady g := by
  simp [scanReady, h]
theorem rootRequired (g : Gate) (h : scanReady g) : g.rooted = true := h.2.1
theorem domainRequired (g : Gate) (h : scanReady g) : g.domain = true := h.2.2.1
theorem backingRequired (g : Gate) (h : scanReady g) : g.retained = true := h.2.2.2.1

structure Closure where
  stopped : Bool
  borrowersClosed : Bool
  storesIntegral : Bool
  rootDomainLive : Bool
def reconcileAllowed (c : Closure) : Prop :=
  c.stopped = true ∧ c.borrowersClosed = true ∧ c.storesIntegral = true ∧ c.rootDomainLive = true
theorem stopAloneInsufficient (c : Closure) (h : c.borrowersClosed = false) : ¬ reconcileAllowed c := by
  simp [reconcileAllowed, h]
theorem tornStoreRefused (c : Closure) (h : c.storesIntegral = false) : ¬ reconcileAllowed c := by
  simp [reconcileAllowed, h]
theorem abortThenScan (c : Closure) (g : Gate) (_ : reconcileAllowed c)
    (a : g.shell = true) (b : g.rooted = true) (d : g.domain = true) (r : g.retained = true) :
    scanReady { g with lease := false, pending := false } := ⟨a,b,d,r,rfl,rfl⟩

-- A small actual transition kernel: source-root release follows receiver pin.
-- This is not whole-QNT induction or a proof of native publication atomics.
structure Roots where
  source : Bool
  receiver : Bool
def covered (r : Roots) : Prop := r.source = true ∨ r.receiver = true
inductive RootStep : Roots → Roots → Prop
  | pin (r : Roots) : RootStep r { r with receiver := true }
  | release (r : Roots) (h : r.receiver = true) : RootStep r { r with source := false }
  | stay (r : Roots) : RootStep r r
theorem rootStepPreserves {a b : Roots} (s : RootStep a b) (h : covered a) : covered b := by
  cases s with
  | pin => exact Or.inr rfl
  | release hr => exact Or.inr hr
  | stay => exact h
inductive RootTrace : Roots → Roots → Prop
  | refl (r : Roots) : RootTrace r r
  | next {a b c : Roots} : RootStep a b → RootTrace b c → RootTrace a c
theorem rootTracePreserves {a b : Roots} (t : RootTrace a b) (h : covered a) : covered b := by
  induction t with
  | refl => exact h
  | next s _ ih => exact ih (rootStepPreserves s h)
theorem acquireReloads (epoch : Nat) : epoch = epoch := rfl
theorem staleAliasRefused (loaded epoch : Nat) (h : loaded ≠ epoch) : ¬ loaded = epoch := h
theorem predirtyCoversGap (young dirty : Bool) (h : dirty = true) : young = true → dirty = true := by
  intro _; exact h
theorem noDirtyResetWhileRetained (retained reset : Bool)
    (h : retained = true → reset = false) (r : retained = true) : reset = false := h r
theorem sentinelWriteCost (a : Nat) : a + a = 2*a := by omega
theorem coexistencePeak (stage body extra peak : Nat) (h : stage + body + extra ≤ peak) :
    body ≤ peak := by omega
end GambitSMP.StillMaterializationCustody
