#!/bin/bash
set -euo pipefail
out=dev/architecture/runtime/gc/models/sysml/generational-barrier.sysml
cat > "$out" <<'EOF'
/* Modern C target: durable card coverage, optional hint logs, no hidden GC.
 * Scope includes writer/cut and destructive-promotion custody, not a complete collector. */
package GambitGenerationalBarrier {
    private import ScalarValues::*;
    part def BarrierPolicy {
        attribute authority : String;
        attribute fastPath : String;
        attribute overflow : String;
        attribute cut : String;
        attribute rootStore : String;
        attribute publication : String;
        attribute promotion : String;
        attribute failure : String;
        attribute elision : String;
        attribute scopeBoundary : String;
    }
    part protocol : BarrierPolicy {
        attribute :>> authority = "Preallocated per-region card table is complete; per-context bounded dirty-card hints accelerate enumeration but are not the only root boundary record";
        attribute :>> fastPath = "Validate source/class and write extent; premark all touched cards before store/CAS; complete finite no-safepoint primitive before acknowledging stop; no allocation, callback or collection inside barrier";
        attribute :>> overflow = "Sticky epoch overflow before unhinted store; keep durable dirty cards; after stop scan allocated card metadata, then dirty object/frame ranges; never overwrite unconsumed hints or clear coverage";
        attribute :>> cut = "Close new writes; settle admitted stores; acquire every context/native writer acknowledgement and local log endpoint; seal same VM/region/generation epoch; exclude reset, unlink and region reuse";
        attribute :>> rootStore = "RC and external root slots use RootRegistry identity and final-value park/reload; native RC headers are not managed-heap cards; scan all admitted root slots";
        attribute :>> publication = "Premark and field store sequenced before writer release acknowledgement; coordinator acquire before card/root scan; collector address rewrite before release completion and acquired rooted reload";
        attribute :>> promotion = "Before first forwarding reserve physical destination, header/alignment, captured-frame expansion, copy/task metadata and worker slack; published forwarding retains initialization and descendant scan owner; root redirection need not imply readable payload";
        attribute :>> failure = "Preflight rejection retains original source, committed stores and dirty state; unpublished local reserve may refund; after any forwarding no whole-epoch rollback or mutator resume until completion; unexpected breach quarantines both spaces and debts";
        attribute :>> elision = "Scheme proves young source or nonyoung value for generational barrier elision; private mature initialization needs publish-time coverage and no missed GC cut; concurrent-major barriers are separate";
        attribute :>> scopeBoundary = "Ordinary C data-race freedom and mixed generated-C semantics need their own proof; weak/will, full reserve bound, full VM/product/source simulation and native performance stay open";
    }
EOF
need() {
 cat >> "$out" <<EOF
    part $1 : GambitAssuranceRouting::ModelNeed {
        ref part :>> owner = GambitRuntimeAssurance::work.component;
        attribute :>> obligationId = "$2";
        attribute :>> kind = "$3";
        attribute :>> subjectPath = "$4";
        attribute :>> subjectScope = "$5";
        attribute :>> premise = "$6";
    }
EOF
}
need history WB-H interleaving models/gambit/generational_barrier.qnt 'generational_barrier:Test$' 'Twenty-two finite histories plus sampled positive steps; three slots/two cards/one copy object; no source or liveness proof'
need induction WB-I induction models/gambit/lean/GenerationalBarrier.lean 'GambitSMP.GenerationalBarrier:recordPreservesCoverage;commitPreservesCoverage;recordDoesNotCollect;commitDoesNotCollect;markPreservesLogCompleteness;selectedCoversDirty;sourceSlotsCovered;noFinishWithCopyDebt;noRollbackAfterForward;claimPreservesBudget;reclaimRequiresRewrite;validatedElision' 'Parametric card/slot coverage, bounded-log fallback, no-collect target transforms and conditional copy/credit guards; full QNT/C refinement open'
need writers WB-WRITERS source-refinement models/gambit/lean/GenerationalBarrier.lean 'WB-WRITERS:actual-source-refinement' 'Continuation heap/stack setters, denv caches/bindings, decoder/bulk/init, generic/CAS and native RootWrite or reject all unknown aliases'
need logs WB-LOG source-refinement models/gambit/lean/GenerationalBarrier.lean 'WB-LOG:actual-source-refinement' 'Durable card table, bounded hint writes, sticky overflow and complete object/frame ranges; no allocator/callback/GC in barrier lowering'
need scanCut WB-SNAPSHOT source-refinement models/gambit/lean/GenerationalBarrier.lean 'WB-SNAPSHOT:actual-source-refinement' 'Every admitted writer finishes or aborts before final-value acknowledgement; immutable same-epoch card/root/region snapshot, no concurrent reset'
need promotion WB-PROMOTE source-refinement models/gambit/lean/GenerationalBarrier.lean 'WB-PROMOTE:actual-source-refinement' 'Physical no-fail destination/work reservation, alias rewrite, partial-copy/Tail custody and all failure endpoints including unexpected breach'
need memoryOrder WB-MEMORY native-memory-order vendor/gambit/lib/mem.c 'WB-MEMORY:actual-source-refinement' 'Atomic card updates, final stores/acks, scan/reset and forwarding readiness happens-before; source plain/atomic access and native lock/progress complete'
idx=0
dep() {
 cat >> "$out" <<EOF
    part dependency$idx : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = $1;
        ref part :>> prerequisite = $2;
    }
EOF
 idx=$((idx+1))
}
for p in history induction writers logs scanCut promotion memoryOrder; do dep GambitGenerationalAdmission::source "$p"; done
for n in writers logs scanCut promotion; do for p in history induction memoryOrder; do dep "$n" "$p"; done; done
dep memoryOrder GambitRuntimeAssurance::work.platform
dep memoryOrder GambitRcFreezePublication::memoryOrder
dep writers GambitRuntimeAssurance::control.source
dep writers GambitRcFreezePublication::census
dep logs writers
dep scanCut logs
dep scanCut GambitRcFreezePublication::freeze
dep scanCut GambitRetainedRcScan::membership
dep promotion scanCut
dep promotion GambitRuntimeAssurance::work.source
cat >> "$out" <<'EOF'
    part def WriterRoute {
        attribute writerId : String;
        attribute sourceAnchors : String;
        attribute actualChain : String;
        attribute storeClass : String;
        attribute boundary : String;
    }
