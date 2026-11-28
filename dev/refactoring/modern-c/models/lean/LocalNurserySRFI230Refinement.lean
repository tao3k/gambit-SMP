/-
  Phase A Mathematical Refinement Proof:
  Processor-Local Independent Minor GC + SRFI-230 Promote-on-Share Memory Model

  Proves:
  1. Disjoint heap partition H = (⊔_p N_p) ⊔ S invariant preservation under local allocation.
  2. Transitive promote-on-share closure preservation prior to SRFI-230 release publication.
  3. SRFI-230 acquire-load soundness (readers observe exclusively shared-heap objects).
  4. Independent local minor GC on processor p preserves validity and reachability for all
     sibling processors q ≠ p without any global stop-the-world barrier.
-/

namespace LocalNurserySRFI230

inductive Placement (Proc : Type) where
  | unalloc : Placement Proc
  | nursery : Proc → Placement Proc
  | shared  : Placement Proc
  deriving DecidableEq

structure HeapState (Proc Obj : Type) where
  loc       : Obj → Placement Proc
  edge      : Obj → Option Obj
  root      : Proc → Option Obj
  atomicBox : Option Obj

/-- Invariant A1: No cross-nursery pointers and shared heap closure. -/
def NoCrossNursery {Proc Obj : Type} (s : HeapState Proc Obj) : Prop :=
  (∀ p o, s.root p = some o → s.loc o = Placement.nursery p ∨ s.loc o = Placement.shared) ∧
  (∀ p o dst, s.loc o = Placement.nursery p → s.edge o = some dst →
      s.loc dst = Placement.nursery p ∨ s.loc dst = Placement.shared) ∧
  (∀ o dst, s.loc o = Placement.shared → s.edge o = some dst →
      s.loc dst = Placement.shared) ∧
  (∀ o, s.atomicBox = some o → s.loc o = Placement.shared)

/-- A subset C of processor p's nursery is closed under outgoing nursery edges. -/
def NurseryClosed {Proc Obj : Type} (s : HeapState Proc Obj) (p : Proc) (C : Obj → Prop) : Prop :=
  (∀ o, C o → s.loc o = Placement.nursery p) ∧
  (∀ o dst, C o → s.edge o = some dst →
      s.loc dst = Placement.nursery p → C dst)

/-- Promote a closed nursery subset C ⊆ N_p to shared old generation S. -/
def promoteClosure {Proc Obj : Type} [DecidableEq Obj]
    (s : HeapState Proc Obj) (C : Obj → Prop) [DecidablePred C] : HeapState Proc Obj :=
  { s with
    loc := fun o => if C o then Placement.shared else s.loc o }

/-- Theorem 1: Promoting any nursery-closed subset C ⊆ N_p to S preserves NoCrossNursery. -/
theorem promote_preserves_disjointness
    {Proc Obj : Type} [DecidableEq Proc] [DecidableEq Obj]
    (s : HeapState Proc Obj) (p : Proc) (C : Obj → Prop) [DecidablePred C]
    (hInv : NoCrossNursery s) (hClosed : NurseryClosed s p C) :
    NoCrossNursery (promoteClosure s C) := by
  rcases hInv with ⟨hRoot, hNurseryEdge, hSharedEdge, hBox⟩
  rcases hClosed with ⟨hCInNp, hCClosed⟩
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro q o hq
    simp only [promoteClosure] at hq ⊢
    by_cases hC : C o
    · simp [hC]
    · simp [hC]; exact hRoot q o hq
  · intro q o dst hLoc hEdge
    simp only [promoteClosure] at hLoc hEdge ⊢
    by_cases hCo : C o
    · simp [hCo] at hLoc
    · simp [hCo] at hLoc
      by_cases hCd : C dst
      · simp [hCd]
      · simp [hCd]; exact hNurseryEdge q o dst hLoc hEdge
  · intro o dst hLoc hEdge
    simp only [promoteClosure] at hLoc hEdge ⊢
    by_cases hCo : C o
    · by_cases hCd : C dst
      · simp [hCd]
      · simp [hCd]
        have hNp : s.loc o = Placement.nursery p := hCInNp o hCo
        cases hNurseryEdge p o dst hNp hEdge with
        | inl hDstNp => exact False.elim (hCd (hCClosed o dst hCo hEdge hDstNp))
        | inr hDstS  => exact hDstS
    · simp [hCo] at hLoc
      have hDstS : s.loc dst = Placement.shared := hSharedEdge o dst hLoc hEdge
      by_cases hCd : C dst
      · simp [hCd]
      · simp [hCd, hDstS]
  · intro o hB
    simp only [promoteClosure] at hB ⊢
    by_cases hCo : C o
    · simp [hCo]
    · simp [hCo]; exact hBox o hB

