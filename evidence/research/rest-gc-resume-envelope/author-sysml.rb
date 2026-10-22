# Authoring only. Emitted SysML is maintained authority; no runtime generator.
pkg='GambitRestGcResumeEnvelope'
q='models/gambit/rest_gc_resume_envelope.qnt'
l='models/gambit/lean/RestGcResumeEnvelope.lean'
needs=[
 ['history','RG-H','interleaving',q,'rest_gc_resume_envelope:16-named-histories;safe;seed=17;100x80','One p2 a5 history: completion before framed GC, known resume, carrier lifetime and ghost historical peak; abstract destination, no source simulation'],
 ['induction','RG-I','induction',l,'GambitSMP.RestGcResumeEnvelope:suffixBound;noDoubleCount;crossingAndCompletion;structureCarrier;boundedStructureCarrier;genericJointBound;completionFits;zeroFirstHeapSpan;stackPrefix;countedOnce;phaseCredit;unchangedPeak;retainedPeak','Conditional Nat extent and phase inequalities; no pointer provenance, generated-code identity or whole-step induction'],
 ['completion','RG-COMPLETE','source-refinement',l,'RG-COMPLETE:actual-source-refinement','Exact p/a/k/m and no-handle layout, entry guard plus post-crossing completion, no collecting before carrier/root publication; physical contiguity and all admitted callers'],
 ['resume','RG-RESUME','source-refinement',l,'RG-RESUME:actual-source-refinement','GC/current binding -> POP_ARGS2 -> push p -> na=-1 -> actual structure entry first POLL; heap0 stack2 local envelope, slow poll invalidates; following frame8 and dynamic structure allocation separately admitted'],
 ['lifetime','RG-LIFETIME','source-refinement',l,'RG-LIFETIME:actual-source-refinement','Last root/alias/continuation and reader drain precede actual region reuse/release; live rest pairs and detached carrier are not immediately free; overflow retry and unknown hold roots'],
 ['peak','RG-PEAK','source-refinement',l,'RG-PEAK:actual-source-refinement','Actual completion/copy/restore/frame-growth/still/failure phase maxima and matched existing reuse baseline; Qg omits real fresh backing, no aggregate reserve or late refund credit']]
