import ChainSealAst
namespace ChainSeal
open ChainSealAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reservePreserves (q : State) (h : Safe q) (g : reserveGuard q) : Safe (reserveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,reserveGuard,reserveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem initializeCopyPreserves (q : State) (h : Safe q) (g : initializeCopyGuard q) : Safe (initializeCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,initializeCopyGuard,initializeCopyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolvePreviousPreserves (q : State) (h : Safe q) (g : resolvePreviousGuard q) : Safe (resolvePreviousNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,resolvePreviousGuard,resolvePreviousNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishInstallPreserves (q : State) (h : Safe q) (g : finishInstallGuard q) : Safe (finishInstallNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,finishInstallGuard,finishInstallNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deferChunkPreserves (q : State) (h : Safe q) (g : deferChunkGuard q) : Safe (deferChunkNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,deferChunkGuard,deferChunkNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishDeferredPreserves (q : State) (h : Safe q) (g : publishDeferredGuard q) : Safe (publishDeferredNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,publishDeferredGuard,publishDeferredNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishPrefixPreserves (q : State) (h : Safe q) (g : publishPrefixGuard q) : Safe (publishPrefixNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,publishPrefixGuard,publishPrefixNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem certifySuffixPreserves (q : State) (h : Safe q) (g : certifySuffixGuard q) : Safe (certifySuffixNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,certifySuffixGuard,certifySuffixNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem terminalPreserves (q : State) (h : Safe q) (g : terminalGuard q) : Safe (terminalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,terminalGuard,terminalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem forwardedPreserves (q : State) (h : Safe q) (g : forwardedGuard q) : Safe (forwardedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,forwardedGuard,forwardedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem capacityFailurePreserves (q : State) (h : Safe q) (g : capacityFailureGuard q) : Safe (capacityFailureNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,capacityFailureGuard,capacityFailureNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retagRootPreserves (q : State) (h : Safe q) (g : retagRootGuard q) : Safe (retagRootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,retagRootGuard,retagRootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem releasePreserves (q : State) (h : Safe q) (g : releaseGuard q) : Safe (releaseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all [Safe,releaseGuard,releaseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13
 · rcases a0 with ⟨g,rfl⟩; exact reservePreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact initializeCopyPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact resolvePreviousPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact finishInstallPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact deferChunkPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact publishDeferredPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact publishPrefixPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact certifySuffixPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact terminalPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact forwardedPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact capacityFailurePreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact retagRootPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact releasePreserves q h g
 · rw [a13]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
-- These theorems quantify all chain lengths in the accounting abstraction.
-- Object/link identity, physical chunk coverage and native source simulation remain premises.
def initialOfLength (n : Nat) : State := {initial with n := Int.ofNat n}
theorem initialOfLengthSafe (n : Nat) : Safe (initialOfLength n) := by
 simp [Safe,initialOfLength,initial]
inductive ReachableAt (n : Nat) : State → Prop where
 | start : ReachableAt n (initialOfLength n)
 | next {q r} : ReachableAt n q → Step q r → ReachableAt n r
theorem arbitraryLengthSafe (n : Nat) (q : State) (h : ReachableAt n q) : Safe q := by
 induction h with
 | start => exact initialOfLengthSafe n
 | next _ st ih => exact stepPreserves _ _ ih st
theorem unresolvedBound (q : State) (h : Safe q) : q.copied - q.sealed ≤ 2 := by
 simp only [Safe] at h; omega
theorem quiescentLinkBound (q : State) (h : Safe q) (hi : q.initialized=false) : q.copied-q.sealed ≤ 1 := by
 simp only [Safe] at h; rcases h with ⟨_,_,_,_,_,_,_,h7,_⟩; have := h7 (by simp [hi]); omega
theorem grantIncludesFrame (grant fs extra header : Int) (hfit : fs+extra+header ≤ grant) : fs+extra ≤ grant-header := by omega
theorem closedChunkBound (threshold maxFrame wordsBefore lastFrame : Int)
 (hb : wordsBefore ≤ threshold) (hf : lastFrame ≤ maxFrame) : wordsBefore+lastFrame ≤ threshold+maxFrame := by omega
end ChainSeal
