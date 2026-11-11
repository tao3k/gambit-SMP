package GambitFrameConsumers { private import ScalarValues::*;
part def Cut { ref part owner:GambitRuntimeComposition::BlueprintModule; ref part target:GambitModernizationTarget::ArchitectureDecision; attribute componentId:String; attribute label:String; attribute sourceRoute:String; attribute retirement:String; attribute benefit:String; attribute addedCost:String; }
part cut0:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule4; ref part :>> target=GambitModernizationTarget::decision2; attribute :>> componentId="roots"; attribute :>> label="Shared physical root view"; attribute :>> sourceRoute="gambit.h.in root cursor -> mem.c mark_frame -> stack and heap frames"; attribute :>> retirement="Retire the separate GC bitmap traversal and two kernel root-index/mask bodies"; attribute :>> benefit="One-based slot coordinates and tail origin shared by GC and continuation inspection; contiguous root marking preserved"; attribute :>> addedCost="A descriptor and transient cursor; same O(frame slots) scan and live-root volume; no new heap metadata"; }
part cut1:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule5; ref part :>> target=GambitModernizationTarget::decision3; attribute :>> componentId="control"; attribute :>> label="Multi-shot control consumer"; attribute :>> sourceRoute="_kernel.scm slot queries -> frame-continuation-roots.scm -> repeated map restore"; attribute :>> retirement="Retire independent cross-word tail indexing and signed-int masks"; attribute :>> benefit="Native-word unsigned reads; stack-to-heap root-view agreement and retained prior results become explicit oracles"; attribute :>> addedCost="80 live payload roots and forced GC in the regression; mutable-frame alias and concurrent resume proofs remain open"; }
part cut2:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule2; ref part :>> target=GambitModernizationTarget::decision1; attribute :>> componentId="binding"; attribute :>> label="Explicit module VM binding"; attribute :>> sourceRoute="setup_module_fixup(ctx) -> make_global(ctx) -> GLOCELL_IN_VM"; attribute :>> retirement="Retire an unbound ambient processor dependency in module global binding"; attribute :>> benefit="The loading context supplies the VM in multiple-VM builds"; attribute :>> addedCost="Existing context is passed; no new allocation, lock or global state; not a general VM lifecycle proof"; }
part cut3:Cut { ref part :>> owner=GambitRuntimeComposition::blueprintModule8; ref part :>> target=GambitModernizationTarget::decision5; attribute :>> componentId="build"; attribute :>> label="Bazel-bound source cohort"; attribute :>> sourceRoute="Bazel validation baseline -> behavioral constraints -> new generated contract -> retired old owner -> source/self and map"; attribute :>> retirement="Retire ad hoc profile switches and mixed-source acceptance; old receipts remain immutable"; attribute :>> benefit="One existing byte-bound profile; four exact source imports and one explicit VM replacement; historic failures constrain new admission"; attribute :>> addedCost="Frame/root sub-contract implemented; coupled membership, heap, native effects and semantic build replacements remain open; source equality is not architectural admission"; }
ref part framePlan=GambitFrameContractRealization::cut0;
ref part frameDecoder=GambitFrameContractRealization::cut1;
part def Need { attribute obligation:String; attribute method:String; attribute artifact:String; attribute scope:String; attribute premise:String; }
part need0:Need { attribute :>> obligation="FR-Q"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/frame_roots.qnt"; attribute :>> scope="frame-roots:finite-word-stream"; attribute :>> premise="Width-four abstraction; prefix coverage, unique visits, terminal guard and tail-index counterexample"; }
part need1:Need { attribute :>> obligation="FR-L"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/FrameRoots.lean"; attribute :>> scope="frame-roots:coordinates-and-prefix-induction"; attribute :>> premise="Seven natural-coordinate/prefix laws; C bit operations, run batching and metadata lifetime are separate"; }
part need2:Need { attribute :>> obligation="FR-NATIVE"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/tests/frame-contract.c"; attribute :>> scope="frame-roots:configured-64bit-native-cursor"; attribute :>> premise="Generated 306 physical plans; independent bit/run enumeration, terminal guard, unsigned high-bit and sanitizer controls"; }
part need3:Need { attribute :>> obligation="FR-MAP"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> scope="frame-roots:coherent-map-multishot"; attribute :>> premise="Fresh compiled map and 80-root non-tail frame; winding/effect/value and materialized-frame root-query agreement"; }
part need4:Need { attribute :>> obligation="FR-COHORT"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm"; attribute :>> scope="frame-roots:source-self-bootstrap-profile"; attribute :>> premise="Actual source and self passes under the existing Bazel profile and explicit threaded-VM goal overlay; original budgets and complete source/header/tool/config identities"; }
part need5:Need { attribute :>> obligation="FR-PROFILE"; attribute :>> method="source"; attribute :>> artifact="evidence/research/modern-c-frame-consumers/bazel-baseline.json"; attribute :>> scope="frame-roots:bazel-profile-and-patch-correspondence"; attribute :>> premise="Exact current script hash, four reverse-apply imports and explicit VM replacement; not configure or native qualification"; }
part need6:Need { attribute :>> obligation="FR-CONSTRAINTS"; attribute :>> method="source"; attribute :>> artifact="dev/refactoring/modern-c/models/sysml/modernization-target.sysml"; attribute :>> scope="frame-roots:repair-behavior-to-architecture-refinement"; attribute :>> premise="Old repairs constrain legal behavior and retained failures, not the replacement layout; bind each new owner and old-owner retirement; no source-equality or automatic 8/12 inheritance"; }
part need7:Need { attribute :>> obligation="FR-FULL"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/sysml/map-multishot-composition.sysml"; attribute :>> scope="frame-roots:whole-runtime-refinement-open"; attribute :>> premise="No claim of generational GC, full FFI/scheduler refinement, arbitrary processor count or 12/12 acceptance"; }
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
part use16:Use { ref part :>> component=cut2; ref part :>> need=need4; }
part use17:Use { ref part :>> component=cut2; ref part :>> need=need5; }
part use18:Use { ref part :>> component=cut2; ref part :>> need=need6; }
part use19:Use { ref part :>> component=cut2; ref part :>> need=need7; }
part use20:Use { ref part :>> component=cut3; ref part :>> need=need3; }
part use21:Use { ref part :>> component=cut3; ref part :>> need=need4; }
part use22:Use { ref part :>> component=cut3; ref part :>> need=need5; }
part use23:Use { ref part :>> component=cut3; ref part :>> need=need6; }
part use24:Use { ref part :>> component=cut3; ref part :>> need=need7; }
part def Flow { ref part producer:Cut; ref part consumer:Cut; attribute label:String; }
part flow0:Flow { ref part :>> producer=cut0; ref part :>> consumer=cut1; attribute :>> label="same physical slot and native-word tail origin"; }
part flow1:Flow { ref part :>> producer=cut2; ref part :>> consumer=cut3; attribute :>> label="explicit loading VM"; }
part flow2:Flow { ref part :>> producer=cut3; ref part :>> consumer=cut0; attribute :>> label="coherent regenerated runtime and header"; }
part flow3:Flow { ref part :>> producer=cut3; ref part :>> consumer=cut1; attribute :>> label="fresh generated witness and restore consumer"; }
attribute wholeRuntimeAdmitted:Boolean=false;
}