f=File.open('dev/architecture/runtime/gc/models/sysml/rest-gc-resume-envelope.sysml','w')
f.puts <<~SYS
/* Mandatory modern generated C. Target contracts, no satisfied runtime instances. */
package #{pkg} {
 private import ScalarValues::*;
 part def Construction { attribute actuals : Integer; attribute formals : Integer;
  attribute built : Integer; attribute remaining : Integer; attribute cursor : Integer;
  attribute physicalEnd : Integer; attribute noHandles : Boolean;
  attribute completionMayRun : Boolean; attribute callerAndLayoutMatched : Boolean;
 }
 requirement def CompletionLaw { subject c : Construction;
  require constraint { c.actuals>=0 and c.formals>=1 and c.built>=0 and c.remaining>=0 and
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
SYS
needs.each do |name,id,kind,path,scope,premise|
 f.puts " part #{name} : GambitAssuranceRouting::ModelNeed { ref part :>> owner=GambitRuntimeAssurance::work.component;"
 {'obligationId'=>id,'kind'=>kind,'subjectPath'=>path,'subjectScope'=>scope,'premise'=>premise}.each{|k,v|f.puts " attribute :>> #{k}=#{v.dump};"};f.puts ' }'
end
deps=[]
{'completion'=>['history','induction','GambitRuntimeAssurance::work.source'],
 'resume'=>['history','induction','completion','GambitHostRootsRefinement::bindingState','GambitRuntimeAssurance::control.source'],
 'lifetime'=>['history','induction','completion','GambitPromotionIntervalHandoff::readers','GambitHostRootsRefinement::bindingState'],
 'peak'=>['history','induction','completion','resume','lifetime','GambitPromotionIntervalHandoff::memory'],
 'GambitGuaranteedTailPlacement::checks'=>['completion'],
 'GambitGuaranteedTailPlacement::restore'=>['resume'],
 'GambitGuaranteedTailPlacement::peak'=>['peak']}.each{|a,bs|bs.each{|b|deps<<[a,b]}}
raise unless deps.length==22
deps.each_with_index{|(a,b),i| f.puts " part dependency#{i} : GambitAssuranceRouting::NeedDependency { ref part :>> dependent=#{a}; ref part :>> prerequisite=#{b}; }"}
routes={
 'completion'=>'lib/_kernel.scm:506-596;include/gambit.h.in:3118-3167,5325;lib/mem.h:63-78;lib/mem.c:7425-7500',
 'resume'=>'lib/_kernel.scm:1992-2049,4984-4994;lib/_kernel.c:23950-23986;include/gambit.h.in:7004-7026,8176-8179,8510-8536;lib/mem.c:7041-7087',
 'lifetime'=>'lib/_kernel.scm:1992-2049;lib/mem.c:891-1083,3426-3439,4380-4453,4966;lib/_kernel.scm:43-112',
 'peak'=>'lib/mem.c:540-598,891-1083,1556-1708,6316-6488,7036-7087;lib/mem.h:63-78;lib/_kernel.c:23950-23986'}
routes.each do |n,anchors|
 f.puts " part #{n}Route : GambitHostRootsRefinement::Route { ref part :>> need=#{n};"
 {'sourceAnchors'=>anchors,'patchAnchors'=>'Existing cumulative patch unchanged; generated kernel snapshot is source evidence, not a freshly built binary',
 'projection'=>needs.find{|a|a[0]==n}[5], 'failureCustodian'=>'Context holds unframed constructor and completion grant; framed roots/epoch ledger retain carrier, both spaces and pending result until known commit and last-alias drain',
 'status'=>'source-chain-located-refinement-and-native-capacity-open'}.each{|k,v|f.puts " attribute :>> #{k}=#{v.dump};"};f.puts ' }'
end
f.puts ' part def CallerRow { attribute callerId : String; attribute sourceAnchors : String; attribute actualChain : String; attribute hazard : String; attribute replacement : String; }'
callers=[
 ['rest-entry','_kernel.c:23950-23956;gambit.h.in:8176-8179','structure one required plus rest -> p2 handler; na=-1 bypass on resume','Calling GET_REST again with nonnegative count would rebuild list','PointId binds actual/formal shape and negative ready-arguments sentinel'],
 ['completion','_kernel.scm:506-596;gambit.h.in:3150-3167','one pair then hp check -> heap_limit may continue -> remaining pairs and vector before GC','B3 alone cannot pay C=3m+p+1; hp/global reserve not a contiguous grant','Noncollecting completion grant issued before exposing unframed arguments'],
 ['framed-gc','_kernel.scm:1992-2000,2034-2049;mem.c:6938-7087','proc and carrier as Scheme args -> saved RA/registers -> GC -> restored binding','overflow handler can return/retry, capture or nonlocal exit','Durable FrameSpec/root receipt and failure delivery reserve'],
 ['first-resume','_kernel.scm:2006-2032;_kernel.c:23950-23957','POP_ARGS2, push vector2, pop regs, na=-1, FIX1, POLL1','heap0 is not stack0; poll slow path may move stack/heap','Temporary stack allowance2 plus current caller frame; fresh assurance after slow path'],
 ['later-body','_kernel.c:23958-23986;_kernel.scm:43-112,4984-4994','8-word recursive frame per field -> POLL -> make-structure n=a','8r logical stack growth can GC/copy; a+1>255 selects still allocator','Separate FrameSpec growth, small-object B=a+1 or rooted still/failure plan'],
 ['release','mem.c:989,1065-1083,1556-1708,4406-4448;_kernel.scm:1992-2032','cursor bump, copying/semispace reuse, msection shrink/free; still cleanup','Rest list remains language value; carrier root detach not physical free','Last alias/root/readers plus known region accounting before reuse or free']]
callers.each_with_index{|row,i|f.puts " part caller#{i} : CallerRow {"; %w[callerId sourceAnchors actualChain hazard replacement].zip(row){|k,v|f.puts " attribute :>> #{k}=#{v.dump};"};f.puts ' }'}
f.puts ' part def CostRow { attribute capability : String; attribute removedWork : String; attribute bound : String; attribute addedCost : String; attribute condition : String; }'
rows=[
 ['completion envelope','Replace unqualified worst-case requests with caller-bound exact suffix','p2: C=3m+3, Bcross<=3; Bcross+C<=3a<=24576 words (196608 bytes at WS8)','Preissued contiguous completion space, argument count/layout identity, checked arithmetic','No shrinking current global204808-word policy by subtracting bounds; multi-context physical/source obligations open'],
 ['general ordinary rest','Avoid independent-max double counting','k+m=r=a-p+1; total=3r+p+1=3a-2p+4<=24578 words, no handles','Generic p<=1024 a<=8192 admission and representation variants','Bound is carrier construction only, not transitive GC live graph, stack, emergency or root metadata'],
 ['first resumed interval','No heap allocation between restore helper and structure POLL1','Heap R0=0; temporary push<=2 slots; next recursive interval adds8 frame words','Existing caller/frame stack grant and fresh assurance on slow poll','Do not grant zero heap globally: current post-GC fudge still exists and later dynamic allocation needs its own plan'],
 ['recursive continuation','Make hidden stack growth explicit and preserve repeated/multi-shot capture','8r<=65528 logical stack words (524224 bytes at WS8), excluding base/control and copied heap frames','Root descriptors, possible frame-to-heap copy, every POLL rebind and alias retention','Logical stack growth not a contiguous native grant or all-round peak bound'],
 ['next structure allocation','Separate small bump demand from still allocation','n=a; small object a+1<=255 words if a<=254; a>=255 uses still allocation','Still header/alignment/allocator, rooted type, possible GC and failure cleanup','Not included in first interval; allocator refcount_dec is not immediate object free'],
 ['guaranteed tail Qg','Omit an actually separate future resume acquisition before overlap','0<=Qg<=min(usable compatible tail,Ractual); phase c<=b-Qg+extra','Copy fence, real backing provenance, transfer ledger, roots and reader pins','Strict whole gain iff every phase below matched baseline peak; existing PSTATE reuse already credited; zero first-span demand gives no credit itself'],
 ['late carrier death/refund','Only reduce occupancy after actual region reuse/free','Late Qo cannot decrease max already observed; carrier3 words no immediate3-word refund','Complete continuation/FFI alias and reader closure, delayed failure roots','Rest pairs remain arguments; lowering a counter or detaching POP_ARGS2 is not releasing an allocation'],
 ['failure and unknown','Avoid unsafe GC at incomplete frames and duplicated grant spending','Before published/copy state only known private reservations refundable; after forwarding retain both spaces','Bounded pending/completion/failure grants and backpressure','No retry/newID/refund while outcome unknown; no OOM, liveness, RSS or native performance claim']]
rows.each_with_index{|row,i|f.puts " part cost#{i} : CostRow {";%w[capability removedWork bound addedCost condition].zip(row){|k,v|f.puts " attribute :>> #{k}=#{v.dump};"};f.puts ' }'}
f.puts ' part def ViewNode { attribute nodeId : String; attribute labelText : String; }'
nodes=[['entry','structure entry: a actuals, p2'],['guard','Pair allocation then guard Bcross'],['complete','Completion grant: 3m+3, no GC'],['roots','Carrier and proc: complete rooted frames'],['collect','GC copy + future tail fence'],['commit','Known ownership / current grant'],['resume','Restore2, na=-1, heap0 -> POLL1'],['later','Frame8 per field, then small/still allocation'],['hold','Failure / unknown: retain roots and spaces'],['release','Last alias + reader drain -> region reuse/free'],['peak','All-phase physical maximum; Qg vs late Qo']]
nodes.each_with_index{|(id,label),i| f.puts " part node#{i} : ViewNode { attribute :>> nodeId=#{id.dump}; attribute :>> labelText=#{label.dump}; }"}
f.puts ' part def ViewEdge { ref part producer : ViewNode; ref part consumer : ViewNode; attribute labelText : String; }'
edges=[[0,1,'admitted shape'],[1,2,'heap_limit requests GC'],[2,3,'finish unframed work'],[3,4,'GC admissible'],[4,5,'copy ready'],[5,6,'readback known'],[6,7,'new PointId / poll rebind'],[4,8,'forwarded failure'],[5,8,'reply unknown'],[8,5,'resolve same operation'],[6,9,'root detachment insufficient'],[7,9,'semantic death + leases'],[4,10,'preflight omission'],[9,10,'late refund preserves history']]
edges.each_with_index{|(a,b,label),i| f.puts " part edge#{i} : ViewEdge { ref part :>> producer=node#{a}; ref part :>> consumer=node#{b}; attribute :>> labelText=#{label.dump}; }"}
f.puts '}';f.close
