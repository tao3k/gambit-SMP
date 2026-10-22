from pathlib import Path
p=Path('models/build/IncrementalBuild.lean');s=p.read_text();assert s.endswith('end GambitBuild\n')
s=s[:-len('end GambitBuild\n')]+'''-- Logical heap admission specification, not a reader of actual Scheme objects.
-- Actual heap acquisition, scalar validation and consumer identity erasure are open.
structure SchemeAtomView where
  kind : DatumAtomKind
  units : List Int
  identity : Nat
  interned : Bool
  deriving DecidableEq

inductive SchemeNodeView where
  | atom (value : SchemeAtomView)
  | pair (car cdr : Nat)
  | vector (elements : List Nat)
  deriving DecidableEq

def NamedKind (kind : DatumAtomKind) : Prop := kind = .symbol ∨ kind = .keyword

def AtomAdmitted (canonical : DatumAtomKind → List Int → Nat)
    (scalarDomain : DatumAtomKind → List Int → Prop) (a : SchemeAtomView) : Prop :=
  if NamedKind a.kind then a.interned = true ∧ canonical a.kind a.units = a.identity
  else scalarDomain a.kind a.units

mutual
  def SchemeValueAdmission (heap : Nat → SchemeNodeView)
      (canonical : DatumAtomKind → List Int → Nat)
      (scalarDomain : DatumAtomKind → List Int → Prop) (rank : Nat → Nat)
      (id : Nat) : RecursiveDatum → Prop
    | .atom kind units => ∃ a, heap id = .atom a ∧ a.kind = kind ∧
        a.units = units ∧ AtomAdmitted canonical scalarDomain a
    | .pair a d => ∃ x y, heap id = .pair x y ∧ rank x < rank id ∧ rank y < rank id ∧
        SchemeValueAdmission heap canonical scalarDomain rank x a ∧
        SchemeValueAdmission heap canonical scalarDomain rank y d
    | .vector ds => ∃ ids, heap id = .vector ids ∧
        (∀ x ∈ ids, rank x < rank id) ∧
        SchemeSequenceAdmission heap canonical scalarDomain rank ids ds
  def SchemeSequenceAdmission (heap : Nat → SchemeNodeView)
      (canonical : DatumAtomKind → List Int → Nat)
      (scalarDomain : DatumAtomKind → List Int → Prop) (rank : Nat → Nat) :
      List Nat → DatumSequence → Prop
    | [], .nil => True
    | x :: xs, .cons d ds =>
        SchemeValueAdmission heap canonical scalarDomain rank x d ∧
        SchemeSequenceAdmission heap canonical scalarDomain rank xs ds
    | _, _ => False
end

theorem canonicalNameIdentity {canonical : DatumAtomKind → List Int → Nat}
    {scalarDomain : DatumAtomKind → List Int → Prop} {a b : SchemeAtomView}
    (ha : AtomAdmitted canonical scalarDomain a) (hb : AtomAdmitted canonical scalarDomain b)
    (namedA : NamedKind a.kind) (sameKind : a.kind = b.kind) (sameUnits : a.units = b.units) :
    a.identity = b.identity := by
  have namedB : NamedKind b.kind := sameKind ▸ namedA
  have ea := (if_pos namedA ▸ ha).2
  have eb := (if_pos namedB ▸ hb).2
  rw [← ea, ← eb, sameKind, sameUnits]

theorem uninternedNameCollision :
    let a : SchemeAtomView := ⟨.symbol, [97], 1, false⟩
    let b : SchemeAtomView := ⟨.symbol, [97], 2, false⟩
    a.units = b.units ∧ a.identity ≠ b.identity ∧ a ≠ b := by decide

def StableValueCut (reads : List Nat) (before after : Nat → SchemeNodeView) : Prop :=
  ∀ id ∈ reads, before id = after id

theorem changedReachableValueRejects {reads : List Nat}
    {before after : Nat → SchemeNodeView} {id : Nat}
    (observed : id ∈ reads) (changed : before id ≠ after id) :
    ¬ StableValueCut reads before after := by
  exact fun stable => changed (stable id observed)

theorem logicalRelocationPreservesAdmission
    {before after : Nat → SchemeNodeView}
    {canonical : DatumAtomKind → List Int → Nat}
    {scalarDomain : DatumAtomKind → List Int → Prop} {rank : Nat → Nat}
    {id : Nat} {tree : RecursiveDatum}
    (logical : ∀ i, before i = after i)
    (admitted : SchemeValueAdmission before canonical scalarDomain rank id tree) :
    SchemeValueAdmission after canonical scalarDomain rank id tree := by
  have heaps : before = after := funext logical
  rwa [← heaps]

theorem rawAddressCopyCanBecomeStale :
    let oldRoot : Nat := 10
    let updatedRoot : Nat := 20
    let copiedAddress := oldRoot
    copiedAddress ≠ updatedRoot := by decide

theorem directSelfPairRefused {heap : Nat → SchemeNodeView}
    {canonical : DatumAtomKind → List Int → Nat}
    {scalarDomain : DatumAtomKind → List Int → Prop} {rank : Nat → Nat}
    {id other : Nat} (self : heap id = .pair id other) (tree : RecursiveDatum) :
    ¬ SchemeValueAdmission heap canonical scalarDomain rank id tree := by
  intro admitted
  cases tree with
  | atom kind units =>
      obtain ⟨a,at,_,_,_⟩ := admitted
      rw [self] at at
      cases at
  | pair a d =>
      obtain ⟨x,y,at,lower,_,_,_⟩ := admitted
      rw [self] at at
      have same : id = x := (SchemeNodeView.pair.inj at).1
      rw [← same] at lower
      exact (Nat.lt_irrefl _) lower
  | vector ds =>
      obtain ⟨ids,at,_,_⟩ := admitted
      rw [self] at at
      cases at

def RootCutCovered (reads scanned : List Nat) : Prop :=
  ∀ id ∈ reads, id ∈ scanned

theorem admissionNeedsRootCoverage {reads scanned : List Nat} {issued : Prop}
    {id : Nat} (issuer : issued → RootCutCovered reads scanned)
    (used : id ∈ reads) (missing : id ∉ scanned) : ¬ issued := by
  exact fun receipt => missing (issuer receipt id used)

-- This bridge is result-observation-specific. Actual readback and consumer
-- factorization are hypotheses; physical identity and external effects need more.
theorem schemeReadbackConsumerReflection {Actual Result : Type}
    (tree : Actual → RecursiveDatum) (consume : Actual → Result)
    (kernel : RecursiveDatum → Result)
    (factors : ∀ x, consume x = kernel (tree x)) {old readback : Actual}
    (sameWire : encodeRecursiveDatum (tree old) = encodeRecursiveDatum (tree readback)) :
    consume old = consume readback := by
  have trees := recursiveEncodingInjective sameWire
  rw [factors old, factors readback, trees]

end GambitBuild
''';p.write_text(s)
p=Path('models/build/incremental_build.qnt');s=p.read_text()+'''
// Qualification/relocation abstraction only; no Scheme adapter or RC registry.
module gsc_value_admission {
  type View = { contentEpoch: int, observedEpoch: int, owner: int,
    registeredOwner: int, scannedOwner: int, rootCovered: bool, active: bool,
    rootAddress: int, rawAddress: int, scalarDomain: bool, symbolIdentity: bool,
    finiteRank: bool, sharingErasure: bool, readback: bool, consumer: bool }
  pure def valueStable(v: View): bool = v.contentEpoch == v.observedEpoch
  pure def rootEligible(v: View): bool = all { v.active, v.rootCovered,
    v.owner == v.registeredOwner, v.owner == v.scannedOwner }
  pure def valueEligible(v: View): bool = all { valueStable(v), rootEligible(v),
    v.scalarDomain, v.symbolIdentity, v.finiteRank, v.sharingErasure, v.readback, v.consumer }
  pure def mutate(v: View): View = { ...v, contentEpoch: v.contentEpoch + 1 }
  pure def relocate(v: View, address: int): View = { ...v, rootAddress: address }
  pure def rawReloadNeeded(v: View): bool = v.rawAddress != v.rootAddress
  pure def missingRootBlocks(v: View): bool = (not(v.rootCovered)) implies not(valueEligible(v))
  pure def mutationBlocks(v: View): bool = valueStable(v) implies not(valueEligible(mutate(v)))
}
''';p.write_text(s)
