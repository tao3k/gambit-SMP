module tcl_checked_refusal {
// Research abstraction; native issuers and C23 refinement remain open.
type State={scope:int,vmOpen:int,outerSticky:int,childSticky:int,childMerged:int,eventSeen:int,tclCode:int,diagnostic:int,done:int,delivered:int,origin:int,translated:int}
pure val initial:State={scope:0,vmOpen:1,outerSticky:0,childSticky:0,childMerged:0,eventSeen:0,tclCode:0,diagnostic:0,done:0,delivered:0,origin:0,translated:0}
var s:State
action init=s'=initial
val safe=all{s.scope>=0,
s.scope<=2,
s.vmOpen>=0,
s.vmOpen<=1,
s.outerSticky>=0,
s.outerSticky<=1,
s.childSticky>=0,
s.childSticky<=1,
s.childMerged>=0,
s.childMerged<=1,
s.eventSeen>=0,
s.eventSeen<=1,
s.tclCode>=0,
s.tclCode<=1,
s.diagnostic>=0,
s.diagnostic<=1,
s.done>=0,
s.done<=1,
s.delivered>=0,
s.delivered<=1,
s.origin>=0,
s.origin<=3,
s.translated>=0,
s.translated<=1,
(s.eventSeen==1) implies (s.outerSticky==1 or (s.scope==2 and s.childSticky==1)),
(s.outerSticky==1) implies (s.eventSeen==1),
(s.childSticky==1) implies (s.scope==2 and s.eventSeen==1),
(s.childMerged==1) implies (s.scope==2 and s.childSticky==1 and s.outerSticky==1),
(s.done==1) implies (s.scope==1),
(s.delivered==1) implies (s.scope==1 and s.done==1 and s.origin>=1),
(s.delivered==0) implies (s.origin==0 and s.translated==0),
(s.delivered==1 and s.eventSeen==1) implies (s.origin==1 and s.translated==0),
(s.translated==1) implies (s.vmOpen==1 and s.eventSeen==0 and s.origin==2),
(s.scope==0) implies (s.eventSeen==0 and s.outerSticky==0 and s.childSticky==0 and s.done==0)}
action beginEval=all{s.scope==0 and s.delivered==0,s'={...s,scope:1}}
action beginNested=all{s.scope==1 and s.done==0 and s.delivered==0,s'={...s,scope:2,childSticky:0,childMerged:0}}
action recordOuterRefusal=all{s.scope==1 and s.done==0 and s.delivered==0,s'={...s,outerSticky:1,eventSeen:1}}
action recordChildRefusal=all{s.scope==2 and s.delivered==0,s'={...s,childSticky:1,eventSeen:1}}
action publishOuterDiagnostic=all{s.scope==1 and s.outerSticky==1 and s.done==0 and s.delivered==0,s'={...s,tclCode:1,diagnostic:1}}
action publishChildDiagnostic=all{s.scope==2 and s.childSticky==1 and s.delivered==0,s'={...s,tclCode:1,diagnostic:1}}
action catchOrResetResult=all{s.tclCode==1 and s.done==0 and s.delivered==0,s'={...s,tclCode:0,diagnostic:0}}
action ordinaryTclError=all{s.scope>=1 and s.done==0 and s.delivered==0,s'={...s,tclCode:1}}
action mergeChildRefusal=all{s.scope==2 and s.childSticky==1 and s.delivered==0,s'={...s,outerSticky:1,childMerged:1}}
action popNested=all{s.scope==2 and s.delivered==0 and (s.childSticky==0 or s.childMerged==1),s'={...s,scope:1,childSticky:0,childMerged:0}}
action finishEval=all{s.scope==1 and s.done==0 and s.delivered==0,s'={...s,done:1}}
action deliverRefusal=all{s.scope==1 and s.done==1 and s.outerSticky==1 and s.delivered==0,s'={...s,delivered:1,origin:1}}
action deliverOrdinaryNativeError=all{s.scope==1 and s.done==1 and s.outerSticky==0 and s.tclCode==1 and s.delivered==0,s'={...s,delivered:1,origin:2}}
action translateOrdinaryError=all{s.scope==1 and s.done==1 and s.outerSticky==0 and s.tclCode==1 and s.vmOpen==1 and s.delivered==0,s'={...s,delivered:1,origin:2,translated:1}}
action deliverSuccess=all{s.scope==1 and s.done==1 and s.outerSticky==0 and s.tclCode==0 and s.delivered==0,s'={...s,delivered:1,origin:3}}
action closeVm=all{s.vmOpen==1 and s.delivered==0,s'={...s,vmOpen:0}}
action resumeVm=all{s.vmOpen==0 and s.delivered==0,s'={...s,vmOpen:1}}
action step=any{beginEval,beginNested,recordOuterRefusal,recordChildRefusal,publishOuterDiagnostic,publishChildDiagnostic,catchOrResetResult,ordinaryTclError,mergeChildRefusal,popNested,finishEval,deliverRefusal,deliverOrdinaryNativeError,translateOrdinaryError,deliverSuccess,closeVm,resumeVm,all{s'=s}}
run caughtRefusalTest=init.then(beginEval).then(closeVm).then(recordOuterRefusal).then(publishOuterDiagnostic).then(catchOrResetResult).then(finishEval).then(deliverRefusal).then(all{assert(safe and s.origin==1 and s.tclCode==0 and s.translated==0),s'=s})
run nestedRefusalTest=init.then(beginEval).then(beginNested).then(recordChildRefusal).then(publishChildDiagnostic).then(catchOrResetResult).then(mergeChildRefusal).then(popNested).then(finishEval).then(deliverRefusal).then(all{assert(safe and s.origin==1 and s.eventSeen==1),s'=s})
run oldFreeCallbackTest=init.then(beginEval).then(recordOuterRefusal).then(publishOuterDiagnostic).then(beginNested).then(recordChildRefusal).then(mergeChildRefusal).then(popNested).then(catchOrResetResult).then(finishEval).then(deliverRefusal).then(all{assert(safe and s.origin==1 and s.translated==0),s'=s})
run ordinaryErrorTest=init.then(beginEval).then(ordinaryTclError).then(finishEval).then(translateOrdinaryError).then(all{assert(safe and s.origin==2 and s.translated==1),s'=s})
run closedOrdinaryErrorTest=init.then(beginEval).then(closeVm).then(ordinaryTclError).then(finishEval).then(deliverOrdinaryNativeError).then(all{assert(safe and s.origin==2 and s.translated==0),s'=s})
run successTest=init.then(beginEval).then(finishEval).then(deliverSuccess).then(all{assert(safe and s.origin==3),s'=s})
}
