import NodeStorageAuthorityAst
import NodeStorageAuthorityStepsA
import NodeStorageAuthorityStepsB
import PutObjsMoveGraph
namespace NodeStorageAuthority
open NodeStorageAuthorityAst
set_option maxRecDepth 10000
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22
 · rcases h0 with ⟨g,rfl⟩
   exact publishRawListPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact initializeOwnerPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact attestDisjointPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact bindNodeMapPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact sealReaderClosurePreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact exposeAliasPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact revokeSealPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact rejectAliasPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact acquireMetadataPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact returnMetadataPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact acquirePayloadPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact returnPayloadPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact knownHandoffPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact unknownHandoffPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact consumerAllocatePreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact fixSourceLastPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact publishCompletionPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact closeAdmissionPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact attestCleanupPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact retireCachePreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact lookupOpaquePreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact probeCurrentCachePreserves q h g
 · simpa [h22] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem unknownKeepsStorage (q : State) (h : Safe q) (hu : q.unknown=1) : q.cacheLive=1 ∧ q.cacheGen=1 ∧ q.receipt=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 omega
theorem roleIsNotAllocation (q : State) (h : Safe q) (hr : q.nodeRole=2) : q.nodeAllocGen=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 omega
theorem staleCacheGeneration (q : State) (h : Safe q) (hs : q.stage=9) : q.cacheGen≠q.queryGen := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 omega
theorem rawListNotBinding (q : State) (h : Safe q) (hs : q.stage=1) : q.mapReady=0 ∧ q.ownerReady=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 omega
theorem postHandoffNoPayload (q : State) (h : Safe q) (hs : q.stage>=5) (ht : q.stage<=9) : ¬ acquirePayloadGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 simp only [acquirePayloadGuard]
 omega
structure Span where
 lo : Int
 hi : Int
def Inside (field whole : Span) : Prop := whole.lo<=field.lo ∧ field.hi<=whole.hi
def Apart (a b : Span) : Prop := a.hi<=b.lo ∨ b.hi<=a.lo
theorem subfieldsApart (cache node cf nf : Span) (ha : Apart cache node) (hc : Inside cf cache) (hn : Inside nf node) : Apart cf nf := by
 simp only [Apart] at *
 simp only [Inside] at *
 omega
theorem unionRoleNotApart (lo hi : Int) (h : lo<hi) : ¬ Apart ⟨lo,hi⟩ ⟨lo,hi⟩ := by simp [Apart]; omega
structure StorageKey where
 allocation : Nat
 incarnation : Nat
 deriving DecidableEq
structure NodeBinding where
 storage : StorageKey
 slot : Nat
 deriving DecidableEq
theorem freshIncarnation (a g h : Nat) (hne : g≠h) : (StorageKey.mk a g)≠(StorageKey.mk a h) := by
 intro he
 have hh := congrArg StorageKey.incarnation he
 exact hne hh
theorem bindingIdentity (phi : Int → NodeBinding) (hinj : Function.Injective phi) (n m : Int) (hne : n≠m) : phi n≠phi m := by
 intro he
 exact hne (hinj he)
def edgeRep (phi : Int → NodeBinding) (n : Int) : Option NodeBinding := if n=0 then none else some (phi n)
def NativeRel (next : NodeBinding → Option NodeBinding) (phi : Int → NodeBinding) (g : PutObjsMoveGraph.Graph) : Prop := ∀ n, 1<=n → n<=1202 → next (phi n)=edgeRep phi (g.edge n)
theorem walkToNative (q : PutObjsMoveGraphAst.State) (g : PutObjsMoveGraph.Graph) (phi : Int → NodeBinding) (next : NodeBinding → Option NodeBinding) (hs : PutObjsMoveGraphAst.Safe q) (hw : PutObjsMoveGraphAst.walkMovedNextGuard q) (he : PutObjsMoveGraph.Encodes g q) (hn : NativeRel next phi g) : next (phi q.cursor)=some (phi (q.cursor+1)) := by
 have hb : 1<=q.cursor ∧ q.cursor<=1202 := by
  simp only [PutObjsMoveGraphAst.Safe] at hs
  omega
 have hh := hn q.cursor hb.1 hb.2
 rw [PutObjsMoveGraph.physicalWalk g q he hs hw] at hh
 have hz : q.cursor+1≠0 := by omega
 simpa [edgeRep,hz] using hh
theorem opaqueRecordSurvivesCache (q : State) (h : Safe q) (hs : q.stage=9) : lookupOpaqueGuard {q with opaqueSeen:=0} := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
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
 simp only [lookupOpaqueGuard]
 omega
end NodeStorageAuthority
