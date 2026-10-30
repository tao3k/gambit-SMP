from pathlib import Path
import json,re
base=Path('dev/architecture/toolchain/models/sysml')
header='''package GambitStableView {
    private import ScalarValues::*;
    private import GambitToolchain::*;
    /* Qualification model only: no issuer or runtime implementation. */
    part def StableViewQualification {
        attribute issueRequested : Boolean;
        attribute writerSetClosed : Boolean;
        attribute ingressSerialized : Boolean;
        attribute readPinsProtected : Boolean;
        attribute rootsQualified : Boolean;
        attribute generationMatched : Boolean;
        attribute payloadEpochMatched : Boolean;
        attribute releaseRequested : Boolean;
        attribute pinsDrained : Boolean;
        attribute cleanupAcknowledged : Boolean;
        attribute rootHandoffAcknowledged : Boolean;
        attribute resumedBodyAllowed : Boolean;
        attribute freshEntryIssued : Boolean;
        attribute oldAcquisitionSettled : Boolean;
    }
    requirement def IssueLaw {
        subject view : StableViewQualification;
        require constraint { not view.issueRequested or
            (view.writerSetClosed and view.ingressSerialized and view.readPinsProtected and
             view.rootsQualified and view.generationMatched and view.payloadEpochMatched) }
    }
    requirement def ReleaseLaw {
        subject view : StableViewQualification;
        require constraint { not view.releaseRequested or
            (view.pinsDrained and view.cleanupAcknowledged and view.rootHandoffAcknowledged) }
    }
    requirement def ResumeLaw {
        subject view : StableViewQualification;
        require constraint { not view.resumedBodyAllowed or
            (view.freshEntryIssued and view.oldAcquisitionSettled and view.rootsQualified) }
    }
'''
dxheader='''package GambitDarwinDevelopment {
    private import ScalarValues::*;
    private import GambitToolchain::*;
    /* Component history is not a current whole-build speedup witness. */
    part def DevelopmentQualification {
        attribute gainReported : Boolean;
        attribute matchedWholeRequest : Boolean;
        attribute semanticAndFailureParity : Boolean;
        attribute requiredEffectsPreserved : Boolean;
        attribute hostAndToolIdentityBound : Boolean;
        attribute noChangeAccepted : Boolean;
        attribute leafChangeAccepted : Boolean;
        attribute sharedMacroChangeAccepted : Boolean;
    }
    requirement def DevelopmentGainLaw {
        subject result : DevelopmentQualification;
        require constraint { not result.gainReported or
            (result.matchedWholeRequest and result.semanticAndFailureParity and
             result.requiredEffectsPreserved and result.hostAndToolIdentityBound and
             result.noChangeAccepted and result.leafChangeAccepted and result.sharedMacroChangeAccepted) }
    }
'''
fields=['fidelityId','diagramLabel','dependsOn','sourcePath','sourceRanges','concreteBoundary','encodingRule','cleanControl','failureMapping','reflectionDuty','benefitBoundary','leanSupport','quintSupport','researchStatus','runtimeContractRefs']
sv=[
('SV-SPEC','One acquisition owns roots and cleanup independently of read authority','S-CUT',str(base/'stable-view.sysml'),'1-35','Issue, release and resume requirements separate read permission from physical custody','Use domain/VM, acquisition, issuer generation, entry, writer and payload epochs; no integer wrap admission','Issuer ledger is mutable owned state outside continuation restoration; ROOT-HANDOFF remains shared','A stale capability denies reads but never silently frees its roots or partially owned output','Static requirements and ledger identities do not prove a native issuer or writer/GC refinement','Share one request lifetime ledger; avoid a second parser, root registry or runtime state machine','revokePreservesCustody; staleCleanupCannotClear','readable; noReleasedRootWithPins','conditional-contract',''),
('SV-ISSUE','Issue only after writer ingress, root coverage and acquisition settle','SV-SPEC; S-ALIASES','vendor/gambit/lib/_eval.scm','1396-1410;1437-1445;1489-1514','Fresh compilation context and shallow alist do not supply immutable captured values','Serialize all admitted writer ingress; bind complete alias/provider set; protect acquisition; then issue matching token','Actual roots and live temporaries must be covered; ledger equality is not a freeze proof','Unknown alias, nonzero RC coverage gap or racy acquisition refuses reuse','issuedReceiptReadable assumes IssuableView; actual gates, source loads and atomic publication remain open','Root/lease support is common modern C infrastructure; no language-specific saving','issuedReceiptReadable','issue; readable','conditional-kernel','ROOT-HANDOFF'),
('SV-REVOKE','Revoke before draining; writers wait for pins rather than stale flags','SV-ISSUE','models/build/IncrementalBuild.lean','1-1','Generation revocation invalidates token while retaining acquisition, roots and read pins','Invalidation and source-memory reclamation are separate cuts; pins must drain before admitted store','Same-owner callbacks must not wait on their own pin; end borrow before callback or refuse it','An epoch retry cannot legalize a C data race or a raw FFI bypass','Logical pin guards and identity proofs need actual memory-order/critical-section refinement','Do not add duplicate global hashing or coarse invalidation to make revocation easy','revokeRejectsOldReceipt; revokePreservesCustody; livePinBlocksWriter; returnPinKeepsCleanupDebt','revoke; returnPin; payloadWrite','conditional-kernel',''),
('SV-RESUME','Continuation restoration needs fresh entry authority and settled old custody','SV-REVOKE','vendor/gambit/lib/_thread.scm','4794-4817;4914-4988;5047-5080','dynamic-wind after/before runs on extent changes; same-extent return fast path can skip winding','Reentry creates fresh acquisition/entry/generation; old parameters, equal bytes or restored PC cannot revive token','Settle old acquisition before native borrow resumes; register fresh roots and check before every resumed source read','Before/after capture or exception can leave acquisition pending; same-extent mutation still needs read guard','Existing CONTROL-ORIGIN and ROOT-HANDOFF are dependencies; full multi-shot/exception refinement remains open','Keep Scheme winding semantics; introduce no C destructor-only continuation emulation','freshEntryRejectsOldReceipt; freshEntryHasDistinctToken; sameExtentMutationRejects','resume; rootGrant; readable','conditional-kernel','ROOT-HANDOFF; CONTROL-ORIGIN'),
('SV-ALIASES','Dynamic writers and FFI enter by capability or refuse the managed profile','SV-ISSUE','vendor/gambit/include/gambit.h.in','5500-5514','Native string store and generated Scheme mutation families bypass a script-line name census','Bind writer-set epoch to generated mutators, context/table aliases and FFI provider identity; unsafe stores cannot self-attest','Read-only provider, mediated write after borrow end, owned copy, or unqualified existing execution are distinct routes','Unknown eval/native provider denies reusable credential without banning legal Scheme mutation','unknownWriterRejectsRead is a ledger implication; actual provider closure and C race freedom remain open','Generated modern C mutation/FFI contract can be shared with runtime work; Zig inherits it','unknownWriterRejectsRead; livePinBlocksWriter','unknownWriter; payloadWrite','open-concrete-provider-closure',''),
('SV-CLEANUP','Cleanup ownership survives revocation, suspension and unknown close result','SV-REVOKE; SV-RESUME','vendor/gambit/gsc/_utils.scm','426-437;506-508','Compiler continuation-abort and ordinary restoration differ from arbitrary exception cleanup','Cleanup ticket binds acquisition rather than invalidated generation; track pending/ack/unknown; reject stale callback','After hook initiates governed release; errors or cancellation retain custodian until physical acknowledgement','No automatic free on stale read token; unknown close must not retry a reused fd or claim drain','Ledger ack idempotence proves no native double-close/free or eventual completion; RETIRE-WINDOW stays unresolved','One cleanup/outcome owner may replace global suffix bookkeeping only after all users migrate','cleanupDebtBlocksDelivery; staleCleanupCannotClear; cleanupAckIdempotent','cleanupAck; noReleasedRootWithPins','conditional-ledger-physical-cleanup-open','RETIRE-WINDOW'),
('SV-ROUNDTRIP','Lease validity must cover actual string reads and exceptional ports','SV-ISSUE; SV-CLEANUP; S-READ','vendor/gambit/lib/_io.scm','11428-11505;13083-13160;13828-13837','Writer scans length/characters; reader reconstructs through readtable and port; normal suffixes do not prove unwind cleanup','Bind one admitted content view to record prefix, C suffix and all other linker inputs; source release follows owned transfer','Guard resumes, allocation/GC reloads and callbacks; retain partial buffers/ports on exception until custody settles','Failed lexical/read/close outcome remains failure or pending, never successful cache observation','Actual character/port inverse, source-to-ledger simulation and full outcome/effect reflection remain open','Reuse Scheme reader/writer and ghost wire; no compulsory extra serialization pass','scriptFullObservationCongruence; cleanupDebtBlocksDelivery','readable; fullLinkEquivalent','open-actual-roundtrip-and-cleanup',''),
('SV-REFINE','Formal ledger preservation is not concrete read or continuation admission','SV-ROUNDTRIP; SV-RESUME; S-REFLECT','models/build/incremental_build.qnt','1-1','Issue/revoke/pin/cleanup/resume actions specify a guarded lifecycle; unsafe providers remain excluded','Prove each actual load, write, hook, error and handoff refines a legal step or explicit refused/pending outcome','Old eight modules and runtime contracts retained; no source/FFI/C memory model proof synthesized','Unknown acknowledgement, provider or multi-shot entry leaves qualification open','Lean implications are checked; QNT is typechecked only; actual refinement and liveness remain open','Conditional safety supports future work avoidance; no positive native speed claim','issuedReceiptReadable; freshEntryRejectsOldReceipt; scriptPropertyReflection','issue; revoke; returnPin; cleanupAck; resume; liveBorrowSafe','conditional-kernel-concrete-refinement-open','')]
dx=[
('DX-SPEC','macOS development is a first-class modern C contract','SV-REFINE; S-COST',str(base/'macos-development.sysml'),'1-22','Cold, no-change, leaf, shared-macro, failure/cancel and first-output behavior need separate acceptance','Use phase cost and invalidation identities rather than language substitution or more wrapper layers','Historical receipts bind tool/profile/source/sample; no current build is executed','A model count or cache HIT cannot replace whole-request and semantic acceptance','Modernization architecture and work inequalities are design-only; platform causality and speedup remain open','Require removed repeated work to exceed validation plus added support; preserve mandatory effects','positiveDevelopmentWork; coordinatorWithoutRemovedWork','positiveWork; oldWork; newWork','conditional-development-contract',''),
('DX-ATTRIBUTION','Do not conflate Scheme expansion, C provenance and first-output latency','DX-SPEC','../../patches/gerbil-v19-darwin/receipts/d802-darwin-gcc-frontend.json','1-49','Historical large object 15.45 to 10.37 seconds; 8915 to 97 MiB GCC allocation with exact object parity','Separate C macro diagnostic provenance from Scheme expansion and interface construction; first-output ceilings are not mandated sleeps','Darwin/GNU historical profile only; current code/toolchains and whole-build gains are unqualified','Reader-only, scheduling-only or universal five-second cooldown attribution is unsupported','Other receipts narrow startup/reader attribution; no platform-wide causal fraction proved','Retain low-risk configured provenance policy; structural lowering must remove repeated front-end work','positiveDevelopmentWork','parallelLatencyLowerBound','historical-component-evidence',''),
('DX-LOWERING','Move invariant ABI work out of per-module macro expansion','DX-ATTRIBUTION','../../patches/gerbil-v19-darwin/receipts/d861-gambit-header-pch-rejection.md','1-28','PCH was rejected by per-module GLOCOUNT; larger header caching alone did not qualify','Generate explicit per-module descriptors/constants and isolate invariant runtime ABI/helpers; keep Scheme tail/GC/frame semantics','C header/module boundary, debug diagnostics and target configuration need independent parity; no C++ required','Blind PCH, inline-everything, unqualified LLVM switch or lossy source maps cannot claim root fix','Frame/root ABI, runtime call cost and actual reduced preprocessing require future design/refinement and matched evidence','Can reduce repeated token work while adding helper calls/descriptors; quantify both and retire old macros by role','positiveDevelopmentWork','positiveWork','architecture-hypothesis-native-open',''),
('DX-REUSE','One validated native request must remove duplicate preparation','DX-SPEC; SV-ISSUE','../../patches/gerbil-v19-darwin/receipts/d1510-object-request-cost.md','1-45','Existing scheduler already submits objects; all-hit coordinator regressed 0.88 to 1.59 seconds pair means','Reuse scoped immutable tool/config/input snapshot without double preparation; phase/member invalidation and required effects stay bound','One-change member result is separate from stable HIT/cold; do not revive unchanged denied coordinator','All-hit status, extra workers or repeated tool hashing is not a gain; unknown inputs deny reuse','Actual snapshot issuer, transitive reads, mutation rejection and net request work remain unqualified','Modern C service should retire old preparation paths rather than wrap them; no duplicate C/Zig maintenance default','coordinatorWithoutRemovedWork; positiveDevelopmentWork','positiveWork','historical-regression-and-conditional-design',''),
('DX-ADMISSION','Developer gain requires bounded work, latency and memory across real scenarios','DX-REUSE; DX-LOWERING','../../patches/gerbil-v19-darwin/README.md','145-171;596-605','Historical one-change gain coexists with slower stable HIT and unqualified whole-consumer gates','Model DAG invalidation, CPU/memory budgets, critical path and failure custody; select existing process/context isolation until shared-VM SMP qualified','Cold/no-change/leaf/shared macro/tool change/failure/cancel plus semantic outputs and real first progress remain distinct','Do not add nested timings, turn a deadline observation into first-log time, or report component gains as package speedup','Existing ten-node to 74-action refinement and native performance still open; QNT work projection is not timing evidence','AOT construction programs may share code while contexts remain fresh; necessary instantiation and root work cannot vanish','positiveDevelopmentWork; untouchedPayloadPreservesView','positiveWork; parallelLatencyLowerBound','conditional-whole-request-admission','')]
lean=Path('models/build/IncrementalBuild.lean').read_text();qnt=Path('models/build/incremental_build.qnt').read_text()
ls=lean[:lean.index('-- Stable-view lifecycle ledger')].count('\n')+1;le=len(lean.splitlines())-1
qs=qnt[:qnt.index('module script_view_lifecycle')].count('\n')+1;qe=len(qnt.splitlines())
for fname,start,rows in [('stable-view.sysml',header,sv),('macos-development.sysml',dxheader,dx)]:
 text=start+'\n'
 for i,row in enumerate(rows):
  v=dict(zip(fields,row));v['obligationId']='BF-BUILD-BUDGET' if row[0].startswith('DX-') else 'BF-BUILD-CUT'
  if row[0]=='SV-REVOKE':v['sourceRanges']=f'{ls}-{le}'
  if row[0]=='SV-REFINE':v['sourceRanges']=f'{qs}-{qe}'
  text+='    part duty'+str(i)+' : GscFidelityObligation {\n'+''.join('        attribute :>> '+k+' = '+json.dumps(val)+';\n' for k,val in v.items())+'    }\n'
 (base/fname).write_text(text+'}\n')
