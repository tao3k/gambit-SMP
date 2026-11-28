/* Model-owned source-sites/qualification declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpQualificationSources {
 private import GambitSharedHeapSmp::*;

 part nativePopulation:SourceSite {
  attribute :>> id="nativePopulation";
  attribute :>> artifact="vendor/gambit/tests/makefile.in";
  attribute :>> anchor="test-rc-roots:";
  attribute :>> role="acceptance";
  attribute :>> observed="Original Make exposes RC/frame/worker/lifecycle tests and topology consumers";
  attribute :>> required="Bind source/profile/toolchain/artifacts to complete affected families plus actual PBT replay/shrink and same-condition controls";
  attribute :>> gap="Presence of test targets is not execution, twelve-family closure or acceptance of a dirty concurrent checkout";
  ref part :>> question=nativeAcceptance;
 }
 part nativeFrame:SourceSite {
  attribute :>> id="nativeFrame";
  attribute :>> artifact="vendor/gambit/tests/makefile.in";
  attribute :>> anchor="frame-continuation-roots.scm";
  attribute :>> role="acceptance";
  attribute :>> observed="Make compiles and executes frame continuation root fixture";
  attribute :>> required="Exercise map capture and repeated restore across GC on current source; include W<R and healthy-VM unknown join histories";
  attribute :>> gap="Focused fixture does not replace whole manifest; no native tests executed by this design flow";
  ref part :>> question=nativeAcceptance;
 }
 part costSubjects:SourceSite {
  attribute :>> id="costSubjects";
  attribute :>> artifact="dev/refactoring/modern-c/post-delivery.org";
  attribute :>> anchor="| composed p1 |";
  attribute :>> role="cost";
  attribute :>> observed="Retains historical matched-cost table including regressions; not a current-source benchmark";
  attribute :>> required="Bind both source periods/topology/warm state; compare root/lookup/scan work, barriers and physical peak across complete population";
  attribute :>> gap="Historical percentages cannot establish current net benefit; generation/Actor speedup remains unmeasured";
  ref part :>> question=netBenefit;
 }

 part minorExecAdmissionClose:SourceSite {
  attribute :>> id="minorExecAdmissionClose";
  attribute :>> artifact="dev/refactoring/modern-c/tests/map-worker-exec-recovery.c";
  attribute :>> anchor="static int recover_multi(";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV replay queues an independent registration while recovery holds the admission gate. The pending reader rejects after synced closure; the registration-first control retains both admitted identities. A recovery SIGKILL before or after unlink leaves durable ACKs and retirement intent; fresh replay performs exactly one unlink across both attempts and permits full GC.";
  attribute :>> required="Keep registration close independent from ACK replay; require last lease drain and both ACKs before retirement and full GC retry.";
  attribute :>> gap="Product registration and restart custody, concurrent admission ordering, repeated recovery-writer failures, and matched pause/throughput evidence remain open.";
  ref part :>> question=nativeAcceptance;
 }
 part packetMapReplayScope:SourceSite {
  attribute :>> id="packetMapReplayScope";
  attribute :>> artifact="dev/refactoring/modern-c/tests/map-worker-stop.scm";
  attribute :>> anchor="(set! trial worker-stop-trial)";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="The local trial replaces the included replay helper with inline DEV fixture effects; it then requests R3 W2 and includes the real frame-continuation-roots map/full-GC control. The overlay marker and real map marker establish different scopes.";
  attribute :>> required="Retain fixture negative/shrink controls, then bind claimed whole-path traces to actual C publish/claim/stop/restore cuts with exact operation identities and same failure signature during shrinking. Verify W2, R3 and the real 11 completed forced collections; neither marker subsumes the other.";
  attribute :>> gap="No production take/partial-commit/last-user interleaving follows from the substituted fixture trial or from running the real map afterward. Current full-GC acceptance needs a real implementation adapter for those claimed histories.";
  ref part :>> question=nativeAcceptance;
 }
 part packetOfficialManifest:SourceSite {
  attribute :>> id="packetOfficialManifest";
  attribute :>> artifact="vendor/gambit/tests/makefile.in";
  attribute :>> anchor="test-root-task: root-task@exe@ root-task-bank@exe@ root-task-primitive@exe@";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Existing test-frame-contract includes frame-continuation-roots; test-entry/test-sfun-entry/test-rc-roots/test-root-task/test-vm-lifecycle exercise entry, RC, root and exit consumers. Root-task variants include real replay/shrink, frozen-union, collector, process-contract, moving-bank and moving-globals routes. Top-level check also lists core and test1..test12.";
  attribute :>> required="Use configured Make and the existing Bazel profile in the single Modern C cache. Record target, feature variant, effective argv/toolchain, exact executable/library identity, required markers and natural status. Extend these owned fixtures only for missing actual-cut coverage; preserve official names, populations and limits.";
  attribute :>> gap="A listed target is neither executed evidence nor a substitute for original GSI/GSC and Gerbil consumers. Independent modern-c SMP family counts require their own exact-source results and cannot inherit patch-line passes.";
  ref part :>> question=nativeAcceptance;
 }
 part packetReplayTransport:SourceSite {
  attribute :>> id="packetReplayTransport";
  attribute :>> artifact="vendor/gambit/tests/root-task-replay.scm";
  attribute :>> anchor="self arguments: (list \"-:p1\" \"--replay\" path)";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="trial-file launches the current executable with fixed p1 and --replay; mismatch requires the existing structured result and natural status 71, while precondition/runtime failures are distinct. shrink deletes command ranges and checks the same signature.";
  attribute :>> required="Preserve the p1 API population. Add an explicitly topology-bound mode to the owned fixture/helper for actual R3 W2 cuts; fixed topology and valid admission dependencies survive shrink. Reuse the existing Scheme trace envelope and oracle interface, not a second runner or model.";
  attribute :>> gap="Fixed p1 replay cannot certify W<R source queries or an active multi-member moving cut. Deleting setup into precondition failure cannot count as a smaller counterexample; no concurrent-mode implementation is claimed by this source record.";
  ref part :>> question=cutSource;
 }
 part packetReplayNativeScope:SourceSite {
  attribute :>> id="packetReplayNativeScope";
  attribute :>> artifact="vendor/gambit/tests/root-task.scm";
  attribute :>> anchor="if(vm->processor_count!=1)";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="replay-native executes actual root service functions but some source-family routes require one processor and clear actual VM/bank/global/stack anchors before a nonreturning child exit. Those are intentionally destructive local API controls, not a live multi-shot frame schedule.";
  attribute :>> required="Keep those controls. A separate case within the same fixture must retain real map frames, native parents and R3 W2 membership; select hooks at actual source enrollment, initialized install, ACK, root publish/claim/finish, origin observation and reentry/exit. Collect bounded nonallocating observations at the cuts, then check them after reentry.";
  attribute :>> gap="No destructive reset or fictitious processor pointer may be used to manufacture the concurrent witness. Actual hook selection, source lifetime, generation checks and production-path coverage remain implementation duties.";
  ref part :>> question=cutSource;
 }
 part bulkInterfacePacket:SourceSite {
  attribute :>> id="bulkInterfacePacket";
  attribute :>> artifact="dev/refactoring/modern-c/bulk-runtime-interface.org";
  attribute :>> anchor="#+NAME: bulk-runtime-interface-contract";
  attribute :>> role="bound-design-packet-not-runtime-source";
  attribute :>> observed="Normative implementation notation and whole acceptance matrix are repository-bound; no proposed signature is asserted to exist in C";
  attribute :>> required="Runtime implementation must meet actual source call boundaries and all authority/result/custody guards; document hashes are design inputs only";
  attribute :>> gap="Interface definition is not source refinement, a native test or a readiness receipt";
  ref part :>> question=cutSource;
 }
 part takeInputAttribution:SourceSite {
  attribute :>> id="takeInputAttribution";
  attribute :>> artifact="evidence/research/retained/modern-c/shared-heap-smp-design/take-input-attribution.json";
  attribute :>> anchor="take-input-source-attribution";
  attribute :>> role="source-period-and-generator-closure-attribution";
  attribute :>> observed="In the retained source period, all 12 observed include/input differences have source digests and reviewed cause/recapture decisions: 5 coordinate-only, 7 configured/semantic. Forty canonical fragments are separately checked; two remove obsolete authorization storage. Old cache reuse was refused after another owner changed os_thread.c; both TUs were recaptured in the same cache, leaving 11 direct mismatches in that observation and no object/link/runtime qualification";
  attribute :>> required="Consume exact row and producer hashes; do not conflate observed include closure with the header/configuration producer closure. Regenerate through the existing profile/Make owner, recapture affected TUs and preserve source/native gates";
  attribute :>> gap="Historical attribution does not qualify a changed current checkout; sourcePeriodSeparation retains later diagnostic/copy-source drift without credit transfer. It does not synchronize another thread's build, implement take settlement, qualify legacy/emulated paths or supply a stop/drain receipt";
  ref part :>> question=cutSource;
 }
 part takeAccessClassification:SourceSite {
  attribute :>> id="takeAccessClassification";
  attribute :>> artifact="evidence/research/retained/modern-c/shared-heap-smp-design/take-access-review.json";
  attribute :>> anchor="source-access-review";
  attribute :>> role="exact-occurrence-source-context-review";
  attribute :>> observed="All 82 declared candidates in 9 files have per-offset source digest, line text and reviewed classification; legacy/generated declarations, macros, comments and activity labels are distinguished from mutations";
  attribute :>> required="Match exact reviewed bytes and occurrence identity before reuse; prove real writer/caller coverage separately; classification grants no slot, effect-settlement or drain receipt";
  attribute :>> gap="Declaration classification does not prove a dead field removable or arbitrary external/macro-generated writers absent; all implementation and whole-source gates remain open";
  ref part :>> question=cutSource;
 }
 part takeCurrentTuObservation:SourceSite {
  attribute :>> id="takeCurrentTuObservation";
  attribute :>> artifact="evidence/research/retained/modern-c/shared-heap-smp-design/take-current-translation-units.json";
  attribute :>> anchor="take-translation-unit-observation";
  attribute :>> role="same-cache-recapture-after-input-change";
  attribute :>> observed="After old-cache reuse was refused for changed os_thread.c, both actual TU preprocessing requests were repeated in the same managed cache; native ordered-word and sync CAS remain selected; os_thread.c matches checkout and 11 other original differences remain";
  attribute :>> required="Keep the original observation and exact source period distinct; consume regenerated canonical/header/configuration evidence before claiming current-checkout identity; generated streams remain managed outputs, not new Git source";
  attribute :>> gap="Fresh preprocessing is not fixed-slot implementation, stop/drain evidence, object/layout/link or runtime acceptance; no affected whole family or performance gate is closed";
  ref part :>> question=cutSource;
 }
 part takeConfiguredTuObservation:SourceSite {
  attribute :>> id="takeConfiguredTuObservation";
  attribute :>> artifact="evidence/research/retained/modern-c/shared-heap-smp-design/take-translation-units.json";
  attribute :>> anchor="take-translation-unit-observation";
  attribute :>> role="actual-configured-cache-preprocessing";
  attribute :>> observed="Existing Make requests for mem.c and os_thread.c run preprocessing only: GCC16.2/aarch64/C23/RTS-O3, WS8, native ordered-word and sync CAS; 341 and 303 include inputs bound; structured observations retained in the repository; complete generated streams remain in managed task outputs";
  attribute :>> required="Scope result to this configured cache, exact request/tool/include closure and source period; the original12 differences are attributed; the fresh same-cache observation has 11 remaining after os_thread.c synchronization, plus actual layout/object/link/runtime qualification";
  attribute :>> gap="No target object, new linked runtime or runtime execution was produced; no take-slot implementation or partial-effect/last-user closure is inferred from preprocessing";
  ref part :>> question=cutSource;
 }

 part mainlineThirdFamilyAudit:SourceSite {
  attribute :>> id="mainlineThirdFamilyAudit";
  attribute :>> artifact="dev/refactoring/modern-c/independent-smp-audit.org";
  attribute :>> anchor="* First three families accepted on one producer";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Published32028f5d binds bootstrap and original GSI/GSC408 populations to a76175ee/65a4a2e2 equivalence, fifty recorded rejection controls and immutable reviewed Org snapshots. Fifty-six selected publication files match the manifest. At that read cut three selected working paths differed, so source equivalence could not be assumed. A later complete-pr-gsi receipt is separately revalidated by mainlineFourthFamilyAudit.";
  attribute :>> required="Family4 is complete-pr-gsi, not stress test4 or repair ordinal4. Freeze the exact additional PR manifest, producer/compiler/runtime/cohort and original limits. Bind every natural exit and required assertion to the same candidate; requalify affected earlier families after semantic changes.";
  attribute :>> gap="This DEV review checks retained trees and evidence identities; no new native execution, phase4 pass, remote CI acceptance or whole-SMP verdict follows.";
  ref part :>> question=cutSource;
 }
 part repair19CapacityBoundary:SourceSite {
  attribute :>> id="repair19CapacityBoundary";
  attribute :>> artifact="docs/current-repair-research.md";
  attribute :>> anchor="## Repair 19 — Unresolved delivery capacity and execution-boundary problem";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="The retained e782 cut reports fourteen focused controls, an exact120000-request sample with499270256 reported allocation bytes and115 collections, yet original interrupt stress exits1 with Thread is not active; the second original file is unstarted. It is diagnostic historical8/12, separate from current user-reported patch9/12.";
  attribute :>> required="Retire split request routing/active-invocation ownership, repeated private wait/service control construction, transport-as-completion and carrier-inferred root/cleanup authority together through dependent whole deliveries. Keep user multi-shot/wind/false-exception semantics. Join per-target accepted/claimed/completed/abandoned debt, capture/materialization, scan/copy work and simultaneous peak on unchanged original populations.";
  attribute :>> gap="Focused safety and root retention do not establish capacity, fairness, deadlines or the actual failure cause. Approximately4160.59 reported bytes per request is not an attribution to continuations. Root handoff alone cannot close Repair9, and this corpus does not prove every possible patch intrinsically impossible.";
  ref part :>> question=cutSource;
 }

 part mainlineFourthFamilyAudit:SourceSite {
  attribute :>> id="mainlineFourthFamilyAudit";
  attribute :>> artifact="evidence/research/retained/modern-c/pr-gsi/qualified-native.json";
  attribute :>> anchor="\"family\": \"pr-gsi\"";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Existing accepted_smp_status and require_pr_smp_evidence revalidate4/12: eight exact PR/control fixtures at each p1/p2 topology, one300/295 whole/inner budget,7.19708179 seconds and a producer-bound private-constructor projection retaining assertions. Canonical65a4a2e2 is explicitly related to published32028f5d.";
  attribute :>> required="Retain the pinned manifest and original references, source/generator/header/runtime identities, real topology probes, all natural case exits and projection digest. Preserve historical3/12 evidence and require fresh equivalence for dirty source changes. This family does not close original stress, request capacity, GC/FFI or current remote CI.";
  attribute :>> gap="This turn revalidates retained evidence with the existing framework, without native reruns. No current dirty-candidate or all-SMP performance/peak claim follows.";
  ref part :>> question=cutSource;
 }
}
