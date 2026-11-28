/* Modern C design-only extension. No native failure-recovery authority. */
package GambitStillCompletionLifetime {
 private import ScalarValues::*;
 part def RestoreState { attribute allowed : Boolean; attribute ready : Boolean; attribute gateHeld : Boolean; attribute resultProtected : Boolean; attribute bindingRestored : Boolean; attribute poisoned : Boolean; }
 requirement def RestoreLaw { subject r : RestoreState; require constraint { not r.allowed or (r.ready and not r.gateHeld and r.resultProtected and r.bindingRestored and not r.poisoned) } }
 part def ReuseState { attribute allowed : Boolean; attribute settled : Boolean; attribute producerClosed : Boolean; attribute floorPublished : Boolean; attribute rawPins : Integer; attribute replayRightsRetired : Boolean; }
 requirement def ReuseLaw { subject r : ReuseState; require constraint { not r.allowed or (r.settled and r.producerClosed and r.floorPublished and r.rawPins==0 and r.replayRightsRetired) } }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/still_completion_lifetime.qnt";
 attribute :>> subjectScope="still_completion_lifetime:29-named-histories;safe;seed=17;100x100";
 attribute :>> premise="One native call and a completed second receipt; separate raw effect/ready, partial gate writes, cooperative cancellation, qualified stop premise, prefix floor and record pins; no weak-memory/native crash recovery";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/StillCompletionLifetime.lean";
 attribute :>> subjectScope="GambitSMP.StillCompletionLifetime:settlePreserves;tracePreserves;consumedCannotCredit;rawGapCannotRestore;heldGateCannotRestore;poisonCannotRestore;unrootedCannotRestore;unpublishedAmbiguity;noObservationOnlyDecoder;pinBlocksReuse;prefixHoleBlocksReuse;producerMustClose;retiredLookupRejected;floorNeverRegresses;generationMismatchRejected;boundedWindowMetadata";
 attribute :>> premise="Conditional settlement Step/Trace conservation, no-observation decoder, restoration and reclamation guards, floor induction and bounded-window metadata; no C simulation";
 }
 part envelope : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-ENVELOPE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillCompletionLifetime.lean";
 attribute :>> subjectScope="NC-ENVELOPE:actual-source-refinement";
 attribute :>> premise="Publish qualified native participation and frozen context roots before acceptance; no-escape raw-enter through ready publication: cancellation/handler policy established before acceptance; no Scheme checkpoint, callback, logging, foreign unwind or local-only result ownership; OS preemption remains allowed";
 }
 part exitState : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-EXIT";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillCompletionLifetime.lean";
 attribute :>> subjectScope="NC-EXIT:actual-source-refinement";
 attribute :>> premise="Expected gate failures only before shared writes; finish cooperative writes and publish commit before unlock; unexpected nonlocal exit or owner death poisons gate/domain rather than blind cleanup unlock or refund";
 }
 part restore : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-RESTORE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillCompletionLifetime.lean";
 attribute :>> subjectScope="NC-RESTORE:actual-source-refinement";
 attribute :>> premise="Before restoring masks/cancellation or propagating Scheme errors: release gate, publish outcome, retain result/root in stable service and restore VM/processor binding; stopped owner recovery needs independent scan/stop evidence";
 }
 part reclaim : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="NC-RECLAIM";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/StillCompletionLifetime.lean";
 attribute :>> subjectScope="NC-RECLAIM:actual-source-refinement";
 attribute :>> premise="Record reuse requires settled outcome, producer closure, acknowledged replay-right retirement, published nonregressing floor and drained raw pins; ID-only stale handles rejected before lookup; no timeout or ACK-only free";
 }
 ref part issued=GambitStillReceiptAdmission::issuance;
 ref part settled=GambitStillReceiptAdmission::settlement;
 ref part admitted=GambitStillReceiptAdmission::gate;
 ref part released=GambitStillReceiptAdmission::sweep;
 ref part bindingState=GambitHostRootsRefinement::bindingState;
 ref part lifetime=GambitRetainedRcScan::lifetime;
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=envelope; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=envelope; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitState; ref part :>> prerequisite=history; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitState; ref part :>> prerequisite=induction; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=history; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=induction; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=history; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=induction; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=envelope; ref part :>> prerequisite=issued; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitState; ref part :>> prerequisite=settled; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitState; ref part :>> prerequisite=admitted; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=exitState; ref part :>> prerequisite=envelope; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=exitState; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=released; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=restore; ref part :>> prerequisite=bindingState; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=restore; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=lifetime; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaim; ref part :>> prerequisite=settled; }
 part envelopeRoute : GambitHostRootsRefinement::Route { ref part :>> need=envelope;
 attribute :>> sourceAnchors="os_base.c:156-180,190-415;mem.c:554-667,1556-1708;setup.c:51-92,317-339;_kernel.scm:1421-1427;os_thread.c:874-915;os_thread.h:94-106;os_setup.c:526-545;os_time.c:1055-1078;os_tty.c:8837-8867;os_io.c:8596-8618;os_io.c:9140-9146,9328-9345;os_shell.c:895-925,994-1003;os_time.c:987-997;os_tty.c:8700-8734;os_io.c:8503-8564;os_setup.c:3084-3133,3194-3200;gambit.h.in:9965-10006,10377-10378;setup.c:839-866,3354-3434;c_intf.c:6511-6562;setup.c:3410-3417;c_intf.c:1683-1711;mem.c:4387-4456;setup.c:903-978;os_thread.c:546-591;setup.c:6207-6211;os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> patchAnchors="Selected source paths only; no runtime patch or native test";
 attribute :>> projection="envelope: separate cooperative no-escape, publication, gate exits and capability retirement";
 attribute :>> failureCustodian="Canonical service retains intent, outcome/root and conservative upper bound; dead-held or inconsistent gate refuses handoff; unknown raw effect cannot be replayed";
 attribute :>> status="source-refinement-open";
 }
 part exitStateRoute : GambitHostRootsRefinement::Route { ref part :>> need=exitState;
 attribute :>> sourceAnchors="os_base.c:156-180,190-415;mem.c:554-667,1556-1708;setup.c:51-92,317-339;_kernel.scm:1421-1427;os_thread.c:874-915;os_thread.h:94-106;os_setup.c:526-545;os_time.c:1055-1078;os_tty.c:8837-8867;os_io.c:8596-8618;os_io.c:9140-9146,9328-9345;os_shell.c:895-925,994-1003;os_time.c:987-997;os_tty.c:8700-8734;os_io.c:8503-8564;os_setup.c:3084-3133,3194-3200;gambit.h.in:9965-10006,10377-10378;setup.c:839-866,3354-3434;c_intf.c:6511-6562;setup.c:3410-3417;c_intf.c:1683-1711;mem.c:4387-4456;setup.c:903-978;os_thread.c:546-591;setup.c:6207-6211;os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> patchAnchors="Selected source paths only; no runtime patch or native test";
 attribute :>> projection="exitState: separate cooperative no-escape, publication, gate exits and capability retirement";
 attribute :>> failureCustodian="Canonical service retains intent, outcome/root and conservative upper bound; dead-held or inconsistent gate refuses handoff; unknown raw effect cannot be replayed";
 attribute :>> status="source-refinement-open";
 }
 part restoreRoute : GambitHostRootsRefinement::Route { ref part :>> need=restore;
 attribute :>> sourceAnchors="os_base.c:156-180,190-415;mem.c:554-667,1556-1708;setup.c:51-92,317-339;_kernel.scm:1421-1427;os_thread.c:874-915;os_thread.h:94-106;os_setup.c:526-545;os_time.c:1055-1078;os_tty.c:8837-8867;os_io.c:8596-8618;os_io.c:9140-9146,9328-9345;os_shell.c:895-925,994-1003;os_time.c:987-997;os_tty.c:8700-8734;os_io.c:8503-8564;os_setup.c:3084-3133,3194-3200;gambit.h.in:9965-10006,10377-10378;setup.c:839-866,3354-3434;c_intf.c:6511-6562;setup.c:3410-3417;c_intf.c:1683-1711;mem.c:4387-4456;setup.c:903-978;os_thread.c:546-591;setup.c:6207-6211;os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> patchAnchors="Selected source paths only; no runtime patch or native test";
 attribute :>> projection="restore: separate cooperative no-escape, publication, gate exits and capability retirement";
 attribute :>> failureCustodian="Canonical service retains intent, outcome/root and conservative upper bound; dead-held or inconsistent gate refuses handoff; unknown raw effect cannot be replayed";
 attribute :>> status="source-refinement-open";
 }
 part reclaimRoute : GambitHostRootsRefinement::Route { ref part :>> need=reclaim;
 attribute :>> sourceAnchors="os_base.c:156-180,190-415;mem.c:554-667,1556-1708;setup.c:51-92,317-339;_kernel.scm:1421-1427;os_thread.c:874-915;os_thread.h:94-106;os_setup.c:526-545;os_time.c:1055-1078;os_tty.c:8837-8867;os_io.c:8596-8618;os_io.c:9140-9146,9328-9345;os_shell.c:895-925,994-1003;os_time.c:987-997;os_tty.c:8700-8734;os_io.c:8503-8564;os_setup.c:3084-3133,3194-3200;gambit.h.in:9965-10006,10377-10378;setup.c:839-866,3354-3434;c_intf.c:6511-6562;setup.c:3410-3417;c_intf.c:1683-1711;mem.c:4387-4456;setup.c:903-978;os_thread.c:546-591;setup.c:6207-6211;os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> patchAnchors="Selected source paths only; no runtime patch or native test";
 attribute :>> projection="reclaim: separate cooperative no-escape, publication, gate exits and capability retirement";
 attribute :>> failureCustodian="Canonical service retains intent, outcome/root and conservative upper bound; dead-held or inconsistent gate refuses handoff; unknown raw effect cannot be replayed";
 attribute :>> status="source-refinement-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="raw-and-debug";
 attribute :>> sourceAnchors="os_base.c:156-180,190-415;mem.c:554-667,1556-1708";
 attribute :>> actualChain="malloc/free or code mmap/munmap -> logging/header/aligned-container construction";
 attribute :>> hazard="Current outer wrappers cannot publish before earlier raw effects and debug vfprintf/fflush";
 attribute :>> replacement="Move logging out of raw-to-ready envelope; record raw backing before fallible view initialization";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="scheme-interrupts";
 attribute :>> sourceAnchors="setup.c:51-92,317-339;_kernel.scm:1421-1427";
 attribute :>> actualChain="raise interrupt -> flags/stack trip; disable retains synchronous operation interrupt";
 attribute :>> hazard="Scheme interrupt mask neither pthread cancellation control nor no-GC-region proof";
 attribute :>> replacement="Reuse deferred request mechanism; add explicit checkpoint/participation admission";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="signal-mask-primitive";
 attribute :>> sourceAnchors="os_thread.c:874-915;os_thread.h:94-106";
 attribute :>> actualChain="thread_sigmask -> pthread_sigmask or sigprocmask returns int";
 attribute :>> hazard="Calling convention/error channel differs; nested restoration needs exact saved state";
 attribute :>> replacement="Use status-bearing per-profile primitive; never fabricate a mask-success receipt";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="signal-mask-wrappers";
 attribute :>> sourceAnchors="os_setup.c:526-545;os_time.c:1055-1078;os_tty.c:8837-8867;os_io.c:8596-8618";
 attribute :>> actualChain="mask-all -> user,heartbeat,child; restore child,heartbeat,user";
 attribute :>> hazard="Void high-level APIs discard three enter and three restore return values";
 attribute :>> replacement="Preserve LIFO idea; typed partial-mask setup/restore results and retained saved masks required";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="mask-real-users";
 attribute :>> sourceAnchors="os_io.c:9140-9146,9328-9345;os_shell.c:895-925,994-1003";
 attribute :>> actualChain="device-process setup or system call inside mask-all pair";
 attribute :>> hazard="These real users do blocking/native resource work; normal lexical pairing is not exceptional cleanup";
 attribute :>> replacement="Keep own domains; no generic atomicity inferred from mask wrapper reuse";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="signals-and-errno";
 attribute :>> sourceAnchors="os_time.c:987-997;os_tty.c:8700-8734;os_io.c:8503-8564;os_setup.c:3084-3133,3194-3200";
 attribute :>> actualChain="heartbeat/TTY callback dispatch, SIGCONT device restore, SIGCHLD waitpid with errno save/restore, optional crash handler";
 attribute :>> hazard="Callback identity, errno preservation and installed configuration are not globally closed";
 attribute :>> replacement="Selective audited returning handlers or qualified masking; crash/foreign handler escapes refuse recovery";
 }
 part caller6 : CallerRow {
 attribute :>> callerId="unwind-real-entry";
 attribute :>> sourceAnchors="gambit.h.in:9965-10006,10377-10378;setup.c:839-866,3354-3434";
 attribute :>> actualChain="C TRY uses setjmp/catcher and THROW longjmp; call/run may rethrow; C cleanup is ordinary code";
 attribute :>> hazard="C cleanup has no automatic destructor guarantee; foreign catch cannot repair partially written metadata";
 attribute :>> replacement="Expected errors returned outside gate; no Scheme/foreign call or THROW while mutable transaction active";
 }
 part caller7 : CallerRow {
 attribute :>> callerId="callback-roots";
 attribute :>> sourceAnchors="c_intf.c:6511-6562;setup.c:3410-3417";
 attribute :>> actualChain="make marker may allocate; callback call; normal path invalidates marker";
 attribute :>> hazard="Explicit pre-allocation root TODO; marker kill is not receipt ACK or alias drain";
 attribute :>> replacement="Protect values before marker allocation; service roots and binding independent of dead C frame";
 }
 part caller8 : CallerRow {
 attribute :>> callerId="foreign-sweep";
 attribute :>> sourceAnchors="c_intf.c:1683-1711;mem.c:4387-4456";
 attribute :>> actualChain="release clears hook/pointer -> arbitrary native destructor; sweep frees afterward";
 attribute :>> hazard="Cleared fields do not prove completion; hook may reenter, escape or block";
 attribute :>> replacement="Separate destructor acceptance/completion from backing release; never run hook under gate";
 }
 part caller9 : CallerRow {
 attribute :>> callerId="processor-retirement";
 attribute :>> sourceAnchors="setup.c:903-978;os_thread.c:546-591;setup.c:6207-6211";
 attribute :>> actualChain="cleanup_pstate -> pthread_exit; processor0 join ignores error; exported exit/join";
 attribute :>> hazard="Join or stop alone gives no raw outcome; exported host calls bypass local census";
 attribute :>> replacement="Stop credential binds thread generation, phase, roots and gate; raw/poisoned state refuses handoff";
 }
 part caller10 : CallerRow {
 attribute :>> callerId="darwin-native-buffer";
 attribute :>> sourceAnchors="os_files.c:1672-1712,1788-1803;_kernel.scm:4221-4224;_nonstd.scm:2684,3040,3055";
 attribute :>> actualChain="Executable-path native buffer malloc -> Scheme conversion -> free";
 attribute :>> hazard="Direct backend bypass plus Scheme allocation while native buffer live";
 attribute :>> replacement="Separate buffer domain; retain native buffer custody across conversion and error paths";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="No-escape envelope";
 attribute :>> removedWork="Defers cooperative cancellation without losing a known completion";
 attribute :>> bound="For E outer calls, POSIX cancellation-state variant adds at most2E state calls on successful enter/restore; nested guards add local depth bookkeeping";
 attribute :>> addedCost="Six mask primitive attempts per outer call if existing three-mask family is adapted; failures add settlement work";
 attribute :>> condition="Conditional profile counts, no timing; no blanket POSIX/Darwin qualification";
 }
 part cost1 : CostRow {
 attribute :>> capability="Reuse existing masking";
 attribute :>> removedWork="Reuse saved-mask storage and reverse restore ordering";
 attribute :>> bound="Candidate family:3+3 primitive calls; qualified union-mask profile:1+1, four fewer per outer envelope";
 attribute :>> addedCost="Must add status propagation, partial setup bookkeeping and producer generation";
 attribute :>> condition="Union profile requires equivalent final masks and admissible pending-handler timing; current raw allocation has no such guard baseline; old helpers retire only after caller migration";
 }
 part cost2 : CostRow {
 attribute :>> capability="Gate exceptional exit";
 attribute :>> removedWork="Expected failures leave metadata unchanged before write; known completed transactions replay without repeated effects";
 attribute :>> bound="Zero rollback required for pre-write rejection; partial unexpected exits admit zero handoffs";
 attribute :>> addedCost="No-escape call-graph discipline; domain poisoning can retain capacity indefinitely";
 attribute :>> condition="Robust mutex or cleanup unlock alone does not establish consistency";
 }
 part cost3 : CostRow {
 attribute :>> capability="Published-result recovery";
 attribute :>> removedWork="Known ready results can survive caller delivery loss or qualified stopped owner";
 attribute :>> bound="Zero new native invocation for a completion query";
 attribute :>> addedCost="Stable outcome/result root, VM binding and raw-reader lifetime bookkeeping";
 attribute :>> condition="Raw gap, unknown destructor effects or dead-held gate remain rejected";
 }
 part cost4 : CostRow {
 attribute :>> capability="Bounded record reuse";
 attribute :>> removedWork="Recycle preallocated slots after floor publication and reader drain";
 attribute :>> bound="At most J*W retained operation slots under enforced per-issuer window W";
 attribute :>> addedCost="J issuer-generation/floor entries plus pin metadata and minimum pool reserve";
 attribute :>> condition="Prefix holes may stall one issuer; reject new work before pool exhaustion, no timeout-based eviction";
 }
 part cost5 : CostRow {
 attribute :>> capability="Peak metadata";
 attribute :>> removedWork="Windowed pool bounds growth if admission and generation retirement are proved";
 attribute :>> bound="Mop <= J*W*Rop + J*Rfloor + L*Rpin plus other prior block/domain/view metadata";
 attribute :>> addedCost="Fixed pool pages remain physically reserved after logical slot reuse";
 attribute :>> condition="No whole-round peak reduction or RSS refund proved";
 }
 part cost6 : CostRow {
 attribute :>> capability="Payload and GC";
 attribute :>> removedWork="No new payload copy required by receipt lifetime protocol";
 attribute :>> bound="Zero existing whole-chain scan passes proved removable";
 attribute :>> addedCost="Unknown allocations/releases and poisoned transactions keep conservative obligations";
 attribute :>> condition="No promise that arbitrary native corruption permits GC progress";
 }
 part cost7 : CostRow {
 attribute :>> capability="Modern C and Zig";
 attribute :>> removedWork="Modern C owns explicit guard, gate, stable roots and lifetime contracts";
 attribute :>> bound="No incremental Zig runtime-work reduction established";
 attribute :>> addedCost="Both require native-policy audits, floors, pins, identity and failure proofs";
 attribute :>> condition="Changing language alone cannot create raw-effect atomicity or reclaim authority";
 }
 part def DiagramNode { attribute nodeId : String; attribute labelText : String; }
 part def DiagramEdge { ref producer : DiagramNode; ref consumer : DiagramNode; attribute labelText : String; }
 part node0 : DiagramNode { attribute :>> nodeId="policy"; attribute :>> labelText="Qualified policy + preallocated intent"; }
 part node1 : DiagramNode { attribute :>> nodeId="raw"; attribute :>> labelText="Native call -> ready publication\\nno escape; preemption allowed"; }
 part node2 : DiagramNode { attribute :>> nodeId="unknown"; attribute :>> labelText="Raw gap / dead-held gate\\nretain custody; refuse handoff"; }
 part node3 : DiagramNode { attribute :>> nodeId="txn"; attribute :>> labelText="Gate transaction\\nvalidate -> write -> commit -> unlock"; }
 part node4 : DiagramNode { attribute :>> nodeId="restore"; attribute :>> labelText="Stable result roots + VM binding\\nrestore masks/cancel outside gate"; }
 part node5 : DiagramNode { attribute :>> nodeId="replay"; attribute :>> labelText="Known outcome / replay receipt"; }
 part node6 : DiagramNode { attribute :>> nodeId="floor"; attribute :>> labelText="ACK + producer closure\\nadvance nonregressing replay floor"; }
 part node7 : DiagramNode { attribute :>> nodeId="pins"; attribute :>> labelText="Drain raw record pins\\nreject old keys before lookup"; }
 part node8 : DiagramNode { attribute :>> nodeId="reuse"; attribute :>> labelText="Reuse record slot\\npool backing remains reserved"; }
 part node9 : DiagramNode { attribute :>> nodeId="formal"; attribute :>> labelText="SysML -> ASCENT\\nQNT / Lean; source gaps open"; }
 part edge0 : DiagramEdge { ref :>> producer=node0; ref :>> consumer=node1; attribute :>> labelText="accept only after policy success"; }
 part edge1 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node2; attribute :>> labelText="outcome unpublished on stop"; }
 part edge2 : DiagramEdge { ref :>> producer=node1; ref :>> consumer=node3; attribute :>> labelText="ready release / acquire"; }
 part edge3 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node2; attribute :>> labelText="unexpected exit during gate"; }
 part edge4 : DiagramEdge { ref :>> producer=node3; ref :>> consumer=node4; attribute :>> labelText="commit then unlock"; }
 part edge5 : DiagramEdge { ref :>> producer=node4; ref :>> consumer=node5; attribute :>> labelText="may deliver pending cancellation"; }
 part edge6 : DiagramEdge { ref :>> producer=node5; ref :>> consumer=node6; attribute :>> labelText="explicit result-right retirement"; }
 part edge7 : DiagramEdge { ref :>> producer=node6; ref :>> consumer=node7; attribute :>> labelText="close new old-key lookups"; }
 part edge8 : DiagramEdge { ref :>> producer=node7; ref :>> consumer=node8; attribute :>> labelText="existing readers + producers drained"; }
 part edge9 : DiagramEdge { ref :>> producer=node9; ref :>> consumer=node3; attribute :>> labelText="conditional refinement"; }
 part edge10 : DiagramEdge { ref :>> producer=node2; ref :>> consumer=node6; attribute :>> labelText="DENY guessed settlement / ACK"; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=envelope; ref part :>> prerequisite=bindingState; }
 part cost8 : CostRow {
 attribute :>> capability="GC participation at native entry";
 attribute :>> removedWork="Permit independent root service only after frozen-context publication";
 attribute :>> bound="Additional root descriptor/pin state scales with live roots R; raw native-call latency has no bound";
 attribute :>> addedCost="Before-call safe-point capture, native-participation transition and after-call rejoin";
 attribute :>> condition="Current synchronous GC may wait for return; independent progress needs root/native allocator proofs, not an interrupt mask";
 }
}
