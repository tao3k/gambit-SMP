import SizeHoldSelections
import SizeHoldConversions
import SizeHoldRoots
import SizeHoldRelease
import SizeHoldReceipts
import SizeHoldGc
open SizeHoldAst
namespace SizeHold
theorem initialSafe : Safe initial := by decide
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22
 · rcases h0 with ⟨g, rfl⟩
   exact selectSizeMaxPreserves q h g
 · rcases h1 with ⟨g, rfl⟩
   exact selectSignedMinPreserves q h g
 · rcases h2 with ⟨g, rfl⟩
   exact selectSignedMaxPreserves q h g
 · rcases h3 with ⟨g, rfl⟩
   exact selectAboveFixPreserves q h g
 · rcases h4 with ⟨g, rfl⟩
   exact selectAtFixPreserves q h g
 · rcases h5 with ⟨g, rfl⟩
   exact selectMinFixPreserves q h g
 · rcases h6 with ⟨g, rfl⟩
   exact selectBelowFixPreserves q h g
 · rcases h7 with ⟨g, rfl⟩
   exact convertBoxedPreserves q h g
 · rcases h8 with ⟨g, rfl⟩
   exact convertImmediatePreserves q h g
 · rcases h9 with ⟨g, rfl⟩
   exact conversionFailurePreserves q h g
 · rcases h10 with ⟨g, rfl⟩
   exact publishRootPreserves q h g
 · rcases h11 with ⟨g, rfl⟩
   exact captureArgumentPreserves q h g
 · rcases h12 with ⟨g, rfl⟩
   exact finishNativePreserves q h g
 · rcases h13 with ⟨g, rfl⟩
   exact enterDropPreserves q h g
 · rcases h14 with ⟨g, rfl⟩
   exact physicalDropPreserves q h g
 · rcases h15 with ⟨g, rfl⟩
   exact commitDropPreserves q h g
 · rcases h16 with ⟨g, rfl⟩
   exact loseReplyPreserves q h g
 · rcases h17 with ⟨g, rfl⟩
   exact recoverReplyPreserves q h g
 · rcases h18 with ⟨g, rfl⟩
   exact dropCapturePreserves q h g
 · rcases h19 with ⟨g, rfl⟩
   exact dropRootPreserves q h g
 · rcases h20 with ⟨g, rfl⟩
   exact beginGcPreserves q h g
 · rcases h21 with ⟨g, rfl⟩
   exact finishGcPreserves q h g
 · rcases h22 with rfl
   exact h
theorem reachableSafe (q : State) (h : Relation.ReflTransGen Step initial q) : Safe q := by
 induction h with
 | refl => exact initialSafe
 | tail h step ih => exact stepPreserves _ _ ih step
theorem settledHoldZero (q : State) (h : Safe q) (s : q.phase=6) : q.hold=0 := by
 unfold Safe at h
 grind
theorem heldBalance (q : State) (h : Safe q) : q.hold+q.effects=q.created := by
 unfold Safe at h
 tauto
theorem noReplayDrop (q : State) (h : Safe q) (s : q.phase=6) : ¬ physicalDropGuard q := by
 simp [physicalDropGuard,s]
theorem captureKeepsRoot (q : State) (h : Safe q) (c : q.captured=1) : q.root=1 := by
 unfold Safe at h
 grind
theorem noGcInEffectWindow (q : State) (h : Safe q) (c : q.critical=1) : q.gc=0 := by
 unfold Safe at h
 tauto
-- Numeric predicates are mathematical; native typedef/preprocessor fidelity stays separate.
def fits (p x : Int) : Prop := -p ≤ x ∧ x < p
def nativeSigned64 (x : Int) : Prop := -9223372036854775808 ≤ x ∧ x ≤ 9223372036854775807
def nativeSize64 (x : Int) : Prop := 0 ≤ x ∧ x ≤ 18446744073709551615
theorem signedPartition (x : Int) (p : Int) : ¬ fits p x ↔ x < -p ∨ p ≤ x := by
 unfold fits
 omega
theorem fixEndpoints : fits 1152921504606846976 (-1152921504606846976) ∧ fits 1152921504606846976 1152921504606846975 := by simp [fits,nativeSigned64,nativeSize64]
theorem upperOutside : ¬ fits 1152921504606846976 1152921504606846976 ∧ nativeSize64 1152921504606846976 := by simp [fits,nativeSigned64,nativeSize64]
theorem lowerOutside : ¬ fits 1152921504606846976 (-1152921504606846977) ∧ nativeSigned64 (-1152921504606846977) := by simp [fits,nativeSigned64,nativeSize64]
theorem sizeMaximumBoxed : nativeSize64 18446744073709551615 ∧ ¬ fits 1152921504606846976 18446744073709551615 := by simp [fits,nativeSigned64,nativeSize64]
theorem signedExtremaBoxed : ¬ fits 1152921504606846976 (-9223372036854775808) ∧ ¬ fits 1152921504606846976 9223372036854775807 := by simp [fits,nativeSigned64,nativeSize64]
theorem alternateProfiles : fits 2305843009213693952 2305843009213693951 ∧ ¬ fits 2305843009213693952 2305843009213693952 ∧ fits 536870912 536870911 ∧ ¬ fits 536870912 536870912 := by simp [fits,nativeSigned64,nativeSize64]
-- Closed-path legacy witness: ending the scope without an effect retains the hold.
def legacyEnd (h : Int) : Int := h
theorem legacyCloseRetains : legacyEnd 1 = 1 := by rfl
theorem zeroCountNotDestruction : ∃ q : State, Safe q ∧ q.hold=0 ∧ q.captured=1 ∧ q.root=1 := by
 let q : State := {initial with phase:=6, created:=1, effects:=1, captured:=1, root:=1, exited:=1, settled:=1}
 exact ⟨q, by dsimp [q,Safe,initial]; decide, by rfl, by rfl, by rfl⟩
end SizeHold
