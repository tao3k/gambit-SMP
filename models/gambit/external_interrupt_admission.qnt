// Admission and ownership specification, not a native external-C adapter.
module external_interrupt_admission {
 type State={scenario:int,policy:int,ownerCredential:bool,tls:bool,vmLive:bool,
 vmPin:bool,instancePin:bool,instance:int,expected:int,open:bool,phase:int,
 requestKind:int,gcSafe:bool,rooted:bool,unsafeScmAccess:bool,nodeOwner:int,link:int,accepted:bool,status:int,enqueues:int,executions:int,
 faultSaved:bool,unsafeDereference:bool,wrongInstance:bool}
 var s:State
 pure def initial(sc:int,p:int):State={scenario:sc,policy:p,
 ownerCredential:sc!=1,tls:true,vmLive:true,vmPin:false,instancePin:false,
 instance:if(sc==2) 2 else 1,expected:1,open:sc!=3,phase:0,requestKind:if(sc>=5) 1 else 0,gcSafe:sc!=5,rooted:sc!=5,unsafeScmAccess:false,nodeOwner:0,
 link:7,accepted:false,status:0,enqueues:0,executions:0,faultSaved:false,
 unsafeDereference:false,wrongInstance:false}
 action initLive=s'=initial(0,0)
 action initTlsRefusal=s'=initial(1,0)
 action initStaleRefusal=s'=initial(2,0)
 action initClosingRefusal=s'=initial(3,0)
 action initAcceptedWakeFault=s'=initial(4,0)
 action initTlsAsOwner=s'=initial(1,1)
 action initCurrentEpochInsteadOfExpected=s'=initial(2,2)
 action initTouchBeforeReject=s'=initial(3,3)
 action initRejectAfterCommit=s'=initial(4,4)
 action initRetryAfterCommit=s'=initial(4,5)
 action initDropOuterPin=s'=initial(0,6)
 action initForeignOwner=s'={...initial(0,0),tls:false}
 action initScmRefusal=s'=initial(5,0)
 action initScmRooted=s'=initial(6,0)
 action initUnrootedScmCommit=s'=initial(5,7)
 // Credential identifies the valid owner from which storage can be pinned.
 // A TLS address/processor number is not this credential.
 action enterOwner=all{s.phase==0,s.ownerCredential or (s.policy==1 and s.tls),
 s'={...s,phase:1,vmPin:true,
 unsafeDereference:not(s.ownerCredential)}}
 action refuseOwner=all{s.phase==0,not(s.ownerCredential),s.policy!=1,
 s'={...s,phase:5,status:1}}
 action borrowInstance=all{s.phase==1,s.vmPin,s.vmLive,
 s'={...s,phase:2,instancePin:true}}
 action releaseOuterTooEarly=all{s.policy==6,s.phase==2,s.vmPin,
 s'={...s,vmPin:false,vmLive:false}}
 action rejectBeforeCommit=all{s.phase==2,
 not(s.open) or (s.instance!=s.expected and s.policy!=2) or
 (s.requestKind==1 and (not(s.gcSafe) or not(s.rooted)) and s.policy!=7),
 s'={...s,phase:4,status:1,
 link:if(s.policy==3) 0 else s.link}}
 action commitQueue=all{s.phase==2,s.open,
 s.instance==s.expected or s.policy==2,
 s.requestKind==0 or (s.gcSafe and s.rooted) or s.policy==7,
 s'={...s,phase:3,nodeOwner:1,accepted:true,link:0,enqueues:s.enqueues+1,
 wrongInstance:s.instance!=s.expected,
 unsafeScmAccess:s.requestKind==1 and (not(s.gcSafe) or not(s.rooted))}}
 // Wake failure is AFTER acceptance. It does not return node ownership.
 action notifyResult=all{s.phase==3,
 s'={...s,phase:4,status:if(s.scenario==4) (if(s.policy==4) 1 else 3) else 2,
 nodeOwner:if(s.scenario==4 and s.policy==4) 0 else s.nodeOwner,
 faultSaved:s.scenario==4}}
 action repeatAccepted=all{s.policy==5,s.phase>=4,s.accepted,s.status==3,
 s.enqueues==1,s'={...s,enqueues:2}}
 action releaseBorrow=all{s.phase==4,
 s'={...s,phase:5,instancePin:false,vmPin:false}}
 action service=all{s.phase>=4,s.nodeOwner==1,s.scenario!=4,
 s'={...s,nodeOwner:2,executions:s.executions+1}}
 val retained=s.phase==5 and s.accepted and s.status==3 and s.nodeOwner==1
 and s.faultSaved
 val done=s.phase==5 and (s.status==1 or s.nodeOwner==2)
 val safe=all{not(s.unsafeScmAccess),not(s.unsafeDereference),not(s.wrongInstance),
 not(s.instancePin) or (s.vmPin and s.vmLive),s.enqueues<=1,s.executions<=1,
 not(s.accepted) or s.nodeOwner!=0,
 s.status!=1 or (not(s.accepted) and s.link==7 and s.nodeOwner==0),
 s.status!=3 or (s.accepted and s.faultSaved and s.nodeOwner==1)}
 action step=any{enterOwner,refuseOwner,borrowInstance,releaseOuterTooEarly,
 rejectBeforeCommit,commitQueue,notifyResult,repeatAccepted,releaseBorrow,
 service,all{done or retained,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
