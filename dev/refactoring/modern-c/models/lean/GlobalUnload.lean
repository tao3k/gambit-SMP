import GlobalUnloadAst
namespace GlobalUnload
open GlobalUnloadAst
set_option maxHeartbeats 8000000
set_option maxRecDepth 14000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem borrow0Preserves (q : State) (h : Safe q) (g : borrow0Guard q) : Safe (borrow0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,borrow0Guard,borrow0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrow1Preserves (q : State) (h : Safe q) (g : borrow1Guard q) : Safe (borrow1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,borrow1Guard,borrow1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observePreserves (q : State) (h : Safe q) (g : observeGuard q) : Safe (observeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,observeGuard,observeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeGlobalPreserves (q : State) (h : Safe q) (g : closeGlobalGuard q) : Safe (closeGlobalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeGlobalGuard,closeGlobalNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeLocal0Preserves (q : State) (h : Safe q) (g : closeLocal0Guard q) : Safe (closeLocal0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeLocal0Guard,closeLocal0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeLocal1Preserves (q : State) (h : Safe q) (g : closeLocal1Guard q) : Safe (closeLocal1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeLocal1Guard,closeLocal1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem return0Preserves (q : State) (h : Safe q) (g : return0Guard q) : Safe (return0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,return0Guard,return0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem return1Preserves (q : State) (h : Safe q) (g : return1Guard q) : Safe (return1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,return1Guard,return1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issueLocal0Preserves (q : State) (h : Safe q) (g : issueLocal0Guard q) : Safe (issueLocal0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,issueLocal0Guard,issueLocal0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issueLocal1Preserves (q : State) (h : Safe q) (g : issueLocal1Guard q) : Safe (issueLocal1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,issueLocal1Guard,issueLocal1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deliver0Preserves (q : State) (h : Safe q) (g : deliver0Guard q) : Safe (deliver0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,deliver0Guard,deliver0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem deliver1Preserves (q : State) (h : Safe q) (g : deliver1Guard q) : Safe (deliver1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,deliver1Guard,deliver1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStalePreserves (q : State) (h : Safe q) (g : rejectStaleGuard q) : Safe (rejectStaleNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,rejectStaleGuard,rejectStaleNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLatePreserves (q : State) (h : Safe q) (g : rejectLateGuard q) : Safe (rejectLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,rejectLateGuard,rejectLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativeBorrowPreserves (q : State) (h : Safe q) (g : nativeBorrowGuard q) : Safe (nativeBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,nativeBorrowGuard,nativeBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativeReturnPreserves (q : State) (h : Safe q) (g : nativeReturnGuard q) : Safe (nativeReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,nativeReturnGuard,nativeReturnNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownNativePreserves (q : State) (h : Safe q) (g : unknownNativeGuard q) : Safe (unknownNativeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,unknownNativeGuard,unknownNativeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observerRetirePreserves (q : State) (h : Safe q) (g : observerRetireGuard q) : Safe (observerRetireNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,observerRetireGuard,observerRetireNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginChildPreserves (q : State) (h : Safe q) (g : beginChildGuard q) : Safe (beginChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,beginChildGuard,beginChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitChildPreserves (q : State) (h : Safe q) (g : commitChildGuard q) : Safe (commitChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,commitChildGuard,commitChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectChildPreserves (q : State) (h : Safe q) (g : rejectChildGuard q) : Safe (rejectChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,rejectChildGuard,rejectChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownChildPreserves (q : State) (h : Safe q) (g : unknownChildGuard q) : Safe (unknownChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,unknownChildGuard,unknownChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem taskDonePreserves (q : State) (h : Safe q) (g : taskDoneGuard q) : Safe (taskDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,taskDoneGuard,taskDoneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem permitPreserves (q : State) (h : Safe q) (g : permitGuard q) : Safe (permitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,permitGuard,permitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginUnloadPreserves (q : State) (h : Safe q) (g : beginUnloadGuard q) : Safe (beginUnloadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,beginUnloadGuard,beginUnloadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeKnownPreserves (q : State) (h : Safe q) (g : closeKnownGuard q) : Safe (closeKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeKnownGuard,closeKnownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeUnknownPreserves (q : State) (h : Safe q) (g : closeUnknownGuard q) : Safe (closeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,closeUnknownGuard,closeUnknownNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectIncompletePreserves (q : State) (h : Safe q) (g : rejectIncompleteGuard q) : Safe (rejectIncompleteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all [Safe,rejectIncompleteGuard,rejectIncompleteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20 | a21 | a22 | a23 | a24 | a25 | a26 | a27 | a28
 · rcases a0 with ⟨g,rfl⟩; exact borrow0Preserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact borrow1Preserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact observePreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact closeGlobalPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact closeLocal0Preserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact closeLocal1Preserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact return0Preserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact return1Preserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact issueLocal0Preserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact issueLocal1Preserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact deliver0Preserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact deliver1Preserves q h g
 · rcases a12 with ⟨g,rfl⟩; exact rejectStalePreserves q h g
 · rcases a13 with ⟨g,rfl⟩; exact rejectLatePreserves q h g
 · rcases a14 with ⟨g,rfl⟩; exact nativeBorrowPreserves q h g
 · rcases a15 with ⟨g,rfl⟩; exact nativeReturnPreserves q h g
 · rcases a16 with ⟨g,rfl⟩; exact unknownNativePreserves q h g
 · rcases a17 with ⟨g,rfl⟩; exact observerRetirePreserves q h g
 · rcases a18 with ⟨g,rfl⟩; exact beginChildPreserves q h g
 · rcases a19 with ⟨g,rfl⟩; exact commitChildPreserves q h g
 · rcases a20 with ⟨g,rfl⟩; exact rejectChildPreserves q h g
 · rcases a21 with ⟨g,rfl⟩; exact unknownChildPreserves q h g
 · rcases a22 with ⟨g,rfl⟩; exact taskDonePreserves q h g
 · rcases a23 with ⟨g,rfl⟩; exact permitPreserves q h g
 · rcases a24 with ⟨g,rfl⟩; exact beginUnloadPreserves q h g
 · rcases a25 with ⟨g,rfl⟩; exact closeKnownPreserves q h g
 · rcases a26 with ⟨g,rfl⟩; exact closeUnknownPreserves q h g
 · rcases a27 with ⟨g,rfl⟩; exact rejectIncompletePreserves q h g
 · rw [a28]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem permitNeedsAllReceipts (q : State) (h : Safe q) (p : q.phase=2) : q.receipt0=true ∧ q.receipt1=true ∧ q.stamp0=q.epoch ∧ q.stamp1=q.epoch ∧ q.nativeUsers=0 ∧ q.tasks=0 ∧ q.observers=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all <;> omega
theorem duplicateDeliveryIdempotent (q : State) : deliver0Next (deliver0Next q)=deliver0Next q := by simp [deliver0Next]
theorem childTransferConserves (q : State) (g : commitChildGuard q) : (commitChildNext q).users0+(commitChildNext q).tasks=q.users0+q.tasks := by simp_all [commitChildGuard,commitChildNext]
theorem knownCloseKeepsAdmissionsClosed (q : State) : (closeKnownNext q).closed0=q.closed0 ∧ (closeKnownNext q).closed1=q.closed1 := by simp [closeKnownNext]
theorem permitOwnersQuiescent (q : State) (h : Safe q) (p : q.phase=2) : q.users0=0 ∧ q.users1=0 ∧ q.closed0=true ∧ q.closed1=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 simp_all <;> omega
end GlobalUnload
