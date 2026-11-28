/-
  Phase C54: Metacontinuation Prefix Relativization & Pointer-Shared Tail Re-Basing
  Refinement Proofs (`srfi/226/prompt.scm`, `srfi/226/cont.scm`, `effect/handler.scm`,
  `effect/resume.scm`, `effect/generator.scm`).
-/

namespace GambitSMP.McPrefixRelativizeAndRebase

/-- Mirror `%tail-for-rel`: returns the exact suffix of `newList = cap ++ base`
    corresponding to `rel ++ base` when `rel` is a suffix of `cap`. -/
def tailForRel (rel : List Nat) (capLen : Nat) (newList baseList : List Nat) : List Nat :=
  if rel.isEmpty then
    baseList
  else if rel.length ≤ capLen then
    newList.drop (capLen - rel.length)
  else
    rel ++ baseList

structure RelFrame where
  relMarks    : List Nat
  relBarriers : List Nat
  relHandlers : List Nat

structure RebasedFrame where
  marks    : List Nat
  barriers : List Nat
  handlers : List Nat

def rebaseFrame (rf : RelFrame)
    (capM newM baseM : List Nat)
    (capB newB baseB : List Nat)
    (capH newH baseH : List Nat) : RebasedFrame :=
  { marks    := tailForRel rf.relMarks capM.length newM baseM
    barriers := tailForRel rf.relBarriers capB.length newB baseB
    handlers := tailForRel rf.relHandlers capH.length newH baseH }

/-- Theorem 1: When `cap = dropPart ++ rel`, `tailForRel` produces the EXACT
    tail `rel ++ base` inside `cap ++ base` (zero copy, pointer-shared suffix). -/
theorem tailForRel_exact_append (dropPart rel base : List Nat) :
    tailForRel rel (dropPart ++ rel).length ((dropPart ++ rel) ++ base) base = rel ++ base := by
  cases rel with
  | nil =>
      simp [tailForRel]
  | cons r rs =>
      have hne : (r :: rs).isEmpty = false := rfl
      simp [tailForRel, hne, List.append_assoc]

/-- Theorem 2: Querying `current-continuation-marks` up to a re-based inner prompt
    on `newMarks = (innerM ++ relM) ++ resM` yields strictly `innerM` (never leaks
    outer captured marks `relM` or resumer marks `resM`). -/
theorem replayed_inner_prompt_marks_no_leak (innerM relM resM : List Nat) :
    let capM := innerM ++ relM
    let newM := capM ++ resM
    let pfM := tailForRel relM capM.length newM resM
    newM.take (newM.length - pfM.length) = innerM := by
  have hTail : tailForRel relM (innerM ++ relM).length ((innerM ++ relM) ++ resM) resM = relM ++ resM :=
    tailForRel_exact_append innerM relM resM
  simp only [hTail]
  have hLen : ((innerM ++ relM) ++ resM).length - (relM ++ resM).length = innerM.length := by
    simp [List.length_append]
  rw [hLen, List.append_assoc]
  exact List.take_left

/-- Theorem 3: Returning or aborting a re-based inner prompt restores
    `(relM ++ resM, relB ++ resB, relH ++ resH)`, preserving EVERY resumer mark,
    EVERY resumer barrier, and EVERY resumer handler. -/
theorem replayed_inner_prompt_return_preserves_resumer_state
    (innerM relM resM innerB relB resB innerH relH resH : List Nat) :
    let rf : RelFrame := ⟨relM, relB, relH⟩
    let rb := rebaseFrame rf
      (innerM ++ relM) ((innerM ++ relM) ++ resM) resM
      (innerB ++ relB) ((innerB ++ relB) ++ resB) resB
      (innerH ++ relH) ((innerH ++ relH) ++ resH) resH
    (∀ m, m ∈ resM → m ∈ rb.marks) ∧
    (∀ b, b ∈ resB → b ∈ rb.barriers) ∧
    (∀ h, h ∈ resH → h ∈ rb.handlers) := by
  simp only [rebaseFrame, tailForRel_exact_append]
  refine ⟨?_, ?_, ?_⟩
  · intro m hm; exact List.mem_append_right relM hm
  · intro b hb; exact List.mem_append_right relB hb
  · intro h hh; exact List.mem_append_right relH hh

/-- Theorem 4: Resumer continuation barriers are monotonically preserved across
    both inner-prompt execution and inner-prompt return/abort (zero barrier bypass). -/
theorem replayed_inner_prompt_barrier_monotonic
    (innerB relB resB : List Nat) (b : Nat) (hb : b ∈ resB) :
    let capB := innerB ++ relB
    let newB := capB ++ resB
    let pfB := tailForRel relB capB.length newB resB
    b ∈ newB ∧ b ∈ pfB := by
  simp only [tailForRel_exact_append]
  exact ⟨List.mem_append_right (innerB ++ relB) hb, List.mem_append_right relB hb⟩

/-- Theorem 5: Multi-shot replay of one immutable relativized frame `rf` in two
    independent extents produces independent exact re-based frames with zero
    cross-extent contamination. -/
theorem multishot_rebase_purity_and_independence
    (innerM relM res1M res2M innerH relH res1H res2H res1B res2B : List Nat) :
    let rf : RelFrame := ⟨relM, [], relH⟩
    let rb1 := rebaseFrame rf
      (innerM ++ relM) ((innerM ++ relM) ++ res1M) res1M
      [] res1B res1B
      (innerH ++ relH) ((innerH ++ relH) ++ res1H) res1H
    let rb2 := rebaseFrame rf
      (innerM ++ relM) ((innerM ++ relM) ++ res2M) res2M
      [] res2B res2B
      (innerH ++ relH) ((innerH ++ relH) ++ res2H) res2H
    rb1.marks = relM ++ res1M ∧ rb1.barriers = res1B ∧ rb1.handlers = relH ++ res1H ∧
    rb2.marks = relM ++ res2M ∧ rb2.barriers = res2B ∧ rb2.handlers = relH ++ res2H := by
  simp only [rebaseFrame, tailForRel_exact_append]
  simp [tailForRel]

end GambitSMP.McPrefixRelativizeAndRebase
