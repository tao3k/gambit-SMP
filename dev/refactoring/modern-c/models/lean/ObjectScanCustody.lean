import ObjectScanAst
namespace ObjectScanCustody
open ObjectScanAst
set_option maxRecDepth 10000
set_option maxHeartbeats 2000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem forwardPreserves (q : State) (h : Safe q) (g : forwardGuard q) : Safe (forwardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,forwardGuard,forwardNext] <;> omega
theorem initializeCopyPreserves (q : State) (h : Safe q) (g : initializeCopyGuard q) : Safe (initializeCopyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,initializeCopyGuard,initializeCopyNext] <;> omega
theorem publishReadyPreserves (q : State) (h : Safe q) (g : publishReadyGuard q) : Safe (publishReadyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,publishReadyGuard,publishReadyNext] <;> omega
theorem publishBatchPreserves (q : State) (h : Safe q) (g : publishBatchGuard q) : Safe (publishBatchNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,publishBatchGuard,publishBatchNext] <;> omega
theorem duplicateTaskPreserves (q : State) (h : Safe q) (g : duplicateTaskGuard q) : Safe (duplicateTaskNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,duplicateTaskGuard,duplicateTaskNext] <;> omega
theorem closeInputsPreserves (q : State) (h : Safe q) (g : closeInputsGuard q) : Safe (closeInputsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,closeInputsGuard,closeInputsNext] <;> omega
theorem finishTailPreserves (q : State) (h : Safe q) (g : finishTailGuard q) : Safe (finishTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,finishTailGuard,finishTailNext] <;> omega
theorem claim0Preserves (q : State) (h : Safe q) (g : claim0Guard q) : Safe (claim0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,claim0Guard,claim0Next] <;> omega
theorem claim1Preserves (q : State) (h : Safe q) (g : claim1Guard q) : Safe (claim1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,claim1Guard,claim1Next] <;> omega
theorem own0Preserves (q : State) (h : Safe q) (g : own0Guard q) : Safe (own0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,own0Guard,own0Next] <;> omega
theorem own1Preserves (q : State) (h : Safe q) (g : own1Guard q) : Safe (own1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,own1Guard,own1Next] <;> omega
theorem skip0Preserves (q : State) (h : Safe q) (g : skip0Guard q) : Safe (skip0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,skip0Guard,skip0Next] <;> omega
theorem skip1Preserves (q : State) (h : Safe q) (g : skip1Guard q) : Safe (skip1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,skip1Guard,skip1Next] <;> omega
theorem done0Preserves (q : State) (h : Safe q) (g : done0Guard q) : Safe (done0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,done0Guard,done0Next] <;> omega
theorem done1Preserves (q : State) (h : Safe q) (g : done1Guard q) : Safe (done1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,done1Guard,done1Next] <;> omega
theorem drain0Preserves (q : State) (h : Safe q) (g : drain0Guard q) : Safe (drain0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,drain0Guard,drain0Next] <;> omega
theorem drain1Preserves (q : State) (h : Safe q) (g : drain1Guard q) : Safe (drain1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,drain1Guard,drain1Next] <;> omega
theorem idle0Preserves (q : State) (h : Safe q) (g : idle0Guard q) : Safe (idle0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,idle0Guard,idle0Next] <;> omega
theorem idle1Preserves (q : State) (h : Safe q) (g : idle1Guard q) : Safe (idle1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,idle1Guard,idle1Next] <;> omega
theorem terminatePreserves (q : State) (h : Safe q) (g : terminateGuard q) : Safe (terminateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [Safe,terminateGuard,terminateNext] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20
 · rcases a0 with ⟨g,rfl⟩; exact forwardPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact initializeCopyPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact publishReadyPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact publishBatchPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact duplicateTaskPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact closeInputsPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact finishTailPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact claim0Preserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact claim1Preserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact own0Preserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact own1Preserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact skip0Preserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact skip1Preserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact done0Preserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact done1Preserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact drain0Preserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact drain1Preserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact idle0Preserves q h g
 · rcases a18 with ⟨g,rfl⟩; exact idle1Preserves q h g
 · rcases a19 with ⟨g,rfl⟩; exact terminatePreserves q h g
 · simpa [a20] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem noTwoOwners (q : State) (h : Safe q) : ¬(q.t0=3 ∧ q.t1=3) := by
 simp_all [Safe]; omega
theorem duplicatePreservesOwner (q : State) : (skip0Next q).owner=q.owner ∧ (skip0Next q).child1=q.child1 := ⟨rfl,rfl⟩
theorem doneRetainsTail (q : State) : (done1Next q).tail=q.tail ∧ (done1Next q).child1=q.child1 := ⟨rfl,rfl⟩
def doneWithTail : State := {phase:=3,owner:= -1,t0:=1,t1:=4,payload:=true,forwarded:=true,copier:=true,tail:=true,privateChunk:=false,child0:=false,child1:=true,active0:=true,active1:=true,closed:=true,terminated:=false}
theorem doneNotGlobalClosure : Safe doneWithTail ∧ doneWithTail.phase=3 ∧ doneWithTail.tail=true ∧ doneWithTail.child1=true := by simp [Safe,doneWithTail]
theorem finalZeroImpliesNoDebt (q : State) (h : Safe q) (g : terminateGuard q) : q.phase=3 ∧ q.tail=false ∧ q.child0=false ∧ q.child1=false := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22⟩
 simp_all [terminateGuard]; omega
end ObjectScanCustody
