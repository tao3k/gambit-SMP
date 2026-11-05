/* A complete source replacement cut. Clauses are refinement criteria, not new
 * QNT/Lean models or proofs. Upstream facts never discharge Gambit premises. */
package GambitRootWorkerExit {
  private import ScalarValues::*;
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
}
