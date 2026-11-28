package GambitFrameContractRealization { private import ScalarValues::*;
part def RealizationCut { ref part owner:GambitRuntimeComposition::BlueprintModule; attribute componentId:String; attribute label:String; attribute sourceRoute:String; attribute retirement:String; attribute benefit:String; attribute addedCost:String; }
part cut0:RealizationCut { ref part :>> owner=GambitRuntimeComposition::blueprintModule0; attribute :>> componentId="producer"; attribute :>> label="Validated Scheme frame plan"; attribute :>> sourceRoute="gsc/_t-c-2.scm returns -> targ-make-frame-spec -> _t-c-1.scm emit/count/OFD consumers"; attribute :>> retirement="Retire unvalidated four-position return vectors and repeated layout decisions in three dumper loops"; attribute :>> benefit="One physical size/IFD decision per frame instead of two to four; emission wire format unchanged for the matched witness"; attribute :>> addedCost="Three extra Scheme vector slots per return label; range validation; bitmap chunks stay transient at emission"; }
part cut1:RealizationCut { ref part :>> owner=GambitRuntimeComposition::blueprintModule4; attribute :>> componentId="consumer"; attribute :>> label="Shared typed C frame decoder"; attribute :>> sourceRoute="include/gambit.h.in: ___decode_frame_descriptor -> seven projections -> mem.c and kernel restore consumers"; attribute :>> retirement="Retire seven independently maintained IFD/OFD reader bodies; descriptor wire ABI retained"; attribute :>> benefit="One decoder interpretation shared by GC and continuation recovery; zero new VM storage or heap allocation in this cut"; attribute :>> addedCost="Inline/local result may affect generated machine code; no speedup or zero stack overhead asserted"; }
part cut2:RealizationCut { ref part :>> owner=GambitRuntimeComposition::blueprintModule5; attribute :>> componentId="control"; attribute :>> label="Repeatable control witness"; attribute :>> sourceRoute="tests/frame-continuation.scm: map, call/cc, dynamic-wind, forced GC and C suffix"; attribute :>> retirement="Replace absence of a coupled regression by an executable value/effect/wind oracle"; attribute :>> benefit="Three preserved results, five callback invocations, three C calls and three wind pairs; prior delivered lists stay unchanged"; attribute :>> addedCost="Focused witness only; full generational GC, scheduling, mutable-frame alias and cohort acceptance remain open"; }
ref part jointWitness=GambitMapMultishot::boundary3;
ref part coordinateContract=GambitFrameContract::coordinate3;
part def Need { attribute obligation:String; attribute method:String; attribute artifact:String; attribute scope:String; attribute premise:String; }
part need0:Need { attribute :>> obligation="FC-Q"; attribute :>> method="quint"; attribute :>> artifact="dev/refactoring/modern-c/models/quint/frame_contract.qnt"; attribute :>> scope="frame-contract:finite-descriptor-arithmetic"; attribute :>> premise="Kinds 1..3; sizes 1..40; finite arithmetic and omitted internal area counterexample"; }
part need1:Need { attribute :>> obligation="FC-L"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/lean/FrameContract.lean"; attribute :>> scope="frame-contract:descriptor-natural-arithmetic"; attribute :>> premise="Seven universal packing field laws over bounded natural fields; no C pointer/shift/lifetime proof"; }
part need2:Need { attribute :>> obligation="FC-PRODUCER"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/tests/frame-spec.scm"; attribute :>> scope="frame-contract:source-loaded-producer-and-matched-C"; attribute :>> premise="Current three backend sources loaded; 2387 checks, 306 fixtures, rejection controls and byte-identical witness against parent sources"; }
part need3:Need { attribute :>> obligation="FC-DECODE"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/include/gambit.h.in"; attribute :>> scope="frame-contract:configured-64bit-decoder-and-GC-slice"; attribute :>> premise="306 native cases over registers 3/5/25; seven projections; sanitizer; source-identical decoder region rebuilt into retained GCC-profile mem object and linked witness"; }
part need4:Need { attribute :>> obligation="FC-COHORT"; attribute :>> method="native"; attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm"; attribute :>> scope="frame-contract:complete-modern-c-bootstrap-open"; attribute :>> premise="Generated backend C checked separately; full compiled compiler/coherent current vendor runtime bootstrap and target profile matrix still required"; }
part need5:Need { attribute :>> obligation="FC-FULL"; attribute :>> method="lean"; attribute :>> artifact="dev/refactoring/modern-c/models/sysml/map-multishot-composition.sysml"; attribute :>> scope="frame-contract:whole-runtime-semantic-refinement-open"; attribute :>> premise="Physical cut does not close root/writer inventories, GC generations, scheduler, FFI lifetime, progress or 12/12 native acceptance"; }
part def Use { ref part component:RealizationCut; ref part need:Need; }
part use0:Use { ref part :>> component=cut0; ref part :>> need=need0; }
part use1:Use { ref part :>> component=cut0; ref part :>> need=need1; }
part use2:Use { ref part :>> component=cut0; ref part :>> need=need2; }
part use3:Use { ref part :>> component=cut0; ref part :>> need=need4; }
part use4:Use { ref part :>> component=cut0; ref part :>> need=need5; }
part use5:Use { ref part :>> component=cut1; ref part :>> need=need0; }
part use6:Use { ref part :>> component=cut1; ref part :>> need=need1; }
part use7:Use { ref part :>> component=cut1; ref part :>> need=need3; }
part use8:Use { ref part :>> component=cut1; ref part :>> need=need4; }
part use9:Use { ref part :>> component=cut1; ref part :>> need=need5; }
part use10:Use { ref part :>> component=cut2; ref part :>> need=need2; }
part use11:Use { ref part :>> component=cut2; ref part :>> need=need3; }
part use12:Use { ref part :>> component=cut2; ref part :>> need=need4; }
part use13:Use { ref part :>> component=cut2; ref part :>> need=need5; }
part def Flow { ref part producer:RealizationCut; ref part consumer:RealizationCut; attribute label:String; }
part flow0:Flow { ref part :>> producer=cut0; ref part :>> consumer=cut1; attribute :>> label="validated kind / stored size / link / root bits"; }
part flow1:Flow { ref part :>> producer=cut1; ref part :>> consumer=cut2; attribute :>> label="GC / heap frame\nrestore coordinates"; }
part flow2:Flow { ref part :>> producer=cut2; ref part :>> consumer=cut0; attribute :>> label="value / effect / wind oracle"; }
attribute sourceImplemented:Boolean=true; attribute fullRuntimeAdmitted:Boolean=false;
}
