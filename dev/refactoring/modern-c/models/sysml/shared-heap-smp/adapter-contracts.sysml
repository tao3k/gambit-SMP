/* Model-owned adapter-contracts declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpAdapters {
 private import GambitSharedHeapSmp::*;

 part freezeAdapter:AdapterContract {
  attribute :>> id="root-freeze";
  attribute :>> inputs="VM and collection epoch; closed member roster; complete six-kind authoritative root views; native slot handles and producer/copy/restore debts";
  attribute :>> precondition="All configured writers have declared access authority and complete frames; raw Scheme inputs have a parent/source root loan before native registration; known borrowers park data access while retaining reloadable source handles";
  attribute :>> authorization="RootOrigin owns lifetime; each RootTask owns one epoch-bound scan lease; worker owns copy/scan capability; no carrier ID alone grants any of them";
  attribute :>> linearization="Under source exclusion close semantic writes and binding access, then release-publish the frozen roster/view; acquire before claims and slot rewrite; restore completion precedes release re-admission";
  attribute :>> postcondition="Every authoritative slot points to the current live object; copy/scan/weak/required cleanup and physical restore debts are settled before writer reentry";
  attribute :>> recovery="Before any claim/forwarding a known refusal may retain the original view and return it; after publication unknown outcomes retain source pins and physical debt until queried/settled; never replay destructive work blindly";
  attribute :>> retirement="Task DONE drops only its scan lease; source domain/roster/PSTATE retirement waits for last reader/borrow and whole-round restored acknowledgment; owner-affine effects are separately retained";
  attribute :>> stateModel="Reuse shared_heap_cut: close/park/issue/pin/begin/finish/reopen/restore and rc_freeze_publication; no new transition model";
  attribute :>> dataModel="Reuse existing root coverage and copy/restore interval owners; RelocationSlots applies only after complete authoritative slots are admitted";
  attribute :>> acceptance="Whole source audit plus current test-rc-roots/test-root-task/frame/worker/lifecycle/PBT manifests; all required platforms, W<R and unknown join; no native pass inferred here";
  attribute :>> rejection="Incomplete frame, unmediated writer, active raw native reader, stale epoch, unresolved same-heap writer or unknown destructive completion refuses the moving cut";
  attribute :>> benefit="Removes carrier-dependent root eligibility and local-DONE/global-reclaim conflation; adds roster, leases, exclusion and scan/reload work";
  ref part :>> question=cutSource;
 }
 part aliasAdapter:AdapterContract {
  attribute :>> id="continuation-alias";
  attribute :>> inputs="Logical captured control with shared frames/denv; FrameSpec and return metadata; authoritative root-slot handles; per-shot target context and native activation lineage";
  attribute :>> precondition="The required root cut and structural layout are valid; distinguish semantic graph mutation from physical relocation; a wrapper copy is not a deep graph copy";
  attribute :>> authorization="Shared frame identity owns semantic revision; each shot obtains independent execution/root authority; collector writes use relocation authority while semantic writers are closed";
  attribute :>> linearization="Under frame/source access publish each complete semantic mutation with shared revision and required remembered coverage; after GC acquire rewritten slots before constructing the next shot";
  attribute :>> postcondition="All aliases observe the same Scheme cells and latest logical mutation; injective forwarding preserves distinct live identities; each restore sees current physical coordinates without consuming the continuation";
  attribute :>> recovery="Partial decode/copy retains rooted source and incomplete destination responsibility; an uncertain write prevents stale restore until source exclusion and completion are known; never retry user hooks as an idempotent copy";
  attribute :>> retirement="Captured graph remains rooted while reachable, independent of completed shots; source/revision metadata cannot retire before all aliases and in-flight restores leave";
  attribute :>> stateModel="Reuse continuation-segments and shared_heap_cut: repeatedRestoreTest/staleReloadControlTest; QNT owns ordering, not the alias algebra";
  attribute :>> dataModel="Reuse RelocationSlots: RewrittenOn and injective forwarding on admitted live targets; all authoritative slots and FrameSpec coordinates are source premises";
  attribute :>> acceptance="Trace producer, raw reflection, continuation-next!, serializer and collector consumers; native multi-shot map/shared mutation/serialization/GC and PBT; dynamic-wind before/after counts remain Scheme semantics";
  attribute :>> rejection="No one-shot substitution, heap rollback or collector-lock-only alias proof; invalid/unmapped structural slot or an unmediated semantic writer cannot enter optimized skip/restore paths";
  attribute :>> benefit="Unifies capture/scan/reflect/rebuild/restore coordinates and avoids redundant mature scans only after barrier coverage; revision checks, retained graphs and required materialization remain costs";
  ref part :>> question=aliasSource;
 }
 part domainAdapter:AdapterContract {
  attribute :>> id="domain-boundary";
  attribute :>> inputs="Message identity and initialized payload; source/target VM heap identity; per-shot captured control, denv, dynamic-wind context and native resource/activation dependencies";
  attribute :>> precondition="Same-VM payload sharing preserves reference identity; VM lifetime entry, queue ownership and control/resource admission are separate checks; cross-VM policy is explicit";
  attribute :>> authorization="Mailbox publisher owns the detached rooted cell until link commit; receiver claims once; execution admission owns the control shot; native resource authority remains with its declared affinity/lifetime owner";
  attribute :>> linearization="Initialize and root before queue permit; commit the link without GC under the permit; wake only advertises availability; claimed control obtains refreshed roots and target admission before winding hooks";
  attribute :>> postcondition="Same-VM aliasing and multi-shot behavior survive; each payload/shot/resource has one current owner of delivery debt; queue receipt does not authorize cross-heap pointer execution";
  attribute :>> recovery="Cancelled/unclaimed messages retain or return publisher custody; claimed/unknown delivery uses exact identity settlement; hook or callback exceptions preserve activation/root/resource debt and cannot imply physical stop";
  attribute :>> retirement="Deletion/exit closes new admissions, drains queued/in-flight claims and native borrows, then retires resources; isolated VM uncertainty must not become global GC authority";
  attribute :>> stateModel="Reuse existing request/FIFO/lifecycle/control owners and shared_heap_cut effect custody; no second Actor scheduler or cancellation model";
  attribute :>> dataModel="Reuse captured-slot alias/identity and existing registry/transfer data owners; raw C pointers and live continuation roots are not serialized message values";
  attribute :>> acceptance="Source-selected mailbox variants, VM entry, winding and foreign marker paths; native shared-payload FIFO, nested hook/exception, multi-shot and shutdown/unknown-join controls; cross-VM transfer remains separately gated";
  attribute :>> rejection="Undescribed cross-VM live closure/continuation/native handle transfer is not admitted; this does not reject ordinary same-VM shared Scheme values or force isolated heaps";
  attribute :>> benefit="Separates scheduling, message and resource failure domains while preserving Scheme sharing; transfer copies/encoding, monitoring, pins and last-use bookkeeping add work";
  ref part :>> question=boundarySource;
 }
 part freezeRoster:AdapterClause {
  attribute :>> id="freezeRoster";
  attribute :>> kind="coverage";
  attribute :>> rule="One sealed roster covers VM/bank/stack/RC/globals/symkey sources and every additional generated/native producer; R roots and W workers are independent roles";
  attribute :>> missing="Current roster and executor checks still use processor slots and synchronous entry; complete native/global writer and source lifetime coverage is unproved";
  attribute :>> acceptance="Review every roster/write/exit constructor and raw store; bind root-union and native manifests to configured source; missing source vetoes the cut";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rootEpoch;
 }
 part freezeAccess:AdapterClause {
  attribute :>> id="freezeAccess";
  attribute :>> kind="exclusion";
  attribute :>> rule="Lifetime borrow survives parking but raw data access is closed before relocation; root handle is reloaded only after acquire reentry";
  attribute :>> missing="Borrow returns &h->data and freeze does not itself require zero borrows; no demonstrated complete park/reload protocol for arbitrary native readers";
  attribute :>> acceptance="Audit borrow/read/return callers including setup and c_intf; adversarial GC while parked plus forbidden raw-reader source controls, without heap or wait changes";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rcBorrow;
 }
 part freezePublish:AdapterClause {
  attribute :>> id="freezePublish";
  attribute :>> kind="publication";
  attribute :>> rule="Final writes happen-before frozen publication; worker acquire sees the exact epoch/view; task and completion access use documented confinement or supported atomic/mutex ordering";
  attribute :>> missing="Native/legacy/sequential word variants and all-R collectives exist but no complete configured-platform closure is retained for this adapter";
  attribute :>> acceptance="Preprocess/compile supported existing profiles and review BARRIER/source mutex/claim ownership; plain concurrent stores or mismatched epochs falsify the refinement";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=orderedRootWords;
 }
 part freezeReentry:AdapterClause {
  attribute :>> id="freezeReentry";
  attribute :>> kind="reentry";
  attribute :>> rule="Root scan completion composes with copy/Tail/weak/physical restore and required cleanup before a new writer permit; owner-affine effects are delivered later";
  attribute :>> missing="finish_scan and root_round_end are explicit but complete producer/borrow/exception coverage and stopped-native admission remain open";
  attribute :>> acceptance="Whole caller chain plus current W<R/multi-shot/root/healthy-VM unknown-join consumers; local DONE or queue empty must not close the round";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rootEnd;
 }
 part freezeFailure:AdapterClause {
  attribute :>> id="freezeFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Known pre-copy refusal returns unchanged roots; uncertain post-publication work retains pins and debt, with no double release or circular GC/owner wait";
  attribute :>> missing="Source retains some planning uncertainty via contract error; no generally recoverable multi-stage unknown-outcome adapter is demonstrated";
  attribute :>> acceptance="Audit refuse/claim/scan/restore/unwind cuts; keep failed/unknown cases and verify original budgets with exact receipts rather than inferring thread death";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rootCollective;
 }
 part freezeValidation:AdapterClause {
  attribute :>> id="freezeValidation";
  attribute :>> kind="validation";
  attribute :>> rule="A source verdict covers the full contract and all related source bytes, not one successful mark_rc call";
  attribute :>> missing="Complete source-refinement attestation and affected native manifests are absent for this whole adapter";
  attribute :>> acceptance="Require all six clause attestations bound to full subject; native SH-EXEC-N and cost SH-COST-N stay independent even after source review";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rootScan;
 }
 part aliasWriters:AdapterClause {
  attribute :>> id="aliasWriters";
  attribute :>> kind="coverage";
  attribute :>> rule="Every semantic frame/denv/continuation/reflection/bulk/native writer has the same ownership, revision and future generational-store meaning";
  attribute :>> missing="continuation-set! writes heap and stack coordinates directly; frame-set!, macro setters and next! remain separate paths";
  attribute :>> acceptance="Enumerate generated macros/raw stores/rebuild callers; inspect structural link semantics including i==link and first-section cases, not just ordinary value slots";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=continuationWriter;
 }
 part aliasExclude:AdapterClause {
  attribute :>> id="aliasExclude";
  attribute :>> kind="exclusion";
  attribute :>> rule="Capture, mutation, relocation and each restore have explicit nonracing graph access; concurrent shots retain independent control and shared heap identity";
  attribute :>> missing="VM collector frame gate excludes collector structural repair but does not demonstrate semantic writer or alias-revision exclusion";
  attribute :>> acceptance="Source audit proves which semantic writers are stopped; native shared aliases across multiple restores and interleaved mutation must preserve Scheme observations";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=frameAccessDomain;
 }
 part aliasPublish:AdapterClause {
  attribute :>> id="aliasPublish";
  attribute :>> kind="publication";
  attribute :>> rule="Initialization and semantic updates publish only complete rooted frames; all aliases share logical revision; collector relocation does not increment a semantic revision";
  attribute :>> missing="Deserializer and continuation-next! have no demonstrated unified initialization/revision/remembered-source publication adapter";
  attribute :>> acceptance="Trace make-frame/check-heap/implode-frame/continuation rebuild and every old-to-young source; validate partial initialization/GC/exception custody";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=rebuildFrame;
 }
 part aliasReentry:AdapterClause {
  attribute :>> id="aliasReentry";
  attribute :>> kind="reentry";
  attribute :>> rule="One FrameSpec coordinates stack/heap/live/link slots; all admitted slots are rewritten under injective live forwarding before a fresh multi-shot restore";
  attribute :>> missing="Descriptor scanner exists but complete liveness/structural/foreign/serialization correspondence and physical-versus-logical refresh are unproved";
  attribute :>> acceptance="Review generator and every decoder/consumer against existing Lean premises; native map capture, two or more restores, shared mutation and dynamic-wind under GC";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=frameConsumer;
 }
 part aliasFailure:AdapterClause {
  attribute :>> id="aliasFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Failed copy/decode/restore retains the source graph and sole initializer; uncertain user hook effects cannot be retried as internal idempotent work";
  attribute :>> missing="Shallow wrapper copy shares graph; no uniform failure/unknown-write settlement has been shown for all reflection/rebuild/restore paths";
  attribute :>> acceptance="Trace all allocation/exception exits and result roots; PBT preserves a minimal shared-alias failure and distinguishes missing slot rewrite from legal shared mutation";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=copyAlias;
 }
 part aliasValidation:AdapterClause {
  attribute :>> id="aliasValidation";
  attribute :>> kind="validation";
  attribute :>> rule="Existing algebra proves equality only for complete admitted slot rewrites and injective live identities; source must establish both premises";
  attribute :>> missing="A well-formed frame size and local algebra proof do not close actual writer coverage or logical revision semantics";
  attribute :>> acceptance="Full-source clause review plus native multi-shot/serializer/frame-root inventory; do not duplicate the Lean law as a Quint data theorem";
  ref part :>> adapter=aliasAdapter;
  ref part :>> site=frameProducer;
 }
 part domainCoverage:AdapterClause {
  attribute :>> id="domainCoverage";
  attribute :>> kind="coverage";
  attribute :>> rule="Heap domain, logical Actor, carrier, execution context, resource affinity and VM lifetime entry remain distinct authorities";
  attribute :>> missing="VM registry entry exists; no demonstrated per-captured-control domain/resource descriptor or complete cross-VM transfer policy";
  attribute :>> acceptance="Trace thread creation/send/receive/control/native activation/exit callers; bind the configured conditional mailbox branch and name every supported transfer class";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=vmDomainEntry;
 }
 part domainExclude:AdapterClause {
  attribute :>> id="domainExclude";
  attribute :>> kind="exclusion";
  attribute :>> rule="Publisher owns a rooted detached payload before queue commit; receiver claims a delivery once; wake or queue presence alone grants no execution/resource authority";
  attribute :>> missing="Mailbox/FIFO code alone does not qualify all delete/cancel/exception and cross-domain ownership paths";
  attribute :>> acceptance="Review allocation before lock and claim/removal/last-use; native FIFO/shared-value identity and cancellation/exit controls with actual PBT shrink/replay";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=mailboxShare;
 }
 part domainPublish:AdapterClause {
  attribute :>> id="domainPublish";
  attribute :>> kind="publication";
  attribute :>> rule="Initialized payload publication has release/acquire ordering; no allocation or winding callback under queue permit; cross-VM representation is copied/encoded only by explicit policy";
  attribute :>> missing="Current same-VM reference passing is visible but does not establish portable cross-VM control/resource transfer";
  attribute :>> acceptance="Audit lock/claim ordering and root edges; cycle/sharing-preserving data transfer must have its own source/native evidence, not a raw object-pointer message";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=mailboxShare;
 }
 part domainReentry:AdapterClause {
  attribute :>> id="domainReentry";
  attribute :>> kind="reentry";
  attribute :>> rule="Each control shot reacquires target VM/context roots and activation lineage before Scheme-owned wind/unwind; no one-shot restriction or heap rollback";
  attribute :>> missing="Winding branches exist but complete capture/resource-domain validation and nested callback restoration are unproved";
  attribute :>> acceptance="Native repeated map restoration with shared cells, hooks and nested callbacks; verify required per-shot semantic effects exactly, not only return values";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=restoreWinding;
 }
 part domainFailure:AdapterClause {
  attribute :>> id="domainFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Queued/in-flight/returned/unknown activations retain separate custody; uncertain native writers in the same moving heap still veto its cut";
  attribute :>> missing="Marker TRY cleanup is source-visible; complete SFUN/CFUN/catcher/deletion/unknown native exit coverage and deferred affinity audit remain open";
  attribute :>> acceptance="Audit allocation-before-marker root protection and all exceptional exits; original healthy-VM unknown-join and GC/owner-cycle controls, with retained resource roots";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=nativeEntry;
 }
 part domainValidation:AdapterClause {
  attribute :>> id="domainValidation";
  attribute :>> kind="validation";
  attribute :>> rule="Source closure covers supported transfers and explicit exclusions; separate native whole-family and net-cost obligations remain open";
  attribute :>> missing="No complete domain/resource policy attestation or current whole-family acceptance is supplied here";
  attribute :>> acceptance="Require full-subject source clause attestations; cross-VM capability/serialization proofs remain existing-owner work and cannot be inferred from Actor terminology";
  ref part :>> adapter=domainAdapter;
  ref part :>> site=restoreWinding;
 }
}
