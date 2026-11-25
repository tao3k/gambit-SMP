/* Model-owned refinements/dependencies declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpRefinementDependencies {
 private import GambitSharedHeapSmp::*;

 part observerMetadataLifetimePremise:CaseDependency { ref part :>> dependent=originRecoveryQuery; ref part :>> prerequisite=metadataPinExitHandoff; attribute :>> condition="Source observation requires writer-side metadata synchronization, frozen-node lifetime and actual observer/activation last-user retirement"; }
 part replayMetadataExitPremise:CaseDependency { ref part :>> dependent=rootHandoffReplayBinding; ref part :>> prerequisite=metadataPinExitHandoff; attribute :>> condition="Real-cut replay joins metadata writes, lock order, last reader, lost ACK and physical reuse on the same actual source subject"; }
 part metadataAccessPremise:CaseDependency { ref part :>> dependent=metadataPinExitHandoff; ref part :>> prerequisite=parkReloadBorrow; attribute :>> condition="Raw data access is closed before moving scan while lifetime loan and scan/observer custody remain distinct"; }

 part amplificationRoundPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=acceptedRoundSimulation; attribute :>> condition="Actual freeze/scan/restore operations refine the accepted round rather than only locating source anchors"; }
 part amplificationWorkPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=wholeWorkPublication; attribute :>> condition="All private, queued, claimed and derived work closes before phase/resume permission"; }
 part amplificationParentPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=preRegistrationLoan; attribute :>> condition="The root is protected before any allocating registration, conversion or callback"; }
 part amplificationBorrowPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=parkReloadBorrow; attribute :>> condition="Native raw access closes before moving collection and reload precedes reentry"; }
 part amplificationStillPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=stillStrongClosure; attribute :>> condition="Still strong-root producers belong to the same complete frozen cut"; }
 part amplificationRecoveryPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=originRecoveryQuery; attribute :>> condition="Lost completion and owner exit retain an exact rooted custodian through settlement"; }
 part settlementAtomicPremise:CaseDependency {
  attribute :>> condition="Concrete partial-effect reconciliation and late access consume qualified same-field atomic operations and checked admission";
  ref part :>> dependent=takeSlotCSettlement;
  ref part :>> prerequisite=takeSlotAtomicServiceMap;
 }
 part settlementLifetimePremise:CaseDependency {
  attribute :>> condition="Unknown result settlement consumes sealed writer/query admission and complete slot/outer last-user retirement";
  ref part :>> dependent=takeSlotCSettlement;
  ref part :>> prerequisite=takeSlotPublicationRetirement;
 }
 // Cross-adapter source premises use the existing question graph:
 // SH-CUT-S -> SH-ALIAS-S -> SH-BOUNDARY-S. Do not bypass proof ownership.
 part runtimeInterfacePremise:CaseDependency { attribute :>> condition="Core/effect/target delivery consumes the held-reference, one-intent, typed result and continuous-coverage interface with exact partial/unknown custody and retirement"; ref part :>> dependent=bulkSyncRootDelivery; ref part :>> prerequisite=bulkRuntimeInterface; }
 part syncDeliveryPremise:CaseDependency { attribute :>> condition="Effect-restricted park and VM root custody consume actual request/error/cleanup outcomes and target protection across every future roster/scan prefix"; ref part :>> dependent=bulkParkExitRefinement; ref part :>> prerequisite=bulkSyncRootDelivery; }
 part stagingParkExitPremise:CaseDependency { attribute :>> condition="Staging authority consumes actual effect-restricted parking, purpose-aware exit and roots installed in a source covered by subsequent collection before owner retirement"; ref part :>> dependent=bulkStagingAuthority; ref part :>> prerequisite=bulkParkExitRefinement; }
 part stagingCustodyPremise:CaseDependency { attribute :>> condition="Bulk write custody consumes real staging purpose, fixed scan shape, writer closure, partial-effect settlement and retained last users"; ref part :>> dependent=bulkForeignWriteCustody; ref part :>> prerequisite=bulkStagingAuthority; }
 part stagingAliasPremise:CaseDependency { attribute :>> condition="Staging uses canonical object/offset ranges and real target/caller/alias branches before progress or source movement can be settled"; ref part :>> dependent=bulkStagingAuthority; ref part :>> prerequisite=bulkBranchAliasRefinement; }
 part bulkBranchPremise:CaseDependency { attribute :>> condition="Bulk/native custody consumes actual target/caller chains, canonical alias classes, rooted staging write ownership and directional progress; generated source alone does not grant native admission"; ref part :>> dependent=bulkForeignWriteCustody; ref part :>> prerequisite=bulkBranchAliasRefinement; }
 part bulkIncomingPremise:CaseDependency { attribute :>> condition="Incoming-edge closure consumes typed bulk and native access, overflow reservation, relocation-safe source identity and known last-writer settlement"; ref part :>> dependent=crossRegionIncomingEdges; ref part :>> prerequisite=bulkForeignWriteCustody; }
 part incomingEdgePremise:CaseDependency { attribute :>> condition="Independent cut or mature-scan omission consumes complete incoming edges, parked raw access and relocation-safe source identity; root publication alone is insufficient"; ref part :>> dependent=regionCollectionPartition; ref part :>> prerequisite=crossRegionIncomingEdges; }
 part regionWorkPremise:CaseDependency { attribute :>> condition="A proposed collection partition consumes complete publication, private/Tail, phase and last-user work closure in its selected scope"; ref part :>> dependent=regionCollectionPartition; ref part :>> prerequisite=wholeWorkPublication; }
 part replayProtectedEntry:CaseDependency { ref part :>> dependent=rootHandoffReplayBinding; ref part :>> prerequisite=preRegistrationLoan; attribute :>> condition="An actual entry loan or freeze-excluded prefix precedes the tested install and all collecting conversions"; }
 part replaySourceObservation:CaseDependency { ref part :>> dependent=rootHandoffReplayBinding; ref part :>> prerequisite=originRecoveryQuery; attribute :>> condition="The same real source observer settles installation and scan/round facts without impersonating a worker"; }
 part replayWholeClosure:CaseDependency { ref part :>> dependent=rootHandoffReplayBinding; ref part :>> prerequisite=wholeWorkPublication; attribute :>> condition="Actual claim, weak, private/Tail and phase closure determines when the observed roots may resume or retire"; }
 part amplificationReplayPremise:CaseDependency { ref part :>> dependent=gambitAmplificationDelivery; ref part :>> prerequisite=rootHandoffReplayBinding; attribute :>> condition="Whole architecture acceptance includes protected install, W<R observation and implementation-bound replay as one source subject"; }
 part workQueueObservationPremise:CaseDependency {
  attribute :>> condition="Whole work closure consumes typed queue observation, local-empty freshness and unresolved-claim custody before idle/phase/physical retirement";
  ref part :>> dependent=wholeWorkPublication;
  ref part :>> prerequisite=queueObservationToIdle;
 }
 part callerQueueSemanticPremise:CaseDependency {
  attribute :>> condition="Both real caller policies and all storage consumers decode the same typed queue outcome and custody contract";
  ref part :>> dependent=queueCallerAdapter;
  ref part :>> prerequisite=queueObservationToIdle;
 }
 part callerClaimWindowPremise:CaseDependency {
  attribute :>> condition="Caller adapter consumes fixed-slot identity, partial-store custody, pure query, once-only settlement and native last-user retirement as one operation contract";
  ref part :>> dependent=queueCallerAdapter;
  ref part :>> prerequisite=claimInterruptionSettlement;
 }
 part claimQueueSemanticPremise:CaseDependency {
  attribute :>> condition="Claim settlement never turns an uncertain operation into the certain Unobserved/busy queue result";
  ref part :>> dependent=claimInterruptionSettlement;
  ref part :>> prerequisite=queueObservationToIdle;
 }
 part claimSlotLifetimePremise:CaseDependency {
  attribute :>> condition="Partial-claim query and settlement require coherent fixed-slot publication, enrolled writer closure, pin-before-key and grace before reuse";
  ref part :>> dependent=claimInterruptionSettlement;
  ref part :>> prerequisite=takeSlotPublicationRetirement;
 }
 part slotAtomicProviderPremise:CaseDependency {
  attribute :>> condition="Layout publication and retirement consume exact selected atomic-service order/failure semantics, checked word range and rejection of late writer permits";
  ref part :>> dependent=takeSlotPublicationRetirement;
  ref part :>> prerequisite=takeSlotAtomicServiceMap;
 }
 part workSettlementPremise:CaseDependency {
  attribute :>> condition="Whole work closure requires every removed chunk to retain an exact operation or accepted scanner custodian across return and interruption";
  ref part :>> dependent=wholeWorkPublication;
  ref part :>> prerequisite=takeSlotCSettlement;
 }
 part workQueueAdapterPremise:CaseDependency {
  attribute :>> condition="Whole collector closure consumes the complete caller/publisher/fixed-point/phase/last-user adapter, not a changed return type alone";
  ref part :>> dependent=wholeWorkPublication;
  ref part :>> prerequisite=queueCallerAdapter;
 }
 part simulationWorkPremise:CaseDependency {
  attribute :>> condition="The accepted round can abstract settleCopy/closeProducers only after every covered private, published, claimed and phase-descendant obligation closes";
  ref part :>> dependent=acceptedRoundSimulation;
  ref part :>> prerequisite=wholeWorkPublication;
 }
 part simulationBorrowPremise:CaseDependency {
  attribute :>> condition="The C-to-QNT close/park relation requires data-access quiescence and reload, not merely a surviving RC lifetime borrow";
  ref part :>> dependent=acceptedRoundSimulation;
  ref part :>> prerequisite=parkReloadBorrow;
 }
 part simulationStrongPremise:CaseDependency {
  attribute :>> condition="Whole finish cannot be inferred until supplemental strong still and downstream producers close";
  ref part :>> dependent=acceptedRoundSimulation;
  ref part :>> prerequisite=stillStrongClosure;
 }
 part sourceCaseDependency0:CaseDependency {
  attribute :>> condition="Installed target root and surviving source loan precede reliance on the borrowed canonical slot; no ACK from mere node membership";
  ref part :>> dependent=parkReloadBorrow;
  ref part :>> prerequisite=preRegistrationLoan;
 }
 part sourceCaseDependency1:CaseDependency {
  attribute :>> condition="Read-only observation needs source record lifetime independent of scan executor and refreshed payload access after relocation";
  ref part :>> dependent=originRecoveryQuery;
  ref part :>> prerequisite=parkReloadBorrow;
 }
 part sourceCaseDependency2:CaseDependency {
  attribute :>> condition="A local completion observation cannot grant whole-round resume until supplemental strong/weak producer work is closed";
  ref part :>> dependent=originRecoveryQuery;
  ref part :>> prerequisite=stillStrongClosure;
 }
}
