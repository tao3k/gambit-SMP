/* Modern C semantic authority; design and models only. */
package GambitRequestRetirement { private import ScalarValues::*;
part history:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-H";
attribute :>> kind="interleaving";
attribute :>> subjectPath="models/gambit/request_retirement.qnt";
attribute :>> subjectScope="request_retirement:W2-K3-G2-atomic-control-and-external-source-seals;seed17";
attribute :>> premise="Finite history and sampling checks; records, issued/settled ghost history, source/root/consumer/query/delivery/scan custody. Not exhaustive, C-order, arbitrary-word or liveness proof.";
}
part induction:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-I";
attribute :>> kind="induction";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="GambitSMP.RequestRetirement:prefix-step-reachability-and-conditional-custody-laws";
attribute :>> premise="Reachable-prefix proof for simplified mark/advance Step plus selective admission, no-wrap and custody laws; not full Quint/C simulation.";
}
part windowDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-WINDOW";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="RT-WINDOW:bounded-issued-window-and-prefix-hole-refinement";
attribute :>> premise="Every issued sequence reserves a physical slot; terminal out-of-order settlement stays a bitmap bit; advance only over exact settled head. Ghost history is not physical storage.";
}
part identityDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-ID";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="RT-ID:checked-sequence-domain-generation-and-VM-router";
attribute :>> premise="No modular reuse: sequence ceiling is representable sentinel K; generation and VM identities also checked; old generation/key rejection precedes record dereference; no raw expired VM pointer admitted.";
}
part oomDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-OOM";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="RT-OOM:prepublication-rejection-and-reserved-VM-escrow";
attribute :>> premise="Arena/bitmap/exit/result and source handle capacity precede publication; before reserve failure caller retains full mapped frame; after publish core settlement allocates nothing and VM exit escrow is already reserved.";
}
part reclaimDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::roots.component;
attribute :>> obligationId="RT-RECLAIM";
attribute :>> kind="source-refinement";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="RT-RECLAIM:result-source-reader-producer-drain-and-slot-reuse";
attribute :>> premise="Separate terminal result ACK, extra source lease ACK, physical scanner/borrower drain, control pins and producer seal. Key-only delayed envelopes may outlive record; no borrowed payload pointer may.";
}
part orderDuty:GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;
attribute :>> obligationId="RT-ORDER";
attribute :>> kind="native-memory-order";
attribute :>> subjectPath="models/gambit/lean/RequestRetirement.lean";
attribute :>> subjectScope="RT-ORDER:lock-release-acquire-ring-tag-and-capacity-C-order";
attribute :>> premise="One per-domain control lock arbitrates reserve/accept/close/lookup-pin/summary/prefix; no callbacks/allocation/GC wait under lock; separate root close adapter and checked all counters/sizes.";
}
ref part priorAck=GambitBootstrapRootRecovery::ackDuty;
ref part priorExit=GambitBootstrapRootRecovery::unwindDuty;
ref part priorRestore=GambitBootstrapRootRecovery::restoreDuty;
ref part priorGate=GambitResizeBootstrapAdmission::gate;
ref part priorMembers=GambitResizeBootstrapAdmission::membership;
part dependency0:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=windowDuty; ref part :>> prerequisite=history; }
part dependency1:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=windowDuty; ref part :>> prerequisite=induction; }
part dependency2:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identityDuty; ref part :>> prerequisite=history; }
part dependency3:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identityDuty; ref part :>> prerequisite=induction; }
part dependency4:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=oomDuty; ref part :>> prerequisite=history; }
part dependency5:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=oomDuty; ref part :>> prerequisite=induction; }
part dependency6:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=history; }
part dependency7:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=induction; }
part dependency8:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=history; }
part dependency9:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=induction; }
part dependency10:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=windowDuty; ref part :>> prerequisite=identityDuty; }
part dependency11:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=windowDuty; ref part :>> prerequisite=reclaimDuty; }
part dependency12:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=identityDuty; ref part :>> prerequisite=orderDuty; }
part dependency13:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=oomDuty; ref part :>> prerequisite=priorExit; }
part dependency14:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=oomDuty; ref part :>> prerequisite=priorGate; }
part dependency15:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=oomDuty; ref part :>> prerequisite=priorRestore; }
part dependency16:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=priorAck; }
part dependency17:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=priorExit; }
part dependency18:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=priorMembers; }
part dependency19:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=reclaimDuty; ref part :>> prerequisite=orderDuty; }
part dependency20:GambitAssuranceRouting::NeedDependency { ref part :>> dependent=orderDuty; ref part :>> prerequisite=priorGate; }
part def CallerRow {  attribute callerId:String; attribute sourceAnchors:String; attribute actualChain:String; attribute hazard:String; attribute replacement:String; }
part caller0:CallerRow { attribute :>> callerId="GENERATOR"; attribute :>> sourceAnchors="vendor/gambit/lib/_kernel.scm:2353-2361;gsc/_ptree2.scm:2850-2874,2902-2925,3238-3251"; attribute :>> actualChain="Scheme object aliases mapped CFUN_ARG; cleanup chosen by conversion types"; attribute :>> hazard="Reserve logical key and source/exit capacity before any native publication"; attribute :>> replacement="Untracked c-code or missing exit plan refuses managed admission"; }
part caller1:CallerRow { attribute :>> callerId="RESIZE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:1050-1112,1155-1178"; attribute :>> actualChain="Local sop contains thunk; executed result can precede later throw"; attribute :>> hazard="Replace pointer-bearing copy with fixed-slot key and typed result/query path"; attribute :>> replacement="Missing return is unknown, never proof of no effect"; }
part caller2:CallerRow { attribute :>> callerId="NATIVE-ALLOC"; attribute :>> sourceAnchors="vendor/gambit/lib/os_base.c:190-265;lib/mem.c:703-757"; attribute :>> actualChain="malloc wrapper returns NULL; RC header addition, default false payload and separate list registration"; attribute :>> hazard="Checked size calculation and arena initialization before publishing managed service"; attribute :>> replacement="Current malloc success/RC registration is not VM root acceptance"; }
part caller3:CallerRow { attribute :>> callerId="PHYSICAL-RC"; attribute :>> sourceAnchors="vendor/gambit/lib/mem.c:681-700,760-778,3970-3988,4928-4964"; attribute :>> actualChain="cleanup_rc frees chain, release_rc unlinks on zero, mark_rc scans data"; attribute :>> hazard="Canonical control arena and VM root view must outlive PSTATE cleanup"; attribute :>> replacement="No reuse of legacy processor RC refcount as a concurrent lookup pin"; }
part caller4:CallerRow { attribute :>> callerId="PARTIAL-RESIZE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:905-916,942-1001,4570-4600"; attribute :>> actualChain="GC overflow returns error; setup rollback, ignored join status and fatal thread-create failure differ"; attribute :>> hazard="Preflight control failure separate from accepted child/native outcome and imported member ledger"; attribute :>> replacement="No OOM classification can erase already published child effects"; }
part caller5:CallerRow { attribute :>> callerId="EXCEPTION-RESTORE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:3276-3423;include/gambit.h.in:9979-9988,10375-10404;lib/mem.c:4529-4561"; attribute :>> actualChain="catcher may rethrow; current slot reloaded through restored PSTATE; normal AT_END is insufficient"; attribute :>> hazard="Use reserved VM escrow with original error and independent restored binding"; attribute :>> replacement="Unknown raw borrower blocks handoff; no stack resurrection"; }
part caller6:CallerRow { attribute :>> callerId="BOOT-FAILURE"; attribute :>> sourceAnchors="vendor/gambit/lib/setup.c:6350-6440;lib/mem.c:4820-4837"; attribute :>> actualChain="setup_vmstate errors prevent main run and eventually cleanup"; attribute :>> hazard="Domain arena construction must complete before ready publication"; attribute :>> replacement="Service initialization failure leaves no admitted request"; }
part def PathRow {  attribute pathId:String; attribute sourceAnchors:String; attribute actualPath:String; attribute contract:String; attribute failure:String; attribute custodian:String; }
part path0:PathRow { attribute :>> pathId="PRE-ISSUE"; attribute :>> sourceAnchors="_ptree2.scm:3238-3251;_kernel.c:6258-6288"; attribute :>> actualPath="Caller full mapped frame exists before new service effects"; attribute :>> contract="Size/capacity failure emits known no-publication disposition without issuing sequence"; attribute :>> failure="No asynchronous waiter/throw callback while holding control lock"; attribute :>> custodian="Natural Scheme caller frame; never a raw unregistered local"; }
part path1:PathRow { attribute :>> pathId="POST-ISSUE"; attribute :>> sourceAnchors="setup.c:1050-1112,1155-1178"; attribute :>> actualPath="Return/throw can diverge from execution effect"; attribute :>> contract="Issued slot includes stable origin, exit escrow, safe false cells and status capacity"; attribute :>> failure="Unrelated allocation failure cannot erase published custody or reset key"; attribute :>> custodian="Canonical VM slot and frozen source until accepted-root ACK"; }
part path2:PathRow { attribute :>> pathId="OUT-OF-ORDER"; attribute :>> sourceAnchors="setup.c:942-1001;proposed fixed window"; attribute :>> actualPath="Actual child outcomes differ and may be unknown"; attribute :>> contract="Cancel/result and all control readers settle before compact fixed bit; prefix cannot cross gap"; attribute :>> failure="Window full returns pre-effect capacity rejection; no grow-to-record-OOM"; attribute :>> custodian="VM owns unresolved head and its roots; later bits consume bounded window"; }
part path3:PathRow { attribute :>> pathId="LATE-ENVELOPE"; attribute :>> sourceAnchors="setup.c:1155-1178;gambit.h.in:10402"; attribute :>> actualPath="Raw copied thunk is not a safe delayed control envelope"; attribute :>> contract="Transport VM/domain/sequence only; check router, current generation, prefix, issued range and full slot tag before pin"; attribute :>> failure="Wrong/expired/unissued keys rejected; no creation on retry lookup"; attribute :>> custodian="Sender retains no pointer into reusable control or payload backing"; }
part path4:PathRow { attribute :>> pathId="RECYCLE"; attribute :>> sourceAnchors="mem.c:760-778,3970-3988,4928-4964"; attribute :>> actualPath="Reference count/free and GC scans are distinct old mechanisms"; attribute :>> contract="Logical settlement, control unreachability, slot reuse and arena free are separate cuts"; attribute :>> failure="Never infer scanner stop or thread death from timeout/join failure"; attribute :>> custodian="VM root/child/view services until explicit drain receipts"; }
part path5:PathRow { attribute :>> pathId="EXHAUSTION"; attribute :>> sourceAnchors="setup.c:1155-1178;proposed key issuer"; attribute :>> actualPath="No existing canonical counter/rollover service"; attribute :>> contract="Check next<K before increment; K sentinel representable; generation limit refuses reuse"; attribute :>> failure="Optional fresh generation needs closed domain and raw producer/reader seal; no transparent live rollover claim"; attribute :>> custodian="Old root views remain VM owned; exhaustion cannot discard operations"; }
part def OrderRow {  attribute edgeId:String; attribute orderContract:String; attribute rejectedShortcut:String; }
part orderRow0:OrderRow { attribute :>> edgeId="RESERVE"; attribute :>> orderContract="Checked total sizes and complete safe slot precede lock-release publishing key; next increments only with reserved slot."; attribute :>> rejectedShortcut="No key issuance followed by fallible fallback/tombstone allocation."; }
part orderRow1:OrderRow { attribute :>> edgeId="LOOKUP"; attribute :>> orderContract="Router lifetime pin then domain lock; bounds/generation/tag check precedes record pin; unlock before actual Scheme/native work."; attribute :>> rejectedShortcut="Acquire after free cannot protect a stale raw pointer; no unconditional increment of zero/dead counter."; }
part orderRow2:OrderRow { attribute :>> edgeId="GC-CLOSE"; attribute :>> orderContract="Same admitted-root cut as imported RB-GATE; pending source remains scan-visible; cancellation control may proceed without root acceptance."; attribute :>> rejectedShortcut="No waiting for GC completion or owner callbacks under domain lock."; }
part orderRow3:OrderRow { attribute :>> edgeId="SUMMARY"; attribute :>> orderContract="Result and source ACK plus physical source/root/control-reader drain precede overwrite by settled bit; slot not reused until prefix excludes old key."; attribute :>> rejectedShortcut="Source ACK alone or aggregate scan coverage cannot justify releasing old source scan."; }
part orderRow4:OrderRow { attribute :>> edgeId="REUSE"; attribute :>> orderContract="Prefix/generation/full key tag published under same control lock; new slot initialization precedes exposing fresh identity."; attribute :>> rejectedShortcut="Sequence modulus selects storage only, never identity; counters, pin increments, bitmap rounding and byte products checked."; }
part orderRow5:OrderRow { attribute :>> edgeId="DOMAIN-FREE"; attribute :>> orderContract="Entry close, logical producer seal, raw-transport/borrower/GC drain and VM registry removal/pin drain precede physical domain free."; attribute :>> rejectedShortcut="Global numeric routing rejects unknown/dead VM identities; raw expired vms pointers are outside admission."; }
part def CostRow {  attribute capability:String; attribute removedWork:String; attribute bound:String; attribute addedCost:String; attribute condition:String; }
part cost0:CostRow { attribute :>> capability="Canonical bounded window"; attribute :>> removedWork="Remove per-retry canonical allocations and unbounded sparse tombstone growth"; attribute :>> bound="At most W outstanding keys, W fixed control cells and W settled bits; R deliveries still O(R) checks"; attribute :>> addedCost="W*H bytes reserved before ready plus bitmap/domain header"; attribute :>> condition="H includes embedded result/exit/root handles; root/frame/native backing counted separately exactly once."; }
part cost1:CostRow { attribute :>> capability="Prefix compression"; attribute :>> removedWork="Retire terminal records without retaining complete historical outcomes"; attribute :>> bound="One bit per settled hole; contiguous retired prefix is scalar; ghost history uses no physical allocation"; attribute :>> addedCost="A slow oldest key can stop new admission after W reservations"; attribute :>> condition="Safety is bounded control storage, not wait-free admission or bounded root lifetime."; }
part cost2:CostRow { attribute :>> capability="OOM after publication"; attribute :>> removedWork="Remove fallible status/tombstone/exit-record allocation from core settlement"; attribute :>> bound="0 required dynamic control allocations after reserve in proposed profile"; attribute :>> addedCost="Preallocation, checked arithmetic and source escrow slot are mandatory"; attribute :>> condition="Payload/child/resource allocations can still fail and must remain separately owned."; }
part cost3:CostRow { attribute :>> capability="Number exhaustion"; attribute :>> removedWork="Remove accidental ABA from modular ID reuse"; attribute :>> bound="Issue only sequence<K; K and generation sentinels fit machine type"; attribute :>> addedCost="Exhaustion is a typed refusal, possible domain drain and admitted rotation"; attribute :>> condition="Finite widths cannot prove unlimited fresh identities; no timeout, randomness or wide counter substitutes for proof."; }
part cost4:CostRow { attribute :>> capability="Reader lifetime"; attribute :>> removedWork="Permit key-only delayed envelopes after old record becomes unreachable"; attribute :>> bound="0 dereferenceable old record/payload pointers in unpinned transport"; attribute :>> addedCost="Lookup pins, VM router pin and full key revalidation"; attribute :>> condition="Unknown raw reader blocks safe physical release; epoch age is not a stop receipt."; }
part cost5:CostRow { attribute :>> capability="Root custody"; attribute :>> removedWork="Retain source until accepted-root or fenced terminal outcome and scanner drain"; attribute :>> bound="0 natural Scheme slots removed by source ACK"; attribute :>> addedCost="Frozen backing can survive metadata/result uncertainty"; attribute :>> condition="Window bound does not bound Scheme heap, frozen-frame or OS-thread peak."; }
part cost6:CostRow { attribute :>> capability="Modern C first cut"; attribute :>> removedWork="One generated source/key/effect contract shared by VM service and callers"; attribute :>> bound="Retire raw sop thunk copying and normal-only cleanup after whole producer/consumer migration"; attribute :>> addedCost="Fixed arena, generated origins and typed result/ownership statuses"; attribute :>> condition="Zig still needs these semantic supports; no additional Zig advantage established."; }
part def IdentityField { ref part need:GambitAssuranceRouting::ModelNeed; attribute fieldId:String; attribute sourceAnchors:String; attribute valueContract:String; attribute invalidShortcut:String; attribute failureCustodian:String; }
part fieldRow0:IdentityField { ref part :>> need=GambitRequestRetirement::identityDuty; attribute :>> fieldId="KEY"; attribute :>> sourceAnchors="_kernel.c:6258-6288;setup.c:1155-1178"; attribute :>> valueContract="VM lifetime identity / domain generation / sequence; stable logical invocation maps to one key"; attribute :>> invalidShortcut="Ring index, pointer or unchecked unsigned wrap as identity"; attribute :>> failureCustodian="Canonical slot and source activation"; }
part fieldRow1:IdentityField { ref part :>> need=GambitRequestRetirement::windowDuty; attribute :>> fieldId="WINDOW"; attribute :>> sourceAnchors="proposed issuer and registry"; attribute :>> valueContract="0<=floor<=next<=K and next-floor<=W; issued slot exists before key escapes"; attribute :>> invalidShortcut="Maximum seen/finished key replaces contiguous settled prefix"; attribute :>> failureCustodian="VM window owns every hole"; }
part fieldRow2:IdentityField { ref part :>> need=GambitRequestRetirement::oomDuty; attribute :>> fieldId="FAILURE-DISPOSITION"; attribute :>> sourceAnchors="os_base.c:190-265;setup.c:905-916,942-1001"; attribute :>> valueContract="NoPublication / PublishedPending / Accepted / TerminalUnknownDelivery are distinct"; attribute :>> invalidShortcut="malloc NULL or absent reply implies native effect absent"; attribute :>> failureCustodian="Natural source before issue; VM escrow after issue"; }
part fieldRow3:IdentityField { ref part :>> need=GambitRequestRetirement::reclaimDuty; attribute :>> fieldId="SETTLED-BIT"; attribute :>> sourceAnchors="mem.c:760-778,3970-3988"; attribute :>> valueContract="Bit certifies source/result ACK, producer close and pointer-bearing reader drain"; attribute :>> invalidShortcut="Bit is original result or Scheme payload capability"; attribute :>> failureCustodian="Fixed bitmap plus prefix, no per-hole allocation"; }
part fieldRow4:IdentityField { ref part :>> need=GambitRequestRetirement::identityDuty; attribute :>> fieldId="EXHAUSTION"; attribute :>> sourceAnchors="proposed checked issuer"; attribute :>> valueContract="Representable K sentinel, checked generation and VM namespace; stop before wrap"; attribute :>> invalidShortcut="Just use a large uint or serial-number half-range without delay bound"; attribute :>> failureCustodian="VM preserves unresolved slots and refuses fresh requests"; }
part def Transition { ref part need:GambitAssuranceRouting::ModelNeed; attribute fromPhase:String; attribute toPhase:String; attribute qntStep:String; attribute guardContract:String; attribute leanLaw:String; attribute sourceAnchors:String; }
part transition0:Transition { ref part :>> need=GambitRequestRetirement::oomDuty; attribute :>> fromPhase="NotReady"; attribute :>> toPhase="Unavailable"; attribute :>> qntStep="poolInitFail"; attribute :>> guardContract="No ready/key publication before complete arena initialization"; attribute :>> leanLaw="oomDoesNotInventPublication"; attribute :>> sourceAnchors="os_base.c:190-265;setup.c:6350-6440"; }
part transition1:Transition { ref part :>> need=GambitRequestRetirement::oomDuty; attribute :>> fromPhase="MappedCaller"; attribute :>> toPhase="KnownNoPublication"; attribute :>> qntStep="preflightFail"; attribute :>> guardContract="No sequence/effect and natural caller roots retained"; attribute :>> leanLaw="oomRetainsCoverage"; attribute :>> sourceAnchors="_kernel.c:26338-26368;_ptree2.scm:3238-3251"; }
part transition2:Transition { ref part :>> need=GambitRequestRetirement::windowDuty; attribute :>> fromPhase="AvailableSlot"; attribute :>> toPhase="IssuedSourceOwned"; attribute :>> qntStep="reserve"; attribute :>> guardContract="One slot + exit/result capacity before exposing key"; attribute :>> leanLaw="reserveBoundsWindow"; attribute :>> sourceAnchors="setup.c:1155-1178;proposed generated preflight"; }
part transition3:Transition { ref part :>> need=GambitRequestRetirement::identityDuty; attribute :>> fromPhase="SequenceLimit"; attribute :>> toPhase="Refused"; attribute :>> qntStep="closeDomain"; attribute :>> guardContract="No modular increment; exhausted state retains all known custody"; attribute :>> leanLaw="exhaustedRefuses"; attribute :>> sourceAnchors="proposed checked native key issuer"; }
part transition4:Transition { ref part :>> need=GambitRequestRetirement::reclaimDuty; attribute :>> fromPhase="IssuedSourceOwned"; attribute :>> toPhase="AcceptedRoot"; attribute :>> qntStep="queue / pinDelivery / accept / unpinDelivery"; attribute :>> guardContract="Current full key pinned; root-admission/GC close cut respected"; attribute :>> leanLaw="releasingSourceNeedsOtherCustody"; attribute :>> sourceAnchors="setup.c:975-1001;mem.c:3970-3988"; }
part transition5:Transition { ref part :>> need=GambitRequestRetirement::oomDuty; attribute :>> fromPhase="PendingOrAccepted"; attribute :>> toPhase="VmExitCustody"; attribute :>> qntStep="takeEscrow / closeProducer / exitOwner"; attribute :>> guardContract="Pre-reserved stable view and effect progress precede physical unwind"; attribute :>> leanLaw="exitRequiresReservedCustody"; attribute :>> sourceAnchors="setup.c:3276-3423;gambit.h.in:9979-9988"; }
part transition6:Transition { ref part :>> need=GambitRequestRetirement::reclaimDuty; attribute :>> fromPhase="TerminalOutcome"; attribute :>> toPhase="SettledHole"; attribute :>> qntStep="sourceAck / releaseSource / resultAck / summarize"; attribute :>> guardContract="Separate ACKs and every actual pointer-bearing reader drained"; attribute :>> leanLaw="resultUnknownKeepsRecord"; attribute :>> sourceAnchors="mem.c:760-778,3970-3988;proposed service"; }
part transition7:Transition { ref part :>> need=GambitRequestRetirement::windowDuty; attribute :>> fromPhase="SettledHead"; attribute :>> toPhase="CompressedPrefix"; attribute :>> qntStep="advance"; attribute :>> guardContract="Only exact head bit advances; unresolved lower key remains owned"; attribute :>> leanLaw="advanceNeedsExactHead"; attribute :>> sourceAnchors="proposed bounded prefix/ring service"; }
part transition8:Transition { ref part :>> need=GambitRequestRetirement::identityDuty; attribute :>> fromPhase="DrainedClosedDomain"; attribute :>> toPhase="FreshGeneration"; attribute :>> qntStep="closeDomain / sealHandles / rotate"; attribute :>> guardContract="No raw old handles/readers; checked fresh generation, no live automatic switch"; attribute :>> leanLaw="nextGenerationRejectsOld"; attribute :>> sourceAnchors="setup.c:942-1001;proposed domain gate"; }
part transition9:Transition { ref part :>> need=GambitRequestRetirement::reclaimDuty; attribute :>> fromPhase="RetiredKeyEnvelope"; attribute :>> toPhase="RejectedNoDereference"; attribute :>> qntStep="retry / rejectLate"; attribute :>> guardContract="Key-only envelope crosses no raw pointer lifetime; full router/window/tag validation"; attribute :>> leanLaw="expiredKeyRejects"; attribute :>> sourceAnchors="setup.c:1155-1178;proposed transport"; }
part def SourceRoute { ref part need:GambitAssuranceRouting::ModelNeed; attribute sourceAnchors:String; attribute projection:String; attribute failureCustodian:String; attribute status:String; }
part route0:SourceRoute { ref part :>> need=GambitRequestRetirement::windowDuty; attribute :>> sourceAnchors="setup.c:942-1001;proposed fixed window"; attribute :>> projection="Cancel/result and all control readers settle before compact fixed bit; prefix cannot cross gap"; attribute :>> failureCustodian="VM owns unresolved head and its roots; later bits consume bounded window"; attribute :>> status="source-and-C-order-refinement-open"; }
part route1:SourceRoute { ref part :>> need=GambitRequestRetirement::identityDuty; attribute :>> sourceAnchors="setup.c:1155-1178;proposed key issuer"; attribute :>> projection="Check next<K before increment; K sentinel representable; generation limit refuses reuse"; attribute :>> failureCustodian="Old root views remain VM owned; exhaustion cannot discard operations"; attribute :>> status="source-and-C-order-refinement-open"; }
part route2:SourceRoute { ref part :>> need=GambitRequestRetirement::oomDuty; attribute :>> sourceAnchors="_ptree2.scm:3238-3251;_kernel.c:6258-6288"; attribute :>> projection="Size/capacity failure emits known no-publication disposition without issuing sequence"; attribute :>> failureCustodian="Natural Scheme caller frame; never a raw unregistered local"; attribute :>> status="source-and-C-order-refinement-open"; }
part route3:SourceRoute { ref part :>> need=GambitRequestRetirement::reclaimDuty; attribute :>> sourceAnchors="mem.c:760-778,3970-3988,4928-4964"; attribute :>> projection="Logical settlement, control unreachability, slot reuse and arena free are separate cuts"; attribute :>> failureCustodian="VM root/child/view services until explicit drain receipts"; attribute :>> status="source-and-C-order-refinement-open"; }
part route4:SourceRoute { ref part :>> need=GambitRequestRetirement::orderDuty; attribute :>> sourceAnchors="setup.c:1155-1178;gambit.h.in:10402"; attribute :>> projection="Transport VM/domain/sequence only; check router, current generation, prefix, issued range and full slot tag before pin"; attribute :>> failureCustodian="Sender retains no pointer into reusable control or payload backing"; attribute :>> status="source-and-C-order-refinement-open"; }
part def DiagramNode {  attribute nodeId:String; attribute labelText:String; }
part node0:DiagramNode { attribute :>> nodeId="caller"; attribute :>> labelText="Complete mapped caller roots"; }
part node1:DiagramNode { attribute :>> nodeId="preflight"; attribute :>> labelText="Checked fixed arena and capacity"; }
part node2:DiagramNode { attribute :>> nodeId="fail"; attribute :>> labelText="No-publication refusal; caller keeps roots"; }
part node3:DiagramNode { attribute :>> nodeId="slot"; attribute :>> labelText="Issued key and reserved VM escrow"; }
part node4:DiagramNode { attribute :>> nodeId="accept"; attribute :>> labelText="GC close arbitrates root acceptance"; }
part node5:DiagramNode { attribute :>> nodeId="query"; attribute :>> labelText="Pinned metadata query; exact key"; }
part node6:DiagramNode { attribute :>> nodeId="exit"; attribute :>> labelText="VM custody before exceptional exit"; }
part node7:DiagramNode { attribute :>> nodeId="settle"; attribute :>> labelText="Result/source ACK and reader drain"; }
part node8:DiagramNode { attribute :>> nodeId="hole"; attribute :>> labelText="Settled bit; earlier hole stays owned"; }
part node9:DiagramNode { attribute :>> nodeId="prefix"; attribute :>> labelText="Advance only over settled head"; }
part node10:DiagramNode { attribute :>> nodeId="reuse"; attribute :>> labelText="Reuse slot with new full key"; }
part node11:DiagramNode { attribute :>> nodeId="limit"; attribute :>> labelText="Exhaustion: refuse or sealed fresh domain"; }
part node12:DiagramNode { attribute :>> nodeId="late"; attribute :>> labelText="Late key rejected before dereference"; }
part def DiagramEdge { ref part producer:DiagramNode; ref part consumer:DiagramNode; attribute labelText:String; }
part edge0:DiagramEdge { ref part :>> producer=node0; ref part :>> consumer=node1; attribute :>> labelText="pre-effect complete view"; }
part edge1:DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node2; attribute :>> labelText="size/capacity/OOM fail"; }
part edge2:DiagramEdge { ref part :>> producer=node1; ref part :>> consumer=node3; attribute :>> labelText="reserve before publish"; }
part edge3:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node4; attribute :>> labelText="source remains until accepted"; }
part edge4:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node5; attribute :>> labelText="lost return queries same key"; }
part edge5:DiagramEdge { ref part :>> producer=node3; ref part :>> consumer=node6; attribute :>> labelText="exception retains reserved escrow"; }
part edge6:DiagramEdge { ref part :>> producer=node4; ref part :>> consumer=node7; attribute :>> labelText="independent source and result ACK"; }
part edge7:DiagramEdge { ref part :>> producer=node5; ref part :>> consumer=node7; attribute :>> labelText="current canonical status"; }
part edge8:DiagramEdge { ref part :>> producer=node6; ref part :>> consumer=node7; attribute :>> labelText="no callback wait under lock"; }
part edge9:DiagramEdge { ref part :>> producer=node7; ref part :>> consumer=node8; attribute :>> labelText="compact only after drain"; }
part edge10:DiagramEdge { ref part :>> producer=node8; ref part :>> consumer=node9; attribute :>> labelText="cannot jump unresolved head"; }
part edge11:DiagramEdge { ref part :>> producer=node9; ref part :>> consumer=node10; attribute :>> labelText="prefix excludes old key"; }
part edge12:DiagramEdge { ref part :>> producer=node10; ref part :>> consumer=node11; attribute :>> labelText="checked finite identity space"; }
part edge13:DiagramEdge { ref part :>> producer=node9; ref part :>> consumer=node12; attribute :>> labelText="key-only delayed delivery"; }
part edge14:DiagramEdge { ref part :>> producer=node11; ref part :>> consumer=node12; attribute :>> labelText="old generation never reopens"; }
part def ResearchGate { attribute gateId:String; }
part def GateNeed { ref part gate:ResearchGate; ref part need:GambitAssuranceRouting::ModelNeed; }
part gateRow0:ResearchGate { attribute :>> gateId="window-and-identity"; }
part gateNeed0:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitRequestRetirement::windowDuty; }
part gateNeed1:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitRequestRetirement::identityDuty; }
part gateNeed2:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitRequestRetirement::reclaimDuty; }
part gateNeed3:GateNeed { ref part :>> gate=gateRow0; ref part :>> need=GambitRequestRetirement::orderDuty; }
part gateRow1:ResearchGate { attribute :>> gateId="failure-custody"; }
part gateNeed4:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitRequestRetirement::oomDuty; }
part gateNeed5:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitRequestRetirement::priorExit; }
part gateNeed6:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitRequestRetirement::priorAck; }
part gateNeed7:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitRequestRetirement::priorRestore; }
part gateNeed8:GateNeed { ref part :>> gate=gateRow1; ref part :>> need=GambitRequestRetirement::priorGate; }
part gateRow2:ResearchGate { attribute :>> gateId="first-cut"; }
part gateNeed9:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::windowDuty; }
part gateNeed10:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::identityDuty; }
part gateNeed11:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::oomDuty; }
part gateNeed12:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::reclaimDuty; }
part gateNeed13:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::orderDuty; }
part gateNeed14:GateNeed { ref part :>> gate=gateRow2; ref part :>> need=GambitRequestRetirement::priorMembers; }
part def WindowCut { attribute low:Integer; attribute nextId:Integer; attribute width:Integer; attribute limit:Integer; attribute headSettled:Boolean; attribute readers:Integer; attribute resultAck:Boolean; attribute sourceGone:Boolean; attribute producerClosed:Boolean; attribute canReserve:Boolean=low>=0 and low<=nextId and nextId<limit and nextId-low<width; attribute canAdvance:Boolean=low<nextId and headSettled; attribute canSummarize:Boolean=readers==0 and resultAck and sourceGone and producerClosed; attribute naturalSchemeSlotsCleared:Integer=0; }
part available:WindowCut { attribute :>> low=0; attribute :>> nextId=1; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=false; attribute :>> readers=0; attribute :>> resultAck=false; attribute :>> sourceGone=false; attribute :>> producerClosed=false; }
part holeFull:WindowCut { attribute :>> low=0; attribute :>> nextId=2; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=false; attribute :>> readers=0; attribute :>> resultAck=true; attribute :>> sourceGone=true; attribute :>> producerClosed=true; }
part headReady:WindowCut { attribute :>> low=0; attribute :>> nextId=2; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=true; attribute :>> readers=0; attribute :>> resultAck=true; attribute :>> sourceGone=true; attribute :>> producerClosed=true; }
part queryPinned:WindowCut { attribute :>> low=0; attribute :>> nextId=2; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=true; attribute :>> readers=1; attribute :>> resultAck=true; attribute :>> sourceGone=true; attribute :>> producerClosed=true; }
part lostResult:WindowCut { attribute :>> low=0; attribute :>> nextId=2; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=true; attribute :>> readers=0; attribute :>> resultAck=false; attribute :>> sourceGone=true; attribute :>> producerClosed=true; }
part exhausted:WindowCut { attribute :>> low=3; attribute :>> nextId=3; attribute :>> width=2; attribute :>> limit=3; attribute :>> headSettled=false; attribute :>> readers=0; attribute :>> resultAck=true; attribute :>> sourceGone=true; attribute :>> producerClosed=true; }
part def WindowCapacity { attribute width:Integer; attribute maxOutstanding:Integer=width; attribute controlCells:Integer=width; attribute bitmapBits:Integer=width; attribute requiredPostPublishControlAllocations:Integer=0; }
part finite:WindowCapacity { attribute :>> width=2; }
part wider:WindowCapacity { attribute :>> width=64; }
}
