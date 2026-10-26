import PutObjsMoveGraphAst
import PutObjsCustodyAst
import PutObjsMoveGraphStepsA
import PutObjsMoveGraphStepsB
import PutObjsMoveGraphStepsC
import PutObjsMoveGraphStepsD
namespace PutObjsMoveGraph
open PutObjsMoveGraphAst
set_option maxRecDepth 10000
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28
 · rcases h0 with ⟨g,rfl⟩
   exact knownProducerUnlockPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact unknownReleasedPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact unknownStillHeldPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact fixProducerLastPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact publishReceiptPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact closeSourceAdmissionPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact sourceReadersDetachedPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact attestSourceFinalizedPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact reuseSourceCachePreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact borrowOldTailPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact acquireConsumerPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact selectMove800Preserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact loadMoveHeadPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact creditDestinationPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact debitSharedPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact walkMovedNextPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact detachSharedHeadPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact assignDestinationTailPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact cutMovedTailPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact publishDestinationHeadPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact releaseConsumerPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact loadPopHeadPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact advanceInteriorHeadPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact advanceLastHeadPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact decrementDestinationPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact returnInteriorPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact returnTailPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact initializeTailPayloadPreserves q h g
 · simpa [h28] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem unknownRetainsSource (q : State) (h : Safe q) (hk : q.knowledge=2) : q.held=1 ∧ q.localTail=1201 ∧ q.receipt=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 omega
theorem returnedTailCount (q : State) (h : Safe q) (ht : q.tailReturned=1) : q.pops=800 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 omega
theorem opaqueAfterUnlock (q : State) (h : Safe q) (hp : q.p>=1) : q.opaqueOnly=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 omega
theorem staleSourceReceipt (q : State) (h : Safe q) (hp : q.p=5) : q.stamp≠q.generation := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 omega
def BeforeMirror (q : State) (r : PutObjsCustodyAst.State) : Prop := q.c=8 → r.phase>=11 ∧ r.delta=800 ∧ r.exposed=800 ∧ r.batchTaken=0
theorem suppliesPriorGuard (q : State) (r : PutObjsCustodyAst.State) (g : publishDestinationHeadGuard q) (hm : BeforeMirror q r) : PutObjsCustodyAst.takePublishedBatchGuard r := by
 simp only [publishDestinationHeadGuard] at g
 simp only [BeforeMirror] at hm
 simp only [PutObjsCustodyAst.takePublishedBatchGuard]
 omega
theorem guardedPriorTake (q : State) (r : PutObjsCustodyAst.State) (g : publishDestinationHeadGuard q) (hm : BeforeMirror q r) : PutObjsCustodyAst.Step r (PutObjsCustodyAst.takePublishedBatchNext r) := by
 exact Or.inl ⟨suppliesPriorGuard q r g hm,rfl⟩
-- Finite graph family: fixed internal chains and two explicit boundary links.
def canonicalNext (n : Int) : Int := if 1<=n ∧ n<1202 then n+1 else 0
def rawNext (q : State) (n : Int) : Int := if n=401 then 0 else if n=1201 then q.tailNext else canonicalNext n
structure Graph where
 edge : Int → Int
 sharedHead : Int
 destinationHead : Int
 producerTail : Int
def expand (q : State) : Graph := ⟨rawNext q,q.sharedHead,q.destHead,q.localTail⟩
def Encodes (g : Graph) (q : State) : Prop := g.edge 401=0 ∧ g.edge 1201=q.tailNext ∧ (∀ n, n≠401 → n≠1201 → g.edge n=canonicalNext n) ∧ g.sharedHead=q.sharedHead ∧ g.destinationHead=q.destHead ∧ g.producerTail=q.localTail
theorem expandedEncodes (q : State) : Encodes (expand q) q := by
 simp [Encodes,expand,rawNext]
theorem encodingUnique (g : Graph) (q : State) (he : Encodes g q) : g.edge=rawNext q := by
 rcases he with ⟨ha,hb,hrest,_⟩
 funext n
 by_cases hn : n=401
 · subst n; simpa [rawNext] using ha
 · by_cases ht : n=1201
   · subst n; simpa [rawNext] using hb
   · simpa [rawNext,hn,ht] using hrest n hn ht
theorem physicalWalk (g : Graph) (q : State) (he : Encodes g q) (h : Safe q) (hw : walkMovedNextGuard q) : g.edge q.cursor=q.cursor+1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [walkMovedNextGuard] at hw
 have ha : q.cursor≠401 := by omega
 have hb : q.cursor≠1201 := by omega
 have hc : 1<=q.cursor ∧ q.cursor<1202 := by omega
 rw [encodingUnique g q he]
 simp [rawNext,ha,hb,canonicalNext,hc]
theorem physicalDetach (g : Graph) (q : State) (he : Encodes g q) (h : Safe q) (hd : detachSharedHeadGuard q) : (detachSharedHeadNext q).sharedHead=g.edge q.cursor := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [detachSharedHeadGuard] at hd
 have hc : q.cursor=1201 := by omega
 rw [encodingUnique g q he]
 simp [detachSharedHeadNext,rawNext,hc]
theorem physicalCut (g : Graph) (q : State) (he : Encodes g q) (h : Safe q) (hc : cutMovedTailGuard q) (n : Int) : rawNext (cutMovedTailNext q) n = (if n=1201 then 0 else g.edge n) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [cutMovedTailGuard] at hc
 have hz : q.destHead=0 := by omega
 rw [encodingUnique g q he]
 by_cases hn : n=1201
 · subst n; simp [rawNext,cutMovedTailNext,hz]
 · simp [rawNext,cutMovedTailNext,hn]
theorem producerFixPreservesEdges (q : State) : rawNext (fixProducerLastNext q)=rawNext q := by rfl
theorem fixAndCutCommute (q : State) : fixProducerLastNext (cutMovedTailNext q)=cutMovedTailNext (fixProducerLastNext q) := by cases q; rfl
theorem cutGuardAfterFix (q : State) (hc : cutMovedTailGuard q) : cutMovedTailGuard (fixProducerLastNext q) := by simpa [cutMovedTailGuard,fixProducerLastNext] using hc
theorem fixGuardAfterCut (q : State) (hf : fixProducerLastGuard q) : fixProducerLastGuard (cutMovedTailNext q) := by simpa [fixProducerLastGuard,cutMovedTailNext] using hf
def freeLink (q : State) (n : Int) : Option Int := if 402<=n ∧ n<402+q.pops then none else some (rawNext q n)
theorem allocatedTailNoLink (q : State) (h : Safe q) (ht : q.tailReturned=1) : freeLink q 1201=none := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 have hp : q.pops=800 := by omega
 simp [freeLink,hp]
theorem opaqueCannotBorrow (q : State) (h : Safe q) (hp : q.p>=1) : ¬ borrowOldTailGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [borrowOldTailGuard]
 omega
theorem unknownCannotRetire (q : State) (h : Safe q) (hk : q.knowledge=2) : ¬ reuseSourceCacheGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50, h51, h52, h53, h54, h55, h56, h57, h58, h59, h60, h61, h62, h63, h64, h65, h66, h67, h68, h69, h70, h71, h72⟩
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
 rcases h22 with ⟨hl22,hu22⟩
 rcases h23 with ⟨hl23,hu23⟩
 rcases h24 with ⟨hl24,hu24⟩
 rcases h25 with ⟨hl25,hu25⟩
 rcases h26 with ⟨hl26,hu26⟩
 simp only [reuseSourceCacheGuard]
 omega
end PutObjsMoveGraph
