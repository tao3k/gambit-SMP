package GambitRevisionDelivery {
  private import ScalarValues::*;
  ref part admission = GambitCommitGates::tests;
  attribute policy:String="Each REV is an independently reviewable responsibility replacement with its own source tree, tests and five ASCENT gates. A file may contain multiple responsibilities: intermediate trees select exact source blocks, never all staged content. Push only qualified commits; preserve unqualified working research. No patch-series progress transfers to this branch.";
  attribute currentScope:String="Modern C architecture ownership. First select execution-root storage in the existing flat public header and existing build entrypoints; then qualify GC participants/root domains and collector work as distinct dependency-bound trees. Keep configured-tool cleanup, phase-loop edits, global C23 compiler-admission changes and tfib diagnosis parked. No entire-SMP completion claim follows from one REV.";
  attribute currentDeliveryHold:String="Official target names remain unchanged. Configured-tool cleanup and phase-loop changes are parked after user scope correction; no further commit or push of these candidates. The local configured-tool commit was removed from the branch while preserving index/working content. Future selection starts from DEV architecture necessity, not ease of submitting isolated Make changes.";
  attribute architectureOrder:String="execution-context-storage -> root-origin-dispatch -> collector-arena-and-restoration. Entry/exit-root-custody depends on execution storage; VM membership/retirement depends on root dispatch and entry/exit custody. Each successor needs its own exact source tree and native observations; dependency links do not transfer acceptance.";
  attribute firstPatchBoundary:String="Move execution-root storage and every actual accessor to stable VM slots while retaining synchronous binding, pstate_mem, collector algorithm and ordinary configure/Make entries. Preserve descriptor/version and validate existing size checks before cached completion or mutation; held old-layout binaries must remain rejected on repeated load. na and heap_limit stay uniquely with existing call/allocator guards. No new ABI marker, official target rename, cleanup policy or tfib investigation.";
  attribute cuttingRule:String="Aggregate nodes retain historical programme scope and failed observations; they are not submission trees. Current leaf cuts require exact lexical-block selection and a buildable intermediate ABI, with source/output identity and five scoped gates. File-pattern ownership is an inventory aid, not proof that every hunk belongs to one REV. Generated C required by a changed Scheme producer belongs to that same qualified tree, never an unspecified later catch-all commit.";
  attribute testPolicy:String="Existing upstream units, stress and GSI/GSC modes are the baseline. GambitModularSmpValidation TestReview records dispose all20 pending Scheme assets into8 candidate controls; suite/catalog/campaign are removed. A retained case needs a distinct contract gap, authoritative upstream comparison and failure witness or new-interface control. Populations are runtime parameters. Consolidation/source checks are not current native admission; gate each component REV on actual applicable execution and preserve original failures.";
  part def Revision {
    attribute id:String;
    attribute responsibility:String;
    attribute sources:String;
    attribute tests:String;
    attribute retired:String;
    attribute excluded:String;
    attribute aggregate:Boolean default =false;
    attribute activeArchitecture:Boolean default =false;
  }
  part index:Revision {
    attribute :>> id="hash-layout";
    attribute :>> responsibility="GC transports references without changing slot coordinates; readers are pure, writers own address-index repair; decoders root partial payloads before final policy publication";
    attribute :>> sources="lib/_mem/hash-table-api.inc;lib/_mem/object-scanning.inc;lib/_mem/weak-tables.inc;lib/_mem/wills.inc;lib/_system.scm;tests/hash-construction-roots.scm;tests/smp/gc/index-traversal.scm";
    attribute :>> tests="Full two-pass bootstrap <=600s; unchanged original 374-file GSI <=300s; interpreted and compiled traversal/construction; flags-zero negative control; existing hash QNT schedules and separate conditional Lean transport law";
    attribute :>> retired="Collector/thread-count-selected eager reordering and read-side rebuild; flags-zero decoder construction window";
    attribute :>> excluded="Worker/context migration, concurrent same-table mutation, old serialized images, future stable-address indexing, whole SMP acceptance";
  }
  part primitive:Revision {
    attribute :>> id="vector-increment";
    attribute :>> responsibility="Safe compiler specialization validates delta and old element before the atomic increment";
    attribute :>> sources="gsc/_prims.scm;tests/vector-increment-contract.scm";
    attribute :>> tests="New compiler build; invalid delta and old element rejected without mutation; valid default/explicit delta return old value; interpreted and compiled fixture";
    attribute :>> retired="Unchecked safe-mode general-vector increment operands";
    attribute :>> excluded="Other primitive changes and unsafe-mode policy";
  }
  part generatedProducts:Revision {
    attribute :>> id="generated-products";
    attribute :>> responsibility="Publish the generated C products required by committed Scheme generator/runtime changes through the existing GENDISTFILES/select-gen-for-commit mechanism; retain the ordinary core build path";
    attribute :>> sources="gsc/_*.c;gsi/_*.c;lib/_*.c";
    attribute :>> tests="Generate using the existing default CI configuration, not SMP-private library features; clean native objects, install dummy seed and run original core/check; retain exact producer/output identities and separately restore the qualified SMP products in the same workspace";
    attribute :>> retired="Stale checked-in generated C after a source/golden change; forcing every existing CI core job through extra bootstrap rounds";
    attribute :>> excluded="No manual generated-code edits, golden refresh, extra SDK copy or implication that SMP-generated _thread.c is a portable default snapshot. Bootstrap qualification remains independent of ordinary core jobs";
  }
  part ciTools:Revision {
    attribute :>> id="ci-tooling";
    attribute :>> responsibility="Correct package/m4 prerequisites and repository-owned integration hooks while preserving existing core build commands and platform coverage";
    attribute :>> sources=".github/workflows/ci.yml";
    attribute :>> tests="Before publication: native YAML/schema checks, unchanged Build/Test commands and matrix, negative controls. After publication: separately observed remote package/build/test outcomes; both MinGW architectures remain; original core commands retained";
    attribute :>> retired="Unused mingw32-make prerequisite and unresolved Linux pkg-config macro";
    attribute :>> excluded="No nested bootstrap chains, platform deletion or local Darwin claims for remote Windows/Linux runs";
  }
  part build:Revision {
    attribute :>> aggregate=true;
    attribute :>> id="build-budget";
    attribute :>> responsibility="Existing Make owns bounded parallel C work; each bootstrap compiler uses one processor; generation depends on effective config; configured tools survive bootclean";
    attribute :>> sources="bin/makefile.in;gsc/makefile.in;gsi/makefile.in;lib/makefile.in;makefile.in;tests/run-unit-tests.scm;configure.ac;include/config.h.in";
    attribute :>> tests="Existing profile/configure/Make, same SDK; two-pass bootstrap <=600s, no-change Make, C-only edit generation count; actual test runtime still requests p2; failure propagation and configuration-dependency inspection";
    attribute :>> retired="Nested compiler processor overcommit, configure-tool invalidation on ordinary bootclean and successful recursive Make hiding earlier failure";
    attribute :>> excluded="New profile layer/executor, front-end macro optimization. C23 admission, conditional Darwin macro diagnostic provenance, cache checkpoints and generation-option defines belong here; modular-header output recipe in configure and worker ABI object rename hunks in lib Make belong to runtime-ownership. Removing macro diagnostics does not remove semantic macro expansion";
  }
  part targetIntegration:Revision {
    attribute :>> id="target-integration";
    attribute :>> responsibility="Normally merge the current PR target, regenerate distribution C from that exact merged Scheme source, and qualify the unchanged stock consumer";
    attribute :>> sources="lib/_num.scm;lib/_num#.scm;lib/_nonstd.scm;lib/os_setup.c;lib/srfi/16/test/test.scm;tests/unit-tests;lib/_*.c;gsi/_*.c;gsc/_*.c";
    attribute :>> tests="Exact two-parent candidate; complete source bootstrap within 600s; clean objects, dummy seed, unchanged core and full original check including target regression additions; preserve pending index/working research; actual remote checks after push";
    attribute :>> retired="Merged-source/default-product skew, notably the atanh large-imaginary regression; force-push or changing core to hide stale products";
    attribute :>> excluded="No new numeric algorithm, test weakening, claim that branch-local observations qualify a different merge tree, or implication that pending SMP ownership changes passed";
  }
  part buildResources:Revision {
    attribute :>> aggregate=true;
    attribute :>> id="build-resources";
    attribute :>> responsibility="Existing Make owns generation parallelism; bootstrap compiler invocations request one processor; configured tools survive bootclean, failed phases stop, and unchanged non-Git stamps preserve timestamps";
    attribute :>> sources="bin/makefile.in;gsc/makefile.in;gsi/makefile.in;lib/makefile.in;makefile.in;include/makefile.in;configure.ac;tests/run-unit-tests.scm";
    attribute :>> tests="Existing Bazel SMP/C23 service, same workspace, complete two-pass bootstrap <=600s; complete original check targets; affected compiled cases with runtimep2; two no-change cores, one C-only edit and restoration, compilerp1/runtimep2 controls, first-phase failure control";
    attribute :>> retired="Nested initial compiler processor multiplication under accumulated runtime options; configured helper invalidation on bootclean; later phases after an earlier failure; unchanged empty stamp forcing kernel rebuild";
    attribute :>> excluded="Strict cross-platform C23 configure admission, raw generation-option escaping/invalidation, modular header publication, runtime ABI and full SMP qualification remain separate. Exclusive comma runtime options are outside the managed profile; initial processor bounds are not OS-thread quotas or speedup claims";
  }
  part testEntry:Revision {
    attribute :>> id="test-entry";
    attribute :>> responsibility="Standalone C controls share an entry adapter matching configured WinMainCRTStartup while preserving their void-argument bodies, exit status and ordinary main on other configurations";
    attribute :>> sources="tests/test-entry.h;tests/test-entry.c;tests/stack-overflow-undo.c;tests/native-scope.c;tests/frame-contract.c;tests/makefile.in";
    attribute :>> tests="Exact old assertion bodies; original stack/native-scope/frame controls and multi-shot/root consumers; adapter single-call/nonzero-return control; source/distribution closure; actual Windows ABI/link result after push";
    attribute :>> retired="MSVC test12 unresolved WinMain and the same missing entry in the subsequent standalone controls";
    attribute :>> excluded="No Scheme test rewrite, runtime entry redesign, C++ modernization, configure/build-command change or Windows ABI claim from a synthetic non-Windows control. Pending native-scope deletion/write-authority rename stays separate";
  }
  part publication:Revision {
    attribute :>> id="shared-publication";
    attribute :>> responsibility="Shared pipe peers own one guard; detached rooted FIFO cells link without safepoints; lock publication uses acquire/release ordering";
    attribute :>> sources="lib/_fifo#.scm;lib/_io.scm;lib/_thread.scm;lib/os_thread.c;include/_gambit/synchronization.h.in;tests/ordered-sync.c;tests/smp/scheduler";
    attribute :>> tests="Original GSI/GSC shared-pipe cases, ordered lock/slot controls, ordered mailbox and blocked-cell root schedules; source review lock-to-park boundary";
    attribute :>> retired="Distinct peer guards, allocation inside publication ownership, relaxed lock handoff";
    attribute :>> excluded="Embedded-C context field accesses share runtime ABI cohort; split only if intermediate flat header and callers remain buildable";
  }
  part runtime:Revision {
    attribute :>> aggregate=true;
    attribute :>> id="runtime-ownership";
    attribute :>> responsibility="Execution context owns Scheme roots and resume state; participant owns round membership; collector worker owns copy/scan arena; write authority and lifecycle custody replace carrier-derived authority";
    attribute :>> sources="include/_gambit;include/gambit.h.in;include/config.h.in;include/makefile.in;configure.ac;lib/_mem;lib/_setup;lib/mem.c;lib/mem.h;lib/setup.c;lib/c_intf.c;lib/c_intf.h;lib/write_authority.c;lib/write_authority.h;lib/native_scope.c;lib/native_scope.h;lib/os_dyn.c;lib/os_setup.c;lib/_kernel.scm;lib/_num.scm;lib/_system.scm;lib/_io.scm;lib/_thread.scm;gsc/igsc.scm;examples/tcltk/tcltk.scm;lib/makefile.in;tests/stack-overflow-undo.c;tests/frame-contract.c;tests/frame-continuation.scm;tests/frame-continuation-roots.scm;tests/gc-root-task.c;tests/runtime-roles.c;tests/sfun-exit.scm;tests/write-authority.c;tests/native-scope.c;tests/smp/gc;tests/smp/control";
    attribute :>> tests="Full bootstrap, map multi-shot plus GC roots, W<R worker restoration, independent refill/handoff, unknown join with healthy VM GC, writer-exit and cleanup custody; exact source/model premises and explicit remaining obligations";
    attribute :>> retired="Carrier-indexed collector ownership, parallel native_scope aliases, implicit PSTATE roots and unowned scan/copy responsibilities only where actual callers replaced";
    attribute :>> excluded="Generational collector, broad CFFI redesign, forced recovery from unknown native writes, full 12-requirement acceptance without own observations. Headers and ABI consumers must be one buildable tree; organization alone confers no semantic closure";
  }
  part testInventory:Revision {
    attribute :>> id="test-inventory";
    attribute :>> responsibility="Official runner and Make remain the execution interfaces; eight necessary component controls replace twenty pending SCM assets; source distribution includes each surviving source";
    attribute :>> sources="tests/smp;tests/sfun-exit.scm;tests/makefile.in";
    attribute :>> tests="Twenty native-SysML dispositions with actual ASCENT missing-source/archive/official/target controls; unchanged original mailbox assertions and limits; each surviving component scenario must compile and execute with its actual implementation tree before submission";
    attribute :>> retired="Parallel suite/catalog/campaign, local-path diagnostic campaigns and duplicated compile products; winding and cyclic-root cases reuse existing necessary consumers";
    attribute :>> excluded="Source review and bounded native cases do not admit the entire SMP runtime. Archived failures remain failed; no new QNT/Lean model, runner or framework. These uncommitted controls accompany their own implementation REVs; tfib investigation and SMP-wide repair are outside this inventory cut";
  }
  part ci:Revision {
    attribute :>> id="github-ci";
    attribute :>> responsibility="Gambit repository SMP CI reuses configure/Make and official GSI/GSC/stress runner with processor options; component controls join only after their implementation REV qualifies";
    attribute :>> sources=".github/workflows/smp.yml";
    attribute :>> tests="Workflow syntax and official entrypoint correspondence, C23/profile equivalence, source archive closure and real official SMP runs; remote exact-head CI remains separately observed after push";
    attribute :>> retired="SMP parent repository ownership of vendor runtime CI";
    attribute :>> excluded="No local result is remote CI success; no unqualified runtime dependency may be pushed through CI REV";
  }
  part def Dependency { ref part predecessor:Revision; ref part successor:Revision; }
  part d0:Dependency { ref part :>> predecessor=index; ref part :>> successor=primitive; }
  part d1:Dependency { ref part :>> predecessor=index; ref part :>> successor=runtime; }
  part d2:Dependency { ref part :>> predecessor=build; ref part :>> successor=runtime; }
  part d3:Dependency { ref part :>> predecessor=runtime; ref part :>> successor=testInventory; }
  part d4:Dependency { ref part :>> predecessor=publication; ref part :>> successor=testInventory; }
  part d5:Dependency { ref part :>> predecessor=testInventory; ref part :>> successor=ci; }
  part d6:Dependency { ref part :>> predecessor=primitive; ref part :>> successor=generatedProducts; }
  part d7:Dependency { ref part :>> predecessor=generatedProducts; ref part :>> successor=ciTools; }
  part d8:Dependency { ref part :>> predecessor=ciTools; ref part :>> successor=targetIntegration; }
  part d9:Dependency { ref part :>> predecessor=targetIntegration; ref part :>> successor=buildResources; }
  part d10:Dependency { ref part :>> predecessor=buildResources; ref part :>> successor=runtime; }
  part d11:Dependency { ref part :>> predecessor=targetIntegration; ref part :>> successor=testEntry; }
  part toolsLifecycle:Revision {
    attribute :>> id="configured-tool-lifetime";
    attribute :>> responsibility="Configured tool templates and installed aliases belong to configure/Make configuration, while bootclean owns generated compiler products";
    attribute :>> sources="bin/makefile.in";
    attribute :>> tests="Predecessor deletes configured tools; new bootclean preserves exact bytes, mtimes and alias targets; repeated core does no helper regeneration; clean/distclean/realclean semantics unchanged";
    attribute :>> retired="bootclean inheriting tool/configuration deletion";
    attribute :>> excluded="No compiler scheduler, configure flags, runtime ABI, new fixture or SMP acceptance";
  }
  part configureCheckpoint:Revision {
    attribute :>> id="configure-cache-checkpoints";
    attribute :>> responsibility="Existing Autoconf cache retains completed probes while interrupted configuration remains unqualified";
    attribute :>> sources="configure.ac";
    attribute :>> tests="Exact AC_CACHE_SAVE hunks only; completed probe reuse, interrupted configure rejection and normal completed configuration; no duplicate native executor";
    attribute :>> retired="Completed probe loss after interruption";
    attribute :>> excluded="Not a completed configure receipt, new configuration source or compiler/runtime semantic change";
  }
  part phaseFailure:Revision {
    attribute :>> id="bootstrap-phase-failure";
    attribute :>> responsibility="The phases owner propagates the first failed recursive Make result and never enters later phases";
    attribute :>> sources="makefile.in";
    attribute :>> tests="Original phase order with successful child; phase1 and middle-phase failures stop exactly; genuine existing from-scratch caller sees nonzero; no Scheme/C payload changes";
    attribute :>> retired="successful loop status masking an earlier failed phase";
    attribute :>> excluded="No capacity, GC, compiler resource policy, timeout increase or change to ordinary CI core command";
  }
  part compilerExecution:Revision {
    attribute :>> id="compiler-execution-budget";
    attribute :>> responsibility="Existing Make jobserver owns compile jobs; each gsc-boot process owns one compiler processor; official runner keeps target runtime population separate";
    attribute :>> sources="gsc/makefile.in;gsi/makefile.in;lib/makefile.in;tests/run-unit-tests.scm";
    attribute :>> tests="Exact invocation hunks excluding config.h dependencies; emitted product equivalence; compilerp1/runtimep2; relevant original GSC cases and complete selected producer; preserve failed mixed-tree history";
    attribute :>> retired="unbounded nested compiler initial contexts and per-action buffering overhead";
    attribute :>> excluded="No promise of OS-thread quota, unmanaged macro input admission or runtime SMP correctness";
  }
  part generationConfig:Revision {
    attribute :>> id="generation-input-identity";
    attribute :>> responsibility="Effective Scheme generation inputs invalidate generated C through existing config.h and Make prerequisites";
    attribute :>> sources="configure.ac;include/config.h.in;lib/makefile.in;gsc/makefile.in;gsi/makefile.in";
    attribute :>> tests="Exact metadata encoding/escaping cases; unchanged-config no-op; changed-generation options invalidate correct outputs; C-only changes regenerate no Scheme";
    attribute :>> retired="timestamp-only or missing generation-option dependency";
    attribute :>> excluded="No typed profile layer, shell execution wrapper or relaxed input encoding";
  }
  part headerSource:Revision {
    attribute :>> id="public-header-source";
    attribute :>> responsibility="Private source fragments compose one configured public gambit.h with lossless ordered content and no new public include namespace";
    attribute :>> sources="include/gambit.h.in;include/_gambit;include/makefile.in;configure.ac";
    attribute :>> tests="Extract organization-only intermediate tree before semantic role changes; exact reconstruction and configuration/preprocessor equivalence; strict patch check; source distribution and ordinary C consumers";
    attribute :>> retired="monolithic header source ownership";
    attribute :>> excluded="Current37 EOF diagnostics remain unresolved; do not trim payload or combine semantic layout changes merely to publish organization";
  }
  part c23Support:Revision {
    attribute :>> id="c23-toolchain-admission";
    attribute :>> responsibility="Declare and qualify the C23 compiler/platform support contract through existing configure";
    attribute :>> sources="configure.ac;include/config.h.in";
    attribute :>> tests="Supported compiler probes and rejection controls; each changed platform tested before its claim; retain published CI evidence separately";
    attribute :>> retired="implicit mixed C dialect assumptions";
    attribute :>> excluded="Current GNU C23 success does not admit MSVC; no silently removed platform or C++ reconstruction";
  }
  part darwinDiagnostics:Revision {
    attribute :>> id="darwin-diagnostic-provenance";
    attribute :>> responsibility="Use supported GCC diagnostic provenance control without claiming removal of semantic macro expansion";
    attribute :>> sources="configure.ac";
    attribute :>> tests="Darwin GNU positive and unsupported-option negative probes; generated/token equivalence; no option added to other compilers";
    attribute :>> retired="unbounded diagnostic expansion provenance only where supported";
    attribute :>> excluded="No front-end optimization project, matched speedup or MLIR implementation";
  }
  part stampLifecycle:Revision {
    attribute :>> id="unchanged-header-stamp";
    attribute :>> responsibility="Existing non-Git stamp generation changes its timestamp only when content changes";
    attribute :>> sources="include/makefile.in";
    attribute :>> tests="Non-Git unchanged repeated core preserves stamp mtime and kernel freshness; real version change invalidates kernel; ordinary Git source retains original route";
    attribute :>> retired="empty stamp recreation forcing unrelated native recompilation";
    attribute :>> excluded="Select stamp-only hunk; header composition remains separate";
  }
  part runtimeBinding:Revision {
    attribute :>> activeArchitecture=true;
    attribute :>> id="execution-context-storage";
    attribute :>> responsibility="VM-owned execution_context replaces PSTATE storage for10 execution-root field families; existing public GVM accessors and setup entrypoints bind it before helpers and early primary interrupts";
    attribute :>> sources="include/gambit.h.in;lib/_mem/allocation-limits.inc;lib/_mem/allocation-statistics.inc;lib/_mem/capacity-resize.inc;lib/_mem/collection-round.inc;lib/_mem/configuration.inc;lib/_mem/continuation-roots.inc;lib/_mem/diagnostics.inc;lib/_mem/memory-lifecycle.inc;lib/setup.c;lib/os_setup.c;gsc/_t-cpu-abstract-machine.scm;tests/frame-spec.scm;lib/_io.scm;lib/_kernel.scm;lib/_num.scm;tests/runtime-roles.c;tests/stack-overflow-undo.c;tests/makefile.in";
    attribute :>> tests="Exact selected flat-header tree;10 moved root field families and all direct/header/embedded-C consumers; early and regular binding source review; C bridge uses actual offsetof; carrier-only CPU coordinates checked against real C declarations; repeated held old-module rejection before any fixup-state mutation required; original storage/overflow/frame/map/GC/embedding consumers and GSI/GSC; complete bootstrap <=600s through unchanged Make/Bazel service; required default generated products included with the source REV";
    attribute :>> retired="PSTATE payload for stack_limit/fp/stack_start/stack_break/hp/r/pc/saved/type_cache/processor_scmobj; direct carrier-field consumers of those roots";
    attribute :>> excluded="Scalar na/heap_limit retain unique carrier storage; generic CPU instruction dispatch/register allocation are unchanged. Allocator/RC/still and collector work remain in the existing pstate_mem for this transitional cut. No participant protocol, new worker/arena, W<R scheduling, live rebinding, owner death recovery, CFFI policy, cleanup change, header-module split or whole GC correctness claim";
  }
  part rootDispatch:Revision {
    attribute :>> activeArchitecture=true;
    attribute :>> id="root-origin-dispatch";
    attribute :>> responsibility="Frozen RootOrigin and epoch-bound RootTask own scan responsibility independently of collector carrier index";
    attribute :>> sources="lib/_mem/root-origins.inc;lib/_mem/rc-roots.inc;lib/_mem/collection-round.inc;lib/_mem/object-allocation.inc;include/_gambit/runtime_roles.h.in;tests/gc-root-task.c";
    attribute :>> tests="Source caller/producer closure, publish/claim/retire ordering, existing QNT schedule premises and distinct Lean coverage premises, targeted actual root scans";
    attribute :>> retired="carrier-index-derived root scan authority where callers replaced";
    attribute :>> excluded="Root freeze and physical writer-stop assumptions must be explicit; no duplicate QNT/Lean or universal writer closure claim";
  }
  part workerMemory:Revision {
    attribute :>> activeArchitecture=true;
    attribute :>> id="collector-arena-and-restoration";
    attribute :>> responsibility="Collector worker owns copy/scan arena; each execution context owns its restoration grant; root population and worker population are distinct";
    attribute :>> sources="lib/mem.c;lib/_mem/movable-sections.inc;lib/_mem/heap-sections.inc;lib/_mem/copy-reservations.inc;lib/_mem/object-scanning.inc;lib/_mem/continuation-roots.inc;lib/_mem/collection-round.inc;include/_gambit/runtime_roles.h.in;tests/frame-continuation.scm;tests/frame-continuation-roots.scm;tests/smp/gc/worker-arena.scm;tests/smp/gc/worker-root-domains.scm";
    attribute :>> tests="Exact selected intermediate tree, contiguous reservation/refund and scan ownership, W<R restore/owner-cleanup, unchanged heap; existing capacity/copy models retain their obligations";
    attribute :>> retired="collector copy state and restoration policy borrowed implicitly from carrier PSTATE";
    attribute :>> excluded="Physical packing and writer closure remain separate open premises. Parked tfib evidence is not a new debugging assignment in this delivery";
  }
  part entryRoots:Revision {
    attribute :>> activeArchitecture=true;
    attribute :>> id="entry-exit-root-custody";
    attribute :>> responsibility="Generated callbacks and RC borrowers preserve roots through conversion, marker allocation and nonlocal physical unwind";
    attribute :>> sources="lib/mem.h;lib/os_dyn.c;include/_gambit/foreign_abi.h.in;include/_gambit/foreign_conversion.h.in;include/_gambit/write_authority.h.in;lib/c_intf.c;lib/c_intf.h;lib/write_authority.c;lib/write_authority.h;lib/native_scope.c;lib/native_scope.h;lib/_mem/rc-allocation.inc;lib/_mem/rc-roots.inc;lib/_mem/still-refcount.inc;examples/tcltk/tcltk.scm;tests/sfun-exit.scm;tests/write-authority.c;tests/native-scope.c";
    attribute :>> tests="Actual generator/entry/exit callers, protected conversions and nonlocal unwind with original embedding controls; retire native_scope with all consumers in one buildable cut; generated payloads qualified";
    attribute :>> retired="parallel native_scope naming and unowned callback root-bank lifetime";
    attribute :>> excluded="Minimal entry root contract only; broad CFFI redesign, Tcl service redesign and arbitrary unknown native writes remain future work";
  }
  part vmMembership:Revision {
    attribute :>> activeArchitecture=true;
    attribute :>> id="vm-membership-and-retirement";
    attribute :>> responsibility="VM registry owns membership publication and cleanup permission; resize owns source-root custody and failed/unpublished actor isolation";
    attribute :>> sources="lib/mem.h;lib/_setup;lib/setup.c;lib/os_thread.c;lib/_mem/memory-lifecycle.inc;lib/_mem/capacity-resize.inc;lib/_mem/still-sweep.inc;include/_gambit/vm_state.h.in;tests/smp/gc/vm-lifecycle.scm;tests/smp/gc/vm-lifecycle-host.scm;tests/smp/gc/unknown-join-worker-domains.scm";
    attribute :>> tests="Actual setup/cleanup/resize callers, retained destructor outcome, host global receipt, partial creation and unknown join; healthy VM GC with exact roots; existing lifecycle models only";
    attribute :>> retired="global cleanup inferred from one VM and lost startup/root debt";
    attribute :>> excluded="No owner-death recovery without a physical stop, natural quarantine reaping or all SMP failures solved";
  }
  part cutDependency0:Dependency { ref part :>> predecessor=toolsLifecycle; ref part :>> successor=compilerExecution; }
  part cutDependency1:Dependency { ref part :>> predecessor=phaseFailure; ref part :>> successor=compilerExecution; }
  part cutDependency2:Dependency { ref part :>> predecessor=compilerExecution; ref part :>> successor=generationConfig; }
  part cutDependency5:Dependency { ref part :>> predecessor=runtimeBinding; ref part :>> successor=rootDispatch; }
  part cutDependency6:Dependency { ref part :>> predecessor=rootDispatch; ref part :>> successor=workerMemory; }
  part cutDependency7:Dependency { ref part :>> predecessor=runtimeBinding; ref part :>> successor=entryRoots; }
  part cutDependency8:Dependency { ref part :>> predecessor=rootDispatch; ref part :>> successor=vmMembership; }
  part cutDependency9:Dependency { ref part :>> predecessor=entryRoots; ref part :>> successor=vmMembership; }
  part cutDependency10:Dependency { ref part :>> predecessor=workerMemory; ref part :>> successor=testInventory; }
  part cutDependency11:Dependency { ref part :>> predecessor=vmMembership; ref part :>> successor=testInventory; }
  part cutDependency12:Dependency { ref part :>> predecessor=publication; ref part :>> successor=testInventory; }
  part cutDependency13:Dependency { ref part :>> predecessor=generationConfig; ref part :>> successor=ci; }
  part compilerScript:Revision {
    attribute :>> id="compiler-script-entry";
    attribute :>> responsibility="The existing polyglot igsc entry canonicalizes script argv and selects its interpreter from the environment once";
    attribute :>> sources="gsc/igsc.scm";
    attribute :>> tests="Both script entry locations, whitespace-safe argv, runtime-directory options removed exactly once and real Scheme-to-C producer with unchanged effective arguments";
    attribute :>> retired="Divergent host/script argv normalization and unquoted shell argument forwarding";
    attribute :>> excluded="Existing entry only; no new shell runner, profile or frontend optimization";
  }
  part diagnosticCoordinates:Revision {
    attribute :>> id="memory-source-coordinates";
    attribute :>> responsibility="Maintain source diagnostic line coordinates after memory-body edits; these are metadata-only hunks, not collector or context ownership replacements";
    attribute :>> sources="lib/_mem/aligned-allocation.inc;lib/_mem/global-bindings.inc;lib/_mem/permanent-allocation.inc;lib/_mem/symbols.inc";
    attribute :>> tests="Exact directive-only diff and unchanged preprocessed semantic tokens; associate each coordinate update with its actual accepted source change before selecting a later tree";
    attribute :>> retired="Stale diagnostic coordinates only";
    attribute :>> excluded="Parked metadata; no runtime improvement, SMP progress or reason to prioritize this ahead of architecture work";
  }
  part scriptDependency:Dependency { ref part :>> predecessor=compilerScript; ref part :>> successor=compilerExecution; }
}
