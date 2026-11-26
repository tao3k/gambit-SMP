/-
  ReleaseCohortAlgebra.lean
  Family 12 (12/12: release) standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. Same-source 12/12 conjunction soundness: whole-runtime admission holds iff all
       12 equal-weight families bind the exact same source tree and profile, with
       zero active same-source vetoes and peak RSS strictly below 8 GiB.
    2. Impossibility of cross-source splicing: if Family i binds tree A and Family j
       binds tree B with A ≠ B, no whole-runtime 12/12 admission is derivable.
    3. Monotone same-source failure veto and hard 8 GiB RSS cap preservation.
-/

namespace ReleaseCohortAlgebra

def maxRssBytes : Nat := 8589934592 -- 8 GiB

structure FamilyVerdict where
  familyId    : Nat
  sourceTree  : Nat
  profileId   : Nat
  passed      : Bool
  vetoActive  : Bool
  peakRss     : Nat
  deriving DecidableEq, Repr

structure PairedCohort where
  baselineProfile   : Nat
  candidateProfile  : Nat
  rawCensored       : Nat
  retainedCensored  : Nat
  peakRss           : Nat
  deriving DecidableEq, Repr

def FamilyClosedFor (tree profile : Nat) (v : FamilyVerdict) : Prop :=
  v.sourceTree = tree ∧
  v.profileId = profile ∧
  v.passed = true ∧
  v.vetoActive = false ∧
  v.peakRss < maxRssBytes

def WholeRuntimeAdmitted
    (tree profile : Nat) (verdicts : Nat → FamilyVerdict) (cohort : PairedCohort) : Prop :=
  (∀ f, 1 ≤ f ∧ f ≤ 12 → FamilyClosedFor tree profile (verdicts f)) ∧
  cohort.baselineProfile = profile ∧
  cohort.candidateProfile = profile ∧
  cohort.retainedCensored = cohort.rawCensored ∧
  cohort.peakRss < maxRssBytes

theorem cross_source_splice_impossible
    (tree profile : Nat) (verdicts : Nat → FamilyVerdict) (cohort : PairedCohort)
    (i j : Nat) (hi : 1 ≤ i ∧ i ≤ 12) (hj : 1 ≤ j ∧ j ≤ 12)
    (hDiff : (verdicts i).sourceTree ≠ (verdicts j).sourceTree) :
    ¬ WholeRuntimeAdmitted tree profile verdicts cohort := by
  intro hAdm
  have hVi := (hAdm.1 i hi).1
  have hVj := (hAdm.1 j hj).1
  exact hDiff (hVi.trans hVj.symm)

theorem same_source_veto_blocks_whole_admission
    (tree profile : Nat) (verdicts : Nat → FamilyVerdict) (cohort : PairedCohort)
    (f : Nat) (hf : 1 ≤ f ∧ f ≤ 12)
    (hVeto : (verdicts f).vetoActive = true) :
    ¬ WholeRuntimeAdmitted tree profile verdicts cohort := by
  intro hAdm
  have hNoVeto := (hAdm.1 f hf).2.2.2.1
  rw [hVeto] at hNoVeto
  cases hNoVeto

theorem rss_ceiling_exceeded_blocks_admission
    (tree profile : Nat) (verdicts : Nat → FamilyVerdict) (cohort : PairedCohort)
    (f : Nat) (hf : 1 ≤ f ∧ f ≤ 12)
    (hOver : maxRssBytes ≤ (verdicts f).peakRss) :
    ¬ WholeRuntimeAdmitted tree profile verdicts cohort := by
  intro hAdm
  have hLt := (hAdm.1 f hf).2.2.2.2
  omega

theorem dropped_censor_blocks_release_cohort
    (tree profile : Nat) (verdicts : Nat → FamilyVerdict) (cohort : PairedCohort)
    (hDrop : cohort.retainedCensored < cohort.rawCensored) :
    ¬ WholeRuntimeAdmitted tree profile verdicts cohort := by
  intro hAdm
  have hEq := hAdm.2.2.2.1
  omega

theorem unified_same_source_admits_twelve_of_twelve
    (tree profile : Nat) (rss : Nat) (hRss : rss < maxRssBytes) :
    WholeRuntimeAdmitted tree profile
      (fun f => { familyId := f, sourceTree := tree, profileId := profile,
                  passed := true, vetoActive := false, peakRss := rss })
      { baselineProfile := profile, candidateProfile := profile,
        rawCensored := 0, retainedCensored := 0, peakRss := rss } := by
  refine ⟨?_, rfl, rfl, rfl, hRss⟩
  intro f _
  exact ⟨rfl, rfl, rfl, rfl, hRss⟩

end ReleaseCohortAlgebra
