/* Architecture requirements and proposed proof duties only. No runtime or generator implementation. */
package GambitNativeDescriptor {
    private import ScalarValues::*;
    enum def BindingState { Reserved; Preparing; NativeReady; Initializing; RetainedAfterFailure; Closing; Drained; }
    part def DescriptorQualification {
        attribute exposed : Boolean;
        attribute tablesInitialized : Boolean;
        attribute labelsResolved : Boolean;
        attribute rootHandoffAccepted : Boolean;
        attribute exactAbiAgreement : Boolean;
        attribute setupOwnerUnique : Boolean;
        attribute retired : Boolean;
        attribute allProducersMigrated : Boolean;
        attribute allConsumersMigrated : Boolean;
        attribute controlAndFailureAccepted : Boolean;
        attribute oldArtifactsHandled : Boolean;
    }
    requirement def NativeExposureLaw {
        subject witness : DescriptorQualification;
        require constraint { not witness.exposed or
            (witness.tablesInitialized and witness.labelsResolved and witness.rootHandoffAccepted and
             witness.exactAbiAgreement and witness.setupOwnerUnique) }
    }
    requirement def DescriptorRetirementLaw {
        subject witness : DescriptorQualification;
        require constraint { not witness.retired or
            (witness.allProducersMigrated and witness.allConsumersMigrated and
             witness.controlAndFailureAccepted and witness.oldArtifactsHandled) }
    }

    part def DescriptorField {
        attribute fieldId : String;
        attribute record : String;
        attribute fields : String;
        attribute semanticOwner : String;
        attribute nativeOwner : String;
        attribute invariant : String;
        attribute sourceRefs : String;
    }
    part descriptorField0 : DescriptorField {
        attribute :>> fieldId = "MS-IDENTITY";
        attribute :>> record = "ModuleSpec / AbiShape";
        attribute :>> fields = "ModuleKey; semanticDigest; layoutContractDigest; target triple/data model; object tags; label/host mode; effective defines/include order; producer/consumer identities";
        attribute :>> semanticOwner = "Scheme module identity and semantic graph";
        attribute :>> nativeOwner = "Target encoder owns representation; actual C compiler owns C ABI";
        attribute :>> invariant = "A matching digest identifies a declared contract, not a proof; reject incompatible layout/call/GC policy even if sizeof agrees";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:1189-1205; vendor/gambit/lib/setup.c:1585-1615";
    }
    part descriptorField1 : DescriptorField {
        attribute :>> fieldId = "MS-TABLES";
        attribute :>> record = "ModuleSpec";
        attribute :>> fields = "Ordered supplied/demanded modules; symbol/keyword/global names; supplied prefix; typed constants/relocations; PointId and FrameSpec index; setup and init effect declarations";
        attribute :>> semanticOwner = "Scheme owns identity, ordering, binding meaning and effects";
        attribute :>> nativeOwner = "Encoder emits bounded tables and typed relocation kinds";
        attribute :>> invariant = "Counts equal complete table extents; every reference resolves within the accepted image/domain; order and supplied prefix preserved";
        attribute :>> sourceRefs = "vendor/gambit/include/gambit.h.in:11877-11901; vendor/gambit/lib/setup.c:1620-1737; vendor/gambit/gsc/_t-c-1.scm:2194-2244";
    }
    part descriptorField2 : DescriptorField {
        attribute :>> fieldId = "MS-INSTANCE";
        attribute :>> record = "LoadedImage / BindingInstance";
        attribute :>> fields = "BindingDomain; instance generation; private resolved tables; label/host addresses; module Scheme descriptor; setup attempt; entered and completed stages; root/metadata leases";
        attribute :>> semanticOwner = "Scheme chooses interning/global domains and init order";
        attribute :>> nativeOwner = "Runtime owns resolved storage, synchronization, roots and leases";
        attribute :>> invariant = "Immutable blueprint never receives fixup stores; retain explicitly scoped sharing only; current globals are not proved VM-local";
        attribute :>> sourceRefs = "vendor/gambit/lib/setup.c:1476-1518; vendor/gambit/lib/setup.c:1522-1584; vendor/gambit/lib/setup.c:1740-1844; vendor/gambit/lib/_kernel.scm:5275-5337";
    }
    part descriptorField3 : DescriptorField {
        attribute :>> fieldId = "FS-SEMANTIC";
        attribute :>> record = "FrameSpec";
        attribute :>> fields = "PointId=(artifact/module identity, point ordinal); kind normal/task/internal; source logical slots; return link; semantic live managed locations; saved GVM registers; debug location";
        attribute :>> semanticOwner = "Scheme liveness, call/return meaning and continuation semantics";
        attribute :>> nativeOwner = "Native lowering maps semantic locations to physical stack and heap slots";
        attribute :>> invariant = "Every live managed value at each admitted checkpoint is represented; unknown inline C/FFI effects require annotation, conservative coverage or refusal";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-2.scm:825-905; vendor/gambit/gsc/_t-c-3.scm:471-484";
    }
    part descriptorField4 : DescriptorField {
        attribute :>> fieldId = "FS-PHYSICAL";
        attribute :>> record = "FrameLayout / LabelResolver";
        attribute :>> fields = "Stack fs versus internal cfs; physical fs; reserve/alignment; link index; inline/out-of-line encoding; map word count; stack/heap coordinate transforms; target address resolver";
        attribute :>> semanticOwner = "Scheme consumes generated target constraints without duplicating constants";
        attribute :>> nativeOwner = "One target-layout description generates encoder and decoder; C compiler validates ordinary struct layout";
        attribute :>> invariant = "Internal size transform is applied exactly once; 32-bit map chunks compose correctly on 32/64-bit words; bounds and no shift overflow required";
        attribute :>> sourceRefs = "vendor/gambit/gsc/_t-c-1.scm:206-218; vendor/gambit/gsc/_t-c-3.scm:489-532; vendor/gambit/include/gambit.h.in:9208-9324; vendor/gambit/include/gambit.h.in:11775-11819";
    }
    part descriptorField5 : DescriptorField {
        attribute :>> fieldId = "FS-CUSTODY";
        attribute :>> record = "FrameInstance / MetadataLease";
        attribute :>> fields = "Stack-or-heap origin; owner/context; relocation epoch; descriptor/image lease; initialized slots; scanner participation; pending capture/restore custody";
        attribute :>> semanticOwner = "Scheme owns control effects and observable frame operations";
        attribute :>> nativeOwner = "Runtime preserves current locations, read/update rules and metadata backing";
        attribute :>> invariant = "Stable PointId is not an address; GC updates roots; restoration uses a live resolver and current roots; frame writers and deserializers remain governed";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3658-3808; vendor/gambit/lib/mem.c:3890-3968; vendor/gambit/lib/_kernel.scm:3342-3597; vendor/gambit/lib/_io.scm:11688-11730";
    }

    part def DescriptorConsumer {
        attribute fieldRefs : String;
        attribute migrationRefs : String;
        attribute routeId : String;
        attribute producer : String;
        attribute consumer : String;
        attribute sourceRefs : String;
        attribute observation : String;
        attribute requiredChange : String;
        attribute retirementGate : String;
        attribute proofRefs : String;
    }
    part descriptorConsumer0 : DescriptorConsumer {
        attribute :>> fieldRefs = "MS-IDENTITY; MS-TABLES; MS-INSTANCE";
        attribute :>> migrationRefs = "DM-INSTANCE; DM-BIND";
        attribute :>> routeId = "MC-BIND";
        attribute :>> producer = "ModuleSpec tables";
        attribute :>> consumer = "setup_module_fixup / make_global / fixrefs";
        attribute :>> sourceRefs = "vendor/gambit/lib/setup.c:1385-1518; vendor/gambit/lib/setup.c:1522-1844";
        attribute :>> observation = "Aligned tables, tagged references, interned identities and supplied-global order; fixup mutates module flags before later failures";
        attribute :>> requiredChange = "Validate first; separate shared blueprint from mutable instance and publish only after accepted root/address/table state";
        attribute :>> retirementGate = "Retire macro count/table assembly only when every binding mode and fixup consumer uses the generated contract";
        attribute :>> proofRefs = "ND-ABI; ND-BIND";
    }
    part descriptorConsumer1 : DescriptorConsumer {
        attribute :>> fieldRefs = "MS-IDENTITY; FS-PHYSICAL; FS-CUSTODY";
        attribute :>> migrationRefs = "DM-FRAME";
        attribute :>> routeId = "MC-LABEL";
        attribute :>> producer = "FrameLayout and host mapping";
        attribute :>> consumer = "setup_module_fixup label/host/OFD setup";
        attribute :>> sourceRefs = "vendor/gambit/lib/setup.c:1740-1844; vendor/gambit/include/gambit.h.in:11836-11868";
        attribute :>> observation = "Host function queried for label values; OFD cursor advances using actual fs and target words";
        attribute :>> requiredChange = "Resolve PointId and descriptors into one image-owned mapping; freeze metadata after preparation; raw label identity stays behind an adapter until all readers migrate";
        attribute :>> retirementGate = "No old DEF_LBL_RET/DEF_OFD producer or implicit sequential OFD consumer remains after all roots/control readers migrate";
        attribute :>> proofRefs = "ND-ENCODE; ND-PUBLISH; ND-LIFETIME";
    }
    part descriptorConsumer2 : DescriptorConsumer {
        attribute :>> fieldRefs = "MS-TABLES; MS-INSTANCE";
        attribute :>> migrationRefs = "DM-BIND";
        attribute :>> routeId = "MC-INIT";
        attribute :>> producer = "ModuleSpec setup/init effects";
        attribute :>> consumer = "setup_module_collect_moddescrs; init-mod; init-modules";
        attribute :>> sourceRefs = "vendor/gambit/lib/setup.c:1925-1958; vendor/gambit/lib/_kernel.scm:5122-5129; vendor/gambit/lib/_kernel.scm:5275-5337";
        attribute :>> observation = "Native setup, init_mod and Scheme thunk are different stages; Scheme marks stages before calls";
        attribute :>> requiredChange = "Separate entered from completed receipts while preserving existing reentry/exception/stage observations; manage roots around allocating/callback stages";
        attribute :>> retirementGate = "Retire BEGIN_MOD_PRM/C_INIT/GLO scaffolding only after effects, ordered bindings, recursion and failures have accepted equivalents";
        attribute :>> proofRefs = "ND-BIND; ND-INIT";
    }
    part descriptorConsumer3 : DescriptorConsumer {
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY";
        attribute :>> migrationRefs = "DM-FRAME";
        attribute :>> routeId = "FC-LIVE";
        attribute :>> producer = "FrameSpec/FrameLayout";
        attribute :>> consumer = "mark_continuation / mark_frame";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3808-3968";
        attribute :>> observation = "RETI/RETN decode; stack base/link traversal; map-driven tagged-root updates";
        attribute :>> requiredChange = "Use generated decoder and shared slot transform; preserve final-value publication and post-GC reload";
        attribute :>> retirementGate = "Retire RETI/RETN_GET_FS_LINK_GCMAP macro role after every current and generated consumer uses accepted decoder";
        attribute :>> proofRefs = "ND-ROOT; ND-PUBLISH";
    }
    part descriptorConsumer4 : DescriptorConsumer {
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY";
        attribute :>> migrationRefs = "DM-FRAME";
        attribute :>> routeId = "FC-CAPTURE";
        attribute :>> producer = "FrameSpec/FrameLayout";
        attribute :>> consumer = "mark_captured_continuation / scan ___sFRAME";
        attribute :>> sourceRefs = "vendor/gambit/lib/mem.c:3658-3808; vendor/gambit/lib/mem.c:4092-4180";
        attribute :>> observation = "Stack origin, forwarding, heap frame size/link and GC map all depend on descriptor; not an opaque byte copy";
        attribute :>> requiredChange = "Shared stack-to-heap slot relation and lease; initialize and retain copy/forwarding custody; preserve repeated references";
        attribute :>> retirementGate = "Retire capture-specific layout calculations only after stack/heap relation, special return slots and partial-copy ownership refine";
        attribute :>> proofRefs = "ND-ROOT; ND-CONTROL; ND-LIFETIME";
    }
    part descriptorConsumer5 : DescriptorConsumer {
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY";
        attribute :>> migrationRefs = "DM-FRAME";
        attribute :>> routeId = "FC-RESTORE";
        attribute :>> producer = "FrameSpec/FrameLayout";
        attribute :>> consumer = "break handler / stack section transfer";
        attribute :>> sourceRefs = "vendor/gambit/lib/_kernel.scm:1170-1280; vendor/gambit/lib/mem.c:7238-7320";
        attribute :>> observation = "Copies frame contents, rewrites links, restores return address; break-frame normalization supports tail calls";
        attribute :>> requiredChange = "Shared accessors for both origins, fresh address resolution, special internal returns and frame-space law";
        attribute :>> retirementGate = "Retire manual offset/size rules only after break frames, internal/task/normal returns and tail-call behavior are covered";
        attribute :>> proofRefs = "ND-CONTROL; ND-ENCODE";
    }
    part descriptorConsumer6 : DescriptorConsumer {
        attribute :>> fieldRefs = "FS-SEMANTIC; FS-PHYSICAL; FS-CUSTODY";
        attribute :>> migrationRefs = "DM-FRAME; DM-RETIRE";
        attribute :>> routeId = "FC-WRITE";
        attribute :>> producer = "FrameSpec/FrameLayout";
        attribute :>> consumer = "frame/continuation primitives and actual explode/implode-frame caller";
        attribute :>> sourceRefs = "vendor/gambit/lib/_kernel.scm:3150-3597; vendor/gambit/lib/_io.scm:11688-11730";
        attribute :>> observation = "Frame introspection and raw writes; make-frame roots return label around allocation; reconstitution writes slots via frame-set!";
        attribute :>> requiredChange = "Govern field kind, bounds, root/update obligations and initialization-before-publication; future generational barrier remains separate";
        attribute :>> retirementGate = "Old access macros cannot retire while generated bootstrap, inline C, serialization or extension callers still depend on them";
        attribute :>> proofRefs = "ND-ROOT; ND-CONTROL; ND-LIFETIME";
    }

    part def DescriptorProofDuty {
        attribute dutyId : String;
        attribute ownerPath : String;
        attribute sharedContracts : String;
        attribute quintState : String;
        attribute quintSteps : String;
        attribute quintSafety : String;
        attribute leanRelation : String;
        attribute leanLaw : String;
        attribute premises : String;
        attribute counterexample : String;
        attribute status : String;
    }
    part descriptorProofDuty0 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-ABI";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> sharedContracts = "BF-BUILD-CUT";
        attribute :>> quintState = "abiShape; producerIdentity; consumerIdentity; layoutWitness; admitted";
        attribute :>> quintSteps = "deriveLayout; compareWitness; admit; reject";
        attribute :>> quintSafety = "admitted implies exact relevant target/layout/call and semantic policy agreement";
        attribute :>> leanRelation = "CAbiAgreement target producer consumer with field-offset, alignment, type and convention equations";
        attribute :>> leanLaw = "AcceptedShape implies every declared native field access is representation-compatible; does not imply control/GC safety";
        attribute :>> premises = "Full relevant macro/include/flags closure; Clang-to-GCC witness trust discharged separately; C aliasing/arithmetic assumptions";
        attribute :>> counterexample = "Same sizeof but swapped field meanings or host calling convention";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty1 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-ENCODE";
        attribute :>> ownerPath = "dev/architecture/toolchain";
        attribute :>> sharedContracts = "CONTROL-ORIGIN";
        attribute :>> quintState = "point; kind; logicalFs; physicalFs; link; liveMap; encoded; decoded";
        attribute :>> quintSteps = "lowerFrame; encodeInline; encodeOutline; decode; rejectOverflow";
        attribute :>> quintSafety = "Decoded facts match completed FrameSpec and all accesses remain in bounds";
        attribute :>> leanRelation = "Decode_t(Encode_t(Lower_t(f))) = Lower_t(f) plus StackHeapSlot bijection";
        attribute :>> leanLaw = "For every admitted slot i, mapBit(decode(f),i)=scanPolicy(f,i); internal transform once; chunk concatenation correct";
        attribute :>> premises = "Normal/task/internal coverage; finite width/range and overflow proofs; injective PointId resolver within artifact/domain generation";
        attribute :>> counterexample = "Double RETI expansion or wrong map chunk order loses a live saved register";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty2 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-PUBLISH";
        attribute :>> ownerPath = "dev/architecture/runtime/execution";
        attribute :>> sharedContracts = "ROOT-HANDOFF; GC-WORK-CLOSURE";
        attribute :>> quintState = "instanceState; initializedSlots; roots; metadataReady; publisher; scanner; setupLease";
        attribute :>> quintSteps = "reserve; initialize; registerRoots; prepareLabels; publish; observe; failRetain";
        attribute :>> quintSafety = "published implies initialized descriptor/tables and scanner-visible final roots; one setup owner; failure retains custody";
        attribute :>> leanRelation = "Concrete release/acquire steps refine logical publish/observe and initialized coverage";
        attribute :>> leanLaw = "Each actual scanner observation follows initialization and final root handoff; record publication alone insufficient";
        attribute :>> premises = "Actual C memory-order/lock proof; collector admission; root registration cannot race allocating setup; unknown readers refused";
        attribute :>> counterexample = "Scanner sees publish bit before last GC map or root write";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty3 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-BIND";
        attribute :>> ownerPath = "dev/architecture/runtime/interfaces";
        attribute :>> sharedContracts = "ROOT-HANDOFF";
        attribute :>> quintState = "blueprint; bindingDomain; interner; relocationMap; suppliedOrder; partialResources; setupEntered; setupComplete";
        attribute :>> quintSteps = "resolveName; allocate; fixref; callback; completeSetup; failRetain";
        attribute :>> quintSafety = "Blueprint unchanged; equal semantic names share identity exactly within specified domain; no complete credential on failure";
        attribute :>> leanRelation = "Relate ordered semantic resource graph to resolved instance graph through typed relocations";
        attribute :>> leanLaw = "Binding observations and errors match old ordered producer/consumer trace; every live temporary is rooted";
        attribute :>> premises = "Process/global/VM scope decision; actual interner/global consumer census; irreversible effects are not rollbackable";
        attribute :>> counterexample = "Early SETUP_FIXUP_DONE followed by failure misread as successful retry or shared blueprint mutated by second owner";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty4 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-INIT";
        attribute :>> ownerPath = "dev/architecture/runtime/control";
        attribute :>> sharedContracts = "CONTROL-ORIGIN; RETIRE-WINDOW";
        attribute :>> quintState = "legacyStage; entered; completed; callbackStack; initEffects; failureCustodian";
        attribute :>> quintSteps = "enterNativeInit; enterThunk; callback; nonlocalExit; return; retainFailure";
        attribute :>> quintSafety = "entered is not completed; no success delivery before all required stages; preserve staged reentry policy";
        attribute :>> leanRelation = "Trace relation over calls, stage changes, warnings, bindings, returns and nonlocal exits";
        attribute :>> leanLaw = "Refinement preserves permitted stage/effect/exception observations; no automatic retry of irreversible initialization";
        attribute :>> premises = "Actual module cycle/reentry behavior and dynamic-wind/FFI laws; complete legacy oracle; any semantic change separately admitted";
        attribute :>> counterexample = "Mark stage before throwing, then replay side effect because new service interprets incomplete as safe retry";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty5 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-ROOT";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> sharedContracts = "ROOT-HANDOFF; GC-WORK-CLOSURE";
        attribute :>> quintState = "logicalLive; physicalSlots; initialized; scanMap; rootCut; relocationEpoch; writes; restored";
        attribute :>> quintSteps = "materialize; writeFrame; freeze; scan; relocate; reload; rebuildFrame";
        attribute :>> quintSafety = "Every live managed location covered at admitted checkpoint; scanned slots initialized/tag-valid; restored roots current";
        attribute :>> leanRelation = "locMap maps semantic values to stack/heap slots; observe_after(i)=relocate(observe_frozen(i))";
        attribute :>> leanLaw = "Source liveness plus map/coordinate correctness plus final handoff implies no live root omitted; scanner preserves identity";
        attribute :>> premises = "Whole safepoint/register/FFI census; saved GVM registers; frame mutation and serializer; future generational barriers separately proved";
        attribute :>> counterexample = "Correct struct offsets but missing saved GVM register or stale unrooted return label across allocation";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty6 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-CONTROL";
        attribute :>> ownerPath = "dev/architecture/runtime/control";
        attribute :>> sharedContracts = "CONTROL-ORIGIN";
        attribute :>> quintState = "origin; returnPoint; chain; breakFrames; denv; captureProgress; resumeProgress; effects";
        attribute :>> quintSteps = "captureStack; forwardFrame; restoreHeap; normalizeBreak; tailTransfer; invokeAgain; unwind";
        attribute :>> quintSafety = "No lost copy responsibility; link chain and PointId resolution preserved; proper-tail space bound independent of tail steps";
        attribute :>> leanRelation = "Bisimulation of logical continuation chain and stack/heap representations; trace relation includes denv/wind effects";
        attribute :>> leanLaw = "Capture/restore and repeated invocation preserve logical continuation; tail steps do not accumulate frame debt";
        attribute :>> premises = "Root and encoding duties first; internal/task return routes; cross-C callbacks and origin/lifetime remain explicit";
        attribute :>> counterexample = "Correct GC map but restore wrong internal actual_ra, duplicate tail frame or skip dynamic-wind";
        attribute :>> status = "open-design-only";
    }
    part descriptorProofDuty7 : DescriptorProofDuty {
        attribute :>> dutyId = "ND-LIFETIME";
        attribute :>> ownerPath = "dev/architecture/runtime/gc";
        attribute :>> sharedContracts = "RETIRE-WINDOW; ROOT-HANDOFF";
        attribute :>> quintState = "imageLease; bindingLease; activeFrames; capturedFrames; callbacks; scannerReaders; writers; closing";
        attribute :>> quintSteps = "acquireLease; capture; callbackEnter; closeIngress; drain; release; refuseUnknown";
        attribute :>> quintSafety = "Reclaim only after admitted producers closed and all descriptor/code/root users drained; unknown users retain";
        attribute :>> leanRelation = "Concrete users refine counted lease families and root carriers, including heap frames and foreign callbacks";
        attribute :>> leanLaw = "No surviving continuation/frame references reclaimed descriptor, label address or module instance; failed transfer retains owner";
        attribute :>> premises = "Complete users including serialized restore tokens, debugger/FFI and dynamic unload; weak-memory and origin proof";
        attribute :>> counterexample = "No active calls but stored continuation still names old image; premature table free";
        attribute :>> status = "open-design-only";
    }

    part def DescriptorMigration {
        attribute cutId : String;
        attribute dependsOn : String;
        attribute change : String;
        attribute retiringRole : String;
        attribute gate : String;
        attribute cost : String;
    }
    part descriptorMigration0 : DescriptorMigration {
        attribute :>> cutId = "DM-CONTRACT";
        attribute :>> dependsOn = "";
        attribute :>> change = "Complete Scheme semantic records and target-layout description; preserve existing ABI as explicit initial policy";
        attribute :>> retiringRole = "Manual reserve=3/alignment=4 agreement and duplicated layout policy once all generated users agree";
        attribute :>> gate = "Compiler layout witness, whole field inventory and existing point/root semantics identified; no runtime role retired yet";
        attribute :>> cost = "Schema validation and generation graph dependencies";
    }
    part descriptorMigration1 : DescriptorMigration {
        attribute :>> cutId = "DM-INSTANCE";
        attribute :>> dependsOn = "DM-CONTRACT";
        attribute :>> change = "Split immutable ModuleSpec from resolved image/binding instances; expose entered/completed state and custody";
        attribute :>> retiringRole = "In-place source-blueprint fixups and global FIXUP_DONE-as-only-progress protocol";
        attribute :>> gate = "Binding/global scope, all fixrefs, allocation roots, recursion and failure semantics admitted";
        attribute :>> cost = "Private resolved tables, leases, setup synchronization and staged errors";
    }
    part descriptorMigration2 : DescriptorMigration {
        attribute :>> cutId = "DM-FRAME";
        attribute :>> dependsOn = "DM-CONTRACT; DM-INSTANCE";
        attribute :>> change = "Generate one frame encoder/decoder and explicit PointId resolver; migrate all selected frame readers and writers";
        attribute :>> retiringRole = "DEF_LBL_RET/DEF_OFD/IFD/OFD and implicit OFD table cursor policy at fully migrated roles";
        attribute :>> gate = "GC live/captured scans, capture/restore, stack-limit transfer, primitives and bootstrap-generated C agree";
        attribute :>> cost = "Metadata bytes, address resolution, table lookups or inline generated accessors";
    }
    part descriptorMigration3 : DescriptorMigration {
        attribute :>> cutId = "DM-BIND";
        attribute :>> dependsOn = "DM-INSTANCE; DM-FRAME";
        attribute :>> change = "Publish ready native binding separately from Scheme stage completion; preserve native setup/init/thunk sequence";
        attribute :>> retiringRole = "BEGIN_MOD_SYM_KEY/GLOTBL and MOD_PRM/C_INIT/GLO scaffolding after all consumers migrate";
        attribute :>> gate = "Tail calls, roots, stage/exception/effect observations, preload/dynamic modes and diagnostics accepted";
        attribute :>> cost = "Publication checks and failure retention; callbacks and fresh binding work stay";
    }
    part descriptorMigration4 : DescriptorMigration {
        attribute :>> cutId = "DM-RETIRE";
        attribute :>> dependsOn = "DM-BIND";
        attribute :>> change = "Remove duplicate encoder/layout owners and obsolete compatibility adapters per migrated role";
        attribute :>> retiringRole = "Old count-controlled layout and frame access paths only when full consumer closure permits";
        attribute :>> gate = "Regenerate required bootstraps; audit inline C/FFI and external artifacts; no indefinite dual representation; native gates remain future work";
        attribute :>> cost = "Temporary adapter cost tracked separately; old artifacts explicitly supported by adapter or rejected";
    }

    part def DescriptorGainCase {
        attribute gainId : String;
        attribute removedWork : String;
        attribute addedWork : String;
        attribute metric : String;
        attribute positiveCondition : String;
        attribute refutation : String;
    }
    part descriptorGainCase0 : DescriptorGainCase {
        attribute :>> gainId = "DG-LAYOUT";
        attribute :>> removedWork = "Repeated manual layout definitions and per-module invariant macro construction";
        attribute :>> addedWork = "One generated layout policy, validation and target-identity tracking";
        attribute :>> metric = "Definition owners per layout fact: current at least Scheme+C -> proposed one authored owner; repeated frontend tokens and invalidated actions";
        attribute :>> positiveCondition = "Generator actually replaces old definitions and all consumers; no shadow hand-maintained header";
        attribute :>> refutation = "Generated files merely duplicate still-required old policy or expand the same macro body per TU";
    }
    part descriptorGainCase1 : DescriptorGainCase {
        attribute :>> gainId = "DG-FRONTEND";
        attribute :>> removedWork = "Per-TU parsing/diagnostic work moved into shared invariant helpers and compact descriptors";
        attribute :>> addedWork = "Helper calls or inlining, relocations, table loads, metadata cache pressure";
        attribute :>> metric = "Total tokens/AST nodes and peak compiler memory; cold/no-change/leaf/macro critical path";
        attribute :>> positiveCondition = "Removed compiler work exceeds generator/validation and any runtime overhead satisfies runtime budgets";
        attribute :>> refutation = "All helpers inline into same-size text or descriptors increase hot-loop latency more than budget";
    }
    part descriptorGainCase2 : DescriptorGainCase {
        attribute :>> gainId = "DG-ROOT";
        attribute :>> removedWork = "Drift between Scheme liveness, encoded maps and consumer coordinates";
        attribute :>> addedWork = "Validation, roots, post-GC reload and governed frame writes";
        attribute :>> metric = "Duplicate map/layout interpretations removed; actual root coverage and per-GC scan work measured separately later";
        attribute :>> positiveCondition = "One policy interpreter removes duplicate support while retaining precise scan semantics";
        attribute :>> refutation = "Blindly scanning fewer mature frames without proven barrier/write closure; no GC speedup follows from binding generation";
    }
    part descriptorGainCase3 : DescriptorGainCase {
        attribute :>> gainId = "DG-INSTANCE";
        attribute :>> removedWork = "Repeated immutable descriptor reconstruction or unsafe shared fixup ownership";
        attribute :>> addedWork = "Per-domain state, synchronization, leases, fresh interning/binding as required";
        attribute :>> metric = "Immutable bytes shared versus per-instance bytes; setup work, contention and failure-retained bytes";
        attribute :>> positiveCondition = "Blueprint sharing is real and private-state/synchronization overhead remains bounded";
        attribute :>> refutation = "More per-instance copies than saved preparation; required instantiation cannot be cached away";
    }
    part descriptorGainCase4 : DescriptorGainCase {
        attribute :>> gainId = "DG-TOOLS";
        attribute :>> removedWork = "Handwritten mechanical declarations/adapters and ad hoc offset tracking";
        attribute :>> addedWork = "Extractor/compiler dependencies, target manifests, wrapper code and equivalence maintenance";
        attribute :>> metric = "Old declarations retired; generator executions per relevant ABI identity, added invalidation fanout";
        attribute :>> positiveCondition = "Batch generation cached at complete ABI cut; target compiler owns final C representation";
        attribute :>> refutation = "Run libclang over macro-heavy header for every module; trust Clang layout for GCC without evidence";
    }
    part descriptorGainCase5 : DescriptorGainCase {
        attribute :>> gainId = "DG-BACKENDS";
        attribute :>> removedWork = "Independent semantic rediscovery in future C/LLVM/MLIR/Zig encoders";
        attribute :>> addedWork = "Each admitted encoder plus its target/runtime semantic refinement";
        attribute :>> metric = "Number of semantic/layout facts with one owner; duplicated semantic branches and adapter counts";
        attribute :>> positiveCondition = "All backends consume completed contracts; each replaces a role or delivers separately demonstrated capability";
        attribute :>> refutation = "Second language requires same semantics rewritten and both runtimes permanently maintained without gain";
    }

    part def DescriptorBindingOption {
        attribute optionId : String;
        attribute mechanism : String;
        attribute canReplace : String;
        attribute cannotSupply : String;
        attribute admission : String;
        attribute decision : String;
    }
    part descriptorBindingOption0 : DescriptorBindingOption {
        attribute :>> optionId = "BG-RUST";
        attribute :>> mechanism = "Use rust-bindgen directly: libclang header -> Rust declarations";
        attribute :>> canReplace = "Rust FFI declarations for an actual Rust consumer";
        attribute :>> cannotSupply = "Scheme liveness, root effects, tail calls, continuation state or module initialization policy";
        attribute :>> admission = "A necessary Rust consumer and complete target/header identity; no such consumer required here";
        attribute :>> decision = "Not selected as Gambit core dependency; no Rust introduced";
    }
    part descriptorBindingOption1 : DescriptorBindingOption {
        attribute :>> optionId = "BG-EXTRACT";
        attribute :>> mechanism = "Bindgen-like allowlisted C header/type extractor -> target ABI observation";
        attribute :>> canReplace = "Mechanical declaration import and known foreign C layouts/constants";
        attribute :>> cannotSupply = "GCC equivalence, arbitrary macros, GC effects, ownership or nonlocal control";
        attribute :>> admission = "Exact target/SDK/include/macro/packing/tool inputs; actual production compiler correspondence; static/inline wrappers charged";
        attribute :>> decision = "Useful optional adapter after a small explicit C ABI surface exists; current giant-header replacement alone unqualified";
    }
    part descriptorBindingOption2 : DescriptorBindingOption {
        attribute :>> optionId = "BG-SCHEMA";
        attribute :>> mechanism = "Scheme-owned declarative native contract with multiple interpreters";
        attribute :>> canReplace = "Duplicated internal encoder/decoder declarations and explicit layout rules";
        attribute :>> cannotSupply = "Semantic truth not present in input description; arbitrary FFI extension inference";
        attribute :>> admission = "One authoritative schema; target C compiler computes ordinary struct layout; generated safety/effect gates; old owners retire";
        attribute :>> decision = "Preferred design direction for ModuleSpec/FrameSpec; generator itself remains unimplemented";
    }
    part descriptorBindingOption3 : DescriptorBindingOption {
        attribute :>> optionId = "BG-COMPILER";
        attribute :>> mechanism = "Generated C offsetof/sizeof/assertion witnesses under production compiler";
        attribute :>> canReplace = "Reimplementation of target C struct layout in Scheme/another compiler";
        attribute :>> cannotSupply = "GC root correctness, tagged-frame layout meaning or tail-call protocol";
        attribute :>> admission = "Cross-target-safe evidence without running target executables; object extraction/static diagnostics trust and compiler inputs bound";
        attribute :>> decision = "Complementary qualification alternative; no witness compiled or executed in this study";
    }

    part def DescriptorPipelineNode {
        attribute nodeId : String;
        attribute diagramLabel : String;
        attribute dependsOn : String;
        attribute owner : String;
    }
    part descriptorPipelineNode0 : DescriptorPipelineNode {
        attribute :>> nodeId = "Semantic";
        attribute :>> diagramLabel = "Scheme semantic completion\nModuleSpec + FrameSpec";
        attribute :>> dependsOn = "";
        attribute :>> owner = "Scheme";
    }
    part descriptorPipelineNode1 : DescriptorPipelineNode {
        attribute :>> nodeId = "Layout";
        attribute :>> diagramLabel = "Target layout interpreter\nABI facts + encoder/decoder";
        attribute :>> dependsOn = "Semantic";
        attribute :>> owner = "Native contract generator";
    }
    part descriptorPipelineNode2 : DescriptorPipelineNode {
        attribute :>> nodeId = "Emission";
        attribute :>> diagramLabel = "Modern generated C\nimmutable tables + code + checks";
        attribute :>> dependsOn = "Layout";
        attribute :>> owner = "C emitter";
    }
    part descriptorPipelineNode3 : DescriptorPipelineNode {
        attribute :>> nodeId = "AbiWitness";
        attribute :>> diagramLabel = "Production C ABI witness\nClang observation is conditional";
        attribute :>> dependsOn = "Emission";
        attribute :>> owner = "Target compiler and extraction adapter";
    }
    part descriptorPipelineNode4 : DescriptorPipelineNode {
        attribute :>> nodeId = "Instance";
        attribute :>> diagramLabel = "LoadedImage + BindingInstance\nroots / labels / setup custody";
        attribute :>> dependsOn = "Emission; AbiWitness";
        attribute :>> owner = "Runtime loader";
    }
    part descriptorPipelineNode5 : DescriptorPipelineNode {
        attribute :>> nodeId = "Bound";
        attribute :>> diagramLabel = "Native binding ready\nScheme init stages remain separate";
        attribute :>> dependsOn = "Instance";
        attribute :>> owner = "Runtime and Scheme module owner";
    }
    part descriptorPipelineNode6 : DescriptorPipelineNode {
        attribute :>> nodeId = "Collector";
        attribute :>> diagramLabel = "GC / frame access\nfinal roots + current metadata";
        attribute :>> dependsOn = "Bound";
        attribute :>> owner = "GC";
    }
    part descriptorPipelineNode7 : DescriptorPipelineNode {
        attribute :>> nodeId = "Control";
        attribute :>> diagramLabel = "Capture / restore / tail calls\nstack-heap relation + denv";
        attribute :>> dependsOn = "Bound";
        attribute :>> owner = "Control";
    }
    part descriptorPipelineNode8 : DescriptorPipelineNode {
        attribute :>> nodeId = "Retirement";
        attribute :>> diagramLabel = "Close ingress and drain\ncontinuations / FFI / scanners";
        attribute :>> dependsOn = "Collector; Control";
        attribute :>> owner = "Resource owner";
    }

    part def DescriptorProjection {
        attribute modelSource : String;
        attribute selectorPath : String;
        attribute requestPath : String;
        attribute relation : String;
        attribute scope : String;
    }
    part reasoning : DescriptorProjection {
        attribute :>> modelSource = "dev/architecture/toolchain/models/sysml/native-descriptor.sysml";
        attribute :>> selectorPath = "dev/modeling/ascent/native-descriptor.ss";
        attribute :>> requestPath = "dev/modeling/ascent/native-descriptor.request.scm";
        attribute :>> relation = "Actual source uses -> consumer routes -> contract fields -> migration cuts -> owner-specific proof duties and shared contracts";
        attribute :>> scope = "Source-bound research hypotheses; QNT/Lean duties are proposed, no source refinement or execution authority";
    }
}
