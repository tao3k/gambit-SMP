require 'json'
r='.cache/tasks/still-init-recovery'
names=File.read('models/gambit/lean/StillInitRecovery.lean').scan(/^theorem (\w+)/).flatten
File.write("#{r}/probe.lean", File.read('models/gambit/lean/StillInitRecovery.lean')+names.map{|n|"\n#check GambitSMP.StillInitRecovery.#{n}\n#print axioms GambitSMP.StillInitRecovery.#{n}\n"}.join)
out=<<~SYS
/* Modern C target specification. No satisfied instance or native admission. */
package GambitStillInitRecovery {
 private import ScalarValues::*;
 part def ProgressRecord { attribute committed : Integer; attribute physical : Integer;
  attribute writerIdle : Boolean; attribute inputStable : Boolean; attribute frozen : Boolean;
  attribute soleOwner : Boolean; attribute rootsRetained : Boolean; attribute transferAllowed : Boolean;
 }
 requirement def ProgressLaw { subject p : ProgressRecord;
  require constraint { p.committed>=0 and p.physical>=p.committed and
   (not p.writerIdle or p.physical==p.committed) and
   (not p.transferAllowed or (p.writerIdle and p.frozen and p.soleOwner and
    p.inputStable and p.rootsRetained)) }
 }
 part def ResultTransfer { attribute bodyComplete : Boolean; attribute serviceRoot : Boolean;
  attribute recipientRoot : Boolean; attribute receiptCommitted : Boolean; attribute exactIdentity : Boolean;
  attribute acceptanceCount : Integer; attribute sourceRelease : Boolean;
 }
 requirement def ResultLaw { subject t : ResultTransfer;
  require constraint { t.acceptanceCount>=0 and t.acceptanceCount<=1 and
   (not t.receiptCommitted or (t.bodyComplete and t.recipientRoot and t.exactIdentity and t.acceptanceCount==1)) and
   (not t.sourceRelease or (t.receiptCommitted and t.recipientRoot)) }
 }
 part def UnknownCustody { attribute unresolved : Boolean; attribute possibleBackingCharged : Boolean;
  attribute originalOperationRetained : Boolean; attribute initializationAuthorityRetained : Boolean;
  attribute mayReplay : Boolean; attribute mayRefund : Boolean;
 }
 requirement def UnknownLaw { subject u : UnknownCustody;
  require constraint { not u.unresolved or (u.possibleBackingCharged and
   u.originalOperationRetained and u.initializationAuthorityRetained and not u.mayReplay and not u.mayRefund) }
 }
SYS
needs=[
 ['history','IR-H','interleaving','models/gambit/still_init_recovery.qnt','still_init_recovery:30-named-histories;safe;seed=17;100x100','One operation, three fields, two initializer owners and one receiver slot; in-flight write, partial and complete lost replies; no native progress or liveness proof'],
 ['induction','IR-I','induction','models/gambit/lean/StillInitRecovery.lean','GambitSMP.StillInitRecovery:'+names.join(';'),'16 exact conditional statements, including progress-kernel step/trace preservation and result-admission idempotence; not complete QNT induction or C refinement'],
 ['progress','IR-PROGRESS','source-refinement','models/gambit/lean/StillInitRecovery.lean','IR-PROGRESS:actual-source-refinement','Actual byte/field/decoder cursor, immutable input, busy write and generation-bound frozen handoff; unknown acknowledgement cannot create a second initializer'],
 ['roots','IR-ROOT','source-refinement','models/gambit/lean/StillInitRecovery.lean','IR-ROOT:actual-source-refinement','Complete body and result root publication; updateable input/result roots and remembered coverage; target enrollment before sender retirement, with reader drain'],
 ['delivery','IR-DELIVERY','source-refinement','models/gambit/lean/StillInitRecovery.lean','IR-DELIVERY:actual-source-refinement','Atomic recipient root installation plus same-operation acceptance receipt; no duplicate OS read, initializer or continuation delivery; multi-shot calls use distinct activation identity; ingress fence before receipt retirement'],
 ['abort','IR-ABORT','source-refinement','models/gambit/lean/StillInitRecovery.lean','IR-ABORT:actual-source-refinement','Typed pointer versus atomic payload, stopped writer, cancellation arbitration and full unknown backing; no unproved unlink, timeout refund or external-effect exactly-once claim']]
needs.each do |name,id,kind,path,scope,premise|
 out+=" part #{name} : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;\n"
 {obligationId:id,kind:kind,subjectPath:path,subjectScope:scope,premise:premise}.each{|a,v|out+=" attribute :>> #{a}=#{v.to_json};\n"};out+=" }\n"
end
edges=[]
[['progress',['history','induction','GambitStillInitSafepoint::admission','GambitPromotionIntervalHandoff::memory','GambitHostRootsRefinement::bindingState']],
 ['roots',['history','induction','progress','GambitHostRootsRefinement::rc','GambitHostRootsRefinement::marker','GambitGenerationalBarrier::writers','GambitGenerationalBarrier::scanCut']],
 ['delivery',['history','induction','roots','GambitHostRootsRefinement::exitState','GambitRuntimeAssurance::control.source']],
 ['abort',['history','induction','roots','GambitRetainedRcScan::lifetime','GambitRuntimeAssurance::release.source']]].each{|d,ps|ps.each{|p|edges<<[d,p]}}
edges += [['GambitStructurePollStillEnvelope::still','progress'],['GambitStructurePollStillEnvelope::still','roots'],['GambitStructurePollStillEnvelope::still','delivery'],['GambitStructurePollStillEnvelope::peak','abort']]
edges.each_with_index{|(d,p),i|out+=" part dependency#{i} : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=#{d}; ref part :>> prerequisite=#{p}; }\n"}
needs[2..].each do |name,id,_,_,_,premise|
 out+=" part #{name}Route : GambitHostRootsRefinement::Route { ref part :>> need=#{name};\n"
 {sourceAnchors:'lib/_kernel.scm:43-112;lib/_kernel.c:23864-23904;lib/mem.c:1487-1498,1677-1708,1730-1818,4016-4040,4170-4180;lib/c_intf.c:4335-4346,5413-5500,5678-5689,5732-5803;lib/os_io.c:11412-11428;lib/os_base.c:1735-1747;include/gambit.h.in:10033-10066,10269-10272',patchAnchors:'No new runtime patch; predecessor marker/root recipe is not partial-initializer or result-receipt implementation',projection:premise,failureCustodian:'Original operation record and unique generation-bound initializer; recipient slot takes result root only with atomic acceptance receipt; unresolved outcomes retain full backing and roots',status:'selected-source-endpoints-known-native-refinement-open'}.each{|a,v|out+=" attribute :>> #{a}=#{v.to_json};\n"};out+=" }\n"
end
callers=[
 ['structure','_kernel.scm:43-112;_kernel.c:23864-23904','Allocate/link/refcount decrement -> fill -> RESULT/R3 -> R1/return','Current uninterrupted C path has no lost reply or progress journal','Preserve one-pass default; typed progress cuts only when service migration requires them'],
 ['native-vector','mem.c:1743-1818','make_pair/make_vector allocate -> write fields -> return refcount1','Inputs explicitly must not be movable; reference count is not field validity','Exact input leases and separate ready/result-root endpoint; do not silently broaden raw FFI contract'],
 ['utf8-converter','c_intf.c:5413-5500,5678-5689','Count UTF8 source -> allocate -> decode/write -> *obj/status; error releases partial result','Field index alone cannot restore decoder/source cursor; input can outlive native borrow','Stable byte image or explicit source lease; index+byte offset/decoder state; atomic payload failure separate'],
 ['string-list','c_intf.c:5732-5803','Convert str -> make_pair(str,lst) -> release str/lst -> next item -> *obj','Partial list, pending child and pair allocation span multiple ownership transfers','Parent/child operation identity and root receipts; body-only model does not prove whole list'],
 ['directory','os_io.c:11412-11428','device_directory_read -> borrowed name -> STRING_to_SCMOBJ -> release/return','Retrying wrapper repeats effectful directory advancement; backing name lease is not proven','Identity begins before I/O; completed constructor query never reruns directory read; caller/effect closure open'],
 ['error-text','os_base.c:1735-1747','Stack/native error buffer -> NONNULLSTRING_to_SCMOBJ -> release -> return','Async continuation cannot retain a dead stack buffer or rootless return value','Copy/pin source before yielding; retain result root through caller acceptance'],
 ['sfun','gambit.h.in:10033-10066,10269-10272;setup.c:3275-3413','Generated conversion scope -> Scheme call/result -> release/invalidate/propagate','Nested escape, raw output pointer and continuation reentry are not transactional delivery','Activation-specific recipient slot and own cleanup; no suppression of intentional multi-shot Scheme invocation'],
 ['collector','mem.c:4016-4040,4170-4180,4222-4245','Atomic payload skips body tracing; ordinary still pointer object scans all fields','Atomic string error cleanup cannot justify partial pointer-object admission','Typed abort, root drain and same GC gate; unresolved partial pointer body still blocks participation']]
out+=" part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }\n"
callers.each_with_index{|row,i|out+=" part caller#{i} : CallerRow {\n"; %w[callerId sourceAnchors actualChain hazard replacement].zip(row).each{|a,v|out+=" attribute :>> #{a}=#{v.to_json};\n"};out+=" }\n"}
costs=[
 ['normal initialization','No mandatory fill/allocation removed versus current synchronous C','a payload writes remain; no required sentinel pass','Progress record and optional checkpoint ceil(a/q) publications','q is an admitted nonreentrant batch; per-field publication is not required by default'],
 ['partial resume','Never rewrite committed prefix or replay an ambiguous in-flight batch','After known prefix p, remaining writes a-p; unsafe retry is not a legitimate performance baseline','Freeze/owner-generation handoff and complete cursor/input/root snapshot','In-flight or dead-owner ambiguity retains responsibility; no takeover from stale progress'],
 ['input stability','Share one qualified input image across readback/resume','Zero byte-copy only with proven borrow; otherwise E input bytes plus copy/scan work','Input pin or immutable snapshot and lifetime/identity metadata','A UTF8 field count does not reconstruct input byte position or guarantee immutable native storage'],
 ['result handoff','Reuse the same completed object, not reconstruct it on lost response','One accepted recipient slot per operation; overlapping roots refer to one backing object','Source/recipient root overlap plus atomic acceptance receipt','No extra object copy needed; direct C already returns one object, so no automatic net saving'],
 ['effectful callers','Do not repeat directory advancement or invoke Scheme merely to query a result','Readback performs zero initializer writes and zero delivery/OS effects','Operation identity before effect; recipient activation identity and effect ledger','Exactly-once external callbacks/crash recovery not established; unmediated raw consumers refused'],
 ['unknown retention','Same-ID queries do not allocate another result','One possible block B retained, not k blocks for k queries','Outstanding records, full B, input image E and root scan sum R_i','No timeout reclamation; permanently unknown owner may prevent GC progress'],
 ['receipt retirement','Prevent stale retry/ABA from reinstalling retired result','O(L+T) records for live operations L and retained dedup entries T','Ingress fence, retry/reader drain and generation nonreuse','No native bound on L or T and no timeout-only tombstone expiry'],
 ['whole-round peak','Eliminate only actual duplicate backing introduced by an otherwise necessary service design','Current selected still request8a+63 remains; saved payload allocation count0','B+E+root/init/receipt bytes across all overlapping phases','Qg lowers max only if actual omitted acquisition exceeds added costs at every dominant phase; no native peak saving measured']]
out+=" part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }\n"
costs.each_with_index{|row,i|out+=" part cost#{i} : CostRow {\n"; %w[capability removedWork bound addedCost condition].zip(row).each{|a,v|out+=" attribute :>> #{a}=#{v.to_json};\n"};out+=" }\n"}
nodes=[['input','Stable input + activation roots + operation identity'],['write','Sole initializer; reserved write may be in flight'],['cut','Committed cursor; writer idle; exact physical prefix'],['freeze','Frozen owner transfer; authoritative generation commit'],['unknown','Unknown: query same operation; no replay/refund'],['complete','Body complete + service result root + remembered coverage'],['offer','Offer result to exact recipient activation'],['admit','Atomic receiver root + acceptance receipt; duplicate is read-only'],['cleanup','Retire sender roots after receipt and reader drain'],['peak','Full backing + input + root/init/receipt phase peak']]
viewedges=[[0,1,'allocate once'],[1,2,'publish progress only after writes'],[2,1,'resume remaining suffix'],[2,3,'freeze at idle cut'],[3,1,'new generation; old owner revoked'],[1,4,'lost reply; original owner may continue'],[5,4,'complete but response unknown'],[4,2,'authoritative idle readback'],[4,5,'validate completed/rooted identity'],[2,5,'all fields done; publish result root'],[5,6,'no reconstruction'],[6,7,'linearized accept or reject'],[7,8,'query receipt, then release'],[7,7,'same identity returns prior receipt'],[4,9,'retain full possible block'],[8,9,'receipt retirement adds lifetime'],[0,9,'input lease/snapshot bytes']]
out+=" part def ViewNode { attribute nodeId : String; attribute labelText : String; }\n"
nodes.each_with_index{|(id,label),i|out+=" part node#{i} : ViewNode { attribute :>> nodeId=#{id.to_json}; attribute :>> labelText=#{label.to_json}; }\n"}
out+=" part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }\n"
viewedges.each_with_index{|(a,b,label),i|out+=" part edge#{i} : ViewEdge { ref part :>> producer=node#{a}; ref part :>> consumer=node#{b}; attribute :>> labelText=#{label.to_json}; }\n"}
out+="}\n";File.write('dev/architecture/runtime/gc/models/sysml/still-init-recovery.sysml',out)
File.write("#{r}/shape.json",{newNeeds:needs.size,newEdges:edges.size,callers:callers.size,costs:costs.size,nodes:nodes.size,edges:viewedges.size,leanNames:names}.to_json)
