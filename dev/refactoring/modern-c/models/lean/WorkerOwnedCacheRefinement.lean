/-
  WorkerOwnedCacheRefinement.lean
  Axis 1 Refactoring (Defect D-MEM-1): Formal Lean 4 proof that replacing
  unowned file-static collector/section lookup caches with collector-worker-owned
  cache fields preserves exact section resolution under frozen GC epochs and
  guarantees cross-worker and cross-VM non-interference.
-/

structure SectionGeometry where
  id : Nat
  base : Nat
  size : Nat
  deriving DecidableEq

structure WorkerCache where
  vmId : Nat
  cachedSection : Option SectionGeometry
  cachedOffset : Nat
  cachedEpoch : Nat

def inHalf (s : SectionGeometry) (dest half ptr : Nat) : Bool :=
  decide (s.base + dest ≤ ptr ∧ ptr < s.base + dest + half)

def cacheHit (c : WorkerCache) (vm epoch dest half ptr : Nat) : Bool :=
  match c.cachedSection with
  | none => false
  | some s =>
      decide (c.vmId = vm ∧ c.cachedEpoch = epoch ∧ c.cachedOffset = dest) &&
      inHalf s dest half ptr

def ValidCache (pool : Nat → Nat → Option SectionGeometry) (vm epoch : Nat) (c : WorkerCache) : Prop :=
  c.vmId = vm →
  c.cachedEpoch = epoch →
  ∀ s, c.cachedSection = some s →
    ∀ ptr half, inHalf s c.cachedOffset half ptr = true → pool vm ptr = some s

def uncachedLookup (pool : Nat → Nat → Option SectionGeometry) (vm dest half ptr : Nat) :
    Option SectionGeometry :=
  match pool vm ptr with
  | none => none
  | some s => if inHalf s dest half ptr then some s else none

def lookupWithWorkerCache
    (pool : Nat → Nat → Option SectionGeometry)
    (vm epoch dest half ptr : Nat)
    (c : WorkerCache) : Option SectionGeometry × WorkerCache :=
  if cacheHit c vm epoch dest half ptr then
    (c.cachedSection, c)
  else
    match pool vm ptr with
    | none => (none, c)
    | some s =>
        if inHalf s dest half ptr then
          (some s, { vmId := vm, cachedSection := some s, cachedOffset := dest, cachedEpoch := epoch })
        else
          (none, c)

theorem worker_cache_sound
    (pool : Nat → Nat → Option SectionGeometry)
    (vm epoch dest half ptr : Nat)
    (c : WorkerCache)
    (hValid : ValidCache pool vm epoch c) :
    (lookupWithWorkerCache pool vm epoch dest half ptr c).1 = uncachedLookup pool vm dest half ptr := by
  unfold lookupWithWorkerCache uncachedLookup
  split
  · rename_i hHit
    unfold cacheHit at hHit
    cases hs : c.cachedSection with
    | none => simp [hs] at hHit
    | some s =>
      simp [hs, Bool.and_eq_true] at hHit
      obtain ⟨⟨hVm, hEp, hOff⟩, hIn⟩ := hHit
      have hInOff : inHalf s c.cachedOffset half ptr = true := by simpa [hOff] using hIn
      have hPool := hValid hVm hEp s hs ptr half hInOff
      simp [hPool, hIn]
  · cases hPool : pool vm ptr with
    | none => rfl
    | some s =>
      by_cases hIn : inHalf s dest half ptr = true <;> simp [hIn]

theorem worker_cache_preserves_validity
    (pool : Nat → Nat → Option SectionGeometry)
    (vm : Nat)
    (hDisjoint : ∀ p s1, pool vm p = some s1 →
      ∀ q dest half, inHalf s1 dest half q = true → pool vm q = some s1)
    (epoch dest half ptr : Nat)
    (c : WorkerCache)
    (hValid : ValidCache pool vm epoch c) :
    ValidCache pool vm epoch (lookupWithWorkerCache pool vm epoch dest half ptr c).2 := by
  unfold lookupWithWorkerCache
  split
  · exact hValid
  · cases hPool : pool vm ptr with
    | none => exact hValid
    | some s =>
      by_cases hIn : inHalf s dest half ptr = true
      · simp [hIn]
        intro _ _ s' hs' q half' hIn'
        cases hs'
        exact hDisjoint ptr s hPool q dest half' hIn'
      · simp [hIn]
        exact hValid

theorem worker_indexed_noninterference
    (workers : Nat → WorkerCache)
    (w1 w2 : Nat) (hNe : w1 ≠ w2)
    (c1' : WorkerCache) :
    (fun w => if w = w1 then c1' else workers w) w2 = workers w2 := by
  simp [Ne.symm hNe]
