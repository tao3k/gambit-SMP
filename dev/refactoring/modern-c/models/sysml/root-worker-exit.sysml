/* A complete source replacement cut. Clauses are refinement criteria, not new
 * QNT/Lean models or proofs. Upstream facts never discharge Gambit premises. */
package GambitRootWorkerExit {
  private import ScalarValues::*;
  part def ProtocolBinding {
    ref part component:Realization;
    attribute id:String; attribute model:String; attribute result:String;
    attribute actions:String; attribute cMap:String; attribute qntDuty:String;
    attribute leanDuty:String; attribute premise:String; attribute status:String;
    attribute main:String; attribute initializer:String; attribute step:String;
    attribute invariant:String; attribute negativeStep:String;
  }
  part capacityProtocol:ProtocolBinding {
    ref part :>> component=sourceRequest;
    attribute :>> id="capacity-publication";
    attribute :>> model="dev/refactoring/modern-c/models/quint/round_capacity.qnt";
    attribute :>> result="evidence/research/capacity-admission/protocol-closure/receipt.json";
    attribute :>> actions="freeze; discover; closeCensus; reserveAt; acknowledge; publishPlan; flip; refuse; observe; returnRefused; unknownResult; retain";
    attribute :>> cMap="freeze -> collection-round.inc participant ROOTS_FROZEN and barrier. Actual census/packing/common-refusal adapters remain absent; current setup_stack_heap_vmstate still flips before a complete plan. Existing return overflow is not returnRefused refinement";
    attribute :>> qntDuty="Finite interleavings: deduplicate discovery, no publication before complete census and acknowledgements, one decision observed by all three participants before flip or refused return, no refused/unknown flip, no early return";
    attribute :>> leanDuty="Existing ProducerCapacity, RoundCapacity and CopyCapacityComposition prove parametric source envelopes, interval coverage and conservation under explicit premises; they do not repeat participant schedules";
    attribute :>> premise="One shared-memory VM round, three objects and three participants, two finite regions. No cross-machine protocol, unbounded-member theorem or liveness claim. Finite placement guards abstract valid C intervals. Source inventory completeness, packing arithmetic, physical exclusion, every real participant and failure custody need a separate C/data adapter";
    attribute :>> status="finite-model-check-required-C-adapter-open";
    attribute :>> main="round_capacity"; attribute :>> initializer="init";
    attribute :>> step="step"; attribute :>> invariant="safe";
    attribute :>> negativeStep="badFlipPending";
  }
  part sfunProtocol:ProtocolBinding {
    ref part :>> component=rootAdmission;
    attribute :>> id="sfun-writer-publication";
    attribute :>> model="models/gambit/host_roots_contract.qnt";
    attribute :>> result="evidence/research/capacity-admission/protocol-closure/receipt.json";
    attribute :>> actions="protect; acquireWriter; convert; releaseWriter; closeWriters; freeze; acquire; relocate; reload; allocateMarker; storeArgument; enter; leave; release";
    attribute :>> cMap="protect -> begin_sfun and alloc_rc_roots; acquireWriter/storeArgument/releaseWriter -> context gate in store_rc_root and call_sfun batch; closeWriters -> close_rc_roots invocation; freeze -> ROOTS_FROZEN barrier; acquire/relocate -> mark_rc plus mark_array; reload -> bank input flag and post-marker batch reload; release -> end_sfun known exit";
    attribute :>> qntDuty="Finite interleavings of root registration before collecting conversion, writer drain before frozen scan, pre-marker GC and reload, nested activation, closed-entry refusal and known-exit release. closing is a close request, not proof that an already admitted writer stopped";
    attribute :>> leanDuty="Existing HostRootsRefinement owns stable-cell to root-view mapping and relocation premises. New root_count span coverage needs source refinement; no duplicate writer state machine or fresh Lean completion claimed";
    attribute :>> premise="One shared-memory root domain, callback depth at most two, two conversion/store observations. No liveness or cross-machine claim. C gate sections are noncollecting stores. A conversion may collect only with inputs in registered stable cells; the model does not hold a writer permit throughout an allocating converter. Correct span initialization, PSTATE/context identity, no raw aliases and native stop remain C premises";
    attribute :>> status="finite-model-check-required-C-adapter-open";
    attribute :>> main="host_roots_contract"; attribute :>> initializer="init";
    attribute :>> step="step"; attribute :>> invariant="safe";
    attribute :>> negativeStep="badMarker";
  }
  part def ProtocolStep {
    ref part protocol:ProtocolBinding;
    attribute id:String; attribute actions:String; attribute source:String;
    attribute anchor:String; attribute boundary:String; attribute progress:String;
  }
  part hashProtocol:ProtocolBinding {
    ref part :>> component=hashLayout;
    attribute :>> id="hash-layout-ownership";
    attribute :>> model="dev/refactoring/modern-c/models/quint/hash_index_owner.qnt";
    attribute :>> result="evidence/research/hash-layout/protocol-closure/receipt.json";
    attribute :>> actions="beginRead; visit; finishRead; freeze; relocate; repairStable; resume; lookup; ownedRebuild; deserialize";
    attribute :>> cMap="Scheme owns physical traversal cursor; collector repairs references and records actual movement without permutation; native pure read preserves slots and address debt; exclusive mutator rebuilds before set/delete/union-find. Scheme explicit deserialize debt remains independent";
    attribute :>> qntDuty="Existing hash_index_owner extended with cursor, layout and address debt: GC/lookup interleavings preserve exact visits; old eager rebuild can duplicate a key despite correct hash placement. One reader, two keys, two addresses/layouts; no concurrent writer or liveness claim";
    attribute :>> leanDuty="Reuse existing HashIndexOwner conditional algorithm/transport and debt laws. It does not prove the new cursor schedule or C linear-search encoding; no Lean scheduler or second proof is introduced";
    attribute :>> premise="Rooted table/key/value state, source scan uniqueness, current repaired pointers, completed collective GC before mutator resume and existing public traversal mutation restrictions. Raw aliases, same-table concurrent/reentrant writers, weak dead-entry snapshot guarantees and unknown-stop recovery are excluded";
    attribute :>> status="finite-model-check-required-C-adapter-open";
    attribute :>> main="hash_index_owner"; attribute :>> initializer="init";
    attribute :>> step="step"; attribute :>> invariant="safe";
    attribute :>> negativeStep="legacyStep";
  }
  part hashCursor:ProtocolStep {
    ref part :>> protocol=hashProtocol; attribute :>> id="hash-cursor";
    attribute :>> actions="beginRead; visit; finishRead";
    attribute :>> source="vendor/gambit/lib/_system.scm";
    attribute :>> anchor="(define-prim (##gc-hash-table-for-each proc gcht)";
    attribute :>> boundary="Existing Scheme cursor advances by two physical fields after visitor return. Its rooted frame may survive GC; explicit same-table public operations remain restricted by the manual";
    attribute :>> progress="located-not-C-proof";
  }
  part hashMove:ProtocolStep {
    ref part :>> protocol=hashProtocol; attribute :>> id="hash-key-movement";
    attribute :>> actions="relocate; repairStable";
    attribute :>> source="vendor/gambit/lib/_mem/object-scanning.inc";
    attribute :>> anchor="if (body[i] != key)";
    attribute :>> boundary="Compare strong key before/after mark_array, record actual address change; permanent symbols cause no speculative debt. Weak-key repair keeps its existing movement/deletion flags";
    attribute :>> progress="located-not-C-proof";
  }
  part hashRepair:ProtocolStep {
    ref part :>> protocol=hashProtocol; attribute :>> id="hash-reference-repair";
    attribute :>> actions="freeze; resume";
    attribute :>> source="vendor/gambit/lib/_mem/weak-tables.inc";
    attribute :>> anchor="GC owns reference repair and weak deletion, never slot permutation.";
    attribute :>> boundary="Repair/remove entries at existing coordinates. Collective round closes mutators before this work and resumes only after its completion; this location alone is not the whole barrier/memory-order refinement";
    attribute :>> progress="located-not-C-proof";
  }
  part hashAccess:ProtocolStep {
    ref part :>> protocol=hashProtocol; attribute :>> id="hash-access";
    attribute :>> actions="lookup; ownedRebuild";
    attribute :>> source="vendor/gambit/lib/_mem/hash-table-api.inc";
    attribute :>> anchor="A read cannot acquire layout-write authority.";
    attribute :>> boundary="KEY_MOVED selects a nonallocating read-only scan. Native set and path-compressing union/find own reconstruction. No runtime reader lock or concurrent mutation permission is supplied";
    attribute :>> progress="located-not-C-proof";
  }
  part hashDeserialize:ProtocolStep {
    ref part :>> protocol=hashProtocol; attribute :>> id="hash-deserialize";
    attribute :>> actions="deserialize";
    attribute :>> source="vendor/gambit/lib/_system.scm";
    attribute :>> anchor="(define-prim (##table-access";
    attribute :>> boundary="Scheme table-access owns explicit NEED_REHASH reconstruction; raw native KEY_MOVED fallback does not discharge deserialization debt or authorize the wrong index algorithm";
    attribute :>> progress="located-not-C-proof";
  }
  part capacityFreeze:ProtocolStep {
    ref part :>> protocol=capacityProtocol; attribute :>> id="capacity-freeze";
    attribute :>> actions="freeze"; attribute :>> source="vendor/gambit/lib/_mem/collection-round.inc";
    attribute :>> anchor="participant->phase = ___GC_ROOTS_FROZEN;";
    attribute :>> boundary="Every R carrier closes RC roots and publishes its frozen view before the existing physical barrier";
    attribute :>> progress="located-not-C-proof";
  }
  part capacityPlan:ProtocolStep {
    ref part :>> protocol=capacityProtocol; attribute :>> id="capacity-plan";
    attribute :>> actions="discover; closeCensus; reserveAt; acknowledge; publishPlan; refuse; observe; returnRefused; unknownResult; retain";
    attribute :>> source="vendor/gambit/lib/_mem/heap-sections.inc";
    attribute :>> anchor="___HIDDEN void setup_stack_heap_vmstate";
    attribute :>> boundary="Legacy setup boundary exists; full census/packing/common-refusal adapter does not. No observed source counter is substituted for those actions";
    attribute :>> progress="missing-adapter";
  }
  part capacityFlip:ProtocolStep {
    ref part :>> protocol=capacityProtocol; attribute :>> id="capacity-flip";
    attribute :>> actions="flip"; attribute :>> source="vendor/gambit/lib/_mem/heap-sections.inc";
    attribute :>> anchor="tospace_offset = ___vms->gc_round.destination_offset;";
    attribute :>> boundary="Real parity change is located. It still lacks the model's complete pre-flip plan and all-participant observation guard; locating it does not establish refinement";
    attribute :>> progress="missing-adapter";
  }
  part sfunProtect:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-protect";
    attribute :>> actions="protect"; attribute :>> source="vendor/gambit/lib/_mem/rc-allocation.inc";
    attribute :>> anchor="h->root_count = count;";
    attribute :>> boundary="Initialize every SCMOBJ cell and flag before count publication under context gate; raw inputs register before any collecting converter";
    attribute :>> progress="located-not-C-proof";
  }
  part sfunConversion:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-conversion";
    attribute :>> actions="convert; allocateMarker"; attribute :>> source="vendor/gambit/include/_gambit/foreign_conversion.h.in";
    attribute :>> anchor="___EXT(___check_sfun)(___ps,___sfun_roots)";
    attribute :>> boundary="Generator orders SCMOBJ declarations first; argument/result converters check root-domain admission. Marker allocation is deferred to call/error boundary and can relocate bank cells";
    attribute :>> progress="located-not-C-proof";
  }
  part sfunBatch:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-batch";
    attribute :>> actions="acquireWriter; storeArgument; releaseWriter; reload; enter";
    attribute :>> source="vendor/gambit/lib/c_intf.c";
    attribute :>> anchor="___PSSTK(___FRAME_SPACE(2)+i) = ___CAST(___SCMOBJ*,bank)[i-1];";
    attribute :>> boundary="After marker allocation reload the current stable cells; physical stack bounds and gate precede the entire noncollecting batch. Unlock before Scheme call; never hold a writer lock over GC";
    attribute :>> progress="located-not-C-proof";
  }
  part sfunClose:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-close";
    attribute :>> actions="closeWriters; freeze"; attribute :>> source="vendor/gambit/lib/_mem/collection-round.inc";
    attribute :>> anchor="close_rc_roots (___ps);";
    attribute :>> boundary="Close invocation can contend with an admitted store; close return and frozen publication follow that store, not a claimed logical cancellation";
    attribute :>> progress="located-not-C-proof";
  }
  part sfunScan:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-scan";
    attribute :>> actions="acquire; relocate"; attribute :>> source="vendor/gambit/lib/_mem/rc-roots.inc";
    attribute :>> anchor="mark_array (work, ___CAST(___SCMOBJ*,h+1), h->root_count);";
    attribute :>> boundary="Same closed-domain gate covers membership and payload scan; worker updates data and root_count cells, independent of origin processor id";
    attribute :>> progress="located-not-C-proof";
  }
  part sfunExit:ProtocolStep {
    ref part :>> protocol=sfunProtocol; attribute :>> id="sfun-exit";
    attribute :>> actions="leave; release"; attribute :>> source="vendor/gambit/lib/c_intf.c";
    attribute :>> anchor="if (bank) { ___return_rc_root(bank); ___release_rc(bank); }";
    attribute :>> boundary="Known wrapper exit invalidates marker and pays bank borrow/reference after converter cleanup. A raw nonlocal exit skips this step and retains debt; no physical-stop proof follows";
    attribute :>> progress="located-not-C-proof";
  }
  ref part writerLastUse=GambitWriteAuthority::lastUse;
  part def BuildBoundary {
    attribute id:String; attribute source:String; attribute guard:String;
    attribute reusable:String; attribute failure:String; attribute benefit:String;
  }
  part configureProbes:BuildBoundary {
    attribute :>> id="configure-probes";
    attribute :>> source="configure.ac::three AC_CACHE_SAVE boundaries; native_capabilities.py::configure_owned_source";
    attribute :>> guard="Exact task request binds configure policy, profile, tools, environment and template hashes. Select standard Autoconf cache by that request; preserve the existing 90-second configure and 600-second whole-run caps";
    attribute :>> reusable="Only completed ac_cv observations persist at standard cache-save boundaries. A resumed configure still validates its own environment and must complete normally; partial cached probes are not configured output or runtime admission";
    attribute :>> failure="Interrupted configure retains the owned source, existing completed producer and cached observations. No successful configure proof is issued, no runtime is published and no old API/source copy is recreated";
    attribute :>> benefit="Avoid repeating completed compiler/OS/option probes after interruption. Cold probing and unsupported/uncached tests still cost work; cache keys do not qualify an externally changed SDK";
  }
  part configureTemplates:BuildBoundary {
    attribute :>> id="configuration-templates";
    attribute :>> source="native_capabilities.py::configuration_probe_identity,completed_configuration_proof,configure_owned_source; completed_producer.py::configure_command";
    attribute :>> guard="Completed original configure receipt, identical policy/profile/tool/environment/non-template inputs and intact remembered configuration outputs. A changed configure.ac, including a header-path rename, requires full configure";
    attribute :>> reusable="Existing config.status regenerates templates from its authenticated substitutions. Retain the original probe receipt and a separate completed config-status receipt; exact unchanged configuration launches neither command";
    attribute :>> failure="Unknown emission cannot replace the prior successful proof. Unexplained output mutation under the same request refuses reuse. Template regeneration is not Scheme generation";
    attribute :>> benefit="A pure header/template edit can remove repeated compiler probes. Changed header bytes still invalidate native consumers; no compiler or macro-expansion speedup is inferred";
  }
  part buildRelocation:BuildBoundary {
    attribute :>> id="source-relocation";
    attribute :>> source="native_development.py::native_relocations,apply_native_delta,relocated_native_line,generation_recipe_projection";
    attribute :>> guard="Whole source move inventory, same-kind paths, exact predecessor SHA, unique target and no symlink or parallel old/new path. The existing leased workspace owns any interrupted move";
    attribute :>> reusable="Only literal native file/object lists and native C/header dependency rules normalize renamed paths. Scheme commands, module lists, preludes and arbitrary Make effects remain significant. Pinned generated C and compiler inputs stay byte-identical";
    attribute :>> failure="Validate before mutation; interrupted tree is unpublished and checkpoint-owned. Resume only through the registered workspace; unknown generation dependencies demand regeneration rather than implicit acceptance";
    attribute :>> benefit="Retire old source/API/build names in place without another full source tree or Scheme-to-C generation. Native objects/archives are invalidated for relocation; this does not promise zero native compilation";
  }
  part nativeObjects:BuildBoundary {
    attribute :>> id="native-object-context";
    attribute :>> source="native_development.py::native_object_context,execute_owned; workspace.py::sync_build_source,checkpoint_build_source";
    attribute :>> guard="Compare native argv/recipes, runtime object membership, public/feature header bytes and tool/environment identity with the last successful object context. A mutable entry configuration is not that evidence; missing context refuses object reuse unless an authenticated completed byte-identical artifact establishes it";
    attribute :>> reusable="Preserve the one successful context across source reconciliation. A repeated relocation declaration with no actual move does not invalidate objects. Body-only changes still follow real Make dependencies; this is not a new effectful build interpreter";
    attribute :>> failure="Do not replace the successful context until Make phases and generated-source checks complete. Failed configuration/build leaves the previous context accountable, so a retry cannot forget changed flags or headers. No source clean/copy or runtime completion is inferred from context metadata";
    attribute :>> benefit="Remove repeated full native recompilation caused only by the presence of relocation metadata. Actual new archive membership, header/tool/flag changes or a performed move still invalidate conservatively; unknown partial object completion remains separate work";
  }
  attribute sourceLock:String="evidence/research/root-worker-exit/source.lock.json";
  attribute upstreamCommit:String="9e6f6742c4d9e9915ee8af0dcb7d97cf1f836116";
  attribute upstreamUrl:String="https://github.com/erlang/otp.git";
  part def Replacement {
    ref part factor:GambitSmpFactorConditions::Factor;
    attribute id:String; attribute oldAuthority:String; attribute replacement:String;
    attribute condition:String; attribute retirement:String; attribute custody:String;
    attribute memoryOrder:String; attribute savedWork:String; attribute addedCost:String;
  }
  part r0:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f3;
    attribute :>> id="root-before-collect";
    attribute :>> oldAuthority="Raw thunk/value C locals, SFUN_ARG and marker setup choreographies";
    attribute :>> replacement="Generated NativeActivation root/borrow plan plus stable VM-owned root origin, before any collecting conversion";
    attribute :>> condition="Cover both run origins, generated SFUN/CFUN, RC writes and nested exceptional exits; a pointer to an unregistered local is not a root";
    attribute :>> retirement="Retire raw managed-entry choreography only when every admitted generator and native user calls the same plan; unmanaged ABI stays explicitly outside optimized admission";
    attribute :>> custody="Registration failure leaves parent roots owned; unknown acknowledgement retains source and destination until queried; startup rooted adapter is existing partial progress";
    attribute :>> memoryOrder="Root metadata initialized under origin gate; release-ready publication and acquire validation precede consuming handles; no collecting operation with an incomplete view";
    attribute :>> savedWork="Remove per-caller reinvention and stale-local recovery attempts; root scanning remains necessary";
    attribute :>> addedCost="Activation/origin records, root register and post-GC reload; retained payload graphs not bounded by fixed records";
  }
  part r1:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f3;
    attribute :>> id="frozen-root-publication";
    attribute :>> oldAuthority="PSTATE index and synchronous barrier imply complete membership and root stability";
    attribute :>> replacement="RoundCoordinator snapshots admitted RootOrigins with incarnations and frozen views independently of OS carrier population";
    attribute :>> condition="Freeze all root writers/borrowers; registration racing close belongs wholly to this round or retains source for next admission; return cannot mutate an unscanned included view";
    attribute :>> retirement="Remove participant-array-by-carrier construction after all resize, GC and callback admissions publish through one root registry and round gate";
    attribute :>> custody="Late registration remains VM/parent-root owned and cannot wait for GC while holding a writer lease; no root disappears on a failed close";
    attribute :>> memoryOrder="Mutex release/acquire publishes member set and root view; claim CAS uses acquire-release; plain slot access occurs only under frozen/exclusive authority, not a revision-only race check";
    attribute :>> savedWork="Avoid equating every root origin with one runnable collector carrier";
    attribute :>> addedCost="Frozen-view metadata, registration arbitration and scanner pins; complete round closure remains required";
  }
  part r2:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f1;
    attribute :>> id="origin-task-claim";
    attribute :>> oldAuthority="Strong/weak/cleanup completion selected by PROCESSOR_ID(work->carrier)";
    attribute :>> replacement="RootTask names VM, round, origin slot/incarnation, kind and claim generation; worker execution identity supplies no participant authority";
    attribute :>> condition="One claim owner scans actual frozen root locations; root task completion differs from completion of descendants and of the full strong phase";
    attribute :>> retirement="Replace carrier indexing in strong, weak, cleanup and root dispatch together; keep OS identity only for host instrumentation";
    attribute :>> custody="Failed dequeue retains queue authority; unknown claim stays recorded in-flight; never recreate a second scanner from an empty queue observation";
    attribute :>> memoryOrder="Initialize task before release queue publication; acquire dequeue/claim, release result/root writes; coordinator acquires completion before phase advance";
    attribute :>> savedWork="Allow W workers to service R root origins without W=R or fixed carrier affinity";
    attribute :>> addedCost="Task claims, root-owner indirection and completion metadata; no automatic speedup when W exceeds useful work";
  }
  part r3:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f1;
    attribute :>> id="independent-copy-arena";
    attribute :>> oldAuthority="Collector allocation, tospace and private frontier use work->context and carrier PSTATE context memory macros";
    attribute :>> replacement="WorkerArena owns copied intervals, frontier, Tail and destination grants; ContextResumePlan separately owns restored mutator intervals";
    attribute :>> condition="Migrate reserve/cancel/commit, stack-frame copying, section refill, still accounting, steal victims and instrumentation; pre-flip physical plan covers copy and resume without overlap";
    attribute :>> retirement="Retire collector context allocation macros and synchronous binding assertion only after the entire allocator/scanner/helper call graph consumes work/round/arena explicitly";
    attribute :>> custody="Unpublished copy or Tail cannot be abandoned; rejected transfer retains donor; unknown stop retains source arena and forbids a second initializer";
    attribute :>> memoryOrder="Arena-exclusive ordinary writes; published object readiness and ownership use release/acquire; migration requires stopped donor plus matching generation, never timeout alone";
    attribute :>> savedWork="Decouple copying policy and worker count from Scheme context lifetime; eligible arena tails can feed resume plans";
    attribute :>> addedCost="Worker arenas, packing and handoff metadata; count simultaneous copy, resume and unknown-retained reserves at physical peak";
  }
  part r4:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f1;
    attribute :>> id="round-global-tasks";
    attribute :>> oldAuthority="Processor zero and each carrier implicitly own VM roots, weak work, still sweep and shared overflow result";
    attribute :>> replacement="Round-scoped task keys and coordinator phase authorization; context root work and VM-global duties are different tasks";
    attribute :>> condition="VM roots/global variables scanned exactly as required; weak fixed point precedes cleanup; effects/affinity of foreign releases are admitted before movement/resume";
    attribute :>> retirement="Remove processor-zero semantic ownership and per-carrier weak/cleanup phase stores; host coordinator thread may remain a policy choice";
    attribute :>> custody="Owner-dependent release retains rooted deferred work and budget; collector never waits for callback execution forbidden by its own parked-owner policy";
    attribute :>> memoryOrder="Task and phase publication under round gate; release result before acquire acknowledgement; failure outcome is immutable for this round";
    attribute :>> savedWork="Remove accidental carrier duplication and owner-callback work from GC critical path when effects allow";
    attribute :>> addedCost="Explicit global/weak/release task accounting, effects checks and retained deferred payload";
  }
  part r5:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f1;
    attribute :>> id="descendant-closure";
    attribute :>> oldAuthority="scan_workers_count decrements and processor barriers imply no future scan producer";
    attribute :>> replacement="Closed producer set plus explicit queued, claimed, private-copy, Tail and descendant custody; stopped worker transfers its responsibilities";
    attribute :>> condition="Every publisher/last use is mapped; parent can finish only after children are durably accounted; handoff receipt proves custody rather than implying completed work";
    attribute :>> retirement="Retire idle-count-as-proof and fixed-population GC barriers together; waking/parking mechanisms can remain implementation details";
    attribute :>> custody="Unknown donor execution or publication leaves an in-flight debt; safeness can hold while progress is unresolved; cannot discharge debt by declaring carrier dead";
    attribute :>> memoryOrder="Reserve child debt before visibility; publish task then transfer authority; terminal transition serialized against producer admission; wait predicates checked under same gate";
    attribute :>> savedWork="Prevent premature completion and false all-worker participation requirements; permit scheduling independent from membership";
    attribute :>> addedCost="Debt/publication traffic and wakeup coordination; fairness and bounded external work remain separate assumptions";
  }
  part r6:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f3;
    attribute :>> id="context-resume";
    attribute :>> oldAuthority="Returning from identical per-processor GC barriers implies restored roots, capacity and overflow consumption";
    attribute :>> replacement="Whole-round resume seal plus context-specific physical allocation grant, authoritative root reload and immutable outcome receipt";
    attribute :>> condition="All required phases/results and native restrictions settled; each context consumes the same round outcome once; preserve multi-shot continuation and Scheme winding";
    attribute :>> retirement="Replace post-GC next_heap_msection/prepare_mem_pstate choreography and carrier result overwrite assumptions with one resume plan consumer";
    attribute :>> custody="Failed capacity admission keeps source before flip; post-flip unknown state forbids Scheme resume; GC movement does not recreate an expired native C activation";
    attribute :>> memoryOrder="Acquire seal and interval grant before address reload/resume; publication of a later round cannot erase unacknowledged result storage";
    attribute :>> savedWork="Avoid unnecessary carrier-wide acknowledgement and reinference of context capacity; required root repair/reload remains";
    attribute :>> addedCost="Per-context receipts, restored interval plans and result retention; resume reserve is not post-peak refund";
  }
  part r7:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f0;
    attribute :>> id="withdrawal-custody";
    attribute :>> oldAuthority="Native thread exit/join result jointly decides membership, work lifetime, roots and cleanup";
    attribute :>> replacement="Separate close-execution, freeze heap writes, transfer work/roots, close native users and recycle host slot authorizations";
    attribute :>> condition="Prove actual no-write/borrow boundaries and known task transfer; unknown join alone proves neither heap safety nor unsafe heap participation";
    attribute :>> retirement="Replace resize abort/shrink and post-run service-loop authority as one lifecycle cut, including accepted callbacks/errors and partial create failure";
    attribute :>> custody="VM retains outcomes, roots and resources across carrier loss; known frozen writers may detach with tasks reassigned; unknown shared-heap writers can still block the affected VM";
    attribute :>> memoryOrder="Close gates before draining permits; release custody receipt before source ACK; native handle reuse still needs known last native user, not GC completion";
    attribute :>> savedWork="Avoid GC veto solely for a safely detached native handle and avoid retaining an entire idle collective just to hold results";
    attribute :>> addedCost="Bounded control records plus possibly large rooted graphs/native arenas; exhaustion policy and failure scope explicit";
  }
  part r8:Replacement {
    ref part :>> factor=GambitSmpFactorConditions::f0;
    attribute :>> id="teardown-reclamation";
    attribute :>> oldAuthority="cleanup_pstate destroys RC/memory and synchronization after a successful join";
    attribute :>> replacement="Separate host cleanup from VM-owned root-domain/arena reclamation and managed-reader grace completion";
    attribute :>> condition="No scanner/borrower/late callback uses reclaimed storage; still/RC roots are transferred or proven dead; queued releases retain payload independently of PSTATE";
    attribute :>> retirement="Replace cleanup_os_and_mem_pstate lifetime coupling after every cleanup/setup/rollback consumer uses the new domain ownership; keep necessary OS resource release";
    attribute :>> custody="Unknown reader/native user prevents physical recycle; metadata cannot be reused across an unresolved incarnation; VM shutdown must drain or explicitly retain";
    attribute :>> memoryOrder="Acquired transfer ACK plus reader grace and native-close receipt precede free; managed epoch progress excludes unregistered native readers";
    attribute :>> savedWork="Reclaim unrelated healthy domains after qualified closure; do not scan a retired PSTATE solely because it owns RC storage";
    attribute :>> addedCost="Grace metadata, delayed native/resource frees and reader tracking; unmanaged borrowers need their own protocol";
  }
  part def Prerequisite { ref part dependent:Replacement; ref part prior:Replacement; }
  part d0:Prerequisite { ref part :>> dependent=r1; ref part :>> prior=r0; }
  part d1:Prerequisite { ref part :>> dependent=r2; ref part :>> prior=r1; }
  part d2:Prerequisite { ref part :>> dependent=r3; ref part :>> prior=r1; }
  part d3:Prerequisite { ref part :>> dependent=r4; ref part :>> prior=r2; }
  part d4:Prerequisite { ref part :>> dependent=r4; ref part :>> prior=r3; }
  part d5:Prerequisite { ref part :>> dependent=r5; ref part :>> prior=r4; }
  part d6:Prerequisite { ref part :>> dependent=r6; ref part :>> prior=r5; }
  part d7:Prerequisite { ref part :>> dependent=r7; ref part :>> prior=r5; }
  part d8:Prerequisite { ref part :>> dependent=r8; ref part :>> prior=r7; }
  part def Witness { attribute id:String; attribute file:String; attribute firstLine:Integer; attribute lastLine:Integer; attribute finding:String; }
  part w0:Witness { attribute :>> id="role-binding"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=4970; attribute :>> lastLine=4991; attribute :>> finding="Setup binds all three roles by processor index"; }
  part w1:Witness { attribute :>> id="root-scan"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7282; attribute :>> lastLine=7305; attribute :>> finding="Frozen origin supplies registers, startup, marker and RC roots"; }
  part w2:Witness { attribute :>> id="phase-owner"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7462; attribute :>> lastLine=7558; attribute :>> finding="Carrier chooses participant in all three phases"; }
  part w3:Witness { attribute :>> id="gc-driver"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7565; attribute :>> lastLine=7740; attribute :>> finding="Synchronous binding, barriers, public outcome, context refill and resume"; }
  part w4:Witness { attribute :>> id="allocator-origin"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=278; attribute :>> lastLine=339; attribute :>> finding="Allocator macros refer to carrier context while work cursors have separate fields"; }
  part w5:Witness { attribute :>> id="idle-proof"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7308; attribute :>> lastLine=7380; attribute :>> finding="Steal victim count and idle termination derive from participant/carrier population"; }
  part w6:Witness { attribute :>> id="resize-gc"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=940; attribute :>> lastLine=970; attribute :>> finding="Resize invokes GC inside an old-member collective"; }
  part w7:Witness { attribute :>> id="sync-gc"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=1135; attribute :>> lastLine=1176; attribute :>> finding="Sync executor dispatches GC and rooted resize transport"; }
  part w8:Witness { attribute :>> id="public-gc"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=1420; attribute :>> lastLine=1440; attribute :>> finding="Public GC calls on_all_processors"; }
  part w9:Witness { attribute :>> id="native-worker-run"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=769; attribute :>> lastLine=867; attribute :>> finding="Created thread enters sync loop, reloads thunk, runs Scheme then forwards outcome"; }
  part w10:Witness { attribute :>> id="main-run"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=6805; attribute :>> lastLine=6840; attribute :>> finding="Main VM invokes run using module thunk"; }
  part w11:Witness { attribute :>> id="run-marker"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=3634; attribute :>> lastLine=3698; attribute :>> finding="Startup rooted marker path differs from generic raw run entry"; }
  part w12:Witness { attribute :>> id="marker-root"; attribute :>> file="vendor/gambit/lib/c_intf.c"; attribute :>> firstLine=6511; attribute :>> lastLine=6577; attribute :>> finding="Root endpoint reloads after allocation; raw wrapper does not register its local"; }
  part w13:Witness { attribute :>> id="generated-entry"; attribute :>> file="vendor/gambit/gsc/_ptree2.scm"; attribute :>> firstLine=3142; attribute :>> lastLine=3180; attribute :>> finding="Scheme generator emits SFUN argument conversion and call body"; }
  part w14:Witness { attribute :>> id="join-cleanup"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=1019; attribute :>> lastLine=1116; attribute :>> finding="Create failure, shrink join, still transfer, retained state and thread exit"; }
  part w15:Witness { attribute :>> id="host-cleanup"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> firstLine=4847; attribute :>> lastLine=4860; attribute :>> finding="PSTATE cleanup currently calls memory then OS cleanup"; }
  part w16:Witness { attribute :>> id="rc-writer"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=730; attribute :>> lastLine=751; attribute :>> finding="Register RC mutates the current context chain"; }
  part w17:Witness { attribute :>> id="rc-reader"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=4314; attribute :>> lastLine=4334; attribute :>> finding="Collector scans a supplied context RC chain"; }
  part w18:Witness { attribute :>> id="actor-send"; attribute :>> file="vendor/gambit/lib/_thread.scm"; attribute :>> firstLine=3401; attribute :>> lastLine=3423; attribute :>> finding="Thread message enters shared mailbox FIFO"; }
  part w19:Witness { attribute :>> id="actor-payload"; attribute :>> file="vendor/gambit/lib/_fifo#.scm"; attribute :>> firstLine=50; attribute :>> lastLine=61; attribute :>> finding="FIFO cons retains the original payload, not a private object-graph copy"; }
  part w20:Witness { attribute :>> id="otp-scheduler"; attribute :>> file="vendor/erlang-otp/erts/emulator/beam/erl_process.c"; attribute :>> firstLine=9608; attribute :>> lastLine=9645; attribute :>> finding="Scheduler data and scheduled Process are separate objects"; }
  part w21:Witness { attribute :>> id="otp-progress"; attribute :>> file="vendor/erlang-otp/erts/emulator/beam/erl_process.c"; attribute :>> firstLine=9859; attribute :>> lastLine=9872; attribute :>> finding="Scheduler event loop reports thread progress before auxiliary work"; }
  part w22:Witness { attribute :>> id="otp-unmanaged"; attribute :>> file="vendor/erlang-otp/erts/emulator/beam/erl_thr_progress.h"; attribute :>> firstLine=205; attribute :>> lastLine=220; attribute :>> finding="Unmanaged delay handles have separate enter/continue accounting"; }
  part w23:Witness { attribute :>> id="otp-dirty-limit"; attribute :>> file="vendor/erlang-otp/erts/doc/references/erl_nif.md"; attribute :>> firstLine=430; attribute :>> lastLine=493; attribute :>> finding="Dirty scheduling does not authorize early GC or final native-resource destruction"; }
  part w24:Witness { attribute :>> id="otp-heap-contract"; attribute :>> file="vendor/erlang-otp/erts/emulator/internal_doc/GarbageCollection.md"; attribute :>> firstLine=24; attribute :>> lastLine=34; attribute :>> finding="OTP documents per-process generational semispace copying and process-local stack/heap"; }
  part w25:Witness { attribute :>> id="otp-grace-contract"; attribute :>> file="vendor/erlang-otp/erts/emulator/internal_doc/ThreadProgress.md"; attribute :>> firstLine=59; attribute :>> lastLine=99; attribute :>> finding="Thread progress requires known managed reporters; blocked unmanaged threads are excluded"; }
  part def SourceUse { ref part clause:Replacement; ref part witness:Witness; }
  part u0:SourceUse { ref part :>> clause=r0; ref part :>> witness=w9; }
  part u1:SourceUse { ref part :>> clause=r0; ref part :>> witness=w10; }
  part u2:SourceUse { ref part :>> clause=r0; ref part :>> witness=w11; }
  part u3:SourceUse { ref part :>> clause=r0; ref part :>> witness=w12; }
  part u4:SourceUse { ref part :>> clause=r0; ref part :>> witness=w13; }
  part u5:SourceUse { ref part :>> clause=r1; ref part :>> witness=w0; }
  part u6:SourceUse { ref part :>> clause=r1; ref part :>> witness=w1; }
  part u7:SourceUse { ref part :>> clause=r1; ref part :>> witness=w16; }
  part u8:SourceUse { ref part :>> clause=r1; ref part :>> witness=w17; }
  part u9:SourceUse { ref part :>> clause=r2; ref part :>> witness=w2; }
  part u10:SourceUse { ref part :>> clause=r3; ref part :>> witness=w4; }
  part u11:SourceUse { ref part :>> clause=r3; ref part :>> witness=w3; }
  part u12:SourceUse { ref part :>> clause=r4; ref part :>> witness=w2; }
  part u13:SourceUse { ref part :>> clause=r5; ref part :>> witness=w5; }
  part u14:SourceUse { ref part :>> clause=r6; ref part :>> witness=w3; }
  part u15:SourceUse { ref part :>> clause=r6; ref part :>> witness=w6; }
  part u16:SourceUse { ref part :>> clause=r6; ref part :>> witness=w7; }
  part u17:SourceUse { ref part :>> clause=r6; ref part :>> witness=w8; }
  part u18:SourceUse { ref part :>> clause=r7; ref part :>> witness=w9; }
  part u19:SourceUse { ref part :>> clause=r7; ref part :>> witness=w14; }
  part u20:SourceUse { ref part :>> clause=r8; ref part :>> witness=w15; }
  part u21:SourceUse { ref part :>> clause=r8; ref part :>> witness=w16; }
  part u22:SourceUse { ref part :>> clause=r8; ref part :>> witness=w17; }
  part def Learning {
    attribute id:String; attribute witnesses:String; attribute fact:String;
    attribute mismatch:String; attribute inference:String; attribute counterexample:String;
  }
  part l0:Learning { attribute :>> id="scheduler-process"; attribute :>> witnesses="otp-scheduler;otp-progress"; attribute :>> fact="Scheduler execution and process state are separate, with explicit process/runqueue synchronization"; attribute :>> mismatch="Gambit context and root graph are not an isolated Erlang process heap"; attribute :>> inference="Separate execution policy from root identity and collector task authority"; attribute :>> counterexample="Renamed carrier fields retain context-owned allocation and carrier-index completion"; }
  part l1:Learning { attribute :>> id="native-exit"; attribute :>> witnesses="otp-dirty-limit"; attribute :>> fact="Dirty scheduler separation permits other work; native execution can outlive logical process termination and delay GC/resources"; attribute :>> mismatch="Unknown native Gambit writers may reach shared movable graphs"; attribute :>> inference="Split logical exit, heap freeze, result delivery and physical native reclamation"; attribute :>> counterexample="A timeout or exiting flag is treated as proof that native writes stopped"; }
  part l2:Learning { attribute :>> id="reader-grace"; attribute :>> witnesses="otp-progress;otp-unmanaged;otp-grace-contract"; attribute :>> fact="Managed progress and unmanaged reader accounting have distinct APIs"; attribute :>> mismatch="External C callers cannot promise scheduler event-loop progress automatically"; attribute :>> inference="Use qualified reader grace for control metadata; preserve separate unmanaged borrower permits"; attribute :>> counterexample="Managed epoch advances while an unregistered native pointer still accesses freed storage"; }
  part l3:Learning { attribute :>> id="actor-memory"; attribute :>> witnesses="actor-send;actor-payload;otp-heap-contract"; attribute :>> fact="Gambit mailbox payload is a shared Scheme reference; OTP's local process collection relies on its own heap/term ownership contract"; attribute :>> mismatch="Actor API resemblance supplies neither heap isolation nor barriers for mutable shared data or continuations"; attribute :>> inference="Keep shared semantics and prove root/write contracts; any isolated actor API is a separately specified optional restriction"; attribute :>> counterexample="Copying all sent mutable values changes alias observations; treating shared values as local loses roots"; }
  part def NativeCase { attribute id:String; attribute observation:String; }
  part n0:NativeCase { attribute :>> id="entry-roots"; attribute :>> observation="Both run origins, generated raw/managed SFUN and CFUN, nonzero processor RC, nested callback and exceptional unwinding under forced GC"; }
  part n1:NativeCase { attribute :>> id="worker-origin-counts"; attribute :>> observation="Same VM with different R root-origin and W worker counts; all root/VM tasks once; carriers can change only at qualified cuts"; }
  part n2:NativeCase { attribute :>> id="copy-round"; attribute :>> observation="Duplicate delivery, Tail/private frontier handoff, weak descendants, CAS loss and physical pre-flip failure at unchanged heap/wait limits"; }
  part n3:NativeCase { attribute :>> id="exit-custody"; attribute :>> observation="Partial create, unknown join, late outcomes and owner-dependent cleanup; distinguish safely stopped actors from unknown shared writers and other-VM from same-VM progress"; }
  part n4:NativeCase { attribute :>> id="scheme-observations"; attribute :>> observation="Real map multi-shot capture/restore, shared mutation and dynamic-wind; proper tail space, natural exit and exact existing Bazel profile"; }
  part def Realization {
    attribute id:String; attribute phaseOrder:String; attribute sourceRefs:String;
    attribute publication:String; attribute affinity:String; attribute custody:String;
    attribute retired:String; attribute overheads:String; attribute qualification:String;
    attribute remaining:String; attribute modelOwnership:String;
  }
  part hashLayout:Realization {
    ref part specification=GambitHashIndexOwnership::identity;
    attribute :>> id="hash-layout-ownership";
    attribute :>> phaseOrder="READ -> FREEZE -> REPAIR -> RESUME -> READ_OR_WRITE_REBUILD";
    attribute :>> sourceRefs="GambitHashIndexOwnership::identity,traversal; vendor/gambit/lib/_mem/object-scanning.inc,weak-tables.inc,hash-table-api.inc,wills.inc; lib/_system.scm::gc-hash-table-for-each/search/foldl; doc/gambit.txi::table-for-each";
    attribute :>> publication="Existing frozen root/worker collective publishes repaired references. KEY_MOVED records actual address debt; it is not a new mutator publication or an atomic lock. GC leaves physical order intact";
    attribute :>> affinity="Collector workers repair reached tables; mutator reads are read-only. Exclusive native writers own index rebuilding regardless of collector count or SINGLE_THREADED_VMS";
    attribute :>> custody="GC preserves traversal coordinates and repaired roots. An unknown GC/native stop does not grant mutation or release authority. Weak removal is not a strong-table snapshot promise";
    attribute :>> retired="GC eager slot permutation, first-reader lazy mutation and eager/lazy selector in wills.inc; worst-case strong-key KEY_MOVED on every collection";
    attribute :>> overheads="No new heap/table field/reader registry. Compare each strong heap key before/after repair; O(n) read while native address debt persists; O(n) writer reconstruction remains. Stable permanent-key tables avoid speculative whole-table rebuild";
    attribute :>> qualification="Existing profile/default heap/same workspace; exact source delta; prior duplicate-key counterexample; QNT cursor counterexample and finite safety; interpreted/compiled moving and retained-weak keys; map multi-shot, W<R and unknown join";
    attribute :>> remaining="C linear-search/index encoding and every caller exclusion remain refinement obligations. No full bootstrap, remote CI, concurrent same-table writers, raw aliases or general unknown-stop recovery inferred";
    attribute :>> modelOwnership="Existing hash_index_owner QNT owns cursor/relocation/debt schedules; existing HashIndexOwner Lean owns conditional algebra only. Native evidence and source anchors stay distinct";
  }
  part rootPhases:Realization {
    attribute :>> id="root-phase-custody";
    attribute :>> phaseOrder="PREPARE -> STRONG -> WEAK -> CLEANUP; a completed task can advance only to its immediate next phase; thaw requires cleanup completion";
    attribute :>> sourceRefs="vendor/gambit/include/_gambit/runtime_roles.h.in::gc_root_phase; include/_gambit/vm_state.h.in::gc_root_task_publish,claim,finish,advance,gc_origin_thaw; lib/_mem/collection-round.inc::collect_root_tasks,advance_root_tasks,garbage_collect_pstate; lib/_mem/object-scanning.inc::setup_still_objs_to_scan; lib/_mem/wills.inc::process_wills; lib/_mem/still-sweep.inc::free_unmarked_still_objs; lib/_mem/root-origins.inc::mark_execution_roots,mark_global_variables";
    attribute :>> publication="Existing full-barrier CAS adapters publish claim and completion. Sole coordinator changes plain phase only between physical collective barriers. PREPARE begins after all task and worker frontiers are initialized; root task completion does not imply descendant drain";
    attribute :>> affinity="Prepare, strong roots and wills claim actual frozen origin slots independently of carrier. The workerDomains extension moves cleanup to all R native owners with distinct host-domain task tokens; arbitrary native reentry remains unqualified. Carrier eligibility alone supplies no task authority";
    attribute :>> custody="Failed/stale phase claim cannot mutate roots. Unknown or in-flight task remains claimed; no phase advance, thaw or speculative second scanner. Retained empty unpublished abort actors use the existing isolation contract; unknown shared-heap writers remain excluded";
    attribute :>> retired="Implicit carrier-owned still-root preparation, deferred still accounting, wills lists and sweep list access. Strong-only completion no longer permits thaw. Global-root partition uses worker census, not origin census";
    attribute :>> overheads="One phase field per fixed RootTask plus alignment; four claim/finish pairs per origin instead of one. Four additional collective barriers per round protect initialized publication and three next-phase authorizations. Root scan work remains; no heap increase or throughput claim";
    attribute :>> qualification="Require exact-source, original-profile, same-workspace, phase-kernel, topology-and-map, calibrated-unknown-join, fresh-processes, bounded-budgets. Existing typed source.project -> source.bind -> native.workspace-build, native.test and gambit.executable-test are reused; no task Python executor";
    attribute :>> remaining="WorkerArena and W/R owner services are tracked by workerArena and workerDomains; complete pre-flip physical plan and independent carrier scheduling remain open; unmanaged root/FFI writers and borrower closure; owner-affine finalizer handoff; unknown published retiree/reaper and whole SMP acceptance. Historical mem.c witness coordinates describe predecessor source, not current split fragments";
    attribute :>> modelOwnership="SysML owns realization and evidence scope; ASCENT joins source/native guards. Existing QNT handles bounded scheduling/authorization and Lean handles refinement/algebra. No new duplicate models or C memory-model proof claimed";
  }
  part workerArena:Realization {
    attribute :>> id="worker-arena-handoff";
    attribute :>> phaseOrder="RESERVE -> COPY -> DRAIN -> HANDOFF; context restoration follows weak descendant drain and precedes capacity/resize readers";
    attribute :>> sourceRefs="vendor/gambit/include/_gambit/runtime_roles.h.in::gc_resume_space,gc_worker_arena; include/_gambit/vm_state.h.in::gc_arena_handoff; lib/_mem/heap-sections.inc::prepare_worker_msection,refill_worker_arena,setup_stack_heap_vmstate; lib/_mem/copy-reservations.inc::reserve_copy; lib/_mem/capacity-resize.inc::move_continuation; lib/_mem/collection-round.inc::garbage_collect_pstate; lib/setup.c::setup_pstate";
    attribute :>> publication="Frozen collective coordinator initializes R stack grants and W distinct copy grants before task publication. VM allocator lock exclusively advances the section ledger. Private copy reservation/refund never changes the context heap cursor. Physical weak-phase barriers drain old writers before handoff";
    attribute :>> affinity="No collector context field. Root origins remain independent of arenas. The workerDomains extension assigns a loan/tail recipient only to each active worker and independent empty spans to the other R-W domains. Cleanup affinity and physical carrier barriers remain; W>R is not qualified";
    attribute :>> custody="Forwarding winner retains payload/Tail responsibility; a pending grant or active scan rejects handoff. Final interval plus retired copied words transfer once under epoch-matched exclusive resume ownership. Unknown writer forbids transfer. Empty aborted unknown-join actors remain VM-held and isolated; published unknown writers remain excluded";
    attribute :>> retired="reserve_copy no longer exports its tip to context memory, invokes next_heap_msection or reimports context limits. Collector refills use the VM section ledger and a bounded one-use stack loan. Round destination parity no longer derives from the worker carrier. Active stack restoration consumes the participant context explicitly";
    attribute :>> overheads="R stack plus W initial copy sections, unchanged at W=R; no heap multiplier. Fixed resume/arena metadata, one handoff per context, one VM allocation lock per physical refill. Retired copied words enter the context ledger once. The optional stack loan is capped by original three-quarter policy and actual stack footprint plus fudge, not counted as extra memory";
    attribute :>> qualification="Require exact-source, original-profile, same-workspace, arena-kernel, topology-and-map, refill-exercised, calibrated-unknown-join, authenticated-executions, bounded-budgets. Reuse typed source projections, compile products and fresh execution capabilities; no new task Python executor";
    attribute :>> remaining="The workerDomains realization extends this earlier bijective slice with selected W<R owner services. Exact physical pre-flip copy packing, arbitrary native-writer closure, independent carrier scheduling and natural quarantined-handle reaping remain open. Source-word totals alone do not bound section fragmentation or large contiguous objects";
    attribute :>> modelOwnership="Existing QNT owns claim/phase/transfer interleavings; existing Lean owns coverage and accounting refinement. This slice provides C source adapters and real native observations only. ASCENT requires source/profile/contract joins and rejects missing guards; it cannot infer unequal worker admission or whole retirement";
  }

  part def WorkerAdmission { attribute id:String; attribute progress:String; attribute condition:String; attribute source:String; attribute proofOwner:String; }
  part wa0:WorkerAdmission {
    attribute :>> id="independent-refill";
    attribute :>> progress="source-refined";
    attribute :>> condition="VM section ownership, one private writer, bounded one-use stack loan and exactly-once drained handoff";
    attribute :>> source="heap-sections.inc::refill_worker_arena; vm_state.h.in::gc_arena_handoff";
    attribute :>> proofOwner="QNT copy_custody.qnt: bounded transfer interleavings; Lean CopyCustody.lean: custody refinement premises; C/native adapter only this turn";
  }
  part wa1:WorkerAdmission {
    attribute :>> id="resume-coverage";
    attribute :>> progress="source-refined";
    attribute :>> condition="W tails have distinct recipients; all other R-W roots restore from their own empty bounded span; all R active stacks seal before cleanup";
    attribute :>> source="heap-sections.inc::setup_stack_heap_vmstate; capacity-resize.inc::determine_occupied_words";
    attribute :>> proofOwner="QNT round_capacity.qnt: reservations and publication; Lean RoundCapacity.lean: interval coverage and conservation; no new proof run";
  }
  part wa2:WorkerAdmission {
    attribute :>> id="affine-cleanup";
    attribute :>> progress="source-refined";
    attribute :>> condition="All R cleanup domains serviced on allowed host threads independently of W copy executors, with retained native payloads";
    attribute :>> source="collection-round.inc::collect_root_tasks CLEANUP";
    attribute :>> proofOwner="Actual owner service and pthread destructor identity; native reentry remains under native-writer closure; no new QNT/Lean scheduler";
  }
  part wa3:WorkerAdmission {
    attribute :>> id="collective-split";
    attribute :>> progress="source-refined";
    attribute :>> condition="All R physical carriers participate in existing barriers while exactly W distinct workers execute scan and terminate";
    attribute :>> source="collection-round.inc::garbage_collect_pstate; setup.h::BARRIER";
    attribute :>> proofOwner="Source/C synchronization refinement and native unequal-count tests; existing bounded control models do not grant physical participation";
  }
  part wa4:WorkerAdmission {
    attribute :>> id="descendant-termination";
    attribute :>> progress="source-refined";
    attribute :>> condition="R phase tasks plus all generated chunk/Tail/weak descendants drain before W-worker idle termination advances the round";
    attribute :>> source="collection-round.inc::mark_reachable_from_marked; advance_root_tasks";
    attribute :>> proofOwner="QNT copy_custody.qnt: authorization and interleavings; Lean CopyCustody.lean: coverage preservation; same obligations reused";
  }
  part wa5:WorkerAdmission {
    attribute :>> id="physical-packing";
    attribute :>> progress="open";
    attribute :>> condition="Pre-flip simultaneous copy and R restore grants cover actual contiguous objects, frame expansion and fragmentation at unchanged heap policy";
    attribute :>> source="heap-sections.inc::setup_stack_heap_vmstate; copy-reservations.inc::reserve_copy";
    attribute :>> proofOwner="QNT round_capacity.qnt: finite placement counterexamples; Lean RoundCapacity.lean: parametric packing/coverage; C planning bridge open";
  }
  part wa6:WorkerAdmission {
    attribute :>> id="native-writer-closure";
    attribute :>> progress="open";
    attribute :>> condition="Included roots and payload writers physically stopped; safely isolated unpublished abort differs from unknown published/native writer";
    attribute :>> source="setup.c::resize; collection-round.inc::garbage_collect_pstate";
    attribute :>> proofOwner="QNT root_producer_closure.qnt: producer close/late work; Lean RootProducerClosure.lean: coverage refinement; source/native writer inventory open";
  }

  part workerDomains:Realization {
    attribute :>> id="worker-root-domains";
    attribute :>> phaseOrder="FREEZE -> PREPARE -> STRONG -> WEAK -> RESTORE -> OWNER_CLEANUP -> RESUME; W scan executors and R owner services share explicit physical phase cuts";
    attribute :>> sourceRefs="runtime_roles.h.in::gc_resume_space,gc_round; vm_state.h.in::gc_resume_without_arena; collection-round.inc::garbage_collect_pstate,cleanup_root_domain; heap-sections.inc::setup_stack_heap_vmstate; still-sweep.inc::free_unmarked_still_objs; memory-lifecycle.inc::setup_mem_vmstate";
    attribute :>> publication="Atomic requested-worker ceiling is snapshotted after physical root freeze and clamped to current R. A nonworker lacking empty-heap fudge causes pre-flip fallback to the existing W=R plan. Coordinator publishes actual W, R restore grants and W arenas through the all-carrier setup barrier. No worker-only helper contains a physical R-carrier barrier. Existing full-barrier C adapters publish requests; exclusive GC stores rely on actual phase exclusion";
    attribute :>> affinity="Only W workers claim preparation/strong/weak root tasks and scan descendants. All R stopped native owners restore their own active context and claim CLEANUP with a distinct host-domain token, even when not a collector. Foreign release uses the original native thread and PSTATE; owner-dependent native reentry is not newly admitted";
    attribute :>> custody="W retired-prefix ledgers and final spans transfer to W distinct context recipients. Other R-W contexts take an empty heap interval from their own pre-reserved stack bottom. The physical restore receipt records source_worker or -1, epoch, acceptance and stack copy completion; all R receipts precede native cleanup. Actual GVM fp/hp/interrupt limits are finalized by prepare_mem_pstate after capacity outcome and cleanup, before root thaw; a physical receipt does not authorize native Scheme reentry. Unknown task/worker writer prevents completion and resume";
    attribute :>> retired="Remove W=R guard and paired restore obligation for every carrier; remove CLEANUP from collector dispatch; remove inactive-worker copy/frontier participation and physical barriers from worker-only helpers. Root, restore, host cleanup and scan termination counts are no longer interchangeable";
    attribute :>> overheads="R roots and R owner cleanup services remain. W copy arenas/queues/idle counters replace R collector jobs. One extra all-R barrier seals all restored stacks before native release; fixed restored/source-owner metadata and atomic worker request. Initial physical demand is R+W, bounded by the previous 2R adapter; no heap/profile multiplier or throughput claim";
    attribute :>> qualification="Require exact-source, original-profile, same-workspace, domain-kernel, topology-and-map, refill-exercised, calibrated-unknown-join, authenticated-executions, bounded-budgets, owner-domain-service. Actual R=3/W=1,2,3,1 transitions and pthread destructor identity are required, alongside host topology multi-shot map and unknown-join W<R observations";
    attribute :>> remaining="Selected 1 <= W <= R adapter only; W>R, complete pre-flip copy packing, unknown published/native writers, native cleanup reentry, independent carrier migration and natural quarantined-handle reaping remain open. All physical carriers still stop and service existing barriers; W<R is not asynchronous/concurrent GC or a throughput result";
    attribute :>> modelOwnership="SysML owns source replacement and admission inventory. ASCENT authenticates current C/native adapters and missing conditions. Existing QNT models retain bounded scheduling/authorization histories; existing Lean models retain coverage/accounting/refinement algebra with premises. No new duplicate transition system, theorem run or C-memory-model proof";
  }

  part ownerEffects:Realization {
    attribute :>> id="owner-cleanup-effects";
    attribute :>> phaseOrder="DETACH -> RELEASE -> MERGE -> ACCOUNT -> PHASE_COMPLETE; new still objects are a separate owner generation, not part of the frozen sweep";
    attribute :>> sourceRefs="still-sweep.inc::free_unmarked_still_objs; collection-round.inc::cleanup_root_domain; object-allocation.inc::alloc_scmobj_still; setup.c::garbage_collect,call,run; runtime_roles.h.in::GC_OWNER_CLEANUP,gc_cleanup_escrow; vm_state.h.in::gc_cleanup_empty; memory_state.h.in::STILL prefix coordinates; tests/smp/gc/worker-root-domains.scm::domain_release";
    attribute :>> publication="The actual native owner sets OWNER_CLEANUP after restored-stack barrier and task claim. It moves the old chain into VM-owned cleanup.pending, records survivors plus in-flight base/native payload/release function before invoking callbacks; callback allocations publish to a fresh chain. After all known returns it merges survivors and fresh objects, recounts actual lengths and clears deferred accounting before ROOTS_FROZEN/task completion";
    attribute :>> affinity="R owner services retain actual pthread/PSTATE, independently of W. Selected release callbacks may allocate and fully initialize noncollecting still objects, with explicit still refcount roots. This is not permission to use unregistered movable pointers, generated SFUN argument writes or a different owner";
    attribute :>> custody="Fresh list is never overwritten by the old sweep tail. Detached pending/survivor chains and in-flight native identity live in fixed VM storage, not solely a C activation; nonempty escrow refuses slot setup. Same-carrier shutdown is refused before interrupt/resize destruction. A collecting allocation fails before starting a nested GC or publishing an object. Public GC and low-level call/run entries refuse before collective or managed-frame effects. Nonreturning callback exits leave VM-owned pending/inflight custody and an incomplete task; native result/stop recovery is not proved and cannot justify replay. A normal C return carrying a release error still uses the legacy result policy and does not prove resource disposition";
    attribute :>> retired="Replace sweep mutation of the public still head during native releases; remove the unconditional deferred-counter reset that could discard callback-created objects. One run_function type in runtime_forwards now drives public import, function-table field and implementation forward declaration; the definition is compiler-checked against it. Independent expected C types and real calls remain separate controls. Native cleanup no longer silently reenters the current GC collective or creates a managed activation from a physical restore receipt";
    attribute :>> overheads="Five pointer-sized fields per fixed participant retain pending/survivor/inflight/native payload/function identity, plus one fresh-chain recount; no dynamic metadata allocation or extra barrier. One phase enum value and constant-time entry checks. All callback-created still/native resources consume existing heap and remain until their real subsequent release; no heap multiplier or pause-speed claim";
    attribute :>> qualification="Require exact-source, original-profile, same-workspace, domain-kernel, topology-and-map, refill-exercised, calibrated-unknown-join, authenticated-executions, bounded-budgets, owner-domain-service, fresh-still-generation, refusal-before-effects, native-run-abi, write-authority, copy-before-reserve. Independent C Generic type checks must match public declaration and function table, and the real callback must call the correct current ABI. The root kernel compiles the actual write_authority implementation and shared component controls; source-bounded-request and closed-root-domain have independent source/native guards; source relocations must remove every old API/file name without aliases. Actual callbacks must allocate child FOREIGN objects, retain them in the owner chain, drop roots, finalize once in the next epoch, and reject call/run/GC/collecting-allocation/shutdown attempts before register/stack/catcher/setup-state changes; observe escrow during callbacks and empty after completion";
    attribute :>> remaining="Complete copy-capacity plan and arbitrary native writer closure remain open. Generated SFUN conversion can write before call, RC domain/borrow adapters cover selected same-owner entries but arbitrary payload aliases remain excluded, nonlocal native exits need escrow and no-write evidence, teardown free_still_objs is a separate producer, and known callback completion does not prove native resource release after an error";
    attribute :>> modelOwnership="Existing QNT root_producer_closure/copy_custody owns producer closure and in-flight history; existing Lean RootProducerClosure/CopyCustody owns source/refinement premises. SysML records actual source boundaries and negative evidence; ASCENT may qualify this owner-service slice but cannot discharge the whole native-writer condition";
  }
  part copyAuthority:Realization {
    attribute :>> id="copy-before-reservation";
    attribute :>> phaseOrder="SOURCE_HINT -> SOURCE_SECTION -> CLAIM -> REVALIDATE -> RESERVE -> FORWARD -> RELEASE -> INITIALIZE -> READY -> COMMIT -> TAIL";
    attribute :>> sourceRefs="vm_state.h.in::gc_copy_acquire,gc_copy_release; memory_state.h.in::msection.copy_gate; movable-sections.inc::adjust_msections; copy-reservations.inc::load_copy_source_header,mark_array; heap-sections.inc::setup_stack_heap_vmstate; continuation-roots.inc::mark_captured_continuation_locked";
    attribute :>> publication="Gate belongs to the source msection and is initialized before section publication. Validated source coordinates resolve the owner; no hash cardinality or object identity table. Section lifetime spans the round, and reset requires prior writer drain. Revalidation precedes reserve/refill; release follows forwarding before payload or Tail. Round reset requires all earlier collectors physically complete. Forwarding visibility does not imply payload READY";
    attribute :>> affinity="Distinct objects in one physical source section serialize reservation; distinct source sections remain independent. Their object identities are never merged. Frame construction takes frame_gate before copy_gate; no copy-gate holder acquires frame access or scans a child. FIFO dequeue releases its own gate before scan";
    attribute :>> custody="Gate winner retains private reservation, payload initialization and sole Tail. Unknown writer/owner stop cannot be timed out, cleared or replayed. The existing CAS-loss refund remains defensive for a writer outside the admitted protocol; it does not establish packing for bypass writers";
    attribute :>> retired="For the two managed object-forwarding variants, remove speculative reservation and section refill by a contender that finds a published forwarding pointer. Captured stack frames already share frame access. FIFO FORW transport writes do not publish object copies";
    attribute :>> overheads="One word per allocated msection, no fixed VM array. If N sections are allocated, storage is N times sizeof WORD; compared with the former array, metadata delta is (N-64) times sizeof WORD. One acquire/release per attempted winner plus header revalidation. Native ordered-word backend loads each inspected header directly; legacy fallback takes an additional gate around its ordinary read to avoid RMW on read-only storage. Same-section requests and reservation critical sections serialize; payload copy remains parallel. Source metadata trailer stays unchanged. Heap/profile limits unchanged; metadata is charged separately, no measured throughput claim";
    attribute :>> qualification="copy-before-reserve; current source C same-section/distinct-section gate controls, actual W<R continuation/root/refill and unknown-join observations; read-only header loads must not issue RMW";
    attribute :>> remaining="All successful-copy section tails still need a physical packing bound; source/frame census, maximum request, full pre-flip plan and reversible common refusal remain open. Native bypass stores and unknown copier stop are not made safe by section-owned arbitration. Full-round worker reset already requires collective completion";
    attribute :>> modelOwnership="Reuse copy_custody QNT grant/cancel schedules with strengthened source admission; Lean RoundCapacity needs real sectionPackingBound inputs, not another transition system. ASCENT checks ordered source anchors and actual C/runtime receipts, not an end-to-end C memory-model proof";
  }
  part sourceRequest:Realization {
    attribute :>> id="source-bounded-request";
    attribute :>> phaseOrder="CLAIM -> VALIDATE_INTERVAL -> PREPARED -> RESERVED -> COMMIT_OR_CANCEL -> SETTLED";
    attribute :>> sourceRefs="runtime_roles.h.in::gc_copy_request; copy-reservations.inc::prepare_copy_request,reserve_copy,cancel_copy,commit_copy; continuation-roots.inc::mark_captured_continuation_locked; collection-round.inc::worker drain";
    attribute :>> publication="Immutable source section/start/length, destination length, epoch and frame kind precede full-barrier CAS from settled to prepared; reserve consumes exactly this request before refill. Physical grant precedes reserved CAS; known settlement clears state after arena settlement";
    attribute :>> affinity="One request per VM-owned worker, no identity table. Heap claim uses source section gate; frame claim uses frame_gate. Both execute the same source interval validation and destination reservation";
    attribute :>> custody="Unknown pre-reserve or reserved copy retains request and any arena pending interval; worker drain refuses nonzero request. No timeout/reset/replay manufactures payload completion. A known forwarding loss settles only its own private interval";
    attribute :>> retired="Unchecked reserve_copy entry with only a body length; C-local-only source coordinates before arena refill. Duplicate forwarding contenders still create zero requests or refills";
    attribute :>> overheads="Per VM worker storage sizeof gc_copy_request plus one SIZE_TS; active requests use two CAS and one fetch-clear, source interval checks and one source-charge addition. All MAX_PROCESSORS descriptors are stored, even if W is smaller. No managed heap increase; native metadata and contention charged separately";
    attribute :>> qualification="source-bounded-request; both actual reserve_copy callers, frame/heap roots, refill/loan and settled request observed in worker-root-domains";
    attribute :>> remaining="A validated individual source interval is not an injective pre-flip census or a packing algorithm. Effective RETI frames and loaded-module bounds, successful-copy stranded space, restore/fudge, unknown retained domains and common recoverable refusal must compose before full admission";
    attribute :>> modelOwnership="Existing QNT copy_custody owns interrupted request/cancel histories; Lean ProducerCapacity and RoundCapacity own interval/source-charge and packing lemmas. No duplicate formal model or fresh proof result";
  }
  part rootAdmission:Realization {
    attribute :>> id="closed-root-domain";
    attribute :>> phaseOrder="RUNNING -> CLOSE_WRITERS -> FROZEN_SCAN -> OWNER_CLEANUP -> WHOLE_ROUND_DRAIN -> REOPEN";
    attribute :>> sourceRefs="memory_state.h.in::rc_header.domain,context_mem.rc_gate_; rc-allocation.inc::register_rc,set_data_rc,alloc_rc_roots,store_rc_root,borrow_rc_root,return_rc_root,cleanup_rc; rc-roots.inc::mark_rc; c_intf.c::make_sfun_stack_marker; os_dyn.c::make_c_closure; examples/tcltk/tcltk.scm::command creation";
    attribute :>> publication="Owner closes under context gate before ROOTS_FROZEN and the collective barrier. Scanner owns the same gate and requires closed. Store/link/refcount access uses acquire/release spinlock; reopen follows RUNNING and final all-R barrier. These are current C synchronization adapters, not a C memory-model proof";
    attribute :>> affinity="Root domain is execution context, scanner is any admitted worker. SFUN resolves same-owner RC root cell before allocating marker and reloads after allocation. Borrow pins RC cell and increments domain debt; it does not hold gate or block GC while Scheme/native work executes";
    attribute :>> custody="Closed registration refuses without taking source allocation; alloc_rc frees its own refused unregistered block; failed payload store leaves old root unchanged. Borrow cannot race final release while caller owns an incoming reference. Unknown nonlocal exit retains registered cell/debt and refuses cleanup; no claim of general callback pin/delete recovery";
    attribute :>> retired="Unprotected RC link/payload/scanner accesses, mismatched register/count definitions, raw C-local marker procedure root and post-allocation c_closure_self payload read in selected SFUN path. All consumers must rebuild for BOOL set_data_rc ABI";
    attribute :>> overheads="One context pointer and one root_count word per RC allocation and sentinel; one SPINLOCK plus two WORDs per allocated context; short gate operations per RC API and scan, two refcount updates per borrow. The raw marker API retains its temporary procedure-cell route. Generated SFUN now allocates one bank with nargs+2 SCMOBJ cells and native flag bytes, registers raw SCMOBJ parameters before collecting conversion, defers marker allocation and reloads the bank into one gated argument batch. Known normal/error/unwind return releases its borrow and owner reference. Rooted startup uses its existing dedicated root. Writer and borrow gates release before Scheme allocation or native callbacks. Scanner holds gate through mark_array including private arena refill; custom allocators which call RC/ Scheme or wait for the owner are excluded. Native release can wait for this whole root task; its latency is not proven bounded independently of graph/copy cost";
    attribute :>> qualification="closed-root-domain; three owner domains with W=1,2,3,1, sole borrowed moving roots, closed cleanup rejection before effects, marker construction, repeated continuation and independent ABI consumer";
    attribute :>> remaining="c_closure_self is still a process-global trampoline cell; cross-thread callbacks, raw payload aliases, raw/bypassing SFUN conversion/argument writers, arbitrary nonlocal native exits and VM teardown grace remain excluded. Tcl construction root fix does not qualify deletion/reentry or Tcl runtime";
    attribute :>> modelOwnership="models/gambit/host_roots_contract.qnt and dev/architecture/runtime/gc/models/quint/native_scope_gate.qnt own existing close/borrow histories; models/gambit/lean/HostRootsRefinement.lean owns stable-cell/scan mapping premises. ASCENT ties source anchors to actual tests without repeating their models";
  }
  part def CapacityBoundary {
    attribute id:String; attribute source:String; attribute premise:String;
    attribute modelOwner:String; attribute outcome:String;
  }
  part cb0:CapacityBoundary {
    attribute :>> id="copy-charge"; attribute :>> source="configuration.inc::words_movable_objs; heap-sections.inc::source_words; continuation-roots.inc::captured frame construction";
    attribute :>> premise="A closed injective census covers every distinct old heap object and stack frame, including header/alignment expansion. Current doubled occupied words is not such an adapter Conditional envelope: D=sum destination_i <= sum source_i + A32 <= S_alloc + A32 requires a disjoint complete source census. Current per-request check proves only interval containment and destination_i <= source_i + one alignment word for heap, or <= source_i for frames; it does not validate S_alloc from doubled legacy occupied counters.";
    attribute :>> modelOwner="QNT copy_producer_envelope: producer/epoch histories; Lean ProducerEnvelope and ProducerCapacity: source/span refinement premises";
    attribute :>> outcome="unresolved";
  }
  part cb1:CapacityBoundary {
    attribute :>> id="request-envelope"; attribute :>> source="gsc/_t-c-1.scm and _t-c-2.scm; copy-reservations.inc::reserve_copy; native constructors and loaded module descriptors";
    attribute :>> premise="Actual maximum contiguous request covers all loaded modules, dynamic/native constructors and effective RETI frames; no universal selected-generator constant Actual heap request is header plus body plus worst 32-bit alignment; frame request is fs+FRAME_EXTRA_SLOTS+header, sourced from FRAME_SPACE(effective fs), including RETI decoding. Each request must fit one admitted piece, independently of total free words.";
    attribute :>> modelOwner="QNT copy_producer_envelope: late/opaque producers; Lean ProducerCapacity: normal/internal frame bounds under ABI premises";
    attribute :>> outcome="unresolved";
  }
  part cb2:CapacityBoundary {
    attribute :>> id="attempt-fragmentation"; attribute :>> source="copy-reservations.inc::reserve_copy,cancel_copy; heap-sections.inc::end_heap_chunk,refill_worker_arena";
    attribute :>> premise="mark_array now resolves the validated source msection and takes its lifetime-owned gate, revalidates the source header and only then reserves/refills. It releases after forwarding, before payload/Tail work. Captured stack-frame construction remains serialized by frame_gate. Managed duplicate contenders therefore request no space. Ordinary successful-copy packing loss, unsupported forwarding writers, native interruption and full pre-flip admission remain obligations; a private refund never restores a closed section Physical destination requirement is D+K+J+F+Hrestore-Qpre <= N*half, with K all end markers (including empty/refill/final), J leading links, F reserved terminal and stranded tails, Hrestore every R restoration grant and Qpre only proved overlap of pre-reserved loans. It also needs an injective interval placement and largest-request fit. Post-GC refund is not Qpre and cannot reduce the admitted round peak.";
    attribute :>> modelOwner="QNT copy_custody: grant/cancel and transfer histories; Lean RoundCapacity: sectionPackingBound requires a real exhausted-section charge";
    attribute :>> outcome="unresolved";
  }
  part cb3:CapacityBoundary {
    attribute :>> id="physical-source-pool"; attribute :>> source="heap-sections.inc::setup_stack_heap_vmstate; setup.c::resize quarantine and grant isolation";
    attribute :>> premise="Full plan assigns known disjoint physical parity intervals; excludes retained domains and unknown allocator results; logical heap size and pool count alone are insufficient";
    attribute :>> modelOwner="QNT round_capacity: finite placement/unknown outcomes; Lean RoundCapacity and CopyCapacityComposition: coverage and collective publication premises";
    attribute :>> outcome="unresolved";
  }
  part cb4:CapacityBoundary {
    attribute :>> id="restore-fudge"; attribute :>> source="heap-sections.inc::restore_loan_words,actual W fallback; vm_state.h.in::gc_resume_without_arena; capacity-resize.inc::move_continuation";
    attribute :>> premise="Every R physical stack grant and R-W empty heap partition covers restoration and fudge; requested W falls back to the same role architecture with W=R before flip when needed";
    attribute :>> modelOwner="Current C/native W/R adapter; existing Lean interval inequalities, not a new packing theorem";
    attribute :>> outcome="selected-source-native-control";
  }
  part cb5:CapacityBoundary {
    attribute :>> id="known-refusal"; attribute :>> source="heap-sections.inc::setup_stack_heap_vmstate; collection-round.inc::garbage_collect_pstate; allocation-limits.inc and resize caller";
    attribute :>> premise="A common capacity refusal preserves every source root and allocator, cancels no unknown native grant and returns one outcome without partial flip; current initial failure remains fatal";
    attribute :>> modelOwner="QNT round_capacity and collective admission: failure/interleaving history; Lean CopyCapacityComposition: rejection/flip implication under source gates";
    attribute :>> outcome="unresolved";
  }
  part def NativeBoundary {
    attribute id:String; attribute source:String; attribute contract:String;
    attribute admission:String; attribute remaining:String;
  }
  part nb0:NativeBoundary {
    attribute :>> id="owner-new-still"; attribute :>> source="object-allocation.inc::alloc_scmobj_still; still-sweep.inc::free_unmarked_still_objs";
    attribute :>> contract="Actual owner, noncollecting allocation, fully initialized payload before next safe point, explicit roots or refcount, fresh-generation merge and exact accounting";
    attribute :>> admission="selected-source-native-control";
    attribute :>> remaining="No permission for unregistered movable aliases or incomplete payloads across callback failure";
  }
  part nb1:NativeBoundary {
    attribute :>> id="nested-gc"; attribute :>> source="setup.c::garbage_collect; object-allocation.inc::alloc_scmobj_still";
    attribute :>> contract="Non-RUNNING participant returns failure before a nested collective; collecting allocation does not publish a new object";
    attribute :>> admission="explicit-rejection";
    attribute :>> remaining="Does not stop an unregistered native thread from writing shared memory";
  }
  part nb2:NativeBoundary {
    attribute :>> id="managed-entry"; attribute :>> source="setup.c::call,run";
    attribute :>> contract="Reject non-RUNNING entry before own stack/register/marker effects; a physical restored flag is not execution authority";
    attribute :>> admission="explicit-rejection";
    attribute :>> remaining="SFUN marker construction now borrows a registered same-owner root; subsequent generated conversions and SFUN_ARG stores still need activation-wide admission";
  }
  part nb3:NativeBoundary {
    attribute :>> id="raw-rc-and-payload"; attribute :>> source="rc-allocation.inc::register_rc,release_rc; foreign_conversion.h.in::SFUN_ARG; generated raw stores";
    attribute :>> contract="Need complete writer permits, stable registered roots, epoch-close and no-write evidence for every admitted native borrower";
    attribute :>> admission="unresolved";
    attribute :>> remaining="Source families are enumerated by NativeWriter below; source inventory is distinct from permit enforcement. RC registration/payload/scanning now share a context gate and SFUN marker construction borrows its stable root cell. Generated argument/root stores, native aliases and teardown still lack one enforced activation/root-domain protocol. Exported APIs and external code forbid claiming a complete finite caller census from repository text search";
  }
  part nb4:NativeBoundary {
    attribute :>> id="nonlocal-native-exit"; attribute :>> source="setup.c::propagate_error; foreign_conversion.h.in::THROW; still-sweep.inc::release_foreign";
    attribute :>> contract="VM-owned pending/survivor/inflight/native identity is implemented; still need stable stop and resource-result recovery before task completion or replay";
    attribute :>> admission="unresolved";
    attribute :>> remaining="No native-exit test or recovery admission; do not dereference a possibly freed pending node or replay a possibly executed release after unknown stop";
  }
  part nb5:NativeBoundary {
    attribute :>> id="teardown-producer"; attribute :>> source="still-sweep.inc::free_still_objs; memory-lifecycle.inc::cleanup_mem_pstate,cleanup_mem_vmstate";
    attribute :>> contract="Must close allocation/callback production before destroying synchronization and root storage; retain affine native release ownership";
    attribute :>> admission="unresolved";
    attribute :>> remaining="Same-carrier public cleanup is refused while non-RUNNING; general cross-VM/direct teardown still uses legacy lifetime rules, including VM other-processors TODO";
  }

  part nb6:NativeBoundary {
    attribute :>> id="native-run-abi";
    attribute :>> source="runtime_forwards.h.in::run_function; runtime_protocols.h.in::run import; global_state.h.in::run function pointer; setup.c::typed forward,run and two internal callers; tests/gc-root-task.c::native_run_signature";
    attribute :>> contract="Public declaration, function table, definition and caller all share the same conditional PSD signature; current explicit-PSTATE mode cannot call a one-argument declaration";
    attribute :>> admission="selected-source-native-control";
    attribute :>> remaining="Baseline declaration omitted PSD and the Darwin native call crashed before the phase guard. The canonical run_function candidate passed current-name type checks and real calls in write-authority-generation-cut. The later object-context run preserves that exact runtime identity. Unrelated target ABIs remain unqualified";
  }
  part nb7:NativeBoundary {
    attribute :>> id="write-authority";
    attribute :>> source="write_authority.c/.h; vm_state.h.in::write_authorities; setup.c::write_authority_init_vmstate; lib/include/tests Make templates; tests/write-authority.c; tests/gc-root-task.c";
    attribute :>> contract="One generation-bound write authority for eight spent/live roles; actual last use precedes release; closed-and-drained CAS transfers both owner permits. Sixty-four one-word VM records initialize before publication. The C tests share one control body and compile the real component; no compatibility aliases or second runtime namespace";
    attribute :>> admission="selected-source-native-control";
    attribute :>> remaining="Current relocated sources passed shared C controls, separate Make linking and the native Scheme suite caller. Reuse existing QNT history and Lean encoding/last-use obligations. Full generated caller, root registration, physical-stop and VM-lifetime closure remain open; the primitive alone cannot discharge native-writer-closure";
  }

  part def NativeWriter {
    attribute id:String; attribute source:String; attribute anchor:String;
    attribute writes:String; attribute consumer:String; attribute required:String;
    attribute status:String;
  }
  part nw0:NativeWriter {
    attribute :>> id="rc-chain"; attribute :>> source="vendor/gambit/lib/_mem/rc-allocation.inc"; attribute :>> anchor="___EXP_FUNC(void*,___register_rc)";
    attribute :>> writes="register_rc returns pointer or refusal before publication; context gate serializes link/unlink, refcount and scanner; free occurs after unlock; cleanup refuses live root borrows";
    attribute :>> consumer="rc-roots.inc::mark_rc follows context-owned next pointers and updates data slots; c_intf string conversions, os_io TLS/rollback and public ABI are callers";
    attribute :>> required="Before root freeze close mutation and pin borrows; registration failure retains source roots; unlink/free waits for scan and payload readers. Context owner identity must be retained because release_rc has no PSD argument";
    attribute :>> status="source-replacement";
  }
  part nw1:NativeWriter {
    attribute :>> id="rc-payload"; attribute :>> source="vendor/gambit/lib/os_dyn.c"; attribute :>> anchor="if (!___set_data_rc (c_closure, proc))";
    attribute :>> writes="set_data_rc returns status and rejects closed/wrong-owner roots; os_dyn handles refusal; Tcl registers the procedure before vector allocation and reloads it afterward; arbitrary aliases remain unadmitted";
    attribute :>> consumer="c_intf.c::make_stack_marker reads c_closure_self data; Tcl callback and delete read the same ClientData before release";
    attribute :>> required="Root registration before allocating marker, pin before payload read, acquire owner/root view and reload after GC. Callback deletion cannot free a pinned RC payload";
    attribute :>> status="source-replacement";
  }
  part nw2:NativeWriter {
    attribute :>> id="generated-entry"; attribute :>> source="vendor/gambit/include/_gambit/foreign_conversion.h.in"; attribute :>> anchor="#define ___SFUN_ARG(i,arg)";
    attribute :>> writes="SFUN_ARG writes caller stack before low-level call guard; conversion and raw SCMOBJ code can allocate, throw or reenter before entry";
    attribute :>> consumer="gsc C-interface generator, setup.c::call,run and catcher/propagate_error consumers";
    attribute :>> required="Generated permit/root plan precedes every conversion and stack write; exceptional paths release after last use, preserve roots and results, and cannot infer native stop from logical unwind";
    attribute :>> status="unresolved";
  }
  part nw3:NativeWriter {
    attribute :>> id="callback-client-data"; attribute :>> source="vendor/gambit/examples/tcltk/tcltk.scm"; attribute :>> anchor="if (!___EXT(___set_data_rc) (cd, vect))";
    attribute :>> writes="Tcl creation publishes RC ClientData; callback reads it; command deletion releases Scheme reference and RC storage";
    attribute :>> consumer="Tcl command callback and deletion callback, nested Scheme/Tcl entry and exceptional return";
    attribute :>> required="Native pin/delete arbitration before first read; source root remains held through conversion, stop/reentry and acknowledged result. External Tcl callbacks are not covered by the low-level run refusal";
    attribute :>> status="unresolved";
  }
  part nw4:NativeWriter {
    attribute :>> id="still-release"; attribute :>> source="vendor/gambit/lib/_mem/still-sweep.inc"; attribute :>> anchor="free_unmarked_still_objs";
    attribute :>> writes="Owner release callback can allocate fresh still objects; normal sweep uses VM escrow and fresh-generation merge. free_still_objs teardown retains a different legacy lifetime path";
    attribute :>> consumer="collection-round.inc::cleanup_root_domain and memory-lifecycle.inc cleanup callers";
    attribute :>> required="Known normal returns settle escrow; errors/nonlocal exits retain in-flight native identity. Close production and readers before cleanup removes RC roots or synchronization";
    attribute :>> status="partial";
  }
  part nw5:NativeWriter {
    attribute :>> id="copy-forwarding"; attribute :>> source="vendor/gambit/lib/_mem/copy-reservations.inc"; attribute :>> anchor="___gc_copy_acquire (copy_gate)";
    attribute :>> writes="mark_array source forwarding under copy gate; captured stack forwarding uses frame_gate. FIFO FORW links are transport metadata, not object forwarding";
    attribute :>> consumer="ordinary roots, continuation-roots.inc, object-scanning.inc and weak-table consumers";
    attribute :>> required="Gate covers header validation through forwarding, before space mutation. Do not acquire frame access while holding copy gate. Payload readiness and sole Tail custody remain separate from visible forwarding. Unknown stopped copier retains the round";
    attribute :>> status="source-replacement";
  }

}
