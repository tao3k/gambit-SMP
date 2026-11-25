// Current Darwin acceleration design. Conditional bounds, not a measured gain.
package GambitDarwinAcceleration {
  private import ScalarValues::*;
  // Ownership is not inferred from dependency failure or evidence availability.
  // Python transports these exact native API values; ASCENT decides requests.
  part executionBoundaryProofOwnership {
    attribute darwinQnt:String="Incremental dependency/readiness/invalidation and build-product delivery histories only";
    attribute darwinLean:String="Compiler emission, ABI/resource representation and source-to-model value refinement only";
    attribute modernCQntLean:String="GC, roots, scheduler, SMP and runtime ownership belong to modern-c-frame-contract; Darwin may consume separately qualified dependencies";
    attribute scopeRuleAssurance:String="Existing ASCENT ownership rules plus real declared-graph positive/negative execution; no duplicate QNT/Lean ownership decision algorithm";
  }
  part executionBoundary {
    attribute taskId:String="darwin-acceleration";
    attribute scopeId:String="darwin-package-acceleration";
    attribute ownedComponents:String="framework-boundary;darwin-process;compiler-emission;stage-products;link-plan;package-acceptance;bootstrap-admission";
    attribute externalOwners:String="gc=modern-c-frame-contract;smp=modern-c-frame-contract;runtime-storage=modern-c-frame-contract;modern-c-runtime=modern-c-frame-contract;repair=repair-9-12";
    attribute allowedCapabilities:String="sysml.project;source.contract;evidence.evaluate;quint.observe;lean.check;gerbil.build;gerbil.test";
    attribute readOnlyCapabilities:String="sysml.project;source.contract";
    // Conservative source boundary. A new runtime/header delta needs an owned
    // interface contract or an externally qualified dependency, never an alias.
    attribute mutableSourcePaths:String="gsc/*.scm;lib/_gsclib.scm;makefile.in;gsc/makefile.in;lib/makefile.in";
    attribute baselineRevision:String="f1c787a000fbb50132af79a1bdf6c7610d430c9b";
    attribute sourceDeltaReceipts:String="gsc/_t-c-1.c=ec1c878cd6b5592b3c976465b98130e54a7efc2a:2f85688d443fba82427330d4a5dff380b611042b50bf1fd32a706bccf5916cbb;gsc/_gambitgsc.c=d02a27bf26f6ddebe2618a78add97fa70bc3dc63:f875335c9ae6103864827ac00b18a5640245fc56265da7fd0db335268f95c9d7;gsc/_gsc_.c=2ea12e22481f9412517de6a8bc8002b98b619c09:e6b9dd7b9e0dd1d649aeb5b2b4358ee355130085f7bb37316c73772210cba0e3;include/gambit.h.in=1f1573a0057fda12e74c7c89d89a7d4a05130c84:3cf6e79f35716f4338212fe5cfe1eae9c7a988518f9bf7085a5f10ffdfef816c;bin/gambuild-C.unix.in=7427992472815973f3c403657fd95e5d8136709f:1765f8c04957fb666ba44aee0c4d8ea8ecf76aa83d7f3314e72a3aa5f862639a;lib/os_io.c=bc4e9f6f6d9ff0662798b0fcd2ab4bb75dac52d9:e17daf7fb752e9eb85b8b6e6e4672d81ae05435332392cff273ceaf6f5f223fa";
    attribute sourcePolicy:String="direct";
    attribute runtimeMode:String="build-concurrency";
    attribute modelOwners:String="dev/architecture/toolchain/models/=stage-products;dev/refactoring/modern-c/=modern-c-runtime;models/gambit/=repair";
  }


  part processSourceAdmission {
    attribute processSourceAdmission:String="Exact old-blob/new-byte receipts admit published Darwin spawn and literal command construction only. Neither file receives a mutable wildcard; GC/SMP and arbitrary descriptor cleanup changes remain excluded. Missing package acceptance grants no broader ownership";
  }

  part constructionCapacity {
    attribute variable:String="Official GERBIL_BUILD_CORES; no Darwin-specific worker variable or fixed construction core count";
    attribute resolution:String="Validated caller environment first, explicit profile environment second, framework available_processors last. Resolve once before native construction; retain chosen value, origin and host CPU capacity in construction-capacity.json and compiler configuration";
    attribute transport:String="Existing closed host environment preserves only validated positive decimal GERBIL_BUILD_CORES; arbitrary shell variables remain excluded. Candidate source profile omits a fixed core count";
    attribute memory:String="CPU capacity is not a memory reservation. Current automatic resolution is12 on this host and does not repair the known8GiB construction failure. No unchanged native retry, silent worker reduction or memory-safety claim follows";
    attribute packageBoundary:String="Compiler construction capacity is distinct from MCP/POO package acceptance. Both package profiles keep12 workers, aggregate8GiB and original assertions; qualification must match their actual executor capacity";
    attribute evidence:String="Installed Homebrew receipt cores3 describes its build machine and invocation, not a universal constant. Construction290b6373 used12 and stopped at8869725280 charged bytes, with all groups reconciled";
    attribute resourceAdmission:String="Isolated source6e647736 uses existing generated-object inventories for an exclusive unqualified-unit lane. Order-only Make edges avoid timestamp invalidation; root phase3 composes runtime/compiler lanes. Ordinary C retains the caller jobserver, without a fixed CPU count or compiler wrapper. GCC memory is still supervised at8GiB, not proved bounded by this classification";
    attribute controls:String="Existing gerbil.build extracts both actual source fragments, requires identical lane semantics and root composition, runs native Make positive/negative controls and checks no false invalidation or successor rebuild when a predecessor is recreated. Native GCC and complete package acceptance remain separate";
    attribute open:String="Resource admission is source-implemented and awaits complete compiler and both original package suites; no net speedup claim";
  }

  part directSourceContract {
    attribute sourceProfile:String="dev/architecture/toolchain/profiles/darwin-master-source.json";
    attribute sourcePolicy:String="direct";
    attribute gambitMaster:String="f1c787a000fbb50132af79a1bdf6c7610d430c9b";
    attribute gambitTree:String="2bc57963b7c457c6576bc81f1f20a960d74e482c";
    attribute gerbilRevision:String="1cfb032c7a1612637da6205f5f8a15683eba3ba0";
    attribute patchPolicy:String="Zero Gambit and Gerbil overlays; no bootstrap text substitution. Bazel patches are read-only design evidence, not producer inputs";
    attribute sourceAuthority:String="Clean authoritative Git commits and tracked source bytes; explicit target HEAD independent of FETCH_HEAD; verify before and after build";
    attribute migration:String="Direct Darwin refactoring commits follow an admitted unmodified baseline; no patch transplantation, GC/SMP redesign or hidden emitter rewrite";
    attribute requiredTarget:String="C23; single VM and single-threaded runtime; build GSC/GCC processes may overlap independently. No SMP/multiple-VM flags or heap/processor override";
    attribute aggregateFootprintBytes:Integer=8589934592;
    attribute acceptance:String="Complete same-source compiler first; then both MCP and POO official gerbil clean/build/original tests. Component success never implies package speedup";
    attribute qntExclusive:String="Stage readiness, invalidation, ordered publication and completion histories";
    attribute leanExclusive:String="Emission, binding/ABI and representation refinement; not scheduler histories";
    attribute ascentExclusive:String="SysML source-policy and ownership projection plus actual source/profile/evidence admission; unknown or missing results refuse acceptance";
    attribute status:String="Run a8234376: ordinary-runtime master completes Gambit from-scratch, core call/cc+GC admission and Gerbil main program; stdlib interrupted at aggregate RSS8945287168>8589934592 after2567.909057s. No complete compiler/package admission";
    attribute evidence:String="evidence/research/retained/darwin-acceleration/direct-source-admission.json";
    attribute nativeBoundary:String="Build concurrency is independent from native Scheme SMP; complete branch toolchain and both original package suites required; no memory-manager or SMP rewrite";
    attribute candidateProfile:String="dev/architecture/toolchain/profiles/darwin-direct-source.json";
    attribute sourceSeam:String="No runtime source delta admitted. Work is compiler stages, external GSC/GCC scheduling and artifact reuse. Multiple-VM helper candidate remains historical";
    attribute resourceObservation:String="One cc1 used2434121728, gerbil5938446336 and gsc477872128 bytes at refusal; not multiple concurrent GCC workers. Four registered groups later observed absent. RSS does not establish live-object retention or Darwin-specific causal excess";
    attribute memoryMetric:String="Sum of per-process resident_size; each PID once, shared pages not deduplicated, non-atomic census. 8945287168 is aggregate sampled RSS, not unique physical footprint or proof of kernel OOM. Local supervisor SIGKILL is not CI failure";
    attribute ciMemoryComparison:String="Runner physical RAM and sum-RSS are different contracts. Darwin safety admission now uses the native phys_footprint ledger with8GiB aggregate; RSS remains observation-only. The ledger is also not an exact whole-machine RAM quota. No reconstruction of historical footprint and no CI hardware-equivalence claim";
    attribute loaderEvidence:String="Historical import sample at25s:849/864 stack samples in dynamic_load/dlopen/dyld mapSegments/fcntl during1s. Treat as loader attribution clue, not849 seconds, whole-run share, exact fcntl command, or current package speedup. Exclude double counting with import/expansion intervals";
    attribute nextAdmission:String="Bound expansion-session/native-stage overlap through admitted stage products and explicit context ownership; preserve binding and macro execution identity. No GC/SMP edit, heap increase, blind worker increase or failed-run speedup denominator";
  }

  part ciResourceCorrespondence {
    attribute evidence:String="evidence/research/retained/darwin-acceleration/ci-resource-correspondence.json";
    attribute ciRun:Integer=40559766825;
    attribute workflowCommit:String="7e1ddc4aa03bdcb60727d981651bbdaf5a82ddba";
    attribute sourceComparison:String="Exact Git objects fetched read-only. Eight compiler/expander/make/build files equal across Gerbil2591dcd and1cfb032 before support changes. CI applied seven Gerbil and two Gambit support inputs; their Git-bound hashes/targets are retained. No patch applied to active Darwin source";
    attribute deliberateDifferences:String="C23 plus explicit SDK/native linker locally; ordinary runtime selected by user versus CI SMP feature; local one construction job versus CI two; active zero-overlay source versus nine CI support inputs. No equivalent-effective-source or matched-performance claim";
    attribute resourceAdmission:String="Existing Python workspace supervisor --footprint-limit-bytes8589934592; native proc_pid_rusage V0 ABI calibrated using C23 SDK compilation and live read; missing live ledger refuses. Registered group sum, birth checks and unknown-completion cleanup preserved. RSS never independently triggers this mode";
    attribute stageProducts:String="Existing build_bazel_compiler consumes configure and original ordered stages under one21600s deadline. Each terminal child and output manifest is persisted before advancing. Interrupted files are not adopted; phase ledger alone never grants automatic reuse or package readiness";
    attribute interruptionRecovery:String="The existing failed-prefix retry may account an explicitly reconciled supervisor resource kill after exact managed run/output binding, measured crossing, parent reap and fresh birth-quiescence observation. Same recipe/capability graph and unexpanded budgets plus a causal engine/input change required. Old aggregate remains INCOMPLETE; no child result is reconstructed, all old artifacts are excluded from the fresh execution";
    attribute contextRetirement:String="Source-held registry aliases and code/eval promises remain live until their future consumers close. Stage producer quiescence can retire a process-owned context only after complete products; do not clear code/e merely from emitted C existence. Full per-module/session retirement is still open";
    attribute qntExclusive:String="Stage readiness, producer quiescence, output publication and invalidation histories; native mapping/refinement remains an obligation";
    attribute leanExclusive:String="Binding identity, macro initialization, generated Scheme/C and link-result equivalence; not timing or physical-memory accounting";
    attribute acceptance:String="Resource contract tests and stage protocol checks do not qualify a compiler. Full branch compiler then MCP AND POO clean/build/original tests; no PR, no speedup until matched package evidence";
  }

  // Historical EA-pinned cohort. Active source is masterBootstrapContract below.
  part bazelSourceReference {
    attribute sourceProfile:String="dev/architecture/toolchain/profiles/darwin-ci-source.json";
    attribute sourceProducer:String="Existing gerbil.build bazel-ci -> build_bazel_compiler; no parallel runner";
    attribute gambitUpstream:String="ea114fc3d2f120abbe20393c1f9aeafdd3f8c89f";
    attribute baselineCommit:String="f96c32deb121d1e32f39e5f25378230cdbd358e7";
    attribute baselineTree:String="087ab266090cdc11c97709960f54c5da71eff795";
    attribute gerbilRevision:String="1cfb032c7a1612637da6205f5f8a15683eba3ba0";
    attribute sourceClosure:String="Published baseline support includes added files; exact tree required before native construction; old mixed tree excluded";
    attribute inheritedSupport:String="Existing GCC/spawn/literal substitution/AOT/streaming/native reuse and global-capacity/setup support are immutable baseline dependencies; zero new acceleration credit";
    attribute allThreeRequired:Boolean=true;
    attribute aggregateRssBytes:Integer=8589934592;
    attribute constructionSeconds:Integer=21600;
    attribute wholeGraphSeconds:Integer=24000;
    attribute packageSequence:String="Both MCP and POO: official gerbil clean/build/original tests; clean30/build300/test300";
    attribute actualReferenceStatus:String="DENY: build_gambit -> make bootstrap/from-scratch -> gsc-boot Heap overflow;161.388927s; no timeout; group quiescent; all three configured flags observed";
    attribute externalBlocker:String="All-three self-bootstrap qualification remains external; failure does not grant Darwin authority to change GC/SMP or borrow mixed runtime";
    attribute candidateIntegration:String="OPEN: stage products and ordered LinkPlan library must be integrated and qualified on this exact cohort; historical native receipts do not transfer";
    attribute netBenefit:String="UNMEASURED: no complete package reference/candidate pair; cold and warm separate; at least2x requires net eliminated critical-path work >= half matched reference";
    attribute qntExclusive:String="Readiness, invalidation, ordered product publication, duplicate/late completion and unknown-result custody; no GC model here";
    attribute leanExclusive:String="SCM/C semantic refinement, binding/ABI preservation and ordered link-metadata equivalence; not scheduling histories or elapsed speed";
    attribute ascentExclusive:String="Join model ownership, source/profile/tool identities, negative controls, native evidence and existing-support deductions; missing evidence refuses package admission";
  }


  part bootstrapIdentityAudit {
    attribute evidence:String="evidence/research/retained/darwin-acceleration/bootstrap-identity-audit.json";
    attribute ciIdentity:String="Success40559766825: Gerbil2591dcd + Gambitdcd677c; explicit SMP, absent multiple-vms and multiple-threaded-vms options; CI configured header/native hashes unavailable";
    attribute localIdentity:String="Failed reference: Gerbil1cfb032 + Gambitea114fc with published support; all3 configured flags observed; C23/GCC16.2.0";
    attribute generatedC:String="52 initial seed C Git blobs equal across dcd677c and ea114fc. This does not prove equal post-bootstrap C, headers, native objects or ABI";
    attribute headerDifference:String="Upstream native header adds stack-overflow undo invalidation at thread save/restore and continuation operations. Its causal role remains unresolved; no header edit performed";
    attribute compilerDifference:String="Both observed GCC16.2.0 version; current explicit -std=c23/sysroot/-B versus CI flags. Equal executable bytes and effective SDK not established";
    attribute sharedDiagnostic:String="PKG_PROG_PKG_CONFIG warning appears in successful CI too; not a sufficient explanation of different outcomes";
    attribute actualBootstrap:String="SHA1ab7ad4b4a75047d73ecf08d0606a3f758e409531af18875608312fb138f6dd4: version exits70 in0.112657s; empty-source entry exits70 in0.098491s; both Heap overflow, no user marker, reaped/quiescent";
    attribute actualFatalStack:String="Same SHA fatal breakpoint: current_vm_resize -> vm_resize_pstate -> setup_pstate -> setup_mem_pstate+568 -> fatal_error. Initial processor stack/heap section setup implicated; exact inlined branch and counters unresolved";
    attribute debuggerBoundary:String="Single fixed10s LLDB target launch completed0.755798s; target intentionally killed at breakpoint; observed stack only, not natural target exit or timing/semantic acceptance. Missing-tool preflight preserved; actual tool resolved by xcrun";
    attribute entryContract:String="main.c chooses1 for single-threaded VM, otherwise ceil(cpuCount*50/100); _repl startup-parallelism -> _thread current-vm-resize. Exact failure site/unique cause unresolved; no GC/SMP rewrite authority";
    attribute resourceContract:String="Existing gerbil.build observation role only; declared retained evidence hash, exact heads, same-task custody, bootstrap/header/profile hashes; two fixed10s commands; aggregate8GiB; no p1/heap/worker override or rebuild";
    attribute modelBoundary:String="No new QNT/Lean runtime proof. ASCENT consumes identity/refusal evidence; QNT owns future stage-product histories; Lean owns future emission/ABI/link semantic refinement";
    attribute productAdmission:String="SourceBootstrapReady=false: do not publish LibraryReadiness, adopt cross-profile C/native products or execute LinkPlan/package consumers. Failed build time and unrelated CI4133s are not speedup denominators";
    attribute nextAdmission:String="A separately qualified all3 default-entry bootstrap is required before stage-product/LinkPlan native integration and both original package sequences";
  }


  part bootstrapSectionAdmission {
    attribute evidence:String="evidence/research/retained/darwin-acceleration/bootstrap-section-admission.json";
    attribute provenance:String="Original source ancestry was master; pinned reference later changed to ea114fc plus published support. Cached candidate db843499 is a child of f96c32de, not modern-c; no silent baseline switch";
    attribute currentGithub:String="Latest verified Bazel success41020777718 uses published2591dcd archive c53d62f26ff382f8956576963edc3eb9193098dc48de78d44b8a3df63636bd18; it is not local all3 source bootstrap";
    attribute upstreamPath:String="main.c, setup.c and mem.c initial VM-resize implementations have equal Git blobs in origin/master f1c787 and ea114fc before published support. VM startup resize was not introduced by Darwin refactoring";
    attribute observedState:String="Same-SHA fatal snapshot: initial1,target6,initializing processor3,committed count1; physical sections6,assigned6,stacks3; next pointer0; new processor stack/heap both0";
    attribute exactBranch:String="setup_mem_pstate return+568 maps to inlined next_stack_msection exhaustion; next_heap_msection call+248 has not executed; shared stack/heap-space fatal would return+608 instead";
    attribute violatedContract:String="Existing lower_bound_nb_sections=2*target=12 is computed, but SET_MAX(target_nb_sections,lower_bound) was guarded by max_heap>0. Default max_heap0 therefore allowed6 sections for target6 processors";
    attribute repair:String="Move the existing SET_MAX outside the optional maximum-heap branch; retain SET_MIN inside it. No heap option/constant increase, GC algorithm/root/worker redesign, scheduling policy or p1 override";
    attribute historicalSourceScope:String="Historical only, no active authorization: lib/mem.c old blob d9c4e5c043b8da7a6fb1b3d0aa56c82f0e5512f5 to SHA2564b798600757a3962c7b800330b0ef0680eeb670c9ef23b1514fe339799a12196 is admitted. Any additional byte edit is denied by sourceDeltaReceipts";
    attribute algebra:String="Bounded mode remains min(max(T,L),U); unbounded mode changes T to max(T,L). This restores an existing requirement, not proof of general GC/SMP correctness";
    attribute constructionResourceAdmission:String="First attempt interrupted at aggregate8590032896>8589934592 bytes: two cc1 used4264656896+4158521344. Explicit drained/quiescent prefix retained. Same-engine continuation changes only Make construction workers2->1; Scheme VM processor policy remains default6. This is low-memory qualification, not an acceleration mechanism or proof of all single-job bounds";
    attribute qualification:String="PARTIAL ONLY: source db843499 advances beyond old processor3 setup to six OS threads; complete build fails204.606583s in GC-copy path. Candidate default version/empty entry also fail70; no compiler or package admission";
    attribute remainingDependency:String="Observed candidate fatal_error <- mark_array+760 <- scan <- mark_reachable_from_marked <- garbage_collect_pstate, with five other native threads marking/scanning. No further GC algorithm/worker/section-constant edit admitted; initial clamp fix is not a whole-runtime proof";
    attribute benefit:String="Zero acceleration credit for prerequisite correctness. Failed reference and unrelated CI cannot supply a package speedup denominator. Stage-product/LinkPlan reuse follows qualified bootstrap";
    attribute proofRouting:String="ASCENT scope/identity/receipt gates; Lean scalar-clamp/source refinement obligation; QNT later readiness/delivery histories. No imported GC/SMP model or claim";
  }

  enum def ModuleReadState { Unread; Reading; Ready; Transferred; Failed; }
  part def ModuleReadProduct {
    attribute sourceOwner:String;
    attribute readerModuleIdentity:String;
    attribute readerNamespace:String;
    attribute interfaceAliasesShareSourceOwner:Boolean;
    attribute aliasPrecedesRegistryCache:Boolean;
    attribute readState:ModuleReadState;
    attribute directReadBodyHeld:Boolean;
    attribute directReaderContextHeld:Boolean;
    attribute pathAnchorAtTransfer:Boolean;
    attribute idAnchorAtTransfer:Boolean;
    attribute compilerCodeHeld:Boolean;
    attribute deferredEvaluationHeld:Boolean;
  }
  requirement def ModuleReadTransferLaw {
    subject product:ModuleReadProduct;
    require constraint { product.readState != ModuleReadState::Transferred or
      (product.pathAnchorAtTransfer and product.idAnchorAtTransfer and
       not product.directReadBodyHeld and not product.directReaderContextHeld) }
  }
  part def ModuleReadAdmission {
    attribute planningReported:Boolean;
    attribute planningReads:Integer;
    attribute directPlanningBodies:Integer;
    attribute nativeConsumerRequested:Boolean;
    attribute producerExited:Boolean;
    attribute parentReaped:Boolean;
    attribute groupQuiescent:Boolean;
    attribute completePlan:Boolean;
    attribute reportsAccepted:Boolean;
  }
  requirement def ModuleReadPlanningLaw {
    subject witness:ModuleReadAdmission;
    require constraint { not witness.planningReported or
      (witness.planningReads == 0 and witness.directPlanningBodies == 0) }
  }
  requirement def ModuleReadConsumerLaw {
    subject witness:ModuleReadAdmission;
    require constraint { not witness.nativeConsumerRequested or
      (witness.producerExited and witness.parentReaped and witness.groupQuiescent and
       witness.completePlan and witness.reportsAccepted) }
  }
  enum def ExpansionSessionPhase { Planned; Active; Sealed; Drained; Retired; }
  part def ExpansionSession {
    attribute sessionPhase:ExpansionSessionPhase;
    attribute aggregateBudgetBytes:Integer;
    attribute separateProducerBudget:Boolean;
    attribute producerSucceeded:Boolean;
    attribute producerReaped:Boolean;
    attribute producerGroupQuiescent:Boolean;
    attribute productsValidated:Boolean;
    attribute nativeRequested:Boolean;
  }
  requirement def ExpansionSessionBudgetLaw {
    subject session:ExpansionSession;
    require constraint { session.aggregateBudgetBytes == 8589934592 and
      not session.separateProducerBudget }
  }
  requirement def ExpansionSessionHandoffLaw {
    subject session:ExpansionSession;
    require constraint { not session.nativeRequested or
      (session.sessionPhase == ExpansionSessionPhase::Retired and
       session.producerSucceeded and session.producerReaped and
       session.producerGroupQuiescent and session.productsValidated) }
  }
  part def StableIterationView {
    attribute copiedSlots:Integer;
    attribute bucketCapacity:Integer;
    attribute strongRootHeld:Boolean;
    attribute copyHasSafepoint:Boolean;
    attribute callbackStarted:Boolean;
    attribute originalBucketsRetainedAsCursor:Boolean;
  }
  requirement def StableIterationLaw {
    subject view:StableIterationView;
    require constraint { not view.callbackStarted or
      (view.strongRootHeld and not view.copyHasSafepoint and
       not view.originalBucketsRetainedAsCursor and
       view.copiedSlots == 2 * view.bucketCapacity) }
  }
  part stableHashIteration {
    attribute sourceChain:String="lib/_system.scm gc-hash-table-for-each/search/foldl retain bucket indices across callbacks; table->list allocates in fold. mem.c eager SMP rehash moves buckets during callback GC. _t-c-1.scm targ-heap-dump sorts table->list, sets each cell index and emits DEF_SYM; REF_SYM uses original table lookup. Duplicate visits duplicate macros; skipped cells remain false and targ-code emits a blank index";
    attribute implementation:String="Private gc-hash-table-entry-snapshot allocates a strong vector before callbacks; nonallocating C memmove decodes WEAK and VECTOR bodies with their distinct tags. All three iterators use the owned snapshot. No rehash-policy change, disabled GC, heap increase or shared pin flag";
    attribute componentReceipt:String="2272fdf032be44bdb79eb979933cdd58: same-profile48-case fixture, old runtime30 bad cases, candidate0; unchanged original table lookups pass. Interned/uninterned/keyword, callback collection positions and rooted weak-key cases. Forced GC is a diagnostic control, not package performance evidence";
    attribute rejectedCandidates:String="c4e1bc0e8c9e48b5b90bd0fae379f980: unchecked vector copy decoded WEAK as VECTOR and failed even no-GC control.4b6aa013346642b496c90d5718ce01e6: typed copy lacked string.h and C23 compilation refused it. Both failures retained; successful2272 requires typed copy plus declaration";
    attribute bounds:String="Two strong vector slots per bucket, O(capacity) copy and temporary roots. Early-return search now pays upfront O(capacity). Snapshot lifetime follows callback/continuation reachability; it is not a bounded whole-module context cache. Weak retention timing, concurrent table mutation and future generational write barriers need independent admission";
    attribute forensicGap:String="Original55a2 failing C was deleted by old GSC and remains missing. The controlled mechanism explains matching duplicate/blank-index symptoms; no original GC point was captured and no original bad-C reconstruction is claimed";
    attribute failedCContract:String="_gsclib.scm deletes temporary C only after successful native compilation. Failure keeps actual C with unchanged error result. Shared executor archives it only after parent reap/group quiescence, checks source/hash, distinguishes preexisting C and rejects symlink/hardlink or shared intermediate writers. Retained bytes do not prove complete emission or native product success";
    attribute retentionControl:String="2272: successful native compile removes temporary C; injected GCC error without keep-temp retains actual C hash6e0bf46690cc882987d26d283110194712832d1bbb89ea0bc6f011fa738b2aee. This injected failure is not the original std/test/base witness";
    attribute currentCohort:String="8294:stage1 exit0 in507.715782792s; source producer exit0 in190.50889725000025s,334/314/20/668 ownership join and912 native requests. Actual regenerated std/test/base member168 exits0.273 successful native members plus one compiler error observed; full library not admitted.12-worker trial then refused aggregate RSS8725184512 above8589934592; parent reaped and cleanup unresolved empty";
    attribute nativeDependencyGap:String="Actual member272 libcrypto failed70: openssl/rand.h missing. Failed C retained fresh with stable source, SHA256eb7159dae7520a85ffb10e01f21cb23e14620a89033ac10e17189554df4306b0. std/make shell-config pkg-config failed and cppflags fell back to empty; metadata PATH was not configured.841cb9823a034953aa0e49f462fdf5c0 validates original failures and explicit OpenSSL/zlib/sqlite pc closure; this is dependency configuration, not a speedup";
    attribute nativeMemoryGap:String="At refusal, three cc1 RSS observations sum7585251328 bytes and their retained GSC contexts sum938344448, plus observer/linker processes. A retired Gerbil source session does not retire per-request GSC heaps.12 workers are withdrawn; no arbitrary per-job memory upper bound is inferred";
    attribute continuedCohort:String="a9ff:resolved dependencies revalidated; passed bootstrap proofs reused; source producer exit0 in85.35983570900044s,334-product/668-alias/912-request join. Native workers2:280 zero-exit observations including libcrypto member239, no compiler error before aggregate refusal8713388032 bytes. Parent reaped, groups recovered and unresolved empty; full library and both packages unqualified";
    attribute singleRequestBlocker:String="Spawn request/birth registry matches socket interface member255 to pgid71100 and cc1 pid71153: observed RSS8048164864 bytes. Actual SCM1838064 bytes and C12540179 bytes,8502 labels,111 procedure bodies,1 module body. Retained actual C hashb60b2d304a821d721a0fa5421a65a1f6ec3513567246e06937bdcb55398a5f66;5690 unique symbol macros,zero blank symbol indices. This is an interrupted request, not a GCC error return or native product";
    attribute effectiveNativePolicy:String="Actual installed gambuild-C and gambit.h match runtime hashes; no CORCXXFLAGS_GAMBUILD or LDFLAGS_GAMBUILD override. GCC16 generatedO1 and ftrack-macro-expansion=0 retained; SINGLE_HOST set and SINGLE_HOST_LIMIT0. configure.ac explicitly warns single-host increases compilation time/memory. No unique GCC-pass attribution or Linux/Darwin differential is proved";
    attribute nextWorkBoundary:String="No further whole-library retry on worker-count tuning. First close source-grounded GVM host partition and GeneratedCResult native consumer contracts, including same module/link identity, return labels, root/frame mapping and tail transfers. Isolating retained C is diagnostic only, never repair acceptance; no flag-only profile workaround earns refactor credit";
    attribute qntExclusive:String="Refine existing stage_context_handoff to copy-before-callback ownership, captured view retention, failed-member drain and retained-C custody. Temporal transitions remain source-refinement obligations, not new claimed theorems";
    attribute leanExclusive:String="Entry multiset/bijection from table to strong view, tag-correct address decoding, cell-index totality, exact once emission and allocation bounds. Callback mutation semantics and weak-view equivalence are explicit assumptions or open obligations, not QNT duplicate state exploration";
    attribute ascentExclusive:String="Join source/binary/profile hashes, old negative and corrected fixture, actual full compiler terminal outputs and both packages; reject standalone compile as repair, missing original C as captured evidence, and component success as acceleration";
    attribute stage1Receipt:String="8294:185 stage0 modules complete; new-source stage1 exit0 in507.715782792s, parent reaped/group quiescent; real reader/promise/alias/failure controls pass. Full stdlib/tools and package acceptance remain separate gates";
    attribute completeCompilerPassed:Boolean=false;
    attribute packagesPassed:Boolean=false;
    attribute measuredPackageGain:Boolean=false;
  }
  part def GvmHostPlan {
    attribute procedureCount:Integer;
    attribute hostCount:Integer;
    attribute totalLabels:Integer;
    attribute maxHostLabels:Integer;
    attribute maxHostCodeSlots:Integer;
    attribute mergesDistinctProcedures:Boolean;
    attribute matchingHeaderRequired:Boolean;
    attribute frameDescriptorsRewritten:Boolean;
    attribute moduleBindingIdsRewritten:Boolean;
  }
  requirement def GvmHostAggregationLaw {
    subject plan:GvmHostPlan;
    require constraint { plan.hostCount == plan.procedureCount and
      not plan.mergesDistinctProcedures and plan.matchingHeaderRequired and
      not plan.frameDescriptorsRewritten and not plan.moduleBindingIdsRewritten and
      plan.maxHostLabels <= plan.totalLabels }
  }
  part gvmHostPartition {
    attribute bootstrapClosure:String="Ship source-regenerated gsc/_t-c-1.c together with original-Make gsc/_gambitgsc.c and gsc/_gsc_.c. CI may use dummy gsc-boot with pre-generated C; timestamps do not authorize stale linker symbol tables. Run123de6ab retains the missing-closure link failure. All three current products are the exact coherent native component inputs";
    attribute currentSourceReceipt:String="Current master-derived isolated commit843684064e0fc48e87498942e056a7508c76ba0f; runf6d4a267 passes socket C219084-line correspondence (excluding debug directives and declared host guard), native object, header negatives, tail50000, GC/map roots and multi-shot continuation controls. Full compiler and packages remain independent gates";
    attribute sourceEntry:String="Official igsc normalizes the SRFI-193 command-line view and uses the bound source GSI. Bootstrap C is source regenerated; original Make rebuilds a coherent compiler initialization. Partial native backend hot-loading is rejected because primitive identity closures do not match";
    attribute implementation:String="Cached gsc/_t-c-1.scm targ-make-host-plan records each original GVM procedure, all label nodes and code-vector slots before emission. targ-dump-cod rechecks procedure identity and counts. Emitted GVM_HOST_LAYOUT/COUNT/MAX_LABELS/MAX_CODE_SLOTS/TOTAL_LABELS select the existing per-procedure host ABI in matching gambit.h; unsupported or old headers refuse planned products";
    attribute preservedConsumers:String="Original ordered prc-list and global label numbers; DEF_LBL_INTRO/PROC/RET, IFD/OFD and gc-map values unchanged. Same module descriptor/linker binding and constant tables. Existing per-procedure read/write resource sets and JUMPINT/JUMPRET/trampoline paths replace only cross-procedure aggregation; no continuation representation or collector change";
    attribute bound:String="A native optimizer host contains exactly one original GVM procedure. Its labels/code slots are bounded by that procedure, independent of total module size. This is an aggregation bound, not a fixed RSS bound or a split of an arbitrarily large procedure. The C translation unit and common header remain module-wide";
    attribute sourceReceipt:String="0ec932b65978454390d277e8e34ae9e2: source reads before/after pass; target emitter and header template/configured header edited together. No configure threshold, heap, optimization flag or package input change";
    attribute bootstrapBoundary:String="5d4e3604985c44498e3236dc8c14e9b2: initial core rebuild with legacy boot compiler had two cc1 observations4.24/4.13GB and aggregate refusal8619786240; groups recovered. New layout not yet qualified by that attempt. Existing regenerate_module now optionally invokes in-tree igsc with explicit processor capacity and loaded-source closure binding; no independent runner";
    attribute candidate:String="654834c7ef7748b685def4e071ad8638: use the existing interpreted source compiler to regenerate target backend itself, then source-built native compiler, retained real socket input and compiled cross-module/GC/multi-shot continuation/tail controls. Three feature switches and aggregate8GiB retained. Full compiler and both packages still independent gates";
    attribute qntExclusive:String="Existing stage_context_handoff/native_artifact_partition own source generator completion, sealed C publication, native consumer acquisition and failure/unknown custody. No parallel QNT model of value-level host equivalence";
    attribute leanExclusive:String="Procedure-to-host bijection, unchanged label/frame/root and module-binding values, cross-host tail/return simulation and max-per-procedure aggregation law. Current source and native checks are evidence; no new Lean theorem claimed";
    attribute ascentExclusive:String="Join exact emitter/header/SCM/C/compiler identities, header negatives, actual socket structural and native observations, full-prefix exit and both original package sequences; failed old socket cannot serve as a completed timing denominator";
    attribute nativeReceipt:String="9dd5c89119f745ddaece105a4eac6ea1: planned socket C reused, public compile-file C-input API creates actual o1 in20.478630333999718s. Aggregate component peak1763655680 bytes, parent reaped/groups quiescent. Cross-module call/tail50000, non-tail GC return, map roots and multi-shot continuation controls pass. Counts111 hosts/max2894 labels/max34296 code slots/total10268 label nodes; global LBLCOUNT8502 is a different metric";
    attribute bodyWitness:String="Full suffix after gambit.h:212123 lines equal after excluding C debug #line and new matching-header guard; candidate SHA b428802db47c3f4debf191f3905d1f5f2fab3773bd842680164c803d9983a959 versus retained old C b60b2d304a821d721a0fa5421a65a1f6ec3513567246e06937bdcb55398a5f66. This is one actual input witness, not a general semantic theorem";
    attribute realCConsumer:String="654834:source compiler generation and native core pass; a CLI dyn C input returned0 without product and was rejected. main.scm target-file branch skips dyn; use existing compile-file API in gsclib for actual C consumption. No exit-zero-only admission";
    attribute fullCohort:String="dcec9de1428045ae80716b9a70302693:185 stage0 modules; stage1 exit0 in387.9796288329999s; stdlib source exit0 in97.51452429100027s.739/912 native products complete,737/740 time out at original600-second whole-stage deadline. Failed C retained; parent reaped and cleanup unresolved empty. Full compiler and MCP/POO not passed, not run. No twofold gain admitted";
    attribute sourceMemoryAttribution:String="Current aggregate peak8211365888 bytes comprises gerbil pid83722 rss8033042432, Python174211072 and two shells4112384. Source producer pgid83714; no GCC at this high-water sample. groups_memory uses a PID set and kernel-birth checked resident_size; shared pages may be counted across processes but no duplicated PID explains this single large gerbil";
    attribute sourceRetentionGap:String="std/make creates one coordinator per spec and imports a full module before dependency wait; worker count2 does not bound imported context count. expander/module.ss registers ctx by path/id, code and delay-atomic evaluator retain body. Initially these share one body, not two copies; optimizer may replace code while promise retains the original. New read products clear direct slots only; process exit is not a peak-live-context bound";
    attribute attributionUnknown:String="RSS is not GC live bytes or a heap dominator census. Current live bytes by owner and a matched pre-refactor memory baseline are missing. Do not assign all7.48GiB to AST, copying GC, HostPlan, or a measured regression without those receipts";
    attribute sourceSessionBounded:Boolean=false;
    attribute continuationOfWork:String="First restore ciConstructionReference producer-equivalent baseline; no further hand-staged full-library retry or concurrency/heap/GC tuning. Source-session ownership and phase-readiness concerns remain hypotheses until same-path/profile memory comparison.739 successes remain partial experimental products, not a repaired cold-stage deadline or a failed normal CI baseline";
    attribute componentPassed:Boolean=true;
    attribute fullCompilerPassed:Boolean=false;
    attribute packagesPassed:Boolean=false;
    attribute measuredSpeedup:Boolean=false;
  }
  part def CiConstructionContract {
    attribute ciProducerOwnsStages:Boolean;
    attribute dependenciesBound:Boolean;
    attribute declaredCapacityHonored:Boolean;
    attribute multipleThreadedVms:Boolean;
    attribute multipleVms:Boolean;
    attribute smp:Boolean;
    attribute experimentalWholeSourceBarrier:Boolean;
    attribute installVerified:Boolean;
    attribute baselineAccepted:Boolean;
  }
  requirement def CiConstructionAdmissionLaw {
    subject construction:CiConstructionContract;
    require constraint { not construction.baselineAccepted or
      (construction.ciProducerOwnsStages and construction.dependenciesBound and
       construction.declaredCapacityHonored and construction.multipleThreadedVms and
       construction.multipleVms and construction.smp and
       not construction.experimentalWholeSourceBarrier and construction.installVerified) }
  }
  part ciConstructionReference {
    attribute source:String="GitHub tao3k/gerbil-bazel run40559766825, Darwin job122385493993, head7e1ddc4aa03bdcb60727d981651bbdaf5a82ddba. Build exact v0.19 toolchain executed successfully in4133s; not a cache-skipped build. Raw log/pinned workflow retained by6a008a25f9834b279bc79b1c5f2b7bd3";
    attribute actualStageSeconds:String="2 cores: prepare0,gambit532,boot-gxi1,stage0310,stage1398,stdlib2304,libgerbil487,lang3,tools17. Whole build step includes configure/other work. Runner total RAM and peak RSS were not observed";
    attribute budgetCorrection:String="The experiment's600-second stdlib envelope is not the successful CI construction contract: reference stdlib alone takes2304s. Earlier timeout proves failure of that experiment under its cap, not that normal Bazel construction is broken. Do not silently extend/relabel the same failed cohort";
    attribute executionOwner:String="Reuse existing gambit_smp.gerbil_build.build_bazel_compiler -> tools/ci/build_source_toolchain.sh prepare/build/verify. Producer owns upstream prepare/gambit/boot-gxi/stage0/stage1/stdlib/libgerbil/lang/tools/install. Python owns exact source materialization, configured profile/dependencies, aggregate8GiB supervision and receipts";
    attribute capacityCorrection:String="Existing source producer now honors explicit GERBIL_BUILD_CORES before host detection; default remains host-derived. Capacity remains recorded in the producer receipt; Python construction configuration records capacity and PKG_CONFIG_PATH/LIBDIR/SYSROOT_DIR. No silently overwritten2->12 worker request";
    attribute experimentalBoundary:String="build_owned_compiler is experimental-staged and returns ciBaselineEquivalent=false. Its whole-source retirement barrier, per-stage600 cap and captured native queue cannot serve as CI-equivalent baseline without separate equivalence evidence. Retain all failures as experimental observations";
    attribute profileBoundary:String="Successful published CI is a reference recipe, not automatically the current local C23/three-flag profile. Pin original workflow/source/compiler/dependencies, record differences, and verify all three required flags in the local producer. Never disable a required feature to imitate a different CI profile";
    attribute smpConfigurationAuthority:String="SMP Scheme compilation is selected by the active PRELUDE_OPT assignment in configured lib/Makefile, not include/config.h. Threaded-VM and multi-VM selections remain configured include/gambit.h macros. Bind and recheck both actual consumers; a commented feature or unrelated variable cannot authorize SMP";
    attribute sourcePublication:String="Source admission38ad57a8c6a94ca7849963e1f1bbde16 binds independent Gerbil1cfb032c7a1612637da6205f5f8a15683eba3ba0 and46 fresh generated C modules to their Scheme inputs and qualified generator9dd5c89119f745ddaece105a4eac6ea1. It admits source inputs, not a newly built native target or package";
    attribute localConstructionAttempt:String="258d01bf85384c228ac7bd7eb9eefb89 uses build_bazel_compiler and existing CI prepare/build/verify; fixed build21600s, whole task24000s, aggregate8589934592 bytes, declared2 jobs. Package clean/build/test budgets30/300/300 each. CI clears GAMBOPT; multithreaded CLI default half CPUs is distinct from Make job capacity. No matched speedup until compiler and both original package gates pass";
    attribute nextAdmission:String="Restore producer-equivalent construction before further memory-driven architectural changes. No complete build rerun in this audit; same8GiB aggregate and both official package clean/build/original test gates remain mandatory. Historical CI duration is not local acceleration";
    attribute localCiConstructionPassed:Boolean=false;
    attribute localConstructionFailure:String="Attempt258d01bf85384c228ac7bd7eb9eefb89: prepare1.260s PASS; build109.327s exit1, no timeout; group reaped/quiescent; aggregate peak2360754176 bytes. Gambit from-scratch gsc-boot reports Heap overflow before full tools. All three generated feature checks PASS. Packages NOT RUN; no speedup denominator";
    attribute defaultStartupDifferential:String="Diagnosticb41b628f49f94f299e3e49185092a14f: both seed and newly built gsc-boot fail default startup exit70 in about0.1s; both p1-only diagnostic controls pass. This narrows failure before Scheme compilation; it does not admit p1 as final profile or prove GC generally correct";
    attribute capacityFloorObligation:String="In lib/mem.c resize_heap, the already computed target processor/stack lower_bound_nb_sections must constrain the uncapped target too. Existing source applies SET_MAX only inside max_heap>0. Isolated candidate moves that existing bound before the cap branch, preserves SET_MIN for explicit caps and changes no capacity constant. Native default/six-processor GC admission still required before complete CI retry";
    attribute ciHostToolClosure:String="Published Darwin workflow prepends Homebrew bin plus system bin/sbin to PATH. Initial local inherited environment selected Nix make/pkg-config/as/ld. Bind tool paths and normalize to the existing CI order before claiming producer-equivalent construction; do not compare durations across these environments as speedup";
    attribute capacityCandidateRefused:String="Candidatec41b243191ce4529a184fd3ece1cada1 builds core2.903s after old-bootstrap-only p1; parameter removed before target test. Default target still exits70; candidate NOT admitted. No full CI retry. Diagnostic68314f49bf3443efa908652edd53f410 reaches next_msection_without_locking exhaustion: processor1,current6,target6,sections12,assigned12,stack sections6,GC count3817. Counters support capacity/progress investigation, not a generic GC proof or package speedup. Diagnostic source instrumentation removed; rebuilt diagnostic binaries are not admitted tools";
    attribute currentMemoryRegressionProved:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
  }
  part gcAllocationProgress {
    attribute ownerTask:String="modern-c-frame-contract";
    attribute externalEvidenceOnly:Boolean=true;
    attribute sourceRoles:String="Current isolated Darwin lib/mem.c: resize_heap / compute_free_heap_space_approximately / next_msection_without_locking / mark_array / scan_complete_heap_chunk; include/gambit.h.in and configured gambit.h: TICKETLOCK_LOCK2, TRYLOCK2 and LOAD_ACQUIRE_WORD. CI input inventory binds the actual source bytes; diagnostic binaries are never construction inputs";
    attribute capacityContract:String="Member minimum alone is insufficient. Sections must cover max(member/live lower bound, assigned sections plus pending processor setup) plus ceil(normal overflow reserve / section words) plus the existing one-section allocation quantum. Apply lower bound for uncapped heaps too. Check addition ranges and refuse an explicit cap below the bound through the existing overflow path; no section constant or heap option increase";
    attribute uniqueWorkContract:String="Each complete chunk is dequeued at most once per GC phase. Waiting for a ticket must perform an atomic acquire read of current_ticket before any protected queue observation. Existing atomic RMW unlock supplies release. Volatile polling is not that contract; never repair repeated scanning by silently skipping an already-mutated field";
    attribute leanExclusiveObligation:String="dev/refactoring/modern-c/models/lean/CollectorCapacity.lean Gambit.CollectorCapacity: numeric counterexample to membership-only capacity; assigned_and_future_reserve_fit proves value arithmetic under explicit reserve coverage. It does not prove synchronization, actual peak RSS, native copying capacity or compiler/package acceptance";
    attribute qntExclusiveObligation:String="dev/refactoring/modern-c/models/quint/collector_ticket_claim.qnt: first claim, release, waiting/acquire-read and second claim. Preserve stale protected-read counterexample [0,0]; acquire refresh produces [0,1]. It does not prove arithmetic bounds, AArch64 LDAR emission or a complete C memory-model refinement";
    attribute nativeNegativeEvidence:String="f540a036: 12 assigned of12 sections, freeApprox=-204808, repeated GC.655e0182: same vector scanned by processors5 and0 in strong phase.65c8d6e: same completed chunk dequeued twice in one phase.1aa17ed6/eaea184a: existing validate_old_obj source-space rule detects re-marking tospace, strong phase. These are current local source witnesses, not package timings";
    attribute nativePositiveEvidence:String="7987c009: 17 uninstrumented cases, each100 allocation/GC rounds:12 default six-processor launches plus2,4,6,8,12 processors.42d977f5:8 cases repeat prior failing chunk/vector/source-space observers without a violation; source instrumentation removed.27 command receipts across both runs are observed, parent-reaped and group-quiescent. These admit local GC regression scope only";
    attribute retainedGap:String="8361e372 old and acquire 12-thread/1200000-operation ticket pressure kernels both hit40s. Neither is a passing primitive performance or fairness result. No budget/workload adjustment, no general termination proof, no inference of2x package speedup";
    attribute constructionGate:String="77ba14e66efd4ab596d429766acdd369 resumes existing CI source producer only after local default-profile/scan admission. C23, all3 VM/SMP flags, CI tool PATH,21600s construction,24000s task,8GiB aggregate. Complete installation/verify and both original package clean/build/tests remain required. Existing ASCENT native/compiler/package gates remain independent from QNT/Lean observations";
    attribute localGcRegressionAdmitted:Boolean=true;
    attribute wholeCompilerAdmitted:Boolean=false;
    attribute bothPackagesAdmitted:Boolean=false;
    attribute wholePackageSpeedupMeasured:Boolean=false;
  }
  part stableGlobalStorage {
    attribute ownerTask:String="modern-c-frame-contract";
    attribute externalEvidenceOnly:Boolean=true;
    attribute sourceRoles:String="Current isolated lib/mem.c ensure_glo_segment / glo_list_add / alloc_mem_aligned_perm; mem.h result declaration; gambit.h.in global-cell access and stable segment directory; setup.c initial globals, fixups and VM setup failure propagation. No generated Scheme/GVM semantic change; native objects must be rebuilt for the global-cell access contract";
    attribute priorFailure:String="77ba14e6 passes Gambit, boot-gxi, stage0 and stage1, then stdlib SIGBUS at obj_to_global_var. Build956.783s exit1, not timeout; peak5722112000 bytes (5.329GiB); groups reaped/quiescent.1053d2b2 matches crash PID62168 and UUID6cd14ee1-4f85-32f4-aa17-cdcc31facfc7 to actual stage1 executable. Existing CI global fixture fails at new-variable7767; the local source still allocated20000 flat slots";
    attribute integrationContract:String="Absorb existing Bazel stable-segment mechanism directly into owned source, not a new build-time patch layer. Prepare unbound-initialized cells before release publication; preserve old directories until VM cleanup; cells do not move during directory growth. Propagate allocation failure through module/VM setup. Source cd3a19e1 records reference and before/after identities";
    attribute permanentArenaContract:String="One process-wide ticket owner covers permanent palloc_ptr, palloc_limit and psection chain reservation; one unlock exit covers fit, dedicated-section, ordinary-section and failure returns. Critical section is native C only, without Scheme callback/collecting allocation. Global shutdown still requires exclusion of late allocations; allocator-hook/reentrancy and general symbol-registry concurrency are separate unclosed obligations";
    attribute nativeEvidence:String="c1f3b273 reports global-var-set SIGSEGV after capacity integration alone.1c0f7187 adds permanent arena transaction ownership: original32768-global plus4-thread registration/GC fixture passes3 times,1.424/0.185/0.182s at default6 processors, normal exits and quiescent groups. Only Gerbil displayln is supplied as a plain-Gambit output prelude; fixture assertions/work count/GC schedule stay unchanged. e1151cd8 repeats17 current-source allocation/GC cases";
    attribute earlyProducerAdmission:String="Existing CI build_target gambit now invokes the same original fixture through produced bootstrap/bin/gsi before Gerbil phases. Fixture bytes enter both source-producer and Python construction identities.12 executable producer tests include fixture exit70 refusal and unchanged argv; missing files remain refused";
    attribute formalBoundary:String="Local native regression acceptance is not a complete C23 data-race-free proof, allocator callback admission, cross-VM count-snapshot proof or physical storage-retirement proof. QNT/Lean collector obligations do not silently close this separate storage component. Existing ASCENT compiler/package obligations remain missing until fresh full construction and original package receipts";
    attribute localNativeAccepted:Boolean=true;
    attribute completeCompilerAccepted:Boolean=false;
    attribute packageAccelerationMeasured:Boolean=false;
  }
  part stage0RecoveryBoundary {
    attribute runtimeMechanismOwner:String="modern-c-frame-contract";
    attribute darwinMayRecordBlocker:Boolean=true;
    attribute darwinMayRedesignRuntime:Boolean=false;
    attribute evidence:String="evidence/research/retained/darwin-acceleration/collector-progress-stage0-boundary.json; raw command logs and failed C remain task cache only. Curated observations survive clean checkout; missing raw bytes cannot grant fresh native admission";
    attribute construction:String="2d0ff00bd7dd41988fe8c9b010c90202 passes Gambit and early original global fixture, then boot-gxi; stage0 gsi build/build0.scm SIGSEGV. Build407.803992s exit1, no timeout; peak3375464448 bytes (3.144GiB), below8GiB. Three feature checks true; groups reaped/quiescent. Packages NOT RUN; no package speedup";
    attribute faultIdentity:String="Matched PID55311 crash UUID6511799f-0036-3e10-94f2-5e97b482375d to bootstrap/bin/gsi SHAeb807400bca85516c6043052c79685435a26ac36741ca85a31ef05d926484c80. thread-mailbox-get host+120 loads thread slot29 from R1 false, fault0xeb. The preceding caller/current-thread source and corruption origin are not established by the truncated native stack";
    attribute diagnosticControls:String="Same binary: bdc678fc default6 processor current-thread predicate and10000 timeout polls plus2000 parallel messages pass; a91e2c60 original parallel-build with100 immediate children passes;4f05f490 adds blocking process-status, passes; a3c67ad2 adds explicit100 GC operations while blocking, passes. These do not reproduce or explain actual stage0 crash; simplified controls cannot replace original consumer";
    attribute localizationContract:String="Preserve prior source/native products before an isolated original stage0 consumer. Use top-level build.sh to load configured build-env.sh; direct src/build.sh without GERBIL_PREFIX refuses before stage0 and is not a native failure. No full pipeline retry without a source-grounded change. All3 switches and existing21600s construction budget,8GiB group monitoring remain";
    attribute modelOwnership:String="QNT owns interleaving histories, not raw pointer or live-root validity; Lean owns value/representation relations under explicit premises, not scheduler exploration. Existing models do not prove mailbox operand recovery. SysML keeps native source refinement and actual two-package gates open; no new model-only pass is allowed to close them";
    attribute originalConsumerReproduction:String="55ea70cb isolates original configured stage0 without source changes:154.504999s exit1 SIGSEGV, same UUID, mailbox-get+120, R1 false and0xeb. Prior278 products preserved in cache archive.5507bc8d direct src/build.sh entry refused GERBIL_PREFIX before native work; retained as precondition failure, not native reproduction. Matching failure confirms genuine consumer reachability, not its cause";
    attribute diagnosticBoundary:String="10346564 diagnostic original stage0 captures current-thread false on one processor from scheduler/wait entry to mutex-wait return and mailbox;196.089s failure.76f83062 return/TLS diagnostic fails earlier SIGBUS45.800s without return mismatch marker; no return equivalence conclusion. Both generated C sources and original GSI restored; all command children reaped/quiescent. Diagnostic outputs never qualify packages";
    attribute mainlineScope:String="Thread/GC failures are prerequisite correctness blockers, not Darwin-specific costs or acceleration benefits. Stop expanding this into a separate SMP campaign. Compare exact Bazel/CI source, profile, generated dependencies and candidate deltas first. Existing CI script appends multiple-threaded-vms only for local-source mode; published success does not automatically cover the required three-switch profile. Keep all3 requested flags; do not use p1 or larger heap to claim acceptance";
    attribute causeClosed:Boolean=false;
    attribute fullCompilerPassed:Boolean=false;
    attribute bothPackagesPassed:Boolean=false;
  }
  dependency constructionNeedsGc from ciConstructionReference to gcAllocationProgress;
  dependency constructionNeedsGlobals from ciConstructionReference to stableGlobalStorage;
  dependency constructionNeedsStage0 from ciConstructionReference to stage0RecoveryBoundary;
  part independentDarwinLane {
    attribute baselineRepository:String="tao3k/gambit";
    attribute baselineBranch:String="master";
    attribute baselineCommit:String="f1c787a000fbb50132af79a1bdf6c7610d430c9b";
    attribute workingBranch:String="darwin-native-acceleration";
    attribute independentGitStore:Boolean=true;
    attribute modernCRuntimeRequired:Boolean=false;
    attribute modernCGcImported:Boolean=false;
    attribute allowedChanges:String="Darwin native process execution/status custody and compiler stage-product reuse; original consumer interfaces and original package tests";
    attribute excludedChanges:String="Copying-collector/VM/FrameSpec/continuation/SMP redesign and repair campaign. Shared hash-storage ownership correction is a source-grounded compiler prerequisite, not platform acceleration";
    attribute baselineGate:String="Pinned master-derived correctness baseline, including identical required hash-owner/header/SDK fixes and retained GCC/startup advantages -> complete source-built Gerbil -> gerbil clean -> gerbil build -> original tests for MCP and POO; failing unmodified control is historical diagnosis, not a speedup denominator";
    attribute candidateGate:String="Same source/dependency/tool identities and original clean/build/test sequences; only declared Darwin changes differ; component results never replace these gates";
    attribute previousCohorts:String="Modern C-based PR2 and its runtime checks are historical; no current master acceptance or speedup is inferred";
    attribute temporalDuty:String="QNT owns native pending/ownership and build publication/invalidation histories when refined to this source; no imported Modern C runtime is required";
    attribute valueDuty:String="Lean owns conditional PATH/fd/byte bounds and net critical-path laws; prior proofs do not establish current executable or package acceptance";
    attribute ascentDuty:String="Same-cohort baseline and candidate receipts, explicit original package results and missing-evidence rejection; no cross-branch receipt mixing";
    attribute currentBaselineCompilerPassed:Boolean=false;
    attribute packagesPassed:Boolean=false;
    attribute speedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part stageProductImplementation {
    attribute sourceBaseline:String="Gambit master f1c787a000fbb50132af79a1bdf6c7610d430c9b; Gerbil staging7688c85a8c75a8a8e437d4bbe391a76f0fddfea1; independent cached Darwin branches";
    attribute sourceProducer:String="Gerbil src/build/build-bach.ss: optional GERBIL_STATIC_PLAN declaration, original ordinary producer body retained; 25 forms read, native branch unqualified";
    attribute sharedService:String="src/gambit_smp/gerbil_build.py:_static_products and _static_link_product; one generation context for ordered misses, independently sealed products and ordered C-only link consumption";
    attribute costContract:String="N missing module products require one generation process if N>0, otherwise zero; per-module generation and native object compilation remain necessary; no elapsed gain inferred";
    attribute custodyContract:String="Quarantine previous C outputs without overwrite; validate whole missing batch, actual fresh outputs, input identities, process reap and group quiescence before individual publication; retain unknown completion";
    attribute nativeObjectReuseAllowed:Boolean=false;
    attribute ordinaryPackagePathIntegrated:Boolean=false;
    attribute sourceGeneratorEquivalentProved:Boolean=false;
    attribute sourceCompilerQualified:Boolean=false;
    attribute seedBuildSeconds:String="104.390972167; natural exit, group quiescent; not current full source-core or compiler qualification";
    attribute currentBlockers:String="Hash owner source fix passes full51-C-source eager core and real GSC generation; full Gerbil tools and both original package populations still pending";
    attribute threeFlagsTogether:Boolean=true;
    attribute aggregateRssLimitBytes:Integer=8589934592;
    attribute budgetRaised:Boolean=false;
    attribute focusedControls:String="9 static-product controls pass; broader25 checks:22 pass,3 fixture setup errors at legacy subprocess birth/exec admission; not skipped or passed";
    attribute qntDuty:String="Batch preparation, old-output custody, producer terminal outcome, all-output validation and member publication histories; concrete refinement OPEN";
    attribute leanDuty:String="Same-context batch generation versus isolated source product equivalence; ordered C metadata consumption and cost law. Actual Scheme/GVM/C extraction equivalence OPEN";
    attribute ascentDuty:String="Complete compiler consumer, both original package clean/build/test populations and matched timing receipts; seed, reader and unit controls cannot fill these observations";
    attribute mcpTestsExecuted:Boolean=false;
    attribute pooTestsExecuted:Boolean=false;
    attribute packageNetGainMeasured:Boolean=false;
    attribute prSubmitted:Boolean=false;
  }
  part nativeProductIdentity {
    attribute authority:String="Independent Darwin source; native artifact contract, not GC algorithm change";
    attribute sourceFinding:String="gsi/makefile.in and gsc/makefile.in depend on undefined MODULES_O; lib/makefile.in omits link object from configured-header prerequisite";
    attribute replacement:String="All OBJECTS depend on configured gambit.h and effective makefile; executable, library and link roles share the same invalidation boundary";
    attribute sourceCustody:String="Missing generated C restored only from exact pinned Git source, checked against original source identity; no historical native or evidence cache restored";
    attribute factorialEvidence:String="e13b453af8894a6386f1ca56faa46290: fresh CLI objects with retained original runtime archive pass GC table lookup; fresh unmodified mem.o byte-identical to retained mem.o; no rehash algorithm patch justified";
    attribute counterevidence:String="22b7f3b8e2564ef78fbe279013736997: full rebuilt GSI is byte-identical to seed and still fails GC lookup; original same binary has input/run-dependent pass and failure; factorial success does not establish artifact incoherence as cause";
    attribute nativeResult:String="Pinned-C seed completes; six sampled header invalidation roles pass; real GC table consumer and GSC ##fxorc2/C generation fail. Package acceptance remains refused";
    attribute qualification:String="Header invalidation must cover executable and link objects; current full GSI and GSC consumers, same-source regeneration, complete Gerbil and both original package gates required";
    attribute qntExclusive:String="Unknown native completion retains custody; profile invalidation and complete-role publication before LinkPlan consumption; concrete native refinement OPEN";
    attribute leanExclusive:String="Native role input identity and declared header/profile closure imply reusable ABI only under complete producer dependency assumptions; concrete ABI/source equivalence OPEN";
    attribute ascentExclusive:String="Join exact generated C/header/compiler/profile/object identities and actual consumers; missing or failed observations never satisfy package acceptance";
    attribute copyingCollectorRedesigned:Boolean=false;
    attribute fullConsumerQualified:Boolean=false;
    attribute newSpeedupMeasured:Boolean=false;
    attribute prSubmitted:Boolean=false;
  }
  part hashLayoutOwnership {
    attribute sourceContract:String="_system.scm:make-table defaults equal?; table-access probes Scheme hash modulo size; _back.scm:make-prim-proc-table uses that constructor. C in-situ MEM_ALLOC_KEYS branch assumes homogeneous heap keys";
    attribute counterexample:String="14285729ac1048b0a946487b32c6a7ac: source-extracted rehash fails mixed immediate/heap keys at size5,key0. 6b649ce252c447979eeeec18389e26c6: real _io generation scan/mark_array dereferences0x3fffffff8 with key0x3fffffff9 and table flags48";
    attribute rejectedPartialFix:String="35e32c5edda442dcb80d5aef0321fabc passes three symbol-only tables and real GSC C generation after NEED_REHASH notification, but full source compilation still fails: notification cannot undo immediate-key retagging";
    attribute immutableOwner:String="SCHEME_HASH=128 is mirrored in configured C and Scheme headers, assigned at generic table storage creation, preserved by resize/copy flags; C eq storage retains homogeneous key partition";
    attribute collectorBoundary:String="Scan mixed roots using ordinary memory-object predicates; Scheme-owned tables never enter C pointer-rehash. If keys move, publish NEED_REHASH for existing Scheme table-access/resize consumer. Eq storage retains eager rehash";
    attribute bootstrapBoundary:String="Private single-processor compiler uses existing lazy policy solely to generate the new Scheme creator. All three VM flags remain enabled. Final source-built runtime uses ordinary eager policy; private seed is never package/runtime acceptance";
    attribute compatibility:String="Native product keys bind configured header, Scheme creator, runtime implementation and policy. Do not reuse unqualified old serialized table images or ownerless generic layouts";
    attribute addedCost:String="One owner flag test per reached table; owner bit preserved in existing flags word, no object-size increase. Scheme hash work on invalidation remains necessary; no speedup credited for correctness";
    attribute qntExclusive:String="Owner-preserving creation/GC invalidation/resize publication histories and unknown producer custody; concrete source refinement remains OPEN";
    attribute leanExclusive:String="No immediate key retagging for Scheme owner, key/value preservation and owner/hash agreement; current source counterexample and finite controls are not universal proof";
    attribute ascentExclusive:String="Require complete eager source-core receipt, mixed-key controls, complete Gerbil, both original package gates and same-cohort timing; partial symbol controls refuse package acceptance";
    attribute finalEagerSourceCorePassed:Boolean=true;
    attribute finalSourceReceipt:String="4bd851b5bad743f78ab403eff7df41be: full51 generated C, Scheme inputs stable, no missing C, native Make269.274s exit0; eager final symbol/mixed controls and GSC C generation pass";
    attribute durableRegression:String="tests/fixtures/darwin-hash-layout.scm:86 mixed immediate/heap keys for equal/custom/eq, repeated collections and replacement; current exact runtime passed before Gerbil continuation";
    attribute additionalCallbackBoundary:String="Conservative NEED_REHASH invokes existing Scheme resize/hash callbacks; exact custom callback-count equivalence and universal table/weak/concurrent semantics remain unproved; no whole-runtime admission";
    attribute packagesPassed:Boolean=false;
    attribute accelerationCredit:Integer=0;
  }
  part nativeRoleMemoryAdmission {
    attribute producer:String="src/build/build-bach.ss invokes GSC -obj -cc-options -g on each actual C input; source core compile-module also retains GSC state while GCC runs";
    attribute rejectedFiveWorkerReceipt:String="b9f53b729bb047da8c3ec15eed49c06a: aggregate8751808512 bytes exceeds8589934592; cc1 sum about7.604GiB; GSI about0.264GiB; parent reaped, registered cleanup unresolved empty, explicitly reconciled";
    attribute singleRoleReceipt:String="5caf2e71b5be4c88bd211f7a14aa852c: exact retained runtime/eval C input, GSC -obj/-g, actual GCC16 O1 C23 SINGLE_HOST/macro-tracking0 argv,19.526992334s exit0; aggregate peak2455240704 bytes; input stable";
    attribute currentAdmission:String="69f5454e39e54bc7a9cc56a14d80e97c: two workers, estimated3GiB per job and512MiB parent reserve, unchanged8GiB sampled aggregate monitor; no increased stage budget";
    attribute reservationIsProvedUpperBound:Boolean=false;
    attribute pipelineGap:String="C-only calibration excludes source-producing GSC retained heap; observed live two-worker sample includes GSC1.531GiB and cc1 3.011GiB alongside GSI1.204GiB. Estimates are not a compositional memory bound";
    attribute workReuse:String="Two-worker continuation launches zero stage0 module compilers:185 completed modules reused under unchanged semantic inputs; unqualified stage1 outputs quarantined, not reused as passed products";
    attribute futureWorkRemoval:String="Seal C-only phase output and retire its generating context before native admission. Preserve real generation options and consumer role before claiming equivalence or memory removal";
    attribute qntExclusive:String="Active-job reservations/admission/drain and unknown completion custody; capacity invariant requires actual upper-bound premises, absent for current estimates";
    attribute leanExclusive:String="Conditional sum/span laws and C-input/native-role equivalence; a single input calibration does not prove an all-input bound";
    attribute ascentExclusive:String="Join source/profile/tool and full process outcomes; RSS-killed stage refuses compiler/package acceptance. C-only component success never fills either package gate";
    attribute packageSpeedupMeasured:Boolean=false;
  }
  part retiredProducerNativeProducts {
    attribute sourceCut:String="std/make.ss:make-build imports every module-id before starting workers; compiler/driver.ss captures the native recorder when each Scheme file is emitted. Foreign gsc specs use the same recorder; original non-plan behavior remains";
    attribute planContract:String="Completed gerbil-native-compile-plan carries exact program/argv/cwd/environment/source. No expander closures cross the boundary. A normal, reaped and group-quiescent producer precedes all native consumers";
    attribute refusedRole:String="Dependent generate/copy/object/bundle actions in the ordinary Darwin single-object sharing path reject recording; they are not falsely represented as one independent process";
    attribute consumer:String="Existing gerbil.build stdlibNativeProducts flag; one shared gerbil_build.py consumer validates the entire plan before submission, hashes actual SCM inputs, refuses existing/duplicate outputs, and preserves unknown completion";
    attribute resources:String="All three runtime features retained; one aggregate8GiB sampled RSS guard includes observer and every registered group. The former extra7GiB producer cap is removed; generation/native phases retain one600s stdlib deadline. Historical7GiB refusals do not qualify8GiB capacity";
    attribute candidateRun:String="8c3600132051482098da6dcb3731855e: new-source stage1 passes375.980450042s; producer refuses after2.649481709s on JSON/FFI bootstrap dependency. Corrected b6b7b9cf4998455e94bb70433d9d37c6 reuses core; producer exceeds7GiB after83.038857916s with zero native consumers launched; reap/group quiescence and byte streams retained";
    attribute capacityCounterexample:String="Producer peak7528218624 bytes exceeds7516192768-byte inner guard without any native consumption. Removing GCC overlap alone does not establish capacity. Separate live context roots from collectable allocation using existing natural GC reports before selecting a further cut; do not raise limits";
    attribute codecBoundary:String="Reuse the prior compiler static-plan escaping algorithm for the narrow strings/arrays/string-keyed-object protocol, no standard-library FFI import. Source function Unicode/control/empty-container roundtrip and unsupported-value/key controls pass; these are observer component checks";
    attribute controls:String="13 native-plan controls and9 existing static-product controls pass; producer failure/unreaped/nonquiescent guards, shared deadline, captured environment and zero-exit/missing-output refusal exercised. Initial test fixture lacked tools and was repaired without production change. MCP source checks pass; no native/package admission follows";
    attribute sourceUpdateRecovery:String="An omitted full input inventory removed declared source files during driver update; recovered2016 entries/1820 source files, verified417 unchanged core identities, preserved native products. No cache/native acceptance inferred; subsequent delta calls conserve the full input set";
    attribute qntExclusive:String="Producer close/failure/unknown, whole-plan admission, native ownership/drain and publication histories; refine existing stage_context_handoff/native_artifact_partition rather than adding another scheduler";
    attribute leanExclusive:String="Captured command value/argv/environment fidelity and source/native equivalence, phase-span and capacity laws. Historical RSS samples do not prove an all-input bound or a speedup";
    attribute ascentExclusive:String="Same source and profile join through actual producer exit, every native output and both original package results; source checks and Python controls cannot fill missing native receipts";
    attribute costBoundary:String="Barrier removes temporal overlap, not C parsing/codegen. New JSON/hash/admission and lost overlap costs must be charged; no twofold gain follows from avoiding an RSS-failed build";
    attribute nativePhasePassed:Boolean=false;
    attribute packagePassed:Boolean=false;
    attribute speedupMeasured:Boolean=false;
    attribute prSubmitted:Boolean=false;
  }
  part moduleReadProductBoundary {
    attribute status:String="Same-source stage1, reader/promise/alias controls and full read-product producer join passed. Source/native phase retirement observed; complete library/tools blocked by original native member171 failure, packages not run. General in-process bounded eviction remains unimplemented";
    attribute nativeObservation:String="93966114f2ee4f7b8f72bbc73784302a: existing natural-GC reporter, no forced GC or heap change;27 reports. Before any compile-start/job callback, post-GC live3109927760 bytes. Later live3390401488 bytes; inner7GiB refusal is not proof of failure at outer8GiB";
    attribute causalSource:String="std/make.ss prepare-completions calls module-id/import-mx for every spec before workers. expander/module.ss import-source stores expanded body both in module-context-code and a delay-atomic eval-syntax promise, then registers the context by path and id";
    attribute readProduct:String="Planning registers unread descriptors and source/interface completion aliases without reading. First real core-import-module reads pre/id/ns/body in its original dynamic context, preserving actual syntax objects; actual id claims are checked for duplicates, never inferred from filenames";
    attribute ownership:String="Unread -> Reading -> Ready -> Transferred; reader failure retains the original exception under Failed. Direct read body/context slots clear only after original module context matches both path and actual-id registry anchors. Compiler code and deferred evaluator remain original context-owned roots until session/process retirement; no early force or registry clearing";
    attribute stateMapping:String="Scheme unread/reading/ready/transferred/failed map to ModuleReadState. Direct-slot absence does not prove absence of indirect body reachability; a prelude identity can itself reference a context";
    attribute demandBoundary:String="The completion preparation loop is read-free. Existing coordinators subsequently demand real expansion and use actual source/interface aliases, including nested-module source paths. General bounded session eviction and arbitrary effectful expansion-order equivalence remain OPEN";
    attribute sourceChecks:String="412512e8 source product;80713f5d planner;65250640 transfer anchors;96d0a933 identity/report;7a8f91aa direct-root evidence: MCP pre/post checks. A call-count assertion stopped before planner mutation and was corrected from actual callers; no native run followed unchecked source";
    attribute admission:String="Existing Python gerbil.build validates whole planned/expanded report relation before native consumers: stable owner/alias sets, zero planning reads, direct payload/context absence, valid actual ids and missing-evidence refusal. Reporter environment is scoped to stdlib producer, not leaked to tools/packages";
    attribute aliasIdentity:String="Declared source and generated SSI paths share one read product and completion. Import resolves the canonical source before the registry cache fast path, including a stale preloaded SSI; alias registry entry is updated to the same context. This is required when an SSI appears during compilation";
    attribute interruptedCohort:String="629b21d8bd25475dac147f59d532ae41 deliberately stopped before native controls after finding the SSI identity gap; parent reaped, registered cleanup unresolved empty. Its completed module receipts do not constitute core or package acceptance";
    attribute nativeControlOutcome:String="6459642747f14f61a9566da975205991: same-source stage1 PASS520.994849375s; real reader/promise/stale-alias/failure controls PASS2.123632666s; stdlib producer failed70 after3.560607875s on a future SSI parent required by path-normalize. Peak aggregate7479017472 bytes; parent reaped and groups drained; packages not run";
    attribute futureOutputPath:String="Existing std/string/path path-maybe-normalize supports unread output parents. Whole-plan native admission rechecks physical path identity; a later symlink retarget refuses consumption. Source check fe7f910f377844b09b44279bb7a21478;23 Python controls include missing-parent and symlink negatives";
    attribute previousInnerLimitObservation:String="54f0666593874368bbbd539c14c05e82:334 unread products/668 aliases, then inner7GiB refusal at84.151189334s. Superseded as the resource contract by the user's single8GiB aggregate envelope; retained as a historical negative observation";
    attribute currentRun:String="55a2b2d3357349e69262318b5da2e013: complete source producer/read-report join and native admission; native171 failed70. Intentionally stopped and fully drained; no complete library/tools/packages.597b4bcf677e41378e7e003b8f58b887 validates26 controls,13-file SysML closure,D2,Org links and hash-archived diagnostic C; later stableHashIteration establishes a controlled cause and component fix; complete compiler/package acceptance and per-module eviction remain OPEN";
    attribute inferenceLimit:String="A real read-free planning boundary is established, not bounded total expansion memory. This inner7GiB refusal does not prove failure at the authorized outer8GiB budget, no memory reduction is measured, and necessary cold expansions may all remain. No repeated attempt or higher limit is evidence of this cut's net benefit";
    attribute nextSemanticDependency:String="Before retiring context code or deferred evaluator, close actual executable macro/provider support, continuation and effectful-reader consumers. A bounded owned session must retain live dependency instances and lazy initialization. Current product cannot issue that retirement receipt; no body-clearing workaround";
    attribute planningBoundaryObserved:Boolean=true;
    attribute readerNativeControlsPassed:Boolean=true;
    attribute completeLibraryPassed:Boolean=false;
    attribute completePackagesPassed:Boolean=false;
    attribute retirement:String="Retire eager full-import planning only after real identity/dependency consumers, macro execution readiness, reader effects, lexical identity and deferred evaluation have source-bound equivalence evidence";
    attribute qntExclusive:String="Read-product ownership, admitted expansion/evaluation, transfer and failure/unknown/late use; refine stage_context_handoff only after actual transition guards are specified";
    attribute leanExclusive:String="Actual core-read-module result preservation, binding/source/exception equivalence and root-coverage/value laws; do not duplicate temporal scheduling exploration";
    attribute ascentExclusive:String="Join concrete source anchors and native observations; live byte counts are not reclaimable-byte or elapsed-saving receipts";
    attribute memorySavingMeasured:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
  }
  part expansionSessionCustody {
    attribute sourceConsumers:String="expander/module.ss import-source and core-eval-module retain/use original body and atomic promise; compiler/driver.ss collect/runtime/meta/SSXI and nested lifting; optimize.ss and method.ss read/update current code; tools/gxtags.ss consumes code for tooling. Public eval/compile hooks and arbitrary captured syntax remain barriers to per-module eviction";
    attribute implementedBoundary:String="Existing gerbil.build stdlibNativeProducts executes one source-generation process, then validates every request before native submission. It never forces promises for retirement. The process-owned registry, optimized bodies and deferred bodies end with that address space; no Scheme object graph is transported through the JSON/file interface";
    attribute lifecycle:String="Planned -> Active -> Sealed producer output -> Drained/reaped/quiescent -> Retired process heap. Failed/unknown producers cannot publish a native plan even if some files exist. A reaped failed process can retire its heap without qualifying any product";
    attribute budgetCorrection:String="7GiB was an agent-added observer reserve, not the user's contract. Removed from gerbil_build.py; one8GiB sampled aggregate monitor covers observer/producer/native groups. No added heap, timeout, workload reduction or profile relaxation";
    attribute concreteReadObservation:String="c2d0524a7ab943d1a713f1b30996c2e1: source producer PASS178.290236875s, reaped/quiescent, aggregate peak8329904128 bytes below8589934592. Actual334 products:314 transferred/20 preexisting,668 aliases; direct-slot report is not per-module promise retirement.912 native requests emitted; C-target decoder gap refused all native launches";
    attribute nativePlanCorrection:String="Whole actual912-request plan decodes with exactly one optional -target C; other/duplicate/missing targets refused.55a2b2d3357349e69262318b5da2e013 source producer PASS221.150934583s;314 transfers/20 preexisting; native171 std/test/base~0 failed70 with duplicate symbol macro and missing symbol index.259 native exits0 observed,2 STARTED at deliberate stop; no complete library/tools or packages. Peak aggregate4626415616 bytes; parent reaped and cleanup unresolved empty";
    attribute failureControls:String="ecec1ed163584a6d8da04ced2b74b9a2: same SCM hash/source GSC, retained C-only output clean.705f3495a1b24d08aa3e5711dd731b59: same SCM, keep-temp/output-scoped dynamic control exit0, output created. Neither reproduces or fixes the original failure. Original failing C was deleted by GSC; stderr fragments are not a complete bad-C witness. No GC cause was assigned by those standalone controls; later controlled mechanism and correction are owned by stableHashIteration";
    attribute boundedExecutor:String="Existing native executor now cancels unstarted futures after the first member failure and drains already running work; original error remains authoritative.26 focused controls include deterministic first-failure cancellation. No new runner, native parallelism or timeout increase";
    attribute remainingBoundary:String="No bounded per-module cache or arbitrary in-process context eviction is implemented. The live transitive execution-support closure may still grow within a source session; budget refusal is not a memory-bound theorem. Cold expansion work reduction and matched package speedup remain OPEN";
    attribute qntExclusive:String="Session failure/unknown/reap/drain, complete-plan publication, native launch and late observation ordering";
    attribute leanExclusive:String="Only value/file projections cross the session; binding/reader/exception fidelity and exact C target/argv decoding. No duplication of QNT schedules";
    attribute ascentExclusive:String="Join one source/profile/cohort through real producer terminal receipt,334-product reports,912 native outcomes and both original packages. No component or stale cohort fills a missing gate";
  }
  part nativeSdkLinkProjection {
    attribute sourceFailure:String="69f5454e39e54bc7a9cc56a14d80e97c: two-worker stage1 completes source/C/object work, exits70 at final BACH GCC link after538.986858375s; missing libSystem symbols, not timeout or memory refusal";
    attribute sharedService:String="src/gerbil/compiler/driver.ss exports native-link-options; both direct driver GCC callers and build-bach.ss use its argv vector";
    attribute projection:String="Managed Darwin SDKROOT becomes separate -B/usr/bin/, -isysroot, SDK path arguments; no shell splitting, no change to existing GCC optimization/diagnostic options";
    attribute coverage:String="Three direct GCC links share one service. GSC/gambuild roles retain their configured SDK paths. Non-Darwin returns no extra arguments";
    attribute scopeBoundary:String="Managed SDKROOT must match the SDK used for C objects. General LDFLAGS decoding, cross-target profiles and unspecified SDK fallback are not qualified by this change";
    attribute sourceChecks:String="db743c74040448f7b1518469b9ab7f68: MCP balance and full-context expansion before/after each of the two source files; observer Homebrew GXI is editor-only, never candidate compiler/package admission";
    attribute independentControl:String="8dc3a8653af4425195590db11fc42a0a: same43 pre-helper-epoch objects, SDK-only native link and executable compiler-import marker pass; input hashes stable; not new-source compiler acceptance";
    attribute currentBuild:String="aba1111f27874aa98f1aa0210717da1f: new-source stage1 passes595.370189083s, exit0 without timeout; standard library interrupted at aggregate8604090368 bytes, Gerbil5.788GiB plus cc1 2.041GiB. Parent reaped and unresolved cleanup empty; tools/packages not admitted";
    attribute aggregateFailureBoundary:String="Outer supervisor killed the observer as well as stdlib; stage1 terminal receipt survives, stdlib STARTED record is not completion. Final stdlib byte streams/precise last module are missing, never reconstructed as observed";
    attribute nextArchitectureCut:String="Retire source expansion contexts before overlapping native work, preserving actual macro execution readiness and binding identity. Do not clear the global module registry or repeat cumulative planning without a valid source contract";
    attribute qntExclusive:String="Source/object/link readiness and failure custody; a failed parent cannot be silently relabelled passed when a link control succeeds";
    attribute leanExclusive:String="SDK projection preserves argv element boundaries and native role values; all emitted object/code equivalence and general flag decoding remain separate obligations";
    attribute ascentExclusive:String="Same source/profile/tool and consumer identities; source editor and old-object controls do not fill current compiler or either original package gate";
    attribute packageAcceptance:Boolean=false;
    attribute newAccelerationCredit:Integer=0;
  }
  part patchEvidencePriority {
    attribute authority:String="Historical priority plan; current execution and evidence admission are owned by twofoldArchitectureAudit";
    attribute prSubmissionAllowed:Boolean=true;
    attribute order:String="1 effective GNU GCC diagnostic policy; 2 native launch contract; 3 sealed stage/native products; 4 streaming closure DAG; 5 frozen verification support; 6 causally bound interface construction";
    attribute rankingRule:String="Historical impact and architectural leverage; incomparable fixture/object/package cohorts never form a numeric total ranking";
    attribute foundationEvidence:String="0004 MCP object 15.45->10.37s, GCC allocation about 8.9GiB->97MiB; 0001 matched120-module medians28.853->10.465s; neither is a whole-package forecast";
    attribute profileContract:String="EffectiveNativeProfile separates capabilities/codegen/diagnostic policy and covers actual OBJ/DYN/static callers; allocation is not RSS; existing active policy earns no new credit";
    attribute processContract:String="NativePipelinePlan owns PATH/fd/env/cwd/signal/status lifetime; retain PTY/unsupported fallback; D1469 zero fork excludes another fork-removal claim in that cohort";
    attribute principalNewWork:String="Gerbil stage service: one sealed producer per consumed projection and native role; LibraryReadiness and ordered LinkPlan reuse actual compatible products; no GC/FrameSpec changes";
    attribute snapshotContract:String="Compiler reads immutable actual C snapshot; profile/header/tool/role/dependency identity; pre/post equal hashes alone do not exclude ABA";
    attribute executorContract:String="Existing bounded compiler executor; capture submission context, release ready jobs, drain accepted/derived work, preserve first error; std/make retains dependency ownership";
    attribute invalidation:String="First affected consumed projection and descendants; native profile changes do not invalidate unchanged Scheme semantics; link order changes require new link result";
    attribute failureCustody:String="Unknown producer/publish/status/verification result retains source and output custody; no successor receipt or reusable hit until known terminal ownership";
    attribute baselineDeduction:String="Separate raw-master and existing-Bazel-advantages-retained pairs; ported existing gains get zero incremental credit against the latter";
    attribute frozenCheckpoint:String="MCP six-patch cold36.414/35.552/37.770s; complete39-file965-case test86.924s; MCP-only opt-in, not POO/general admission; 0026 safety credit only";
    attribute counterevidence:String="ASCENT cold98.66->101.90s regression;71 hits43.40s vs43.08s; graph rewrite29.832->30.505s;26.907860s complement unattributed; no ratio multiplication";
    attribute netLaw:String="Tnew=B-E-O+A; twofold iff E+O-A>=B/2 with disjoint measured critical removal E, verified overlap O, all new costs A; job seconds and bytes cannot replace elapsed savings";
    attribute qntExclusive:String="Product reserve/publish/invalidate and accepted/derived drain/late/unknown histories; reuse compile_resource_admission and compile_stage_products; concrete source composition OPEN";
    attribute leanExclusive:String="Actual-input/consumer observational equivalence, ordered-link semantic obligations and net/span algebra; reuse CompilerBuildBatch/DevelopmentBenefit; concrete compiler refinement OPEN";
    attribute ascentExclusive:String="Exact cohort/source/profile/tool joins, baseline deductions, both original clean/build/test receipts; historical darwin-module-image rules stay historical, new active routing OPEN";
    attribute retirementOrder:String="Enumerate effective foundation callers; replace duplicate stage producers and closure compiles; integrate existing streaming executor; amortize immutable verification; retire old authorities only after original controls and callers migrate";
    attribute currentTwofoldProved:Boolean=false;
    attribute concreteRefinementClosed:Boolean=false;
    attribute newNativeTrialsPerformed:Boolean=true;
    attribute evidenceRoot:String="patches/gerbil-v19-darwin:README.md,REFLECTION.md,receipts/d1469-real-process-census-and-extension-boundary.md,receipts/d1510-frozen-safety-bundle.md,receipts/d1510-static-object-reuse-v4.md";
  }
  part target {
    attribute targetSpeedup:Integer=2;
    attribute currentPackageGainMeasured:Boolean=false;
    attribute macroPrimaryTailEstablished:Boolean=false;
    attribute occupancyEqualsCpu:Boolean=false;
    attribute blindNativeTrialsAllowed:Boolean=false;
    attribute historicalMcpMicros:Integer=74671000;
    attribute historicalTargetMicros:Integer=37335500;
    attribute parseableCompileJobMicros:Integer=636536000;
    attribute workers:Integer=12;
    attribute minimumJobIntervalRemovalMicros:Integer=188510000;
    attribute phaseOnlyAfterGraphFloorMicros:Integer=40054000;
    attribute sourceBasis:String="Independent tao3k/gambit master f1c787a000fbb50132af79a1bdf6c7610d430c9b; Modern C is neither baseline nor prerequisite. Earlier cohorts remain historical, not transferable acceptance";
    attribute packageHeads:String="mcp:05ed8728a4871e3483fe9792480ecee2d9653e4b;poo:2167f1f87bb0ffda3c29ff7497b35bcd47aeffe9";
    attribute qntDuty:String="Existing package_benchmark_admission/preparation_reuse/incremental compiler models own readiness, invalidation and publication interleavings; concrete refinement remains open";
    attribute leanDuty:String="Existing DevelopmentBenefit owns reuse/overlap/net-removal algebra; fixed historical interval arithmetic below is a conditional bound, not new runtime proof";
    attribute ascentDuty:String="Join current typed design values and explicit refusal controls; file associations, historical reports and missing current native observations never grant twofold admission";
    attribute budgetPolicy:String="Research120s; model60s; evidence20s; original package/native budgets unchanged";
    attribute nonGoals:String="No Modern C import, GC/global-storage/FrameSpec/SMP redesign, repair campaign, historical cache recovery, new runner, wrapper or blind native experiment";
    attribute priorAuthority:String="GambitDarwinDevelopment::platformPhaseCost, costFactor0..8 and target0..1; DevelopmentBenefit.platformGap and twofoldAcceleration remain the existing owners";
    attribute differentialCreditRule:String="Classify extra action counts, higher matched-action unit cost and extra platform overhead separately; per-phase work law is not parallel elapsed time. Shared improvement alone supplies no residual ratio claim";
    attribute sharedGainIsDifferentialProof:Boolean=false;
    attribute platformGapReductionMeasured:Boolean=false;
    attribute darwinPriority:String="Reuse Bazel reached evidence first: D1469 observed zero Gambit fork in its MCP build; 0015 shell substitution and runtime-object reuse are existing gains. NativePipelinePlan must replace transport authorities, not add preparation/coordinator layers. Root startup spawn time is not the silent interval; current two-package differential weights remain open.";
  }
  part work0 {
    attribute key:String="phase-readiness";
    attribute owner:String="incremental-query-service";
    attribute source:String="../gerbil-gambit-bootstrap-audit/src/std/make.ss";
    attribute needle:String="(def (build-coordinator spec)";
    attribute mechanism:String="Separate interface, executable macro-support, generated Scheme/C and native readiness; release consumers on their consumed projection";
    attribute retire:String="Whole-module completion as the only readiness gate and timestamp-only freshness authority";
    attribute retain:String="Required initialization, actual dynamic reads, macro execution support and explicit serial policy";
    attribute added:String="Dependency trace validation and per-stage result publication";
    attribute invalidate:String="Leaf runtime change affects consumed runtime/C/native/link projections; shared macro change affects actual expansion consumers and their descendants";
    attribute scope:String="Both packages; cold first build still owes necessary misses";
    attribute platformScope:String="shared-action-count candidate; no Darwin-specific credit without actual per-platform count or unit-cost attribution";
  }
  part work1 {
    attribute key:String="private-phase-context";
    attribute owner:String="gambit-phase-engine";
    attribute source:String="vendor/gambit/gsc/_front.scm";
    attribute needle:String="(define (compile-frontend";
    attribute mechanism:String="Seal immutable support/construction programs; instantiate owned compiler contexts with private target/primitive/expander state";
    attribute retire:String="Whole-process/global compiler state as the sole isolation and reuse boundary";
    attribute retain:String="Lexical identity, module effects, source diagnostics, roots, continuation multiplicity and mutable per-session instances";
    attribute added:String="Private instance setup, root ownership and bounded state retention";
    attribute invalidate:String="Semantic provider/declaration/support change invalidates affected phase programs; native compiler-only change leaves semantic stages reusable";
    attribute scope:String="Both packages; D803 excludes universal macro-primary-tail credit";
    attribute platformScope:String="shared semantic/support construction; no proof that Darwin expander cost is the platform excess";
  }
  part work2 {
    attribute key:String="closure-link-plan";
    attribute owner:String="phase-artifact-graph";
    attribute source:String="../gerbil-gambit-bootstrap-audit/src/gerbil/compiler/driver.ss";
    attribute needle:String="(def (compile-executable-module/separate ctx opts)";
    attribute mechanism:String="Content-keyed ordered closure and LinkPlan consume existing stage products; preserve immutable stub/link products rather than obligatorily recreate/delete them";
    attribute retire:String="Unconditional executable stub/link reconstruction and timestamp/path readiness as reuse authority after complete LinkPlan consumers migrate";
    attribute retain:String="Ordered module initialization, link mode/options, changed objects, actual link errors and runtime binding identity";
    attribute added:String="Closure/ABI validation, retained artifact storage and exact output manifests";
    attribute invalidate:String="Runtime closure/interface/order/ABI changes invalidate link projections; unchanged generation can survive compiler-only object misses";
    attribute scope:String="MCP and explicit POO executables only; installed Darwin already reuses produced runtime C and schedules objects, which are baseline rather than new savings";
    attribute platformScope:String="mixed contract with an existing Darwin-specific runtime-C/object/bundle realization; current baseline improvements deducted; compare full action DAG rather than outer invoke count";
  }
  part work3 {
    attribute key:String="shared-native-interface";
    attribute owner:String="native-module-data-emitter";
    attribute source:String="vendor/gambit/gsc/_t-c-1.scm";
    attribute needle:String="(targ-define-count \"GLOCOUNT\"";
    attribute mechanism:String="Scheme emits ModuleSpec/FrameSpec data against stable C23 interfaces and compiled common helpers; explicit hot inline policy";
    attribute retire:String="Per-module count-specialized reconstruction of shared interface/layout responsibilities after all consumers migrate";
    attribute retain:String="Tail calls, object layout, roots, continuation descriptors, module setup and portable C semantics";
    attribute added:String="Relocations, descriptor decoding, ABI rebuilds and any helper-call runtime cost";
    attribute invalidate:String="Descriptor/runtime ABI change invalidates every dependent generated/native artifact; module data-only changes do not alter the shared ABI header";
    attribute scope:String="Both packages; header modularization alone does not eliminate textual parsing; D858 header-only package negative result retained";
    attribute platformScope:String="shared interface/literal construction; current Darwin GCC diagnostic tracking compaction is already baseline; differential frontend contribution remains unallocated";
  }
  part work4 {
    attribute key:String="owned-native-actions";
    attribute owner:String="native-action-runtime";
    attribute source:String="vendor/gambit/lib/os_setup.c";
    attribute needle:String="int ___closefrom";
    attribute mechanism:String="One typed NativeAction and CapacityPlan; qualified Darwin fd actions avoid descriptor-limit-proportional child cleanup and duplicate request setup";
    attribute retire:String="Duplicated launch/configuration authorities and eligible fd-limit sweep; never re-credit an already installed fix";
    attribute retain:String="Exact argv/env/cwd/fds/signals/PTY, startup errors, natural exit and unsupported-mode equivalence";
    attribute added:String="Request validation and terminal/unknown-result custody inside original limits";
    attribute invalidate:String="Tool/config/platform capability or launch context changes invalidate native action evidence, not independent Scheme semantic products";
    attribute scope:String="Both packages for eligible native launches; default serial configuration is cross-platform and not a Darwin-only cause";
    attribute platformScope:String="Actual retained MCP census closes ordinary Gambit fork-removal opportunity there. Preserve that fast behavior in current C23 migration; remaining platform transport gain must be beyond admitted0015 and unchanged request-preparation layers.";
  }

  part module0 {
    attribute key:String="mcp-data-embedded";
    attribute repositoryKey:String="mcp";
    attribute source:String="../gerbil-mcp/data/embedded.ss";
    attribute buildProducer:String="../gerbil-mcp/scripts/embed_data.py via Makefile:43; direct gerbil build consumes existing generated input";
    attribute schemeProducer:String="Gerbil generate-runtime-code/compile-scm-file; GSC compile-file-to-target then targ-dump-sub/string";
    attribute nativeProducer:String="Installed Darwin gsc-compile-file:1054; -c once, copy static C, -obj with DYNAMIC/fPIC, gambuild-C dyn uses static object";
    attribute cBytes:Integer=11425281;
    attribute str8Calls:Integer=218334;
    attribute str8CallSourceBytes:Integer=7897965;
    attribute symbols:Integer=4;
    attribute globals:Integer=18;
    attribute labels:Integer=34;
    attribute ofd:Integer=1;
    attribute equalSchemeCopies:Boolean=true;
    attribute equalCCopies:Boolean=true;
    attribute artifactScope:String="Existing unqualified generated artifacts; not a current vendor C23 execution or proof of repeated GSC invocation";
    attribute newOpportunity:String="Target-qualified literal image plus code/data dependency projections; remove per-character packing expressions and repeated metadata construction, not required payload semantics";
    attribute alreadyPresent:String="One C generation, static C copy and shared static object/dynamic bundle branch already exist in installed source; zero new credit for recreating them";
  }
  part module1 {
    attribute key:String="poo-support-rationaldict";
    attribute repositoryKey:String="poo";
    attribute source:String="../gerbil-poo/support/rationaldict.ss";
    attribute buildProducer:String="../gerbil-poo/t/build-spec.ss:33 library and qualification inventories";
    attribute schemeProducer:String="Gerbil defstruct/iter expansion -> runtime Scheme -> GSC targ-dump and per-procedure frame/label metadata";
    attribute nativeProducer:String="Same installed Darwin gsc-compile-file conditional producer; eligibility requires matching effective mode/profile; observed global artifact provenance incomplete";
    attribute cBytes:Integer=179814;
    attribute str8Calls:Integer=33;
    attribute str8CallSourceBytes:Integer=1239;
    attribute symbols:Integer=35;
    attribute globals:Integer=70;
    attribute labels:Integer=191;
    attribute ofd:Integer=9;
    attribute equalSchemeCopies:Boolean=true;
    attribute equalCCopies:Boolean=false;
    attribute artifactScope:String="Static C and two equal Scheme files observed; dynamic C absent, so duplicate C generation is not established";
    attribute newOpportunity:String="Shared compiled binding/setup helpers and typed module/frame data across ordinary modules; string-only change has little lexical coverage here";
    attribute alreadyPresent:String="Existing object freshness, dynamic/static sharing and compiler parallelism are baseline; no current POO timing assigned";
  }
  part moduleContract {
    attribute key:String="module-code-literal-binding-contract";
    attribute semanticOwner:String="Scheme owns literal graph, code semantics and FrameSpec; target data emitter owns qualified encoding, never Gerbil serialization of live compiler state";
    attribute generationKey:String="Complete semantic input, module-ref/linker identity, target word/character width/endian/tags and generation policy; may ignore native compiler only when not semantically observed";
    attribute codeProjection:String="Code may ignore literal payload only with complete constant-folding/inspection and stable-reference projection; shape, identity or optimized-value changes invalidate code";
    attribute dataProjection:String="Literal image includes full payload, object graph, alignment, padding, tags and relocation/fixup records; data edits still require their real output work";
    attribute bindingProjection:String="Keep ordered globals/symbols/keywords/init, fresh gensym and required instance effects; fixrefs writes and SETUP_FIXUP_DONE remain owned mutable state";
    attribute retirement:String="Retire targ-vector-like-object-body string packing and count-specialized shared metadata only for migrated classes; preserve old path until all consumers agree";
    attribute retained:String="Payload encoding, necessary C parsing/code optimization, module identity, object/root registration, frame descriptors, tail calls and continuation remain required";
    attribute cost:String="Scheme packing and validation, module-data C/object materialization, relocations, fixups, helper calls, ABI rebuilds and retained code/descriptor lifetime";
    attribute headerScope:String="37 direct quoted component includes, 526499 source bytes plus root1818 bytes; lexical census only, not configured expanded tokens or compiler time";
    attribute proofSplit:String="Existing QNT owns phase invalidation/publication schedules; existing Lean owns keys/layout and cost laws; actual layout/fixup refinement remains open";
  }

  part launchRoute {
    attribute key:String="posix-source-launch-chain";
    attribute driver:String="Installed Gerbil compiler/driver.ss:1190 invoke -> open-process -> process-status -> close-port";
    attribute gsc:String="Current vendor gsc/_gsclib.scm:544 gambuild -> lib/gambit/process/process.scm:76 run-subprocess -> _io.scm:7101 open-process-generic";
    attribute bridge:String="lib/_io.scm:7171 os-device-stream-open-process -> os_io.c:10565 conversions -> device_stream_setup_from_process:9101";
    attribute posix:String="Current vendor ordinary POSIX path forks at9156, closes child fds, uses execvp9257 and errno pipe; Linux and Darwin share this source path before configured capabilities";
    attribute contract:String="Preserve PATH versus explicit environment, cwd, fd alias/order, PTY, signal mask/defaults, child affinity and parent SIGCHLD/device-group registration, launch errors versus exit status";
    attribute retirement:String="Qualified NativeAction backend replaces fresh gsc/env/script processes used only for native dispatch; necessary compiler/linker actions remain";
    attribute baseline:String="Historical eligible spawn intervention and installed native/object reuse remain baseline; source availability is not an installed binary seal";
    attribute linux:String="Linux realization may use its cheap bulk-close/native launch path; do not force Darwin service overhead onto it";
    attribute evidence:String="D1469 actual complete-build target/parent census and fallback-positive control supersede D879 source-only uncertainty for that retained workload; D1510 startup root calls and child execution coverage remain separately scoped.";
    attribute nativeAdmitted:Boolean=false;
  }
  part fdRoute {
    attribute key:String="configured-fd-close-realization";
    attribute source:String="vendor/gambit/lib/os_setup.c:225 closefrom; os.h:352 capability selection; os_io.c:9237 caller";
    attribute priority:String="HAVE_CLOSEFROM -> HAVE_SYS_close_range -> F_CLOSEM -> descriptor-limit loop";
    attribute historicalDarwinOpenMax:Integer=1048575;
    attribute historicalDarwinScope:String="D879 host probe lacked all three bulk capabilities; not a current-host/configuration receipt";
    attribute linuxScope:String="Source can choose closefrom/close_range/F_CLOSEM when qualified; Linux is not unconditionally a successful bulk-close path";
    attribute removable:String="Preserve an eligible low-cost launch backend during C23 migration. Do not offer ordinary fork removal as new gain on D1469 retained MCP, where observed Gambit fork count is zero; a distinct uncovered path needs explicit evidence.";
    attribute retained:String="Required inherited descriptors and EOF/error-pipe behavior; PTY and bare executable with explicit child environment require qualified resolution or fallback";
    attribute failure:String="Bulk operation return and runtime availability must be handled; a configure symbol alone does not prove successful closure";
    attribute baseline:String="Already-installed eligible spawn bypass earns zero new speedup; preserve the optimized behavior during C23 migration";
    attribute sourceOnly:Boolean=true;
  }
  part bundleRoute {
    attribute key:String="conditional-darwin-module-pipeline";
    attribute eligibility:String="current-compile-static and static-path and not gerbil-toolchain-static-path; std/make enables static runtime objects for a buildspec with exe/static-exe";
    attribute darwinDriverCalls:Integer=3;
    attribute elseDriverCalls:Integer=1;
    attribute darwinGambitLaunchSites:Integer=4;
    attribute elseGambitLaunchSites:Integer=2;
    attribute darwinMetadataExtractions:Integer=2;
    attribute elseMetadataExtractions:Integer=1;
    attribute darwinSingleFileGrepPipelines:Integer=10;
    attribute elseSingleFileGrepPipelines:Integer=5;
    attribute countScope:String="Explicit source skeleton of one eligible runtime module action: Gerbil invoke plus current vendor GSC gambuild; excludes optional macro/native effects and compiler/shell grandchildren; not an observed trace or whole executable graph";
    attribute darwin:String="gsc -c -> copy static C -> gsc -obj DYNAMIC/fPIC -> env gambuild-C dyn with static object and Mach-O alias";
    attribute linux:String="Gerbil else branch invokes gsc once; GSC generates C then gambuild dyn supplies C to compile/link driver; later executable/static work remains outside this one-action comparison";
    attribute bundleSemantics:String="configure.ac selects bundle on Darwin and shared/rdynamic on other GNU POSIX targets; retain native format, relocation, symbol/alias and runtime loading semantics";
    attribute metadataPlan:String="gambuild-C.unix.in get_meta_info uses grep/sed; extract_cc_ld_options has five scan pipelines for one nonempty metadata file; object and dyn both resolve it";
    attribute retirement:String="Generator-produced BuildMetadata and distinct object/bundle actions may replace repeated transport only after actual consumer migration. Do not revive denied metadata-empty probes, terminal-exec filtering or unchanged preparation-plus-coordinator routes.";
    attribute baseline:String="One C generation/shared object/ready-runtime-C and object scheduling already implemented; -ftrack-macro-expansion=0 already in current C23 Darwin configure";
    attribute currentPlatformDeltaMeasured:Boolean=false;
  }
  part packageNativeRoutes {
    attribute key:String="two-package-mode-admission";
    attribute mcp:String="MCP build.ss has an exe main entry; selected data/embedded runtime can enter static-runtime preparation on its cold executable build";
    attribute poo:String="POO ordinary library-build-spec has no executable entry; support/rationaldict takes ordinary path. Explicit test-program/executable graphs are separate requests";
    attribute mcpBranchRequires:String="Actual runtime/phase identity, static output path and toolchain-path exclusion; no transfer to all543 historical compile-file jobs";
    attribute pooDarwinDriverCalls:Integer=1;
    attribute pooElseDriverCalls:Integer=1;
    attribute pooDarwinMetadataExtractions:Integer=1;
    attribute pooElseMetadataExtractions:Integer=1;
    attribute sharedCost:String="Both ordinary paths still use Gambit process launch and native metadata transport; a Darwin higher launch unit cost can amplify common counts";
    attribute counterevidence:String="D1469 sees zero Gambit fork; original compile-job audit pairs186 runtime producers/objects and rejects189 duplicate-compilation claims. D851 has real MCP improvement but no two-package admission. Shell substitution is existing build-only evidence; metadata-empty and coordinator routes are denied.";
    attribute gapCredit:String="No package seconds assigned from source counts. Keep net Darwin self-speedup, absolute platform gap and residual ratio separate under existing platformGap law";
    attribute noNewNativeRun:Boolean=true;
  }

  part retainedProcessEvidence {
    attribute key:String="D1469-reached-mcp-process-census";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d1469-real-process-census-and-extension-boundary.md";
    attribute scope:String="Historical complete instrumented MCP at9a5c35e, staging1cfb032/ea114fc3 runtime lineage, twelve workers; observed Gerbil/gxi/GSC parents, not shell/compiler grandchildren";
    attribute spawnp:Integer=1482;
    attribute forkCalls:Integer=0;
    attribute gscTargets:Integer=740;
    attribute gambuildTargets:Integer=553;
    attribute envTargets:Integer=186;
    attribute apiIntervalSumMicros:Integer=3711499;
    attribute prefixSpawnp:Integer=2;
    attribute prefixIntervalMicros:Integer=963;
    attribute prefixFirstCompileMicros:Integer=5934667;
    attribute fallbackControlReached:Boolean=true;
    attribute apiSumIsWallSaving:Boolean=false;
    attribute newOrdinaryForkRemovalCredit:Boolean=false;
  }

  part retainedDriverEvidence {
    attribute key:String="D1510-driver-mechanism-and-refusals";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d1510-shell-substitution-build-admission.md";
    attribute scope:String="Historical exact-driver MCP cold ABBA; source9a5c35e/GNU16, retained object reuse; metadata parsing unchanged";
    attribute originalA1Micros:Integer=66164491;
    attribute originalA2Micros:Integer=64919734;
    attribute candidateB1Micros:Integer=47211369;
    attribute candidateB2Micros:Integer=48705787;
    attribute actualGscSedOriginal:Integer=25;
    attribute actualGscSedCandidate:Integer=7;
    attribute metadataParserChanged:Boolean=false;
    attribute historicalGainIsNewCredit:Boolean=false;
    attribute allRowControllerPassed:Boolean=false;
    attribute candidateBuildOnlyGatePassed:Boolean=true;
    attribute metadataEmptyProbeAdmitted:Boolean=false;
    attribute terminalExecAdmitted:Boolean=false;
    attribute newCoordinatorAdmitted:Boolean=false;
    attribute coordinatorOriginalMeanMillis:Integer=880;
    attribute coordinatorCandidateMeanMillis:Integer=1590;
    attribute fusionProducerWaveGainBasisPoints:Integer=416;
    attribute fusionWholePackageAdmitted:Boolean=false;
  }

  part retainedStartupEvidence {
    attribute key:String="D1510-startup-root-versus-child";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d1510-startup-process-resource-boundary.md";
    attribute scope:String="Separate killed prefix diagnostics and side-channel import probes, not a complete build or all-descendant census";
    attribute rootSpawnp:Integer=2;
    attribute rootSpawnApiMicros:Integer=3125;
    attribute rootForkObserved:Integer=0;
    attribute completedImportRoots:Integer=84;
    attribute importWallMicros:Integer=4670305;
    attribute importCpuMicros:Integer=2335439;
    attribute childCoverageComplete:Boolean=false;
    attribute rootSpawnExplainsSilentWindow:Boolean=false;
    attribute importRemainderIsRemovable:Boolean=false;
  }

  part retainedReuseEvidence {
    attribute key:String="D851-and-original-job-closure";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d851-executable-graph-scoped-runtime-object-reuse.md";
    attribute scope:String="Historical independent MCP cold and POO native-warm consumers; current graph mapping is explicit rather than inferred from a package name";
    attribute mcpOriginalReverseMillis:Integer=72130;
    attribute mcpCandidateReverseMillis:Integer=60690;
    attribute mcpOriginalForwardMillis:Integer=74727;
    attribute mcpCandidateForwardMillis:Integer=59555;
    attribute pooPair1OriginalMillis:Integer=13074;
    attribute pooPair1CandidateMillis:Integer=13099;
    attribute pooPair2OriginalMillis:Integer=12076;
    attribute pooPair2CandidateMillis:Integer=12258;
    attribute twoPackageAdmission:Boolean=false;
    attribute runtimeProducerObjectPairs:Integer=186;
    attribute loggedExeObjectJobs:Integer=189;
    attribute loggedJobsAreRepeatedCompiles:Boolean=false;
    attribute ordinaryPooEnteredStaticReuse:Boolean=false;
  }

  part metadataProduct {
    attribute key:String="BuildMetadata-single-producer";
    attribute producer:String="Scheme target emitter seals ordered metadata with GeneratedCResult; the legacy script is a consumer, not a second source of truth";
    attribute parsedKey:String="Exact metadata projection, emitter/format identity and legacy feature language; C payload-only edits need not change this key when the emitter proves projection fidelity";
    attribute resolvedKey:String="Parsed key plus feature map, role, explicit option overlays, full environment/cwd and actual pkg-config/tool/input/effect closure";
    attribute roleProjections:String="Separate obj/dyn/exe projections retain option ordering, aliases, outputs and legacy conditional semantics; never share final argv unchanged across roles";
    attribute kept:String="Required metadata evaluation and query effects, warnings/failure categories, supported wrappers/compound recipes and unsupported-input refusal";
    attribute retired:String="Whole-C grep/sed extraction and command reconstruction on migrated service paths; no metadata omission and no simple5-to1 grep probe";
    attribute cost:String="Producing/validating structured data, query closure, per-role rendering and lifetime; opaque queries cannot become free cache hits";
    attribute failure:String="No valid metadata product on partial/error/unknown generation. Unknown external effects reject reuse or use one original fallback, never both preparation routes";
    attribute evidence:String="0015 actual trace isolates substitution with parsing unchanged; empty-metadata extension and terminal exec remain rejected; no measured BuildMetadata gain";
  }

  part pipelineProduct {
    attribute key:String="NativePipelinePlan-replaces-not-wraps";
    attribute producer:String="Existing Gerbil phase planner consumes immutable GeneratedCResult/BuildMetadata and one normalized EffectiveConfig/CapacityPlan";
    attribute nodes:String="ObjectCompile and required BundleLink/ExecutableLink are distinct actions with exact inputs, argv/env/cwd/fd/signal context and output identities";
    attribute ordering:String="Generator seals metadata -> role resolution -> native action readiness -> known terminal and validated products -> complete consumer manifest";
    attribute retired:String="Migrated C-input native roles no longer call GSC-obj/env/gambuild only to reconstruct a native command; public legacy CLI/fallback consumers remain Simple old GSC producer fusion already measured only about4.16 percent on producer waves in D1416 and has no major package admission.";
    attribute baseline:String="Keep existing spawn behavior,0015 substitutions, runtime-C/object reuse and object scheduling; none supplies new credit";
    attribute noCoordinatorWrapper:String="Do not run old configured preparation and add independent rediscovery/coordinator checks;0.88-to1.59s route is denied";
    attribute inputSnapshot:String="Full source/header/compiler/cc1/assembler content, original source spelling, cwd/env and actual tool selection are bound; preprocessing alone does not bind compiler environment";
    attribute publication:String="Failed/cancelled/unknown actions retain custody; no partial public group manifest. Private immutable products are not accepted consumer results";
    attribute cost:String="One validation/discovery owner where equivalent, exact action work, storage/roots and interactions all charged; fixed resource/watchdog contracts unchanged";
    attribute gain:String="New gain requires actual removed duties beyond retained fixes; no summing historical cohort deltas or component ratios";
  }

  part pipelineInvalidation {
    attribute key:String="projection-invalidation-and-retirement";
    attribute cPayload:String="Changed C with identical sealed metadata invalidates native code actions and descendants, not unobserving parsed metadata";
    attribute ccOptions:String="CC options or compiler/tool/env/cwd/header changes invalidate affected object actions and dependent bundle/link; preserve semantic generation only if unobserved";
    attribute ldOptions:String="LD-only changes invalidate affected link/bundle projection; pkg-config cflags/libs changes propagate according to actual consumed role";
    attribute abi:String="Target/module/frame ABI changes invalidate all affected generation/native/descriptor consumers; filename equality is never authority";
    attribute queries:String="Changed lookup/negative lookup/features/external query dependencies invalidate resolved metadata and dependent actions; opaque effects refuse reuse";
    attribute continuation:String="Compilation sessions keep owned mutable instances; immutable plans are not cached live expander/optimizer objects or test verdicts";
    attribute completionRule:String="Known complete outputs only; duplicate/late response cannot authorize new generation; unknown completion never releases ownership or publishes a false HIT";
    attribute retirement:String="Remove an old caller only after all its real role/mode/error consumers use the new authority and preserve original output/context/failure controls";
    attribute sharedSupport:String="Reuse the existing typed capability, source identity, snapshot, process and budget supports; no new runner, coordinator framework or parallel cache system";
  }

  part childImportCost {
    attribute key:String="build.ss-child-import-accounting";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d1510-startup-process-resource-boundary.md";
    attribute cohort:String="Separate gxi -L original build.ss side-channel probe; 84 completed outer imports; shared recursion guard; first-log denied, not complete-build timing";
    attribute importWallMicros:Integer=4670305;
    attribute importCpuMicros:Integer=2335439;
    attribute evaluatorWallMicros:Integer=312662;
    attribute evaluatorCpuMicros:Integer=232321;
    attribute compilerWallMicros:Integer=101913;
    attribute compilerCpuMicros:Integer=53099;
    attribute unattributedCpuMicros:Integer=2050019;
    attribute callbackEntriesEach:Integer=5594;
    attribute readerSeparateRun:String="84 files/1062 forms; validated reader-only wall45457us CPU42930us; separate warm-cache run, not subtractable exclusive time";
    attribute remainderIsExpansionTimer:Boolean=false;
    attribute remainderIsSaving:Boolean=false;
    attribute nativePhaseReplacementAdmitted:Boolean=false;
    attribute costBoundary:String="Import read/expand/resolve/execute and probe overhead remain mixed. Native positive-phase bodies already reused; no 12-worker multiplication or pure dyld allocation.";
  }

  part interfaceProduct {
    attribute key:String="SealedInterfaceProduct-query-and-fresh-instantiation";
    attribute producer:String="Existing Gerbil interface emitter derives dependency projection and ordered construction program from successfully expanded module, not a second independent parser";
    attribute consumers:String="std/make module-id, build-coordinator, build-dependent?, consider/wait-for consume projection; actual compile-module/import-module instantiate required live interfaces";
    attribute identity:String="Source/reader/prelude/expander/provider/declaration identities, positive and negative dynamic reads, phase, search order, ABI and effects; opaque untracked capability rejects reuse";
    attribute projection:String="Canonical module id, nested-root mapping, phase-labelled import/export/reexport dependency edges and output roles; not live module-context/import records";
    attribute construction:String="Keep fresh context/mark/binding/import records, ordered first-stage effects, deferred export resolution, positive-phase eval and delayed atomic module body; sealed syntax alone is insufficient";
    attribute stages:String="MISS -> owned expansion -> close dependency/effect trace -> seal -> publish known immutable product; HIT -> validate snapshot -> query projection or private instantiation; changed or opaque inputs invalidate/refuse";
    attribute retirement:String="Only qualified graph-only import/mx calls and repeated generic SSI preparation can retire; source-dependent macro execution, fresh live instance work and actual native misses remain";
    attribute failure:String="Failed/unknown expansion publishes no reusable product; old owner retains private state. Late/duplicate delivery is keyed to request generation; no rerun of effects on ambiguous completion";
    attribute sessionParallelism:String="One product may feed independent private sessions; current import/driver locks remain until all mutable alias and initialization ownership obligations close; no assumed 12x scaling";
    attribute cold:String="All-miss build pays producer and sealing cost; prebuilt SDK product is a declared warm input, not clean-cold savings. Build.ss own imports/effects remain unless separately qualified.";
    attribute c23Boundary:String="Gerbil owns phase semantics and queries; Gambit _front compile-frontend and target state require private contexts; C23 owns publication, GC-updated roots and native lifetimes, not Scheme effect purity";
    attribute refutations:String="No shared initialized context (72.213895s denied), no record sharing/deletion, no raw AST/native-phase serialization, no declaration-count gain or quoted SSI bypass";
  }

  part sharedDispatchFactory {
    ref part interfaceContract=GambitDarwinAcceleration::interfaceProduct;
    attribute record:String="evidence/research/retained/darwin-acceleration/shared-dispatch-factory.json";
    attribute producer:String="Gerbil core contract.ss Interface::defdispatch-rule; one make-dispatch-transformer compiled in core, method-specific signature/body/lift use existing hygienic syntax template constructors; raw quote-syntax is rejected";
    attribute identity:String="Fresh generated placeholder matched by free-identifier equality across quoted contexts; lexical identifiers retained, compound syntax reconstructed per expansion";
    attribute existingConsumer:String="with-dispatch-arguments retains positional/optional/keyword/rest validation and evaluation order; checked and unchecked method procedures remain";
    attribute workRemoved:String="Per-method repeated generated defrules matcher programs; actual emitted work and critical-path reduction must be measured, not inferred from source bytes";
    attribute addedCost:String="One core matcher factory, per-method closures and hygienic syntax constructor code/data, fresh substitution per expansion. No guaranteed cold-time or Darwin-specific saving";
    attribute focusedEvidence:String="Complete module syntax and focused optional/rest/keyword/lift/single-evaluation/hygiene checks PASS. Initial placeholder mismatch and full stage1 unbound __string-index at87.683798s retained. Corrected def/c/private binding full-module import and gxc-S PASS; full compiler/native/package equivalence remains OPEN; corrected full stage1 TIMEOUT600.121671s, partial outputs withdrawn";
    attribute qntExclusive:String="Existing preparation/session publication and unknown-completion histories only; do not duplicate value-level syntax equivalence as a toy state machine";
    attribute leanExclusive:String="Fresh-placeholder substitution, source/binding preservation and expansion equivalence require source refinement; OPEN, not inferred from focused tests";
    attribute admission:String="Rebuild same-source core and full compiler; original interface/MCP/POO tests; matched package timing under unchanged budgets. No current twofold claim or merge";
    attribute twofoldEstablished:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }

  part staticLinkPreparation {
    ref part pipeline=GambitDarwinAcceleration::pipelineProduct;
    attribute record:String="evidence/research/retained/darwin-acceleration/static-link-preparation.json";
    attribute actualCaller:String="build-bach.ss sends42 ordered static SCM inputs to one gsc-link. gsi/main.scm loops do-compile-file-to-target before metadata linking; native object jobs are queued only afterward";
    attribute product:String="StaticModuleProduct binds SCM, macro/include, generator, mode/module naming, profile/target and ModuleSpec/FrameSpec identities to complete C plus link metadata";
    attribute refactor:String="Existing private compile jobs produce sealed module products; LinkPlan consumes their original ordered set. Missing/stale products schedule an explicit producer, never hidden serial SCM compilation inside linking";
    attribute retirement:String="Raw-SCM link input retires only after C/link-info equivalence, original ordered initialization and frame/root fidelity, failure custody, full compiler and both original packages pass";
    attribute qntExclusive:String="Existing native artifact partition/publication histories cover joins, late/unknown completion and link admission; concrete42-input refinement OPEN";
    attribute leanExclusive:String="Source-level target/link-info equivalence, ordered-link semantic result and ModuleSpec/FrameSpec fidelity plus net-span algebra; OPEN, not replaced by key-invalidates proofs";
    attribute netBoundary:String="Cold generation still happens; parallel setup/publication costs must be deducted. Warm generation disappears only on exact hits. Dynamic C is not assumed reusable as static C";
    attribute evidenceLimit:String="Snapshot confirms one GSC and no matching GCC at that instant. No phase duration, whole600s attribution, package twofold gain or Darwin-specific delta is established";
    attribute implemented:Boolean=true;
    attribute producerImplementation:String="Isolated darwin src/build/build-bach.ss writes a typed StaticModuleProduct plan with original ordered source/argv sets; old raw-SCM native link loop removed";
    attribute sharedImplementation:String="gambit_smp.gerbil_build _stage1_static/_static_products/_static_link_product; existing ctx processes, journals and atomic cache installation; no separate runner";
    attribute actualReuse:String="Per-source C keys and ordered metadata LinkPlan keys require authenticated completion witnesses and matching byte digests. Unknown process completion cannot publish. Whole stage deadline remains600s";
    attribute nativeControl:String="Real single module serial/split byte equivalence PASS. Full42 C producers, ordered metadata link,43 native objects and actual core consumer PASS. Exact retained42-product warm request:42 hits plus link hit, zero producer processes,0.455145s; prefix bytes unchanged. Stdlib TIMEOUT600.874s; complete compiler and both package gates OPEN";
    attribute executionOwner:String="darwin-acceleration; independent source-only handoff complete; old repair-9-12 Darwin artifacts are historical references, not shared execution ownership or native product qualification";
    attribute durationDiagnostic:String="Temporarily uncapped stdlib run stopped by user after reported memory exhaustion. No completed duration or measured memory peak;56 orphan processes stopped and original group empty. Temporary uncapped-stage extension removed";
    attribute nativeResumeCondition:String="Independent source/product custody plus aggregate child-tree memory admission, peak attribution and descendant drain after supervisor/driver death; OPEN. No native retry from this diagnostic";
    attribute sourceProductGap:String="SCM embeds compile timestamp and quoted gensym identity. Fresh expansion can invalidate byte products; timestamp normalization is not admitted. Package gxc and stdlib do not yet publish qualified stage products";
    attribute measuredBoundary:String="Current42-product cold spans: prepare263.684s, C generation94.336s, metadata0.998s, native objects53.490s. No matched serial baseline or package gain; process-time sums are not wall savings";
    attribute conservativeCosts:String="Native objects always rebuild until include closure seals. Provider hashes whole plan-producer/framework files, so their edits conservatively invalidate all C products; finer factoring OPEN";
    attribute twofoldEstablished:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }

  part darwinExecutionAdmission {
    ref part products=GambitDarwinAcceleration::staticLinkPreparation;
    attribute task:String="darwin-acceleration";
    attribute sourceContract:String="Independent Gerbil and Gambit repositories, both darwin branches; content manifests override skip-worktree visibility. Source-only transfer excludes native artifacts and Git alternates";
    attribute sourceEvidence:String="evidence/research/retained/darwin-acceleration/execution-admission.json";
    attribute sourceBytesTransferred:Boolean=true;
    attribute resourceInterface:String="workspace process-run --rss-limit-bytes; one union of all groups in the exact task/run journal. process_identity groups_memory uses native kernel census, birth checks and RSS; recipe process capture supports a per-group guard";
    attribute resourceSemantics:String="250ms sampled RSS, shared pages conservatively double-counted; maximum observed census sum is not a simultaneous snapshot or OS hard bound. Unreadable live data refuses; inter-sample spikes and unregistered sessions remain outside proof";
    attribute memorySchedulingGap:String="Native Make capacity now intersects CPU slots and total-minus-parent/job reservation through existing Stages adapter; no second scheduler. Unknown job reserves available child budget. Single GCC exceeded that reservation, so actual-use <= reservation premise is REFUTED for this configuration; not safe scheduling proof";
    attribute prerequisiteEvidence:String="evidence/research/retained/darwin-acceleration/compiler-prerequisite-memory.json";
    attribute prerequisiteStatus:String="Three-flag C23 configure PASS;12-job and exclusive1-job seed attempts resource-refused at unchanged3GiB envelope. Source-regenerated core, complete compiler and original packages NOT RUN. NativeRequest producer integration remains unimplemented";
    attribute cleanup:String="Freeze the driver, stop only same-boot birth-attested registered groups, retain unknown births unresolved, reap the driver. A normal driver exit with detached groups returns125 rather than admitting results";
    attribute sourceDiscovery:String="Six generated C source inputs were hidden by skip-worktree; Git diff alone failed exact snapshot equivalence and was rejected. Complete content manifests preserved them explicitly";
    attribute qntModel:String="dev/architecture/toolchain/models/quint/compile_resource_admission.qnt";
    attribute qntExclusive:String="Registration closure, sampled total versus per-group checks, close/signal/drain ordering, reused birth and root-only cleanup counterexamples. No claim of an OS memory bound";
    attribute leanModel:String="dev/architecture/toolchain/models/lean/CompilerBuildBatch.lean";
    attribute leanExclusive:String="Pointwise joint-budget arithmetic and counterexamples to independent budgets and future-value inference. Native census, birth and pointer refinement remain OPEN";
    attribute currentControls:String="Native small Python group limit, unreadable RSS, reused birth, timeout drain, detached driver and shared nested-session budget controls; compiler/package admission separate";
    attribute componentEntry:String="darwin-execution-admission.recipe.json: complete component graph of integration-model, batch-closure-values, resource-temporal and component-boundary";
    attribute wholeEntry:String="Original acceptance-boundary remains intact. Full run stopped at global-capacity-values after sampled RSS exceeded1GiB; no whole-chain PASS";
    attribute nativeExecutionAdmitted:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }

  part darwinSchemeStageProducts {
    ref part producer=GambitDarwinAcceleration::staticLinkPreparation;
    ref part admission=GambitDarwinAcceleration::darwinExecutionAdmission;
    attribute sourceEvidence:String="evidence/research/retained/darwin-acceleration/stdlib-stage-products.json";
    attribute callers:String="std/make.ss gxc-compile:503-518 and gerbil/gxc-main.ss:200-204 reach compiler/driver.ss compile-module:100-136; shared native boundary compile-scm-file:787-804 -> gsc-compile-file:881-886";
    attribute sourceBundle:String="PreparedSchemeProduct contains exact generated SCM/SSI/static/optional-SSXI bytes and required manifest, one generation-wide timestamp and binding map, source/macro/context/provider/profile closure. These are proposed data contracts; no source-stage cache hit is admitted yet";
    attribute nativeRequest:String="NativeCompileRequest seals executable, argv, cwd, environment capability, phi/runtime role, canonical source/output identities, generation receipt and resource profile before enqueue. Mutable parameter-list aliases must be copied or closed; thread inheritance is not proof of immutable closure";
    attribute existingSemantics:String="make-compile-job creates threads while compile parameters are bound. Gambit macro-thread-init inherits denv-local from parent, so delayed starts alone do not imply lost dynamic parameters. Cross-process transport must explicitly preserve this binding";
    attribute timestamp:String="driver.ss:129,679 and base.ss:198-207/compile.ss:832-860 link timestamp to runtime payload and quoted symbol identity. Restore a whole proven generation bundle, never erase timestamp or mix fresh SSI with old phi/SCM. Equal seconds are not a generation key";
    attribute readiness:String="std/make completion is currently posted after build returns; pending GSC jobs drain after make-build. Replacement must distinguish private import/expansion readiness, generated-bundle readiness, phi load readiness and runtime/static readiness; actual consumers determine edges";
    attribute resourcePlan:String="Parent memory reserve plus per-job credits <= total budget. Unknown profile refuses launch; unknown completion keeps credit and custody until process-group drain is proved. Current sampled excess abort is a guard, not this scheduler implementation";
    attribute observedMemory:String="Aborted-stop snapshot maps GCC RSS2,565,652,480 bytes and1,451,360,256 bytes to ensemble/network/connection~0 and~1 SCM requests. Snapshot only, not measured peak or calibrated bound; no timing/performance transfer to packages";
    attribute qntModel:String="compile_resource_admission.qnt main compile_stage_products; whole-bundle sealing, cohort matching, joint reserve/unknown outcome/drain histories and negative controls. Two roles abstract variable source output sets, not a literal two-output compiler";
    attribute leanModel:String="CompilerBuildBatch.lean Gambit.CompilerStageProducts: whole-cohort binding/payload equality and conditional actual-use <= reservation algebra. Source extraction and measured memory bounds remain independent OPEN premises";
    attribute componentEntry:String="darwin-execution-admission.recipe.json evaluates the complete shared source/resource component graph; full integration and original package gates remain separate";
    attribute retirement:String="Retire executable closures as native job transport only after frozen-request equivalence. Retire mtime-only source reuse authority only after dynamic dependency/phase-effect closure. Remove raw-SCM hidden link generation only per qualified consumer; do not remove Scheme semantics or original error behavior";
    attribute implementationReady:Boolean=false;
    attribute compilerPassed:Boolean=false;
    attribute twofoldEstablished:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }

  part interfaceProofAndBenefit {
    attribute key:String="interface-products-obligations-and-differential-credit";
    attribute qntExclusive:String="Existing incremental/preparation models: miss/hit/refuse, dependency change vs publication, duplicate/late/unknown completion, private-session admission and bounded ownership. Concrete interface product refinement OPEN.";
    attribute leanExclusive:String="Projection soundness, nested/phase edge normalization, fresh-instance observational equivalence, dependency-closure fidelity and critical-path net-removal algebra. No duplicate temporal state machine; source equivalence OPEN.";
    attribute ascentExclusive:String="Join typed SysML scopes and curated historical facts to source hashes; reject missing evidence, promoted timing, shared-gain-as-Darwin-proof and current-native success. Equality checks are not causal proof.";
    attribute c23Synchronization:String="Immutable payload initialized before release publication; acquire consumer pins storage before use; dependency snapshot revalidation shares publication linearization; GC roots and descriptor leases survive unknown completion. No relaxed-only flag or raw-pointer acquisition proof.";
    attribute darwinMechanism:String="Omit the same eligible child preparation calls rather than move them earlier; any proven higher Darwin per-call cost disappears with those calls. Existing evidence does not identify the matched Linux per-call excess.";
    attribute netCondition:String="For a fixed scenario DAG, saved critical span minus validation/instantiation/retention/publication span must be positive; twice-fast requires net removal >= current qualified D0/2, with baseline optimizations deducted.";
    attribute gapCondition:String="With measured gains gD,gL and original times D,L, ratio shrinks iff gD/D > gL/L; a common saving is not automatically Darwin-specific relief.";
    attribute allMissReuseSavingGuaranteed:Boolean=false;
    attribute twofoldEstablished:Boolean=false;
    attribute darwinGapReductionEstablished:Boolean=false;
    attribute currentC23NativeAdmitted:Boolean=false;
    attribute migration:String="Seal emitter contract -> qualified planning projection -> fresh interface constructor -> independent private-context admission -> remove each replaced old caller after role/error/continuation equivalence, no old+new double preparation";
  }

  part packagePriority {
    attribute key:String="whole-package-twofold-primary-native-distribution";
    attribute primary:String="Broad C23 producer/runtime contract refactor across ordinary runtime and phase modules: CodePlan plus ModuleSpec/FrameSpec/LiteralImageSpec, compiled common cold helpers, stage-keyed native products and exact NativePipelinePlan. Not a header-only patch or single string-module optimization.";
    attribute secondary:String="Interface construction and dependency projections support prefix/graph readiness and incremental hits; they do not replace the broad compile-distribution mainline.";
    attribute evidence:String="D855 diagnostic and D858 adjacent package negative result; historical cohorts, not current C23 timing or a new gain.";
    attribute historicalWholeMicros:Integer=74671000;
    attribute historicalCompileJobs:Integer=543;
    attribute historicalCompileIntervalMicros:Integer=636536000;
    attribute historicalWorkers:Integer=12;
    attribute historicalTargetMicros:Integer=37335500;
    attribute historicalMinimumJobIntervalRemovalMicros:Integer=188510000;
    attribute historicalGraphEndMicros:Integer=40054000;
    attribute historicalLastCompileMicros:Integer=68718000;
    attribute historicalDrainEndMicros:Integer=73823000;
    attribute historicalLateMeanOccupancyHundredths:Integer=1189;
    attribute schedulingAloneSufficient:Boolean=false;
    attribute singleEmbeddedJobSufficient:Boolean=false;
    attribute interfaceOnlyTwofoldEstablished:Boolean=false;
    attribute baselineDeduction:String="D855 predates later loader and driver improvements. Do not transfer its543 jobs,636.536 worker-s or188.510 threshold to current remaining work; retain0015,187 pure loaders and existing C/object reuse before assigning new credit.";
    attribute currentNativeBudget:String="OPEN: disjoint current MCP and POO stage costs and native critical paths after retained optimizations; no new fixed percentage claimed.";
    attribute coldPriority:String="All-miss builds need shorter unavoidable native production across the distribution, not a cache-HIT story. Stable data ABI must replace emitted common C duties while retaining hot GVM semantics.";
    attribute incrementalPriority:String="Validated semantic/code/data/binding/native/link projections can omit equal-key stages; shared macro, observed reader/effects or ABI changes invalidate actual consumers.";
    attribute darwinPriority:String="Bind omissions or shorter compiler actions to the actual Darwin frontend/bundle/driver realization; Linux also benefits and the per-platform fractional net savings still need attribution.";
  }

  part constructorCallers {
    attribute key:String="generic-interface-preparation-versus-required-instantiation";
    attribute startup:String="build.ss top-level imports precede std/make scheduling. core-import-module(module.ss139) -> core-read-module -> new module-context -> core-expand-module-begin168 -> delayed eval/registry. A graph-only HIT cannot remove these entry imports.";
    attribute genericDispatch:String="module.ss633-645 -> core-expand-head; module.ss702-705 -> core-expand-block(core.ss296), K327 head expansion -> identifier resolution/special-form classification -> expand-special/core-expand-top. core.ss281 stop predicate can observe live bindings; no unguarded terminal-result transfer.";
    attribute deferred:String="module.ss678-700 expands expressions and resolves exports after first-stage bindings. Constructor emits equivalent ordered operations with original diagnostics/source/context identity; not every macro is executed twice.";
    attribute needed:String="module.ss840-872 fresh retained import records, core-bind-import! and positive-phase eval remain. Properties/callbacks and delayed module evaluation are observable; factory cannot replace them with cached live objects.";
    attribute planning:String="std/make.ss238-248 module-id and306-335 coordinator/dependent traversal may consume validated graph projection; current registry already shares contexts, so repeated callers are not repeated full expansions.";
    attribute privateBinding:String="Factory dispatch targets and primitive/provider identities are snapshot-bound. Rebinding, macro callbacks, exceptions and continuation recovery invalidate eligibility or preserve original resolution; compiled direct handler calls require capability equivalence.";
    attribute coldEffect:String="Matching prebuilt interface program may avoid generic SSI preparation but still owes live instantiation; full factory MISS adds its own generation/load/validation. No complete prefix elimination.";
    attribute incrementalEffect:String="Only graph-only consumers and unaffected stage products can skip live work; real expansion consumers still instantiate required executable support. Build.ss own startup imports remain until independently qualified.";
    attribute dispatchTimeKnown:Boolean=false;
    attribute planningImportTimeKnown:Boolean=false;
    attribute startupAndPlanningClocksAdditive:Boolean=false;
  }

  part wholeRequestRefinement {
    attribute key:String="source-to-model-obligations-not-file-association";
    attribute qntMapping:String="Existing preparation_reuse admit/pinView/beginProducer/unknownProducer/canSeal maps to selected input snapshot, currentness admission, private factory production, unknown custody and sealed product; actual source refinement remains OPEN. Startup imports and planner queries are separate consumers.";
    attribute qntSafety:String="Before HIT omission: complete observed input closure and effect permission; before factory delivery: ordered fresh context complete and roots installed; on dependency change invalidate all selected consumers; no valid output on unknown/failure; duplicate delivery never reruns initialization.";
    attribute qntNonAssumptions:String="No assumption that a completed expansion is pure, timestamps are stable content, all source callbacks are intercepted, or a registry lookup implies another expansion. QNT explores temporal choices, not source evaluator equivalence or timing.";
    attribute leanMapping:String="DevelopmentBenefit.singleStageCannotDouble/additionalRemovalForTwofold/twofoldAcceleration own one-unit whole-request accounting. Constructor lemmas must prove dispatch replacement, two-stage effect/export trace equivalence, phase/nesting edge fidelity and fresh identity/root preservation.";
    attribute leanOpen:String="Need a source-derived ordered operation trace and relation between old ModuleContext/import records and private factory instance, including handler rebinding, exceptions and multi-shot continuation. A string declaration or ASCENT equality is not this proof.";
    attribute c23Composition:String="Root publication before collecting calls, release product publication and pinned acquire, descriptor/code retention through continuation and unknown completion; these are source/native obligations, not proved by language-standard selection.";
    attribute benefitComposition:String="Use a single case DAG and same metric: net removed critical span includes interactions and all added costs. Worker intervals constrain capacity; they are never added to prefix wall savings or treated as exclusive compiler CPU.";
    attribute ascentChecks:String="Join historical capacity and refusal fields, typed priority/consumer scope and exact source identities; deliberately reject promoting historical543 into current duplicate jobs, prefix-only2x, occupancy-to-CPU or missing current timing to PASS.";
    attribute currentTwoPackageNativeQualified:Boolean=false;
    attribute currentPositiveSpeedupProved:Boolean=false;
    attribute mainlineDecision:String="Research priority is broad native distribution and early readiness together. Interface factory cost attribution is a subordinate open obligation, not permission to delay the primary C23 emitter/runtime contract design.";
  }

  part commonDutyAccounting {
    attribute key:String="already-shared-runtime-versus-new-code-generation-work";
    attribute sharedFixup:String="setup.c1742 setup_module_fixup already handles module table alignment, global creation, symbol/keyword setup, constant graph fixrefs and labels/OFD; setup_modules2214 invokes common passes. Zero new credit for moving these same loops into another shared helper.";
    attribute generatedResidual:String="_t-c-1.scm2191 targ-dump-mod emits primitive/global assignments, optional opaque C init, descriptor/linker entry and configuration-dependent symbol/key stores; module_generation.h.in1352-1402 supplies actual expansions.";
    attribute required:String="Actual module identity/data/roots/fixups, ordered primitive/global stores, user C init, live Scheme module initialization, host label addresses, RETI/OFD roots, tail-call and continuation semantics remain.";
    attribute kernelConsumer:String="setup_module_collect_moddescrs calls setup_mod; _kernel.scm init-mod invokes module->init_mod. Sharing code does not remove these runtime effects.";
    attribute candidate:String="Remaining unrolled setup stores can be represented as BindingPlan data and shared loops; compiler packing/descriptor representation and metadata transport are separate candidates with their own keys and costs.";
    attribute notEliminated:String="A table-driven loop still executes per-module stores and relocations; descriptor bytes and unique procedure bodies do not disappear. Opaque native init is retained/refused, not inferred pure.";
    attribute alreadySharedFixupIsNewGain:Boolean=false;
    attribute setupOnlyTwofoldSupported:Boolean=false;
    attribute coldMechanism:String="Only genuinely reduced generated/native frontend representation work counts on an all-miss build. Product construction and shared runtime build/loading are charged to their actual baseline/cache scenario.";
  }

  part ordinaryModuleCoverage {
    attribute key:String="hash-matched-static-artifact-partition-not-time";
    attribute method:String="Disjoint UTF-8 byte intervals [0,BEGIN_M_COD),[BEGIN_M_COD,BEGIN_LBL),[BEGIN_LBL,BEGIN_MOD_PRM),[BEGIN_MOD_PRM,EOF); anchored unique line markers. No preprocess or compiler executed.";
    attribute pooBytes:Integer=179814;
    attribute pooPrefixBytes:Integer=47676;
    attribute pooCodeBytes:Integer=99326;
    attribute pooFrameBytes:Integer=23779;
    attribute pooSetupBytes:Integer=9033;
    attribute pooPrimitiveStores:Integer=24;
    attribute pooGlobalStores:Integer=24;
    attribute pooSymbolRows:Integer=35;
    attribute pooKeywordRows:Integer=5;
    attribute mcpBytes:Integer=11425281;
    attribute mcpPrefixBytes:Integer=11400710;
    attribute mcpCodeBytes:Integer=19718;
    attribute mcpFrameBytes:Integer=3756;
    attribute mcpSetupBytes:Integer=1097;
    attribute pooScope:String="Existing rationaldict static C, SHA afc661c4be9baaef17300e02db52f1b14ec06be5203f5f2788a3c23f2ad0a61d; historical unqualified artifact, no current C23 binary acceptance.";
    attribute mcpScope:String="Existing embedded runtime C, SHA65f215e0e4e58c7e22b1be8214ee929295f1051b5318d9056797bedd63e5b8d0; same scope limitation. Not representative ordinary-module mix.";
    attribute interpretation:String="POO setup tail is about5.02 percent of C bytes and includes required data/entry; procedure region about55.24 percent, label/frame region13.22 percent and prefix26.51 percent. No bytes-to-time or same-cost-per-macro conversion.";
    attribute byteShareIsTimeShare:Boolean=false;
    attribute setupTailEntirelyRemovable:Boolean=false;
    attribute allProcedureCodeIsCommon:Boolean=false;
  }

  part quantitativeTargetGate {
    attribute key:String="twofold-coverage-threshold-and-baseline-deductions";
    attribute accounting:String="For one actual disjoint critical-path partition T=U+C and Tnew=U+Cprime+A, >=2x iff C>=U+2*Cprime+2*A. C is covered critical-path time, not all native interval occupancy or source bytes.";
    attribute idealLocalTwofoldRequiredCoveragePercent:Integer=100;
    attribute idealLocalThreefoldRequiredCoveragePercent:Integer=75;
    attribute idealLocalFourfoldRequiredCoveragePermille:Integer=667;
    attribute idealInfiniteLocalRequiredCoveragePercent:Integer=50;
    attribute coverageScope:String="Necessary thresholds at zero added cost and unchanged uncovered span;4x exact threshold2/3,667per-mille is rounded up. Real validation/load/runtime/data-fixup cost raises thresholds. These are design conditions, not predicted local speedups.";
    attribute d855NecessaryRemovalMicros:Integer=188510000;
    attribute d855Scope:String="Historical fixed543-job/12-worker pool only; later187 pure-loader elimination,0015 substitution and C/object reuse already deducted from any current new credit. Do not transfer the threshold to current residual jobs.";
    attribute currentGainInterval:String="No finite positive saving bound inferred from these data; zero new proved seconds is not an upper bound. Current cold/incremental critical-span weights and local speedups are unbound; overhead can cause regression.";
    attribute combination:String="Cold: native frontend representation reduction across ordinary modules + phase release + qualified pipeline/link retirement. Incremental: equal-key semantic/C/object/bundle/link omission adds a separate source of removal. Sum only disjoint spans in one scenario DAG.";
    attribute retirement:String="After exact ABI/FrameSpec/GC/continuation/module-init and native role equivalence, remove only covered emitter/header responsibilities and old query/transport callers. Already-shared fixup loops remain authoritative.";
    attribute qntObligation:String="Existing preparation_reuse and native readiness models own matching/miss/refuse/publication/retirement interleavings. Concrete BindingPlan store progress and partial-init failure mapping remains OPEN; byte census supplies no action-duration guards.";
    attribute leanObligation:String="Existing singleStageCannotDouble, twofoldAcceleration, couplingThreshold and additionalRemovalForTwofold own benefit algebra. Need source-level old unrolled stores vs private plan interpreter equivalence and critical-span partition fidelity; not a duplicate QNT state machine.";
    attribute ascentObligation:String="Join actual static artifact hashes/partition/counts and source consumer anchors; reject already-shared-loop credit, byte-to-time conversion, setup-tail deletion and current-native/twofold promotion.";
    attribute currentTwofoldForecastSupported:Boolean=false;
  }

  part ordinaryCompilerTiming {
    attribute key:String="D859-D860-ordinary-native-timers";
    attribute report:String="../../patches/gerbil-v19-darwin/receipts/d859-mcp-broad-tail-and-gsc-batch.md";
    attribute cohort:String="Historical instrumented GCC16 report on real howto-verify~0.c from D858 baseline;0.39 reported compiler seconds. Timer column/raw pass breakdown not retained in this report; not current C23 or package wall time.";
    attribute reportedTotalMicros:Integer=390000;
    attribute reportedParsingMicros:Integer=100000;
    attribute reportedPreprocessingMicros:Integer=60000;
    attribute reportedOptimizationGenerationMicros:Integer=290000;
    attribute preprocessingIncludedInParsing:Boolean=true;
    attribute ordinaryPreprocessingPrimarySupported:Boolean=false;
    attribute preciseMacroExclusiveCostKnown:Boolean=false;
    attribute allOrdinaryModulesHaveSameSplit:Boolean=false;
    attribute idealNoPreprocessResidualMicros:Integer=330000;
    attribute idealNoParsingResidualMicros:Integer=290000;
    attribute backendRemovalNeededForLocalTwofoldMicros:Integer=195000;
    attribute timerCaveat:String="Rounded instrumented report values support sensitivity algebra only; no transplant to POO, all543 jobs, current source or Darwin/Linux ratio. Optimization/generation remains aggregated.";
    attribute negativeEvidence:String="D860 exact IFD folding153/1222 sites has no material win; D861 PCH invalid dueGLOCOUNT; D871 ordinary STR8 packing no stable gain; D859 naive multi-inputGSC0.78->1.01s rejected.";
  }

  part nativeCodePlanCut {
    attribute key:String="ExplicitNativeCodePlan-at-GVM-to-C-boundary";
    attribute producer:String="_gvm.scm bbs-purify already cascades/dead/common cleanup -> _front target.dump -> _t-c-1 targ-dump-prc1854/targ-dump-cod2063/targ-begin-cod2129 -> _t-c-2 instruction emitters -> configured native compiler.";
    attribute hostShape:String="stack_operations.h.in HOST_PROC/BEGIN_M_COD/BEGIN_P_COD/BEGIN_COD selects host function and D_ALL/R_ALL/W_ALL resources; configuration.h.in label-count limits select whole-module/procedure shape and host optimization attributes. Actual active profile remains a separate input.";
    attribute edgeSemantics:String="targ-gen-jump1318 computes nargs, frame update, polling and stack adjustment before JUMPINT/JUMPRET/global/generic transfer; labels.h.in JUMPINT assumes same-host goto in single-host mode. No blind function split.";
    attribute contract:String="Plan seals canonical GVM blocks, typed control-transfer edges, nargs/entry mode, frame and safepoint root descriptors, label-to-host ordinal map, resource read/write sets, source diagnostics, target/host-attribute policy and C/native role keys.";
    attribute normalization:String="Use domain-known CFG facts before C to omit proven redundant blocks/check/representation work. Existing cleanup is baseline; historical next-label>300 guard misses sparse cases, but actual workload reachability/frequency and cost are unknown.";
    attribute hostPolicy:String="Make host/resource/label layout explicit. Current topology is a valid zero-gain control; different partitions need precise group unions and no unqualified hot cross-host transfer. Unweighted256-label grouping with conservative resources is denied by D1434.";
    attribute notEnough:String="Printing equivalent expanded C, renaming macros, moving existing shared fixup loops or sealing the plan alone saves no proven optimizer work. Byte/instruction counts are not timing weights.";
    attribute retire:String="Only proven redundant GVM nodes or duplicated generated CFG/resource work and obsolete macro-selected layout authorities retire. Keep optimized program semantics, polls, tail calls, roots, multi-shot continuation, FFI entry and setup label cursor behavior.";
    attribute coldBenefit:String="Can reduce unavoidable native optimization input/CFG complexity without lowering GCC optimization. Requires measured ordinary-function pass/shape coverage plus total added GVM-planning and runtime-transition cost; current major gain unproved.";
    attribute failure:String="Unsupported opaque C/FFI, unresolved descriptor/edge/provider state or unknown output keeps original owned route and refuses reusable plan; do not produce old C plus an extra planner as a speedup architecture.";
  }

  part nativeTimingRefinement {
    attribute qntPath:String="dev/architecture/toolchain/models/quint/native_artifact_partition.qnt";
    attribute qntCase:String="codePlanChangedDuringCompileRefusesTest";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/NativeArtifactPartition.lean";
    attribute leanLemma:String="staleCodePlanRefusesPublication";
    attribute key:String="native-phase-cost-to-source-refinement";
    attribute provenLinks:String="D859 reports phase times, D860/D861 constrain specific macro/preprocess hypotheses, current source establishes producer and consumer shape. No report attributes0.29s exclusively to JUMPINT, IFD, register allocation or any one GCC pass.";
    attribute qntExclusive:String="Existing preparation/native-readiness models own plan admission, invalidation, action readiness, partial/unknown completion and code/descriptor retention. Host transfer publication must carry valid entry/roots. Do not use QNT to manufacture phase timers or prove twoCFGs equivalent.";
    attribute leanExclusive:String="Prove trace simulation for GVM normalization and host-edge lowering: observable effects, poll/root points, frame mapping, nargs and resume identity; label-host ordinal agrees with setup.c cursor traversal. Existing benefit algebra only consumes a separately justified disjoint cost projection.";
    attribute c23Obligation:String="Initialized immutable plan is published release/acquired under a valid storage pin; code/frame descriptors survive calls, GC and captured continuations. Language choice does not prove instruction equivalence or eliminate native optimizer cost.";
    attribute evidenceJoin:String="ASCENT joins report-specific clocks, current source hashes and refused promotions; report text interpretation and macro-to-cost attribution remain human-reviewed/open, not automatic inference from equal fields.";
    attribute twofoldGate:String="Preprocessing-only and full-parsing-only cannot halve this ordinary timer snapshot even with zero replacement cost. Optimizer-only local2x would need at least0.195/0.29 of the aggregated optimization/generation time removed under unchanged0.10 parsing; not a package forecast.";
    attribute wholePackageGate:String="Cold package needs broad covered critical span, earlier readiness and all new costs charged, retaining loader/substitution/object fixes. Old543 occupied jobs and one0.39 compiler report cannot be combined as a current time partition.";
    attribute refutations:String="D1434 startup6.168448->7.742066s rejects unweighted groups; D1883 packed-emitter candidates68.080142/70.253448s fail55s gate with incomplete controls, so no matched regression ratio. Preserve both as bounds against simplistic architecture transfer.";
    attribute currentNativePlanEquivalent:Boolean=false;
    attribute currentColdTwofoldSupported:Boolean=false;
    attribute darwinDifferentialAttributed:Boolean=false;
  }

  part howtoVerifyChain {
    attribute key:String="howto-verify-source-to-GVM-identity-boundary";
    attribute source:String="../gerbil-mcp/tools/howto-verify.ss";
    attribute caller:String="handle-howto-verify calls load-recipes, filter/map, run-verify-batch, optional run-compile-check-batch, hash/record mutation and text output. This application execution is not the GCC compile timer or build.ss startup.";
    attribute compilerChain:String="Gerbil expanded module -> generated Scheme -> Gambit bbs-purify -> target.dump -> targ-scan-procedure resource/label vectors -> host/procedure C -> configured GCC. Current vendor anchors available; exact measured howto generated input not present at checked conventional locators.";
    attribute historicalTiming:String="D859 reported0.39 compiler seconds, parsing0.10 including preprocessing0.06, optimization/generation0.29; D860 IFD and D871 ordinary string negatives retained. No pass/function-exclusive timer.";
    attribute currentGeneratedGvmMatched:Boolean=false;
    attribute currentGeneratedCMatched:Boolean=false;
    attribute identityRefusal:String="Do not reconstruct actual howto label ids, frames or resource masks from Scheme text; absence of generated files is unresolved, not an empty or successful extraction. No compiler run or cache restoration authorized.";
    attribute initialCut:String="Resource projection at an unchanged host boundary, with exact read/write coverage and full materialize/GC-update/reload/landing/resume obligations. Existing per-host resource unions already exist; narrowing an actually used resource is invalid.";
    attribute candidateScope:String="No host repartition, tail transfer optimization or poll deletion proved here. Only abstract semantic resource-boundary simulation, parameterized by complete roots and unchanged boundary operation.";
  }

  part hostSemanticRefinement {
    attribute key:String="resource-boundary-semantic-refinement";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/host_resource_semantics.qnt";
    attribute qntCase:String="rootMaterializeReloadTest";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/HostResourceSemantics.lean";
    attribute leanLemma:String="finiteProgramSimulation";
    attribute relation:String="Source Machine equals target observed logical state: kept locals overlay stable base; pc/nargs/fp/frameId/denv, effect history and noncaptured world preserved. Not merely equal artifact keys.";
    attribute admission:String="Copy reads/writes must be covered by kept resources. Boundary materializes complete view, applies same operation once and reloads. Root-list completeness and source/target ABI/FrameSpec agreement are separate source obligations.";
    attribute gc:String="Moving update applies to all declared roots including base-only slots; kept locals reload afterward. Captured snapshot roots also update before later restore; omission is a negative control.";
    attribute continuation:String="Snapshot contains resource/control state, not effect history/world. Repeated resume restores the same captured control while preserving new effect history and external world; full Gambit continuation heap/frame semantics remain open.";
    attribute landing:String="Exception landing is represented as a state/effect boundary. The proof does not assert actual C catcher or FFI code already flushes/reloads correctly.";
    attribute negativeControls:String="Omitted read/write, missing root, missing reload, lost writeback, duplicate effect, stale captured root, wrong FrameId and erased history produce semantic mismatches.";
    attribute leanDuty:String="Arbitrary-store copy/boundary/GC-root-update/reload/capture/resume/landing simulation. Full GVM extraction, tags, physical stack/heap aliasing, actual safepoint/root coverage and real host transfer remain OPEN.";
    attribute qntDuty:String="Finite executions of the same boundary protocol and bad-lowering histories. Tests are not induction or native-semantic proof; no optimizer timings in state guards.";
    attribute actualHowtoSemanticRefinementClosed:Boolean=false;
  }

  part howtoTwofoldGap {
    attribute key:String="howto-native-semantic-cost-composition-gap";
    attribute reportedCompilerMicros:Integer=390000;
    attribute reportedOptimizerMicros:Integer=290000;
    attribute reportedParsingMicros:Integer=100000;
    attribute neededNetRemovalForLocalTwofoldMicros:Integer=195000;
    attribute idealOptimizerOnlyResidualMicros:Integer=100000;
    attribute coverageForIdealOptimizerOnlyWholeTwofoldPermille:Integer=673;
    attribute sensitivity:String="Using rounded one-file report only: optimizer-only ideal local ratio3.9; with zero overhead and same split on a covered critical-span region, whole2x needs covered fraction>=39/58(~67.24 percent), rounded up673per-mille. Not a workload forecast.";
    attribute costOwnership:String="No executed evidence yet identifies extra howto C optimization work removed by this resource representation. Semantic equivalence gives no positive optimizer-time credit; GCC may already remove redundant locals/copies.";
    attribute added:String="Analysis/plan generation, resource validation, materialization/reloads, any new scope-entry or host-transfer work, descriptor storage and code/cache effects; baseline already performs some synchronization, count only net differences.";
    attribute wholeGap:String="Remaining actual net critical-span removal must satisfy Rnative+Rother-Ainteraction>=D0/2 in one current case. Current D0/current span weights and realized Rnative are not bound by the selected historical records.";
    attribute sourceAndModelProofIsPerformanceEvidence:Boolean=false;
    attribute coldTwofoldEstablished:Boolean=false;
  }

  part howtoProductProvenance {
    attribute key:String="howto-generated-product-producer-and-retention";
    attribute schemeProducer:String="Installed Gerbil driver generate-runtime-code writes~0.scm and separate loader.scm; compile-scm-file writes declarations/code and optionally copies static.scm. Effective libdir/GERBIL_PATH and package namespace select locations.";
    attribute nativeProducer:String="Gambit _gsclib target filename -> c#cf -> _front parsed module/GVM -> target.dump C. Generic native compilation deletes generated target C unless keep-temp or source already target; explicit Darwin runtime-C branch generates/copies C before obj/bundle.";
    attribute gvmProducer:String="_front compiler-option-gvm defaults false; only enabled branch opens root.gvm and virtual.dump-gvm. Missing standalone dump is not evidence of a lost cache or a failed ordinary compile.";
    attribute gerbilConsumers:String="Installed output jobs advertise produced runtime C; prepare-link chooses current produced C versus Scheme fallback and copies static C. Stub/link temporary files are deleted separately; ordinary build cleanup can remove package outputs.";
    attribute identity:String="Original Scheme blob matches historical9a5c35e; phase/mode, expansion inputs, SDK compiler bytes, opts/target/word-char/ABI, module-ref/linker-name, output role/path and complete generated-byte digest still needed. Equal source alone does not bind native descriptors.";
    attribute historicalAnchors:String="D859/D860/D871 reference D858 real howto C; raw/tmpD858/D855 JSON and D871 directory are absent at declared locators. Registered clue read refused host-source attestation; do not repair framework or turn refusal into empty success.";
    attribute frameBaseline:String="Current _t-c-3.scm489 freezes frame-spec; _t-c-2 return label emission creates it; _t-c-1 emits IFD/OFD/chunks; modular header decoder and _mem consumers already exist. Zero new credit for reintroducing these.";
    attribute standaloneGvmNormallyRequired:Boolean=false;
    attribute currentGeneratedBytesBound:Boolean=false;
  }

  part howtoWitnessBoundary {
    attribute key:String="partial-real-howto-evidence-not-synthetic-frames";
    attribute ifdExpressionOccurrences:Integer=153;
    attribute descriptorRowsKnown:Boolean=false;
    attribute resourceRowsKnown:Boolean=false;
    attribute physicalRootSlotsKnown:Boolean=false;
    attribute actualFrameSpecAdmitted:Boolean=false;
    attribute partialFact:String="D860 counts IFD calls, not unique frame identities, GC bitmap values, physical roots or FrameSpec objects. Do not synthesize zeros, the previous three-cell fixture or a majority mask.";
    attribute extractionContract:String="Bound actual generated C and target role first; read md/mr/mw and pd/pr/pw declarations with host selection, DEF_LBL_RET/IFD/OFD rows, paired chunks and label-host order. Join to producer FrameSpec fields and checkpoint roots; raw C parsing cannot recover all GVM semantics.";
    attribute admission:String="Require matched C bytes/producer/profile, actual resource rows, frame/slot mapping and live descriptor ownership. Standalone .gvm can be optional if equivalent source-bound evidence closes the same obligations; count-only evidence refuses.";
    attribute failure:String="Missing or ambiguous rows remain None/unresolved; existing abstract semantic theorem is not an actual howto instance. No cache restoration or compilation to manufacture a witness.";
  }

  part frameModelInstantiation {
    attribute key:String="FrameSpec-derived-roots-to-host-semantics";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/host_resource_semantics.qnt";
    attribute qntCase:String="howtoCountIsNotDescriptorWitnessTest";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/HostFrameBridge.lean";
    attribute leanLemma:String="ordinaryRootUpdated";
    attribute reusedProofs:String="FrameContract.inlineRoots supplies encoded bitmap identity; FrameRoots.coordinate supplies one-based physical word/bit coordinates. Existing frame cursor family remains separate native/complete-source refinement authority.";
    attribute sourceCoordinates:String="bit i corresponds to physical slot i+1. Ordinary roots are positive slots <=actual-fs whose bitmap bit is set, excluding link+1. _mem continuation/object scanning follows structural link separately; never relocate it twice as ordinary.";
    attribute logicalCellMap:String="Injective physical-slot-to-logical-cell map is explicit. Physical slot-1 is NOT automatically a GVM register index. Cross-frame/address aliasing and descriptor lifetime remain source obligations.";
    attribute proof:String="Frame-derived ordinary root list feeds HostResourceSemantics.poll; every ordinary root updates, zero/link exclude, structural link stays unchanged by ordinary pass. Full structural traversal still has its own operation contract.";
    attribute baselineBenefit:String="FrameSpec freeze/decoder/root cursor are current vendor work already implemented, not new compile-time acceleration. Binding models to these fields improves soundness only.";
    attribute actualHowtoInstantiationClosed:Boolean=false;
    attribute newColdSpeedupProved:Boolean=false;
  }

  part rationaldictIdentity {
    attribute key:String="retained-POO-C-identity-before-semantics";
    attribute witnessPath:String="tests/fixtures/sysml-api/rationaldict-native-witness.json";
    attribute cSha256:String="afc661c4be9baaef17300e02db52f1b14ec06be5203f5f2788a3c23f2ad0a61d";
    attribute scmSha256:String="8e0985a80a438172f3e723884e8ac3150490736f2a41f5ab99aeaf3a4c114be8";
    attribute scmTimestamp:Integer=1792170496;
    attribute cTimestamp:Integer=1789984941;
    attribute pairAdmitted:Boolean=false;
    attribute abiAdmitted:Boolean=false;
    attribute reason:String="SCM has rationaldict-iter; C does not. Timestamp mismatch forbids SCM-to-C promotion. Configured gambit.h uses ps->r; modular C23 uses ps->context->r. Version409008 alone does not bind state ABI.";
    attribute allowed:String="C-only retained resource/descriptor instance under conditional regs5/align4/reserve3. No current image loading, no native experiment, no original-GVM or end-to-end ABI proof.";
  }
  part rationaldictSemanticInstance {
    attribute key:String="actual-POO-resource-and-FrameSpec-instance";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/rationaldict_witness.qnt";
    attribute qntDuty:String="Finite row163 assignment/poll/capture/repeated-resume histories; missing-root/wrong-coordinate and mixed-generation rejection. No arbitrary-history theorem or C memory model claim.";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/RationaldictWitness.lean";
    attribute leanDuty:String="138 concrete descriptors validate; root list equality/count/unique labels; arbitrary-store SET_R2 plus frame-root-update simulation via HostFrameBridge; conditional multishot boundary semantics. Not source parser correctness or whole native execution.";
    attribute procedures:Integer=24;
    attribute labels:Integer=191;
    attribute descriptors:Integer=138;
    attribute outlines:Integer=9;
    attribute ordinaryRootOccurrences:Integer=612;
    attribute selectedLabel:Integer=163;
    attribute selectedContract:String="min-key__0: read FP/R2, write R2; RETI storedFs0 actualFs9 link0 bitmap63 roots2..6. Logical frame placement injective and separate from resource indices. Raw physical mapping and live descriptor ownership remain obligations.";
    attribute transfer:String="Wrong arity branch retains original entry requirements. JUMPINT in SINGLE_HOST uses direct unchecked goto and does not execute SET_NARGS; multi-host does. Transfer is an explicit unrefined boundary, not an unconditional nargs2 update.";
    attribute singleHost:String="Active module union7, not 134/130 per-procedure memberships as dynamic loads/stores. Current single-host resources cannot be replaced with selected procedure set without new CFG and boundary proof.";
  }
  part rationaldictBenefitGate {
    attribute key:String="POO-cold-twofold-no-howto-transfer";
    attribute nativeTimingKnown:Boolean=false;
    attribute howtoTimingTransferred:Boolean=false;
    attribute newPositiveTimingCreditMicros:Integer=0;
    attribute currentTwofoldEstablished:Boolean=false;
    attribute reusableBaseline:String="Existing FrameSpec freeze, descriptor decoder, root cursor, Darwin C/object reuse and installed launch fixes: zero new credit.";
    attribute retirement:String="Replace per-module repetition only after CFG/arity/host-transfer equivalence, FrameSpec lifetime, code/literal/binding consumer coverage and matched product identity; unknown callbacks stay explicit boundary or reject.";
    attribute benefit:String="Candidate shared helper/layout construction reduces generated/parsed/optimized common duties; current source counts cannot allocate removable GCC time or Darwin excess. No rationaldict local speed ratio asserted.";
    attribute gap:String="Need same-source whole-package D0 and critical span, removed net duties R, new planning/materialization/helper-call/cache overhead A; require R-A>=D0/2 for 2x. No borrowed howto0.39/0.29s, byte-share timing or serial work double count.";
  }

  part rationaldictReturn163Coordinates {
    attribute key:String="RETI163-spill-native-consumer-coordinates";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/rationaldict_return163.qnt";
    attribute qntDuty:String="Finite ordered register pushes, return-address push, reserve, scan, restore and heap-link-rewrite histories; missing-root/link-scan controls. Abstract values are not native pointer encodings.";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/RationaldictReturn163.lean";
    attribute leanDuty:String="Arbitrary register/payload spill-restore, ordinary-root updates, structural-link exclusion, affine stack/heap coordinates and mark_array interval equality. Int word addresses are not C pointer provenance or all C23 schedules.";
    attribute source:String="gvm_registers PUSH_REGS NB_GVM_REGS5; stack_operations FP_PUSH/FP_ADJFP; kernel handler_stack_limit and internal_return; _mem continuation-roots mark_frame/capture and object-scanning FRAME; decoder/root cursor.";
    attribute stackWords:Integer=12;
    attribute payloadWords:Integer=9;
    attribute heapBodyWords:Integer=10;
    attribute heapAllocationWords:Integer=11;
    attribute spillValues:Integer=6;
    attribute rootFirst:Integer=2;
    attribute rootPast:Integer=7;
    attribute actualReturnHeapIndex:Integer=4;
    attribute coordinates:String="F=pre-POLL FP; push R0..R4 at F-1..F-5, IRA at F-6; H=F-12; RETI_RA=-6; GC rebase H+12=F. Slots1..6=R0,R1,R2,R3,R4,IRA. Heap body[10-slot]; IRA body4; link body9. Ordinary bulk mark_array(F-6,5).";
    attribute restore:String="Direct stack pop restores all five registers and IRA after ordinary-root handling; heap break handler copies payload then overwrites slot1 with handler_break and records prior link in break-next. R0 bitwise preservation across capture is false; structural continuation relation remains separate.";
    attribute actualPointerProvenanceClosed:Boolean=false;
  }
  part rationaldictReturn163Transfer {
    attribute key:String="RETI163-to-min-key-percent-mode-sensitive-tail";
    attribute source:String="Retained C2526-2533 and target2438-2454; labels.h.in JUMPINT; value_types SM; stack_operations R/W_ALL and host exits; module_generation PRC/SET_NARGS.";
    attribute targetPoint:Integer=150;
    attribute returnPoint:Integer=163;
    attribute singleHostNargsWritten:Boolean=false;
    attribute multipleHostNargsWritten:Boolean=true;
    attribute tailAddsFrame:Boolean=false;
    attribute consumer:String="Single-host jumps directly to min-key-percent unchecked body with existing nargs1. Multi-host sets nargs2 and jumps to PRC150 procedure entry whose arity guard accepts2. Both preserve R1/R2 values and continuation; target builds a closure capturing R2/R1 and calls call-with-current-continuation.";
    attribute admission:String="Same unchecked target and arguments do not make complete C executions identical without arity, host flush/reload, closure construction, GC and continuation refinement. Native label addresses remain bound to owning live host/module.";
    attribute fullNativeTailEquivalenceClosed:Boolean=false;
  }
  part rationaldictReturn163Sharing {
    attribute key:String="shared-runtime-cut-with-existing-centralization-deducted";
    attribute alreadyShared:String="RETI register save/restore, stack-limit handler, frame decoder/root cursor, mark_frame and captured-frame machinery are already runtime-owned. Moving them again earns zero C-generation or cold-build credit.";
    attribute movable:String="Private layout/descriptor algorithms and non-label-dependent helpers can live in one compiled runtime behind a minimal generated-code ABI, subject to complete header/type-use closure. Shared service receives explicit context and live continuation descriptor identity, never borrowed local C labels.";
    attribute moduleOwned:String="Actual Scheme operations, local CFG/goto labels, checkpoint identity, per-point root metadata, arity and host-mode choices, resource writeback set, closure capture values, literal fixups and module binding remain generated plan/data or native module code.";
    attribute sourceBarrier:String="POLL references LBL1 and live local R2; standalone runtime function cannot goto another C function's label. Generic dispatcher replacement needs a new point/host ABI and must count added indirect dispatch, accessors, spills and aliasing/optimizer loss.";
    attribute retirement:String="Retire header-exposed private bodies after proving complete type/macro consumers against minimal ABI; retire generated generic code only after emitted byte/CFG coverage and matching profile. Retain direct local transfers until explicit replacement refinement passes.";
    attribute noGuaranteedSpillRemoval:Boolean=true;
    attribute newDemonstratedTimingCreditMicros:Integer=0;
    attribute howtoTimingTransferred:Boolean=false;
    attribute wholeTwofoldClosed:Boolean=false;
    attribute costGap:String="No row163 or rationaldict phase timer in selected records. Need same-package critical-span duty totals, removable shared-body/header parsing and optimization, and net added costs. Require Rcommon+Rother-A>=D0/2; existing runtime/launch/object reuse counted once as baseline. No bytes/resources-to-time ratio.";
  }

  part rationaldictAbiClosure {
    attribute key:String="minimal-generated-code-ABI-two-independent-cuts";
    attribute macroSurvey:String="42 source headers scanned;190 direct header-macro names;680 reached names/773 explicit header definitions across20 headers, unioning conditional alternatives. Not a complete active CPP/type closure; three reachable token-paste sites and184 lexical terminals need discharge/classification.";
    attribute privateSizeDependency:String="BEGIN_MOD_SYM_KEY embeds sizeof module/global/VM/processor. setup.c1794 checks all four; global embeds VM, VM embeds processor/context arrays, context embeds context_mem. An accessor-only change leaves this entire completeness chain.";
    attribute privateAccessDependency:String="GVM resources, host entry/exit, POLL/CHECK and optional BIND_LATE EXT/GSTATE dereference processor/context/global layouts. Unioned debug/activity/TLS/platform alternatives are not the active Darwin profile.";
    attribute publicRetained:String="C23 target/compiler scalar and calling ABI; tagged word/header/fixnum/object layout used by direct operations; label layout or an explicitly replaced label-image schema; host signatures; per-point roots/CFG/local labels; literal/binding inputs.";
    attribute opaqueCandidate:String="Collector/VM/processor implementation, native locks/OS fields and context_mem may leave generated-code includes only when sizeof-based registration and every field access/type/declaration edge have both been replaced. Full public structs are not removed by forward declarations.";
    attribute alreadyShared:String="RETI save/pop, GC scanning/decoder, setup/fixup iteration and current Darwin runtime-C/object reuse already centralized. Zero new removal credit.";
    attribute closureClosed:Boolean=false;
  }
  part rationaldictAbiRefinement {
    attribute key:String="generated-code-ABI-source-cut-proof-obligations";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/rationaldict_abi_cut.qnt";
    attribute qntDuty:String="Temporal dual migration, unresolved paste/declaration refusal, pre-retirement rollback and single-update projection histories. Finite protocol observations, not arbitrary native execution or unbounded theorem.";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/RationaldictAbiCut.lean";
    attribute leanDuty:String="Actual source-type paths, necessity of BOTH registration/access cuts, conditional edge retirement, equal-size/different-offset countermodel, projection equalities and exact historical D855 arithmetic. C23 parser/CFG and pointer correctness stay open.";
    attribute registrationContract:String="ModuleImageSpec binds public value/label/frame/call schema and profile, consumed by runtime-owned setup/private layouts. Replacing old size fields requires producer and setup consumer migration; do not drop compatibility rejection or just add a version constant.";
    attribute accessContract:String="Private context access is replaced only by semantically complete typed value/lvalue and root/host-boundary projections. READ/WRITE/ADDR/update categories differ; setters cannot duplicate or reorder effects. GC/exception/callback/continuation effects remain explicit.";
    attribute retirement:String="Keep old full include/size checks until active profile, paste expansion, all typedef/initializer/sizeof/align/offsetof and transitive C declarations, embedded C/FFI, setup effects and both consumer cuts close. Then remove old producer+consumer together, not a permanent wrapper.";
    attribute binaryAdmitted:Boolean=false;
  }
  part rationaldictAbiBenefit {
    attribute key:String="minimal-ABI-cost-gap-same-cohort-only";
    attribute historicalWholeMicros:Integer=74671000;
    attribute historicalTargetMicros:Integer=37335500;
    attribute historicalCompileIntervalMicros:Integer=636536000;
    attribute historicalWorkers:Integer=12;
    attribute historicalIntervalRemovalNeededMicros:Integer=188510000;
    attribute historicalCapacityLowerBoundMicros:Integer=53044667;
    attribute historicalRemainingCriticalLowerBoundMicros:Integer=15709167;
    attribute scope:String="Existing D855 MCP diagnostic at fixed job intervals and12 capacity. Interval sums are not CPU time; ceil(sum/12) is a capacity lower bound. Not current C23, POO or a forecast; subtract no invented new credit.";
    attribute newPositiveTimingCreditMicros:Integer=0;
    attribute howtoTimingTransferred:Boolean=false;
    attribute currentWholeTwofoldClosed:Boolean=false;
    attribute currentGap:String="Current matched MCP/POO D0 and removed compiler-duty span remain unknown; need net span removal>=D0/2. Minimal header only qualifies eligible private parsing/construction; actual body optimization, helpers/accessors, alias/inlining loss and cache overhead must be bound separately.";
  }

  part rationaldictTerminalDeclarations {
    attribute key:String="184-terminal-caller-partition";
    attribute classifiedTerminals:Integer=184;
    attribute categories:Integer=14;
    attribute unclassifiedTerminals:Integer=0;
    attribute typeTerminals:Integer=15;
    attribute serviceTerminals:Integer=4;
    attribute importedDataTerminals:Integer=2;
    attribute inventoryPath:String="tests/fixtures/sysml-api/rationaldict-terminal-classes.json";
    attribute roles:String="37 globals,5 keywords,8 symbols,40 local labels,1 link entry,20 literal storage,15 types,32 parameters/temporaries,14 module-or-host static storage,2 setup functions,2 dispatch labels,4 service declarations,2 imported data,2 token-paste prefixes. These partition only the old184 terminal subset, not all generated symbols.";
    attribute closureMeaning:String="Every row has source/caller witnesses; category and origin do not prove active declarator/type completeness. Conditional higher-reg/debug/low-level/MSVC paths are not missing declarations; no arithmetic184-minus-exclusions admission.";
    attribute activeClosureClosed:Boolean=false;
  }
  part rationaldictPasteAndProfile {
    attribute key:String="literal-tag-pastes-and-Darwin-role-candidates";
    attribute pasteSites:Integer=3;
    attribute explicitCallerEdges:Integer=6;
    attribute formedTagNames:Integer=8;
    attribute newlyReachedNames:Integer=2;
    attribute pastePath:String="tests/fixtures/sysml-api/rationaldict-paste-callers.json";
    attribute callerClosure:String="FIELD:STRUCTURE_TYPE_FIELD/TYPE_ID_FIELD with STRUCTURE. MEM_ISA:IS_ND_STRUCTURE/MEM_ALLOCATED_FLONUM with STRUCTURE/FLONUM. MEM_ISA_AND_IS_NOT_DOUBLE:PAIRP/PROCEDUREP with PAIR/PROCEDURE. Resolve t-tag and s-subtype names in object_tags; sFLONUM and tPROCEDURE were absent from old explicit reach.";
    attribute profilePath:String="tests/fixtures/sysml-api/rationaldict-darwin-declaration-profiles.json";
    attribute modeRule:String="Recorded DEFS_OBJ lacks DYNAMIC and defaults early binding; DEFS_DYN adds DYNAMIC, forcing library/shared/late binding. Extra action options may override; candidate recipes do not bind historical C compilation or current effective builtin/include profile.";
    attribute profileSealed:Boolean=false;
    attribute originalCompileInputsBound:Boolean=false;
    attribute headerAbiMatched:Boolean=false;
  }
  part rationaldictDeclarationRefinement {
    attribute key:String="image-state-joint-declaration-and-benefit-contract";
    attribute qntPath:String="dev/architecture/toolchain/models/quint/rationaldict_darwin_declarations.qnt";
    attribute qntDuty:String="Finite classification/profile/type/image/access sequencing, OBJ/DYN adapter mismatch, role-neutral image support, and qualified cold/incremental object-reuse histories. Not unbounded type resolution or native semantics.";
    attribute leanPath:String="dev/architecture/toolchain/models/lean/RationaldictDarwinDeclarations.lean";
    attribute leanDuty:String="Exact184-row name uniqueness,14-category partition/origin witnesses; literal tag spelling; compatible image representation plus supported binding adapter; unsealed profile/input refusal; cold object-credit zero. Source classification/extraction remains inspected, not mechanically verified C.";
    attribute jointContract:String="ModuleImageSpec consumes value/label/frame/host representation; state/binding access consumes matching representation and a supported role-specific adapter. A common image may support OBJ and DYN without duplicating data. Registration sizeof and private field/declaration paths retire only together after effects/root/lvalue obligations close.";
    attribute coldBenefit:String="No prior-object reuse in all-miss cold build. Only new work elimination net of added ABI costs can reduce current D0/2 deficit. Existing D85515.709167s capacity deficit remains historical, not a current timer.";
    attribute incrementalBenefit:String="With same public consumed representation/effects and both private paths retired, private runtime layout changes may retain module products; public value/label/frame or consumed service contract changes invalidate actual consumers. Role-neutral image projection must not unnecessarily include unused adapter details.";
    attribute nativeAbiAdmitted:Boolean=false;
    attribute newPositiveTimingCreditMicros:Integer=0;
    attribute howtoTimingTransferred:Boolean=false;
  }

  part darwinNativeAbiPrototype {
    attribute key:String="implemented-C23-state-projection-component";
    attribute sourceDirectory:String=".cache/tasks/repair-9-12/processes/audit/build/darwin/CONFIGURATION/source";
    attribute implementationBranch:String="darwin";
    attribute prototypeDirectory:String="tests/darwin-generated-code-abi";
    attribute currentForkNativeAccepted:Boolean=false;
    attribute storageContract:String="Existing Python build_output and source_capacity own the isolated source. Vendor modern-c is never edited by this experiment. Historical native PASS is not replayed on the new source identity. DEV contains design/models only.";
    attribute implementation:String="Public header/contract and private runtime adapter are separate C translation units. Actual C23 context R2 read/write uses memcpy for all word bits. Public tuple/binding/method checks reject before output publication. No private sizeof in the new consumer.";
    attribute bindingRule:String="EARLY/LATE are adapter modes, distinct from OBJ/DYN operations. Installed Gerbil Darwin static-runtime path explicitly invokes -obj -cc-options -D___DYNAMIC -fPIC then reuses that object for dyn bundle linkage. Never infer binding from operation name alone.";
    attribute testHeaderCurrent:Boolean=true;
    attribute retainedRationaldictCObjectCompiles:Integer=2;
    attribute nativeRegisterRoundTrip:Boolean=true;
    attribute nativeHighBitRoundTrip:Boolean=true;
    attribute nativeFrameRows:Integer=138;
    attribute nativeInlineRows:Integer=129;
    attribute nativeOutlineRows:Integer=9;
    attribute nativeOrdinaryRootOccurrences:Integer=612;
    attribute nativeNegativeCases:Integer=6;
    attribute headerScope:String="Official config.status renders current modular HEADER_CONFIG in isolated cache. New header73415b8a... differs from installed/configured670ff0b9...; no in-place regeneration or runtime-library mixing.";
  }
  part darwinNativeProfileWitness {
    attribute key:String="actual-explicit-native-control-profiles";
    attribute compilerMajor:Integer=16;
    attribute compilerMinor:Integer=2;
    attribute wordBits:Integer=64;
    attribute registers:Integer=5;
    attribute argumentRegisters:Integer=3;
    attribute singleHost:Boolean=true;
    attribute singleVm:Boolean=true;
    attribute singleThreadedVm:Boolean=true;
    attribute profileScope:String="Two actual -c controls under explicit early/late defines with newly assembled current header. Object C type/declaration closure passes for these profiles. Not recovered original rationaldict argv or a DYN bundle load. The actual source-level -obj plus DYNAMIC route maps to LATE.";
    attribute historicalProducerBound:Boolean=false;
    attribute smpRuntimeQualified:Boolean=false;
  }
  part darwinNativeAbiAcceptance {
    attribute key:String="native-component-pass-not-whole-runtime-speedup";
    attribute record:String="evidence/research/retained/darwin-acceleration/native-abi-prototype.json";
    attribute nativeComponentPassed:Boolean=true;
    attribute moduleLoaderMigrated:Boolean=false;
    attribute legacySizePathsRetired:Integer=0;
    attribute legacyPrivateFieldPathsRetired:Integer=0;
    attribute fullSchemeExecutionTested:Boolean=false;
    attribute fullGcContinuationTested:Boolean=false;
    attribute mergeAllowed:Boolean=false;
    attribute newDemonstratedSpeedupMicros:Integer=0;
    attribute costScope:String="Single local early/late object compilation observations only; not strict cold package timings or an A/B acceleration ratio. Existing C/object reuse remains baseline; test-harness SDK link correction is not a Gambit performance repair.";
    attribute nextGate:String="Implement full public value/host/label/image setup/effect contract and owner/GC admission, migrate real generator+loader consumers together, then test matched current runtime/Gerbil package cohort. Do not load new objects into old SDK or claim private paths retired from component tests.";
  }
  part darwinGeneratorLoaderIntegration {
    attribute key:String="darwin-real-generator-loader-source-change";
    attribute generator:String="darwin:gsc/_t-c-1.scm::targ-dump-mod emits BEGIN_MOD_IMAGE_SYM_KEY";
    attribute producer:String="darwin:include/_gambit/module_generation.h.in::BEGIN_MOD_IMAGE_SYM_KEY emits immutable initial resource image and mutable runtime descriptor";
    attribute consumer:String="darwin:lib/setup.c validates image before table import; completed fixup must never reimport initial addresses";
    attribute stateService:String="darwin:lib/setup.c::state_register_slot; 25 PSRn macros use a nonallocating same-owner full-expression borrow, existing local register cache unchanged";
    attribute qntModel:String="dev/architecture/toolchain/models/quint/module_image_setup.qnt";
    attribute qntExclusiveObligation:String="Validation-before-hydration ordering, repeated load ordering and same-owner borrow consumption; no payload algebra";
    attribute leanModel:String="dev/architecture/toolchain/models/lean/ModuleImageSetup.lean";
    attribute leanExclusiveObligation:String="ABI mismatch cannot return a payload; initial table projection; repeated setup preserves relocated values; no concurrent scheduler model";
    attribute cRefinementOpen:String="Whole image validation/source identity, all private access closure, module load concurrency, full-expression borrow bounds, owner identity and no-GC/reentry closure remain native/source refinement obligations";
    attribute privateSizeChecksRetired:Integer=0;
    attribute registerMacroPrivateAccessesReplaced:Integer=25;
    attribute newGlobalAccessorServices:Integer=2;
    attribute imageResourceScalarFields:Integer=19;
    attribute wholePackagePassed:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinNativeImageWitness {
    attribute key:String="real-image-control-and-retained-rationaldict-witness";
    attribute record:String="evidence/research/retained/darwin-acceleration/generator-loader-integration.json";
    attribute seedMode:String="51 byte-checked frozen C products; changed Scheme emitter regenerated and linked; not full source bootstrap";
    attribute realSchemeControlPassed:Boolean=true;
    attribute badImageRejected:Boolean=true;
    attribute retainedRationaldictPassed:Boolean=true;
    attribute continuationResumesPerCase:Integer=2;
    attribute nativeScope:String="One C23 Darwin profile, one processor execution, composed Gerbil macro support per compile-stub; no whole SMP admission";
    attribute immutableImageBytes:Integer=184;
    attribute newDescriptorPointerBytes:Integer=8;
    attribute resourceImportAssignments:Integer=19;
    attribute privateSizePathsRetired:Integer=0;
    attribute fullHeaderStillRequired:Boolean=true;
    attribute freshExpansionPassed:Boolean=false;
    attribute gerbilCompilerAdmitted:Boolean=false;
    attribute wholePackageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinCompilerBatches {
    attribute key:String="compiler-build-dependency-closed-batches";
    attribute record:String="evidence/research/retained/darwin-acceleration/compiler-build-batches.json";
    attribute schemeOwner:String="Cached darwin src/std/make.ss::make-build-batch and shared for-each-module-dependency; src/std/build-std.ss selects planning or compilation";
    attribute pythonOwner:String="gerbil.build stdlibBatchSize parameter; build_owned_compiler and _stdlib_batches; no independent runner or stdout decoder";
    attribute planContract:String="Plan covers all normalized specs and owned submodules. Integer ordinal graph is a file result; cycles and invalid dependencies are rejected before native batch submission";
    attribute completionContract:String="Selected specs retain original order; existing make owns scheduling and executor drain. Require actual exit0, parent reaping, process-group quiescence, equal graph/source identities, unchanged sealed prefix and native output manifest before publication";
    attribute failureContract:String="Quiescent failed/unknown work is moved outside lookup. An overwritten sealed prefix rejects reuse and preserves custody; it is never silently restored or reported complete";
    attribute sourceScope:String="Frozen C23 runtime cohort, explicit build source overrides and target/environment; not generic dynamic-module reuse or qualification for concurrently changed vendor HEAD";
    attribute qntModel:String="dev/architecture/toolchain/models/quint/native_artifact_partition.qnt";
    attribute qntExclusive:String="Existing start/publish/failure/invalidation temporal owner; a publication guard must refine the actual returned/quiescent/source/output checks. This source-to-model guard correspondence remains an obligation, not a duplicate scheduler";
    attribute leanModel:String="dev/architecture/toolchain/models/lean/CompilerBuildBatch.lean";
    attribute leanExclusive:String="Dependency-closed extension and membership-preserving reorder of ordinal sets; Python graph extraction, lexical identity, macro effects and native execution are not established by these lemmas";
    attribute nativeObservation:String="326 targets and1487 edges planned. A resumed native request validated the sealed23-target prefix and extended it to55 targets; next work was deferred before launch. Complete compiler and package observations remain separate";
    attribute newCost:String="Full source-interface planning and repeated import/context construction, source/output hashing and persistent receipts; no package speedup credit";
    attribute retire:String="Whole stdlib process completion as the only persisted boundary for this managed build mode; unproved partial artifacts never become freshness authority";
    attribute fullCompilerPassed:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinCompilerBuild {
    attribute key:String="same-source-sdk-before-package-comparison";
    attribute record:String="evidence/research/retained/darwin-acceleration/same-source-sdk.json";
    attribute sourceRegenerationPassed:Boolean=true;
    attribute regeneratedCProducts:Integer=51;
    attribute fullSourceCoreMicros:Integer=121835951;
    attribute compilerBuildComplete:Boolean=false;
    attribute compilerCoreReady:Boolean=true;
    attribute throughStage:String="stage1";
    attribute standardLibraryFullReady:Boolean=false;
    attribute toolsReady:Boolean=false;
    attribute scopeRule:String="Existing gerbil.build throughStage selects a complete requested prefix. A core query is sufficient for a case with separately ready dependencies; full upstream tests require explicit tools readiness and reject the smaller scope";
    attribute sourceRegenerationScope:String="Current darwin Scheme source regenerated all51 core C products; not a complete Gerbil SDK or package acceleration observation";
    attribute sourceCohort:String="Gerbil1cfb032 plus11 existing installed source changes and existing build-aot.ss; target native products must use the current darwin compiler/header/runtime cohort";
    attribute latestVendorByteMatch:Boolean=false;
    attribute sourceDriftRule:String="Frozen2232-path modern-c snapshot is the comparison cohort. Concurrent vendor changes in6 paths include symbol/keyword getter semantics; do not promote frozen-cohort results to the changed HEAD or mutate leased sources mid-run";
    attribute configurationDefect:String="src/build.sh overwrote caller GAMBOPT; requested p1 was not preserved. Cached source now preserves caller options before adding owned SDK paths; no speedup credit";
    attribute failureCustody:String="Initial600s SDK budget exhausted after completed stage1; bounded continuation failed stdlib by SIGBUS138. Keep failures and move unqualified stdlib outputs out of lookup before source-bound revalidation";
    attribute existingOptimizationRule:String="AOT tools, native C/object reuse, diagnostic compaction and installed source changes remain baseline; SDK setup or budget repair is not package gain";
    attribute qntExclusive:String="Existing setup-order and package-admission models own publication/reload/readiness/invalidation interleavings; no new duplicated SDK state machine";
    attribute leanExclusive:String="Existing image-value and benefit models own layout/value preservation and net-removal algebra; no claim that these lemmas verify a native SDK build";
    attribute ascentExclusive:String="Require separate gerbil-compiler, fresh rationaldict, gerbil-mcp and gerbil-poo complete observations; a model or retained-Scheme component PASS supplies none of these facts";
    attribute packageComparisonAllowed:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinFreshRationaldict {
    attribute record:String="evidence/research/retained/darwin-acceleration/fresh-rationaldict-compiler-case.json";
    attribute sourceScope:String="Frozen C23 darwin compiler/runtime cohort; original .ss input snapshot, normal gxc -s and same-cohort macro execution artifacts";
    attribute compilerCoreRequired:Boolean=true;
    attribute fullStandardLibraryRequiredForThisCase:Boolean=false;
    attribute generatedDirectoryVisible:Boolean=true;
    attribute executableMacroSupportReady:Boolean=true;
    attribute normalGerbilLoaderPassed:Boolean=true;
    attribute gcChecked:Boolean=true;
    attribute continuationResumes:Integer=2;
    attribute invalidImageRejected:Boolean=true;
    attribute artifactRoleRule:String="Interface, macro executable, dynamic load-module stub, static runtime source and native bundle are distinct. A raw GSI consumer is not a substitute for the Gerbil runtime required by a dynamic stub";
    attribute costScope:String="51.982125s normal gxc includes frontend, GSC and native support generation;6.798371s normal loader and case. Neither is a pure expansion timer or package benchmark";
    attribute sourceRefinementAdmitted:Boolean=false;
    attribute latestVendorAdmitted:Boolean=false;
    attribute wholePackagesPassed:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinBazelCompiler {
    attribute record:String="evidence/research/retained/darwin-acceleration/bazel-compiler-construction.json";
    attribute implementation:String="src/gambit_smp/gerbil_build.py::build_bazel_compiler";
    attribute producer:String="tools/ci/build_source_toolchain.sh prepare/build/verify; existing Bazel source producer";
    attribute sourceIdentity:String="Exact Gerbil HEAD plus all present tracked/untracked nonignored Gambit working source bytes and modes; deletions preserved; local nested Git metadata retains the Darwin branch base";
    attribute configurationIdentity:String="GNU GCC16, C23, Darwin SDK, flags, producer and patch input hashes; --enable-multiple-threaded-vms --enable-smp --enable-multiple-vms are one mandatory profile. Validate actual generated headers and runtime cond-expand features, not command strings alone";
    attribute selectionInvariant:String="Upstream manifest precedes configure; no force checkout of the older Gambit gitlink; package CLI can consume only the resulting complete prefix, never Homebrew objects or a core-only source-tool overlay";
    attribute completionInvariant:String="Every producer command must exit zero, be reaped and leave a quiescent group; verify and compiled gxpkg/gxtest interfaces and native modules required before package readiness";
    attribute failureCustody:String="Failed and timed-out outputs remain in the owned cache and do not grant package or performance readiness; input drift invalidates the construction";
    attribute benefitScope:String="Correct complete compiler construction is a prerequisite, not evidence of acceleration; existing Bazel optimizations receive no new credit";
    attribute nativeObservation:String="Actual bound source producer reached stage1 and timed out at600.047584s; exit-9, parent reaped and group quiescent. Generated multiple-threaded-vms, multiple-vms and SMP feature all confirmed. Complete prefix and both packages remain unaccepted";
    attribute compatibilityGap:String="Gerbil baseline producer input repaired; old Gambit global-capacity responsibility still needs an equivalent modular C23 implementation and its existing native control. Fixed20000 allocation is a source risk, not established cause of this timeout";
    attribute nativeAcceptance:String="Open until complete source production and both package requests pass; do not repeat unchanged full builds or increase limits to manufacture acceptance";
  }
  part darwinCompilerStageContinuation {
    attribute record:String="evidence/research/retained/darwin-acceleration/bazel-compiler-continuation.json";
    attribute implementation:String="build_bazel_compiler prior/through_stage -> _continue_bazel_compiler -> existing _current stage proof checker; Bazel build_target is shared by full build and stage requests";
    attribute sourceCohort:String="Gerbil1cfb032 with the bound da5651a Darwin working source, not current vendor HEAD admission; all three VM/SMP capabilities retained";
    attribute prerequisite:String="Old request must be timed out, reaped and quiescent; check exact heads, source inventory, runtime payloads and complete185 bootstrap source/native pairs; regenerate-only C differences remain explicit";
    attribute isolation:String="Withdraw unproved stage1 outputs before bootstrap import; do not let partial ssi/scm files shadow the completed bootstrap";
    attribute observation:String="Bootstrap compiler import PASS41.317844s; fresh stage1 PASS371.219689s; bound input drift empty; core gxi version reports Gerbil1cfb032 on Gambitda5651a in1.088269s";
    attribute reuse:String="Complete native receipt, successful exit, reap/quiescence and unchanged bytes/modes/links required. No BUILD label, file existence or old whole-command timeout can authorize reuse";
    attribute budgetMeaning:String="The old600.047584s whole construction stays failed. The independently bounded core-only request does not represent a successful600s whole compiler build or a cold-package speedup";
    attribute qntOwner:String="native_artifact_partition.qnt owns publication/key invalidation; source-to-attempt/phase and root-lifetime refinement remains OPEN, not established by current bounded tests";
    attribute leanOwner:String="CompilerBuildBatch.lean owns prerequisite-closure arithmetic; it does not prove source extraction or temporal completion. No duplicate Lean scheduler";
    attribute packageReady:Boolean=false;
  }
  part darwinGlobalCapacityAdmission {
    attribute record:String="evidence/research/retained/darwin-acceleration/bazel-compiler-continuation.json";
    attribute runtimeOwner:String="Modern-C VM global-root storage; the compiler producer consumes its qualification and does not create a Darwin-specific VM registry";
    attribute source:String="Historical flat-layout cohort: memory-lifecycle.inc setup_mem_vmstate allocated20000 cells; global-bindings.inc assigned increasing indices; root-origins.inc scanned count cells. Isolated Darwin replacement is tracked separately";
    attribute observed:String="Existing tools/ci/multiple_vm_globals.ss: exit70 after0.589694s; new global was not initialized as unbound at iteration7762; concurrent second half was not reached";
    attribute valueModel:String="models/library/gc/GlobalSlotCapacity.lean Covers/count_bound/fixed_table_cannot_cover_control/first_outside_when_base_fits";
    attribute valueMeaning:String="For every natural initial base, a flat20000-cell table cannot cover32768 distinct consecutive new global indices. Native count/index reflection remains a source premise; the observed first failure is not asserted to be the exact first out-of-bounds index";
    attribute temporalModel:String="Existing VM-root-registry and native-publication owners must cover roster borrow, initialized segment publication, count publication, GC scan and teardown. Their composition for segmented globals is OPEN; do not duplicate these transitions in Lean";
    attribute replacement:String="Use the existing Bazel address-stable segmented-growth mechanism as the baseline responsibility. Adapt it to the current VM registry admission/retirement contract; never reintroduce the removed vm_list_mut";
    attribute publication:String="Prepare UNB1 cells in every live VM before publishing the new index/count; allocation failure cannot expose an unbacked index; scan sees a count whose entire interval has storage";
    attribute retirement:String="Retire fixed allocation and flat scan only together with all GLOCELL consumers. A pointer-meaning change requires an explicit native-layout identity check before module fixup; equal sizeof is insufficient";
    attribute costs:String="Baseline segment size4096 cells; slack below4096 words per VM, plus geometric pointer metadata and old table custody. Extra segment lookup loads, growth serialization and roster lifetime remain costs; no measured Darwin gain";
    attribute nativeControlPassed:Boolean=false;
    attribute historicalCrashesAttributed:Boolean=false;
    attribute darwinSpeedupCredited:Boolean=false;
  }
  part darwinGlobalCapacityReconstruction {
    attribute record:String="evidence/research/retained/darwin-acceleration/global-storage-reconstruction.json";
    attribute storage:String="4096-cell stable segments; a storage-only arena list includes preparing VMs. Slot lock serializes capacity growth and arena retirement, without restoring the removed execution vm_list_mut";
    attribute publication:String="Initialize UNB1 and backing segments before index/count publication; GC coordinator captures one count for the whole round before the existing barrier. Allocation failure publishes no new index";
    attribute abi:String="Module flag bit4 identifies segmented global cells. Reject old flat-layout objects before native fixup; all bootstrap and core native objects must be reconstructed";
    attribute makeContract:String="lib LIBRARY_OBJECTS and gsi/gsc OBJECTS depend on the generated header. Undefined MODULES_O cannot cover consumers. Native build no longer invokes concurrent Git index-selection targets; explicit developer targets remain";
    attribute nativeObservation:String="Segmented-only cohort: GSI starts with p1 and p4. Original32768-global plus threaded control passes at p1 in0.614254s. p4 reaches GLOBALS-OK then crashes in GLOBALVARSET; source stack also includes concurrent permanent allocation and symbol interning. New writer-control cohort is tracked separately";
    attribute compilerReplacement:String="Existing build_bazel_compiler rebuild_bootstrap option consumes the owned nested runtime, checks unchanged pinned heads, retires old native objects and calls the existing Bazel boot-gxi/stage0 stages. Receipt and byte identity govern reuse; old whole-command timeout remains failed";
    attribute bootstrapObservation:String="All185 native bootstrap modules rebuilt in186.163s. First compiler import timed out at45.008s; a same45s diagnostic completed in40.991439s with the actual marker. Retain both outcomes and reuse only checked successful receipt plus exact source/native bytes";
    attribute darwinLoadingEvidence:String="A one-second sample25s into the diagnostic contains849 of864 samples below dynamic_load/dlopen/dyld Loader mapSegments/fcntl. This is a local sample, not whole-duration attribution or package speedup. Source-level mapping retained; no claim that a sampled symbol identifies the exact fcntl operation";
    attribute nativeCohortLimit:String="The source-mapped failure build adds -g1 to the optimized kernel object. Correctness observations remain useful; production-profile matched performance admission remains open";
    attribute qntOwner:String="Existing publication and VM-root-registry models own temporal growth/scan/retirement. Whole compiler stages own replacement/readiness. Neither abstract model proves the unresolved native permanent-allocator interleaving";
    attribute leanOwner:String="GlobalSlotCapacity owns interval capacity, not scheduling. Native index-to-cell, common-count partitions and initialization coverage require source refinement; no claim of completed native proof";
    attribute actualPackageProtocol:String="Both original package entrypoints must use the complete same-source gxi. Record actual processor count separately from the three enabled configure capabilities; package passes cannot qualify the failed p4 control";
    attribute nativeParallelControlPassed:Boolean=false;
    attribute packageReady:Boolean=false;
    attribute darwinSpeedupCredited:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinNativeGlobalWriterControl {
    attribute record:String="evidence/research/retained/darwin-acceleration/global-storage-reconstruction.json";
    attribute discriminator:String="Actual regenerated gxi reports6 processors, completes32768 sequential globals and crashes at GLOBALVARSET in the threaded half. This matches the earlier four-processor source location; the real frontend cannot be qualified by the p1 GSI control";
    attribute implementation:String="Process-global native service locks protect the permanent allocation cursor/psection list and atomic find-create-intern/global-registration transactions. Private locked implementations are hidden; public C function names/types remain. Initialize primitive value before adding a global to the published list";
    attribute order:String="Symbol publication may acquire permanent storage or global slot publication. No inverse nesting. Error returns release the outer lock before Scheme can raise or retry; NULL/permanent allocation paths do not request Scheme GC under these locks";
    attribute gc:String="GC captures symbol/keyword table root fields under the same publication lock. Permanent names/objects remain nonmoving. Existing VM stop-the-world participant closure is still required";
    attribute observation:String="Same original p4 control passes in0.936533s with GLO-PROCESSORS4, GLOBALS-OK and THREADS-OK; production -O1 kernel restored. New complete gxi and both packages remain unqualified until rebuilt and tested";
    attribute excluded:String="No complete proof for concurrent independent VMs, enumeration callbacks/direct metadata readers, custom reentrant allocation providers, or whole runtime teardown. This bounded writer control is not whole SMP admission";
    attribute qntOwner:String="Existing root/publication/retirement owners must model lock acquisition, no-GC prefix, error unlock and GC handoff. Native four-processor execution is evidence for this control, not a temporal proof";
    attribute leanOwner:String="Capacity and partition arithmetic stay value obligations. Do not duplicate the scheduler or infer C source fidelity from the existing interval theorem";
    attribute darwinAccelerationCredit:Integer=0;
    attribute wholeRuntimeAccepted:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinStageConsumerQualification {
    attribute implementation:String="_continue_bazel_compiler -> existing Bazel stage1 -> src/build.sh build_stage1 -> boot-gxi src/build/build1.ss. The real consumer imports gerbil/compiler before its existing building-gerbil-in marker and all compilation";
    attribute gate:String="Bind complete bootstrap source/native pairs and reviewed consumer source; require import form before the unique consumer marker, successful whole stage exit, reap/quiescence, unchanged output bytes and the original stdout hash. Missing marker rejects completion even for exit0";
    attribute retirement:String="Retire the redundant import-only preflight process. Historical45s timeout receipts stay failed; they never become native stage1 passes. A successful actual consumer is a distinct request under its unchanged600s budget";
    attribute publication:String="The marker alone grants no readiness. Publish the consumed-bootstrap witness only with completed stage1 output proof. Reuse requires both that witness and current source/runtime/bootstrap key; partial files, labels and unknown completion cannot qualify it";
    attribute qntOwner:String="native_artifact_partition owns UNKNOWN/RUNNING/completed-consumer/READY transitions and invalidation; VM-root models own runtime roots. No additional Lean scheduler";
    attribute leanOwner:String="CompilerBuildBatch retains prerequisite closure arithmetic. Source import ordering and stdout fidelity remain explicit source/refinement obligations, not inferred from that arithmetic";
    attribute benefit:String="Eliminates one diagnostic-only process and repeated compiler import during construction. Native stage1 still performs its necessary import. Zero package or twofold cold-build credit until matched complete package observations";
    attribute negativeControl:String="Exit0 with missing consumer marker is rejected by the shared completion checker; native error/timeout/unquiescent controls remain unchanged";
    attribute packageAccepted:Boolean=false;
  }
  part darwinChildStatusAdmission {
    ref part pipeline=GambitDarwinAcceleration::pipelineProduct;
    attribute record:String="evidence/research/retained/darwin-acceleration/child-status-admission.json";
    attribute observed:String="Production -O1 writer-control cohort: stage1 PASS349.459258s, no input drift; original default gxi global/thread control PASS2.320s; explicit gxi query reports6 processors. Stdlib then fails at132.999821s by parent gxi SIGSEGV; shell and OS crash report agree on pid83616";
    attribute sourceFacts:String="sigchld_signal_handler performs waitpid and traverses global_device_group list/prev, invoking device_kind and status_set; normal add/remove/release paths mutate or free device structures. The handler takes no stable lifetime claim for those pointers";
    attribute inferenceLimit:String="OS fault frames name sigchld_signal_handler while the interrupted context is in alloc_rc/malloc. This does not uniquely prove the invalid pointer cause, a complete source-line mapping or a Darwin-versus-Linux cost ratio";
    attribute requiredBoundary:String="Separate asynchronous notification/status capture from normal device ownership, birth registration and status delivery. No list reclamation while an async reader can retain a pointer; no child status consumed before its registration/failed-birth custodian is known";
    attribute temporalDuty:String="QNT must own notification coalescing, registration/reaping interleavings, device last-use, close/late handler and shutdown custody. Existing runtime_ownership composition does not yet instantiate this child-status protocol; native_artifact_partition only owns build readiness/invalidation";
    attribute valueDuty:String="Lean may establish status encoding and custody/capacity arithmetic after a protocol is selected. Do not copy the QNT scheduler or infer this native C lifetime result from existing root/bitmap theorems";
    attribute sourceDuty:String="Close actual device add/remove/release, spawn registration, signal-mask and status readers under the effective C23 profile before admitting a replacement. Public/raw aliases and unknown outcomes remain explicit gaps";
    attribute baselineAccounting:String="Existing published process-exec12.2.1 optimizes child fd closure and explicitly excludes whole SMP; it is independent of this async-status gap. The tested da5651a Darwin working cohort is frozen, not current vendor HEAD. Deduct existing platform optimizations; no new twofold credit";
    attribute packageResult:String="MCP and POO original test entries bound, but both package requests rejected before clean/build/test because compiled package-tool prefix is incomplete. This is admission denial, not two test failures or passes";
    attribute runtimeReplacementImplemented:Boolean=false;
    attribute bothPackagesTested:Boolean=false;
    attribute wholePackageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part nativeDeviceMonitor {
    ref part consumer=GambitDarwinAcceleration::darwinChildStatusAdmission;
    attribute record:String="evidence/research/retained/darwin-acceleration/native-device-monitor.json";
    attribute implementation:String="Isolated lib/os_io.c and os_io.h. One lock-free control word carries LOCKED/PENDING/CLOSED; normal native accesses nest by thread-local depth, async delivery never waits for an interrupted owner";
    attribute sourceClosure:String="All list/prev mutations are device_add_to_group/remove_from_group; cleanup owns an in-flight ring before releasing structural access; process birth holds access through setup_from_pid registration; handler scans only protected active/in-flight rings and recognizes the builtin process table without a virtual call";
    attribute failureCustody:String="Failed close returns its node to active ownership. Abandoned/unknown close retains an in-flight node and blocks group retirement. Final reference settlement runs in a cancellation-disabled noncollecting tail; error after reference settlement does not reinsert or release a dead node";
    attribute shutdown:String="Close async admission before group teardown; retain a nonempty/in-flight group on incomplete cleanup. Unknown raw external aliases and unsealed native callbacks are not qualified by CLI tests";
    attribute temporalModel:String="dev/refactoring/modern-c/models/quint/native_device_monitor.qnt";
    attribute temporalDuty:String="Exclusive structural/reaper access, registration-before-reap, durable pending across unlock, late notification after close, and retained cleanup ownership. Legacy lost-wake/early-reap/use-after-free histories remain explicit negative controls";
    attribute valueModel:String="dev/refactoring/modern-c/models/lean/NativeDeviceMonitor.lean";
    attribute valueDuty:String="Three-bit word range, distinct pending/lock states, preservation on unlock/close; no duplicated scheduler and no proof of native pointer lifetime by value algebra alone";
    attribute sourceRefinement:String="C23 sequentially consistent lock-free atomics refine QNT actions; no collecting Scheme call or nonlocal exit under structural access; final release provider closure and joined shutdown roster remain explicit admission premises";
    attribute cancellation:String="Normal outermost access disables pthread cancellation before acquisition and restores after ownership release; nesting keeps the outer state. Final cleanup settlement remains cancellation-disabled across unlink and release. Unknown nonlocal provider exits remain unqualified";
    attribute statusIdentity:String="Only builtin process nodes still awaiting status match waitpid PID. Completed devices retaining a recycled PID cannot intercept the later child status. Status, completion and POSIX cleanup flags use atomic access";
    attribute nativeObservation:String="Source-built GSI p4 original global/GC/thread control PASS; p6 six-thread 96-child status/retained-handles/GC/missing-executable control PASS. First raw GSI invocation lacked Gerbil displayln and exited70; invocation environment corrected without altering original test. Whole Gerbil and both packages remain separate gates";
    attribute implementationBuilt:Boolean=true;
    attribute focusedControlsPassed:Boolean=true;
    attribute typedFailureControl:String="Durable tests/fixtures/darwin-child-status.scm PASS15.274701s at p6: all96 statuses checked; missing executable must raise no-such-file-or-directory-exception, not an arbitrary exception";
    attribute completeCompilerOutcome:String="Same-source producer: stage0 PASS156.995503s; stage1 TIMEOUT600.060675s under unchanged600s budget, exit-9, parent/group reaped and quiescent, no bound input drift. Actual consumer marker observed but whole stage incomplete; stdlib not reached, so former handler crash is not proved eliminated";
    attribute timeoutCustody:String="Existing _withdraw_stage1_outputs moves partial core out of lookup after quiescence, preserving bytes and completed bootstrap; no bulk restoration or retry. Current original MCP and POO suites both denied before execution: complete compiled package-tool prefix missing";
    attribute costAttributionLimit:String="Pre-timeout census observed active GCC on optimize-top~0.c. There is no per-phase time decomposition or evidence the entire600s belongs to that module, the new monitor, or Darwin excess. No historical failed-time speedup ratio";
    attribute nativeAccepted:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
  }
  part darwinModernCStorageIntegration {
    ref part baseline=GambitDarwinAcceleration::darwinCleanStagingBaseline;
    attribute record:String="evidence/research/retained/darwin-acceleration/modern-c-dynamic-storage.json";
    attribute source:String="Clean staging7688c85 with isolated modern-c4b9d865 source deltas; vendor and historical working runtime are not overwritten";
    attribute storage:String="4096-cell stable segments; global_gate owns arena membership and prepare-all-VMs before count/symbol publication. Preparing VMs participate. Partial allocation failure leaves initialized unbound capacity but no new global identity. Old tables retire only after closed VM/root users";
    attribute scan:String="One frozen count, disjoint processor partitions and segment-boundary mark_array calls. NativeControls PASS at6 processors for original32768 globals, threaded writes/GC and96-child status; no constant/heap increase";
    attribute build:String="Library and executable object sets, including generated linker metadata, depend on gambit.h. Core no longer performs concurrent git update-index; verified unchanged index. Flat ABI dimensions were reconstructed byte-exactly and differ under the current Darwin profile";
    attribute actualCopyFailure:String="Real stage1 reached GC mark_array/scan. A bounded source contract observed processor4, section233, position78579, destination offset65536: a current-destination reference was being copied again. Historical extracted counterexamples are no longer the only evidence for this cohort";
    attribute idempotentFix:String="Existing atomic adapters read root/header and publish root updates. A destination revisit creates no new source copy, scan task or Tail debt. Invalid moving references outside the two owned half-spaces still fail closed";
    attribute residualFailure:String="Before frame exclusion, stage1 failed by Bus error at134.581550s. With frame exclusion, actual completed stage1 PASS327.850167s and default six-processor global control PASS2.008107s. Full stdlib then TIMEOUT601.579939s under the unchanged600s budget; group reaped/quiescent and unqualified stdlib withdrawn. Complete compiler and packages remain unqualified";
    attribute frameAccess:String="Adapt existing frame access domain: closed-roster PSTATE identity serializes whole captured-chain backfill, active-frame scan and FRAME/CONTINUATION structural access. Nested synchronous calls borrow the outer claim; ordinary object work remains parallel. No callback, nonlocal exit or collecting allocator is admitted under the claim";
    attribute qntModel:String="dev/refactoring/modern-c/models/quint/copy_custody.qnt";
    attribute qntDuty:String="Revisit before initialization, during Tail debt and after scan creates no new authority; existing recopyTospace control remains a negative history. Frame constructor/scanner exclusion and termination debts remain temporal obligations";
    attribute leanModel:String="dev/refactoring/modern-c/models/lean/CopyCustody.lean";
    attribute leanDuty:String="Prove opposite-half disjointness/coverage and existing unique-source capacity arithmetic. Do not repeat QNT histories or claim native aligned membership, pointer lifetime, reads-from or whole SMP proof";
    attribute admission:String="Rebuild complete compiler on the same new layout, actual stage1 consumer, original gxi controls, full stdlib/tools, original MCP/POO suites, then matched package timing. Package tests have not yet executed for this cohort; missing evidence never passes";
    attribute packageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinCleanStagingBaseline {
    attribute record:String="evidence/research/retained/darwin-acceleration/clean-staging-baseline.json";
    attribute gerbilRevision:String="7688c85a8c75a8a8e437d4bbe391a76f0fddfea1";
    attribute gambitRevision:String="4b9d8656b678100f2172492580e7ec294d05b935";
    attribute materialization:String="Fresh user-selected v0.19-staging Gerbil in owned cache; local darwin branches; pinned committed modern-c Gambit. No old experimental tree or Bazel patchset copied. Generated bootstrap outputs are recorded, not called pristine source";
    attribute profile:String="GCC16.2 C23; multiple-threaded-vms, smp and multiple-vms enabled together; make-j12; native phases capped600s";
    attribute nativeOutcome:String="Configure PASS31.270175s after proper aclocal/autoconf; bootstrap PASS46.677691s; core PASS55.097852s; actual p6 count6 and96-child control PASS. Original32768-global control FAIL exit70 after printed13312; threaded writer portion not reached";
    attribute sourceCause:String="lib/root.h fixes GLOBALS_CAPACITY=20000; global-bindings global_room rejects exhausted capacity; memory-lifecycle allocates one fixed glos extent with expansion TODO. Kernel make-global-var maps all fixnum errors to heap-overflow. Physical heap exhaustion is not established";
    attribute frameworkDuty:String="Existing build_owned_compiler respects explicit GERBIL_BUILD_CORES; no implicit p1 candidate override; whole stage0 and stdlib batch deadlines and ordinary phase caps remain at most600s. Framework tests do not qualify a native compiler";
    attribute migrationDuty:String="Reconcile prior isolated dynamic global-storage work with current modern-c under explicit source identity before compiler admission. Do not raise capacity/heap, import unqualified generated outputs or silently synchronize a moving vendor working tree";
    attribute qntDuty:String="Existing global-storage publication and lease histories own concurrent growth, scan and retirement order. This failing native observation cannot be filled by model PASS or another source cohort";
    attribute leanDuty:String="Existing GlobalSlotCapacity owns slot bounds and extent arithmetic; actual source-to-storage refinement remains separate. No duplicate scheduler proof and no native acceleration theorem";
    attribute compilerAdmitted:Boolean=false;
    attribute originalPackageTestsExecuted:Boolean=false;
    attribute packageSpeedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinStage1SourceAttribution {
    ref part lifetime=GambitDarwinAcceleration::nativeDeviceMonitor;
    attribute record:String="evidence/research/retained/darwin-acceleration/stage1-source-attribution.json";
    attribute failedTail:String="The retained600s attempt reached src/build/build-bach.ss. It contains186 dynamic core objects,31 static C outputs and zero static objects. optimize-top native output existed before withdrawal; it is not evidence that optimize-top occupied the whole timeout";
    attribute callers:String="build.sh build_stage1 -> build1.ss compile1 -> compiler/driver compile-module/compile-scm-file/gsc-compile-file/invoke; then build-bach.ss invokes gsc -link over static Scheme inputs, compiles every C object and links BACH";
    attribute measuredFrontendMicros:Integer=19026560;
    attribute measuredSchemeToCMicros:Integer=6106858;
    attribute measuredObjectMicros:Integer=8714783;
    attribute gccParsingMicros:Integer=960000;
    attribute gccOptimizeGenerateMicros:Integer=6920000;
    attribute measurementScope:String="Focused current-source observations, not a reconstructed original stage interval. Frontend includes imports/optimization/emission, not pure macros; C/GCC use the retained Scheme input. Do not add independent process times into an asserted whole-build saving";
    attribute upstreamIntegration:String="Production os_io.c delta81d3acc0 selected from modern-c, preserving Darwin private entry and SIGCHLD monitor; no history rewrite, reset, bulk generated-C overwrite or other six commits. Base remains da5651af plus recorded working changes, not current vendor HEAD";
    attribute startupPair:String="Same p6/96-child typed fixture:15.274701s before,0.879753s after. Single matched pair around17.36; benefit belongs to already published modern-c descriptor closure, not a new branch or whole-package gain";
    attribute nextNativeUnitContract:String="One generated C metadata/CodePlan and one compatible native object per semantic input; dynamic core and BACH consumers may share only after module/linker identities, DYNAMIC definitions, descriptor layout, roots and initialization are proved equivalent. Current gerbil-toolchain-static-path exclusion remains until that admission";
    attribute qntDuty:String="Existing native_artifact_partition owns source/tool/ABI/inline/code-plan invalidation and publication. It does not prove static/dynamic semantic equivalence or erase incomplete outputs";
    attribute leanDuty:String="Existing CompilerBuildBatch owns dependency-closed prefix algebra; semantic refinement for shared module images and FrameSpec consumers remains open. Do not duplicate QNT scheduling or call value laws a native proof";
    attribute performanceAdmission:String="Same-source complete compiler and both original MCP/POO suites precede matched package timing; all three flags,600s stage budget and30/300/300 package budgets unchanged";
    attribute completeProducerOutcome:String="After selective81d3 integration: stage0 PASS135.388288s; stage1 PASS354.254561s with actual completed consumer; default gxi original global/GC/thread control PASS2.343434s; stdlib TIMEOUT600.765025s under600s cap, exit-9, group quiescent, no bound-input drift";
    attribute finalCustody:String="Existing _withdraw_stdlib_batch moved4570 incomplete files including1344 native objects out of lookup; completed core binary SHA256 unchanged. Both original package suites NOT RUN: complete compiled package-tool prefix missing. No repeat after this timeout, no merge";
    attribute remainingCostGap:String="Stdlib census reached active GCC on socket~1 and db/interface~1 with debug generation. optimize-top~0 isolated costs do not measure those jobs or the stdlib critical path; native-unit sharing and remaining upstream integration still need their own source/semantic admission";
    attribute effectiveHostPolicy:String="configure.ac488-511: active single-host=0 means unlimited control points in a single C function per Scheme module, not disabled single-host. No dominance claim or flag change. Bounded host units require tail-transfer/continuation/FrameSpec refinement and accounting for added dispatch";
    attribute wholePackageGainMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinReviewCheckpoint {
    attribute repository:String="tao3k/gambit";
    attribute branch:String="darwin-acceleration";
    attribute target:String="modern-c";
    attribute pullRequest:String="https://github.com/tao3k/gambit/pull/2";
    attribute sourceCommit:String="c930bc626d463a2fe3478427666be78885b80132";
    attribute targetBase:String="4652db0d379e6cb1dd65cab3fad675a98e20499f";
    attribute scope:String="Three Makefile contracts plus Org review record; generated C and unqualified runtime changes excluded";
    attribute positiveGraphCases:Integer=3;
    attribute negativeGraphCases:Integer=3;
    attribute nativeObjects:Integer=66;
    attribute repairedHeaderEdges:Integer=41;
    attribute ordinaryIndexMutationHooksRemoved:Integer=3;
    attribute memoryEnvelopeBytes:Integer=8589934592;
    attribute memoryAuthority:String="User explicitly approved8GiB aggregate registered-process-group monitoring and group cleanup; sampled guard, not OS hard limit";
    attribute priorRefusalMeaning:String="Assistant-selected uncalibrated3GiB envelope also refused installed reference; not proof of a runtime regression";
    attribute storageIntegrationGap:String="4652db0 ordinary globals, primitive overrides and presence bits share one VM storage block; old ordinary-only arena cannot replace it";
    attribute referenceMcp:String="First installed-reference build52.645306959s exit70: absent OpenSSL3.6.4 directory. Separate corrected-search run: build92.546264125s PASS; original27-entry suite TIMEOUT300.010623083s, group drained; suite cause unresolved";
    attribute referencePoo:String="Installed reference build62.293403125s PASS; original just test237.274376208s exit42; illegal import during SSI consumption; cause unresolved";
    attribute importCounterevidence:String="HashTable/ports direct imports4/4 PASS with/without explicit loadpath; actual POO object import2/2 PASS. No universal symbol-missing or direct-import failure established; full harness SSI-consumption path remains open";
    attribute qntDuty:String="Existing publication/invalidation and ownership histories; Make dependency graph checks add no new temporal proof";
    attribute leanDuty:String="Existing conditional value/layout/coverage/cost laws; dependency edges and source counts are not elapsed-time savings";
    attribute ascentDuty:String="Existing twelve native admission gates remain required; draft review and installed-reference observations grant no merge or acceleration";
    attribute sameSourceCompilerPassed:Boolean=false;
    attribute packageAcceptance:Boolean=false;
    attribute speedupMeasured:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part darwinActualPackageTests {
    ref part protocol=GambitPackageDevelopment::pairedExperiment;
    attribute record:String="evidence/research/retained/darwin-acceleration/actual-package-attempts.json";
    attribute executor:String="src/gambit_smp/gerbil_build.py::execute_package; one kind parameter, existing ExecutionContext/build_output/sync_build_source, isolated source snapshots and private darwin Git metadata";
    attribute sourceScope:String="Historical incomplete compiler construction from the frozen da5651af241ff30632c2f2009f09f22240fa3752 cohort. These observations do not qualify the intended complete Darwin compiler or the package tests";
    attribute constructionProfileQualified:Boolean=false;
    attribute intendedCompilerAccepted:Boolean=false;
    attribute supportOutcome:String="Full standard-library request timed out within600s; native env/gxpkg/gxtest compilation subsequently failed by SIGSEGV. Unchanged upstream source tools were delivered through Gerbil's supported module dispatcher; compiled-tools readiness remains false";
    attribute mcpCleanMicros:Integer=19411341;
    attribute pooCleanMicros:Integer=2089785;
    attribute cleanOutcome:String="Both actual gerbil clean requests ended by SIGSEGV, were reaped and had quiescent process groups. Neither reached package compilation";
    attribute mcpOfficialTestsMicros:Integer=27164904;
    attribute mcpOfficialTestsOutcome:String="scripts/run-tests.sh completed its full27-entry inventory; all27 child statuses139, aggregate exit1, no qualified pass markers";
    attribute pooOfficialTestsMicros:Integer=10189628;
    attribute pooOfficialTestsOutcome:String="just test invoked the original project build dependency; it terminated by signal11, aggregate exit139, before the linked harness ran";
    attribute observationRule:String="Official full-test entries were invoked independently after retained package-manager failures as a diagnostic discriminator. Neither test-entry execution nor failed-checks=0 means successful TestCase execution";
    attribute crashEvidence:String="A retained system report for the tool attempt identifies ___garbage_collect_pstate. The precise bad root/frame/object and attribution to candidate changes are unresolved; do not infer that all failures share a proved cause";
    attribute proofSplit:String="Existing QNT owns publication/censoring/custody; existing Lean owns value and gain laws; actual native outcomes remain FAIL and source-to-native GC refinement remains open. No new model can turn these failures into PASS";
    attribute nextDiscriminator:String="Existing gerbil_build.build_bazel_compiler must drive tools/ci/build_source_toolchain.sh from the bound local Darwin working source, retaining the complete Gerbil producer and baseline compatibility responsibilities. Only its compiled package-tool prefix can feed execute_package; no source fallback or Homebrew native artifacts. No timeout/heap enlargement or retry-until-pass";
    attribute packageSpeedupMeasured:Boolean=false;
    attribute bothPackagesPassed:Boolean=false;
    attribute mergeAllowed:Boolean=false;
  }
  part cliRuntimeDispatchStudy {
    ref part sourceBoundary=GambitDarwinAcceleration::executionBoundary;
    attribute evidence:String="evidence/scenarios/darwin-acceleration/official-api.observation.json officialDriverCurrent.cliLoadStudy";
    attribute compilerAdmission:String="6dc0f1ba terminal compiler step PASS; both packages stop at clean. Later d6538db1 uses the same program SHA996e09b8 and canonical installed home; no rebuild or adoption of denied compiler products";
    attribute observed:String="MCP782/793 and POO779/797 one-second main-thread samples at dynamic_load/dlopen/dyld mapSegments/fcntl;162/222 loaded o1 images. Diagnostic sample counts are not whole-run durations";
    attribute rootCaller:String="gerbil/main.ss init! -> gerbil-load-expander! -> runtime/init.ss __load-gxi imports gerbil/core before tool-main; tool-main additionally imports the tool SSI. Stack samples do not separate these callers. runtime/loader.ss owns native runtime initialization and loading/error cache";
    attribute proposedChange:String="Separate eager interpreter/expander initialization and runtime entry lookup using existing official resolution and loader. Admit only a proven runtime main projection; preserve fallback for unresolved/reexported/source entries and required macro effects";
    attribute rejectedExplanation:String="Canonical installed home alone does not remove either30s clean timeout. Earlier SIGKILL sender remains unresolved; user denies manual termination; no GC/SMP inference";
    attribute qntExclusive:String="Existing module loading and stage ownership histories, concurrent loading/error outcomes and unknown completion. Do not duplicate binding/SSI value refinement";
    attribute leanExclusive:String="Same ordered resolution, phase-zero export projection, runtime binding identity, initializer/error/side-effect equivalence and fallback completeness. No timing inference or second loader lifecycle automaton";
    attribute ascentExclusive:String="Source AST caller edges and independent selected receipts remain distinct. Native loader samples do not close binding refinement or either package gate";
    attribute speedupAdmitted:Boolean=false;
    attribute sourceImplementation:String="Isolated Gerbil main.ss separates runtime init! from init-expander!; compiled-tool-main admits only the bundled gxpkg SSI/native pair and its actual local main export/runtime binding. Other tools and unsupported/source/overridden interfaces retain the original interpreter initialization. Phase qualification pending.";
    attribute focusedGate:String="Derive BACH with original build/build-bach.ss from committed complete compiler; withhold core SSI for runtime-help positive and unsupported-interface fallback negative; restore inputs, then run macro/exception/multi-shot interpreter and actual compiled provider/consumer controls before original package entries.";
    attribute runtimePrelude:String="Actual gxpkg SSI declares gerbil/base. core-eval-module initializes core-context-prelude before the body; generated runtime wrappers contain explicit imports and omit the implicit prelude edge. Validate the declared prelude and initialize its compiled runtime before the tool without creating macro interfaces. Matching full-module expansion and BACH producer pass in run906c546b; runtime positive still times out at60s. Prelude correction alone is insufficient.";
    attribute imageLoadingBoundary:String="Calibrated run6d1d0981 passes SIGALRM through and captures a complete dyld image-notification / dlopen stack after32 loader returns. This is debugger-context attribution, not ordinary elapsed time, exact fcntl command identity or package acceptance.";
    attribute prebuiltDependencyContract:String="Official driver previously classified all gerbil/ and std/ identifiers as prebuilt. Actual gerbil/tools/env supplies SCM without C/object; runfeaf58e4 fails linking. Isolated driver now requires the selected installed-generation path and fresh C/object files, otherwise uses its ordinary dependency producer. This relies on an immutable ABI-matched installed generation; timestamps alone are not universal identity or concurrent-publisher proof.";
    attribute executableComponentReceipt:String="Runbf391eb0 compiles the source-checked official driver, package manager and BACH; official gxc -exe product builds in13.470892s and requested clean help exits0 in0.893520s with quiescent child. Literal gerbil positive still times out60.010604s. Component product must not be published as a whole CLI or package pass; binding/override/exception controls and command dispatch remain open.";
    attribute commandHandoffContract:String="Managed bundled gxpkg dispatch uses POSIX execv after the existing binding/provider checks. The installed executable is an official gxc -exe product. Native char-string admission covers ASCII argv/path; other encodings retain the original loader, avoiding new conversion exceptions. No Scheme GC/SMP changes.";
    attribute execSignalContract:String="Rune178e37b observes SIGALRM exit-14 after bare exec, while direct product help passes. os_time.c setup_heartbeat_interrupt_handling installs heartbeat handler before unblocking SIGALRM. Handoff now blocks SIGALRM in the calling thread; exec inherits that mask; new setup installs and unblocks; failed exec restores the original mask and reports errno. These source sequencing facts require native countercontrols, not a whole-runtime proof.";
    attribute managedCliAdmission:String="Complete immutable executable generation requires actual literal gerbil positive, malformed executable rejection, unsupported SSI fallback, shadow provider fallback, optional alias identity, interpreter macro/exception/multi-shot control and compiled provider/consumer. Removing the executable and swapping old module products is a separate bootstrap diagnostic, not a managed-generation gate. Its observed60s timeout remains unresolved; never reinterpret it as semantic rejection.";
    attribute constructorReuseContract:String="Existing CLI capability may clone a completed constructor snapshot from a committed failed-control observation. Require exact journal receipt and artifact digest, all constructor exits0, every child reaped/quiescent, exact parent and three-source identities, full product-tree digest and program/executable digests, then verify transferred tree. Enclosing failure remains failed. Fresh required CLI controls must pass before package tests; source/receipt drift and missing evidence reject.";
    attribute stableProductRequalification:String="Prepared constructor descendants must byte-match their constructor ancestor, with committed journal/artifact identities and known child custody at every hop; bound ancestry to8 and reject cycles. Reuse the existing prefix under an exclusive lease with the already-validated frozen identity, not a newly observed replacement identity. Do not clone all compiler images per control run or reuse prior control outcomes. Clone-related first-touch loading costs are research preparation, not package acceleration gains.";
    attribute managedCliQualificationResult:String="Run23c01c2e PASS: literal gerbil help0.144148s; malformed image, unsupported SSI and shadow provider reject; six aliases pass5.599459s; interpreter macro/exception/multi-shot pass0.384232s; actual provider/consumer compile7.520668s and execution1.325082s pass. Runtime source bde807ba, program707192da, full tree48c1c363. Stable-prefix requalification timing is not package speedup.";
    attribute compilerTaskAbortiveEntry:String="Native controlcd3c9a11 completes all constructors but rejects after false-exception and derived-work checks because worker permits are not fully returned. Existing runtime/thread.ss thread-main explicitly installs an abortive handler so unwind-protect finalizers execute; compiler/base now wraps deferred tasks with this existing function. Runtime implementation is unchanged. Source balance and matching full expansion048cce12 pass; fresh native permit/drain controls remain mandatory.";
    attribute frontendHeapContract:String="Read parent heap bound with existing Gambit ##get-max-heap, whose setup.c implementation returns bytes. main.c runtime heap grammar defaults to a10-bit shift; pass exact KiB with an explicit K suffix, including0 for an unbounded original. Child verifies the same value before expansion. Auto mode falls back for nonrepresentable bounds; explicit separate mode rejects before fork. New cold-library control retains POO's1GiB bound;8GiB aggregate and native worker capacity remain unchanged. This is build-process resource propagation, not a GC/SMP modification.";
    attribute runtimeObjectReuseImplementation:String="Cache-only compiler/base publishes one immutable pending-queue/output-index snapshot under the existing mutex. Registration remains distinct from producer completion; alias and recipe lookups return an existing task handle. All allocation precedes the single publication assignment, and the final empty cut retires the index without a later clear race. Driver runtime C/static object/dynamic bundle products follow the existing Bazel0007 module-reference and Mach-O alias mechanism; this restores existing optimization and earns zero new credit over an optimized control.";
    attribute sharedCWriterReaderAdmission:String="Only a matching current-graph effective recipe may reuse a registered runtime C/object producer. Reader and link tasks join actual producer handles before taking native permits. Unmatched recipes generate C and objects in a fresh executable-private directory; GSC link preparation reads those C operands and owns only its unique stub outputs. Two executable closures never regenerate a shared C input while another compiler reads it. Source SCM writers and installed tool/header generations must be closed and stable, output directories alias-free, and no unrelated issuer may outlive graph drain. Cross-build reuse and arbitrary external mutation remain unqualified.";
    attribute runtimeReuseNativeGate:String="Require executor recipe/alias/duplicate/failure controls, two actual executables sharing leaf/consumer C and objects, private fallback compilation, real failed-C link suppression, and original1GiB cold frontend with native FFI. Ordinary qualification29ff8037 passes all18 controls for compiler8f55b37b. Both original package entries remain required at12workers and8GiB; no source-check-only performance admission.";
    attribute currentPathReferenceContract:String="Resolve gerbil/gxi/gxc from the explicitly captured current host PATH, bind selected launcher bytes and logical targets, and let that gxi write its own runtime home/bin identity as JSON. Do not infer Gambit from PATH gsc, which currently selects Ghostscript. Execute reference gerbil clean/build through the selected launcher and preserve its wrapper environment. Pin runtime inputs and reject detected launcher drift; historical fixed-Cellar runs are not this control.";
    attribute frontendInitializationCorrection:String="The private frontend no longer evaluates _gambit# into its own expansion environment. Stock gxc-main.ss passes include-gambit-sharp as a GSC option; make still preserves those GSC arguments and explicit C target. The duplicated frontend evaluation was outside that route. Its effect on POO1GiB remains a hypothesis until real C FFI and package tests; no heap or worker change.";
    attribute runtimeReuseProofBoundary:String="QNT owns graph registration/readiness/dependency/failure/drain histories. Lean owns effective-recipe equality, ordered SCM/C/object arguments and static/dynamic module-reference/alias semantics. Native controls witness selected real paths, not universal source-to-model refinement. Snapshot-index copying adds graph metadata allocation; private fallback adds native work for unmatched recipes. Source publication mirrors official install.sh, with no standalone planner or new runtime GC/SMP subsystem.";
    attribute portableTestInput:String="User-authorized chunk12 fixture uses existing :gerbil-mcp/proc find-gxi instead of obsolete /opt/gerbil/bin/gxi; assertions and missing-file negative control unchanged. Candidate chunk12 PASS. Candidate and reference complete source snapshots match; reference has not reached MCP original tests because linking fails.";
    attribute currentRuntimeReusePackageResult:String="Candidate9cba7af9: MCP clean2.378471s/build180.395516s PASS; original tests429.037098s DENY,25/27 files pass, chunk07 request120s timeout (irritant5 is request ID) and chunk23 commit-only stamp parse failure. POO clean1.983656s/build154.567057s PASS; original tests337.422126s exit42 with illegal only-in imports, no heap overflow observed. Peak charged footprint8,346,130,368 bytes below8GiB. No whole-package or speedup admission.";
    attribute entryReadinessQualification:String="Run449c2051 passes20 native controls for programcccdaca7: official gxtest run-tests invokes idempotent gerbil-load-expander! before raw source imports; actual embedded source suite passes and unchanged failure assertion exits42. This is component readiness, not package admission.";
    attribute latestEntryPackageResult:String="Run304c4c4b: MCP clean3.508241s/build224.119766s PASS, original tests609.952658s DENY26/27 files; chunk23 stamp parser PASS, chunk07 request120s/file240s timeout. POO clean2.501666s PASS, build180.628923s exits70 because original build.ss shebang expires180s with child status124; no test receipt. Peak charged footprint4,724,160,264 below8GiB, all groups quiescent. No package speedup.";
    attribute compilerProviderAdmission:String="Current-PATH Homebrew GCC verbose native link fails with ambient Nix ld64-954.16; COMPILER_PATH=/usr/bin selects Apple as and ld-1267 and identical minimal C consumer executes. Keep public Gerbil PATH and logical runtime home. Apply only this proven provider selection for the next original package control; assembler and linker effects are not isolated.";
    attribute verificationCostScope:String="Recipes merge to789 unique entries and158 isolated sequential batches. Fixed probes64c33393/d57f07cf observe candidate empty child0.314045s/first batch0.523245s versus reference0.560608s/1.260335s; no uniform batch or whole-corpus bound follows. Missing POO SSI rejects diagnostics; test assertions and deadlines remain unchanged.";
    attribute correctedReferencePackageResult:String="Run ea4d7e14 uses identical MCP266/POO475 source files and Apple COMPILER_PATH while preserving public PATH launchers. MCP clean3.362954s/build62.710988s PASS, original tests308.983453s FAIL26/27; chunk07/23 PASS, chunk21 linked-package missing-path assertion fails. POO clean3.079238s/build71.024656s PASS; original test charged footprint8,605,824,088 exceeds8,589,934,592. Final test receipt absent, owner reaped and reconciled with zero unresolved groups. No complete-package ratio.";
    attribute forcedHostRegression:String="Prior private Gambit2b3b4ef/8436840 emitted GVM_HOST_LAYOUT for every unit; gambit.h undefines configured SINGLE_HOST and forces MULTIPLE_HOSTS. Thus configured unlimited single-host flags did not describe effective generated code. Native case e2da3ad5 confirms no speedup after streaming/literal recovery: MCP283.650340s, tests625.930914s fail25/27; POO build111.723047s PASS, original test1017.113541s fails retained300s batch deadline. Peak7,985,959,264 below8GiB; all groups quiescent. Exact timing attribution to host mode remains pending.";
    attribute configuredHostSourceRepair:String="Private Gambit6ac1d44 restores five exact upstreamf1c787a emitter/header/bootstrap files, retains source-version identity and literal command construction, and integrates only published Darwin process code. Gerbil30ad943 pins six source changes including streaming dependency completion and official runtime/test readiness. No patch overlay, GC/SMP source change, heap increase or worker reduction. Per-procedure splitting did not bound an arbitrary large procedure; withdraw blanket policy rather than claim a valid capacity proof.";
    attribute compilerAndPackageBudgetBoundary:String="Existing CI constructor keeps prepare180/build21600/verify120 under recipe24000; it publishes only a complete compiler. Original package acceptance uses its existing separate6200/6000 envelope and unchanged leaf/request/watchdog limits; no1400-second combined envelope may truncate the original POO prerequisite/test scope. Both packages remain required before acceleration admission.";
    attribute linkedPackagePresenceContract:String="Native public-registry consumer14580fa4 reproduces readlink-f accepting a missing final component and dangling link while valid links pass. Isolated source adds file-exists? before canonicalization; MCP beforee180b36f and after08661052 pass, actual native module/consumer19cf3b82 passes four cases. This is an unapplied isolated package correction with zero acceleration credit; original baseline and failing assertions remain frozen.";
    attribute logicalReferenceHome:String="Current PATH selects public Homebrew launchers. Preserve their reported logical current home in GERBIL_HOME, GAMBOPT, load paths and tool overrides; use resolved storage only for identity verification. Do not introduce both aliases into compiler module resolution. Actual duplicate-link removal still needs a completed native consumer; no installed prefix mutation.";
    attribute referenceAdmissionResult:String="dbd6adf8 fails old OpenSSL3.6.4 metadata and pkg-config lookup after upgrade to3.6.5. Explicit opt searches in8a225240 remove those failures but MCP system symbols remain unresolved and POO repeats aliased runtime objects. Logical-home/C23 SDK alignment in6ba9434b still fails MCP system symbols; POO original test exceeds8GiB at8,654,997,792 bytes. Supervisor reaped and reconciled with zero unresolved groups. Missing final test receipt is DENY; no repeated unchanged POO workload.";
    attribute linkerSelectionGap:String="Current PATH ld resolves to a Nix cctools wrapper; actual GCC child reads-from/exec identity remains unresolved. Final direct GCC argv does not contain environment LDFLAGS. Original POO entry explicitly sets COMPILER_PATH=/usr/bin. Reconcile with successful reference support before new native admission; preserve public Gerbil PATH and do not claim environment assignment proves linker selection.";
    attribute executorNativeAdmission:String="Native runa452e0e1 passes real executable, failed-object link suppression, false-exception sibling/derived drain, restored permits and ordinary1GiB cold-library handoff. Same compiler c695caff then runs both unchanged packages in ef437b4b: clean/build succeed, original tests fail. Native component qualification does not admit package acceleration.";
    attribute wholeGraphContextLimit:String="Complete graph expansion remains in one frontend; process retirement removes overlap only after that frontend completes. Original POO batch still overflows its inherited1GiB. The small cold-library control does not prove a per-module bounded context. No heap increase, p1, worker reduction or GC/SMP edit follows from this failure.";
    attribute independentPackageControl:String="Installed Homebrew reference f5827a77 uses12workers and8GiB with identical package source snapshots. MCP build78.331579s versus candidate160.352641s; no improvement observed. Original reference tests share chunk12/23 failures; candidate alone also fails source-location chunk05 and howto chunk07. POO reference build60.777488s then exceeds8GiB during original test; no completed test receipt. Source and native environment differ, so do not infer a single-factor cause or whole-package ratio.";
    attribute executableReuseBoundary:String="Bazel0007, beyond0003, binds runtime C producers, static objects and linker aliases. Equal550 compile-file plus189 object job counts do not prove identical executed work. Arbitrary queued GSC link preparation must not race writes to shared C with object readers. Preserve complete generation-to-read dependencies and product ABI before parallel admission; restoration of an existing optimized advantage receives zero new net credit.";
    attribute executorQntExclusive:String="Reuse existing stage_context_handoff and link_stage_contract readiness/product histories. Native task handles must refine dependency completion, failed-producer refusal and queue drain. Current controls are examples, not a universal termination proof; no duplicate binding or argv semantics in QNT.";
    attribute executorLeanExclusive:String="Refine driver-owned ordered SCM/C/object/linker inputs and effective compilation options to product identities; establish runtime/static ABI alias equivalence before reuse. Also require complete source-publication and macro binding/effect equivalence. No duplicate scheduler histories or elapsed-time proof in Lean.";
    attribute executorDependencyRefactor:String="Cache-only compiler/base add-compile-job! returns task handles and accepts earlier acyclic dependencies. Dependencies join before native permit acquisition; execute-pending drains started tasks and derived submissions, preserving a false exception separately from its presence bit. Driver closes GSC C generation, submits independent static-object tasks, then a final-link task dependent on those exact handles. Existing nonparallel and non-Darwin routes remain. Ordinary managed-thread completion is qualified; asynchronous native interruption still retains unknown outcome in supervisor custody.";
    attribute coldContextRetirementRefactor:String="Darwin std/make defaults separate-compiler to auto for absent-output Scheme-only library specs using the matching runtime compiler. Existing-output, mixed executable and custom-compiler paths retain original behavior. The existing frontend owns complete dependency and macro expansion, seals phase output, exits and joins; scalar GSC jobs run afterward in the existing executor. Conditional memory reduction removes frontend/native overlap, not arbitrary individual GCC peak or whole-runtime GC work. Frozen POO table-mapping test host has9194 labels/61280 code slots, demonstrating the per-procedure host plan is not an absolute compiler-memory bound.";
    attribute executorAdmissionGate:String="Require native compiled executor at12 permits and a one-permit negative scheduling control, false-exception/sibling/derived drain and suppressed dependent side effects; real parallel executable build and binding consumer; real object compilation failure with no linked output; ordinary public make cold-library phase completion and fresh consumer; all earlier CLI provider/macro/exception/continuation controls. Then both original package requests at12 build workers and8GiB; no component-to-package promotion.";
    attribute alignedPackageResult:String="Run21741434 uses12 build workers and qualified program955e31d9. MCP clean2.174604s PASS, build TIMEOUT300.033744s;187 static C and165 objects remain, check-arity object lock retained. POO clean1.741032s and build89.120190s PASS; original just test begins, then aggregate charged footprint8,633,532,112 exceeds8,589,934,592. Owner drained and reconciled with no unresolved groups; absent final test receipt is not PASS. No package speedup admitted.";
    attribute staticTailCut:String="Existing compiler/driver compile-stub places GSC link preparation, sequential for-each compile-obj and final GCC link inside one queued compile-it. Pool capacity12 does not make this object loop parallel. Bazel0003 is a reference for the dependency cut, not automatically applied code or credited benefit. Preserve scalar argv, closure order, failed-object drain and one final-link dependency barrier in the refactor; do not consume a bounded worker merely waiting for its own children.";
    attribute packageWorkerContract:String="Performance qualification must preserve explicit GERBIL_BUILD_CORES=12 from BazelD855, read by std/make gerbil-build-cores. TEST_JOBS=2 belongs to the original MCP test runner and is not build capacity. Run89bb5059 used2 build workers: MCP hits300s and POO's original build.ss shebang hits180s, yielding child124/outer70. Both remain DENY diagnostics, not regression or acceleration evidence. Correct only declared build capacity; preserve8GiB, clean/build/test entrypoints and original deadlines. Compare only matching source/profile cohorts.";
    attribute absentSearchRootContract:String="Run54c66bb2 DENY: both original clean commands exit70 before build because new dispatch normalized a nonexistent package .gerbil/lib. The original core resolver probes file existence before normalization. Source95b0af8c now skips absent roots and retains existing std/gerbil provider checks. MCP balance passes28 forms; full matching-checkout expansion run97a5adbf passes after incompatible MCP module-header check. Fresh missing-root positive is mandatory alongside existing provider negatives; old CLI qualification cannot admit this new source.";
    attribute packageInputAdmission:String="Existing installed-prefix gerbil.test consumer accepts a committed managed CLI qualification only when phasePassed, program/home, required role exits and quiescence, literal command argv and complete source tree match. Both packages execute original clean/build/test requests with original per-file/prerequisite budgets; no component-to-package inference.";
    attribute executableProduct:String="Use official gxc -exe dependency closure, generated runtime init and actual exported main for one source-bound gxpkg component control. Do not use -static: gxc-main defines it as static external C libraries and Darwin rejects crt0.o. This does not yet route literal gerbil commands or admit either package.";
    attribute optionalFeatures:String="Existing Gerbil nested modules gxpkg~request and gxpkg~template own HTTP/template provider imports. Base command wrapper has no demand for these providers. Only remote directory operations or new request the feature loader; no second cache or promise protocol.";
    attribute bindings:String="Feature aliases are local definitions in compiler-generated nested namespaces. The public provider is resolved by Gerbil import, not guessed external names. Existing load-module must return READY before extern calls. Validate actual six procedure identities.";
    attribute overrideContract:String="Noninstalled std/gerbil directories or package prefixes retain original interpreter initialization. The bundled runtime-only entry requires matching actual SSI/native wrapper paths and its local main export.";
    attribute featureArtifacts:String="Installer/package closure must retain lifted feature loaders, runtime sections and metadata. Generic self-contained static-executable closure for late module demand remains unqualified; no static-link portability claim from CLI tests.";
    attribute nativeControls:String="Withhold core SSI/source and optional runtime providers: new base help must pass, old gxpkg products must fail on the missing request provider, unsupported main must retain core initialization error. Restore provider inputs before macro/continuation and native binding controls; never swap files while child custody is unknown.";
    attribute implementationAdmitted:Boolean=false;
  }

  part stdlibOuterPhaseOwnership {
    attribute sourceOwner:String="Official std/build.ss and std/build-std.ss retain the specification, macro initialization, debug and target options; the existing CI stage adapter owns process retirement";
    attribute observation:String="Run ca2c5008: nested compilation output 9593688 bytes, SHA256 f2ddb06e522d947ae0fa6fc094558e878ec30318857b6519d070dc68b0378aee, no native complete marker; outer Gerbil owner retained 1149585040 charged bytes";
    attribute correctedHypothesis:String="Current stdlib specifications are gxc modules. Delivered output refutes the former mixed-spec/auto-rejection explanation; no such explanation is admitted";
    attribute ownershipSequence:String="Frontend owns generated files -> complete output plus joined/quiescent frontend -> claim native generation -> unchanged output plus native completion -> sealed stdlib stage; exceptions never imply completion";
    attribute resourceAdmission:String="Preserve caller GERBIL_BUILD_CORES and 8589934592-byte aggregate charged-footprint guard. Unqualified whole-module jobs use the existing exclusive native class, not a global worker or runtime p1 override";
    attribute qntExclusive:String="Check phase-order, single native claim, failed/unknown ownership and no stage publication before joined completion; finite interleavings do not prove Scheme or native byte semantics";
    attribute leanExclusive:String="Refine the actual emitted file, argv/environment/cwd and source initialization to the phase observation; preserve binding, timestamp, exceptions and continuation semantics. This source refinement remains open";
    attribute ascentDuty:String="Relate the _ci_stage_products caller to stdlib_products and actual require/run receipts; model/source edges and executed native evidence must agree. A unit-test or AST edge alone cannot admit compiler or package speedup";
    attribute acceptance:String="Required: real phase positive/negative controls, full compiler/tools, both identical package cohorts with literal gerbil clean/build and original tests, matched current-PATH Homebrew control";
    attribute terminalCollection:String="Run6dcceab7 native stdlib consumer completes889 tasks in4401.746560542s with exit0 and quiescence, but old collector requests missing gerbil-stdlib.process.json. The run remains DENY. A real terminal read-compilation-output consumer must validate completion count and current native output regular-file/size/time interval before a new snapshot; never synthesize an old process receipt";
    attribute recoveryBoundary:String="Only same-source prepared ownership and attested successful frontend/native commands allow current-image verification without native replay. Missing/unknown completion, changed handoff or absent outputs refuse. This establishes a newly hashed current image under private-workspace/no-forged-mtime assumptions, not retrospective historical byte custody. A real missing-output negative control must exit70 before terminal positive admission";
    attribute downstreamImage:String="Completed compiler artifact2f7b9088 is a PASS with constructionPassed/packageReady. Package verification consumes that committed typed artifact through existing gerbil-phase-check packages=true and the shared original package executor. Do not rerun gerbil.build or compare pre-tools stage1 write views against a later installed image. Run6fe79016 records that invalid replay attempt as DENY; no package executed in it";
    attribute compilerPassed:Boolean=true;
    attribute packageSpeedupAdmitted:Boolean=false;
  }

  part selectiveConfiguredHostCalibration {
    attribute actualFailure:String="Run b84cff1f: stdlib frontend84.693225625s joined/quiescent; native request connection~1 is phi support; aggregate9130618112 bytes, cc1 7846369424, GSC770245736, independent Gerbil consumer150618688; all registered groups recovered";
    attribute input:String="Retained connection~1.c SHA25676c5f7c6a3f9b02d0e60bc2b1ecb577805d457e38929f6bd15b3f5463430a035;22609942 bytes;13638 labels;205 procedure intervals;largest procedure4178 labels including intro";
    attribute configuration:String="Current header single-host limit0 disables fallback; optimized-module limit20000. Homebrew has the same limits. Candidate default CORCXXFLAGS_GAMBUILD already contains ftrack-macro-expansion=0; do not claim the flag is absent based only on FLAGS_DYN";
    attribute hypothesis:String="Calibrate upstream SINGLE_HOST_LIMIT8192 on this actual unit; small units must retain single host. This is neither a selected production threshold nor a universal native-memory bound";
    attribute negativeKnowledge:String="Do not restore the withdrawn unconditional multiple-host emitter. One large procedure, module-wide parsing, optimizer/debug work and foreign C can still exceed a memory budget";
    attribute evidenceDuty:String="Existing gerbil.test host consumer with exact old runtime files and retained C/SCM; no emitter/header overlay, no old failed-C retry, no missing-input pass, and no source refinement or package promotion";
    attribute qntExclusive:String="Single claim, failed/unknown task custody and no final stage publication before all consumers complete";
    attribute leanExclusive:String="Source GVM labels, per-procedure coverage, saved-root/return correspondence and mixed-host ABI refinement; finite lifecycle traces do not prove these semantics";
    attribute nativeCalibration:String="Run01168da1 compiles the exact retained C in36.882624875s; aggregate peak3902315216 bytes; small-host and mixed-host GC/continuation/tail controls pass. The original failure was censored, so no elapsed speed ratio follows. C-only consumption also removes concurrent Scheme-to-C memory and cannot isolate the entire peak delta to GCC host grouping";
    attribute proposedDelivery:String="Official compile-scm-file emits Gambit ##meta-info cc-options only for Darwin C phi support. Existing gambuild-C extracts the metadata. Runtime code and small support units retain their host policy. Standard metadata interpreted-load and C-emission-to-native transport must pass before complete compiler admission";
    attribute transportQualification:String="Run8371e4bc PASS: interpreted metadata, separate public compile-file-to-target emission with explicit dynamic linker-name, metadata-only native options and mixed-host runtime controls. Prior e9ad7114 remains DENY for fixture linker-name mismatch. Sourcec8f5735 is not yet a completed compiler or package cohort";
    attribute invalidation:String="A body-only compile-scm-file change invalidates stage1 and all successors. Retained configure/prepare/Gambit/bootstrap/stage0 receipts keep their actual producer heads; regenerated stage1 must never inherit old bootstrap source identity";
    attribute failureCustody:String="Exact failed connection SCM/C are preserved in the task failure store before withdrawal of partial standard-library outputs. Existence of884 objects is not a reusable completion receipt";
    attribute packageSpeedupAdmitted:Boolean=false;
  }

  part installedCommandProductAcceptance {
    attribute evidence:String="evidence/scenarios/darwin-acceleration/official-api.observation.json#packageControlComparison";
    attribute producer:String="Official src/tools/build.ss currently declares the gxpkg library; the completed c8f5735 installation has its SSI and dynamic modules but lacks lib/gerbil/tools/gxpkg executable";
    attribute consumer:String="Official src/gerbil/main.ss tool-main can exec the native product only after compiled-tool-main provider admission. Absence keeps dynamic loading. The exact provider decision in failed clean remains unobserved";
    attribute requiredProduct:String="Declare the executable with the existing std/make exe specification and preserve the library/import contract. Install, hash and attest it as an output, not as an optional optimization inferred from compiler construction";
    attribute requiredControls:String="Runtime command, macro/provider overrides, missing executable and failed handoff controls precede both complete package suites. Do not replace literal gerbil clean/build or original test entrypoints";
    attribute currentCandidate:String="b09fda33: identity queries pass6.964060875/1.875814416s; both clean commands time out30s. One-second clean stacks show dyld mapSegments/fcntl, not full-duration attribution or exact syscall/fd identity";
    attribute currentPathControl:String="9f495fca: MCP clean/build/original27-file suite pass; build59.2477s. POO clean/build pass; build95.1062s. Original POO test compilation interrupts at8609413240 charged bytes versus8589934592; all registered groups reconciled. Not a candidate regression or physical-machine RAM equivalence";
    attribute qntExclusive:String="Declared-product readiness, provider-selected handoff, publication/retirement and failure/unknown custody histories. Current native observations do not prove these histories";
    attribute leanExclusive:String="Provider binding, argv/environment, macro dependency and exceptional-result preservation across runtime command selection. Not elapsed-time or scheduler proof";
    attribute performance:String="No idle-host gate requested. Both package acceptance and causal net benefit remain unresolved; identity improvement without a source change receives zero optimization credit";
    attribute counterevidence:String="Unplanned e71d987d executed the full recipe because --step was ignored with --run. Same-source MCP clean8.19669s and build70.04815s passed before operator interruption; no completed original tests. Exclude from performance admission. Missing native gxpkg does not prove the whole clean-delay cause. Existing CLI now rejects the misleading combination before launch";
    attribute bothPackagesPassed:Boolean=false;
  }

  // Current audit authority; historical narrative parts do not override this gate.
  part twofoldArchitectureAudit {
    attribute auditDate:String="2026-11-02";
    attribute scope:String="Independent Darwin source PRs; implementation and compiler/package reruns paused pending architectural evidence audit";
    attribute auditOrg:String="dev/architecture/toolchain/darwin-architecture-audit.org";
    attribute priorChronology:String="dev/architecture/toolchain/darwin-acceleration-matrix.org";
    attribute gambitCodeHead:String="6e647736d7003db252b7b61ad761c53e3cdf7c86";
    attribute gerbilCodeHead:String="c8f5735516368a31b60a708f243e5d88e45ec3a2";
    attribute targetSpeedup:Integer=2;
    attribute nativeRunsAllowed:Boolean=true;
    attribute implementationAllowed:Boolean=true;
    attribute currentTwofoldProved:Boolean=false;
    attribute matchedPlatformPair:Boolean=false;
    attribute mcpControlBuildMicros:Integer=59247738;
    attribute pooControlBuildMicros:Integer=95106186;
    attribute targetScope:String="No numeric speedup budget or prediction before the published patched concurrent baseline is aligned. Existing MCP tens-of-seconds achievements are mandatory baseline, not candidate credit";
    attribute fullViewClosure:Boolean=false;
    attribute auditProjectionMeaning:String="SDK parse/instantiation and ASCENT local step completeness only. Org table is derived from the typed projection; no native provenance, causal speedup or semantic refinement follows";

    attribute netLaw:String="Tnew=B-E-O+A; twofold iff E+O-A>=B/2 for exclusive elapsed removal E, newly verified overlap O and all added/interaction costs A. Trace refinement must establish this balance";
    attribute admittedIncrementalSavingLowerBoundMicros:Integer=0;
    attribute savingUpperBound:String="Unknown; no fabricated range or expected multiplier";
    attribute historicalRestriction:String="Old no-PR and three-VM-switch statements are historical. Current PRs are drafts, runtime switches false, external build concurrency independent of SMP; do not rewrite their old evidence";
    attribute resumeContract:String="Complete this architectural audit first. Subsequent implementation requires a selected source-grounded cut, nonduplicated critical-path coverage, semantic obligations and explicit unchanged acceptance gates; this audit alone authorizes no new native work";
  }
  part auditCohortIdentity {
    attribute key:String="cohortIdentity";
    attribute status:String="OPEN";
    attribute observation:String="Published source identities are explicit. Retained runtime identities show Homebrew SMP=true/version ea114fc versus candidate SMP=false/version6e64773; a matched accepted causal pair is absent.";
    attribute closure:String="Exact source, generated C/header, compiler, SDK, dependency, environment and observer identities must join per comparison.";
    attribute owner:String="SysML + ASCENT";
    attribute evidence:String="official-api.observation.json#packageControlComparison";
  }
  part auditNativeAcceptance {
    attribute key:String="nativeAcceptance";
    attribute status:String="OPEN";
    attribute observation:String="Construction2f7b9088 passed; candidate original MCP and POO suites are not both accepted.";
    attribute closure:String="Both literal clean/build/original-test histories, natural exits and quiescence are required; a test-compile guard stop is not pass.";
    attribute owner:String="Native evidence + QNT admission";
    attribute evidence:String="official-api.observation.json#selectiveHostDelivery/completedCompiler";
  }
  part auditSpanAttribution {
    attribute key:String="spanAttribution";
    attribute status:String="OPEN";
    attribute observation:String="Patch baseline equivalence is not closed; no numerical removal budget or twofold forecast is assigned.";
    attribute closure:String="Assign each omitted action and wait interval once; measure new overhead and schedule interaction. Do not add worker-seconds, bytes or nested timers.";
    attribute owner:String="Lean DevelopmentBenefit + trace refinement";
    attribute evidence:String="darwin-acceleration-matrix.org#DARWIN-INSTALLED-COMMAND-PRODUCT";
  }
  part auditExistingAdvantages {
    attribute key:String="existingAdvantages";
    attribute status:String="DEDUCTION-REQUIRED";
    attribute observation:String="Published patch618d76 includes AOT tools and persistent static-object reuse safety. Installed control has real gxpkg/gxtags executables and reuse/digest helpers; candidate has launcher symlinks and no corresponding helper products. Baseline-equivalent behavior is not demonstrated.";
    attribute closure:String="Ported baseline advantages receive zero new credit against that optimized control; raw-master comparison stays separate.";
    attribute owner:String="ASCENT cohort join + Lean net accounting";
    attribute evidence:String="macos-development.sysml#costFactor3";
  }
  part auditPlatformGap {
    attribute key:String="platformGap";
    attribute status:String="OPEN";
    attribute observation:String="No current same-work Darwin/Linux pair establishes the residual5x ratio or a post-refactor ratio.";
    attribute closure:String="A shared optimization may help both platforms. Twofold Darwin acceleration is distinct from Darwin becoming at most twice Linux.";
    attribute owner:String="Lean platformGap and twofoldAcceleration";
    attribute evidence:String="macos-development.sysml#platformPhaseCost";
  }
  part auditSemanticRefinement {
    attribute key:String="semanticRefinement";
    attribute status:String="OPEN";
    attribute observation:String="QNT package admission uses abstract profile1 and Required=Set(0,1,2,3,4), not MCP27 files or the real POO inventory. Lean net balance is a premise. Concrete producer/trace refinement remains open.";
    attribute closure:String="Map concrete source events to QNT actions; prove binding/argv/ABI/exception equivalence separately in Lean. Parser or test count is not that proof.";
    attribute owner:String="QNT temporal; Lean semantic";
    attribute evidence:String="models/quint/package_benchmark_admission.qnt";
  }
  part auditEvidenceRouting {
    attribute key:String="evidenceRouting";
    attribute status:String="OPEN";
    attribute observation:String="Registered ASCENT query reports darwin-python-source-chain view unavailable; attestation explicitly means integrity, not truth.";
    attribute closure:String="Restore the maintained source-chain producer/consumer contract without resurrecting caches; absent view is a gap, not zero facts or passed provenance.";
    attribute owner:String="Existing Python + ASCENT evidence owners";
    attribute evidence:String="evidence/scenarios/darwin-acceleration/source-chain.view.json";
  }
  part auditViewAuthority {
    attribute key:String="viewAuthority";
    attribute status:String="PARTIAL";
    attribute observation:String="Existing architecture renderer covers typed macos-development views; the large Darwin acceleration chronology is manually accumulated.";
    attribute closure:String="Generate the current audit table from typed SysML values and label historical prose; full automatic drift rejection and current-source trace extraction remain open.";
    attribute owner:String="SysML authority + Python Org projection";
    attribute evidence:String="src/gambit_smp/architecture_views.py";
  }
  part auditResourcePolicy {
    attribute key:String="resourcePolicy";
    attribute status:String="PARTIAL";
    attribute observation:String="8GiB admission is sum-darwin-phys-footprint, not sum-RSS or unique machine RAM; the Homebrew POO test control also hit it.";
    attribute closure:String="Keep one metric and process-group ownership; separate compiler construction from package/test resources and retain censored outcomes.";
    attribute owner:String="Python observation + QNT custody";
    attribute evidence:String="official-api.observation.json#packageControlComparison/currentPathControl";
  }
  part auditContinuationAndProducts {
    attribute key:String="continuationAndProducts";
    attribute status:String="OPEN";
    attribute observation:String="Native gxpkg executable is absent while dispatch can consume it; source-unchanged clean/build success prevents claiming it explains every timeout.";
    attribute closure:String="Close actual tools-producer/install/dispatch contracts with provider and exception controls before changing runtime loading. Do not count cold executable-image removal as proved seconds.";
    attribute owner:String="Scheme source refinement + native acceptance";
    attribute evidence:String="installedCommandProductAcceptance";
  }

  part publishedPatchBaseline {
    attribute authority:String="Align this released patched concurrent baseline before assigning any twofold budget";
    attribute releaseCommit:String="7f7a1b9877ceb49134a2942dceea492811538741";
    attribute patchset:String="618d76f9eb725e27ce13194514ce5b8ca5489038";
    attribute reconstructedInputs:Integer=26;
    attribute reconstructedPatchsetMatches:Boolean=true;
    attribute workingInputDriftCount:Integer=5;
    attribute archiveSha256:String="0e18d063f888a73d9f9692d441fb3776898114e8440eada6876937d289578183";
    attribute archiveIdentityMeaning:String="Homebrew formula digest equals published release asset digest; archive was not downloaded or reexecuted";
    attribute gerbilSource:String="1cfb032c7a1612637da6205f5f8a15683eba3ba0";
    attribute gambitSource:String="ea114fc3d2f120abbe20393c1f9aeafdd3f8c89f";
    attribute profile:String="gcc16-arm64-aot-tools-single-host-unlimited-multiple-vms";
    attribute compilerConstructionCores:Integer=3;
    attribute packageObservedWorkers:Integer=12;
    attribute concurrencyMeaning:String="Recorded CI construction3 cores is separate from observed package12 workers; neither is a new hardcoded concurrency policy";
    attribute currentMcpBuildMicros:Integer=59247738;
    attribute frozenMcpColdSeconds:String="36.414 /35.552 /37.770; retained qualified six-patch sample, not a new benchmark";
    attribute frozenScope:String="39 files/965 cases versus current MCP27 files; package/state/runtime identity must join before transferring numbers or ceilings";
    attribute serialDiagnostic:String="Missing GERBIL_BUILD_CORES MCP393.33s is excluded, not the baseline for refactor credit";
    attribute installedSurfaces:String="Released bin/gxpkg and bin/gxtags are regular AOT executables; candidate bin launchers are symlinks. Released static-object-reuse and file-sha256 helpers exist; candidate helper products absent. Equivalent contracts remain unqualified";
    attribute candidateBaselineEquivalent:Boolean=false;
    attribute forecastAllowed:Boolean=false;
    attribute evidence:String="evidence/scenarios/darwin-acceleration/baseline-audit.observation.json";
  }

  part aotToolProductsRefactor {
    attribute baseline:String="Published618d76 AOT tools; original source builds a separate optimized-exe phase with force=true in a second frontend process";
    attribute sourceScope:String="Gerbil src/tools/build.ss, src/build.sh and src/gerbil/main.ss only; no runtime/GC/SMP changes";
    attribute replacement:String="One official tools entry owns libraries and dependency-aware exe targets. Keep source lookup explicit, unlink only owned launcher aliases before writes, preserve regular executable products on install, and dispatch through the provider-checked bin/gxpkg product";
    attribute newMechanism:String="Remove forced whole-program target rebuilding and second frontend setup; reuse already built core/native prerequisites. General gerbil command dispatch can consume the native command as well as direct gxpkg";
    attribute acceptance:String="Existing compiler artifact and actual source syntax -> three native tools -> unchanged pass preserves product hash/mtime -> existing CLI/override/failure/GC-continuation controls -> both packages clean/build/original tests";
    attribute existingGainCredit:Integer=0;
    attribute newMeasuredPackageGain:String="Unmeasured; do not infer from the older1973s construction stage or count restored AOT baseline gains twice";
    attribute componentMeasured:Boolean=true;
    attribute productionAndReuseObserved:Boolean=true;
    attribute fullComponentOutcome:String="PASS: run d965fbd64c454d269ccc1a4b6c627730; 24 uninstrumented source stages/controls. First production 153.947290 s and no-change 5.293614 s are different workloads, not patch-relative speedup";
    attribute componentEvidence:String="evidence/scenarios/darwin-acceleration/tool-products.observation.json";
    attribute sourceCommit:String="1575f4d1a1fd688b08670b39476145538a047d6a";
    attribute failureObservation:String="Existing gerbil.test diagnostic binds failed producer, exact application environment, original 1G heap/request t/300s bound. LLDB crash hooks record x5=0xffffffffffffffcc and absent provider among488 images; slot38 is infer-callback-directory-service__%. Runtime dependency evaluation remains unresolved, not GC/SMP attribution; diagnostic PASS never qualifies packages";
    attribute bindingDiagnostic:String="Actual invocation sampled in dyld mapSegments/fcntl; binding equalities subsequently passed in 167.579973 s under the unchanged 180-second deadline. Diagnostic-only; original timeout retained";
    attribute remainingAcceptance:String="All24 component controls passed. Same-binary POO control54be2125 passes148 modules/1752 cases after phase-view repair. Latest request8268677b passes MCP clean/build/all27 test entries; POO clean/build pass but test preparation is interrupted at8.140890GiB under unchanged8GiB footprint limit. Final POO result and whole-run receipt are missing, not passed";
    attribute phaseLibraryView:String="Build frontend source view retires only after terminal clean/build completion. Original tests consume package/.gerbil/lib before compiler/lib. A source-first provider can omit generated fast-entry bindings; no source/binary modification or forced binding is allowed";
    attribute phaseLibraryViewEvidence:String="54be2125e03b4009b7b7a18897f4b842: original source-first context reproduces unbound entry; same binary with compiled view loads provider, passes148 modules, no undefined warnings, exit0/final OK in79.629056s. Acceptance-driver correction earns zero Darwin performance credit; latest MCP package request passed; POO preparation remains open";
    attribute incrementalRetirementGap:String="std/make make selects separate frontend only when every spec output is absent. POO clean excludes test roots;92 retained test interfaces predate8268677b. Existing-output test groups retain expansion contexts; two frontends account for2.19GiB at the footprint stop. Extending handoff requires macro freshness and generated binding identity, not merely removing the guard";
    attribute nativeUnitGap:String="At limit cc1 holds4.13GiB. Its exact argv is missing; table-mapping-test~0.c with6665 labels is only a timestamp-correlated clue. Candidate and current-PATH gambuild-C both use-O1/default SINGLE_HOST_LIMIT0. No heap increase, worker reduction, source reassignment or GC/SMP repair is admitted";
    attribute phaseViewProofRouting:String="ASCENT binds source, environment, producer receipt and positive/negative observations. QNT owns build-completion to test-view publication ordering only; Lean owns source/compiled binding-identity refinement, still open. Neither model proves native correctness or speedup";
    attribute bothPackagesPassed:Boolean=false;
    attribute ownership:String="Existing gerbil.build/test capability and batches/source/CLI owners; closed isolated mutable runtime products and Gerbil sources exclude the Gambit checkout, bootstrap and Git repository; no new framework";
  }

}
