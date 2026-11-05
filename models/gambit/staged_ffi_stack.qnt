module staged_ffi_stack {
  // One prefix string loan, one scalar argument, one callback-native result loan.
  // phase 4 initial dispatch has no host frame; callback repark at 8 is in-place.
  type S={mode:int,bug:int,phase:int,journal:bool,jobPin:bool,root:bool,scan:bool,
    gcBit:bool,rootBit:bool,active:bool,argHeld:bool,argFrees:int,calls:int,
    bodyEntered:bool,bodyDone:bool,hostAlive:bool,parentMarker:bool,
    cbCount:int,cbLive:bool,cbMarker:bool,cbTail:bool,cbRoot:bool,cbBit:bool,
    cbLoan:bool,cbLoanOwner:int,cbLoanFrees:int,cbError:bool,cbReturned:bool,
    resultConverted:bool,schemeResult:bool,resultBit:bool,resultScan:bool,catcherOwner:int,hookCount:int,error:bool,
    retained:bool,refused:bool,unknownEffect:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,phase:0,journal:false,jobPin:false,
    root:false,scan:true,gcBit:false,rootBit:false,active:true,argHeld:false,
    argFrees:0,calls:0,bodyEntered:false,bodyDone:false,hostAlive:false,
    parentMarker:true,cbCount:0,cbLive:false,cbMarker:false,cbTail:false,
    cbRoot:false,cbBit:false,cbLoan:false,cbLoanOwner:0,cbLoanFrees:0,
    cbError:false,cbReturned:false,resultConverted:false,schemeResult:false,resultBit:false,resultScan:true,catcherOwner:1,
    hookCount:0,error:false,retained:false,refused:false,unknownEffect:false}
  action initReturn=s'=initial(0,0)
  action initPrefixError=s'=initial(1,0)
  action initResultError=s'=initial(2,0)
  action initCallback=s'=initial(3,0)
  action initCallbackError=s'=initial(4,0)
  action initReparkRetained=s'=initial(5,0)
  action initInlineRefusal=s'=initial(6,0)
  action initHookRefusal=s'=initial(7,0)
  action initNativeUnknown=s'=initial(8,0)
  action initPrepareError=s'=initial(9,0)
  action initMissingResultRoot=s'=initial(0,15)
  action initReturnedCatcher=s'=initial(3,16)
  action initMissingNativeCatcher=s'=initial(0,17)
  action initUnwindHost=s'=initial(3,1)
  action initLegacyErrorUnwind=s'=initial(4,2)
  action initDoubleBody=s'=initial(3,3)
  action initPrefixLeak=s'=initial(1,4)
  action initDoubleArgFree=s'=initial(0,5)
  action initMissingRoot=s'=initial(0,6)
  action initKillRunMarker=s'=initial(0,7)
  action initResultWhileParked=s'=initial(0,8)
  action initReturnBeforeRepark=s'=initial(3,9)
  action initChildOwnsLoan=s'=initial(3,10)
  action initDropCallbackTail=s'=initial(3,11)
  action initAtEndEarly=s'=initial(0,12)
  action initPrefixBeforeJournal=s'=initial(0,13)
  action initReplayUnknownBody=s'=initial(8,14)
  action refuse=all {s.phase==0,Set(6,7).contains(s.mode),s'={...s,phase:15,refused:true}}
  action beginJob=all {s.phase==0,not(Set(6,7).contains(s.mode)),
    s'={...s,phase:1,journal:true,jobPin:true,root:true,rootBit:s.gcBit}}
  action convertFirst=all {s.phase==1,s'={...s,phase:2,argHeld:true}}
  action prefixError=all {s.phase==2,s.mode==1,s'={...s,phase:14,error:true}}
  action convertSecond=all {s.phase==2,s.mode!=1,s'={...s,phase:3}}
  action prepareError=all {s.phase==3,s.mode==9,s'={...s,phase:14,error:true}}
  action initialPark=all {s.phase==3,s.mode!=9,s'={...s,phase:4,active:false}}
  action enterHost=all {s.phase==4,s'={...s,phase:5,calls:s.calls+1,bodyEntered:true,hostAlive:true}}
  action callbackEnter=all {s.phase==5,Set(3,4,5).contains(s.mode),s.cbCount==0,
    s'={...s,phase:6,active:true,cbCount:1,cbLive:true,cbMarker:true,cbTail:true,catcherOwner:2,
      cbRoot:true,cbBit:s.gcBit,cbError:s.mode==4}}
  action callbackConvert=all {s.phase==6,s'={...s,phase:7,cbLoan:true,cbLoanOwner:1}}
  // Child marker/SFUN lease ends, native wrapper tail remains pinned.
  action callbackEpilogue=all {s.phase==7,s'={...s,phase:8,cbMarker:false,cbRoot:false,catcherOwner:1}}
  action repark=all {s.phase==8,s.mode!=5,s'={...s,phase:9,active:false}}
  action reparkFailure=all {s.phase==8,s.mode==5,s'={...s,phase:12,retained:true}}
  action callbackNativeReturn=all {s.phase==9,s'={...s,phase:5,cbLive:false,cbTail:false,cbReturned:true}}
  action hostReturn=all {s.phase==5,not(Set(3,4,5).contains(s.mode)) or s.cbReturned,
    s.mode!=8,s'={...s,phase:10,bodyDone:true,hostAlive:false}}
  action nativeUnknown=all {s.phase==5,s.mode==8,s'={...s,phase:12,bodyDone:true,
    hostAlive:false,retained:true,error:true,unknownEffect:true}}
  action finalAttach=all {s.phase==10,s'={...s,phase:11,active:true}}
  action resultConvert=all {s.phase==11,s'={...s,phase:13,resultConverted:true,
    schemeResult:s.mode!=2,resultBit:s.gcBit,error:s.mode==2}}
  action atEnd=all {s.phase==13,s'={...s,phase:14,hookCount:s.hookCount+1}}
  action cleanup=all {s.phase==14,s'={...s,phase:15,argHeld:false,
    argFrees:if(s.argHeld) s.argFrees+1 else s.argFrees,
    cbLoan:false,cbLoanFrees:if(s.cbLoan) s.cbLoanFrees+1 else s.cbLoanFrees,
    root:false,journal:false,jobPin:false}}
  action gc=all {s.phase>0,s'={...s,gcBit:not(s.gcBit),
    rootBit:if(s.root and s.scan) not(s.gcBit) else s.rootBit,
    cbBit:if(s.cbRoot) not(s.gcBit) else s.cbBit,
    resultBit:if(s.schemeResult and s.resultScan) not(s.gcBit) else s.resultBit}}
  action mutant=any {
    all {s.bug==15,s.phase==13,s.schemeResult,s'={...s,resultScan:false}},
    all {s.bug==16,s.phase==8,s'={...s,catcherOwner:3}},
    all {s.bug==17,s.phase==5,s.hostAlive,s'={...s,catcherOwner:0}},
    all {s.bug==1,s.phase==8,s'={...s,phase:12,hostAlive:false,cbLive:false,retained:true}},
    all {s.bug==2,s.phase==8,s.cbError,s'={...s,phase:12,hostAlive:false,cbLive:false,retained:true}},
    all {s.bug==3,s.phase==9,s'={...s,calls:s.calls+1}},
    all {s.bug==4,s.phase==14,s'={...s,phase:15,journal:false,jobPin:false,root:false}},
    all {s.bug==5,s.phase==15,s.argFrees==1,s'={...s,argFrees:2}},
    all {s.bug==6,s.phase==4,s'={...s,scan:false}},
    all {s.bug==7,s.phase==4,s'={...s,parentMarker:false}},
    all {s.bug==8,s.phase==10,s'={...s,resultConverted:true}},
    all {s.bug==9,s.phase==8,s'={...s,phase:5,cbLive:false,cbTail:false,cbReturned:true}},
    all {s.bug==10,s.phase==7,s'={...s,cbLoanOwner:2}},
    all {s.bug==11,s.phase==8,s'={...s,cbTail:false}},
    all {s.bug==12,s.phase==11,s'={...s,hookCount:1}},
    all {s.bug==13,s.phase==1,s'={...s,journal:false}},
    all {s.bug==14,s.phase==12,s.unknownEffect,s'={...s,phase:5,calls:2,bodyDone:false,hostAlive:true}}
  }
  action idle=s'=s
  action step=any {refuse,beginJob,convertFirst,prefixError,convertSecond,prepareError,
    initialPark,enterHost,callbackEnter,callbackConvert,callbackEpilogue,repark,
    reparkFailure,callbackNativeReturn,hostReturn,nativeUnknown,finalAttach,
    resultConvert,atEnd,cleanup,gc,mutant,idle}
  val safe=all {
    s.parentMarker,Set(1,2).contains(s.catcherOwner),
    s.catcherOwner!=2 or (s.cbLive and s.cbMarker),
    not(s.schemeResult) or s.resultBit==s.gcBit,
    s.calls<=1,s.argFrees<=1,s.cbLoanFrees<=1,s.hookCount<=1,
    not(s.root) or (s.jobPin and s.journal and s.rootBit==s.gcBit),
    not(s.cbRoot) or s.cbBit==s.gcBit,
    not(s.argHeld) or (s.jobPin and s.journal),
    not(s.cbLoan) or (s.cbLoanOwner==1 and s.jobPin and s.journal),
    not(s.bodyEntered) or s.bodyDone or s.hostAlive,
    not(s.hostAlive and not(s.cbLive)) or not(s.active),
    not(s.cbLive) or (s.hostAlive and s.cbTail and s.jobPin),
    not(s.resultConverted) or (s.bodyDone and s.active),
    s.hookCount==0 or (s.bodyDone and s.resultConverted),
    not(s.retained) or (s.root and s.journal and s.jobPin),
    s.phase!=15 or (not(s.argHeld) and not(s.cbLoan)),
    not(s.refused) or (s.calls==0 and not(s.bodyEntered))}
  val goal=if(Set(5,8).contains(s.mode)) s.retained and s.root and s.journal
    else if(Set(6,7).contains(s.mode)) s.phase==15 and s.refused
    else if(Set(1,9).contains(s.mode)) s.phase==15 and s.error and s.calls==0 and s.argFrees==1
    else s.phase==15 and s.calls==1 and s.hookCount==1 and s.argFrees==1
  temporal fairness=all {weakFair(refuse,Set(s)),weakFair(beginJob,Set(s)),
    weakFair(convertFirst,Set(s)),weakFair(prefixError,Set(s)),weakFair(convertSecond,Set(s)),
    weakFair(prepareError,Set(s)),weakFair(initialPark,Set(s)),weakFair(enterHost,Set(s)),
    weakFair(callbackEnter,Set(s)),weakFair(callbackConvert,Set(s)),
    weakFair(callbackEpilogue,Set(s)),weakFair(repark,Set(s)),weakFair(reparkFailure,Set(s)),
    weakFair(callbackNativeReturn,Set(s)),weakFair(hostReturn,Set(s)),
    weakFair(nativeUnknown,Set(s)),weakFair(finalAttach,Set(s)),weakFair(resultConvert,Set(s)),
    weakFair(atEnd,Set(s)),weakFair(cleanup,Set(s)),weakFair(gc,Set(s))}
  temporal progress=fairness.implies(eventually(goal))
}
