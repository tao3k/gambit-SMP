import NodePoolAst
namespace NodePool
open NodePoolAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
set_option linter.unusedSimpArgs false
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem admitPreserves (q : State) (h : Safe q) (g : admitGuard q) : Safe (admitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 rcases g with ⟨gp,gc⟩
 rcases h21 (Or.inl gp) with ⟨zi,za⟩
 have zprivateNodes : q.privateNodes=0 := by omega
 have zsealedNodes : q.sealedNodes=0 := by omega
 have zqueued : q.queued=0 := by omega
 have zowned : q.owned=0 := by omega
 have zdone : q.done=0 := by omega
 have zdebt : q.debt=0 := by omega
 have zreceipts : q.receipts=0 := by omega
 simp_all [Safe,admitGuard,admitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectPreserves (q : State) (h : Safe q) (g : rejectGuard q) : Safe (rejectNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 rcases g with ⟨gp,gc⟩
 rcases h21 (Or.inl gp) with ⟨zi,za⟩
 have zprivateNodes : q.privateNodes=0 := by omega
 have zsealedNodes : q.sealedNodes=0 := by omega
 have zqueued : q.queued=0 := by omega
 have zowned : q.owned=0 := by omega
 have zdone : q.done=0 := by omega
 have zdebt : q.debt=0 := by omega
 have zreceipts : q.receipts=0 := by omega
 simp_all [Safe,rejectGuard,rejectNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reservePreserves (q : State) (h : Safe q) (g : reserveGuard q) : Safe (reserveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,reserveGuard,reserveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem derivePreserves (q : State) (h : Safe q) (g : deriveGuard q) : Safe (deriveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,deriveGuard,deriveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealPreserves (q : State) (h : Safe q) (g : sealGuard q) : Safe (sealNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,sealGuard,sealNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishPreserves (q : State) (h : Safe q) (g : publishGuard q) : Safe (publishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,publishGuard,publishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem claimPreserves (q : State) (h : Safe q) (g : claimGuard q) : Safe (claimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,claimGuard,claimNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem finishPreserves (q : State) (h : Safe q) (g : finishGuard q) : Safe (finishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,finishGuard,finishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observePreserves (q : State) (h : Safe q) (g : observeGuard q) : Safe (observeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,observeGuard,observeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowPreserves (q : State) (h : Safe q) (g : borrowGuard q) : Safe (borrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,borrowGuard,borrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBorrowPreserves (q : State) (h : Safe q) (g : returnBorrowGuard q) : Safe (returnBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,returnBorrowGuard,returnBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeRootsPreserves (q : State) (h : Safe q) (g : closeRootsGuard q) : Safe (closeRootsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeRootsGuard,closeRootsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem completePreserves (q : State) (h : Safe q) (g : completeGuard q) : Safe (completeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,completeGuard,completeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeUsersPreserves (q : State) (h : Safe q) (g : closeUsersGuard q) : Safe (closeUsersNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeUsersGuard,closeUsersNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem detachHeadPreserves (q : State) (h : Safe q) (g : detachHeadGuard q) : Safe (detachHeadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,detachHeadGuard,detachHeadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem certifyPreserves (q : State) (h : Safe q) (g : certifyGuard q) : Safe (certifyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,certifyGuard,certifyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reclaimPreserves (q : State) (h : Safe q) (g : reclaimGuard q) : Safe (reclaimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,reclaimGuard,reclaimNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17
 · rcases a0 with ⟨g,rfl⟩; exact admitPreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact rejectPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact reservePreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact derivePreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact sealPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact publishPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact claimPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact finishPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact observePreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact borrowPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact returnBorrowPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact closeRootsPreserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact completePreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact closeUsersPreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact detachHeadPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact certifyPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact reclaimPreserves q h g
 · rw [a17]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem permittedReserveHasSpace (q : State) (h : Safe q) (g : reserveGuard q) : q.issued < q.capacity := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [reserveGuard] <;> omega
theorem permittedChildHasSpace (q : State) (h : Safe q) (g : deriveGuard q) : q.issued < q.capacity := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [deriveGuard] <;> omega
theorem conservation (q : State) (h : Safe q) : q.issued=q.done+q.debt := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 omega
theorem publicationDoesNotAllocate (q : State) : (publishNext q).issued=q.issued ∧ (publishNext q).debt=q.debt := by simp [publishNext]
theorem receiptExcludesUsers (q : State) (h : Safe q) (g : q.phase=3) : q.debt=0 ∧ q.receipts=0 ∧ q.borrowers=0 ∧ q.headAttached=false ∧ q.usersClosed=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all <;> omega
def drainRank (q : State) : Int := 4*q.privateNodes+3*q.sealedNodes+2*q.queued+q.owned
theorem drainAvailable (q : State) (h : Safe q) (hp : q.phase=1) (hd : q.debt>0) : sealGuard q ∨ publishGuard q ∨ claimGuard q ∨ finishGuard q := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [sealGuard,publishGuard,claimGuard,finishGuard] <;> omega
theorem sealDecreases (q : State) : drainRank (sealNext q)=drainRank q-1 := by simp [drainRank,sealNext]; omega
theorem publishDecreases (q : State) : drainRank (publishNext q)=drainRank q-1 := by simp [drainRank,publishNext]; omega
theorem claimDecreases (q : State) : drainRank (claimNext q)=drainRank q-1 := by simp [drainRank,claimNext]; omega
theorem finishDecreases (q : State) : drainRank (finishNext q)=drainRank q-1 := by simp [drainRank,finishNext]; omega
theorem rankNonnegative (q : State) (h : Safe q) : drainRank q>=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp [drainRank]; omega
 -- Physical injectivity / threshold charging are premises, not derived from C.
theorem coarseCapacity (issued closed words workers : Int) (h : issued<=closed+workers) (inj : closed<=words) : issued<=words+workers := by omega
theorem chargedCapacity (issued threshold visits workers words : Int) (h : issued<=threshold+visits+workers) (charge : 255*threshold<=words) : 255*issued<=words+255*(visits+workers) := by omega
theorem noDrainReleasesCapacity (q : State) : (finishNext q).issued=q.issued := by rfl
theorem fullRetainedPool : let q := {initial with phase:=2,admitted:=true,issued:=3,done:=3,rootsClosed:=true,receipts:=3}; Safe q ∧ q.debt=0 ∧ q.issued=q.capacity ∧ q.headAttached=true := by simp [Safe,initial]

-- Import retained strong-phase storage instead of resetting its allocation count.
def weakEntry (capacity budget retained receiptCount borrowerCount : Int) : State :=
 {initial with phase:=1,capacity:=capacity,budget:=budget,issued:=retained,done:=retained,receipts:=receiptCount,borrowers:=borrowerCount,admitted:=true}
theorem weakEntrySafe (capacity budget retained receiptCount borrowerCount : Int)
 (hd : 0<=retained) (hb : retained<=budget) (hc : budget<=capacity)
 (hr : 0<=receiptCount ∧ receiptCount<=retained) (hp : 0<=borrowerCount) :
 Safe (weakEntry capacity budget retained receiptCount borrowerCount) := by
 simp [Safe,weakEntry,initial]
 omega
inductive RunsFrom (base : State) : State → Prop where
 | start : RunsFrom base base
 | next {q r} : RunsFrom base q → Step q r → RunsFrom base r
theorem runsFromSafe (base q : State) (hb : Safe base) (h : RunsFrom base q) : Safe q := by
 induction h with
 | start => exact hb
 | next _ st ih => exact stepPreserves _ _ ih st
end NodePool

