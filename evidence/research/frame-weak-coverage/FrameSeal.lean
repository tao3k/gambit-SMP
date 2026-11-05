import FrameSealAst
namespace FrameSeal
open FrameSealAst
set_option maxHeartbeats 4000000
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem rollInitialPreserves (q : State) (h : Safe q) (g : rollInitialGuard q) : Safe (rollInitialNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,rollInitialGuard,rollInitialNext] <;> omega
 · simp_all [Safe,rollInitialGuard,rollInitialNext]
theorem copyAPreserves (q : State) (h : Safe q) (g : copyAGuard q) : Safe (copyANext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,copyAGuard,copyANext] <;> omega
 · simp_all [Safe,copyAGuard,copyANext]
theorem readyEarlyPreserves (q : State) (h : Safe q) (g : readyEarlyGuard q) : Safe (readyEarlyNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,readyEarlyGuard,readyEarlyNext] <;> omega
 · simp_all [Safe,readyEarlyGuard,readyEarlyNext]
theorem publishEarlyPreserves (q : State) (h : Safe q) (g : publishEarlyGuard q) : Safe (publishEarlyNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,publishEarlyGuard,publishEarlyNext] <;> omega
 · simp_all [Safe,publishEarlyGuard,publishEarlyNext]
theorem deferChunkPreserves (q : State) (h : Safe q) (g : deferChunkGuard q) : Safe (deferChunkNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,deferChunkGuard,deferChunkNext] <;> omega
 · simp_all [Safe,deferChunkGuard,deferChunkNext]
theorem fillLinkPreserves (q : State) (h : Safe q) (g : fillLinkGuard q) : Safe (fillLinkNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,fillLinkGuard,fillLinkNext] <;> omega
 · simp_all [Safe,fillLinkGuard,fillLinkNext]
theorem sealReadyPreserves (q : State) (h : Safe q) (g : sealReadyGuard q) : Safe (sealReadyNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,sealReadyGuard,sealReadyNext] <;> omega
 · simp_all [Safe,sealReadyGuard,sealReadyNext]
theorem publishDeferredPreserves (q : State) (h : Safe q) (g : publishDeferredGuard q) : Safe (publishDeferredNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,publishDeferredGuard,publishDeferredNext] <;> omega
 · simp_all [Safe,publishDeferredGuard,publishDeferredNext]
theorem claimPreserves (q : State) (h : Safe q) (g : claimGuard q) : Safe (claimNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,claimGuard,claimNext] <;> omega
 · simp_all [Safe,claimGuard,claimNext]
theorem readLinkPreserves (q : State) (h : Safe q) (g : readLinkGuard q) : Safe (readLinkNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,readLinkGuard,readLinkNext] <;> omega
 · simp_all [Safe,readLinkGuard,readLinkNext]
theorem hideLinkPreserves (q : State) (h : Safe q) (g : hideLinkGuard q) : Safe (hideLinkNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,hideLinkGuard,hideLinkNext] <;> omega
 · simp_all [Safe,hideLinkGuard,hideLinkNext]
theorem restoreOldPreserves (q : State) (h : Safe q) (g : restoreOldGuard q) : Safe (restoreOldNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,restoreOldGuard,restoreOldNext] <;> omega
 · simp_all [Safe,restoreOldGuard,restoreOldNext]
theorem restoreFixedPreserves (q : State) (h : Safe q) (g : restoreFixedGuard q) : Safe (restoreFixedNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,restoreFixedGuard,restoreFixedNext] <;> omega
 · simp_all [Safe,restoreFixedGuard,restoreFixedNext]
theorem releaseCopierPreserves (q : State) (h : Safe q) (g : releaseCopierGuard q) : Safe (releaseCopierNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,releaseCopierGuard,releaseCopierNext] <;> omega
 · simp_all [Safe,releaseCopierGuard,releaseCopierNext]
theorem closePreserves (q : State) (h : Safe q) (g : closeGuard q) : Safe (closeNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
   simp_all [Safe,closeGuard,closeNext] <;> omega
 · simp_all [Safe,closeGuard,closeNext]
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15
 · rcases a0 with ⟨g,rfl⟩; exact rollInitialPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact copyAPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact readyEarlyPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact publishEarlyPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact deferChunkPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact fillLinkPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact sealReadyPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact publishDeferredPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact claimPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact readLinkPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact hideLinkPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact restoreOldPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact restoreFixedPreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact releaseCopierPreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact closePreserves q h g
 · simpa [a15] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem readyExcludesPending (q : State) (h : Safe q) (hm : q.managed=true) (r : q.ready=true) : q.pending=false := by
 have hs := h hm
 rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all
theorem deferredRetainsCopier (q : State) (h : Safe q) (hm : q.managed=true) (d : q.deferred=true) : q.copier=true := by
 have hs := h hm
 rcases hs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14⟩
 simp_all
theorem cursorOutsideDisjoint (cursor a b c d : Int) (inside : a≤cursor ∧ cursor<b) (disjoint : b≤c ∨ d≤a) : ¬(c≤cursor ∧ cursor<d) := by omega
def legacyStart : State := {initial with managed:=false}
def legacyLost : State := restoreOldNext (fillLinkNext (hideLinkNext (readLinkNext (claimNext (publishEarlyNext (readyEarlyNext (copyANext (rollInitialNext legacyStart))))))))
theorem legacyLostFixup : legacyLost.fixed=true ∧ legacyLost.link=3 := by decide
theorem stepKeepsMode (q r : State) (st : Step q r) : r.managed=q.managed := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15
 · rcases a0 with ⟨_,e⟩; rw [e]; rfl
 · rcases a1 with ⟨_,e⟩; rw [e]; rfl
 · rcases a2 with ⟨_,e⟩; rw [e]; rfl
 · rcases a3 with ⟨_,e⟩; rw [e]; rfl
 · rcases a4 with ⟨_,e⟩; rw [e]; rfl
 · rcases a5 with ⟨_,e⟩; rw [e]; rfl
 · rcases a6 with ⟨_,e⟩; rw [e]; rfl
 · rcases a7 with ⟨_,e⟩; rw [e]; rfl
 · rcases a8 with ⟨_,e⟩; rw [e]; rfl
 · rcases a9 with ⟨_,e⟩; rw [e]; rfl
 · rcases a10 with ⟨_,e⟩; rw [e]; rfl
 · rcases a11 with ⟨_,e⟩; rw [e]; rfl
 · rcases a12 with ⟨_,e⟩; rw [e]; rfl
 · rcases a13 with ⟨_,e⟩; rw [e]; rfl
 · rcases a14 with ⟨_,e⟩; rw [e]; rfl
 · rw [a15]
theorem reachableManaged (q : State) (h : Reachable q) : q.managed=true := by
 induction h with
 | start => rfl
 | next _ st ih => exact (stepKeepsMode _ _ st).trans ih
theorem frameLinkCoordinate (body fs extra link : Int) :
 body+(fs+extra)-(link+1) = (body+extra+fs)-(link+1) := by omega
end FrameSeal
