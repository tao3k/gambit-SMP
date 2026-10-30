import GuardAdmissionAst
namespace GuardAdmission
open GuardAdmissionAst
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
theorem arrivePreserves (q : State) (h : Safe q) (g : arriveGuard q) : Safe (arriveNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,arriveGuard,arriveNext]
theorem cancelBeforeRegistrationPreserves (q : State) (h : Safe q) (g : cancelBeforeRegistrationGuard q) : Safe (cancelBeforeRegistrationNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,cancelBeforeRegistrationGuard,cancelBeforeRegistrationNext]
theorem maskConfirmedPreserves (q : State) (h : Safe q) (g : maskConfirmedGuard q) : Safe (maskConfirmedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,maskConfirmedGuard,maskConfirmedNext]
theorem maskOutcomeUnknownPreserves (q : State) (h : Safe q) (g : maskOutcomeUnknownGuard q) : Safe (maskOutcomeUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,maskOutcomeUnknownGuard,maskOutcomeUnknownNext]
theorem reserveGuardPreserves (q : State) (h : Safe q) (g : reserveGuardGuard q) : Safe (reserveGuardNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,reserveGuardGuard,reserveGuardNext]
theorem capacityRejectPreserves (q : State) (h : Safe q) (g : capacityRejectGuard q) : Safe (capacityRejectNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,capacityRejectGuard,capacityRejectNext]
theorem publishRegistryPreserves (q : State) (h : Safe q) (g : publishRegistryGuard q) : Safe (publishRegistryNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,publishRegistryGuard,publishRegistryNext]
theorem publicationUnknownPreserves (q : State) (h : Safe q) (g : publicationUnknownGuard q) : Safe (publicationUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,publicationUnknownGuard,publicationUnknownNext]
theorem queryCommittedPreserves (q : State) (h : Safe q) (g : queryCommittedGuard q) : Safe (queryCommittedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,queryCommittedGuard,queryCommittedNext]
theorem queryAbsentPreserves (q : State) (h : Safe q) (g : queryAbsentGuard q) : Safe (queryAbsentNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,queryAbsentGuard,queryAbsentNext]
theorem roundAcknowledgedPreserves (q : State) (h : Safe q) (g : roundAcknowledgedGuard q) : Safe (roundAcknowledgedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,roundAcknowledgedGuard,roundAcknowledgedNext]
theorem releaseSourceRootPreserves (q : State) (h : Safe q) (g : releaseSourceRootGuard q) : Safe (releaseSourceRootNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,releaseSourceRootGuard,releaseSourceRootNext]
theorem bindContextPreserves (q : State) (h : Safe q) (g : bindContextGuard q) : Safe (bindContextNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,bindContextGuard,bindContextNext]
theorem bindingUnknownPreserves (q : State) (h : Safe q) (g : bindingUnknownGuard q) : Safe (bindingUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,bindingUnknownGuard,bindingUnknownNext]
theorem enterApplicationPreserves (q : State) (h : Safe q) (g : enterApplicationGuard q) : Safe (enterApplicationNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,enterApplicationGuard,enterApplicationNext]
theorem beginNestedPreserves (q : State) (h : Safe q) (g : beginNestedGuard q) : Safe (beginNestedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,beginNestedGuard,beginNestedNext]
theorem nestedPublishPreserves (q : State) (h : Safe q) (g : nestedPublishGuard q) : Safe (nestedPublishNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedPublishGuard,nestedPublishNext]
theorem nestedRoundAcknowledgedPreserves (q : State) (h : Safe q) (g : nestedRoundAcknowledgedGuard q) : Safe (nestedRoundAcknowledgedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedRoundAcknowledgedGuard,nestedRoundAcknowledgedNext]
theorem nestedPublicationUnknownPreserves (q : State) (h : Safe q) (g : nestedPublicationUnknownGuard q) : Safe (nestedPublicationUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedPublicationUnknownGuard,nestedPublicationUnknownNext]
theorem queryNestedCommittedPreserves (q : State) (h : Safe q) (g : queryNestedCommittedGuard q) : Safe (queryNestedCommittedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,queryNestedCommittedGuard,queryNestedCommittedNext]
theorem returnNestedPreserves (q : State) (h : Safe q) (g : returnNestedGuard q) : Safe (returnNestedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,returnNestedGuard,returnNestedNext]
theorem nestedExitUnknownPreserves (q : State) (h : Safe q) (g : nestedExitUnknownGuard q) : Safe (nestedExitUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,nestedExitUnknownGuard,nestedExitUnknownNext]
theorem armOuterExitPreserves (q : State) (h : Safe q) (g : armOuterExitGuard q) : Safe (armOuterExitNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,armOuterExitGuard,armOuterExitNext]
theorem armAfterNestedPreserves (q : State) (h : Safe q) (g : armAfterNestedGuard q) : Safe (armAfterNestedNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,armAfterNestedGuard,armAfterNestedNext]
theorem restoreReturnsPreserves (q : State) (h : Safe q) (g : restoreReturnsGuard q) : Safe (restoreReturnsNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreReturnsGuard,restoreReturnsNext]
theorem restoreDoesNotReturnPreserves (q : State) (h : Safe q) (g : restoreDoesNotReturnGuard q) : Safe (restoreDoesNotReturnNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreDoesNotReturnGuard,restoreDoesNotReturnNext]
theorem restoreUnknownPreserves (q : State) (h : Safe q) (g : restoreUnknownGuard q) : Safe (restoreUnknownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,restoreUnknownGuard,restoreUnknownNext]
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,closeAdmissionGuard,closeAdmissionNext]
theorem tlsDetachKnownPreserves (q : State) (h : Safe q) (g : tlsDetachKnownGuard q) : Safe (tlsDetachKnownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,tlsDetachKnownGuard,tlsDetachKnownNext]
theorem scanGraceKnownPreserves (q : State) (h : Safe q) (g : scanGraceKnownGuard q) : Safe (scanGraceKnownNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,scanGraceKnownGuard,scanGraceKnownNext]
theorem retireActiveGuardPreserves (q : State) (h : Safe q) (g : retireActiveGuardGuard q) : Safe (retireActiveGuardNext q) := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all [Safe,retireActiveGuardGuard,retireActiveGuardNext]
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · rcases g with ⟨g,rfl⟩; exact arrivePreserves q h g
 · rcases g with ⟨g,rfl⟩; exact cancelBeforeRegistrationPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact maskConfirmedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact maskOutcomeUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact reserveGuardPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact capacityRejectPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact publishRegistryPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact publicationUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact queryCommittedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact queryAbsentPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact roundAcknowledgedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact releaseSourceRootPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact bindContextPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact bindingUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact enterApplicationPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact beginNestedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedPublishPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedRoundAcknowledgedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedPublicationUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact queryNestedCommittedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact returnNestedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact nestedExitUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact armOuterExitPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact armAfterNestedPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreReturnsPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreDoesNotReturnPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact restoreUnknownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact closeAdmissionPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact tlsDetachKnownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact scanGraceKnownPreserves q h g
 · rcases g with ⟨g,rfl⟩; exact retireActiveGuardPreserves q h g
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem guardRootCoverage (q : State) (h : Safe q) (g : q.guard=1) : q.sourceRoot=1 ∨ q.targetRoot=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem preRegistrationCancellationCustody (q : State) (h : Safe q) (g : q.phase=2) : q.guard=0 ∧ q.sourceRoot=1 ∧ q.application=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem applicationEntryHasRoots (q : State) (h : Safe q) (g : q.phase=9) : q.ack=1 ∧ q.targetRoot=1 ∧ q.tls=1 ∧ q.mask=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem restorationRetainsOwner (q : State) (h : Safe q) (g : q.phase=15 ∨ q.phase=16) : q.supervisor=2 ∧ q.guard=1 ∧ q.targetRoot=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem nestedRootCoverage (q : State) (h : Safe q) (g : q.childGuard=1) : q.childSource=1 ∨ q.childRoot=1 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem nestedParentRetained (q : State) (h : Safe q) (g : q.childGuard=1) : q.guard=1 ∧ q.targetRoot=1 ∧ q.mask≠0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem nestedReturnsDisabled (q : State) (h : Safe q) (g : q.phase=12) : q.mask=1 ∧ q.guard=1 ∧ q.childGuard=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem unknownPublicationRetainsSource (q : State) (h : Safe q) (g : q.phase=23) : q.sourceRoot=1 ∧ q.guard=1 ∧ q.supervisor=2 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
theorem retirementCut (q : State) (h : Safe q) (g : q.phase=20) : q.closed=1 ∧ q.tls=0 ∧ q.guard=0 ∧ q.childGuard=0 := by
 simp only [Safe] at h
 rcases h with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
 all_goals simp_all
end GuardAdmission
