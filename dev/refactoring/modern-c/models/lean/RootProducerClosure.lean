namespace RootProducerClosure
-- Physical slots, not object values, define the quotient. Stable address/generation is assumed.
def Covered (occurrences canonical : List Nat) : Prop := ∀ slot, slot ∈ occurrences ↔ slot ∈ canonical
theorem aliasCoverage : Covered [0,1,0] [0,1] := by intro slot; simp [or_comm]
theorem valueDedupLosesSlot : ¬ Covered [0,1] [0] := by
 intro h
 have bad := (h 1).mp (by simp)
 simp at bad
theorem rewriteCoverage (occurrences canonical : List Nat) (h : Covered occurrences canonical)
 (updated : Nat → Prop) (all : ∀ s, s ∈ canonical → updated s) : ∀ s, s ∈ occurrences → updated s := by
 intro s member
 exact all s ((h s).mp member)
-- Nontrivial coverage premise: an exhaustive disjoint family of slot sets has a unique owner.
theorem uniqueOwner (slots : Nat → Nat → Prop) (total : ∀ s, ∃ w, slots w s)
 (disjoint : ∀ a b s, slots a s → slots b s → a=b) (s : Nat) : ∃ w, slots w s ∧ ∀ y, slots y s → y=w := by
 obtain ⟨w,hw⟩ := total s
 exact ⟨w,hw,fun y hy => disjoint y w s hy hw⟩
structure State where
 producer : Bool
 copying : Bool
 initialized : Bool
 tail : Bool
 privateChunk : Bool
 queued : Bool
 claimed : Bool
 scanned : Bool
 consumer : Bool
 deriving DecidableEq
def Safe (s : State) : Prop :=
 ((s.copying=true ∨ s.tail=true ∨ s.privateChunk=true) → s.producer=true) ∧
 ((s.queued=true ∨ s.claimed=true ∨ s.scanned=true) → s.initialized=true) ∧
 (s.claimed=true → s.consumer=true) ∧ ¬(s.queued=true ∧ s.claimed=true)
def publishGuard (s : State) : Prop := s.producer=true ∧ s.initialized=true ∧ s.privateChunk=true ∧ ¬s.claimed=true
def publishNext (s : State) : State := {s with privateChunk:=false,queued:=true}
def claimGuard (s : State) : Prop := s.consumer=true ∧ s.queued=true ∧ ¬s.claimed=true
def claimNext (s : State) : State := {s with queued:=false,claimed:=true}
def idleGuard (s : State) : Prop := s.initialized=true ∧ ¬s.copying=true ∧ ¬s.tail=true ∧ ¬s.privateChunk=true
def idleNext (s : State) : State := {s with producer:=false}
theorem publishPreserves (s : State) (h : Safe s) (g : publishGuard s) : Safe (publishNext s) := by
 rcases h with ⟨a,b,c,d⟩; rcases g with ⟨p,i,v,n⟩
 simp_all [Safe,publishNext]
theorem claimPreserves (s : State) (h : Safe s) (g : claimGuard s) : Safe (claimNext s) := by
 rcases h with ⟨a,b,c,d⟩; rcases g with ⟨co,q,n⟩
 simp_all [Safe,claimNext]
theorem idlePreserves (s : State) (h : Safe s) (g : idleGuard s) : Safe (idleNext s) := by
 rcases h with ⟨a,b,c,d⟩; rcases g with ⟨i,cp,t,v⟩
 simp_all [Safe,idleNext]
theorem tailBlocksIdle (s : State) (t : s.tail=true) : ¬idleGuard s := by simp [idleGuard,t]
theorem privateBlocksIdle (s : State) (t : s.privateChunk=true) : ¬idleGuard s := by simp [idleGuard,t]
theorem uninitializedBlocksPublish (s : State) (t : s.initialized=false) : ¬publishGuard s := by simp [publishGuard,t]
theorem claimTransfersCustody (s : State) : (claimNext s).queued=false ∧ (claimNext s).claimed=true := ⟨rfl,rfl⟩
-- Manual semantic mirror. Extraction from actual Quint typed IR and C11 simulation remain open.
end RootProducerClosure
