/* Model-owned architecture declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpArchitecture {
 private import GambitSharedHeapSmp::*;

 part sharing:Component {
  attribute :>> id="sharing";
  attribute :>> label="Shared graph semantics / logical identity";
  attribute :>> authority="GambitSharedHeapSmp:sharing-contract";
  attribute :>> guarantee="Within an admitted sharing domain, object identity, aliases, shared mutable cells, closures and multi-shot continuation observations survive relocation; control restore does not roll back shared heap effects. A sharing domain is a semantic boundary, not one contiguous heap or an OS thread.";
  attribute :>> retirement="Retire physical address, request completion or actor membership as a proxy for shared identity/liveness only after every admitted store, root and per-shot observer preserves the same graph contract. Do not silently copy ordinary shared references across a new isolation boundary.";
  attribute :>> source="vendor/gambit/lib/_kernel.scm;vendor/gambit/lib/_thread.scm;dev/knowledge/systems/shared-heap-smp-literature.org";
  attribute :>> falsifier="Two restored wrappers observe different copies of a previously shared mutable cell, or a request frees an environment retained by a continuation/native borrower.";
  attribute :>> cost="Shared mutation still needs a defined memory model, writer admission and root/update coverage; privacy and isolation are not free consequences of placement.";
 }
 part allocationRegions:Component {
  attribute :>> id="allocationRegions";
  attribute :>> label="Allocation regions / placement and capacity";
  attribute :>> authority="GambitSharedHeapSmp:allocation-placement";
  attribute :>> guarantee="A region owns physical allocation/copy/restore intervals and capacity accounting; context-local allocation does not prove private reachability or authorize independent collection. Mutator nursery, collector destination and native pinned/permanent space are distinct roles.";
  attribute :>> retirement="Retire carrier identity or allocation address as heap/object owner only after source bounds, initialization publication, cross-region references and actual capacity transfer/free are explicit. Current WorkerArena cannot be relabeled as an implemented nursery.";
  attribute :>> source="vendor/gambit/lib/_mem/configuration.inc;vendor/gambit/lib/collector.h;vendor/gambit/lib/_mem/copy-planning.inc";
  attribute :>> falsifier="A supposedly private region is freed while another context/global/continuation/FFI still refers into it, or copy/restore intervals overlap after repartition.";
  attribute :>> cost="Region descriptors, refill/reserve slack, fragmentation, promotion and incoming-edge tracking; local bump allocation may save coordination but not tracing all by itself.";
 }
 part collectionDomains:Component {
  attribute :>> id="collectionDomains";
  attribute :>> label="Collection domains / authorized evacuation cut";
  attribute :>> authority="GambitSharedHeapSmp:collection-cut";
  attribute :>> guarantee="A collection domain identifies collected regions, epoch, admitted mutators/root sources, all incoming edges and native-access exclusions. Root count R, collector count W and domain membership are separate. Current VM-wide cut is a candidate boundary; finer domains require an actual cross-boundary protocol.";
  attribute :>> retirement="Retire one VM/processor/actor count as universal collection and reclaim permission only after every uncollected-to-collected edge is repaired, handled, pinned or excluded, and all scoped work/weak/restore/last-user debt closes. No independent per-region GC is admitted from local allocation alone.";
  attribute :>> source="vendor/gambit/lib/root.h;vendor/gambit/lib/_mem/root-tasks.inc;vendor/gambit/lib/_mem/collection-round.inc;dev/architecture/runtime/gc/modern-c-generational-design.org";
  attribute :>> falsifier="A collector moves an object while an unknown raw borrower in the same domain may access it; another VM's progress is asserted despite a shared mutable dependency or unreleased global service.";
  attribute :>> cost="Rendezvous, remembered edges, access barriers/handles/pinning and domain coordination; smaller cuts can reduce scanned work but increase publication and reclamation complexity.";
 }
 part execution:Component {
  attribute :>> id="execution";
  attribute :>> label="ExecutionContext / carrier";
  attribute :>> authority="GambitRuntimeComposition:execution";
  attribute :>> guarantee="ExecutionContext owns registers, denv, PointId and per-shot restore; VM owns membership and heap epoch; carriers hold revocable execution grants. Park requires a complete root view, and reentry acquires the completed epoch before reloading relocated values.";
  attribute :>> retirement="Retire PSTATE/carrier identity as execution/root/collector authority only after generated entry, direct/apply/native entry, park, restore and exceptional exit use the same context grant; keep actual platform TLS transport.";
  attribute :>> source="vendor/gambit/lib/_thread.scm;vendor/gambit/lib/_setup/vm-registry.inc";
  attribute :>> falsifier="A restored continuation remains multi-shot and keeps shared mutable cells; restoring control does not roll back the heap.";
  attribute :>> cost="Per-shot roots and reentry refresh; restoration can still copy frames.";
 }
 part roots:Component {
  attribute :>> id="roots";
  attribute :>> label="RootOrigin / RootTask";
  attribute :>> authority="GambitRuntimeAssurance:roots";
  attribute :>> guarantee="All admitted roots and native borrows publish one epoch-bound frozen view; scan authority outlives the carrier until every authoritative slot is updated.";
  attribute :>> retirement="Retire carrier-index root discovery only after bank/stack, captured frames/denv, RC, VM/global, symbol/keyword and strong still sources have writer/borrow closure, installation-before-parent-ACK, scan leases and source-side completion/reload; no lexical inventory grants retirement.";
  attribute :>> source="vendor/gambit/lib/_mem/root-tasks.inc;vendor/gambit/lib/_mem/rc-allocation.inc";
  attribute :>> falsifier="An unknown writer, incomplete frame, unregistered RC source or stale receipt vetoes the cut.";
  attribute :>> cost="Root descriptors, writer/borrow exclusion, source pins and retained unknown debt.";
 }
 part collector:Component {
  attribute :>> id="collector";
  attribute :>> label="CollectorWorker / WorkerArena";
  attribute :>> authority="GambitRuntimeAssurance:work";
  attribute :>> guarantee="One copy initializer owns claimed objects, private frontiers and Tail debt; R root domains and W workers are distinct; resume waits for real work closure.";
  attribute :>> retirement="Retire carrier-index arenas and fixed R=W scan assignment only after W<R roots, private/dequeued/chunk/Tail custody, copy-before-forwarding capacity and per-context restore intervals close; queued work count alone never grants resume or reclamation.";
  attribute :>> source="vendor/gambit/lib/_mem/copy-planning.inc;vendor/gambit/lib/_mem/copy-reservations.inc;vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> falsifier="No partial forwarding, uninitialized payload, unowned dequeued work or unreserved contiguous copy/restore interval may be admitted.";
  attribute :>> cost="Census, packing, CAS/refunds, private work custody and physical slack; useful parallelism also depends on serial root prefix, export delay, graph span and memory bandwidth, not just copied-byte balance or W count.";
 }
 part generations:Component {
  attribute :>> id="generations";
  attribute :>> label="Generational selection / barriers";
  attribute :>> authority="GambitGenerationalAdmission:candidate";
  attribute :>> guarantee="Consume the existing VM-wide young-cut candidate: roots, remembered source slots and young closure; mature skips require complete writers, residual edges and major/weak semantics.";
  attribute :>> retirement="Retire repeated mature interior scanning class by class only after all initialization/mutation/FFI/continuation writers, remembered residual edges, minor promotion capacity and major/weak/will processing close; still/permanent tags are not object ages.";
  attribute :>> source="dev/architecture/runtime/gc/models/sysml/generational-admission.sysml;dev/architecture/runtime/gc/models/sysml/generational-barrier.sysml";
  attribute :>> falsifier="Barrier overflow must retain coverage and cannot hide an allocating GC in an unrooted store; a major collector remains mandatory.";
  attribute :>> cost="Barrier/card/log work, rendezvous, promotion, extra major traffic and peak reserve; concurrent major remains a separate choice.";
 }
 part control:Component {
  attribute :>> id="control";
  attribute :>> label="CapturedControl / FrameSpec";
  attribute :>> authority="GambitContinuationSegments";
  attribute :>> guarantee="Scheme owns dynamic-wind and semantic control; one frame/root description serves capture, scan, deserialization and repeated restore with fresh physical authority.";
  attribute :>> retirement="Independent frame coordinates, cached moved addresses and one-shot consumption imposed to make scheduling easier.";
  attribute :>> source="vendor/gambit/lib/_kernel.scm;vendor/gambit/gsc/_t-c-3.scm;dev/architecture/runtime/control/models/sysml/continuation-segments.sysml";
  attribute :>> falsifier="Logical frame revision differs from physical GC relocation; every aliased authoritative slot must agree after relocation.";
  attribute :>> cost="Version/view checks, retained frames, Scheme hooks and necessary materialization remain.";
 }
 part messages:Component {
  attribute :>> id="messages";
  attribute :>> label="Scheduler / request / mailbox ownership";
  attribute :>> authority="GambitModernCOutcomes:execution";
  attribute :>> guarantee="Scheduler owns runnable/waiting membership, priority/FIFO publication and claim; service activation owns request execution, not the waiter continuation. One publish-claim-execute-result-or-abandon chain preserves policy; mailbox protocol does not mandate per-actor heaps.";
  attribute :>> retirement="Retire wakeup-as-completion and duplicate FIFO ownership only after every enqueue/dequeue, BTQ/TOQ key reorder, owner propagation and exception path shares one authorization transaction; do not replace scheduling policy or multi-shot control.";
  attribute :>> source="vendor/gambit/lib/_thread.scm;vendor/gambit/lib/os_thread.c";
  attribute :>> falsifier="Cross-VM messages need an explicit copy/move/immutable-share or external-handle policy; do not silently migrate shared mutable graphs or live native continuation resources.";
  attribute :>> cost="Queue synchronization, ordering, request roots and optional isolation transfer costs.";
 }
 part retirement:Component {
  attribute :>> id="retirement";
  attribute :>> label="VM / resource retirement";
  attribute :>> authority="GambitRuntimeAssurance:release";
  attribute :>> guarantee="Execution exit, GC participation, native return and resource-specific last use are separate; unknown join retains local custody without global healthy-VM veto.";
  attribute :>> retirement="Retire one join/count/global cleanup permit only after separate execution-write closure, root/borrow drain, native-return and resource last-use facts. A pre-RUN child already reads VM/lifecycle/gate, so data_closed alone cannot authorize their free; unknown join retains local pins without vetoing unrelated healthy-VM collection.";
  attribute :>> source="vendor/gambit/lib/_setup/vm-lifecycle.inc;vendor/gambit/lib/c_intf.c";
  attribute :>> falsifier="GC may not wait for an owner-affine destructor while owner reentry is forbidden. Deferred effects need retained custody and may finish after resume. Unknown join isolation never authorizes moving a VM heap with an unknown live writer.";
  attribute :>> cost="Retained unknown resources, deferred queues and shutdown drain obligations.";
 }
 part qualification:Component {
  attribute :>> id="qualification";
  attribute :>> label="Generated C / evidence boundary";
  attribute :>> authority="GambitModernCDeliveryPlan:qualification";
  attribute :>> guarantee="Scheme semantics plus generated contracts feed C23 consumers; source epoch, profile, workload and observer identity accompany every claim.";
  attribute :>> retirement="Patch-line progress, model success, module counts or artifact presence as current SMP acceptance.";
  attribute :>> source="dev/refactoring/modern-c/models/sysml/pending-cuts.sysml;dev/modeling/models/sysml/verification-responsibilities.sysml";
  attribute :>> falsifier="4/4 foundation, independent SMP checkpoint and repair-line status remain different axes; source changes invalidate impacted acceptance.";
  attribute :>> cost="Model/source correspondence, implementation PBT and matched native/resource/performance evidence.";
 }
 part sharingPlacement:Flow { ref part :>> producer=sharing; ref part :>> consumer=allocationRegions; attribute :>> contract="Placement can change while shared identity and alias observations remain stable"; }
 part regionCut:Flow { ref part :>> producer=allocationRegions; ref part :>> consumer=collectionDomains; attribute :>> contract="Physical region membership is not collection authority; account every incoming edge and capacity debt"; }
 part domainRoots:Flow { ref part :>> producer=collectionDomains; ref part :>> consumer=roots; attribute :>> contract="The domain declares all root/writer/native participants before a frozen epoch is issued"; }
 part workerPlacement:Flow { ref part :>> producer=collector; ref part :>> consumer=allocationRegions; attribute :>> contract="Destination and restore leases preserve object identity, unique initialization and disjoint physical intervals"; }
 part domainRetirement:Flow { ref part :>> producer=collectionDomains; ref part :>> consumer=retirement; attribute :>> contract="Scoped writers/queries/native access and all dependent work must close before region or service reclamation"; }
 part continuationSharing:Flow { ref part :>> producer=control; ref part :>> consumer=sharing; attribute :>> contract="Every restore shot preserves shared frame/denv aliases and actual effects; request end is not environment death"; }
 part schedulerExecution:Flow { ref part :>> producer=messages; ref part :>> consumer=execution; attribute :>> contract="Claim runnable computation, then acquire execution grant; queue membership is not a grant"; }
 part schedulerRoots:Flow { ref part :>> producer=messages; ref part :>> consumer=roots; attribute :>> contract="Queued requests and suspended computations retain authoritative roots until accepted transfer or abandonment"; }
 part retirementScheduler:Flow { ref part :>> producer=retirement; ref part :>> consumer=messages; attribute :>> contract="Close future callbacks and queue producers, settle admitted tasks, then drain last users; never wait on own GC dependency"; }
 part generationRoots:Flow { ref part :>> producer=generations; ref part :>> consumer=roots; attribute :>> contract="Minor scan exclusion requires complete root cut, remembered sources and governed continuation/FFI writers"; }
 part flow0:Flow { ref part :>> producer=execution; ref part :>> consumer=roots; attribute :>> contract="Generated safe PointId and complete updateable FrameSpec roots precede release publication; unparked raw native readers forbid relocation"; }
 part flow1:Flow { ref part :>> producer=roots; ref part :>> consumer=collector; attribute :>> contract="Acquire exact frozen VM/epoch/source generation; W workers claim the task union of R member-root domains without borrowing carrier identity; task/shard count is independent of R and W, and scan completion retains source lifetime"; }
 part flow2:Flow { ref part :>> producer=collector; ref part :>> consumer=control; attribute :>> contract="Repair canonical roots and close copy/frontier/Tail, weak work and physical restore reservation before publishing whole-round completion"; }
 part flow3:Flow { ref part :>> producer=control; ref part :>> consumer=execution; attribute :>> contract="Acquire completed epoch and reload per-shot slots before execution grant; preserve shared heap aliases, repeated restore, wind and required effects"; }
 part flow4:Flow { ref part :>> producer=generations; ref part :>> consumer=collector; attribute :>> contract="remembered cut and promotion reserve"; }
 part flow5:Flow { ref part :>> producer=messages; ref part :>> consumer=roots; attribute :>> contract="queued/request roots"; }
 part flow6:Flow { ref part :>> producer=retirement; ref part :>> consumer=roots; attribute :>> contract="retained unknown origins"; }
 part flow7:Flow { ref part :>> producer=collector; ref part :>> consumer=retirement; attribute :>> contract="Counted private/queued work closes before phase arrival; unknown stop retains arena and native/control last-user custody; scan DONE does not authorize physical retirement"; }
 part flow8:Flow { ref part :>> producer=qualification; ref part :>> consumer=execution; attribute :>> contract="source-bound admission"; }
 part flow9:Flow { ref part :>> producer=messages; ref part :>> consumer=execution; attribute :>> contract="service ownership, not wait state"; }
}
