import RuntimeTlsReadyAst
import CacheReadyPublicationAst
import RuntimeTlsReadyInitialization
import RuntimeTlsReadyBindings
import RuntimeTlsReadyFinalization
namespace RuntimeTlsReady
open RuntimeTlsReadyAst
set_option maxRecDepth 10000
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39
 · rcases h0 with ⟨g,rfl⟩
   exact beginThreadClosePreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact rebindCachePreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact refreshHandlePreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact closeEmptyOwnerPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact reserveRuntimePreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact initializeLocksPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact initializeTablesPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact createGenericKeyPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact createAllocKeyKnownPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact createAllocKeyUnknownPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact bootstrapBorrowPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact bootstrapReturnPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact initializationReentryPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact publishRuntimePreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact observeRuntimePreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact beginCacheInstallPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact rawSetterReturnedPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact recordKnownInstallPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact installUnknownPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact publishCachePreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact publishFastPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact acquireNormalPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact releaseNormalPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact admitFinalizerPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact beginGlobalClosePreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact deriveLateTsdWorkPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact drainLateTsdWorkPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact finishFinalizerPreserves q h g
 · rcases h28 with ⟨g,rfl⟩
   exact closeCachePreserves q h g
 · rcases h29 with ⟨g,rfl⟩
   exact clearFastKnownPreserves q h g
 · rcases h30 with ⟨g,rfl⟩
   exact clearTlsKnownPreserves q h g
 · rcases h31 with ⟨g,rfl⟩
   exact clearTlsUnknownPreserves q h g
 · rcases h32 with ⟨g,rfl⟩
   exact freeCacheKnownPreserves q h g
 · rcases h33 with ⟨g,rfl⟩
   exact attestRosterClosedPreserves q h g
 · rcases h34 with ⟨g,rfl⟩
   exact deleteGenericKeyPreserves q h g
 · rcases h35 with ⟨g,rfl⟩
   exact deleteAllocKeyKnownPreserves q h g
 · rcases h36 with ⟨g,rfl⟩
   exact deleteAllocKeyUnknownPreserves q h g
 · rcases h37 with ⟨g,rfl⟩
   exact freeGlobalLocksPreserves q h g
 · rcases h38 with ⟨g,rfl⟩
   exact retireRuntimePreserves q h g
 · simpa [h39] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem runtimeReadyHasServices (q : State) (h : Safe q) (hg : q.g=2) : q.locks=1 ∧ q.tables=1 ∧ q.genericKey=1 ∧ q.allocKey=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem unknownInstallRetainsOwner (q : State) (h : Safe q) (ht : q.tls=2) : q.owner=1 ∧ q.cache≠4 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem freeHasNoAliases (q : State) (h : Safe q) (hc : q.cache=4) : q.tls=0 ∧ q.fast=0 ∧ q.usePin=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem lateWorkRetainsParent (q : State) (h : Safe q) (hl : q.late=1) : q.finalizer=1 ∧ q.cache=2 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem retiredHasNoServices (q : State) (h : Safe q) (hg : q.g=4) : q.locks=0 ∧ q.allocKey=0 ∧ q.genericKey=0 ∧ q.epoch=2 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem unknownKeyNoReady (q : State) (h : Safe q) (hk : q.allocKey=2) : q.g≠2 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 omega
theorem cacheRetainsServices (q : State) (h : Safe q) (hc : q.cache>=1 ∧ q.cache<=3) : q.allocKey=1 ∧ q.genericKey=1 ∧ q.locks=1 ∧ q.tables=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49⟩
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
 exact h49 hc
-- Conditional C23 bridge: the matching same-epoch release/acquire edge is supplied, not inferred from volatile.
theorem readyHappensBefore (hb rf : Nat → Nat → Prop) (trans : ∀ a b c, hb a b → hb b c → hb a c) (sync : ∀ s l, rf s l → hb s l) (write release acquire read : Nat) (hw : hb write release) (hrf : rf release acquire) (hr : hb acquire read) : hb write read := by
 exact trans write acquire read (trans write release acquire hw (sync release acquire hrf)) hr
def InstallMirror (q : State) (r : CacheReadyPublicationAst.State) : Prop := (q.cache=1 ∧ q.tls=0) → r.stage=3 ∧ r.tls=0
theorem suppliesPriorGuard (q : State) (r : CacheReadyPublicationAst.State) (g : recordKnownInstallGuard q) (hm : InstallMirror q r) : CacheReadyPublicationAst.installTlsKnownGuard r := by
 simp only [recordKnownInstallGuard] at g
 simp only [InstallMirror] at hm
 simp only [CacheReadyPublicationAst.installTlsKnownGuard]
 omega
theorem guardedPriorInstall (q : State) (r : CacheReadyPublicationAst.State) (g : recordKnownInstallGuard q) (hm : InstallMirror q r) : CacheReadyPublicationAst.Step r (CacheReadyPublicationAst.installTlsKnownNext r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))
end RuntimeTlsReady
