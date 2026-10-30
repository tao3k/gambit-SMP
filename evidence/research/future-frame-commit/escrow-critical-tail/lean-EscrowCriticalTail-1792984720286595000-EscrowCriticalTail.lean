import EscrowCriticalTailAst
import NrInflightHandoffAst
namespace EscrowCriticalTail
open EscrowCriticalTailAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem disableCancelPreserves (q : State) (h : Safe q) (g : disableCancelGuard q) : Safe (disableCancelNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [disableCancelGuard] at g
 simp [disableCancelNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem exhaustPoolPreserves (q : State) (h : Safe q) (g : exhaustPoolGuard q) : Safe (exhaustPoolNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [exhaustPoolGuard] at g
 simp [exhaustPoolNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem returnExternalSlotPreserves (q : State) (h : Safe q) (g : returnExternalSlotGuard q) : Safe (returnExternalSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [returnExternalSlotGuard] at g
 simp [returnExternalSlotNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem claimSlotPreserves (q : State) (h : Safe q) (g : claimSlotGuard q) : Safe (claimSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [claimSlotGuard] at g
 simp [claimSlotNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem releaseUnpublishedSlotPreserves (q : State) (h : Safe q) (g : releaseUnpublishedSlotGuard q) : Safe (releaseUnpublishedSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [releaseUnpublishedSlotGuard] at g
 simp [releaseUnpublishedSlotNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem registerKnownPreserves (q : State) (h : Safe q) (g : registerKnownGuard q) : Safe (registerKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [registerKnownGuard] at g
 simp [registerKnownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem registerUnknownPreserves (q : State) (h : Safe q) (g : registerUnknownGuard q) : Safe (registerUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [registerUnknownGuard] at g
 simp [registerUnknownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem reconcileRegistrationPreserves (q : State) (h : Safe q) (g : reconcileRegistrationGuard q) : Safe (reconcileRegistrationNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [reconcileRegistrationGuard] at g
 simp [reconcileRegistrationNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem popKnownEscrowPreserves (q : State) (h : Safe q) (g : popKnownEscrowGuard q) : Safe (popKnownEscrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [popKnownEscrowGuard] at g
 simp [popKnownEscrowNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem escapeTokenPreserves (q : State) (h : Safe q) (g : escapeTokenGuard q) : Safe (escapeTokenNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [escapeTokenGuard] at g
 simp [escapeTokenNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownTokenEndpointPreserves (q : State) (h : Safe q) (g : knownTokenEndpointGuard q) : Safe (knownTokenEndpointNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [knownTokenEndpointGuard] at g
 simp [knownTokenEndpointNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem qualifyNodeTailPreserves (q : State) (h : Safe q) (g : qualifyNodeTailGuard q) : Safe (qualifyNodeTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [qualifyNodeTailGuard] at g
 simp [qualifyNodeTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem completeQualifiedNodeTailPreserves (q : State) (h : Safe q) (g : completeQualifiedNodeTailGuard q) : Safe (completeQualifiedNodeTailNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [completeQualifiedNodeTailGuard] at g
 simp [completeQualifiedNodeTailNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem unknownNodeCompletionPreserves (q : State) (h : Safe q) (g : unknownNodeCompletionGuard q) : Safe (unknownNodeCompletionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [unknownNodeCompletionGuard] at g
 simp [unknownNodeCompletionNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownNodeBackendReceiptPreserves (q : State) (h : Safe q) (g : knownNodeBackendReceiptGuard q) : Safe (knownNodeBackendReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [knownNodeBackendReceiptGuard] at g
 simp [knownNodeBackendReceiptNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem publishDonePreserves (q : State) (h : Safe q) (g : publishDoneGuard q) : Safe (publishDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [publishDoneGuard] at g
 simp [publishDoneNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem acquireMapPreserves (q : State) (h : Safe q) (g : acquireMapGuard q) : Safe (acquireMapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [acquireMapGuard] at g
 simp [acquireMapNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem issuePinPreserves (q : State) (h : Safe q) (g : issuePinGuard q) : Safe (issuePinNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [issuePinGuard] at g
 simp [issuePinNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem unlockMapPreserves (q : State) (h : Safe q) (g : unlockMapGuard q) : Safe (unlockMapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [unlockMapGuard] at g
 simp [unlockMapNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem escapeHoldingMapPreserves (q : State) (h : Safe q) (g : escapeHoldingMapGuard q) : Safe (escapeHoldingMapNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [escapeHoldingMapGuard] at g
 simp [escapeHoldingMapNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownOwnerLandingPreserves (q : State) (h : Safe q) (g : knownOwnerLandingGuard q) : Safe (knownOwnerLandingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [knownOwnerLandingGuard] at g
 simp [knownOwnerLandingNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem returnPinKnownPreserves (q : State) (h : Safe q) (g : returnPinKnownGuard q) : Safe (returnPinKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [returnPinKnownGuard] at g
 simp [returnPinKnownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem returnPinUnknownPreserves (q : State) (h : Safe q) (g : returnPinUnknownGuard q) : Safe (returnPinUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [returnPinUnknownGuard] at g
 simp [returnPinUnknownNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownPinReturnLandingPreserves (q : State) (h : Safe q) (g : knownPinReturnLandingGuard q) : Safe (knownPinReturnLandingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [knownPinReturnLandingGuard] at g
 simp [knownPinReturnLandingNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem handoffSupervisorPreserves (q : State) (h : Safe q) (g : handoffSupervisorGuard q) : Safe (handoffSupervisorNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [handoffSupervisorGuard] at g
 simp [handoffSupervisorNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem beginRestoreCancelPreserves (q : State) (h : Safe q) (g : beginRestoreCancelGuard q) : Safe (beginRestoreCancelNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [beginRestoreCancelGuard] at g
 simp [beginRestoreCancelNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem knownRestoreReturnPreserves (q : State) (h : Safe q) (g : knownRestoreReturnGuard q) : Safe (knownRestoreReturnNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [knownRestoreReturnGuard] at g
 simp [knownRestoreReturnNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem retireSlotPreserves (q : State) (h : Safe q) (g : retireSlotGuard q) : Safe (retireSlotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 simp only [retireSlotGuard] at g
 simp [retireSlotNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | ((try simp) <;> omega)
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27 | h28
 · rcases h0 with ⟨g,rfl⟩
   exact disableCancelPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact exhaustPoolPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact returnExternalSlotPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact claimSlotPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact releaseUnpublishedSlotPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact registerKnownPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact registerUnknownPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact reconcileRegistrationPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact popKnownEscrowPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact escapeTokenPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact knownTokenEndpointPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact qualifyNodeTailPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact completeQualifiedNodeTailPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact unknownNodeCompletionPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact knownNodeBackendReceiptPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact publishDonePreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact acquireMapPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact issuePinPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact unlockMapPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact escapeHoldingMapPreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact knownOwnerLandingPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact returnPinKnownPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact returnPinUnknownPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact knownPinReturnLandingPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact handoffSupervisorPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact beginRestoreCancelPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact knownRestoreReturnPreserves q h g
 · rcases h27 with ⟨g,rfl⟩
   exact retireSlotPreserves q h g
 · simpa [h28] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem unknownPinIsNotReturned (q : State) (hp : q.pin=2) : ¬ returnPinKnownGuard q := by simp [returnPinKnownGuard,hp]
theorem unknownRestoreRetainsSlot (q : State) (h : Safe q) (hc : q.cancel=2) : q.slot=1 ∧ q.registered=1 ∧ q.supervisor=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40⟩
 omega
def DoneMirror (q : State) (r : NrInflightHandoffAst.State) : Prop := q.stage=8 → r.stage=9 ∧ r.escrow=0
def RetireOthers (r : NrInflightHandoffAst.State) : Prop := r.lock=2 ∧ r.gate=0 ∧ r.pin=0 ∧ r.live=1 ∧ r.senders=0 ∧ r.rawClosed=1
theorem suppliesPriorGuard (q : State) (r : NrInflightHandoffAst.State) (g : retireSlotGuard q) (hm : DoneMirror q r) (hr : RetireOthers r) : NrInflightHandoffAst.retireRecordGuard r := by
 simp only [retireSlotGuard] at g
 simp only [DoneMirror] at hm
 simp only [RetireOthers] at hr
 simp only [NrInflightHandoffAst.retireRecordGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : NrInflightHandoffAst.State) (g : retireSlotGuard q) (hm : DoneMirror q r) (hr : RetireOthers r) : NrInflightHandoffAst.Step r (NrInflightHandoffAst.retireRecordNext r) := by
 have h := suppliesPriorGuard q r g hm hr
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))))))))))))))))))
end EscrowCriticalTail
