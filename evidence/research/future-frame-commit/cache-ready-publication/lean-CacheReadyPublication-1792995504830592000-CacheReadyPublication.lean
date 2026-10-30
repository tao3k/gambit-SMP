import CacheReadyPublicationAst
import NodeStorageAuthorityAst
import CacheReadyPublicationConstruction
import CacheReadyPublicationReaders
import CacheReadyPublicationSnapshots
import CacheReadyPublicationShutdown
import CacheReadyPublicationRollback
namespace CacheReadyPublication
open CacheReadyPublicationAst
set_option maxRecDepth 10000
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33
 · rcases h0 with ⟨g,rfl⟩
   exact reserveConstructionPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact allocateCandidatePreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact allocationRejectedPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact initializeOwnerPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact installTlsKnownPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact installTlsUnknownPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact stageRegistryEntryPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact publishKnownPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact publishUnknownCommittedPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact publishUnknownAbsentPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact rejectPublicationPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact reconcileCommittedPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact reconcileAbsentPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact finishBuilderPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact publishFastHandlePreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact constructionReentryPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact closingReentryPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact acquireReaderPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact releaseReaderPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact qualifyStatsPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact beginDiagnosticPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact requestOwnerSnapshotPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact ownerSnapshotAckPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact releaseDiagnosticPinPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact formatSnapshotPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact closeReadyPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact unlinkEntryPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact clearTlsKnownPreserves q h g
 · rcases h28 with ⟨g,rfl⟩
   exact clearFastKnownPreserves q h g
 · rcases h29 with ⟨g,rfl⟩
   exact attestNativeCleanupPreserves q h g
 · rcases h30 with ⟨g,rfl⟩
   exact retireKnownPreserves q h g
 · rcases h31 with ⟨g,rfl⟩
   exact rollbackUnknownPreserves q h g
 · rcases h32 with ⟨g,rfl⟩
   exact rollbackKnownPreserves q h g
 · simpa [h33] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem readyRequiresInitialization (q : State) (h : Safe q) (hr : q.ready=1) : q.owner=1 ∧ q.tls=1 ∧ q.listed=1 ∧ q.owned=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 rcases h33 (h34 hr) with ⟨_,ho,hw,ht,hl,_⟩
 exact ⟨hw,ht,hl,ho⟩
theorem unknownRetainsBuilder (q : State) (h : Safe q) (ha : q.ack=2) : q.builder=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 exact (h41 ha).1
theorem unknownTlsNoRegistry (q : State) (h : Safe q) (ht : q.tls=2) : q.builder=1 ∧ q.ready=0 ∧ q.listed=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 rcases h42 ht with ⟨hp,_,hb,hr⟩
 exact ⟨hb,hr,(h30 hp).2.1⟩
theorem formatUsesDetachedCopy (q : State) (h : Safe q) (hf : formatSnapshotGuard q) : q.diagPin=0 ∧ q.snapshot=1 ∧ q.snapshotGen=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 simp only [formatSnapshotGuard] at hf
 omega
theorem retiredNoPins (q : State) (h : Safe q) (hs : q.stage=8) : q.readerPin=0 ∧ q.diagPin=0 ∧ q.builder=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 rcases h36 hs with ⟨_,_,_,_,hb,hr,hd,_⟩
 exact ⟨hr,hd,hb⟩
theorem noSecondCandidate (q : State) (h : Safe q)  : q.allocations<=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 exact h21.2
theorem rollbackUnknownRetainsDuty (q : State) (h : Safe q) (hu : q.rollbackUnknown=1) : q.builder=1 ∧ q.ready=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 exact ⟨(h54 hu).2.2.1,(h54 hu).2.1⟩
theorem lateFormatAdmitted (q : State) (h : Safe q) (hs : q.stage=8) (hd : q.diagState=4) : formatSnapshotGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 rcases h20 with ⟨hl20,hu20⟩
 rcases h21 with ⟨hl21,hu21⟩
 simp only [formatSnapshotGuard]
 omega
def DiagnosticMirror (q : State) (r : NodeStorageAuthorityAst.State) : Prop := (q.ready=1 ∧ q.diagPin=1) → r.mapReady=1 ∧ r.metaLease=1 ∧ r.gate=1 ∧ r.cacheLive=1 ∧ r.cacheGen=r.queryGen ∧ r.coverage=1 ∧ r.aliasSeen=0 ∧ r.currentSeen=0
theorem suppliesPriorGuard (q : State) (r : NodeStorageAuthorityAst.State) (g : beginDiagnosticGuard q) (hm : DiagnosticMirror (beginDiagnosticNext q) r) : NodeStorageAuthorityAst.probeCurrentCacheGuard r := by
 simp only [beginDiagnosticGuard] at g
 have hr : q.ready=1 := by omega
 simp only [DiagnosticMirror] at hm
 have hh := hm (show (beginDiagnosticNext q).ready=1 ∧ (beginDiagnosticNext q).diagPin=1 from ⟨hr,rfl⟩)
 simp only [NodeStorageAuthorityAst.probeCurrentCacheGuard]
 omega
theorem guardedPriorDiagnostic (q : State) (r : NodeStorageAuthorityAst.State) (g : beginDiagnosticGuard q) (hm : DiagnosticMirror (beginDiagnosticNext q) r) : NodeStorageAuthorityAst.Step r (NodeStorageAuthorityAst.probeCurrentCacheNext r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩)))))))))))))))))))))
end CacheReadyPublication
