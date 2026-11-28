import ModuleHandleAst
namespace ModuleHandle
open ModuleHandleAst
set_option maxHeartbeats 8000000
set_option maxRecDepth 14000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem recordLeafPreserves (q : State) (h : Safe q) (g : recordLeafGuard q) : Safe (recordLeafNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,recordLeafGuard,recordLeafNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem recordEdgesPreserves (q : State) (h : Safe q) (g : recordEdgesGuard q) : Safe (recordEdgesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,recordEdgesGuard,recordEdgesNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem declareOpaquePreserves (q : State) (h : Safe q) (g : declareOpaqueGuard q) : Safe (declareOpaqueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,declareOpaqueGuard,declareOpaqueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem qualifyNativePreserves (q : State) (h : Safe q) (g : qualifyNativeGuard q) : Safe (qualifyNativeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,qualifyNativeGuard,qualifyNativeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem sealSpecPreserves (q : State) (h : Safe q) (g : sealSpecGuard q) : Safe (sealSpecNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,sealSpecGuard,sealSpecNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reservePreserves (q : State) (h : Safe q) (g : reserveGuard q) : Safe (reserveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,reserveGuard,reserveNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem protectCandidatePreserves (q : State) (h : Safe q) (g : protectCandidateGuard q) : Safe (protectCandidateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,protectCandidateGuard,protectCandidateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem startEffectsPreserves (q : State) (h : Safe q) (g : startEffectsGuard q) : Safe (startEffectsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,startEffectsGuard,startEffectsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitPreserves (q : State) (h : Safe q) (g : commitGuard q) : Safe (commitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,commitGuard,commitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem acknowledgePreserves (q : State) (h : Safe q) (g : acknowledgeGuard q) : Safe (acknowledgeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,acknowledgeGuard,acknowledgeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retryReplyPreserves (q : State) (h : Safe q) (g : retryReplyGuard q) : Safe (retryReplyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,retryReplyGuard,retryReplyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem dropCandidatePreserves (q : State) (h : Safe q) (g : dropCandidateGuard q) : Safe (dropCandidateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,dropCandidateGuard,dropCandidateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem abortBeforeEffectsPreserves (q : State) (h : Safe q) (g : abortBeforeEffectsGuard q) : Safe (abortBeforeEffectsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,abortBeforeEffectsGuard,abortBeforeEffectsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownReservedPreserves (q : State) (h : Safe q) (g : unknownReservedGuard q) : Safe (unknownReservedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,unknownReservedGuard,unknownReservedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownCommittedPreserves (q : State) (h : Safe q) (g : unknownCommittedGuard q) : Safe (unknownCommittedNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,unknownCommittedGuard,unknownCommittedNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem exposeRawPreserves (q : State) (h : Safe q) (g : exposeRawGuard q) : Safe (exposeRawNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,exposeRawGuard,exposeRawNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem borrowNativePreserves (q : State) (h : Safe q) (g : borrowNativeGuard q) : Safe (borrowNativeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,borrowNativeGuard,borrowNativeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnBorrowPreserves (q : State) (h : Safe q) (g : returnBorrowGuard q) : Safe (returnBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,returnBorrowGuard,returnBorrowNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginNativeInitPreserves (q : State) (h : Safe q) (g : beginNativeInitGuard q) : Safe (beginNativeInitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,beginNativeInitGuard,beginNativeInitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnNativeInitPreserves (q : State) (h : Safe q) (g : returnNativeInitGuard q) : Safe (returnNativeInitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,returnNativeInitGuard,returnNativeInitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginSchemeInitPreserves (q : State) (h : Safe q) (g : beginSchemeInitGuard q) : Safe (beginSchemeInitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,beginSchemeInitGuard,beginSchemeInitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem returnSchemeInitPreserves (q : State) (h : Safe q) (g : returnSchemeInitGuard q) : Safe (returnSchemeInitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,returnSchemeInitGuard,returnSchemeInitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem failInitPreserves (q : State) (h : Safe q) (g : failInitGuard q) : Safe (failInitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,failInitGuard,failInitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem removeAliasPreserves (q : State) (h : Safe q) (g : removeAliasGuard q) : Safe (removeAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,removeAliasGuard,removeAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishAliasPreserves (q : State) (h : Safe q) (g : publishAliasGuard q) : Safe (publishAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,publishAliasGuard,publishAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closePreserves (q : State) (h : Safe q) (g : closeGuard q) : Safe (closeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,closeGuard,closeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem retirePayloadPreserves (q : State) (h : Safe q) (g : retirePayloadGuard q) : Safe (retirePayloadNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,retirePayloadGuard,retirePayloadNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem permitPreserves (q : State) (h : Safe q) (g : permitGuard q) : Safe (permitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,permitGuard,permitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLatePreserves (q : State) (h : Safe q) (g : rejectLateGuard q) : Safe (rejectLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases pr : q.payloadRetired <;> cases rr : q.receipt <;> simp_all [Safe,rejectLateGuard,rejectLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20 | a21 | a22 | a23 | a24 | a25 | a26 | a27 | a28 | a29 | a30
 · rcases a0 with ⟨g,eqn⟩; rw [eqn]; exact recordLeafPreserves q h g
 · rcases a1 with ⟨g,eqn⟩; rw [eqn]; exact recordEdgesPreserves q h g
 · rcases a2 with ⟨g,eqn⟩; rw [eqn]; exact declareOpaquePreserves q h g
 · rcases a3 with ⟨g,eqn⟩; rw [eqn]; exact qualifyNativePreserves q h g
 · rcases a4 with ⟨g,eqn⟩; rw [eqn]; exact sealSpecPreserves q h g
 · rcases a5 with ⟨g,eqn⟩; rw [eqn]; exact reservePreserves q h g
 · rcases a6 with ⟨g,eqn⟩; rw [eqn]; exact protectCandidatePreserves q h g
 · rcases a7 with ⟨g,eqn⟩; rw [eqn]; exact startEffectsPreserves q h g
 · rcases a8 with ⟨g,eqn⟩; rw [eqn]; exact commitPreserves q h g
 · rcases a9 with ⟨g,eqn⟩; rw [eqn]; exact acknowledgePreserves q h g
 · rcases a10 with ⟨g,eqn⟩; rw [eqn]; exact retryReplyPreserves q h g
 · rcases a11 with ⟨g,eqn⟩; rw [eqn]; exact dropCandidatePreserves q h g
 · rcases a12 with ⟨g,eqn⟩; rw [eqn]; exact abortBeforeEffectsPreserves q h g
 · rcases a13 with ⟨g,eqn⟩; rw [eqn]; exact unknownReservedPreserves q h g
 · rcases a14 with ⟨g,eqn⟩; rw [eqn]; exact unknownCommittedPreserves q h g
 · rcases a15 with ⟨g,eqn⟩; rw [eqn]; exact exposeRawPreserves q h g
 · rcases a16 with ⟨g,eqn⟩; rw [eqn]; exact borrowNativePreserves q h g
 · rcases a17 with ⟨g,eqn⟩; rw [eqn]; exact returnBorrowPreserves q h g
 · rcases a18 with ⟨g,eqn⟩; rw [eqn]; exact beginNativeInitPreserves q h g
 · rcases a19 with ⟨g,eqn⟩; rw [eqn]; exact returnNativeInitPreserves q h g
 · rcases a20 with ⟨g,eqn⟩; rw [eqn]; exact beginSchemeInitPreserves q h g
 · rcases a21 with ⟨g,eqn⟩; rw [eqn]; exact returnSchemeInitPreserves q h g
 · rcases a22 with ⟨g,eqn⟩; rw [eqn]; exact failInitPreserves q h g
 · rcases a23 with ⟨g,eqn⟩; rw [eqn]; exact removeAliasPreserves q h g
 · rcases a24 with ⟨g,eqn⟩; rw [eqn]; exact publishAliasPreserves q h g
 · rcases a25 with ⟨g,eqn⟩; rw [eqn]; exact closePreserves q h g
 · rcases a26 with ⟨g,eqn⟩; rw [eqn]; exact retirePayloadPreserves q h g
 · rcases a27 with ⟨g,eqn⟩; rw [eqn]; exact issuePreserves q h g
 · rcases a28 with ⟨g,eqn⟩; rw [eqn]; exact permitPreserves q h g
 · rcases a29 with ⟨g,eqn⟩; rw [eqn]; exact rejectLatePreserves q h g
 · rw [a30]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem permitMigrationReady (q : State) (h : Safe q) (p : q.phase=2) : q.sealed=true ∧ q.raw=false ∧ q.unknown=false ∧ q.privateRoot=false ∧ (q.ticket=3 ∨ (q.ticket=2 ∧ q.payloadRetired=true)) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 simp_all <;> omega
theorem sealedNativeCoverage (q : State) (h : Safe q) (p : q.sealed=true) : q.leaf=true ∧ q.edges=true ∧ (q.hasOpaque=true → q.qualified=true) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24⟩
 cases op : q.hasOpaque <;> simp_all <;> omega
theorem replyRetryDoesNotRerun (q : State) : (retryReplyNext q).stage=q.stage ∧ (retryReplyNext q).ticket=q.ticket := by simp [retryReplyNext]
theorem facadeDoesNotRevokeRaw (q : State) : (commitNext q).raw=q.raw := by simp [commitNext]
end ModuleHandle
