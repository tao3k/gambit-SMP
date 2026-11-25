/* Model-owned handoff/facts declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpHandoffFacts {
 private import GambitSharedHeapSmp::*;

 part rootHandoffUse0:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Only after actual target protection and caller/source prelude premises are known";
  ref part :>> point=emitRootPrelude;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse1:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="After exact payload commit with target lifetime; not after link alone";
  ref part :>> point=enrollTargetSlot;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse2:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Argument slot/source protection installed; no release permission for another scope";
  ref part :>> point=reloadSfunArgument;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse3:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="If a conversion or marker collected, reacquire/reload before payload use";
  ref part :>> point=reloadSfunArgument;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse4:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Input proc/source already protected before allocation";
  ref part :>> point=installMarkerTarget;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse5:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="If marker allocation collected, canonical source slot is refreshed before read";
  ref part :>> point=installMarkerTarget;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse6:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Known initialized marker/activation root can become the child target";
  ref part :>> point=installMarkerTarget;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse7:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Retain requester source until its enrolled cell is protected";
  ref part :>> point=requestResizeWithRoot;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse8:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Only at complete collective participation, not from positive borrow count";
  ref part :>> point=requestResizeWithRoot;
  ref part :>> receipt=parkedBorrow;
 }
 part rootHandoffUse9:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="After an actual GC before next canonical payload read";
  ref part :>> point=requestResizeWithRoot;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse10:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Input source lifetime valid while initializing child slot";
  ref part :>> point=publishStartupSlot;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse11:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Target RC cell and transferred lifetime custody established before launch";
  ref part :>> point=publishStartupSlot;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse12:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Parent/startup root holds through allocating marker construction";
  ref part :>> point=ackStartupMarker;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse13:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Known marker/activation protection precedes old RC borrow/ref release";
  ref part :>> point=ackStartupMarker;
  ref part :>> receipt=installedRoot;
 }
 part rootHandoffUse14:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="If construction collected, use the post-restore payload";
  ref part :>> point=ackStartupMarker;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse15:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Every relevant writer/borrower contributes actual data closure before sealing";
  ref part :>> point=freezeSourceUnion;
  ref part :>> receipt=parkedBorrow;
 }
 part rootHandoffUse16:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Aggregate only known complete same-epoch views; current phase change alone is insufficient";
  ref part :>> point=freezeSourceUnion;
  ref part :>> receipt=parkedBorrow;
 }
 part rootHandoffUse17:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Actual supplemental writers are quiescent or have a qualified admitted path";
  ref part :>> point=sealStillPrefix;
  ref part :>> receipt=parkedBorrow;
 }
 part rootHandoffUse18:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="producer-closed";
  attribute :>> condition="Selection and late-root accounting satisfy existing producer owner premises";
  ref part :>> point=sealStillPrefix;
  ref part :>> receipt=sealedProducers;
 }
 part rootHandoffUse19:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Source remains frozen; scanner also has its separate assigned lease";
  ref part :>> point=completeWorkerScan;
  ref part :>> receipt=parkedBorrow;
 }
 part rootHandoffUse20:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="scan-status";
  attribute :>> condition="Report only local matching-task progress and final lease state";
  ref part :>> point=completeWorkerScan;
  ref part :>> receipt=scanProgress;
 }
 part rootHandoffUse21:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Pinned consistent metadata query; no payload read or mutation authority";
  ref part :>> point=observeSourceOrigin;
  ref part :>> receipt=originObservation;
 }
 part rootHandoffUse22:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="scan-status";
  attribute :>> condition="All relevant task completion plus non-task copy/scan debt, not one DONE";
  ref part :>> point=resumeSourceAndReload;
  ref part :>> receipt=scanProgress;
 }
 part rootHandoffUse23:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="producer-closed";
  attribute :>> condition="Supplemental strong/weak producer closure remains part of the joint cut";
  ref part :>> point=resumeSourceAndReload;
  ref part :>> receipt=sealedProducers;
 }
 part rootHandoffUse24:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="All memory work and physical restore completed before acquired access";
  ref part :>> point=resumeSourceAndReload;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse25:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="If an admission/return/query outcome was unknown, it must first be settled or explicitly retained";
  ref part :>> point=retireSourceAndQueries;
  ref part :>> receipt=originObservation;
 }
 part rootHandoffUse26:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="When completing a joined GC round; terminal nonjoined cases prove their own stopped-source boundary";
  ref part :>> point=retireSourceAndQueries;
  ref part :>> receipt=roundResume;
 }
 part rootHandoffUse27:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="retire-storage";
  attribute :>> condition="Only exact storage with known physical closure and last use can retire";
  ref part :>> point=retireSourceAndQueries;
  ref part :>> receipt=sourceRetired;
 }
 part clientHandoffUse0:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="ClientData/source payload stays installed and pinned before calls or last-use release";
  ref part :>> point=externalClientHandoff;
  ref part :>> receipt=installedRoot;
 }
 part clientHandoffUse1:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Known constructor payload install and accepted library ownership preserve target protection";
  ref part :>> point=externalClientHandoff;
  ref part :>> receipt=installedRoot;
 }
 part clientHandoffUse2:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Any GC cut requires native payload and still-hold writers closed; RC identity count alone is insufficient";
  ref part :>> point=externalClientHandoff;
  ref part :>> receipt=parkedBorrow;
 }
 part clientHandoffUse3:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="If nested conversion collected, load canonical payload only after acquired Scheme/source reentry";
  ref part :>> point=externalClientHandoff;
  ref part :>> receipt=roundResume;
 }
 part bulkStageUse0:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Original parent roots protect inputs until complete installed stage input, not merely FAL membership";
  ref part :>> point=bulkStageInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkStageUse1:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Complete immutable stage/input revision and target root lifetime are durable before source ACK";
  ref part :>> point=bulkStageInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkStageUse2:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Only when every selected stage/destination data writer and helper has actual closure";
  ref part :>> point=bulkStageCloseWrites;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkStageUse3:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="producer-closed";
  attribute :>> condition="Other root/work producer closure plus bulk spans are required for the selected whole cut";
  ref part :>> point=bulkStageCloseWrites;
  ref part :>> receipt=sealedProducers;
 }
 part bulkStageUse4:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Staging and destination scan cannot race physical access or torn writes";
  ref part :>> point=bulkStageScan;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkStageUse5:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="All typed stage roots and canonical input sources remain installed";
  ref part :>> point=bulkStageScan;
  ref part :>> receipt=installedRoot;
 }
 part bulkStageUse6:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="scan-status";
  attribute :>> condition="Only exact claimed task and valid rewritten slots establish local progress";
  ref part :>> point=bulkStageScan;
  ref part :>> receipt=scanProgress;
 }
 part bulkStageUse7:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Pinned consistent status identity grants no physical write/read or source ACK by itself";
  ref part :>> point=bulkStageObserve;
  ref part :>> receipt=originObservation;
 }
 part bulkStageUse8:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="Whole-round memory/restore completion precedes refreshed root reload";
  ref part :>> point=bulkStageResume;
  ref part :>> receipt=roundResume;
 }
 part bulkStageUse9:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Known same-call cursor/effect state is required; unknown cannot be guessed";
  ref part :>> point=bulkStageResume;
  ref part :>> receipt=originObservation;
 }
 part bulkStageUse10:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Physical last writers/helpers are closed; known stop is not inferred from lifecycle status";
  ref part :>> point=bulkStageRetire;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkStageUse11:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Outcome and root/result/query users are settled with exact identity";
  ref part :>> point=bulkStageRetire;
  ref part :>> receipt=originObservation;
 }
 part bulkStageUse12:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="retire-storage";
  attribute :>> condition="Only after all source/root/span/result/native users and required scans are done and cells cleared";
  ref part :>> point=bulkStageRetire;
  ref part :>> receipt=sourceRetired;
 }
 part bulkParkExitUse0:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="All prior physical bulk spans have actually stopped before memory movement";
  ref part :>> point=bulkParkEffectBoundary;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkParkExitUse1:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Current operation endpoints/input and pending error values are rooted before coordination";
  ref part :>> point=bulkParkEffectBoundary;
  ref part :>> receipt=installedRoot;
 }
 part bulkParkExitUse2:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="Only complete memory/restore closure plus valid effect restriction permits same-call address reload";
  ref part :>> point=bulkParkEffectBoundary;
  ref part :>> receipt=roundResume;
 }
 part bulkParkExitUse3:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="Original data writes closed and actual old source access is qualified";
  ref part :>> point=bulkVmRootInstall;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkParkExitUse4:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Original source and parents remain installed until matching target commit";
  ref part :>> point=bulkVmRootInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkParkExitUse5:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Known target commit and all overlapping/future roster coverage precede original source release";
  ref part :>> point=bulkVmRootInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkParkExitUse6:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Pinned target query separates no-effect refusal, committed installation and unknown";
  ref part :>> point=bulkVmRootInstall;
  ref part :>> receipt=originObservation;
 }
 part bulkParkExitUse7:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="Memory/restore completion precedes effects but does not count as their completion";
  ref part :>> point=bulkDeliverDeferredEffects;
  ref part :>> receipt=roundResume;
 }
 part bulkParkExitUse8:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Effect/call status and owner affinity remain separately known or retained";
  ref part :>> point=bulkDeliverDeferredEffects;
  ref part :>> receipt=originObservation;
 }
 part bulkSyncDeliveryUse0:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Pending root-bearing results/errors are protected before any later moving cut";
  ref part :>> point=bulkCollectiveOutcome;
  ref part :>> receipt=installedRoot;
 }
 part bulkSyncDeliveryUse1:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Consistent request/error/cleanup fields are status only, never effect completion by implication";
  ref part :>> point=bulkCollectiveOutcome;
  ref part :>> receipt=originObservation;
 }
 part bulkSyncDeliveryUse2:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="reload-after-resume";
  attribute :>> condition="Permitted effect delivery follows full memory restoration and an effect-safe call boundary";
  ref part :>> point=bulkCleanupObserve;
  ref part :>> receipt=roundResume;
 }
 part bulkSyncDeliveryUse3:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Known effect result or explicitly retained uncertainty cannot be replaced by cleared object fields";
  ref part :>> point=bulkCleanupObserve;
  ref part :>> receipt=originObservation;
 }
 part bulkSyncDeliveryUse4:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Actual canonical target slots and lifetime cover all GC prefixes after original source ACK";
  ref part :>> point=bulkTargetNextScan;
  ref part :>> receipt=installedRoot;
 }
 part bulkSyncDeliveryUse5:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="No source/target/stage data access races relocation; retired old writers really drained";
  ref part :>> point=bulkTargetNextScan;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkSyncDeliveryUse6:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="scan-status";
  attribute :>> condition="Matching enrolled task and actual target root rewrites establish local scan completion only";
  ref part :>> point=bulkTargetNextScan;
  ref part :>> receipt=scanProgress;
 }
 part bulkInterfaceUse0:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Original canonical value/source roots already protect this slot input; target ACK is a separate event";
  ref part :>> point=bulkPurposeWrite;
  ref part :>> receipt=installedRoot;
 }
 part bulkInterfaceUse1:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Original source roots remain installed through target native allocation uncertainty";
  ref part :>> point=bulkTargetPrepare;
  ref part :>> receipt=installedRoot;
 }
 part bulkInterfaceUse2:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="All relevant old source/destination data writes actually stopped before copying canonical roots";
  ref part :>> point=bulkTargetInstall;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkInterfaceUse3:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Original parent/root lifetime covers the full partial target interval";
  ref part :>> point=bulkTargetInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkInterfaceUse4:HandoffUse {
  attribute :>> role="establishes";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Only exact complete root payload and protected target lifetime establish target installation";
  ref part :>> point=bulkTargetInstall;
  ref part :>> receipt=installedRoot;
 }
 part bulkInterfaceUse5:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="parent-ack";
  attribute :>> condition="Matching complete target protection spans every overlapping/future GC prefix";
  ref part :>> point=bulkTargetAck;
  ref part :>> receipt=installedRoot;
 }
 part bulkInterfaceUse6:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="access-stopped";
  attribute :>> condition="ACK never substitutes for known old physical write closure";
  ref part :>> point=bulkTargetAck;
  ref part :>> receipt=parkedBorrow;
 }
 part bulkInterfaceUse7:HandoffUse {
  attribute :>> role="requires";
  attribute :>> purpose="observe-origin";
  attribute :>> condition="Pinned consistent target commit/revision and prior ACK state precede idempotent decision";
  ref part :>> point=bulkTargetAck;
  ref part :>> receipt=originObservation;
 }
}
