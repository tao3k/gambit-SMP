module cohort_ack_rc {
  // Three old members; B=2 parks. New members 0,1. One rooted job carrier.
  type S={mode:int,bug:int,installed:bool,go:bool,acks:Set[int],tails:Set[int],
    activated:Set[int],oldLive:bool,oldAccess:bool,departed:bool,hostDone:bool,
    rejoined:bool,dst:bool,restoreAck:bool,rc:bool,borrowers:Set[int],readers:Set[int],
    window:bool,closing:bool,releases:int,g:bool,rg:bool,dg:bool,
    retained:bool,serviced:bool,returnedEarly:bool,detachedPs:bool,failed:bool,newGc:bool,distinctChannels:bool}
  var s:S
  val old=Set(0,1,2)
  val successors=Set(0,1)
  pure def initial(m:int,b:int):S={mode:m,bug:b,installed:false,go:false,acks:Set(),tails:old,
    activated:Set(),oldLive:true,oldAccess:false,departed:false,hostDone:false,
    rejoined:false,dst:false,restoreAck:false,rc:true,borrowers:Set(0,1),readers:Set(),
    window:false,closing:false,releases:0,g:false,rg:false,dg:false,
    retained:false,serviced:false,returnedEarly:false,detachedPs:false,failed:false,newGc:false,distinctChannels:true}
  action initSuccess=s'=initial(0,0)
  action initRetry=s'=initial(1,0)
  action initRetained=s'=initial(2,0)
  action initSharedMailbox=s'=initial(0,15)
  action initEarlyGo=s'=initial(0,1)
  action initActivateBeforeGo=s'=initial(0,2)
  action initMemberReturn=s'=initial(0,3)
  action initFreeOldAtAck=s'=initial(0,4)
  action initOldTailAccess=s'=initial(0,5)
  action initFreeRcAtGo=s'=initial(0,6)
  action initAckWithoutRoot=s'=initial(0,7)
  action initFreeWithBorrow=s'=initial(0,8)
  action initFreeWithReader=s'=initial(0,9)
  action initLoseMap=s'=initial(0,10)
  action initDetachedReload=s'=initial(0,11)
  action initDoubleRelease=s'=initial(0,12)
  action initFailedDrop=s'=initial(2,13)
  action initPostReleaseRead=s'=initial(0,14)
  action prepare=all {not(s.installed),not(s.retained),s.mode!=2 and (s.mode!=1 or s.failed),s'={...s,installed:true}}
  action refuse=all {not(s.installed),not(s.retained),s.mode==2 or (s.mode==1 and not(s.failed)),s'={...s,retained:true,failed:true}}
  action serviceRetained=all {s.retained,s'={...s,serviced:not(s.serviced)}}
  action retry=all {s.mode==1,s.retained,s.serviced,s'={...s,retained:false}}
  action ack(i:int):bool=all {s.installed,not(s.go),not(s.acks.contains(i)),s'={...s,acks:s.acks.union(Set(i))}}
  action publishGo=all {s.installed,s.acks==old,not(s.go),s'={...s,go:true}}
  action activate(i:int):bool=all {s.go,not(s.activated.contains(i)),s'={...s,activated:s.activated.union(Set(i))}}
  action dropTail(i:int):bool=all {s.go,s.tails.contains(i),s'={...s,tails:s.tails.exclude(Set(i))}}
  action freeOld=all {s.oldLive,s.go,s.tails==Set(),s'={...s,oldLive:false}}
  action returnHost=all {s.go,not(s.departed),not(s.tails.contains(2)),s'={...s,departed:true}}
  action finishHost=all {s.departed,not(s.hostDone),s'={...s,hostDone:true}}
  action rejoin=all {s.hostDone,s.activated==successors,not(s.rejoined),s'={...s,rejoined:true}}
  action installRoot=all {s.rejoined,not(s.dst),s'={...s,dst:true,dg:s.g}}
  action ackRoot=all {s.dst,not(s.restoreAck),s'={...s,restoreAck:true}}
  action dropBorrow(i:int):bool=all {s.restoreAck,s.borrowers.contains(i),s'={...s,borrowers:s.borrowers.exclude(Set(i))}}
  action startRead(i:int):bool=all {s.go,s.rc,not(s.window),not(s.closing),not(s.readers.contains(i)),s'={...s,readers:s.readers.union(Set(i))}}
  action endRead(i:int):bool=all {s.readers.contains(i),s'={...s,readers:s.readers.exclude(Set(i))}}
  action beginWindow=all {s.restoreAck,not(s.window),s.readers==Set(),s'={...s,window:true}}
  action skipBusy=all {s.window,s.borrowers!=Set(),s'={...s,window:false}}
  action closeRc=all {s.window,s.borrowers==Set(),not(s.closing),s'={...s,closing:true}}
  action releaseRc=all {s.window,s.closing,s.rc,s.readers==Set(),s.borrowers==Set(),s.restoreAck,
    s'={...s,rc:false,releases:s.releases+1}}
  action endWindow=all {s.window,not(s.rc),s'={...s,window:false}}
  action gc=all {not(s.window),(not(s.installed) or (s.go and s.activated==successors)),s'={...s,newGc:s.newGc or s.go,g:not(s.g),
    rg:if(s.rc) not(s.g) else s.rg,dg:if(s.dst) not(s.g) else s.dg}}
  action mutant=any {
    all {s.bug==15,s.go,s.tails!=Set(),s'={...s,distinctChannels:false}},
    all {s.bug==1,s.installed,s.acks!=old,s'={...s,go:true}},
    all {s.bug==2,s.installed,not(s.go),s'={...s,activated:Set(0)}},
    all {s.bug==3,s.installed,not(s.go),s'={...s,returnedEarly:true}},
    all {s.bug==4,s.go,s.tails!=Set(),s'={...s,oldLive:false}},
    all {s.bug==5,s.go,not(s.tails.contains(2)),s'={...s,oldAccess:true}},
    all {s.bug==6,s.go,not(s.dst),s'={...s,rc:false}},
    all {s.bug==7,s.rejoined,not(s.dst),s'={...s,restoreAck:true}},
    all {s.bug==8,s.window,s.borrowers!=Set(),s'={...s,rc:false,releases:1}},
    all {s.bug==9,s.restoreAck,s.readers!=Set(),s'={...s,rc:false,releases:1}},
    all {s.bug==10,s.dst,s'={...s,g:not(s.g),rg:if(s.rc) not(s.g) else s.rg}},
    all {s.bug==11,s.departed,not(s.rejoined),s'={...s,detachedPs:true}},
    all {s.bug==12,s.releases==1,s'={...s,releases:2}},
    all {s.bug==13,s.retained,s'={...s,rc:false}},
    all {s.bug==14,not(s.rc),s'={...s,oldAccess:true}}
  }
  action idle=s'=s
  action step=any {prepare,refuse,serviceRetained,retry,publishGo,freeOld,returnHost,finishHost,
    rejoin,installRoot,ackRoot,beginWindow,skipBusy,closeRc,releaseRc,endWindow,gc,mutant,idle,
    ack(0),ack(1),ack(2),activate(0),activate(1),dropTail(0),dropTail(1),dropTail(2),
    dropBorrow(0),dropBorrow(1),startRead(0),startRead(1),endRead(0),endRead(1)}
  val safe=all {not(s.go and s.tails!=Set()) or s.distinctChannels,not(s.go) or (s.installed and s.acks==old),s.go or s.activated==Set(),
    s.oldLive or s.tails==Set(),not(s.oldAccess),not(s.returnedEarly),not(s.detachedPs),
    not(s.departed) or (s.go and not(s.tails.contains(2))),
    not(s.restoreAck) or (s.dst and s.rejoined),s.rc or s.dst,
    not(s.rc) or s.rg==s.g,not(s.dst) or s.dg==s.g,
    s.releases<=1,s.rc or (s.restoreAck and s.readers==Set() and s.borrowers==Set()),
    not(s.retained) or (s.rc and not(s.go))}
  // Safety only: readers can arrive indefinitely. Progress of root reclaim
  // requires bounded owner windows, reader completion and borrower completion.
}