EOF
writer() {
 cat >> "$out" <<EOF
    part writer$1 : WriterRoute {
        attribute :>> writerId = "$2";
        attribute :>> sourceAnchors = "$3";
        attribute :>> actualChain = "$4";
        attribute :>> storeClass = "$5";
        attribute :>> boundary = "$6";
    }
EOF
}
writer 0 FRAME '_kernel.scm:3439-3558; _io.scm:11706-11727' 'reader frame dispatch -> implode-frame -> make-frame -> frame-set; continuation-set has heap and stack branches' 'Mature heap slot: MutateStore/range card; active stack slot: root/frame write permit' 'Interrupt masking is not no-GC proof; frame-link structural edits require FrameSpec validity'
writer 1 SHELL '_kernel.scm:3154-3162,3595-3727; gambit.h.in:5908-5931; _t-c-2.scm:4263-4273' 'frame/denv setters; make/copy shell and continuation-next cursor update' 'InitStore before safe publication or ordinary mature MutateStore; preserve shared aliases' 'Shallow shell copy does not duplicate reachable mutable Scheme state'
writer 2 SMP-DENV '_thread.scm:340-565; _thread#.scm:735-886; _gambit#.scm:638-643' 'dynamic-ref cache2/cache3/miss -> cache writes; dynamic-set -> pair cdr/default/cache; dynamic-let -> persistent env construction' 'Thread/denv/vector/pair managed stores; proven private young init may elide' 'SMP env-insert! is reader-commented; cache1 hit alone is not the whole lookup path'
writer 3 OTHER-DENV '_thread.scm:9-44,5351-5368,5654-5874; _thread#.scm:2990-3039' 'Conditional non-SMP dynamic lookup/set/let and active destructive env insertion' 'Profile-specific generic field/pair/card writes' 'Source branch inventory only; configured/loaded selection not executed'
writer 4 CONTROL '_kernel.scm:1354-1378,1115-1346; gambit.h.in:6314-6330,6377-6387,6654-6665,6716-6736' 'dynamic-env-bind install/restore; scheduler save/restore; graft/return denv and cache assignments' 'Managed thread/shell stores plus exact active-root handoff; collector/control relocation authority distinct' 'Current thread being active does not imply its managed object is young; nonlocal exits need winding cleanup'
writer 5 DECODE '_io.scm:11756-11824,12726-12845,12883-12908,13729-13798' 'reader deserialization and delayed closure/list/vector fixups -> real setters' 'BulkWrite/MutateStore after rooted valid initialization; all touched card and pointer-slot ranges' 'General cyclic/forward frame repair is not established; do not invent a frame fixup callback'
writer 6 GENERIC 'gambit.h.in:5328-5329,5482-5485,6764-6771; _t-c-2.scm:3356-3365' 'pair/vector/global writes and vector CAS; inactive SSB reservation hook' 'Premark before store/CAS; failed CAS may leave harmless dirty card; globals are roots' 'Successful-CAS-only logging needs separate race proof; unused hook is not an active barrier'
writer 7 FFI-ROOT 'mem.c:703-829,3969-3986; os_dyn.c:744-795; examples/tcltk/tcltk.scm:125-195,288-342' 'RC allocation/register/data write; dynamic C closure and Tcl ClientData producers/readers/delete' 'RootRegistry RootWrite and final-value freeze; C writes into managed payload require validated owner/range barrier' 'Raw RC data is not a heap card; unknown native aliases/threads cannot be repaired just by scanning cards'
writer 8 FFI-ENTRY 'c_intf.c:6511-6562; setup.c:3275-3422; gambit.h.in:10040-10138,10325-10480' 'SFUN and run marker allocation; CFUN conversions/writeback/reentry and cleanup' 'Protected handles before declared allocating points; barrier primitive cannot call back; reacquire/reload after GC' 'Existing cumulative patch protects some paths; full generated/embedded C and nonlocal exit closure remains open'
writer 9 COLLECTOR 'mem.c:3490-3665,3667-3966,4210-4245' 'forwarding CAS before payload copy; captured-stack expansion; chunk publication and tail scan' 'Collector-exclusive relocation and explicit initialization/scan custody, not a recursive mutator barrier' 'Root redirection may precede copy completion; payload consumption and phase completion may not'
cat >> "$out" <<'EOF'
    part def Amplification {
        attribute capability : String;
        attribute mechanism : String;
        attribute removedWork : String;
        attribute addedWork : String;
        attribute condition : String;
        attribute falsifier : String;
    }
