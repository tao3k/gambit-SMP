/* Causal research refinement of the existing blueprint, not a second layout.
 * Strings describe conditional arguments; validation does not prove C behavior. */
package GambitCausalArchitecture {
  private import ScalarValues::*;
  attribute sourceLock:String="evidence/research/modern-c-bootstrap/request-custody-source.lock.json";
  attribute gateLedger:String="docs/smp-twelve-gate-research-map.md";
  attribute controlReferences:String="Chez: vendor/chez/c/schsig.c and c/alloc.c; Bruggeman/Waddell/Dybvig PLDI 1996; Guile official prompt, continuation and VM instruction manuals; OCaml papers only for selected coordination mechanisms";
  attribute controlSelection:String="Gambit full multi-shot is the semantic baseline; study Chez mixed one-shot/multi-shot stack representation and Guile delimited composition and foreign barriers; do not import OCaml one-shot, Guile thread confinement or a foreign GC policy as Gambit semantics";
  attribute runtimeAdmitted:Boolean=false;
  attribute commitAdmitted:Boolean=false;
  part def Argument {
    ref part pressure:GambitRefactoring::RefactoringPressure;
    attribute id:String;
    attribute gates:String;
    attribute evidence:String;
    attribute evidenceClass:String;
    attribute badHistory:String;
    attribute rule:String;
    attribute proofRoute:String;
    attribute premise:String;
    attribute refutation:String;
    attribute present:String;
    attribute gain:String;
    attribute cost:String;
    attribute next:String;
  }
  part exitCase:Argument {
    ref part :>> pressure=GambitRefactoring::exitPressure;
    attribute :>> id="exit";
    attribute :>> gates="3;5;6;7;8;9;10";
    attribute :>> evidence="docs/smp-repair9-accepted-hard-failure.md; docs/shutdown-error-handoff.md";
    attribute :>> evidenceClass="source/lifecycle argument; no reconstruction of every crash";
    attribute :>> badHistory="Accepted callback or error survives its receiver; unknown join is used as either safe reuse or a VM-wide GC veto";
    attribute :>> rule="Outcome and native-user custody outlive execution admission; detach heap participation only with an immutable no-RUN empty-domain certificate; native reuse still requires known closure";
    attribute :>> proofRoute="copy_custody.isolate; Gambit.CopyCustody.isolationDoesNotRequireJoin; Gambit.CopyCustody.nativeReuseStillNeedsJoin";
    attribute :>> premise="Complete legal senders, callback tails and OS-result inventory; a recoverable failure has an independent progress agent";
    attribute :>> refutation="A published actor still writes the heap, or a retained handler has no disposition; empty-startup isolation does not cover either";
    attribute :>> present="Scoped unpublished-actor isolation implemented; complete result/mailbox and exit lifecycle replacement open";
    attribute :>> gain="Three healthy participants complete three GCs while one unpublished actor is retained; general progress gain is conditional";
    attribute :>> cost="Native handle and descriptor retention, admission/drain synchronization, bounded-capacity policy";
    attribute :>> next="Close all accepted outcomes and final native users before generalizing beyond empty unpublished actors";
  }
  part work:Argument {
    ref part :>> pressure=GambitRefactoring::workPressure;
    attribute :>> id="work";
    attribute :>> gates="6;7;9;10;12";
    attribute :>> evidence="vendor/gambit/include/gambit.h.in; vendor/gambit/lib/mem.c; dev/refactoring/modern-c/models/sysml/copy-custody.sysml";
    attribute :>> evidenceClass="current separated storage and conditional work-closure design";
    attribute :>> badHistory="A participant leaves while private frontier, Tail, weak-phase or release work can still create descendants";
    attribute :>> rule="ExecutionContext, GCParticipant and CollectorWorkContext have separate lifetimes; completion requires closed producers plus zero private, queued, running and descendant debt";
    attribute :>> proofRoute="copy_custody.takeChunk; copy_custody.drainChunk; dev/architecture/runtime/interfaces/models/sysml/publication-close.sysml";
    attribute :>> premise="Every producer and last use mapped; publication orders payload visibility before consumer authority; scheduler fairness is separate";
    attribute :>> refutation="finish reopens work after close, or an exiting worker has the only unrecorded cursor; an empty queue is insufficient";
    attribute :>> present="VM-owned role arrays and explicit chunk transport implemented; synchronous carriers remain; independent workers and full phase closure open";
    attribute :>> gain="Remove implicit PSTATE lifetime as collector-work lifetime; permit worker policy to change without changing Scheme execution identity";
    attribute :>> cost="Descriptors, counters, cache traffic and publication synchronization; no parallel speedup established";
    attribute :>> next="Prove producer closure and the root-cut/capacity handoff before enabling independently scheduled workers";
  }
  part copy:Argument {
    ref part :>> pressure=GambitRefactoring::copyPressure;
    attribute :>> id="copy";
    attribute :>> gates="4;6;7;10;11;12";
    attribute :>> evidence="dev/refactoring/modern-c/copy-custody-results.org; vendor/gambit/lib/mem.c";
    attribute :>> evidenceClass="native duplicate ordinary-scan request witnessed; universal producer/crash explanation open";
    attribute :>> badHistory="Two delivered traversal requests repair the same destination fields, while forwarding visibility is mistaken for completed payload and Tail ownership";
    attribute :>> rule="Transport delivery is distinct from object write authority; one canonical initializer, one ordinary scanner and separately owned Tail/frame-link work; reserve a real contiguous interval before forwarding";
    attribute :>> proofRoute="copy_custody.observeDuplicate; Gambit.CopyCustody.duplicateTaskDoesNotCreateWriter; round_capacity.publishPlan; Gambit.RoundCapacity.sectionPackingBound";
    attribute :>> premise="All pair/frame/weak adapters obey the same claim and publication protocol; closed source bound, maximum request and injective physical layout precede parity flip";
    attribute :>> refutation="Any bypass performs field repair without the claim; per-copy refunds are used as a whole-round capacity proof; raw-ready frame exposes an unfinished semantic link";
    attribute :>> present="Object authority, unified FIFO, frame domain and private copy grants implemented; full pre-flip planner unimplemented";
    attribute :>> gain="At most one ordinary field-repair execution per destination despite duplicate delivery; no claim that delivery count or total runtime drops by the same amount";
    attribute :>> cost="Packed scan metadata 1.5625 percent of section payload; resets, lookups/CAS and frame-gate serialization";
    attribute :>> next="Bind frozen root and source identity to actual whole-round interval grants and restoration reserve";
  }
  part ffi:Argument {
    ref part :>> pressure=GambitRefactoring::ffiPressure;
    attribute :>> id="ffi";
    attribute :>> gates="2;3;4;5;9;10;11";
    attribute :>> evidence="vendor/gambit/lib/c_intf.c; vendor/gambit/lib/setup.c; dev/refactoring/modern-c/resize-source-custody.org";
    attribute :>> evidenceClass="actual request transport replaced; full raw FFI writer coverage open";
    attribute :>> badHistory="Movable thunk lives only in a copied sync operation across another request's GC; nested entry allocates before incoming root registration";
    attribute :>> rule="Register VM-owned root before publishing stable origin/serial; consumers reload after GC; ACK only after consumption and transport drain; generated native activation plans protect pre-marker inputs";
    attribute :>> proofRoute="resize_sources.competingGCTest; resize_sources.unknownKeepsRootTest; Gambit.ResizeSources";
    attribute :>> premise="Every GC-capable conversion, nested callback, exceptional exit and raw borrower is covered or explicitly excluded; no stale C local is treated as a root";
    attribute :>> refutation="A new conversion allocates before the root plan or an exceptional ACK removes a still-readable source; fixed slot count does not bound retained graph bytes";
    attribute :>> present="Fixed request cells, stable sync tokens, GC reload and retained failure roots implemented; general generated RootHandle/FFI replacement open";
    attribute :>> gain="Eliminate movable payload from resize transport; one pending root per bounded origin is scanned even outside active membership";
    attribute :>> cost="1536 additional VM bytes against its immediate predecessor; at most 64 request-cell visits per GC; retained payload graph can exceed that fixed storage";
    attribute :>> next="Complete pre-marker root protection and all native borrower/exit adapters before retiring handwritten entry choreography";
  }
  part release:Argument {
    ref part :>> pressure=GambitRefactoring::releasePressure;
    attribute :>> id="release";
    attribute :>> gates="2;3;5;6;7;9;10;12";
    attribute :>> evidence="vendor/gambit/lib/mem.c; dev/architecture/runtime/gc/release-producer-admission-design.org";
    attribute :>> evidenceClass="source-effect inventory and target design; complete deferred-release service not implemented";
    attribute :>> badHistory="Collector waits for a foreign destructor's owner callback while that owner is parked waiting for collector completion";
    attribute :>> rule="Release effects and owner affinity are declared; eligible rooted work is accepted before GC resume and drained with descendant accounting after required owners can run";
    attribute :>> proofRoute="dev/architecture/runtime/gc/models/sysml/release-producer-admission.sysml; dev/architecture/runtime/gc/models/sysml/constructor-debt-closure.sysml";
    attribute :>> premise="All release producers, native payload dependencies, budgets and failure dispositions covered; ineligible callbacks keep a supported explicit route";
    attribute :>> refutation="Deferred task still borrows reclaimed PSTATE or requires a callback prohibited by its wait; moving work into a queue alone removes no cycle";
    attribute :>> present="Research contracts; complete runtime service and C refinement open";
    attribute :>> gain="Remove eligible external blocking effects from GC critical completion; total destructor work is preserved";
    attribute :>> cost="Queueing, rooted retained bytes, affinity dispatch, descendant counters and shutdown drain";
    attribute :>> next="Classify every actual release-function constructor and close payload custody before replacing inline cleanup";
  }
  part frames:Argument {
    ref part :>> pressure=GambitRefactoring::framesPressure;
    attribute :>> id="frames";
    attribute :>> gates="1;2;4;7;10;11;12";
    attribute :>> evidence="vendor/gambit/gsc/_t-c-1.scm; vendor/gambit/include/gambit.h.in; vendor/gambit/tests/frame-continuation-roots.scm";
    attribute :>> evidenceClass="generated frame contracts and native multi-shot witness; universal generated-consumer refinement open";
    attribute :>> badHistory="Scanner and continuation restore interpret the same frame/link slot under different coordinates or treat raw copy completion as legal resumption";
    attribute :>> rule="Scheme owns FrameSpec and PointId; generated descriptors serve stack-to-heap mapping, ordinary roots, structural links, tail dispatch and resumption; each multi-shot restore gets a fresh execution view";
    attribute :>> proofRoute="copy_custody.scanOrdinaryFrame; Gambit.CopyCustody.ordinaryRootsExcludeLink; Gambit.CopyCustody.frameGateExcludesSecondRole";
    attribute :>> premise="Every frame kind, dynamic rest/apply, floating materialization, serializer and native return consumer shares the schema; C activation origin remains valid";
    attribute :>> refutation="One-shot is substituted for multi-shot, or a restored dynamic-wind extent is reused as a current native resource permit";
    attribute :>> present="Frame decoding and ordinary/link access split implemented; complete semantic schema and all consumers not yet retired";
    attribute :>> gain="One frame meaning across control and GC; enables certified mature-continuation minor-scan skipping only with complete writer/barrier coverage";
    attribute :>> cost="Metadata, spill/reload, restore work, write barriers and remembered roots; current frame gate can serialize work";
    attribute :>> next="Use repeated map-continuation restoration as a cross-consumer oracle; study Chez and Guile for segment, prompt and composition contracts; close all frame kinds and native origins";
  }
  part profile:Argument {
    ref part :>> pressure=GambitRefactoring::profilePressure;
    attribute :>> id="profile";
    attribute :>> gates="1;2;3;4;5;6;7;11;12";
    attribute :>> evidence="evidence/fixtures/gerbil-bazel-build-profile/profile.json; dev/architecture/toolchain/models/sysml/architecture.sysml";
    attribute :>> evidenceClass="effective-profile and exact completed-bootstrap reuse observations";
    attribute :>> badHistory="Compiler or runtime ABI changes but a stale header/archive is reused; make parallelism is mistaken for same-VM SMP population";
    attribute :>> rule="Typed effective capability and ABI identity bind every generated/native artifact and runtime witness; one shared scheduling budget controls independent actions";
    attribute :>> proofRoute="dev/architecture/toolchain/models/sysml/architecture.sysml; dev/refactoring/modern-c/blueprint-matrix.org";
    attribute :>> premise="Full actual tool/options/input identity and complete product inventory; dynamic build dependencies either controlled or rejected";
    attribute :>> refutation="A real compiler/header/environment input is absent from the key, or hash validation costs exceed eligible avoided work";
    attribute :>> present="Existing Bazel profile used; exact 2505-entry product lease reused for two independent wide-root lanes; complete new build architecture open";
    attribute :>> gain="This verification reruns no bootstrap: only two fixture compilations and executions; no general cold-build speedup follows";
    attribute :>> cost="Identity validation, artifact inventory, dependency recording and budget arbitration";
    attribute :>> next="Qualify no-op, leaf and macro invalidation against clean builds under identical semantics and toolchain lineage";
  }
  part generation:Argument {
    ref part :>> pressure=GambitRefactoring::generationPressure;
    attribute :>> id="generation";
    attribute :>> gates="1;4;5;7;10;11;12";
    attribute :>> evidence="vendor/gambit/gsc/_t-c-1.scm; dev/architecture/runtime/models/sysml/composition.sysml";
    attribute :>> evidenceClass="source ownership and target semantic/native contract";
    attribute :>> badHistory="C macro emission and runtime layout independently reconstruct semantic decisions; unchanged output unnecessarily invalidates downstream native work";
    attribute :>> rule="Scheme produces completed FrameSpec/ModuleSpec/effect/allocation plans once; modern generated C mechanically realizes them; LLVM/MLIR consumes the same semantics through a separate backend boundary";
    attribute :>> proofRoute="dev/architecture/runtime/models/sysml/composition.sysml; dev/refactoring/models/sysml/adoption.sysml";
    attribute :>> premise="Generated declarations and runtime/link consumers migrate together; external semantic effects are part of dependency closure";
    attribute :>> refutation="A second policy remains in C or MLIR, or a Zig/LLVM wrapper is added while all old emitters and interpretation paths remain authoritative";
    attribute :>> present="Modern C is required; partial frame consumer migration implemented; complete plan producer, modular C ABI and alternate backend open";
    attribute :>> gain="Leverage Gambit semantic knowledge across native consumers; eligible identical output cuts off downstream work; backend choice no longer owns Scheme semantics";
    attribute :>> cost="Schema/generator verification, ABI invalidation, descriptors and backend-specific lowering; Zig has no automatic incremental benefit";
    attribute :>> next="Retire duplicated C semantic/layout decisions with matching generator/runtime/module consumers rather than add a second runtime";
  }
  part def Dependency { ref part dependent:Argument; ref part prerequisite:Argument; attribute why:String; }
  part rootsBeforeWorkers:Dependency { ref part :>> dependent=work; ref part :>> prerequisite=ffi; attribute :>> why="Worker independence needs a complete frozen root view and park/reload protocol"; }
  part framesBeforeCopy:Dependency { ref part :>> dependent=copy; ref part :>> prerequisite=frames; attribute :>> why="Unique object authority alone does not prove frame coordinates or structural link completion"; }
  part workBeforeExit:Dependency { ref part :>> dependent=exitCase; ref part :>> prerequisite=work; attribute :>> why="Participant withdrawal cannot discard private or descendant work"; }
  part releaseBeforeExit:Dependency { ref part :>> dependent=exitCase; ref part :>> prerequisite=release; attribute :>> why="Final callbacks and resources can outlive execution admission"; }
  part semanticsBeforeFrames:Dependency { ref part :>> dependent=frames; ref part :>> prerequisite=generation; attribute :>> why="Frame consumers share a Scheme-owned semantic source"; }
  part identityBeforeGeneration:Dependency { ref part :>> dependent=generation; ref part :>> prerequisite=profile; attribute :>> why="Native results qualify only the actual generated/header/object closure"; }
}