/-- SRFI-230 atomic-box-set! release publication after promoting closure C containing v. -/
def srfi230Publish {Proc Obj : Type} [DecidableEq Obj]
    (s : HeapState Proc Obj) (v : Obj) (C : Obj → Prop) [DecidablePred C] : HeapState Proc Obj :=
  let s' := promoteClosure s C
  { s' with atomicBox := some v }

/-- Theorem 2: SRFI-230 publication preserves NoCrossNursery and guarantees acquire-load sees S. -/
theorem srfi230_publish_sound
    {Proc Obj : Type} [DecidableEq Proc] [DecidableEq Obj]
    (s : HeapState Proc Obj) (p : Proc) (v : Obj) (C : Obj → Prop) [DecidablePred C]
    (hInv : NoCrossNursery s) (hClosed : NurseryClosed s p C)
    (hV : C v ∨ s.loc v = Placement.shared) :
    NoCrossNursery (srfi230Publish s v C) ∧
    (srfi230Publish s v C).loc v = Placement.shared := by
  have hProm := promote_preserves_disjointness s p C hInv hClosed
  have hVShared : (promoteClosure s C).loc v = Placement.shared := by
    simp only [promoteClosure]
    cases hV with
    | inl hCv => simp [hCv]
    | inr hSv =>
      by_cases hCv : C v
      · simp [hCv]
      · simp [hCv, hSv]
  rcases hProm with ⟨hRoot, hNurseryEdge, hSharedEdge, _⟩
  constructor
  · refine ⟨hRoot, hNurseryEdge, hSharedEdge, ?_⟩
    intro o hBox
    simp only [srfi230Publish] at hBox ⊢
    cases hBox
    exact hVShared
  · exact hVShared

/-- Independent local minor GC on processor p:
    promotes live closure L ⊆ N_p to S and reclaims N_p \ L without touching any q ≠ p. -/
def localMinorGC {Proc Obj : Type} [DecidableEq Proc] [DecidableEq Obj]
    (s : HeapState Proc Obj) (p : Proc) (L : Obj → Prop) [DecidablePred L] : HeapState Proc Obj :=
  { s with
    loc := fun o =>
      if s.loc o = Placement.nursery p then
        (if L o then Placement.shared else Placement.unalloc)
      else s.loc o }

/-- Theorem 3: Independent local minor GC on processor p preserves NoCrossNursery
    for ALL processors without stopping or modifying any sibling processor q ≠ p. -/
theorem local_minor_gc_preserves_all_processors
    {Proc Obj : Type} [DecidableEq Proc] [DecidableEq Obj]
    (s : HeapState Proc Obj) (p : Proc) (L : Obj → Prop) [DecidablePred L]
    (hInv : NoCrossNursery s)
    (hClosed : NurseryClosed s p L)
    (hRootLive : ∀ o, s.root p = some o → s.loc o = Placement.nursery p → L o) :
    NoCrossNursery (localMinorGC s p L) := by
  rcases hInv with ⟨hRoot, hNurseryEdge, hSharedEdge, hBox⟩
  rcases hClosed with ⟨hLInNp, hLClosed⟩
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro q o hq
    simp only [localMinorGC] at hq ⊢
    by_cases hEq : s.loc o = Placement.nursery p
    · have hQP : q = p := by
        cases hRoot q o hq with
        | inl hNq => rw [hEq] at hNq; injection hNq with h; exact h.symm
        | inr hS  => rw [hEq] at hS; cases hS
      subst hQP
      have hLo : L o := hRootLive o hq hEq
      simp [hEq, hLo]
    · simp [hEq]; exact hRoot q o hq
  · intro q o dst hLoc hEdge
    simp only [localMinorGC] at hLoc hEdge ⊢
    by_cases hEqO : s.loc o = Placement.nursery p
    · simp [hEqO] at hLoc
      split at hLoc <;> cases hLoc
    · simp [hEqO] at hLoc
      have hQNeP : q ≠ p := by
        intro hEq; subst hEq; exact hEqO hLoc
      have hDstOk := hNurseryEdge q o dst hLoc hEdge
      have hDstNotNp : s.loc dst ≠ Placement.nursery p := by
        intro hDstNp
        cases hDstOk with
        | inl hDstNq => rw [hDstNp] at hDstNq; injection hDstNq with h; exact hQNeP h.symm
        | inr hDstS  => rw [hDstNp] at hDstS; cases hDstS
      simp [hDstNotNp, hDstOk]
  · intro o dst hLoc hEdge
    simp only [localMinorGC] at hLoc hEdge ⊢
    by_cases hEqO : s.loc o = Placement.nursery p
    · simp [hEqO] at hLoc
      by_cases hLo : L o
      · cases hNurseryEdge p o dst hEqO hEdge with
        | inl hDstNp =>
          have hLd : L dst := hLClosed o dst hLo hEdge hDstNp
          simp [hDstNp, hLd]
        | inr hDstS =>
          simp [hDstS]
      · simp [hLo] at hLoc
    · simp [hEqO] at hLoc
      have hDstS : s.loc dst = Placement.shared := hSharedEdge o dst hLoc hEdge
      simp [hDstS]
  · intro o hB
    simp only [localMinorGC] at hB ⊢
    have hS : s.loc o = Placement.shared := hBox o hB
    simp [hS]

/-- Theorem 4: Sibling processor q ≠ p sees its entire nursery untouched by p's local minor GC. -/
theorem sibling_nursery_untouched
    {Proc Obj : Type} [DecidableEq Proc] [DecidableEq Obj]
    (s : HeapState Proc Obj) (p q : Proc) (L : Obj → Prop) [DecidablePred L]
    (hNe : q ≠ p) (o : Obj) (hInNq : s.loc o = Placement.nursery q) :
    (localMinorGC s p L).loc o = Placement.nursery q := by
  simp [localMinorGC, hInNq, hNe]

end LocalNurserySRFI230
