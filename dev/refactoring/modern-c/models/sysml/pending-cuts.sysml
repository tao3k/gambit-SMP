package GambitPendingCuts {
  private import ScalarValues::*;
  ref part plan=GambitModernCDeliveryPlan::roots;
  attribute baseline:String="b39f694498c5dec23dcbffd21ffaeb58e57a49ce";
  attribute submissionBatch:String="Binding-read activation a9b896c4 closes one complete21-file owner after five gates; The accepted queue has51 later paths; this active19-file generated SFUN owner adds18 new status paths plus one shared test Make path. The live pre-commit inventory is69 paths; source-path count grants no progress. Shared-file residual hunks remain unqualified. Foundation4/4 and independent SMP1/12 unchanged.";
  attribute derivedPolicy:String="A published generated cohort supersedes only producer-derived outputs. Preserve prior HEAD/index/working blob identities as evidence; never merge handwritten edits into generated C. Remaining Scheme generators retain their unqualified source responsibility and must regenerate their own cohort after closure. A selected handwritten path retires only when every residual hunk/version has an explicit disposition.";
  attribute policy:String="Pending file assignment is a review queue, not admission. One path can contain several hunks owned by later cuts; selected tree and five gates choose each commit. Native SysML drives the exact path inventory and ASCENT rejects missing/duplicate owners and unqualified promotion. Generated C has producer disposition, not an independent code REV. UI counts, index paths, net HEAD changes and cancelled staged deletions are separate observations.";
  attribute indexPolicy:String="Capture HEAD/index/working independently. Current92 status paths include one backend Scheme file whose working bytes equal HEAD but whose index holds an obsolete layout.85 staged statuses are not85 ready changes. Exact source/model snapshots and shared-hunk review, not UI counts, choose a future REV.";
  attribute deliveryPolicy:String="The15 units are primary review/hunk owners for127 paths, not main progress or15 promised commits. GambitModernCOutcomes drives four complete integration results. Entry-root registration/write/exit hunks feed frozen roots; affine-resource effects and unknown retirement feed owned lifetime. The broad entry unit is not wholly required before roots, and early hunks do not close that whole unit. Include tests/build/ABI changes with their real consumer and preserve every other version.";
  attribute exitPolicy:String="After every admitted REV compare all three versions and actual producer lineage again. Primary path ownership is not hunk admission: configure/header, mem.h/root-entry and tests/makefile consumers have explicit shared responsibilities. Source-only observations do not close an independent SMP family.";
  attribute nextSourceEvidence:String="First reconcile stale backend/header/allocator/marker dialects with bd0991ed. Then admit whole header-organization or entry/root/lifecycle consumer replacements with original tests. Existing old CI failures and missing exact-head CI stay separately attributed; no old patch credit.";
  part def Cut { ref part stage:GambitModernCDeliveryPlan::Stage; attribute id:String; attribute responsibility:String; attribute tests:String; attribute blocker:String; attribute ordering:String; attribute paths:String; attribute status:String; }
  part headers:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::headerStage;
    attribute :>> id="headers";
    attribute :>> responsibility="Existing monolithic header layout and all consumers";
    attribute :>> tests="Layout identity, all290 assertions, MSVC constant expressions, old module refusal, C23 bootstrap";
    attribute :>> blocker="Exact include composition and ABI identity; pending header fragments are not admitted";
    attribute :>> ordering="independent scoped layout prerequisite";
    attribute :>> paths="include/_gambit/activity_log.h.in;include/_gambit/code_generation.h.in;include/_gambit/compiler.h.in;include/_gambit/configuration.h.in;include/_gambit/declarations_begin.h.in;include/_gambit/declarations_end.h.in;include/_gambit/foreign_abi.h.in;include/_gambit/foreign_conversion.h.in;include/_gambit/global_state.h.in;include/_gambit/gvm_operations.h.in;include/_gambit/gvm_registers.h.in;include/_gambit/header_begin.h.in;include/_gambit/header_end.h.in;include/_gambit/integer_representation.h.in;include/_gambit/label_types.h.in;include/_gambit/labels.h.in;include/_gambit/language.h.in;include/_gambit/math.h.in;include/_gambit/memory_state.h.in;include/_gambit/module_generation.h.in;include/_gambit/module_state.h.in;include/_gambit/native_platform.h.in;include/_gambit/native_types.h.in;include/_gambit/object_access.h.in;include/_gambit/object_tags.h.in;include/_gambit/platform.h.in;include/_gambit/processor_os.h.in;include/_gambit/processor_state.h.in;include/_gambit/runtime_forwards.h.in;include/_gambit/runtime_protocols.h.in;include/_gambit/runtime_roles.h.in;include/_gambit/setup_parameters.h.in;include/_gambit/signals.h.in;include/_gambit/stack_operations.h.in;include/_gambit/synchronization.h.in;include/_gambit/temporary_roots.h.in;include/_gambit/utilities.h.in;include/_gambit/value_types.h.in;include/_gambit/visibility.h.in;include/_gambit/vm_state.h.in;include/_gambit/write_authority.h.in;include/config.h.in;include/gambit.h.in;include/makefile.in;tests/frame-contract.c;tests/frame-spec.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part roots:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::roots;
    attribute :>> id="roots";
    attribute :>> responsibility="All root source adapters and actual writer closure";
    attribute :>> tests="Existing RC/bank/stack/symkey/globals PBT, moving roots, nonzero processor, caller census and failures";
    attribute :>> blocker="Remaining raw writers and full source/exit census, not a one-time mark_rc";
    attribute :>> ordering="after current getters; before independent worker composition";
    attribute :>> paths="lib/_mem/continuation-roots.inc;lib/_mem/global-bindings.inc;lib/_mem/hash-table-api.inc;lib/_mem/rc-allocation.inc;lib/_mem/rc-roots.inc;lib/_mem/root-origins.inc;lib/_mem/root-tasks.inc;lib/_mem/symbols.inc;lib/root.h;tests/frame-continuation-roots.scm;tests/frame-continuation.scm;tests/gc-root-task.c;tests/rc-root-origin.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part capacity:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="capacity";
    attribute :>> responsibility="Physical copy/restoration reservations and unique allocation authority";
    attribute :>> tests="Census bound, contiguous prefix certificate, pre-reserve source contention and unknown failure custody";
    attribute :>> blocker="Complete source/frame upper bounds and real physical layout; never increase heap";
    attribute :>> ordering="after complete frozen root population";
    attribute :>> paths="lib/_mem/aligned-allocation.inc;lib/_mem/allocation-limits.inc;lib/_mem/allocation-statistics.inc;lib/_mem/capacity-resize.inc;lib/_mem/copy-planning.inc;lib/_mem/copy-reservations.inc;lib/_mem/heap-sections.inc;lib/_mem/movable-sections.inc;lib/_mem/object-allocation.inc;lib/_mem/permanent-allocation.inc";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part workers:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="workers";
    attribute :>> responsibility="Collector worker task ownership and W!=R restoration";
    attribute :>> tests="W<R, claimed/private/Tail work, worker exit, map multi-shot GC and unknown join";
    attribute :>> blocker="No carrier-index authority; all root tasks and restoration owners accounted";
    attribute :>> ordering="after roots and capacity";
    attribute :>> paths="lib/_mem/collection-round.inc;lib/_mem/configuration.inc;lib/_mem/diagnostics.inc;lib/_mem/memory-lifecycle.inc;lib/_mem/object-scanning.inc;lib/_mem/still-refcount.inc;lib/_mem/still-sweep.inc;lib/_mem/weak-tables.inc;lib/_mem/wills.inc;lib/collector.h;lib/mem.c;lib/mem.h;tests/makefile.in;tests/runtime-roles.c;tests/smp/gc/native-fault-adapter.c;tests/smp/gc/native-fault-calibration.c;tests/smp/gc/worker-arena.scm;tests/smp/gc/worker-root-domains.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part retirement:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::retirement;
    attribute :>> id="retirement";
    attribute :>> responsibility="VM membership publication and resource-specific retirement";
    attribute :>> tests="Partial startup/create/join/unknown results, healthy VM continues GC";
    attribute :>> blocker="All roots/worker debts transferred; unknown owner cannot be declared dead by timeout";
    attribute :>> ordering="after roots and workers";
    attribute :>> paths="lib/_setup/vm-lifecycle.inc;lib/_setup/vm-registry.inc;lib/setup.c;tests/smp/gc/unknown-join-worker-domains.scm;tests/smp/gc/vm-lifecycle-host.scm;tests/smp/gc/vm-lifecycle.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part scheduling:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::scheduling;
    attribute :>> id="scheduling";
    attribute :>> responsibility="FIFO mailbox lock/publication and service activation ownership";
    attribute :>> tests="Official scheduler populations, ordered shared values, real PBT replay/shrink";
    attribute :>> blocker="Separate source-root freeze, lock handoff and request service activation; repair9 remains independent workload";
    attribute :>> ordering="after root and retirement contracts";
    attribute :>> paths="lib/_fifo#.scm;lib/_io.scm;lib/_thread.scm;lib/os_thread.c;tests/ordered-sync.c;tests/smp/scheduler/mailbox-permit-roots.scm;tests/smp/scheduler/mailbox-publication.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part entries:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::entries;
    attribute :>> id="entries";
    attribute :>> responsibility="FFI write authority and acquired-effect cleanup";
    attribute :>> tests="Actual SFUN/CFUN/catcher/marker nested exit, RC writers and Tcl lifetime";
    attribute :>> blocker="Complete writer/borrow admission and exit custody; do not promise all CFFI in first root REV";
    attribute :>> ordering="after root writer closure and worker interface";
    attribute :>> paths="lib/_kernel.scm;lib/_num.scm;lib/_system.scm;lib/c_intf.c;lib/c_intf.h;lib/native_scope.c;lib/native_scope.h;lib/os_dyn.c;lib/os_setup.c;lib/write_authority.c;lib/write_authority.h;tests/native-scope.c;tests/sfun-exit.scm;tests/write-authority.c";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part build:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
    attribute :>> id="build";
    attribute :>> responsibility="Canonical generation/configuration/compile invalidation and reuse";
    attribute :>> tests="Same cache two builds, C-only rebuild, complete source bootstrap and official tests";
    attribute :>> blocker="Source/tool/profile identity and failed producer custody; no new executor/profile";
    attribute :>> ordering="parallel support lane; commit only minimal audited slices";
    attribute :>> paths="bin/makefile.in;configure.ac;gsc/_t-cpu-abstract-machine.scm;gsc/igsc.scm;gsc/makefile.in;gsi/makefile.in;lib/makefile.in;tests/run-unit-tests.scm";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part ci:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::assurance;
    attribute :>> id="ci";
    attribute :>> responsibility="Publish only validated test entrypoints and manifests";
    attribute :>> tests="Actual GitHub jobs on exact revision, namespaced existing tests, fixed limits";
    attribute :>> blocker="Do not fold runtime fixes into workflow edits or infer remote green from local";
    attribute :>> ordering="after referenced source and test targets are published";
    attribute :>> paths=".github/workflows/smp.yml";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  part generated:Cut {
    ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
    attribute :>> id="generated";
    attribute :>> responsibility="Exact generated C cohort follows its qualified Scheme producer";
    attribute :>> tests="Reproducible complete cohort and distribution source/tool identity";
    attribute :>> blocker="Never a standalone handwritten REV; do not commit partial stale generated products";
    attribute :>> ordering="attached to its producing source cut";
    attribute :>> paths="gsc/_t-cpu-abstract-machine.c;lib/_io.c;lib/_module.c;lib/_nonstd.c;lib/_num.c;lib/_system.c";
    attribute :>> status="UNQUALIFIED_PENDING";
  }
  attribute collectorSourceExtension:String="The historical127-path pending catalogue predates the complete second cut. Add copy-planning.inc to capacity and collector.h to workers as primary owners; these are source paths in one integration result, not new progress units. The tested selected source tree owns shared-file hunks and preserves unrelated staged prototypes.";
  part def Delivery {
    ref part stage:GambitModernCDeliveryPlan::Stage;
    attribute id:String; attribute order:Integer; attribute kind:String;
    attribute audit:String; attribute scope:String; attribute retire:String;
    attribute tests:String; attribute benefit:String; attribute cost:String;
    attribute admission:String; attribute status:String;
  }
  part headerDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::headerStage;
    attribute :>> id="header-layout"; attribute :>> order=1; attribute :>> kind="revision"; attribute :>> audit="10.1";
    attribute :>> scope="Lossless gambit.h composition and its actual include/build consumers; exclude semantic context/worker/FFI field additions from the mechanical extraction";
    attribute :>> retire="Monolithic ownership only, with byte/token/ABI identity; never bundle pending semantic layouts to claim losslessness";
    attribute :>> tests="Recomposition equality, all290 assertions, official bootstrap/consumers, old-module refusal; MSVC constant-expression qualification on actual CI";
    attribute :>> benefit="One owner per header concern and smaller audit surface"; attribute :>> cost="Include/dependency maintenance; zero unproved runtime performance gain";
    attribute :>> admission="Exact pre/post representation and official names; local versus MSVC remote status separate"; attribute :>> status="REVIEWABLE_SUPPORT";
  }
  part borrowDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::roots;
    attribute :>> id="root-borrowers"; attribute :>> order=2; attribute :>> kind="revision"; attribute :>> audit="3.5.2";
    attribute :>> scope="Remaining actual RC/native-entry borrowers and exceptional release after published Tcl construction, explicit marker input and permanent identity callback snapshot3.5.2.3. Callback3.5.2.4 is published043a9341 under explicit scoped baseline classification; nonlocal/cross-owner duties remain. Audit false C-closure identity/ABI, callback read/delete/drain and conversion-bank/nonlocal paths; avoid redundant roots for permanent/already-rooted values";
    attribute :>> retire="Unowned payload/address use across actual allocation/reentry; do not introduce a root handle for a read already after the last GC-capable call";
    attribute :>> tests="Existing RC/root-task PBT extended only for the selected real caller; moving GC, nested entry/error/last release; same source producer and official consumers";
    attribute :>> benefit="Explicit source-to-marker/callback root custody and reload"; attribute :>> cost="Measure any extra root record/borrow/lock; no speculative benefit for redundant pinning";
    attribute :>> admission="Identify actual GC/reentry interval and native lifetime owner; address borrowing and logical referent ownership differ. Construction3.5.2.1 is published920cf0c7 and marker input3.5.2.2 is publishede6a80bcb; permanent native callback3.5.2.3 is published4b9d8656; cross-owner/foreign lifetime, deletion/nonlocal exit and callback gaps still block complete3.5.2"; attribute :>> status="PARTIAL_PUBLISHED_SOURCE_AUDIT_REMAINS";
  }
  part writerDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::roots;
    attribute :>> id="root-value-writers"; attribute :>> order=3; attribute :>> kind="revision"; attribute :>> audit="3.5";
    attribute :>> scope="Remaining globals/primitive/denv/frame/FFI value stores; select one source-freeze/write-admission family per complete cut";
    attribute :>> retire="Raw stores outside the owning source protocol and implicit allocation/safepoint effects";
    attribute :>> tests="Actual producer and writer census, source freeze race, GC relocation, continuation aliases/reflection and real replay/shrink for each chosen family";
    attribute :>> benefit="Complete writer authority becomes a concrete root-scan premise"; attribute :>> cost="Store/barrier/permit cost and additional retained roots must be recorded";
    attribute :>> admission="No omitted raw generator/FFI store; reject affected unknown writer rather than assuming coverage"; attribute :>> status="SOURCE_CENSUS_REQUIRED";
  }
  part censusDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::roots;
    attribute :>> id="root-lifetime-union"; attribute :>> order=4; attribute :>> kind="revision"; attribute :>> audit="3.6";
    attribute :>> scope="Compose all six root kinds, writer/borrow closure, frozen view lifetime, task publication/claim/scan/exit";
    attribute :>> retire="Carrier-index lookup and unclaimed/implicitly lived root sources";
    attribute :>> tests="Complete real caller union, processor0/nonzero, source detach/failure, map multi-shot/GC and implementation replay/shrink; unchanged existing QNT/Lean duties";
    attribute :>> benefit="Root lifetime independent of executing carrier"; attribute :>> cost="Explicit root/task lease metadata and synchronization";
    attribute :>> admission="Every live source/writer/loan has one custodian; unknown exits retain custody"; attribute :>> status="BLOCKED_ROOT_WRITERS";
  }
  part censusCapacity:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="copy-census"; attribute :>> order=5; attribute :>> kind="revision"; attribute :>> audit="4.1";
    attribute :>> scope="Complete source object/frame physical bounds before copying, allocation checks and restoration obligations";
    attribute :>> retire="Late capacity guesses based only on participant count";
    attribute :>> tests="Actual rest/structure/frame constructors, sparse layout/endpoints, overflow/refusal, exact byte census and fixed-heap official cases";
    attribute :>> benefit="Capacity refusal precedes irreversible copy publication"; attribute :>> cost="Census work/metadata and conservative peak bound";
    attribute :>> admission="Real writers/layouts bounded; no extra heap or timeout to manufacture a pass"; attribute :>> status="BLOCKED_ROOT_UNION";
  }
  part packingDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="copy-intervals"; attribute :>> order=6; attribute :>> kind="revision"; attribute :>> audit="4.2";
    attribute :>> scope="Source-section unique copy right, contiguous interval packing, CAS-loss refund and first restoration reservation";
    attribute :>> retire="Overlapping/insufficient reservations and refund without physical custody";
    attribute :>> tests="Copy before publication, real CAS-loss/refund, partial/unknown result, no aliasing interval and whole-round peak accounting";
    attribute :>> benefit="One physical capacity decision shared by copying and restore"; attribute :>> cost="Reservation records, fragmentation and retained unknown intervals";
    attribute :>> admission="Every charged byte maps to a real interval and exactly one owner"; attribute :>> status="BLOCKED_COPY_CENSUS";
  }
  part arenaDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="worker-arenas"; attribute :>> order=7; attribute :>> kind="revision"; attribute :>> audit="4.3";
    attribute :>> scope="Worker-owned copy/scan arenas and task acquisition; W independent of R without changing counters alone";
    attribute :>> retire="PSTATE/carrier identity as collector storage or root-task ownership";
    attribute :>> tests="W<R/W=R, unique scan, private frontier/Tail/batch histories, worker exit and real implementation replay/shrink";
    attribute :>> benefit="Collector concurrency chosen independently from execution contexts"; attribute :>> cost="Arena/queue coordination, bounded private state and task claims";
    attribute :>> admission="No unfinished private copy/Tail loses custody on transfer or unknown exit"; attribute :>> status="BLOCKED_ROOTS_AND_CAPACITY";
  }
  part restoreDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::workers;
    attribute :>> id="context-restoration"; attribute :>> order=8; attribute :>> kind="revision"; attribute :>> audit="4.4";
    attribute :>> scope="R context restore/root domains serviced by W workers, thread-affine cleanup and whole-round resume seal";
    attribute :>> retire="One worker implicitly restores only its matching processor";
    attribute :>> tests="W<R roots, map multi-shot/dynamic-wind, recovery interval identity, delayed cleanup and finite admitted restore tasks";
    attribute :>> benefit="All contexts resume once without requiring matching collector carriers"; attribute :>> cost="Restore tasks/seal, affinity delivery and conservative unknown-state retention";
    attribute :>> admission="GC completion includes all restoration/cleanup obligations, not merely an empty mark queue"; attribute :>> status="BLOCKED_WORKER_ARENAS";
  }
  part retirementDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::retirement;
    attribute :>> id="member-retirement"; attribute :>> order=9; attribute :>> kind="revision"; attribute :>> audit="7";
    attribute :>> scope="Setup/member publication, partial creation, exit and per-resource retirement with unknown join isolation";
    attribute :>> retire="Global reclamation permission inferred from one VM/thread outcome";
    attribute :>> tests="Actual partial-create/join-failed/unknown histories, source ACK, roots transferred, healthy VM continues GC";
    attribute :>> benefit="Unknown owner debt scoped to affected resources"; attribute :>> cost="Quarantine retention/receipts and explicit close protocol";
    attribute :>> admission="No timeout proves thread death; global resources reclaim only with complete resource-specific evidence"; attribute :>> status="BLOCKED_RESTORE_AND_ROOTS";
  }
  part activationDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::entries;
    attribute :>> id="entry-write-authority"; attribute :>> order=10; attribute :>> kind="revision"; attribute :>> audit="6";
    attribute :>> scope="Generated SFUN/CFUN/catcher and marker entry/exit share write/borrow authority and acquired-effect cleanup; remove superseded native_scope names directly";
    attribute :>> retire="Implicit PSTATE lifetime and parallel legacy/new scope namespaces";
    attribute :>> tests="Real generator/catcher callers, nested callback/nonlocal exit, marker allocation failure and exact writer/loan drain";
    attribute :>> benefit="One owner for entry effects and exceptional cleanup"; attribute :>> cost="Activation/permit records and affinity/exit bookkeeping";
    attribute :>> admission="No extra compatibility alias; all acquired effects have exception/unknown-result custodian"; attribute :>> status="BLOCKED_ROOT_AND_RETIREMENT_INTERFACES";
  }
  part schedulerDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::scheduling;
    attribute :>> id="request-mailbox-service"; attribute :>> order=11; attribute :>> kind="revision"; attribute :>> audit="5";
    attribute :>> scope="Separate wait state from service activation, FIFO/lock handoff and shared mailbox root publication";
    attribute :>> retire="Repeated scheduler continuation materialization for immediate outcomes and implicit request ownership";
    attribute :>> tests="Original ordered shared values, thread interrupt failure retained, real stateful replay/shrink and Repair9 at its unchanged population";
    attribute :>> benefit="Avoid unnecessary capture/GC work where control semantics permit"; attribute :>> cost="Queue/activation bookkeeping, actual latency/backlog/peak must be measured";
    attribute :>> admission="Not a root REV or relocated repair patch; preserve arbitrary user multi-shot continuation"; attribute :>> status="DEFERRED_SEPARATE_ARCHITECTURE";
  }
  part toolchainDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::toolchain;
    attribute :>> id="c23-toolchain"; attribute :>> order=12; attribute :>> kind="revision"; attribute :>> audit="11";
    attribute :>> scope="Existing configure/Bazel C23 parameter and platform contract; only configuration hunks necessary for the selected source";
    attribute :>> retire="Unqualified implicit tool/feature assumptions";
    attribute :>> tests="Existing profile/configure equivalence, GCC/Clang/MSVC supported cells and complete official producer";
    attribute :>> benefit="One effective toolchain identity"; attribute :>> cost="Platform matrix maintenance; no new profile/executor";
    attribute :>> admission="Retain official names/commands and fixed limits; unsupported cells remain explicit"; attribute :>> status="REVIEWABLE_SUPPORT";
  }
  part buildDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
    attribute :>> id="incremental-producer"; attribute :>> order=13; attribute :>> kind="revision"; attribute :>> audit="12.2";
    attribute :>> scope="Existing Make producer dependency/currentness and same-workspace exact artifact reuse; necessary source/test build glue accompanies each actual consumer";
    attribute :>> retire="Regenerating unaffected Scheme products for C-only edits and losing an admitted producer on failure";
    attribute :>> tests="Two same-cache builds, C-only edit, Scheme/macro invalidation, exact source/tool/cwd/product receipts and unchanged watchdog";
    attribute :>> benefit="Avoid actual unnecessary generation/configuration/compile work"; attribute :>> cost="Dependency/currentness metadata checks; no second scheduler";
    attribute :>> admission="Measure each skipped phase; no invented cache-hit percentage or frontend optimization detour"; attribute :>> status="REVIEWABLE_SUPPORT";
  }
  part distributionDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
    attribute :>> id="generated-distribution"; attribute :>> order=14; attribute :>> kind="attached-product"; attribute :>> audit="12.3";
    attribute :>> scope="All checked-in generated C follows one qualified Scheme producer/features/tool cohort";
    attribute :>> retire="Partial stale generated products and handwritten generated C fixes";
    attribute :>> tests="Reproduce complete cohort, stage counts, exact output hashes, distribution bootstrap and actual consumers";
    attribute :>> benefit="Reproducible source distribution and bootstrap seed"; attribute :>> cost="Producer work/output storage; generated diffs are audited as products";
    attribute :>> admission="Attached to its producing source cut; never a standalone handwritten code REV"; attribute :>> status="ATTACHED_NOT_INDEPENDENT";
  }
  part ciDelivery:Delivery {
    ref part :>> stage=GambitModernCDeliveryPlan::assurance;
    attribute :>> id="qualified-ci"; attribute :>> order=15; attribute :>> kind="revision"; attribute :>> audit="13";
    attribute :>> scope="Vendor GitHub workflow only references already qualified official or necessary architecture test entrypoints";
    attribute :>> retire="Workflow names/targets/manifests drifting from actually published source";
    attribute :>> tests="Actual remote jobs on exact revision; complete local manifests; preserve official names and limits";
    attribute :>> benefit="Repeatable cross-platform audit of published responsibilities"; attribute :>> cost="CI compile/execution budget; queued/local pass is not remote green";
    attribute :>> admission="No speculative tests, wholesale workflow redesign or scheduler workaround"; attribute :>> status="BLOCKED_REFERENCED_SOURCE";
  }
  part def DeliveryEdge { ref part before:Delivery; ref part next:Delivery; }
  part e1:DeliveryEdge { ref part :>> before=borrowDelivery; ref part :>> next=censusDelivery; }
  part e2:DeliveryEdge { ref part :>> before=writerDelivery; ref part :>> next=censusDelivery; }
  part e3:DeliveryEdge { ref part :>> before=censusDelivery; ref part :>> next=censusCapacity; }
  part e4:DeliveryEdge { ref part :>> before=censusCapacity; ref part :>> next=packingDelivery; }
  part e5:DeliveryEdge { ref part :>> before=packingDelivery; ref part :>> next=arenaDelivery; }
  part e6:DeliveryEdge { ref part :>> before=censusDelivery; ref part :>> next=arenaDelivery; }
  part e7:DeliveryEdge { ref part :>> before=arenaDelivery; ref part :>> next=restoreDelivery; }
  part e8:DeliveryEdge { ref part :>> before=restoreDelivery; ref part :>> next=retirementDelivery; }
  part e9:DeliveryEdge { ref part :>> before=retirementDelivery; ref part :>> next=activationDelivery; }
  part e10:DeliveryEdge { ref part :>> before=censusDelivery; ref part :>> next=schedulerDelivery; }
  part e11:DeliveryEdge { ref part :>> before=retirementDelivery; ref part :>> next=schedulerDelivery; }
  part e12:DeliveryEdge { ref part :>> before=buildDelivery; ref part :>> next=distributionDelivery; }
  part e13:DeliveryEdge { ref part :>> before=activationDelivery; ref part :>> next=ciDelivery; }
  part e14:DeliveryEdge { ref part :>> before=restoreDelivery; ref part :>> next=ciDelivery; }
  part e15:DeliveryEdge { ref part :>> before=buildDelivery; ref part :>> next=ciDelivery; }
  part def DeliverySlice { ref part owner:Cut; ref part delivery:Delivery; attribute patterns:String; attribute omissions:String; }
  part s1:DeliverySlice { ref part :>> owner=headers; ref part :>> delivery=headerDelivery; attribute :>> patterns="*"; attribute :>> omissions=""; }
  part s2:DeliverySlice { ref part :>> owner=roots; ref part :>> delivery=writerDelivery; attribute :>> patterns="lib/_mem/rc-allocation.inc;lib/_mem/global-bindings.inc;lib/_mem/hash-table-api.inc;lib/_mem/symbols.inc;tests/rc-root-origin.scm"; attribute :>> omissions=""; }
  part s3:DeliverySlice { ref part :>> owner=roots; ref part :>> delivery=censusDelivery; attribute :>> patterns="*"; attribute :>> omissions="lib/_mem/rc-allocation.inc;lib/_mem/global-bindings.inc;lib/_mem/hash-table-api.inc;lib/_mem/symbols.inc;tests/rc-root-origin.scm"; }
  part s4:DeliverySlice { ref part :>> owner=capacity; ref part :>> delivery=censusCapacity; attribute :>> patterns="lib/_mem/allocation-limits.inc;lib/_mem/allocation-statistics.inc;lib/_mem/object-allocation.inc"; attribute :>> omissions=""; }
  part s5:DeliverySlice { ref part :>> owner=capacity; ref part :>> delivery=packingDelivery; attribute :>> patterns="*"; attribute :>> omissions="lib/_mem/allocation-limits.inc;lib/_mem/allocation-statistics.inc;lib/_mem/object-allocation.inc"; }
  part s6:DeliverySlice { ref part :>> owner=workers; ref part :>> delivery=arenaDelivery; attribute :>> patterns="lib/_mem/configuration.inc;lib/_mem/memory-lifecycle.inc;lib/mem.c;lib/mem.h;tests/runtime-roles.c;tests/smp/gc/native-fault-*;tests/smp/gc/worker-arena.scm"; attribute :>> omissions=""; }
  part s7:DeliverySlice { ref part :>> owner=workers; ref part :>> delivery=restoreDelivery; attribute :>> patterns="*"; attribute :>> omissions="lib/_mem/configuration.inc;lib/_mem/memory-lifecycle.inc;lib/mem.c;lib/mem.h;tests/runtime-roles.c;tests/smp/gc/native-fault-*;tests/smp/gc/worker-arena.scm"; }
  part s8:DeliverySlice { ref part :>> owner=retirement; ref part :>> delivery=retirementDelivery; attribute :>> patterns="*"; attribute :>> omissions=""; }
  part s9:DeliverySlice { ref part :>> owner=scheduling; ref part :>> delivery=schedulerDelivery; attribute :>> patterns="*"; attribute :>> omissions=""; }
  part s10:DeliverySlice { ref part :>> owner=entries; ref part :>> delivery=borrowDelivery; attribute :>> patterns="lib/c_intf.c;lib/os_dyn.c;examples/tcltk/tcltk.scm;examples/tcltk/command.h;tests/root-task.scm"; attribute :>> omissions=""; }
  part s11:DeliverySlice { ref part :>> owner=entries; ref part :>> delivery=writerDelivery; attribute :>> patterns="lib/_kernel.scm;lib/_num.scm;lib/_system.scm"; attribute :>> omissions=""; }
  part s12:DeliverySlice { ref part :>> owner=entries; ref part :>> delivery=activationDelivery; attribute :>> patterns="*"; attribute :>> omissions="lib/c_intf.c;lib/os_dyn.c;examples/tcltk/tcltk.scm;examples/tcltk/command.h;tests/root-task.scm;lib/_kernel.scm;lib/_num.scm;lib/_system.scm"; }
  part s13:DeliverySlice { ref part :>> owner=build; ref part :>> delivery=toolchainDelivery; attribute :>> patterns="configure.ac"; attribute :>> omissions=""; }
  part s14:DeliverySlice { ref part :>> owner=build; ref part :>> delivery=buildDelivery; attribute :>> patterns="*"; attribute :>> omissions="configure.ac"; }
  part s15:DeliverySlice { ref part :>> owner=generated; ref part :>> delivery=distributionDelivery; attribute :>> patterns="*"; attribute :>> omissions=""; }
  part s16:DeliverySlice { ref part :>> owner=ci; ref part :>> delivery=ciDelivery; attribute :>> patterns="*"; attribute :>> omissions=""; }

 attribute currentPackages:String="currentHeaders;currentBuild;currentEntryAdmission;currentEntries;currentCollector;currentPipe;currentWords;currentBackend;currentCi;currentCost;currentRootTests;currentRootWrite;currentAuthorityService;currentVmLayout";
 attribute currentRuntimeProgress:String="4/4 local foundation deliveries; no independent SMP or universal performance promotion";
 attribute independentSmpProgress:String="1/12 checkpoint; eleven families remain open until whole source-bound manifests qualify";
 attribute currentNetSpeedup:String="NOT_ESTABLISHED; source correctness/bounded-work benefits and measured costs must remain separate";
 part def PendingPackage { ref part stage:GambitModernCDeliveryPlan::Stage; attribute id:String; attribute paths:String; attribute depends:String; attribute scope:String; attribute tests:String; attribute benefit:String; attribute cost:String; attribute admission:String; }
 part currentHeaders:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::headerStage;
  attribute :>> id="header-composition";
  attribute :>> paths="";
  attribute :>> depends="";
  attribute :>> scope="CLOSED header organization b39f6944: forty canonical payload modules, exact baseline bytes, all consumers and five gates. Remaining semantic header edits belong to the complete entry/root consumer chain, not another split.";
  attribute :>> tests="Token/byte recomposition, all290 layout assertions, old-module refusal, actual MSVC and unchanged-profile compiler consumers.";
  attribute :>> benefit="One declaration owner and smaller review surface; no measured runtime speedup.";
  attribute :>> cost="Source/dependency maintenance; no ABI or include performance saving inferred.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentBuild:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
  attribute :>> id="build-inputs";
  attribute :>> paths="bin/makefile.in;configure.ac;gsc/igsc.scm;gsc/makefile.in;gsi/makefile.in;include/config.h.in;include/makefile.in;tests/run-unit-tests.scm";
  attribute :>> depends="header-composition;backend-residue";
  attribute :>> scope="Split configure header-composition hunks from C23 admission/generation invalidation and original Make resource inputs. Retain one existing cache/profile; no new environment knob or runner.";
  attribute :>> tests="Exact input/configure/template/argv identities; no-change and C-only paths; original600/120/300/90 limits and immutable completed products.";
  attribute :>> benefit="Avoid repeated generation/configuration when effective inputs are unchanged.";
  attribute :>> cost="Hash/receipt work remains; cold full-build gains remain unmeasured.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentEntryAdmission:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::entries;
  attribute :>> id="rc-entry-admission";
  attribute :>> paths="";
  attribute :>> depends="header-composition";
  attribute :>> scope="Published3ab1444b: actual source registration/write/borrow and live SFUN record authorizes positive span stores; logical revoke retains physical roots but denies mutation.";
  attribute :>> tests="Exact parent revoked-write witness,17 native consumer checks including RC/SFUN p2,204 PBT actions, map multi-shot and old public modules; existing QNT13+13 cases and1000 entry traces.";
  attribute :>> benefit="Close real duplicate-registration and activation-authority bypasses without new metadata; remove actual linked argument forwarding call.";
  attribute :>> cost="Extra kind/identity guards; mixed0/1/8 timings -3.063%/+2.129%/-4.160%; no stable whole speedup or peak claim.";
  attribute :>> admission="PUBLISHED3ab1444b; complete declared RC/SFUN owner only, not general FFI/startup/resize or whole SMP";
 }
 part currentEntries:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::entries;
  attribute :>> id="entry-write-authority";
  attribute :>> paths="lib/_num.scm;lib/_system.scm;lib/_thread.scm;lib/mem.h;lib/os_setup.c";
  attribute :>> depends="header-composition;rc-entry-admission";
  attribute :>> scope="Remaining context/startup/resize/interrupt sources after the complete RC/SFUN admission owner3ab1444b. This five-file queue does not inherit its runtime acceptance. One complete writer/borrow/root-entry/exception consumer chain. Rename pairs and marker/root/resize declarations must be reconciled with the published ABI; remaining mem.h declarations require separate resize/global ownership. Startup-ready guards require real generation and completion authority.";
  attribute :>> tests="Actual C/FFI generator, normal/throw/catcher/GC/borrow/refusal paths; existing Scheme replay/shrink and old module refusal; no parallel namespace.";
  attribute :>> benefit="One entry writer authority and explicit root/exception custody, preserving multi-shot Scheme semantics. Complete SFUN owner13104c8a now owns one root span through physical C exit; VM layout retirement is separately blocked and general raw native APIs remain separate. The admitted binding-read activation a9b896c4 moves owner proof to lifecycle entry and module executable publication, with no per-host admission/cache or repeated permit/epoch metadata. A context-owned logical VM capability must preserve current-directory and value/presence acquire reads, local primitive overrides, reader drain, PointId/frame roots and multi-shot restoration; never cache moving Scheme values.";
  attribute :>> cost="Leases, root cells and cleanup debt; broad CFFI is not already accepted.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentCollector:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::workers;
  attribute :>> id="collector-source-review";
  attribute :>> paths="lib/_mem/aligned-allocation.inc;lib/_mem/allocation-limits.inc;lib/_mem/allocation-statistics.inc;lib/_mem/diagnostics.inc;lib/_mem/hash-table-api.inc;lib/_mem/object-allocation.inc;lib/_mem/permanent-allocation.inc;lib/_mem/still-refcount.inc;lib/_mem/symbols.inc";
  attribute :>> depends="entry-write-authority";
  attribute :>> scope="Separate5 coordinate-only deltas from real diagnostics, allocation/release and symbol ownership. Pending permanent allocation removes the published lock; pending symbols remove published bounds/publication checks. Reject those as a current implementation until a complete replacement owner is proven. GC-phase allocation refusal needs initialization/resource debt custody, not just an early error.";
  attribute :>> tests="Real allocator/release/root callers, pre-reserve and unknown outcomes, debug coordinate provenance, GC/reentry and scan ownership. Rebase allocation counters across context/carrier/GC boundaries: negative request-only bytes forbid physical allocation or peak-memory claims until a complete accounting contract is refined.";
  attribute :>> benefit="Preserve the published root/worker contract while replacing real remaining ownership gaps.";
  attribute :>> cost="No benefit from line churn or removing synchronization; reservation and retention overhead stay explicit.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentPipe:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::scheduling;
  attribute :>> id="pipe-domain-owner";
  attribute :>> paths="";
  attribute :>> depends="header-composition";
  attribute :>> scope="Published4b9ac843: one managed guard per aliased vector/string/u8 pipe pair across construction, wait, close and exception exit.";
  attribute :>> tests="Existing production p1 profile34 official IO cases, native stateful replay/shrink, p2 exchange, six hook exits, frame/root consumers and finite Quint owner model.";
  attribute :>> benefit="Retire independent locks over shared FIFO/cursor state and remove one mutex record per pair.";
  attribute :>> cost="Shared-domain contention remains; no universal wall or peak gain. Original default GSC and whole-suite negatives remain unresolved.";
  attribute :>> admission="PUBLISHED4b9ac843; qualified C target only; no whole-SMP or default compiler admission";
 }
 part currentWords:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::scheduling;
  attribute :>> id="ordered-word-fallback";
  attribute :>> paths="lib/os_thread.c;tests/ordered-sync.c";
  attribute :>> depends="header-composition";
  attribute :>> scope="Remaining portable word-fetch-add arithmetic and real lock/sync service tests. Peer-pipe ownership is separately qualified in4b9ac843; thread create/join formatting is not an architectural benefit.";
  attribute :>> tests="Actual public word/ticket/sync operations including wrap and real fallback compiler cohort; exercising only GCC builtins cannot qualify unused fallback code.";
  attribute :>> benefit="Defined modulo arithmetic in the existing fallback interface, independently of pipe-domain ownership.";
  attribute :>> cost="No measured speedup; synchronization and compiler-portability proof remain required.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; complete atomic fallback responsibility and five gates before publication. Do not merge these two paths into the already qualified Scheme pipe owner.";
 }
 part currentBackend:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::buildGraph;
  attribute :>> id="backend-residue";
  attribute :>> paths="gsc/_t-cpu-abstract-machine.c;gsc/_t-cpu-abstract-machine.scm";
  attribute :>> depends="";
  attribute :>> scope="The working Scheme backend equals HEAD while the index restores obsolete carrier offsets; the lone generated C delta has no admitted producer. Preserve/review its three versions and retire or regenerate through its real producer, never commit generated bytes alone.";
  attribute :>> tests="HEAD/index/working identity plus actual generator cohort/PointId and layout consumers if any source is retained.";
  attribute :>> benefit="Remove a stale publication candidate that could undo execution-context storage.";
  attribute :>> cost="No runtime gain assigned to deleting a staged prototype.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentCi:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::assurance;
  attribute :>> id="ci-consumer";
  attribute :>> paths=".github/workflows/smp.yml";
  attribute :>> depends="header-composition;build-inputs;entry-write-authority;collector-source-review;root-worker-qualification;pipe-domain-owner;ordered-word-fallback;backend-residue;cost-fixture";
  attribute :>> scope="Vendor Gambit only. The pending SMP workflow is not current CI and contains a custom tool variable; reconcile with standard tool inputs and the exact published source/test contract before activation. Existing official workflow names/build commands remain.";
  attribute :>> tests="Actual exact-head GitHub jobs on required platforms; source/distribution tests, original limits and unchanged check population.";
  attribute :>> benefit="Remote verification of the real responsibility replacement.";
  attribute :>> cost="Runner/build cost; enabled workflow or old queued jobs do not qualify the new head.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentCost:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::qualification;
  attribute :>> id="cost-fixture";
  attribute :>> paths="tests/smp/scheduler/request-service-cost.scm";
  attribute :>> depends="";
  attribute :>> scope="Binding-read activation a9b896c4 publishes the complete4096-request and composed8192-resume/16-GC measurement source. Only its unqualified physical-placement option remains in the working version; retain that hunk for a whole routing/workload attribution, not another baseline timing claim.";
  attribute :>> tests="Same old/current modules,4096 requests/8192 resumes/16 GC, real topology and local-counter semantics; replay all samples and retain prior regressions. Materialize signed binary products by exact digest and fresh-inode replacement under the existing lease; preserve the kernel invalid-page counterexample.";
  attribute :>> benefit="Auditable measurements and reproducible cost attribution.";
  attribute :>> cost="No proven aggregate positive net speedup; p2 routing and per-processor accounting prohibit VM-total allocation claims.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 part currentRootTests:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::qualification;
  attribute :>> id="root-worker-qualification";
  attribute :>> paths="tests/frame-continuation-roots.scm;tests/frame-continuation.scm;tests/gc-root-task.c;tests/makefile.in;tests/rc-root-origin.scm;tests/root-task.scm;tests/runtime-roles.c;tests/smp/gc/global-storage.scm;tests/smp/gc/native-fault-adapter.c;tests/smp/gc/native-fault-calibration.c;tests/smp/gc/unknown-join-worker-domains.scm;tests/smp/gc/worker-arena.scm;tests/smp/gc/worker-root-domains.scm";
  attribute :>> depends="entry-write-authority;collector-source-review";
  attribute :>> scope="Tests follow their actual current source APIs: frame/RC/task roots, W<R, worker arenas, unknown join and fault calibration. Test Make hunks are shared with entry rename. Existing case names and all assertions remain; these files are not another test framework.";
  attribute :>> tests="Current producer, real root relocation/multi-shot/exit, fault-adapter calibration, actual replay and same-signature shrink; separate source periods and no SMP credit from a focused leaf.";
  attribute :>> benefit="Turn source assumptions into current implementation counterexamples and larger-family manifests.";
  attribute :>> cost="Test/native product storage and execution; no source change is admitted by a fixture alone.";
  attribute :>> admission="REVIEW_QUEUE_ONLY; one full responsibility/consumer contract plus five gates; no file-count or support progress";
 }
 attribute completeDeliveryRule:String="Nine primary review owners are not nine commits. First reconcile/retire obsolete staged or generated versions with recovery evidence. Then one lossless header responsibility, one full entry/root/lifecycle consumer replacement, and one pipe/publication consumer replacement may qualify as separate whole REVs; build/CI/cost hunks accompany their true owner. None automatically increments the already4/4 foundation axis or independent SMP numerator.";
 attribute currentRoutes:String="route1;route2;route3;route4;route5;route6;route7;route8;route9;route10;route11;route12";
 part def CurrentRoute { ref part family:GambitModernCDeliveryPlan::AcceptanceFamily; attribute status:String; attribute depends:String; attribute work:String; attribute evidence:String; attribute modelDuty:String; }
 part route1:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a1;
  attribute :>> status="CHECKPOINT_REQUIRES_EXACT_EPOCH_ATTACHMENT";
  attribute :>> depends="";
  attribute :>> work="Keep the existing accepted bootstrap family; attach exact publication/source-generation/artifact equivalence for bd0991ed. Cold reexecution is not silently asserted.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Source generation and artifact custody, existing frame/capacity laws; no duplicated QNT/Lean.";
 }
 part route2:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a2;
  attribute :>> status="OPEN";
  attribute :>> depends="bootstrap";
  attribute :>> work="Run the complete current non-stress GSI manifest at its declared p1/p2 topology and dispose the retained interruption veto by same-condition source evidence; p1 timing positives alone do not close the family.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing thread/interruption QNT histories; actual whole native inventory.";
 }
 part route3:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a3;
  attribute :>> status="OPEN";
  attribute :>> depends="bootstrap";
  attribute :>> work="Compile and execute every current original unit and audit natural completion under unchanged300/numeric90 budgets. Preserve fxmul failure and numeric censor; classify baseline debt separately from complete family acceptance.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Native compiler/result population, existing frame/GC laws; no timing theorem.";
 }
 part route4:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a4;
  attribute :>> status="OPEN";
  attribute :>> depends="gsi";
  attribute :>> work="Freeze the additional PR-regression manifest from the branch source/PR ledger, then interpret every case with exact current artifacts and assertions.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Source-bound manifest and implementation regression observations.";
 }
 part route5:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a5;
  attribute :>> status="OPEN";
  attribute :>> depends="gsc";
  attribute :>> work="Compile and execute that same complete additional PR manifest; no focused serialization/pipe subset closes it.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Actual native compilation/execution and existing control/GC contracts.";
 }
 part route6:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a6;
  attribute :>> status="OPEN";
  attribute :>> depends="gsi;registry;lifecycle";
  attribute :>> work="Run all original interpreted stress populations and fixed parameters; retain tfib/interruption/termination failures as architecture counterexamples, with no heap or wait change.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing request/queue/registry temporal QNT and implementation PBT, separate Lean roots.";
 }
 part route7:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a7;
  attribute :>> status="OPEN";
  attribute :>> depends="gsc;registry;lifecycle";
  attribute :>> work="Run the complete original compiled stress populations under the same inputs/limits; support products and repaired-line history grant no credit.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Same temporal QNT owners plus actual native stress; no duplicated Lean schedules.";
 }
 part route8:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a8;
  attribute :>> status="OPEN";
  attribute :>> depends="gsi;gsc";
  attribute :>> work="Compose shared registry identity, concurrent resize/reuse/readers and retirement on the current producer; include refused/unknown membership outcomes and real progress.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing vm_registry and vm_resize_transaction QNT; separate interval/identity laws.";
 }
 part route9:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a9;
  attribute :>> status="OPEN";
  attribute :>> depends="registry";
  attribute :>> work="Complete constructor/partial creation/rollback/retry/join-failure manifest, including healthy VM progress and retained native debt; one startup target is scoped evidence.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing lifecycle/resize/retained-resource QNT, actual faults and replay/shrink.";
 }
 part route10:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a10;
  attribute :>> status="OPEN";
  attribute :>> depends="gsc;lifecycle";
  attribute :>> work="Close actual complete FFI/GC writers, conversions, blocking/nested callbacks, roots and exceptional exits. Original test7/8/9 remain fixtures within the manifest.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing activation/RC/cleanup temporal QNT; existing Lean frame/root/interval premises.";
 }
 part route11:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a11;
  attribute :>> status="OPEN";
  attribute :>> depends="gsi;gsc;pr-gsi;pr-gsc";
  attribute :>> work="Retain completed326/326/740 build consumers; add the complete pinned Gerbil correctness manifest on exact current ABI/source products. Build completion does not substitute for correctness tests.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Existing incremental_build QNT and source/product receipts; actual Gerbil tests.";
 }
 part route12:CurrentRoute { ref part :>> family=GambitModernCDeliveryPlan::a12;
  attribute :>> status="OPEN";
  attribute :>> depends="gsi;gsc;pr-gsi;pr-gsc;stress-gsi;stress-gsc;registry;lifecycle;gc-ffi;gerbil";
  attribute :>> work="Measure the whole declared release workload/topologies and peak/build populations with all regressions. Cold build was excluded only from the fourth foundation REV and remains required here; do not infer whole net speedup from the small composed fixture.";
  attribute :>> evidence="Current branch/source/profile/manifest receipt, exact natural exits, failures and negative controls; no repair-line credit";
  attribute :>> modelDuty="Empirical matched populations and native counter/route attribution; no formal speedup prediction.";
 }
 attribute snapshotBoundary:String="Git and source double-read detects observed drift, but is not an atomic filesystem snapshot or an ABA-proof writer-freeze credential. Unknown writers require reobservation or refusal. No runtime admission follows from this planning model.";

 part currentRootWrite:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::entries;
 attribute :>> id="rc-root-write";
 attribute :>> paths="";
 attribute :>> depends="";
 attribute :>> scope="Complete primary/span mutator and borrower source contract; reuse accepted freeze/scan/physical-exit owners, unchanged ABI.";
 attribute :>> tests="Actual RC/SFUN replay and shrink, nonzero, frame/multi-shot consumers, old-module reuse, original full population and matched cost.";
 attribute :>> benefit="One source mutation policy and real owner check, no new metadata or permit table.";
 attribute :>> cost="Index/borrow branch and source call; timing may regress, no universal speedup.";
 attribute :>> admission="PUBLISHED b299e267, five gates and46 rejection controls; source contract complete. tests/makefile.in retains separately owned future hunks.";
 }
 part currentAuthorityService:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::entries;
 attribute :>> id="authority-service-retirement";
 attribute :>> paths="";
 attribute :>> depends="rc-entry-admission";
 attribute :>> scope="Published5c0ff489 retires whole obsolete role-service code, initializer, object/header/distribution and synthetic test. Exact VM representation unchanged.";
 attribute :>> tests="Old API success/candidate refusal, archive26→25 and10→0 symbols;20 native consumers, actual PBT/GC/p2/map multi-shot/old modules, focused division and existing QNT;48 matched/frozen samples.";
 attribute :>> benefit="Five original queue paths retired; one fewer actual competing implementation and native compilation unit. Archive -2944 bytes, selected program -672 in current profile.";
 attribute :>> cost="Dormant512-byte measured representation remains. Mixed noisy timing and frozen-sign reversal forbid universal speedup. No changed-ABI admission.";
 attribute :>> admission="PUBLISHED5c0ff489; scoped full code-service retirement only. No independent SMP or old layout-failure attribution.";
 }
 part currentVmLayout:PendingPackage { ref part :>> stage=GambitModernCDeliveryPlan::entries;
 attribute :>> id="vm-layout-retirement";
 attribute :>> paths="include/_gambit/vm_state.h.in;include/_gambit/write_authority.h.in";
 attribute :>> depends="authority-service-retirement";
 attribute :>> scope="Only two public layout-template deletions remain after code-service retirement5c0ff489. Current measured512-byte dormant storage is retained. Changed-ABI experiment and prior combined division failure remain separately unattributed.";
 attribute :>> tests="Code service: actual old-API witness/refusal, archive member/symbol absence and real current authority/root/exit consumers with exact header/layout and old modules. Layout deletion separately requires exact baseline/candidate full original populations and changed-ABI consumers.";
 attribute :>> benefit="Potential unused table removal is NOT credited to RC mutation contract.";
 attribute :>> cost="ABI/code-object consumers and unresolved combined failure.";
 attribute :>> admission="BLOCKED_NEW_FAILURE for the two layout deltas only; code-service owner5c0ff489 is already independently published. Preserve old failure, no512-byte or changed-ABI admission.";
 }
}
