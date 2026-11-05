/* Mandatory modern generated C. Target contracts, no satisfied runtime instances. */
package GambitRestGcResumeEnvelope {
 private import ScalarValues::*;
 part def Construction { attribute actuals : Integer; attribute formals : Integer;
  attribute built : Integer; attribute remaining : Integer; attribute cursor : Integer;
  attribute physicalEnd : Integer; attribute noHandles : Boolean;
  attribute completionMayRun : Boolean; attribute callerAndLayoutMatched : Boolean;
 }
 requirement def CompletionLaw { subject c : Construction;
  require constraint { c.actuals>=0 and c.formals>=1 and c.built>=0 and c.remaining>=0 and c.cursor>=0 and c.physicalEnd>=0 and
   (not c.completionMayRun or (c.noHandles and c.callerAndLayoutMatched and
    c.actuals<=8192 and c.formals<=1024 and c.built>=1 and
    c.built+c.remaining+c.formals==c.actuals+1 and
    c.cursor+3*c.remaining+c.formals+1<=c.physicalEnd)) }
 }
 part def Resume { attribute grantKnown : Boolean; attribute rootsCurrent : Boolean;
  attribute layoutMatched : Boolean; attribute pollInvalidates : Boolean;
  attribute heapDemand : Integer; attribute temporaryStackDemand : Integer;
  attribute allowFirstInterval : Boolean;
 }
 requirement def ResumeLaw { subject r : Resume;
  require constraint { not r.allowFirstInterval or (r.grantKnown and r.rootsCurrent and
   r.layoutMatched and r.pollInvalidates and r.heapDemand==0 and r.temporaryStackDemand>=2) }
 }
 part def Lifetime { attribute semanticDead : Boolean; attribute readersDrained : Boolean;
  attribute noCapturedAlias : Boolean; attribute physicalReleaseAllowed : Boolean;
  attribute accountingRefundOnly : Boolean;
 }
 requirement def LifetimeLaw { subject l : Lifetime;
  require constraint { not l.physicalReleaseAllowed or (l.semanticDead and l.readersDrained and
   l.noCapturedAlias and not l.accountingRefundOnly) }
 }
 part history : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-H";
 attribute :>> kind="interleaving";
 attribute :>> subjectPath="models/gambit/rest_gc_resume_envelope.qnt";
 attribute :>> subjectScope="rest_gc_resume_envelope:16-named-histories;safe;seed=17;100x80";
 attribute :>> premise="One p2 a5 history: completion before framed GC, known resume, carrier lifetime and ghost historical peak; abstract destination, no source simulation";
 }
 part induction : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-I";
 attribute :>> kind="induction";
 attribute :>> subjectPath="models/gambit/lean/RestGcResumeEnvelope.lean";
 attribute :>> subjectScope="GambitSMP.RestGcResumeEnvelope:suffixBound;noDoubleCount;crossingAndCompletion;structureCarrier;boundedStructureCarrier;genericJointBound;completionFits;zeroFirstHeapSpan;stackPrefix;countedOnce;phaseCredit;unchangedPeak;retainedPeak";
 attribute :>> premise="Conditional Nat extent and phase inequalities; no pointer provenance, generated-code identity or whole-step induction";
 }
 part completion : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-COMPLETE";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestGcResumeEnvelope.lean";
 attribute :>> subjectScope="RG-COMPLETE:actual-source-refinement";
 attribute :>> premise="Exact p/a/k/m and no-handle layout, entry guard plus post-crossing completion, no collecting before carrier/root publication; physical contiguity and all admitted callers";
 }
 part resume : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-RESUME";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestGcResumeEnvelope.lean";
 attribute :>> subjectScope="RG-RESUME:actual-source-refinement";
 attribute :>> premise="GC/current binding -> POP_ARGS2 -> push p -> na=-1 -> actual structure entry first POLL; heap0 stack2 local envelope, slow poll invalidates; following frame8 and dynamic structure allocation separately admitted";
 }
 part lifetime : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-LIFETIME";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestGcResumeEnvelope.lean";
 attribute :>> subjectScope="RG-LIFETIME:actual-source-refinement";
 attribute :>> premise="Last root/alias/continuation and reader drain precede actual region reuse/release; live rest pairs and detached carrier are not immediately free; overflow retry and unknown hold roots";
 }
 part peak : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
 attribute :>> obligationId="RG-PEAK";
 attribute :>> kind="source-refinement";
 attribute :>> subjectPath="models/gambit/lean/RestGcResumeEnvelope.lean";
 attribute :>> subjectScope="RG-PEAK:actual-source-refinement";
 attribute :>> premise="Actual completion/copy/restore/frame-growth/still/failure phase maxima and matched existing reuse baseline; Qg omits real fresh backing, no aggregate reserve or late refund credit";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=completion; ref part :>> prerequisite=history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=completion; ref part :>> prerequisite=induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=completion; ref part :>> prerequisite=GambitRuntimeAssurance::work.source; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=history; }
 part dependency4 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=induction; }
 part dependency5 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=completion; }
 part dependency6 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency7 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=resume; ref part :>> prerequisite=GambitRuntimeAssurance::control.source; }
 part dependency8 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=history; }
 part dependency9 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=induction; }
 part dependency10 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=completion; }
 part dependency11 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=GambitPromotionIntervalHandoff::readers; }
 part dependency12 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=lifetime; ref part :>> prerequisite=GambitHostRootsRefinement::bindingState; }
 part dependency13 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=history; }
 part dependency14 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=induction; }
 part dependency15 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=completion; }
 part dependency16 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=resume; }
 part dependency17 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=lifetime; }
 part dependency18 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=peak; ref part :>> prerequisite=GambitPromotionIntervalHandoff::memory; }
 part dependency19 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitGuaranteedTailPlacement::checks; ref part :>> prerequisite=completion; }
 part dependency20 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitGuaranteedTailPlacement::restore; ref part :>> prerequisite=resume; }
 part dependency21 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=GambitGuaranteedTailPlacement::peak; ref part :>> prerequisite=peak; }
 part completionRoute : GambitHostRootsRefinement::Route { ref part :>> need=completion;
 attribute :>> sourceAnchors="lib/_kernel.scm:506-596;include/gambit.h.in:3118-3167,5325;lib/mem.h:63-78;lib/mem.c:7425-7500";
 attribute :>> patchAnchors="Existing cumulative patch unchanged; generated kernel snapshot is source evidence, not a freshly built binary";
 attribute :>> projection="Exact p/a/k/m and no-handle layout, entry guard plus post-crossing completion, no collecting before carrier/root publication; physical contiguity and all admitted callers";
 attribute :>> failureCustodian="Context holds unframed constructor and completion grant; framed roots/epoch ledger retain carrier, both spaces and pending result until known commit and last-alias drain";
 attribute :>> status="source-chain-located-refinement-and-native-capacity-open";
 }
 part resumeRoute : GambitHostRootsRefinement::Route { ref part :>> need=resume;
 attribute :>> sourceAnchors="lib/_kernel.scm:1992-2049,4984-4994;lib/_kernel.c:23950-23986;include/gambit.h.in:7004-7026,8176-8179,8510-8536;lib/mem.c:7041-7087";
 attribute :>> patchAnchors="Existing cumulative patch unchanged; generated kernel snapshot is source evidence, not a freshly built binary";
 attribute :>> projection="GC/current binding -> POP_ARGS2 -> push p -> na=-1 -> actual structure entry first POLL; heap0 stack2 local envelope, slow poll invalidates; following frame8 and dynamic structure allocation separately admitted";
 attribute :>> failureCustodian="Context holds unframed constructor and completion grant; framed roots/epoch ledger retain carrier, both spaces and pending result until known commit and last-alias drain";
 attribute :>> status="source-chain-located-refinement-and-native-capacity-open";
 }
 part lifetimeRoute : GambitHostRootsRefinement::Route { ref part :>> need=lifetime;
 attribute :>> sourceAnchors="lib/_kernel.scm:1992-2049;lib/mem.c:891-1083,3426-3439,4380-4453,4966;lib/_kernel.scm:43-112";
 attribute :>> patchAnchors="Existing cumulative patch unchanged; generated kernel snapshot is source evidence, not a freshly built binary";
 attribute :>> projection="Last root/alias/continuation and reader drain precede actual region reuse/release; live rest pairs and detached carrier are not immediately free; overflow retry and unknown hold roots";
 attribute :>> failureCustodian="Context holds unframed constructor and completion grant; framed roots/epoch ledger retain carrier, both spaces and pending result until known commit and last-alias drain";
 attribute :>> status="source-chain-located-refinement-and-native-capacity-open";
 }
 part peakRoute : GambitHostRootsRefinement::Route { ref part :>> need=peak;
 attribute :>> sourceAnchors="lib/mem.c:540-598,891-1083,1556-1708,6316-6488,7036-7087;lib/mem.h:63-78;lib/_kernel.c:23950-23986";
 attribute :>> patchAnchors="Existing cumulative patch unchanged; generated kernel snapshot is source evidence, not a freshly built binary";
 attribute :>> projection="Actual completion/copy/restore/frame-growth/still/failure phase maxima and matched existing reuse baseline; Qg omits real fresh backing, no aggregate reserve or late refund credit";
 attribute :>> failureCustodian="Context holds unframed constructor and completion grant; framed roots/epoch ledger retain carrier, both spaces and pending result until known commit and last-alias drain";
 attribute :>> status="source-chain-located-refinement-and-native-capacity-open";
 }
 part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }
 part caller0 : CallerRow {
 attribute :>> callerId="rest-entry";
 attribute :>> sourceAnchors="_kernel.c:23950-23956;gambit.h.in:8176-8179";
 attribute :>> actualChain="structure one required plus rest -> p2 handler; na=-1 bypass on resume";
 attribute :>> hazard="Calling GET_REST again with nonnegative count would rebuild list";
 attribute :>> replacement="PointId binds actual/formal shape and negative ready-arguments sentinel";
 }
 part caller1 : CallerRow {
 attribute :>> callerId="completion";
 attribute :>> sourceAnchors="_kernel.scm:506-596;gambit.h.in:3150-3167";
 attribute :>> actualChain="one pair then hp check -> heap_limit may continue -> remaining pairs and vector before GC";
 attribute :>> hazard="B3 alone cannot pay C=3m+p+1; hp/global reserve not a contiguous grant";
 attribute :>> replacement="Noncollecting completion grant issued before exposing unframed arguments";
 }
 part caller2 : CallerRow {
 attribute :>> callerId="framed-gc";
 attribute :>> sourceAnchors="_kernel.scm:1992-2000,2034-2049;mem.c:6938-7087";
 attribute :>> actualChain="proc and carrier as Scheme args -> saved RA/registers -> GC -> restored binding";
 attribute :>> hazard="overflow handler can return/retry, capture or nonlocal exit";
 attribute :>> replacement="Durable FrameSpec/root receipt and failure delivery reserve";
 }
 part caller3 : CallerRow {
 attribute :>> callerId="first-resume";
 attribute :>> sourceAnchors="_kernel.scm:2006-2032;_kernel.c:23950-23957";
 attribute :>> actualChain="POP_ARGS2, push vector2, pop regs, na=-1, FIX1, POLL1";
 attribute :>> hazard="heap0 is not stack0; poll slow path may move stack/heap";
 attribute :>> replacement="Temporary stack allowance2 plus current caller frame; fresh assurance after slow path";
 }
 part caller4 : CallerRow {
 attribute :>> callerId="later-body";
 attribute :>> sourceAnchors="_kernel.c:23958-23986;_kernel.scm:43-112,4984-4994";
 attribute :>> actualChain="8-word recursive frame per field -> POLL -> make-structure n=a";
 attribute :>> hazard="8r logical stack growth can GC/copy; a+1>255 selects still allocator";
 attribute :>> replacement="Separate FrameSpec growth, small-object B=a+1 or rooted still/failure plan";
 }
 part caller5 : CallerRow {
 attribute :>> callerId="release";
 attribute :>> sourceAnchors="mem.c:989,1065-1083,1556-1708,4406-4448;_kernel.scm:1992-2032";
 attribute :>> actualChain="cursor bump, copying/semispace reuse, msection shrink/free; still cleanup";
 attribute :>> hazard="Rest list remains language value; carrier root detach not physical free";
 attribute :>> replacement="Last alias/root/readers plus known region accounting before reuse or free";
 }
 part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }
 part cost0 : CostRow {
 attribute :>> capability="completion envelope";
 attribute :>> removedWork="Replace unqualified worst-case requests with caller-bound exact suffix";
 attribute :>> bound="p2: C=3m+3, Bcross<=3; Bcross+C<=3a<=24576 words (196608 bytes at WS8)";
 attribute :>> addedCost="Preissued contiguous completion space, argument count/layout identity, checked arithmetic";
 attribute :>> condition="No shrinking current global204808-word policy by subtracting bounds; multi-context physical/source obligations open";
 }
 part cost1 : CostRow {
 attribute :>> capability="general ordinary rest";
 attribute :>> removedWork="Avoid independent-max double counting";
 attribute :>> bound="k+m=r=a-p+1; total=3r+p+1=3a-2p+4<=24578 words, no handles";
 attribute :>> addedCost="Generic p<=1024 a<=8192 admission and representation variants";
 attribute :>> condition="Bound is carrier construction only, not transitive GC live graph, stack, emergency or root metadata";
 }
 part cost2 : CostRow {
 attribute :>> capability="first resumed interval";
 attribute :>> removedWork="No heap allocation between restore helper and structure POLL1";
 attribute :>> bound="Heap R0=0; temporary push<=2 slots; next recursive interval adds8 frame words";
 attribute :>> addedCost="Existing caller/frame stack grant and fresh assurance on slow poll";
 attribute :>> condition="Do not grant zero heap globally: current post-GC fudge still exists and later dynamic allocation needs its own plan";
 }
 part cost3 : CostRow {
 attribute :>> capability="recursive continuation";
 attribute :>> removedWork="Make hidden stack growth explicit and preserve repeated/multi-shot capture";
 attribute :>> bound="8r<=65528 logical stack words (524224 bytes at WS8), excluding base/control and copied heap frames";
 attribute :>> addedCost="Root descriptors, possible frame-to-heap copy, every POLL rebind and alias retention";
 attribute :>> condition="Logical stack growth not a contiguous native grant or all-round peak bound";
 }
 part cost4 : CostRow {
 attribute :>> capability="next structure allocation";
 attribute :>> removedWork="Separate small bump demand from still allocation";
 attribute :>> bound="n=a; small object a+1<=255 words if a<=254; a>=255 uses still allocation";
 attribute :>> addedCost="Still header/alignment/allocator, rooted type, possible GC and failure cleanup";
 attribute :>> condition="Not included in first interval; allocator refcount_dec is not immediate object free";
 }
 part cost5 : CostRow {
 attribute :>> capability="guaranteed tail Qg";
 attribute :>> removedWork="Omit an actually separate future resume acquisition before overlap";
 attribute :>> bound="0<=Qg<=min(usable compatible tail,Ractual); phase c<=b-Qg+extra";
 attribute :>> addedCost="Copy fence, real backing provenance, transfer ledger, roots and reader pins";
 attribute :>> condition="Strict whole gain iff every phase below matched baseline peak; existing PSTATE reuse already credited; zero first-span demand gives no credit itself";
 }
 part cost6 : CostRow {
 attribute :>> capability="late carrier death/refund";
 attribute :>> removedWork="Only reduce occupancy after actual region reuse/free";
 attribute :>> bound="Late Qo cannot decrease max already observed; carrier3 words no immediate3-word refund";
 attribute :>> addedCost="Complete continuation/FFI alias and reader closure, delayed failure roots";
 attribute :>> condition="Rest pairs remain arguments; lowering a counter or detaching POP_ARGS2 is not releasing an allocation";
 }
 part cost7 : CostRow {
 attribute :>> capability="failure and unknown";
 attribute :>> removedWork="Avoid unsafe GC at incomplete frames and duplicated grant spending";
 attribute :>> bound="Before published/copy state only known private reservations refundable; after forwarding retain both spaces";
 attribute :>> addedCost="Bounded pending/completion/failure grants and backpressure";
 attribute :>> condition="No retry/newID/refund while outcome unknown; no OOM, liveness, RSS or native performance claim";
 }
 part def ViewNode { attribute nodeId : String; attribute labelText : String; }
 part node0 : ViewNode { attribute :>> nodeId="entry"; attribute :>> labelText="structure entry: a actuals, p2"; }
 part node1 : ViewNode { attribute :>> nodeId="guard"; attribute :>> labelText="Pair allocation then guard Bcross"; }
 part node2 : ViewNode { attribute :>> nodeId="complete"; attribute :>> labelText="Completion grant: 3m+3, no GC"; }
 part node3 : ViewNode { attribute :>> nodeId="roots"; attribute :>> labelText="Carrier and proc: complete rooted frames"; }
 part node4 : ViewNode { attribute :>> nodeId="collect"; attribute :>> labelText="GC copy + future tail fence"; }
 part node5 : ViewNode { attribute :>> nodeId="commit"; attribute :>> labelText="Ownership commit / readback"; }
 part node6 : ViewNode { attribute :>> nodeId="resume"; attribute :>> labelText="Restore2, na=-1, heap0 -> POLL1"; }
 part node7 : ViewNode { attribute :>> nodeId="later"; attribute :>> labelText="Frame8 per field, then small/still allocation"; }
 part node8 : ViewNode { attribute :>> nodeId="hold"; attribute :>> labelText="Failure / unknown: retain roots and spaces"; }
 part node9 : ViewNode { attribute :>> nodeId="release"; attribute :>> labelText="Last alias + reader drain -> region reuse/free"; }
 part node10 : ViewNode { attribute :>> nodeId="peak"; attribute :>> labelText="All-phase physical maximum; Qg vs late Qo"; }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="admitted shape"; }
 part edge1 : ViewEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="heap_limit requests GC"; }
 part edge2 : ViewEdge { ref part :>> producer=node2; ref part :>> consumer=node3; attribute :>> labelText="finish unframed work"; }
 part edge3 : ViewEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="GC admissible"; }
 part edge4 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node5; attribute :>> labelText="copy ready"; }
 part edge5 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node6; attribute :>> labelText="readback known"; }
 part edge6 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="new PointId / poll rebind"; }
 part edge7 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node8; attribute :>> labelText="forwarded failure"; }
 part edge8 : ViewEdge { ref part :>> producer=node5; ref part :>> consumer=node8; attribute :>> labelText="reply unknown"; }
 part edge9 : ViewEdge { ref part :>> producer=node8; ref part :>> consumer=node5; attribute :>> labelText="resolve same operation"; }
 part edge10 : ViewEdge { ref part :>> producer=node6; ref part :>> consumer=node9; attribute :>> labelText="root detachment insufficient"; }
 part edge11 : ViewEdge { ref part :>> producer=node7; ref part :>> consumer=node9; attribute :>> labelText="semantic death + leases"; }
 part edge12 : ViewEdge { ref part :>> producer=node4; ref part :>> consumer=node10; attribute :>> labelText="preflight omission"; }
 part edge13 : ViewEdge { ref part :>> producer=node9; ref part :>> consumer=node10; attribute :>> labelText="late refund preserves history"; }
}
