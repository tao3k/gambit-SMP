import SizeGuardEntry
import SizeGuardConversion
import SizeGuardUse
import SizeGuardDrop
import SizeGuardReceipt
import SizeGuardRetire
import SizeGuardFreeze
import SizeGuardResume
open SizeGuardAst
namespace SizeGuard
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29
 · rcases h0 with ⟨g, rfl⟩
   exact reserveSfunPreserves q h g
 · rcases h1 with ⟨g, rfl⟩
   exact reserveCfunPreserves q h g
 · rcases h2 with ⟨g, rfl⟩
   exact beginConversionPreserves q h g
 · rcases h3 with ⟨g, rfl⟩
   exact completeBoxedPreserves q h g
 · rcases h4 with ⟨g, rfl⟩
   exact completeImmediatePreserves q h g
 · rcases h5 with ⟨g, rfl⟩
   exact abortBeforeConversionPreserves q h g
 · rcases h6 with ⟨g, rfl⟩
   exact acquireRootUpdatePreserves q h g
 · rcases h7 with ⟨g, rfl⟩
   exact publishLanguagePreserves q h g
 · rcases h8 with ⟨g, rfl⟩
   exact releaseRootUpdatePreserves q h g
 · rcases h9 with ⟨g, rfl⟩
   exact captureArgumentPreserves q h g
 · rcases h10 with ⟨g, rfl⟩
   exact finishNativePreserves q h g
 · rcases h11 with ⟨g, rfl⟩
   exact escapeNativePreserves q h g
 · rcases h12 with ⟨g, rfl⟩
   exact claimDropPreserves q h g
 · rcases h13 with ⟨g, rfl⟩
   exact fuseCfunHandoffPreserves q h g
 · rcases h14 with ⟨g, rfl⟩
   exact physicalDropPreserves q h g
 · rcases h15 with ⟨g, rfl⟩
   exact recordDropPreserves q h g
 · rcases h16 with ⟨g, rfl⟩
   exact releaseDropPreserves q h g
 · rcases h17 with ⟨g, rfl⟩
   exact loseReplyPreserves q h g
 · rcases h18 with ⟨g, rfl⟩
   exact queryReceiptPreserves q h g
 · rcases h19 with ⟨g, rfl⟩
   exact dropCapturePreserves q h g
 · rcases h20 with ⟨g, rfl⟩
   exact clearLanguagePreserves q h g
 · rcases h21 with ⟨g, rfl⟩
   exact retireGuardPreserves q h g
 · rcases h22 with ⟨g, rfl⟩
   exact reissueSfunPreserves q h g
 · rcases h23 with ⟨g, rfl⟩
   exact reissueCfunPreserves q h g
 · rcases h24 with ⟨g, rfl⟩
   exact closeGatePreserves q h g
 · rcases h25 with ⟨g, rfl⟩
   exact freezeOwnerPreserves q h g
 · rcases h26 with ⟨g, rfl⟩
   exact beginScanPreserves q h g
 · rcases h27 with ⟨g, rfl⟩
   exact endScanPreserves q h g
 · rcases h28 with ⟨g, rfl⟩
   exact resumeOwnerPreserves q h g
 · rcases h29 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance h step ih => exact stepPreserves _ _ ih step
theorem nativeHoldConservation (q : State) (h : Safe q) : q.hold+q.effects=q.created := by
 unfold Safe at h
 grind
theorem frozenExcludesLease (q : State) (h : Safe q) (f : q.frozen=1) : q.lease=0 ∧ q.closed=1 := by
 unfold Safe at h
 grind
theorem effectWindowExcludesGc (q : State) (h : Safe q) (f : q.lease=2) : q.gc=0 ∧ q.frozen=0 ∧ q.leaseEpoch=q.epoch := by
 unfold Safe at h
 grind
theorem scanPinsOwner (q : State) (h : Safe q) (f : q.scanners=1) : q.frozen=1 ∧ q.lease=0 := by
 unfold Safe at h
 grind
theorem receiptMatchesAttempt (q : State) (h : Safe q) (f : q.reply=1) : q.receiptId=q.attempt ∧ q.effects=q.created ∧ q.hold=0 := by
 unfold Safe at h
 grind
theorem settledCannotReplayDrop (q : State) (p : q.phase≥8) : ¬ physicalDropGuard q := by
 unfold physicalDropGuard
 omega
theorem liveHoldHasCarrier (q : State) (h : Safe q) (p : q.phase≥3) (hld : q.hold=1) : q.carrier=1 ∧ q.guard=1 := by
 unfold Safe at h
 grind
theorem captureStillHasRoot (q : State) (h : Safe q) (p : q.captured=1) : q.lang=1 := by
 unfold Safe at h
 grind
theorem closeKeepsDropAuthority (q : State) (g : physicalDropGuard q) : physicalDropGuard (closeGateNext q) := by
 simpa [physicalDropGuard,closeGateNext] using g
theorem recordBeforeUnlock (q : State) (g : releaseDropGuard q) : q.receiptId=q.attempt ∧ q.phase=7 := by
 unfold releaseDropGuard at g
 grind
theorem fusedCfunEqualsSeparate (q : State) : fuseCfunHandoffNext q = claimDropNext (finishNativeNext (releaseRootUpdateNext (publishLanguageNext (acquireRootUpdateNext q)))) := by rfl
theorem fusedGuardChain (q : State) (g : fuseCfunHandoffGuard q) :
 acquireRootUpdateGuard q ∧
 publishLanguageGuard (acquireRootUpdateNext q) ∧
 releaseRootUpdateGuard (publishLanguageNext (acquireRootUpdateNext q)) ∧
 finishNativeGuard (releaseRootUpdateNext (publishLanguageNext (acquireRootUpdateNext q))) ∧
 claimDropGuard (finishNativeNext (releaseRootUpdateNext (publishLanguageNext (acquireRootUpdateNext q)))) := by
 simp_all [fuseCfunHandoffGuard,acquireRootUpdateGuard,acquireRootUpdateNext,publishLanguageGuard,publishLanguageNext,releaseRootUpdateGuard,releaseRootUpdateNext,finishNativeGuard,finishNativeNext,claimDropGuard]
end SizeGuard
