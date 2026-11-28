module ffi_native_owner_handoff {
  // A's native stack never migrates. B has an independent local frame.
  // A semantic callback lineage and a rooted completion bridge connect them.
  type S={mode:int,bug:int,a:int,b:int,closing:bool,phase:int,calls:int,
    loanA:bool,loanB:bool,ctlA:bool,ctlB:bool,frameA:bool,frameB:bool,
    runA:bool,markerA:bool,bridge:bool,msgPin:bool,resourcePin:bool,
    rootA:bool,rootB:bool,rootM:bool,senderDomain:bool,ownerBAlive:bool,msgRootOwner:int,cleanupOwner:int,vA:int,vB:int,vM:int,gc:int,
    msg:int,msgVm:int,msgOwner:int,msgNonce:int,routeVm:int,routeOwner:int,routeNonce:int,routeNative:int,refs:int,routed:bool,failed:bool,runError:bool,
    staleRejected:bool,duplicateRejected:bool,metaFree:bool,vmFree:bool,bad:bool}
  var s:S
  pure def initial(m:int,n:int):S={mode:m,bug:n,a:1,b:0,closing:false,phase:0,calls:0,
    loanA:true,loanB:false,ctlA:true,ctlB:false,frameA:true,frameB:false,
    runA:true,markerA:true,bridge:false,msgPin:false,resourcePin:true,
    rootA:true,rootB:false,rootM:false,senderDomain:false,ownerBAlive:false,msgRootOwner:0,cleanupOwner:-1,vA:0,vB:0,vM:0,gc:0,msg:0,msgVm:0,msgOwner:0,msgNonce:0,routeVm:0,routeOwner:0,routeNonce:0,routeNative:0,refs:3,
    routed:false,failed:false,runError:false,staleRejected:false,duplicateRejected:false,metaFree:false,vmFree:false,bad:false}
  action initWrongAckOwner=s'=initial(0,13)
  action initDropSenderDomain=s'=initial(0,14)
  action initOwnerDiesWithDomain=s'=initial(0,15)
  action initAckBeforeReceiverRoot=s'=initial(0,16)
  action initReturn=s'=initial(0,0)
  action initBodyError=s'=initial(1,0)
  action initPrefixError=s'=initial(2,0)
  action initBlockedChild=s'=initial(3,0)
  action initRunError=s'=initial(4,0)
  action initStaleOwner=s'=initial(5,0)
  action initDuplicateCompletion=s'=initial(6,0)
  action initRemoteLongjmp=s'=initial(0,1)
  action initPidOnlyRoute=s'=initial(0,2)
  action initChildFreesParent=s'=initial(0,3)
  action initPublishNoRoot=s'=initial(0,4)
  action initDropBridgeEarly=s'=initial(0,5)
  action initDropChildBeforeMessage=s'=initial(0,6)
  action initAcceptStaleOwner=s'=initial(5,7)
  action initDuplicateFinalDrop=s'=initial(6,8)
  action initRestorePreGcResult=s'=initial(0,9)
  action initAccessAfterFinalDrop=s'=initial(0,10)
  action initRunMarkerBypassed=s'=initial(4,11)
  action initBlockedChildFreed=s'=initial(3,12)
  action openBridge=all {s.a==1,s.mode!=4,not(s.closing),
    s'={...s,a:2,bridge:true,refs:s.refs+1}}
  action enterChild=all {s.a==2,s.b==0,not(s.closing),
    s'={...s,a:3,b:1,ownerBAlive:true,frameB:true,ctlB:true,rootB:true,vB:s.gc,refs:s.refs+1}}
  action refuseChild=all {s.a==2,s.b==0,s.closing,
    s'={...s,a:3,b:5,failed:true}}
  action childBorrow=all {s.b==1,s.phase==0,s.mode!=2,
    s'={...s,b:2,loanB:true}}
  action childPrefixError=all {s.b==1,(s.mode==2 or s.phase!=0),
    s'={...s,b:3,failed:true}}
  action childBodyReturn=all {s.b==2,s.mode!=3,
    s'={...s,b:3,failed:s.mode==1}}
  action childDrain=all {s.b==3,s'={...s,b:4,loanB:false}}
  action childTail=all {s.b==4,s'={...s,b:5}}
  action publish=all {s.b==5,s.msg==0,s.bridge,
    s'={...s,msg:1,msgRootOwner:if(s.frameB) 1 else 0,senderDomain:s.frameB,msgVm:7,msgOwner:2,msgNonce:101,rootM:true,vM:s.gc,msgPin:true,refs:s.refs+1}}
  action childFinal=all {s.b==5,s.msg==1,
    s'={...s,b:6,frameB:false,ctlB:false,rootB:false,refs:s.refs-(if(s.frameB) 1 else 0)}}
  action staleReject=all {s.mode==5,s.a==3,s.b==6,s.msg==1,not(s.staleRejected),
    s'={...s,staleRejected:true}}
  action consume=all {s.a==3,s.b==6,s.msg==1,s.msgVm==7,s.msgOwner==2,s.msgNonce==101,s.mode!=5 or s.staleRejected,
    s'={...s,a:4,msg:2,vA:s.vM,routed:true,routeVm:s.msgVm,routeOwner:s.msgOwner,routeNonce:s.msgNonce,routeNative:0}}
  action ownerAckFinal=all {s.b==6,s.msg==2,
    s'={...s,msg:3,rootM:false,msgPin:false,senderDomain:false,cleanupOwner:s.msgRootOwner,refs:s.refs-1}}
  action duplicateReject=all {s.mode==6,s.msg==3,not(s.duplicateRejected),
    s'={...s,duplicateRejected:true}}
  action parentNativeReturn=all {s.a==4,s.routed,s.mode!=6 or s.duplicateRejected,
    s'={...s,a:6,loanA:false}}
  action parentTail=all {s.a==6,s'={...s,a:7}}
  action parentFinal=all {s.a==7,s.msg>=2,s.b==6,
    s'={...s,a:8,frameA:false,ctlA:false,rootA:false,refs:s.refs-1}}
  action bridgeFinal=all {s.b==6,s.msg==3,s.bridge,
    s'={...s,bridge:false,refs:s.refs-1}}
  action abnormalRun=all {s.mode==4,s.a==1,
    s'={...s,a:8,loanA:false,frameA:false,ctlA:false,rootA:false,runError:true,refs:s.refs-1}}
  action runFinal=all {s.a==8,s.runA,
    s'={...s,runA:false,markerA:false,refs:s.refs-1}}
  action gc=all {s.gc<2,s.runA,
    s'={...s,gc:s.gc+1,vA:if(s.rootA) s.gc+1 else s.vA,
      vB:if(s.rootB) s.gc+1 else s.vB,vM:if(s.rootM) s.gc+1 else s.vM}}
  action close=all {not(s.closing),s'={...s,closing:true,phase:if(s.phase==0) 1 else s.phase}}
  action release=all {s.phase<2,not(s.loanA),not(s.loanB),
    s'={...s,phase:2,calls:1,resourcePin:false,refs:s.refs-1}}
  action freeMetadata=all {s.phase==2,not(s.ctlA),not(s.ctlB),not(s.bridge),not(s.msgPin),not(s.metaFree),s'={...s,metaFree:true}}
  action freeVm=all {s.closing,s.refs==0,not(s.vmFree),s'={...s,vmFree:true}}
  action unregisterOwnerB=all {s.b==6,not(s.senderDomain),s.ownerBAlive,s'={...s,ownerBAlive:false}}
  action mutant=any {
    all {s.bug==1,s.b==2,s'={...s,bad:true}},
    all {s.bug==2,s.a==3,s.msg==1,s'={...s,a:4,routed:true,routeVm:7,routeOwner:2,routeNonce:101,routeNative:1}},
    all {s.bug==3,s.b==2,s'={...s,frameA:false,ctlA:false,rootA:false,refs:s.refs-1}},
    all {s.bug==4,s.msg==1,s'={...s,rootM:false}},
    all {s.bug==5,s.b==2,s.bridge,s'={...s,bridge:false,refs:s.refs-1}},
    all {s.bug==6,s.b==4,s'={...s,frameB:false,ctlB:false,rootB:false,refs:s.refs-1}},
    all {s.bug==7,s.a==3,s.b==6,s.msg==1,s'={...s,a:4,routed:true,routeVm:7,routeOwner:1,routeNonce:101,routeNative:0}},
    all {s.bug==8,s.msg==3,s'={...s,refs:s.refs-1}},
    all {s.bug==9,s.a==4,s.gc>0,s'={...s,vA:0}},
    all {s.bug==10,s.a==8,not(s.ctlA),s'={...s,bad:true}},
    all {s.bug==11,s.runError,s.runA,s'={...s,runA:false,refs:s.refs-1}},
    all {s.bug==12,s.mode==3,s.b==2,s'={...s,phase:2,resourcePin:false,calls:1,refs:s.refs-1}},
    all {s.bug==13,s.msg==2,s.msgRootOwner==1,s'={...s,msg:3,rootM:false,msgPin:false,senderDomain:false,cleanupOwner:0,refs:s.refs-1}},
    all {s.bug==14,s.b==6,s.rootM,s.msgRootOwner==1,s'={...s,senderDomain:false}},
    all {s.bug==15,s.senderDomain,s'={...s,ownerBAlive:false}},
    all {s.bug==16,s.msg==1,s.b==6,s'={...s,msg:3,rootM:false,msgPin:false,senderDomain:false,cleanupOwner:s.msgRootOwner,refs:s.refs-1}}
  }
  action step=any {openBridge,enterChild,refuseChild,childBorrow,childPrefixError,childBodyReturn,childDrain,childTail,publish,childFinal,staleReject,consume,ownerAckFinal,duplicateReject,parentNativeReturn,parentTail,parentFinal,bridgeFinal,abnormalRun,runFinal,gc,close,release,freeMetadata,freeVm,unregisterOwnerB,mutant}
  val safe=all {not(s.bad),s.calls<=1,
    s.msg<2 or s.routed,s.msg!=3 or s.cleanupOwner==s.msgRootOwner,
    not(s.senderDomain) or (s.ownerBAlive and s.msgPin),
    not(s.rootM) or s.msgRootOwner!=1 or s.senderDomain,not(s.frameB) or s.ownerBAlive,
    not(s.routed) or (s.routeVm==7 and s.routeOwner==2 and s.routeNonce==101 and s.routeNative==0 and s.msg>=2),
    s.refs==(if(s.frameA) 1 else 0)+(if(s.frameB) 1 else 0)+(if(s.runA) 1 else 0)+(if(s.bridge) 1 else 0)+(if(s.msgPin) 1 else 0)+(if(s.resourcePin) 1 else 0),
    s.a>=8 or (s.frameA and s.ctlA and s.rootA and s.runA),
    s.b==0 or s.b>=6 or s.bridge,
    not(s.frameB) or (s.ctlB and s.rootB),s.b<1 or s.b>4 or s.frameB,
    s.msg==0 or s.msg>=3 or (s.rootM and s.msgPin),
    not(s.loanA) or s.frameA,not(s.loanB) or s.frameB,
    s.phase<2 or (not(s.loanA) and not(s.loanB)),
    not(s.markerA) or s.runA,
    not(s.rootA) or s.vA==s.gc,not(s.rootB) or s.vB==s.gc,not(s.rootM) or s.vM==s.gc,
    not(s.metaFree) or (s.phase==2 and not(s.ctlA) and not(s.ctlB) and not(s.bridge) and not(s.msgPin)),
    not(s.vmFree) or (s.closing and s.refs==0)}
}