EOF
benefit() {
 cat >> "$out" <<EOF
    part benefit$1 : Amplification {
        attribute :>> capability = "$2";
        attribute :>> mechanism = "$3";
        attribute :>> removedWork = "$4";
        attribute :>> addedWork = "$5";
        attribute :>> condition = "$6";
        attribute :>> falsifier = "$7";
    }
EOF
}
benefit 0 'Scheme semantic leverage' 'Generator carries source-age/value/escape and checkpoint evidence into semantic stores' 'E proved-unnecessary generational barrier operations out of W pointer stores' 'Analysis/contract validation and remaining W-E barriers; major barriers separate' 'Elision receipt valid for actual source/value and publication lifetime' 'Captured alias, callback escape or allocating constructor invalidates young/private premise'
benefit 1 'Reusable multi-shot continuations' 'FrameSpec scan ranges plus all frame/denv writes recorded' 'Repeated scan/copy of unchanged mature captured frames across eligible minor epochs' 'Dirty frame/card ranges, alias rewrites, active roots and activation work' 'Every setter/decoder/FFI/control writer covered; sharing and eq? identity retained' 'One omitted mature write or structural frame edit invalidates skip'
benefit 2 'Tail-call and high-order execution' 'Semantic call/checkpoint plan separates poll/allocation from noncollecting stores' 'Hidden GC/root-spill path from a barrier; redundant barriers only when proved' 'Explicit poll latency bound, roots at declared safepoints and mandatory stores' 'Finite barrier region and correct allocation/poll placement; tail-call semantics retained' 'Unbounded no-poll tail loop, callback in barrier, or hidden log allocation'
benefit 3 'C-friendly multicore embedding' 'RootRegistry park/reload plus fixed-size card metadata and no surprise store safepoint' 'Repeated whole-mature scan when complete dirty precision is available' 'Atomic card operations, writer acknowledgements, root scan and rejected raw escapes' 'All native writers enrolled; DRF/atomic field access and VM binding specified' 'Unmediated C store or copying an unsafe volatile pattern from another runtime'
benefit 4 'Overflow without lost coverage' 'Durable cards plus bounded context hints; sticky overflow selects bitmap walk' 'On normal epochs enumeration of all C card entries; no per-store log growth' 'Hint appends, duplicate filtering, overflow O(C) metadata walk plus dirty-range scan' 'Every relevant write marks card; snapshot has complete per-context overflow/hints' 'Lost dirty bit, concurrent reset or missing range/region identity'
benefit 5 'Parallel promotion with custody' 'No-fail reserve before forwarding and explicit partial-copy owner' 'Whole-epoch restart/duplicate canonical copying can be avoided under the contract' 'Worst-case destination/task reserve, worker slack and failure retention' 'Physical reservation bound covers layout expansion, stack capture and all simultaneous claims' 'Reserve covers only likely survivors; premature refund or discarded initialization task'
for spec in writers:writer0 logs:writer6 scanCut:writer7 promotion:writer9 memoryOrder:writer9; do
 n=${spec%:*}; anchor=${spec#*:}
 cat >> "$out" <<EOF
    part ${n}Route : GambitHostRootsRefinement::Route {
        ref part :>> need = $n;
        attribute :>> sourceAnchors = $anchor.sourceAnchors;
        attribute :>> patchAnchors = "cumulative.patch:3160-3234,3443-3460; retained repairs do not implement generational stores or reserve receipts";
        attribute :>> projection = protocol.$(case "$n" in writers) echo elision;; logs) echo overflow;; scanCut) echo cut;; promotion) echo promotion;; *) echo publication;; esac);
        attribute :>> failureCustodian = protocol.failure;
        attribute :>> status = "target-contract-specified-concrete-source-and-memory-open";
    }
