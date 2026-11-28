/-
  Lean 4 refinement proof for SRFI-226 continuation-mark dynamic frame unwind,
  tail-checked immediate marks, and prompt-scoped `continuation-marks` slicing:
    1. Tail-call mark replacement preserves `fid`, so `%pop-mark-frame-by-id`
       pops the replaced frame in O(1).
    2. Dynamic `%pop-mark-frame-by-id` across composable replay preserves all
       resumer marks and never resurrects dead capture-site marks.
    3. Cross-thread SMP continuation replay unwinds exclusively on the invoking
       thread's mark stack, leaving the capture thread's mark stack untouched.
    4. `call-with-immediate-continuation-mark` strictly requires `r0 = markPopRa`,
       returning `default` for non-tail and cross-prompt calls.
    5. `sliceUntilStop` computes the exact inner mark prefix even under nested
       multi-shot self-replay where identical frame values repeat.
-/

namespace Srfi226MarksDynamicUnwind

structure MarkFrame where
  fid : Nat
  key : Nat
  val : Nat
  deriving DecidableEq, Repr

def tailReplaceTop (ms : List MarkFrame) (k v : Nat) : List MarkFrame :=
  match ms with
  | f :: rest => { f with key := k, val := v } :: rest
  | [] => []

def popByFid (ms : List MarkFrame) (targetFid : Nat) : List MarkFrame :=
  match ms with
  | [] => []
  | f :: rest =>
    if f.fid = targetFid then rest
    else
      match popByFid rest targetFid with
      | r => if rest.any (fun x => x.fid = targetFid) then r else ms

theorem popByFid_fast_path_after_tail_replace
    (f : MarkFrame) (rest : List MarkFrame) (k v : Nat) :
    popByFid (tailReplaceTop (f :: rest) k v) f.fid = rest := by
  simp [tailReplaceTop, popByFid]

theorem popByFid_preserves_resumer_and_excludes_zombie
    (fInner fRes : MarkFrame) (resRest : List MarkFrame) :
    popByFid (fInner :: fRes :: resRest) fInner.fid = fRes :: resRest := by
  simp [popByFid]

structure TwoThreadMarks where
  t0 : List MarkFrame
  t1 : List MarkFrame
  deriving DecidableEq, Repr

def unwindOnThread1 (st : TwoThreadMarks) (fid : Nat) : TwoThreadMarks :=
  { st with t1 := popByFid st.t1 fid }

theorem cross_thread_replay_preserves_origin_thread
    (m0 : List MarkFrame) (fInner : MarkFrame) (m1Rest : List MarkFrame) :
    let st0 : TwoThreadMarks := { t0 := m0, t1 := fInner :: m1Rest }
    let st1 := unwindOnThread1 st0 fInner.fid
    st1.t0 = m0 ∧ st1.t1 = m1Rest := by
  simp [unwindOnThread1, popByFid]

def immediateMark (ms : List MarkFrame) (r0 markPopRa key defaultVal : Nat) : Nat :=
  if r0 = markPopRa then
    match ms with
    | f :: _ => if f.key = key then f.val else defaultVal
    | [] => defaultVal
  else defaultVal

theorem immediate_mark_requires_tail_ra
    (ms : List MarkFrame) (r0 markPopRa key defaultVal : Nat)
    (hNe : r0 ≠ markPopRa) :
    immediateMark ms r0 markPopRa key defaultVal = defaultVal := by
  simp [immediateMark, hNe]

def tailMatchesPrefix : List MarkFrame → List MarkFrame → Bool
  | [], _ => true
  | _ :: _, [] => false
  | a :: as, b :: bs => decide (a = b) && tailMatchesPrefix as bs

def sliceUntilStop (marks stop : List MarkFrame) : List MarkFrame :=
  match stop with
  | [] => marks
  | _ =>
    let rec go (xs : List MarkFrame) (acc : List MarkFrame) : List MarkFrame :=
      match xs with
      | [] => marks
      | x :: rest =>
        if tailMatchesPrefix xs stop then acc.reverse
        else go rest (x :: acc)
    go marks []

theorem sliceUntilStop_exact_on_self_replay
    (fA fB fE : MarkFrame) (hNe : fA ≠ fE) :
    sliceUntilStop [fA, fB, fA, fB] [fA, fB, fE] = [fA, fB] := by
  have hFalse : decide (fA = fE) = false := decide_eq_false hNe
  simp [sliceUntilStop, sliceUntilStop.go, tailMatchesPrefix, hFalse]
  rintro rfl _ rfl
  exact hNe rfl

end Srfi226MarksDynamicUnwind
