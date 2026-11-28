/* Modern-C target only. Native SysML owns needs, edges, source census and cost rows. */
package GambitPromotionResidual {
 private import ScalarValues::*;
 part def CapacityReceipt {
  attribute payloadWords : Integer;
  attribute overheadWords : Integer;
  attribute committedWords : Integer;
  attribute resumeWords : Integer;
  attribute intervalsDisjoint : Boolean;
  attribute censusClosed : Boolean;
  attribute physicalAccepted : Boolean;
  attribute forwardingAllowed : Boolean;
 }
 requirement def CapacityLaw {
  subject r : CapacityReceipt;
  require constraint { r.payloadWords >= 0 and r.overheadWords >= 0 and r.resumeWords >= 0 and
   (not r.forwardingAllowed or (r.censusClosed and r.physicalAccepted and r.intervalsDisjoint and
    r.committedWords >= r.payloadWords + r.overheadWords + r.resumeWords)) }
 }
 part def EpochReceipt {
  attribute oldEpoch : Integer;
  attribute nextEpoch : Integer;
  attribute admittedWriters : Integer;
  attribute producersClosed : Boolean;
  attribute aliasesSettled : Boolean;
  attribute weakSettled : Boolean;
  attribute residualCovered : Boolean;
  attribute seedsComplete : Boolean;
  attribute seedOverflow : Boolean;
  attribute descriptorPublished : Boolean;
  attribute oldReadersDrained : Boolean;
  attribute resetRequested : Boolean;
 }
 requirement def EpochLaw {
  subject r : EpochReceipt;
  require constraint { r.admittedWriters >= 0 and
   (not r.descriptorPublished or (r.nextEpoch == r.oldEpoch+1 and r.producersClosed and
    r.admittedWriters == 0 and r.aliasesSettled and r.weakSettled and r.residualCovered and
    (r.seedsComplete or r.seedOverflow))) and
   (not r.resetRequested or (r.descriptorPublished and r.oldReadersDrained)) }
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-H";
 attribute :>> kind = "interleaving";
 attribute :>> subjectPath = "models/gambit/promotion_residual.qnt";
 attribute :>> subjectScope = "promotion_residual:17-named-histories;safe;seed=17;100x80";
 attribute :>> premise = "Two unique destination costs, pending writer cut, pre-forward refund, staged residual handoff and omission controls; finite target only";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-I";
 attribute :>> kind = "induction";
 attribute :>> subjectPath = "models/gambit/lean/PromotionResidual.lean";
 attribute :>> subjectScope = "GambitSMP.PromotionResidual:frameFitsStack;payloadBound;fullBound;claimConserves;refundConserves;seedComplete;residualCovered;zeroResidual;disjointPeak;positiveWork";
 attribute :>> premise = "Conditional parametric arithmetic and coverage lemmas; source enumeration and whole transition induction remain open";
 }
 part bound : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-BOUND";
 attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionResidual.lean";
 attribute :>> subjectScope = "PR-BOUND:actual-source-refinement";
 attribute :>> premise = "Unique heap/frame extent census, layout expansion/alignment, claim-first workers, fragmentation and physical destination/resume intervals; no survivor estimate";
 }
 part residual : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-RESIDUAL";
 attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionResidual.lean";
 attribute :>> subjectScope = "PR-RESIDUAL:actual-source-refinement";
 attribute :>> premise = "Final strong/weak closure, collector-created ranges, staged next bitmap plus seed endpoint/fallback; zero residual only under all-promoted alias closure";
 }
 part ffi : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-FFI";
 attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/gambit/lean/PromotionResidual.lean";
 attribute :>> subjectScope = "PR-FFI:actual-source-refinement";
 attribute :>> premise = "RC RootWrite, still marker slot, payload writes and nested callback permits; unknown native writer blocks cut and next-epoch publication";
 }
 part memory : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitRuntimeAssurance::work.component;
 attribute :>> obligationId = "PR-MEMORY";
 attribute :>> kind = "native-memory-order";
 attribute :>> subjectPath = "vendor/gambit/lib/mem.c";
 attribute :>> subjectScope = "PR-MEMORY:actual-source-refinement";
 attribute :>> premise = "Acquired writer/root endpoints, unique layout claims and payload-ready publication; immutable epoch descriptor release/acquire and old-bank reader reclamation";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = bound;
 ref part :>> prerequisite = history;
 }
 part dependency1 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = bound;
 ref part :>> prerequisite = induction;
 }
 part dependency2 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = bound;
 ref part :>> prerequisite = GambitGenerationalBarrier::writers;
 }
 part dependency3 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = bound;
 ref part :>> prerequisite = GambitRuntimeAssurance::work.source;
 }
 part dependency4 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = residual;
 ref part :>> prerequisite = history;
 }
 part dependency5 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = residual;
 ref part :>> prerequisite = induction;
 }
 part dependency6 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = residual;
 ref part :>> prerequisite = GambitGenerationalBarrier::logs;
 }
 part dependency7 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = residual;
 ref part :>> prerequisite = GambitGenerationalBarrier::writers;
 }
 part dependency8 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = ffi;
 ref part :>> prerequisite = history;
 }
 part dependency9 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = ffi;
 ref part :>> prerequisite = induction;
 }
 part dependency10 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = ffi;
 ref part :>> prerequisite = GambitRcFreezePublication::census;
 }
 part dependency11 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = ffi;
 ref part :>> prerequisite = GambitRcFreezePublication::freeze;
 }
 part dependency12 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = ffi;
 ref part :>> prerequisite = GambitRetainedRcScan::membership;
 }
 part dependency13 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = memory;
 ref part :>> prerequisite = history;
 }
 part dependency14 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = memory;
 ref part :>> prerequisite = induction;
 }
 part dependency15 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = memory;
 ref part :>> prerequisite = GambitGenerationalBarrier::memoryOrder;
 }
 part dependency16 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = GambitGenerationalBarrier::promotion;
 ref part :>> prerequisite = bound;
 }
 part dependency17 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = GambitGenerationalBarrier::promotion;
 ref part :>> prerequisite = memory;
 }
 part dependency18 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = GambitGenerationalBarrier::scanCut;
 ref part :>> prerequisite = residual;
 }
 part dependency19 : GambitAssuranceRouting::NeedDependency {
 ref part :>> dependent = GambitGenerationalBarrier::scanCut;
 ref part :>> prerequisite = ffi;
 }
 part boundRoute : GambitHostRootsRefinement::Route {
  ref part :>> need = bound;
  attribute :>> sourceAnchors = "mem.c:3490-3811,3241-3410,6316-6468;mem.h:63-79;gambit.h.in:9224-9226";
  attribute :>> patchAnchors = "Existing cumulative patch retained; no generational reservation implementation";
  attribute :>> projection = "Unique extents -> target costs -> physical disjoint capacity, claims and recovery";
  attribute :>> failureCustodian = "Pre-forward source owner; post-forward initialization descriptor and quarantine";
  attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part residualRoute : GambitHostRootsRefinement::Route {
  ref part :>> need = residual;
  attribute :>> sourceAnchors = "mem.c:3490-3811,3969-3986,4387-4455;_kernel.scm:3439-3558;_thread.scm:340-565";
  attribute :>> patchAnchors = "Existing cumulative patch retained; no card epoch handoff implementation";
  attribute :>> projection = "Closed producer edges -> residual post-layout ranges -> staged bitmap/seed -> next descriptor";
  attribute :>> failureCustodian = "Old epoch coordinator until descriptor commit; next descriptor plus retained old reader pins after commit";
  attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part ffiRoute : GambitHostRootsRefinement::Route {
  ref part :>> need = ffi;
  attribute :>> sourceAnchors = "mem.c:703-829,3969-3986;c_intf.c:6511-6562;os_dyn.c:744-795;tcltk.scm:288-342";
  attribute :>> patchAnchors = "Active nonzero RC and marker protection repairs retained, not new benefit";
  attribute :>> projection = "RC root permits separate from mature payload cards; callback reentry acquires exact installed epoch";
  attribute :>> failureCustodian = "Registered root domain/finite writer token; unresolved native alias blocks admission";
  attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part memoryRoute : GambitHostRootsRefinement::Route {
  ref part :>> need = memory;
  attribute :>> sourceAnchors = "mem.c:3241-3305,3533-3610;gambit.h.in:5328-5329,5482-5485";
  attribute :>> patchAnchors = "Existing synchronization repairs do not prove generated/native C race freedom";
  attribute :>> projection = "Claim readiness and epoch descriptor release/acquire, old reader drain and no generation ABA";
  attribute :>> failureCustodian = "Retain both descriptor banks and source/layout pins on unknown commit/drain";
  attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
 }
 part def CapacitySource {
 attribute sourceId : String;
 attribute sourceAnchors : String;
 attribute bound : String;
 attribute layoutFact : String;
 attribute hazard : String;
 attribute replacement : String;
 }
 part source0 : CapacitySource {
 attribute :>> sourceId = "heap";
 attribute :>> sourceAnchors = "mem.c:3490-3665; include/gambit.h.in:3110-3135";
 attribute :>> bound = "Sum aligned target sizes of every allocated nursery object, not predicted survivors";
 attribute :>> layoutFact = "64-bit no-handle unchanged target: payload plus one header; Y already includes headers";
 attribute :>> hazard = "Cannot count still/permanent as age or count the same heap frame twice";
 attribute :>> replacement = "Claim-before-payload target removes duplicate destination bodies; existing forwarding/readiness changes still required";
 }
 part source1 : CapacitySource {
 attribute :>> sourceId = "frame";
 attribute :>> sourceAnchors = "mem.c:3667-3811; gambit.h.in:6576,9224-9226; mem.h:63-70";
 attribute :>> bound = "Distinct stack frames: fs+2 target words; source extent roundUp(fs+3,4)";
 attribute :>> layoutFact = "fs<=8192 implies heap frame<=8194 words: 65552 bytes at word=8";
 attribute :>> hazard = "Root chains overlap: deduplicate by stack region generation and frame base; include retained contexts";
 attribute :>> replacement = "Whole closed allocated stack interval S bounds all frame targets; never add 2 per frame to S again";
 }
 part source2 : CapacitySource {
 attribute :>> sourceId = "worker";
 attribute :>> sourceAnchors = "mem.c:3241-3410;3490-3610";
 attribute :>> bound = "Unique object claim before destination allocation; descriptors for every candidate; worker private tails charged once";
 attribute :>> layoutFact = "Current first chunk link plus two end-marker positions; MSECTION_CHUNK=255 is a trigger, not hard extent limit";
 attribute :>> hazard = "32-bit pre-CAS pad can survive loser undo; repeated claims/empty chunk endings need an explicit count bound";
 attribute :>> replacement = "Selected modern-C monotone packs: per-segment tail < max target extent and fixed links; no empty publication cycle";
 }
 part source3 : CapacitySource {
 attribute :>> sourceId = "resume";
 attribute :>> sourceAnchors = "mem.c:3326-3355;6316-6468;mem.h:76-79";
 attribute :>> bound = "Disjoint resume nursery/stack/failure-delivery credit, not worker tospace tail credit";
 attribute :>> layoutFact = "Current msection=131072 words; each copying half=65536; prepare subtracts 2 and writes first link";
 attribute :>> hazard = "Global compute_msection_space is not the per-worker tospace capacity; physical native commit can fail";
 attribute :>> replacement = "Interval/layout transfer receipt before worker tails become context allocation space";
 }
 part source4 : CapacitySource {
 attribute :>> sourceId = "ffi";
 attribute :>> sourceAnchors = "mem.c:703-829,3969-3986;c_intf.c:6511-6562;os_dyn.c:744-795;tcltk.scm:288-342";
 attribute :>> bound = "Native RC data is a registered relocatable root; still payload/marker stores need mature source coverage";
 attribute :>> layoutFact = "Registration, mutation and release settle before seal; next callback gets the installed epoch permit";
 attribute :>> hazard = "RC lifetime/refcount does not establish root freeze, owner thread or payload-write closure";
 attribute :>> replacement = "Unknown native alias refuses cut; known next-epoch FFI old-to-young writes mark new bank, not residual from completed old epoch";
 }
 part def BenefitRow {
 attribute capability : String;
 attribute removedWork : String;
 attribute bound : String;
 attribute addedWork : String;
 attribute condition : String;
 }
 part benefit0 : BenefitRow {
 attribute :>> capability = "mature traversal";
 attribute :>> removedWork = "Repeated full mature scan/copy work on unchanged captured graphs";
 attribute :>> bound = "For k matched young collections and one comparable major: remove (k-1)*M work units";
 attribute :>> addedWork = "Charge A=barriers+dirty/frame decoding+root scans+promotion+coordination+major differences";
 attribute :>> condition = "Positive iff A<(k-1)*M under matched complete cost accounting; native time unmeasured";
 }
 part benefit1 : BenefitRow {
 attribute :>> capability = "capacity census";
 attribute :>> removedWork = "Repeated chain traversal or survivor speculation at collection entry";
 attribute :>> bound = "Maintain nursery high-water and closed stack extent bounds; enumerate exact layouts only if tighter credit desired";
 attribute :>> addedWork = "Y+S is payload bound only under unchanged layout; frame exact=sum(fs+2) deduplicated";
 attribute :>> condition = "Huge dead young allocation can force conservative reserve or preflight refusal; no unconditional memory win";
 }
 part benefit2 : BenefitRow {
 attribute :>> capability = "worker packing";
 attribute :>> removedWork = "No demonstrated loser-body saving: current 64-bit source already avoids it; replace implicit private-allocation custody";
 attribute :>> bound = "One destination per unique object; retry/padding reduction needs an actual schedule bound, not worker count";
 attribute :>> addedWork = "Bphysical=payload+packing slack+links+task storage+separate resume reserve, committed before forwarding";
 attribute :>> condition = "Claim table costs N*d bytes and coordination; native target progress/lock-free behavior unproved";
 }
 part benefit3 : BenefitRow {
 attribute :>> capability = "residual enumeration";
 attribute :>> removedWork = "Whole mature payload scan and normal full bitmap reset";
 attribute :>> bound = "Normal H+seedHints+S(D), overflow C+S(D); sparse reset D; residual R<=D plus admitted collector-created ranges";
 attribute :>> addedWork = "Two card banks + per-context logs + bounded global next seed endpoint; conservative overflow is safe";
 attribute :>> condition = "If dirty coverage spans whole mature heap S(D) approaches M; fallback metadata walk remains C";
 }
 part benefit4 : BenefitRow {
 attribute :>> capability = "peak memory";
 attribute :>> removedWork = "No implied improvement from work reduction";
 attribute :>> bound = "PeakCandidate=existingLiveAndRetainedSources+committedDestination+disjointResume+metadata";
 attribute :>> addedWork = "Extra bank C*b + seedCapacity*entryBytes + claim/descriptors + charged packing; old/new objects coexist until rewrite";
 attribute :>> condition = "DeltaPeak=PeakCandidate-PeakBaseline on same workload; may be positive, not generational GC magically saves space";
 }
 part benefit5 : BenefitRow {
 attribute :>> capability = "capability amplification";
 attribute :>> removedWork = "Repeated mature continuation work restricts economical reuse";
 attribute :>> bound = "Multi-shot captured graphs stay shared and nonmoving mature; generated semantics eliminate valid redundant barriers";
 attribute :>> addedWork = "All frame/denv/decoder/FFI writers, weak closure, identity and winding preserved; explicit portable native contract";
 attribute :>> condition = "Modern C supplies mechanism; Zig supplies no automatic capacity/epoch proof or established incremental benefit";
 }
 part def ViewNode {
 attribute nodeId : String;
 attribute labelText : String;
 }
 part node0 : ViewNode {
 attribute :>> nodeId = "census";
 attribute :>> labelText = "Closed nursery and stack extents";
 }
 part node1 : ViewNode {
 attribute :>> nodeId = "reserve";
 attribute :>> labelText = "Physical destination plus resume reservation";
 }
 part node2 : ViewNode {
 attribute :>> nodeId = "copy";
 attribute :>> labelText = "Unique claim, initialize, scan and rewrite";
 }
 part node3 : ViewNode {
 attribute :>> nodeId = "retained";
 attribute :>> labelText = "Retain source/root/initialization custody";
 }
 part node4 : ViewNode {
 attribute :>> nodeId = "stage";
 attribute :>> labelText = "Stage residual bitmap and seed or fallback";
 }
 part node5 : ViewNode {
 attribute :>> nodeId = "publish";
 attribute :>> labelText = "Publish immutable next epoch descriptor";
 }
 part node6 : ViewNode {
 attribute :>> nodeId = "reset";
 attribute :>> labelText = "Drain old bank readers then recycle";
 }
 part node7 : ViewNode {
 attribute :>> nodeId = "writers";
 attribute :>> labelText = "Next epoch Scheme and FFI writers";
 }
 part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
 part edge0 : ViewEdge { ref part :>> producer = node0; ref part :>> consumer = node1; attribute :>> labelText = "bound"; }
 part edge1 : ViewEdge { ref part :>> producer = node1; ref part :>> consumer = node2; attribute :>> labelText = "accepted"; }
 part edge2 : ViewEdge { ref part :>> producer = node1; ref part :>> consumer = node3; attribute :>> labelText = "refused"; }
 part edge3 : ViewEdge { ref part :>> producer = node2; ref part :>> consumer = node3; attribute :>> labelText = "breach"; }
 part edge4 : ViewEdge { ref part :>> producer = node2; ref part :>> consumer = node4; attribute :>> labelText = "closed"; }
 part edge5 : ViewEdge { ref part :>> producer = node4; ref part :>> consumer = node5; attribute :>> labelText = "seeded"; }
 part edge6 : ViewEdge { ref part :>> producer = node5; ref part :>> consumer = node6; attribute :>> labelText = "acquired"; }
 part edge7 : ViewEdge { ref part :>> producer = node5; ref part :>> consumer = node7; attribute :>> labelText = "permit"; }
}