EOF
done
cat >> "$out" <<'EOF'
    part def ViewNode { attribute nodeId : String; attribute labelText : String; }
    part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }
EOF
node() { cat >> "$out" <<EOF
    part $1 : ViewNode { attribute :>> nodeId = "$1"; attribute :>> labelText = "$2"; }
EOF
}
edge() { cat >> "$out" <<EOF
    part edge$1 : ViewEdge { ref part :>> producer = $2; ref part :>> consumer = $3; attribute :>> labelText = "$4"; }
EOF
}
node semantic 'Scheme semantic StorePlan: proved elision / declared checkpoints'
node writeOp 'Finite noncollecting store / bulk / CAS'
node cards 'Durable per-region dirty cards'
node hints 'Bounded local hints + sticky overflow'
node cut 'Same-epoch cut: all writers settled / roots parked'
node capacity 'Physical destination + copy-work reserve'
node pendingCopy 'Forwarding visible: copy initialization still owned'
node readyCopy 'Ready payload + descendant scan + alias rewrite'
node complete 'Epoch completion / dirty reset / source reclaim'
node retry 'Pre-forward failure: retain original stores and dirty state'
node quarantine 'Post-forward unexpected failure: retain both spaces / debts'
edge 0 semantic writeOp 'generated semantic contract'
edge 1 writeOp cards 'premark before heap write'
edge 2 writeOp hints 'optional acceleration'
edge 3 cards cut 'overflow: enumerate dirty-card metadata'
edge 4 hints cut 'normal: deduplicate hinted cards'
edge 5 cut capacity 'no unfinished mutator store'
edge 6 capacity pendingCopy 'all required capacity reserved'
edge 7 capacity retry 'reject before any forwarding'
edge 8 pendingCopy readyCopy 'initialize before payload read'
edge 9 pendingCopy quarantine 'no rollback or mutator resume'
edge 10 readyCopy complete 'all root/field aliases updated'
edge 11 complete writeOp 'next epoch'
edge 12 retry writeOp 'safe checkpoint retry / error'
echo '}' >> "$out"
