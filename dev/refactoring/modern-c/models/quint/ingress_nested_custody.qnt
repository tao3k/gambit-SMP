module ingress_nested_custody {
 type State={parent:bool,child:bool,closed:bool,deletion:bool,root:bool,header:bool,unknown:bool,destructor:bool,code:bool}
 pure val initial:State={parent:true,child:false,closed:false,deletion:false,root:true,header:true,unknown:false,destructor:false,code:true}
 var s:State
 action init=s'=initial
 val safe=all{(s.parent or s.child or s.unknown) implies (s.root and s.header and s.code),s.root implies (s.header and s.code),s.destructor implies s.code}
 action enterChild=all{s.parent,not(s.child),not(s.closed),s.root,s.header,s.code,s'={...s,child:true}}
 action leaveChild=all{s.child,s'={...s,child:false}}
 action leaveParent=all{s.parent,s'={...s,parent:false}}
 action unknownExit=all{s.parent,s'={...s,parent:false,unknown:true}}
 // Qualified completion receipt; never an inference from timeout or command deletion.
 action settleUnknown=all{s.unknown,s'={...s,unknown:false}}
 action requestDelete=all{s'={...s,closed:true,deletion:true}}
 action createResult=all{s.parent,s.code,s'={...s,destructor:true}}
 action releaseResult=all{s'={...s,destructor:false}}
 action dropRoot=all{s.closed,s.deletion,not(s.parent),not(s.child),not(s.unknown),s'={...s,root:false}}
 action freeHeader=all{not(s.root),not(s.parent),not(s.child),not(s.unknown),s'={...s,header:false}}
 action freeCode=all{s.closed,not(s.root),not(s.parent),not(s.child),not(s.unknown),not(s.destructor),s'={...s,code:false}}
 action step=any{enterChild,leaveChild,leaveParent,unknownExit,settleUnknown,requestDelete,createResult,releaseResult,dropRoot,freeHeader,freeCode,all{s'=s}}
 run nestedDeletionTest=init.then(enterChild).then(requestDelete).then(leaveParent).then(all{assert(safe and s.root and s.header and s.child),s'=s}).then(leaveChild).then(dropRoot).then(freeHeader).then(freeCode).then(all{assert(safe),s'=s})
 run unknownRetainsRootTest=init.then(requestDelete).then(unknownExit).then(all{assert(safe and s.unknown and s.root and s.header),s'=s}).then(settleUnknown).then(dropRoot).then(freeHeader).then(freeCode).then(all{assert(safe),s'=s})
 run resultIndependentOfRcTest=init.then(createResult).then(requestDelete).then(leaveParent).then(dropRoot).then(freeHeader).then(all{assert(safe and s.destructor and s.code and not(s.header)),s'=s}).then(releaseResult).then(freeCode).then(all{assert(safe),s'=s})
 run nestedFreeControlTest=init.then(enterChild).then(requestDelete).then(leaveParent).then(all{s'={...s,root:false,header:false}}).then(all{assert(not(safe)),s'=s})
 run unknownFreeControlTest=init.then(unknownExit).then(all{s'={...s,root:false,header:false}}).then(all{assert(not(safe)),s'=s})
 run destructorUnloadControlTest=init.then(createResult).then(leaveParent).then(requestDelete).then(all{s'={...s,code:false}}).then(all{assert(not(safe)),s'=s})
}
