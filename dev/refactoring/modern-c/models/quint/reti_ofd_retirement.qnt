module reti_ofd_retirement {
 // Admission coverage and exact lease completion are premises, not current runtime facilities.
 type State={open:bool,code:int,descr:int,scan:int,native:int,inspect:int,unknown:bool,retired:bool}
 pure val initial:State={open:true,code:0,descr:0,scan:0,native:0,inspect:0,unknown:false,retired:false}
 var s:State
 action init=s'=initial
 val empty=s.code==0 and s.descr==0 and s.scan==0 and s.native==0 and s.inspect==0
 val safe=all{s.code>=0,s.descr>=0,s.scan>=0,s.native>=0,s.inspect>=0,
 s.retired implies (not(s.open) and empty and not(s.unknown))}
 action capturePin=all{s.open,s.code<1,s.descr<1,s'={...s,code:s.code+1,descr:s.descr+1}}
 action scanEnter=all{not(s.retired),(s.open or s.code>0 or s.descr>0 or s.native>0 or s.inspect>0),s.scan<1,s'={...s,scan:s.scan+1}}
 action nativeEnter=all{s.open,s.native<1,s'={...s,native:s.native+1}}
 action inspectEnter=all{s.open,s.inspect<1,s'={...s,inspect:s.inspect+1}}
 action close=all{s'={...s,open:false}}
 action releaseCapture=all{s.code>0,s.descr>0,s'={...s,code:s.code-1,descr:s.descr-1}}
 action scanExit=all{s.scan>0,s'={...s,scan:s.scan-1}}
 action nativeExit=all{s.native>0,not(s.unknown),s'={...s,native:s.native-1}}
 action inspectExit=all{s.inspect>0,s'={...s,inspect:s.inspect-1}}
 action loseOutcome=all{s.native>0,s'={...s,unknown:true}}
 action retire=all{not(s.open),empty,not(s.unknown),s'={...s,retired:true}}
 action step=any{capturePin,scanEnter,nativeEnter,inspectEnter,close,releaseCapture,scanExit,nativeExit,inspectExit,loseOutcome,retire,all{s'=s}}
 run fullDrainTest=init.then(capturePin).then(scanEnter).then(nativeEnter).then(inspectEnter).then(close).then(releaseCapture).then(scanExit).then(nativeExit).then(inspectExit).then(retire).then(all{assert(safe and s.retired),s'=s})
 run stoppedCallerStillPinnedTest=init.then(capturePin).then(close).then(all{assert(safe and not(empty) and not(s.retired)),s'=s})
 run unknownKeepsNativeDebtTest=init.then(nativeEnter).then(close).then(loseOutcome).then(all{assert(safe and s.native==1 and not(s.retired)),s'=s})
 run scannerOutlivesCaptureTest=init.then(capturePin).then(scanEnter).then(close).then(releaseCapture).then(all{assert(safe and s.scan==1 and not(s.retired)),s'=s})
 run closedCaptureStillScannableTest=init.then(capturePin).then(close).then(scanEnter).then(scanExit).then(releaseCapture).then(retire).then(all{assert(safe and s.retired),s'=s})
 run zeroWithoutCloseControlTest=init.then(all{s'={...s,retired:true}}).then(all{assert(not(safe)),s'=s})
 run descriptorFreedWithCaptureControlTest=init.then(capturePin).then(close).then(all{s'={...s,retired:true}}).then(all{assert(not(safe)),s'=s})
 run unknownRetirementControlTest=init.then(nativeEnter).then(close).then(loseOutcome).then(all{s'={...s,native:0,retired:true}}).then(all{assert(not(safe)),s'=s})
 run lateAdmissionControlTest=init.then(close).then(retire).then(all{s'={...s,scan:1}}).then(all{assert(not(safe)),s'=s})
}