p=Path('dev/modeling/models/sysml/assurance.sysml');s=p.read_text().replace('evidence/research/gsc-script-line-reflection/formal-results.json','evidence/research/script-view-lifecycle-darwin/formal-results.json')
names=re.findall(r'(?m)^theorem (\w+)',lean)[68:];s=s.replace('scriptPropertyReflection"','scriptPropertyReflection; '+'; '.join(names)+'"')
s=s.replace('sameResultIsInsufficient"','sameResultIsInsufficient; issue; readable; revoke; returnPin; cleanupAck; resume; rootGrant; unknownWriter; payloadWrite; liveBorrowSafe; noReleasedRootWithPins; positiveWork; oldWork; newWork; parallelLatencyLowerBound"')
s=s.replace('Script-line source census, shallow capture and last-truthy selection; conditional complete outcome/effect reflection; actual writer-reader and trace/cleanup refinement remain open','Stable-view issuer/revoke/pin/cleanup/reentry ledger and Darwin development-work accounting; actual writer, continuation, C memory, root, I/O and performance refinement remain open')
s=s.replace('S-ORIGIN through S-COST refine V-CONSUMER and D-BRIDGE; ROOT-HANDOFF reused; dynamic writer closure, actual text roundtrip, reentrant emitter/handler ownership and trace refinement remain open','SV-SPEC through SV-REFINE and DX-SPEC through DX-ADMISSION are owned toolchain models; shared ROOT-HANDOFF/CONTROL-ORIGIN/RETIRE-WINDOW remain unresolved; actual lifecycle, writer/FFI, readback and development-cost refinement open')
p.write_text(s);print('Added 8 lifecycle and 5 Darwin duties in two owned SysML files')
