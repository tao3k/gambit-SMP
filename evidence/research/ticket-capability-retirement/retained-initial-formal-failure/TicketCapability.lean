import TicketCapabilityAst
namespace TicketCapability
open TicketCapabilityAst
set_option maxHeartbeats 6000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserve0Preserves (q : State) (h : Safe q) (g : reserve0Guard q) : Safe (reserve0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,reserve0Guard,reserve0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enter0Preserves (q : State) (h : Safe q) (g : enter0Guard q) : Safe (enter0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,enter0Guard,enter0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeSuccess0Preserves (q : State) (h : Safe q) (g : observeSuccess0Guard q) : Safe (observeSuccess0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,observeSuccess0Guard,observeSuccess0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeFailure0Preserves (q : State) (h : Safe q) (g : observeFailure0Guard q) : Safe (observeFailure0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,observeFailure0Guard,observeFailure0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commit0Preserves (q : State) (h : Safe q) (g : commit0Guard q) : Safe (commit0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,commit0Guard,commit0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem query0Preserves (q : State) (h : Safe q) (g : query0Guard q) : Safe (query0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,query0Guard,query0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryPending0Preserves (q : State) (h : Safe q) (g : queryPending0Guard q) : Safe (queryPending0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,queryPending0Guard,queryPending0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem conflictingSettle0Preserves (q : State) (h : Safe q) (g : conflictingSettle0Guard q) : Safe (conflictingSettle0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,conflictingSettle0Guard,conflictingSettle0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem loseReply0Preserves (q : State) (h : Safe q) (g : loseReply0Guard q) : Safe (loseReply0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,loseReply0Guard,loseReply0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainTombstone0Preserves (q : State) (h : Safe q) (g : retainTombstone0Guard q) : Safe (retainTombstone0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,retainTombstone0Guard,retainTombstone0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserve1Preserves (q : State) (h : Safe q) (g : reserve1Guard q) : Safe (reserve1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,reserve1Guard,reserve1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem enter1Preserves (q : State) (h : Safe q) (g : enter1Guard q) : Safe (enter1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,enter1Guard,enter1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeSuccess1Preserves (q : State) (h : Safe q) (g : observeSuccess1Guard q) : Safe (observeSuccess1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,observeSuccess1Guard,observeSuccess1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeFailure1Preserves (q : State) (h : Safe q) (g : observeFailure1Guard q) : Safe (observeFailure1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,observeFailure1Guard,observeFailure1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commit1Preserves (q : State) (h : Safe q) (g : commit1Guard q) : Safe (commit1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,commit1Guard,commit1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem query1Preserves (q : State) (h : Safe q) (g : query1Guard q) : Safe (query1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,query1Guard,query1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem queryPending1Preserves (q : State) (h : Safe q) (g : queryPending1Guard q) : Safe (queryPending1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,queryPending1Guard,queryPending1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem conflictingSettle1Preserves (q : State) (h : Safe q) (g : conflictingSettle1Guard q) : Safe (conflictingSettle1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,conflictingSettle1Guard,conflictingSettle1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem loseReply1Preserves (q : State) (h : Safe q) (g : loseReply1Guard q) : Safe (loseReply1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,loseReply1Guard,loseReply1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retainTombstone1Preserves (q : State) (h : Safe q) (g : retainTombstone1Guard q) : Safe (retainTombstone1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,retainTombstone1Guard,retainTombstone1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cloneHandle1Preserves (q : State) (h : Safe q) (g : cloneHandle1Guard q) : Safe (cloneHandle1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,cloneHandle1Guard,cloneHandle1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dropHandle0Preserves (q : State) (h : Safe q) (g : dropHandle0Guard q) : Safe (dropHandle0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,dropHandle0Guard,dropHandle0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dropHandle1Preserves (q : State) (h : Safe q) (g : dropHandle1Guard q) : Safe (dropHandle1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,dropHandle1Guard,dropHandle1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem duplicateDrop0Preserves (q : State) (h : Safe q) (g : duplicateDrop0Guard q) : Safe (duplicateDrop0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,duplicateDrop0Guard,duplicateDrop0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowNative0Preserves (q : State) (h : Safe q) (g : borrowNative0Guard q) : Safe (borrowNative0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,borrowNative0Guard,borrowNative0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnNative0Preserves (q : State) (h : Safe q) (g : returnNative0Guard q) : Safe (returnNative0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,returnNative0Guard,returnNative0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowNative1Preserves (q : State) (h : Safe q) (g : borrowNative1Guard q) : Safe (borrowNative1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,borrowNative1Guard,borrowNative1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnNative1Preserves (q : State) (h : Safe q) (g : returnNative1Guard q) : Safe (returnNative1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,returnNative1Guard,returnNative1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem duplicateNativeReturn0Preserves (q : State) (h : Safe q) (g : duplicateNativeReturn0Guard q) : Safe (duplicateNativeReturn0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,duplicateNativeReturn0Guard,duplicateNativeReturn0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeCapabilityPreserves (q : State) (h : Safe q) (g : closeCapabilityGuard q) : Safe (closeCapabilityNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,closeCapabilityGuard,closeCapabilityNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem discoverRawEscapePreserves (q : State) (h : Safe q) (g : discoverRawEscapeGuard q) : Safe (discoverRawEscapeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,discoverRawEscapeGuard,discoverRawEscapeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestAliasCensusPreserves (q : State) (h : Safe q) (g : attestAliasCensusGuard q) : Safe (attestAliasCensusNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,attestAliasCensusGuard,attestAliasCensusNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem attestRootMapsPreserves (q : State) (h : Safe q) (g : attestRootMapsGuard q) : Safe (attestRootMapsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,attestRootMapsGuard,attestRootMapsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAuthorityPreserves (q : State) (h : Safe q) (g : closeAuthorityGuard q) : Safe (closeAuthorityNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,closeAuthorityGuard,closeAuthorityNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pinScanner0Preserves (q : State) (h : Safe q) (g : pinScanner0Guard q) : Safe (pinScanner0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,pinScanner0Guard,pinScanner0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unpinScanner0Preserves (q : State) (h : Safe q) (g : unpinScanner0Guard q) : Safe (unpinScanner0Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,unpinScanner0Guard,unpinScanner0Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem pinScanner1Preserves (q : State) (h : Safe q) (g : pinScanner1Guard q) : Safe (pinScanner1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,pinScanner1Guard,pinScanner1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unpinScanner1Preserves (q : State) (h : Safe q) (g : unpinScanner1Guard q) : Safe (unpinScanner1Next q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,unpinScanner1Guard,unpinScanner1Next] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeMaintenancePreserves (q : State) (h : Safe q) (g : closeMaintenanceGuard q) : Safe (closeMaintenanceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,closeMaintenanceGuard,closeMaintenanceNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retireRootPreserves (q : State) (h : Safe q) (g : retireRootGuard q) : Safe (retireRootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,retireRootGuard,retireRootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem selectStaleGenerationPreserves (q : State) (h : Safe q) (g : selectStaleGenerationGuard q) : Safe (selectStaleGenerationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,selectStaleGenerationGuard,selectStaleGenerationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem selectCurrentGenerationPreserves (q : State) (h : Safe q) (g : selectCurrentGenerationGuard q) : Safe (selectCurrentGenerationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,selectCurrentGenerationGuard,selectCurrentGenerationNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectStaleRequestPreserves (q : State) (h : Safe q) (g : rejectStaleRequestGuard q) : Safe (rejectStaleRequestNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39⟩
 cases c : q.rootRetired <;> simp_all [Safe,rejectStaleRequestGuard,rejectStaleRequestNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (g : Step q r) : Safe r := by
 rcases g with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28 | h29 | h30 | h31 | h32 | h33 | h34 | h35 | h36 | h37 | h38 | h39 | h40 | h41 | h42 | h43
 · rcases h0 with ⟨g,e⟩; rw [e]; exact reserve0Preserves q h g
 · rcases h1 with ⟨g,e⟩; rw [e]; exact enter0Preserves q h g
 · rcases h2 with ⟨g,e⟩; rw [e]; exact observeSuccess0Preserves q h g
 · rcases h3 with ⟨g,e⟩; rw [e]; exact observeFailure0Preserves q h g
 · rcases h4 with ⟨g,e⟩; rw [e]; exact commit0Preserves q h g
 · rcases h5 with ⟨g,e⟩; rw [e]; exact query0Preserves q h g
 · rcases h6 with ⟨g,e⟩; rw [e]; exact queryPending0Preserves q h g
 · rcases h7 with ⟨g,e⟩; rw [e]; exact conflictingSettle0Preserves q h g
 · rcases h8 with ⟨g,e⟩; rw [e]; exact loseReply0Preserves q h g
 · rcases h9 with ⟨g,e⟩; rw [e]; exact retainTombstone0Preserves q h g
 · rcases h10 with ⟨g,e⟩; rw [e]; exact reserve1Preserves q h g
 · rcases h11 with ⟨g,e⟩; rw [e]; exact enter1Preserves q h g
 · rcases h12 with ⟨g,e⟩; rw [e]; exact observeSuccess1Preserves q h g
 · rcases h13 with ⟨g,e⟩; rw [e]; exact observeFailure1Preserves q h g
 · rcases h14 with ⟨g,e⟩; rw [e]; exact commit1Preserves q h g
 · rcases h15 with ⟨g,e⟩; rw [e]; exact query1Preserves q h g
 · rcases h16 with ⟨g,e⟩; rw [e]; exact queryPending1Preserves q h g
 · rcases h17 with ⟨g,e⟩; rw [e]; exact conflictingSettle1Preserves q h g
 · rcases h18 with ⟨g,e⟩; rw [e]; exact loseReply1Preserves q h g
 · rcases h19 with ⟨g,e⟩; rw [e]; exact retainTombstone1Preserves q h g
 · rcases h20 with ⟨g,e⟩; rw [e]; exact cloneHandle1Preserves q h g
 · rcases h21 with ⟨g,e⟩; rw [e]; exact dropHandle0Preserves q h g
 · rcases h22 with ⟨g,e⟩; rw [e]; exact dropHandle1Preserves q h g
 · rcases h23 with ⟨g,e⟩; rw [e]; exact duplicateDrop0Preserves q h g
 · rcases h24 with ⟨g,e⟩; rw [e]; exact borrowNative0Preserves q h g
 · rcases h25 with ⟨g,e⟩; rw [e]; exact returnNative0Preserves q h g
 · rcases h26 with ⟨g,e⟩; rw [e]; exact borrowNative1Preserves q h g
 · rcases h27 with ⟨g,e⟩; rw [e]; exact returnNative1Preserves q h g
 · rcases h28 with ⟨g,e⟩; rw [e]; exact duplicateNativeReturn0Preserves q h g
 · rcases h29 with ⟨g,e⟩; rw [e]; exact closeCapabilityPreserves q h g
 · rcases h30 with ⟨g,e⟩; rw [e]; exact discoverRawEscapePreserves q h g
 · rcases h31 with ⟨g,e⟩; rw [e]; exact attestAliasCensusPreserves q h g
 · rcases h32 with ⟨g,e⟩; rw [e]; exact attestRootMapsPreserves q h g
 · rcases h33 with ⟨g,e⟩; rw [e]; exact closeAuthorityPreserves q h g
 · rcases h34 with ⟨g,e⟩; rw [e]; exact pinScanner0Preserves q h g
 · rcases h35 with ⟨g,e⟩; rw [e]; exact unpinScanner0Preserves q h g
 · rcases h36 with ⟨g,e⟩; rw [e]; exact pinScanner1Preserves q h g
 · rcases h37 with ⟨g,e⟩; rw [e]; exact unpinScanner1Preserves q h g
 · rcases h38 with ⟨g,e⟩; rw [e]; exact closeMaintenancePreserves q h g
 · rcases h39 with ⟨g,e⟩; rw [e]; exact retireRootPreserves q h g
 · rcases h40 with ⟨g,e⟩; rw [e]; exact selectStaleGenerationPreserves q h g
 · rcases h41 with ⟨g,e⟩; rw [e]; exact selectCurrentGenerationPreserves q h g
 · rcases h42 with ⟨g,e⟩; rw [e]; exact rejectStaleRequestPreserves q h g
 · rw [h43]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ edge ih => exact stepPreserves _ _ ih edge
theorem atMostOnce0 (q : State) (h : Safe q) : q.t0settles≤1 ∧ q.t0enters≤1 := by simp_all [Safe]
theorem terminal0Stable (q r : State) (h : Safe q) (p : q.t0phase≥3) (g : Step q r) : r.t0outcome=q.t0outcome ∧ r.t0settles=q.t0settles ∧ r.t0phase≥3 := by
 rcases g with e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e
 all_goals simp_all [Step,reserve0Guard,reserve0Next,enter0Guard,enter0Next,observeSuccess0Guard,observeSuccess0Next,observeFailure0Guard,observeFailure0Next,commit0Guard,commit0Next,query0Guard,query0Next,queryPending0Guard,queryPending0Next,conflictingSettle0Guard,conflictingSettle0Next,loseReply0Guard,loseReply0Next,retainTombstone0Guard,retainTombstone0Next,reserve1Guard,reserve1Next,enter1Guard,enter1Next,observeSuccess1Guard,observeSuccess1Next,observeFailure1Guard,observeFailure1Next,commit1Guard,commit1Next,query1Guard,query1Next,queryPending1Guard,queryPending1Next,conflictingSettle1Guard,conflictingSettle1Next,loseReply1Guard,loseReply1Next,retainTombstone1Guard,retainTombstone1Next,cloneHandle1Guard,cloneHandle1Next,dropHandle0Guard,dropHandle0Next,dropHandle1Guard,dropHandle1Next,duplicateDrop0Guard,duplicateDrop0Next,borrowNative0Guard,borrowNative0Next,returnNative0Guard,returnNative0Next,borrowNative1Guard,borrowNative1Next,returnNative1Guard,returnNative1Next,duplicateNativeReturn0Guard,duplicateNativeReturn0Next,closeCapabilityGuard,closeCapabilityNext,discoverRawEscapeGuard,discoverRawEscapeNext,attestAliasCensusGuard,attestAliasCensusNext,attestRootMapsGuard,attestRootMapsNext,closeAuthorityGuard,closeAuthorityNext,pinScanner0Guard,pinScanner0Next,unpinScanner0Guard,unpinScanner0Next,pinScanner1Guard,pinScanner1Next,unpinScanner1Guard,unpinScanner1Next,closeMaintenanceGuard,closeMaintenanceNext,retireRootGuard,retireRootNext,selectStaleGenerationGuard,selectStaleGenerationNext,selectCurrentGenerationGuard,selectCurrentGenerationNext,rejectStaleRequestGuard,rejectStaleRequestNext] <;> omega
theorem atMostOnce1 (q : State) (h : Safe q) : q.t1settles≤1 ∧ q.t1enters≤1 := by simp_all [Safe]
theorem terminal1Stable (q r : State) (h : Safe q) (p : q.t1phase≥3) (g : Step q r) : r.t1outcome=q.t1outcome ∧ r.t1settles=q.t1settles ∧ r.t1phase≥3 := by
 rcases g with e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e | e
 all_goals simp_all [Step,reserve0Guard,reserve0Next,enter0Guard,enter0Next,observeSuccess0Guard,observeSuccess0Next,observeFailure0Guard,observeFailure0Next,commit0Guard,commit0Next,query0Guard,query0Next,queryPending0Guard,queryPending0Next,conflictingSettle0Guard,conflictingSettle0Next,loseReply0Guard,loseReply0Next,retainTombstone0Guard,retainTombstone0Next,reserve1Guard,reserve1Next,enter1Guard,enter1Next,observeSuccess1Guard,observeSuccess1Next,observeFailure1Guard,observeFailure1Next,commit1Guard,commit1Next,query1Guard,query1Next,queryPending1Guard,queryPending1Next,conflictingSettle1Guard,conflictingSettle1Next,loseReply1Guard,loseReply1Next,retainTombstone1Guard,retainTombstone1Next,cloneHandle1Guard,cloneHandle1Next,dropHandle0Guard,dropHandle0Next,dropHandle1Guard,dropHandle1Next,duplicateDrop0Guard,duplicateDrop0Next,borrowNative0Guard,borrowNative0Next,returnNative0Guard,returnNative0Next,borrowNative1Guard,borrowNative1Next,returnNative1Guard,returnNative1Next,duplicateNativeReturn0Guard,duplicateNativeReturn0Next,closeCapabilityGuard,closeCapabilityNext,discoverRawEscapeGuard,discoverRawEscapeNext,attestAliasCensusGuard,attestAliasCensusNext,attestRootMapsGuard,attestRootMapsNext,closeAuthorityGuard,closeAuthorityNext,pinScanner0Guard,pinScanner0Next,unpinScanner0Guard,unpinScanner0Next,pinScanner1Guard,pinScanner1Next,unpinScanner1Guard,unpinScanner1Next,closeMaintenanceGuard,closeMaintenanceNext,retireRootGuard,retireRootNext,selectStaleGenerationGuard,selectStaleGenerationNext,selectCurrentGenerationGuard,selectCurrentGenerationNext,rejectStaleRequestGuard,rejectStaleRequestNext] <;> omega
theorem authorityNeedsNoActive (q : State) (h : Safe q) (c : q.cap=3) : (q.t0phase=0 ∨ q.t0phase≥3) ∧ (q.t1phase=0 ∨ q.t1phase≥3) := by simp_all [Safe]
theorem rootNeedsScannerDrain (q : State) (h : Safe q) (r : q.rootRetired=true) : q.s0open=false ∧ q.s1open=false := by simp_all [Safe]
theorem duplicateDropDoesNotDropOther (q : State) : (duplicateDrop0Next q).h1open=q.h1open := by rfl
theorem duplicateNativeReturnDoesNotDropOther (q : State) : (duplicateNativeReturn0Next q).b1open=q.b1open := by rfl
theorem queryDoesNotExecute (q : State) : (query0Next q).t0enters=q.t0enters := by rfl
theorem rootBlocksRawEscape (q : State) (h : Safe q) (r : q.rootRetired=true) : q.rawEscape=false := by simp_all [Safe]
theorem staleCannotReserve (q : State) (old : q.messageGeneration≠7) : ¬reserve0Guard q := by simp_all [reserve0Guard]
theorem staleCannotDrop (q : State) (old : q.messageGeneration≠7) : ¬dropHandle0Guard q := by simp_all [dropHandle0Guard]
theorem staleCannotReturnBorrow (q : State) (old : q.messageGeneration≠7) : ¬returnNative0Guard q := by simp_all [returnNative0Guard]
end TicketCapability
