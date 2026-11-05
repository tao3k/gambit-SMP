package GambitRuntimeRoleRealization { private import ScalarValues::*;
part def Cut { ref part owner:GambitRuntimeComposition::BlueprintModule; ref part target:GambitModernizationTarget::ArchitectureDecision; attribute componentId:String; attribute label:String; attribute sourceRoute:String; attribute retirement:String; attribute benefit:String; attribute addedCost:String; }
part cut0:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule2; ref part :>> target=GambitModernizationTarget::decision1; attribute :>> componentId="execution"; attribute :>> label="VM-owned execution context"; attribute :>> sourceRoute="gambit.h.in execution_contexts -> PSR/PSFP accessors -> setup.c and embedded Scheme C"; attribute :>> retirement="Remove GVM registers, fp/hp, processor Scheme object and execution mem from processor_state"; attribute :>> benefit="Root and continuation storage no longer occupies carrier state; one owned root origin survives clearing the carrier representation"; attribute :>> addedCost="Extra root-access indirection; old PSTATE was already VM-embedded; cleanup still follows the carrier; not independent retirement or live migration"; }
part cut1:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule2; ref part :>> target=GambitModernizationTarget::decision1; attribute :>> componentId="participant"; attribute :>> label="Closed root participant"; attribute :>> sourceRoute="garbage_collect_pstate -> frozen participant -> mark_execution_roots -> prepare/final acknowledgement"; attribute :>> retirement="Remove carrier-local register/saved/cache visitor trio and master-only RC root selection"; attribute :>> benefit="Root origin is explicit; every participant scans its own RC chain; incomplete phase transitions fail rather than silently scan"; attribute :>> addedCost="16 bytes per configured slot; phase checks per collection; foreign writers and whole-source freeze proof remain open"; }
part cut2:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule4; ref part :>> target=GambitModernizationTarget::decision1; attribute :>> componentId="worker"; attribute :>> label="VM-owned collector work"; attribute :>> sourceRoute="collector_workers -> explicit worker kernels -> chunk publication/dequeue -> strong/weak completion"; attribute :>> retirement="Remove chunk FIFO, scan cursor, weak-discovery state and copy-chunk bounds from execution/PSTATE mem"; attribute :>> benefit="Queue/cursor custody belongs to the worker record; stealing indexes the worker census rather than peer PSTATE mem"; attribute :>> addedCost="Worker allocation region and actlog still borrow a synchronous carrier; no independent GC thread-pool or death recovery claim"; }
part cut3:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule4; ref part :>> target=GambitModernizationTarget::decision1; attribute :>> componentId="round"; attribute :>> label="One GC outcome and final acknowledgement"; attribute :>> sourceRoute="closed gc_round census -> resize_heap publication -> local outcome copy -> final barrier"; attribute :>> retirement="Remove processor_count reads for GC work partitioning and processor-local-only overflow outcome"; attribute :>> benefit="Every caller sees the same capacity outcome; next round cannot overwrite an unconsumed shared result"; attribute :>> addedCost="One additional final collective barrier; 8-byte round record; original barrier C memory-order refinement remains open"; }
part def Need { attribute obligation:String; attribute method:String; attribute artifact:String; attribute scope:String; attribute premise:String; }
part need0:Need { attribute :>> obligation="RR-Q"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/runtime_roles.qnt"; attribute :>> scope="roles:two-participant-publication-and-results"; attribute :>> premise="Two participants; phase/readback ordering, four negative transitions; no forwarding/private-Tail termination proof"; }
part need1:Need { attribute :>> obligation="RR-L"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/RuntimeRoles.lean"; attribute :>> scope="roles:root-origin-and-receipt-laws"; attribute :>> premise="Six universal guard/origin/receipt laws; stable-storage and collective publication premises explicit"; }
part need2:Need { attribute :>> obligation="RR-C"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/lib/mem.c"; attribute :>> scope="roles:bazel-configured-C-object-projection"; attribute :>> premise="Six canonical C units compiled with retained Bazel flags/RTS O3; no generated Scheme cohort or runtime link"; }
part need3:Need { attribute :>> obligation="RR-STORAGE"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/tests/runtime-roles.c"; attribute :>> scope="roles:64bit-storage-and-accessors"; attribute :>> premise="Actual public accessor/storage checks, sanitizer, negative old-field compilation and matched sizeof; not live rebinding permission"; }
part need4:Need { attribute :>> obligation="RR-PROFILE"; attribute :>> method="source"; attribute :>> artifact="evidence/fixtures/gerbil-bazel-build-profile/profile.json"; attribute :>> scope="roles:configuration-reference-only"; attribute :>> premise="Read-only exact profile/header projection; patch candidates are problem evidence and are not imported source"; }
part need5:Need { attribute :>> obligation="RR-COHORT"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/lib/_kernel.scm"; attribute :>> scope="roles:source-generated-cohort-open"; attribute :>> premise="Regenerate Scheme embedded C and compiler/runtime cohort; execute real map/multi-shot/GC; no old runtime reuse"; }
part need6:Need { attribute :>> obligation="RR-REFINE"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/sysml/modernization-target.sysml"; attribute :>> scope="roles:whole-source-role-simulation-open"; attribute :>> premise="GC private work, all root writers, barriers, resize and failure paths need source/C/weak-memory composition"; }
part need7:Need { attribute :>> obligation="RR-LIFETIME"; attribute :>> method="native"; attribute :>> artifact="evidence/research/processor-interrupt-collective-wait/repair-9-12-native-observation.json"; attribute :>> scope="roles:carrier-lifecycle-and-native-failures-open"; attribute :>> premise="Context-resource cleanup still follows PSTATE; independent retirement, joins, old handlers, callbacks and whole SMP scenes remain open; no 8/12 inheritance"; }
part def Use { ref part component:Cut; ref part need:Need; }
part use0:Use { ref part :>> component=cut0; ref part :>> need=need0; }
part use1:Use { ref part :>> component=cut0; ref part :>> need=need1; }
part use2:Use { ref part :>> component=cut0; ref part :>> need=need2; }
part use3:Use { ref part :>> component=cut0; ref part :>> need=need3; }
part use4:Use { ref part :>> component=cut0; ref part :>> need=need4; }
part use5:Use { ref part :>> component=cut0; ref part :>> need=need5; }
part use6:Use { ref part :>> component=cut0; ref part :>> need=need6; }
part use7:Use { ref part :>> component=cut0; ref part :>> need=need7; }
part use8:Use { ref part :>> component=cut1; ref part :>> need=need0; }
part use9:Use { ref part :>> component=cut1; ref part :>> need=need1; }
part use10:Use { ref part :>> component=cut1; ref part :>> need=need2; }
part use11:Use { ref part :>> component=cut1; ref part :>> need=need3; }
part use12:Use { ref part :>> component=cut1; ref part :>> need=need4; }
part use13:Use { ref part :>> component=cut1; ref part :>> need=need5; }
part use14:Use { ref part :>> component=cut1; ref part :>> need=need6; }
part use15:Use { ref part :>> component=cut1; ref part :>> need=need7; }
part use16:Use { ref part :>> component=cut2; ref part :>> need=need0; }
part use17:Use { ref part :>> component=cut2; ref part :>> need=need2; }
part use18:Use { ref part :>> component=cut2; ref part :>> need=need3; }
part use19:Use { ref part :>> component=cut2; ref part :>> need=need4; }
part use20:Use { ref part :>> component=cut2; ref part :>> need=need5; }
part use21:Use { ref part :>> component=cut2; ref part :>> need=need6; }
part use22:Use { ref part :>> component=cut2; ref part :>> need=need7; }
part use23:Use { ref part :>> component=cut3; ref part :>> need=need0; }
part use24:Use { ref part :>> component=cut3; ref part :>> need=need1; }
part use25:Use { ref part :>> component=cut3; ref part :>> need=need2; }
part use26:Use { ref part :>> component=cut3; ref part :>> need=need4; }
part use27:Use { ref part :>> component=cut3; ref part :>> need=need5; }
part use28:Use { ref part :>> component=cut3; ref part :>> need=need6; }
part use29:Use { ref part :>> component=cut3; ref part :>> need=need7; }
part def Flow { ref part producer:Cut; ref part consumer:Cut; attribute label:String; }
part flow0:Flow { ref part :>> producer=cut0; ref part :>> consumer=cut1; attribute :>> label="complete root origin published at collective cut"; }
part flow1:Flow { ref part :>> producer=cut1; ref part :>> consumer=cut2; attribute :>> label="frozen participant authorizes root scan"; }
part flow2:Flow { ref part :>> producer=cut2; ref part :>> consumer=cut3; attribute :>> label="strong, weak and cleanup completion precede public outcome"; }
part flow3:Flow { ref part :>> producer=cut3; ref part :>> consumer=cut0; attribute :>> label="local result consumed and all contexts prepared before resume"; }
attribute sourceStorageAndCallChainImplemented:Boolean=true;
attribute referencePatchesImported:Boolean=false;
attribute independentCarriersAdmitted:Boolean=false;
attribute wholeRuntimeAdmitted:Boolean=false;
}
