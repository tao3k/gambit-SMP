module admission_lifetime_aba {
  // Boundary refinement of finalizer_registry_composition: one VM is reused
  // at the SAME address. Registry cells and their lock outlive both VMs.
  type S={bug:int,phase:int,gen:int,token:int,entryGen:int,message:int,
    registryReaders:int,units:int,resource:bool,service:bool,reader:bool,
    borrowed:bool,closed:bool,destroying:bool,freed:bool,
    receiverReady:bool,owned:bool,accessed:bool,rejected:bool,bad:bool}
  var s:S
  pure def initial(b:int):S={bug:b,phase:0,gen:1,token:1,entryGen:1,message:1,
    registryReaders:0,units:0,resource:false,service:false,reader:false,
    borrowed:false,closed:false,destroying:false,freed:false,
    receiverReady:false,owned:false,accessed:false,rejected:false,bad:false}
  action initNormal=s'=initial(0)
  action initStaleVm=s'={...initial(0),token:0}
  action initStaleEntry=s'={...initial(0),message:0}
  action initLookupAfterUnlock=s'=initial(1)
  action initReleaseBeforeLastUse=s'=initial(2)
  action initRawDestructor=s'=initial(3)
  action initStaleVmAccepted=s'={...initial(4),token:0}
  action initStaleEntryAccepted=s'={...initial(5),message:0}
  action initOwnedBeforePayload=s'=initial(6)
  action initWrapCount=s'=initial(7)
  action initResetWithReader=s'=initial(8)
  action initLateEnroll=s'=initial(9)
  action lookup=all {s.phase==0,
    s'={...s,phase:1,registryReaders:1}}
  action acquire=all {s.phase==1,
    val valid=s.token==s.gen
    s'={...s,phase:2,borrowed:valid or s.bug==4,
      units:if(valid or s.bug==4) 1 else 0,rejected:not(valid) and s.bug!=4,
      bad:s.bad or (not(valid) and s.bug==4)}}
  action unlockRegistry=all {s.phase==2,
    s'={...s,phase:3,registryReaders:0}}
  action publish=all {s.phase==3,s.borrowed,
    s'={...s,phase:4,borrowed:false,resource:true,
      receiverReady:s.bug!=6,owned:true}}
  action close=all {s.phase==4,
    s'={...s,phase:5,closed:true}}
  action derive=all {s.phase==5,
    s'={...s,phase:6,service:true,reader:true,
      units:if(s.bug==7) 0 else s.units+2,
      bad:s.bad or s.bug==7}}
  action readEntry=all {s.phase==6,
    val valid=s.message==s.entryGen
    s'={...s,phase:7,accessed:valid or s.bug==5,
      bad:s.bad or (not(valid) and s.bug==5) or not(s.receiverReady)}}
  action leaveReader=all {s.phase==7,
    s'={...s,phase:8,reader:false,units:s.units-1}}
  action releaseResource=all {s.phase==8,
    s'={...s,phase:9,resource:false,units:s.units-1}}
  action finishService=all {s.phase==9,
    s'={...s,phase:10,service:false,units:s.units-1}}
  action takeDestroy=all {s.phase==10,s.closed,s.units==0,
    s'={...s,phase:11,destroying:true}}
  action destroy=all {s.phase==11,s.destroying,s.units==0,
    s'={...s,phase:12,freed:true}}
  action reuse=all {s.phase==12,s.registryReaders==0,
    s'={...s,phase:13,gen:2,entryGen:2}}
  action replay=all {s.phase==13,
    s'={...s,phase:14,rejected:s.token!=s.gen and s.message!=s.entryGen}}
  action rejectDone=all {s.phase==3,s.rejected,s'={...s,phase:14}}
  action corrupt=any {
    all {s.bug==1,s.phase==1,s'={...s,registryReaders:0,freed:true,bad:true}},
    all {s.bug==2,s.phase==9,s'={...s,units:0,freed:true,bad:true}},
    all {s.bug==3,s.phase==5,s'={...s,freed:true,bad:true}},
    all {s.bug==8,s.phase==6,s'={...s,entryGen:2,bad:true}},
    all {s.bug==9,s.phase==5,s'={...s,borrowed:true,units:s.units+1,bad:true}}
  }
  action step=any {lookup,acquire,unlockRegistry,publish,close,derive,readEntry,
    leaveReader,releaseResource,finishService,takeDestroy,destroy,reuse,replay,
    rejectDone,corrupt}
  val safe=all {not(s.bad),s.units>=0,
    s.units== (if(s.borrowed) 1 else 0)+(if(s.resource) 1 else 0)+(if(s.service) 1 else 0)+(if(s.reader) 1 else 0),
    not(s.freed) or (s.units==0 and s.registryReaders==0),
    not(s.owned) or s.receiverReady,
    s.phase!=14 or s.rejected}
}
