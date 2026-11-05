module reaper_root_publication {
  // Conservative publication/view abstraction, not a complete C11 checker.
  // Root kinds1..7: continuation/registers/saved/cache/processor/RC/still.
  // Synchronized reads are fresh; absent a matching HB edge, stale is allowed.
  type State={bug:int,epoch:int,phase:int,callbacksDone:bool,rawFrame:bool,
    carrierRooted:bool,exports:Set[int],listsRegistered:bool,frozen:bool,
    preparedRelease:bool,preparedFresh:bool,readyRelease:bool,inputFresh:bool,claimed:bool,joined:bool,
    payloadWritten:bool,doneRelease:bool,resultFresh:bool,consumerOwns:bool,
    consumedEpoch:int,gcPass:int,scanLease:bool,scanned:Set[int],
    destinationRooted:bool,freed:bool,readEarly:bool,producerAfterDone:bool,
    overwritten:bool,pastRooted:bool}
  val kinds=Set(1,2,3,4,5,6,7)
  var s:State
  pure def initial(bug:int):State={bug:bug,epoch:1,phase:0,
    callbacksDone:false,rawFrame:true,carrierRooted:false,exports:Set(),
    listsRegistered:false,frozen:false,preparedRelease:false,preparedFresh:false,readyRelease:false,inputFresh:false,
    claimed:false,joined:false,payloadWritten:false,doneRelease:false,
    resultFresh:false,consumerOwns:false,consumedEpoch:0,gcPass:0,
    scanLease:false,scanned:Set(),destinationRooted:false,freed:false,
    readEarly:false,producerAfterDone:false,overwritten:false,pastRooted:false}
  action init=s'=initial(0)
  action initNoReadyRelease=s'=initial(1)
  action initNoReadyAcquire=s'=initial(2)
  action initNoDoneRelease=s'=initial(3)
  action initNoDoneAcquire=s'=initial(4)
  action initReadBeforeAcquire=s'=initial(5)
  action initOverwriteBeforeConsume=s'=initial(6)
  action initRawFrameCommit=s'=initial(7)
  action initMissingStillScan=s'=initial(8)
  action initCallbackAfterFreeze=s'=initial(9)
  action initFreeWithScanLease=s'=initial(10)
  action initPublishBeforePayload=s'=initial(11)
  action initStaleEpoch=s'=initial(12)
  action initUnrootedCarrier=s'=initial(13)
  action initProducerAfterDone=s'=initial(14)
  action initPartialExport=s'=initial(15)
  action initSkipSecondRcScan=s'=initial(16)
  action initNoPreparedRelease=s'=initial(17)
  action initNoPreparedAcquire=s'=initial(18)
  action drainCallbacks=all {
    s.phase==0,not(s.callbacksDone),s'={...s,callbacksDone:true}
  }
  action save=all {
    s.phase==0,s.callbacksDone,
    s'={...s,phase:1,carrierRooted:true,exports:Set(2,3,4,5),listsRegistered:true}
  }
  // Old cohort still owns raw frames until materialization has completed.
  action materialize=all {
    s.phase==1,s.listsRegistered,s.carrierRooted,
    s'={...s,phase:2,rawFrame:false,exports:s.exports.union(Set(1)),frozen:true,preparedRelease:s.bug!=17}
  }
  action publishReady= {
    nondet fresh=Set(false,true).oneOf()
    all {
      s.phase==2,s.frozen,
      fresh or not(s.preparedRelease) or s.bug==18,
      s'={...s,phase:3,preparedFresh:fresh,readyRelease:s.bug!=1}
    }
  }
  action claim= {
    nondet fresh=Set(false,true).oneOf()
    all {
      s.phase==3,
      fresh or not(s.readyRelease) or s.bug==2,
      s'={...s,phase:4,claimed:true,inputFresh:fresh}
    }
  }
  action startGc=all {
    (s.phase==4 and s.gcPass==0) or (s.phase==6 and s.gcPass==1),
    not(s.scanLease),s'={...s,scanLease:true}
  }
  action finishGc=all {
    s.scanLease,
    s'={...s,scanLease:false,gcPass:s.gcPass+1,
      scanned:if(s.bug==8) kinds.exclude(Set(7))
        else if(s.bug==16 and s.gcPass==1) kinds.exclude(Set(6)) else kinds}
  }
  action joinZero=all {
    s.phase==4,s.gcPass==1,not(s.scanLease),
    s'={...s,phase:5,joined:true}
  }
  action writePayload=all {
    s.phase==5,not(s.payloadWritten),s'={...s,payloadWritten:true}
  }
  action publishDone=all {
    s.phase==5,s.payloadWritten,
    s'={...s,phase:6,doneRelease:s.bug!=3}
  }
  action consume= {
    nondet fresh=Set(false,true).oneOf()
    all {
      s.phase==6,s.gcPass==2,not(s.scanLease),
      fresh or not(s.doneRelease) or s.bug==4,
      s'={...s,phase:7,resultFresh:fresh,consumerOwns:true,consumedEpoch:s.epoch}
    }
  }
  action transferAndCloseScan=all {
    s.phase==7,s.gcPass==2,not(s.scanLease),s.consumerOwns,
    s'={...s,phase:8,destinationRooted:true}
  }
  action reclaim=all {
    s.phase==8,s.destinationRooted,not(s.scanLease),
    s'={...s,phase:9,freed:true,carrierRooted:false,consumerOwns:false}
  }
  action nextEpoch=all {
    s.phase==9,s.epoch==1,
    s'={...initial(s.bug),epoch:2,pastRooted:true}
  }
  action readBeforeAcquire=all {
    s.bug==5,s.phase==6,s'={...s,readEarly:true}
  }
  action overwriteBeforeConsume=all {
    s.bug==6,s.phase==6,s'={...s,overwritten:true}
  }
  action rawFrameCommit=all {
    s.bug==7,s.phase==1,
    s'={...s,phase:3,frozen:true,preparedFresh:true,readyRelease:true}
  }
  action callbackAfterFreeze=all {
    s.bug==9,s.phase==3,s'={...s,callbacksDone:false}
  }
  action freeWithScanLease=all {
    s.bug==10,s.phase==6,s.scanLease,s'={...s,freed:true}
  }
  action publishBeforePayload=all {
    s.bug==11,s.phase==5,not(s.payloadWritten),
    s'={...s,phase:6,doneRelease:true}
  }
  action staleEpoch=all {
    s.bug==12,s.epoch==2,s.phase==6,
    s'={...s,phase:7,resultFresh:true,consumerOwns:true,consumedEpoch:1}
  }
  action unrootedCarrier=all {
    s.bug==13,s.phase==3,s'={...s,carrierRooted:false}
  }
  action producerAfterDone=all {
    s.bug==14,s.phase==6,s'={...s,producerAfterDone:true}
  }
  action partialExport=all {
    s.bug==15,s.phase==2,s'={...s,exports:s.exports.exclude(Set(3))}
  }
  val terminal=s.phase==9 and s.epoch==2
  action done=all {terminal,s'=s}
  action step=any {drainCallbacks,save,materialize,publishReady,claim,startGc,
    finishGc,joinZero,writePayload,publishDone,consume,transferAndCloseScan,
    reclaim,nextEpoch,readBeforeAcquire,overwriteBeforeConsume,rawFrameCommit,
    callbackAfterFreeze,freeWithScanLease,publishBeforePayload,staleEpoch,
    unrootedCarrier,producerAfterDone,partialExport,done}
  val safe=all {
    not(s.readEarly),not(s.overwritten),not(s.producerAfterDone),
    s.epoch==1 or s.pastRooted,
    s.phase<3 or (s.preparedFresh and not(s.rawFrame) and s.frozen and s.callbacksDone and
      s.exports==Set(1,2,3,4,5)),
    s.phase<3 or s.carrierRooted or s.destinationRooted,
    not(s.claimed) or s.inputFresh,
    s.gcPass==0 or s.scanned==kinds,
    s.phase<6 or s.payloadWritten,
    not(s.consumerOwns) or (s.resultFresh and s.consumedEpoch==s.epoch),
    not(s.freed) or (s.joined and s.destinationRooted and not(s.scanLease)),
    s.phase<7 or s.resultFresh
  }
  temporal completion=weakFair(step,Set(s)).implies(eventually(terminal))
}
