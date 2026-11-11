module sfun_converter_use_closure {
// Successfully rooted marker, one privateCopy copy/foreign wrapper, one captured payload.
// Callback success and NoAbandon are explicit refinement premises, not facts inferred from legacy return codes.
type State={phase:int,privateCopy:int,payload:int,inputRef:int,active:int,result:int,gate:int,valid:int,receipt:int,marker:int,effects:int,settled:int,critical:int,captured:int,dtor:int,code:int,roots:int,gc:int,exitAck:int,reply:int}
pure val initial:State={phase:0,privateCopy:0,payload:0,inputRef:0,active:0,result:0,gate:1,valid:1,receipt:0,marker:1,effects:0,settled:0,critical:0,captured:0,dtor:0,code:1,roots:1,gc:0,exitAck:0,reply:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,
s.privateCopy>=0,
s.payload>=0,
s.inputRef>=0,
s.active>=0,
s.result>=0,
s.gate>=0,
s.valid>=0,
s.receipt>=0,
s.marker>=0,
s.effects>=0,
s.settled>=0,
s.critical>=0,
s.captured>=0,
s.dtor>=0,
s.code>=0,
s.roots>=0,
s.gc>=0,
s.exitAck>=0,
s.reply>=0,
s.phase<=14,
s.privateCopy<=1,
s.payload<=1,
s.inputRef<=1,
s.active<=1,
s.result<=2,
s.gate<=1,
s.valid<=1,
s.receipt<=1,
s.marker<=1,
s.effects<=1,
s.settled<=1,
s.critical<=1,
s.captured<=1,
s.dtor<=3,
s.code<=1,
s.roots<=1,
s.gc<=1,
s.exitAck<=1,
s.reply<=1,
s.marker+s.effects==1,
s.settled<=s.effects,
(s.phase==0) implies (s.privateCopy==0 and s.payload==0 and s.inputRef==0 and s.active==0 and s.result==0),
(s.phase==1 or s.phase==2) implies (s.privateCopy==1 and s.payload==0 and s.inputRef==0 and s.active==0 and s.result==0),
(s.phase==3) implies (s.privateCopy==0 and s.payload==1 and s.inputRef==1 and s.active==1 and s.result==0),
(s.phase==4) implies (s.privateCopy==0 and s.payload==1 and s.inputRef==1 and s.active==0 and s.result>=1),
(s.phase==5 or s.phase==6 or s.phase==7) implies (s.privateCopy==0 and s.inputRef==0 and s.result>=1),
(s.phase==6) implies (s.active==1 and s.result==1),
(s.phase==5 or s.phase==7) implies (s.active==0),
(s.phase==7) implies (s.result==2),
(s.phase<=7) implies (s.gate==1 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==0),
(s.active==1) implies (s.phase==3 or s.phase==6),
(s.privateCopy==1) implies (s.phase==1 or s.phase==2 or s.phase==9),
(s.privateCopy==1) implies (s.code==1 and s.roots==1),
(s.payload==1) implies (s.privateCopy==0 and s.code==1 and s.roots==1),
(s.inputRef==1) implies (s.payload==1 and (s.phase==3 or s.phase==4 or s.phase==13)),
(s.captured==1) implies (s.payload==1 and s.code==1 and s.roots==1),
(s.phase==9) implies (s.privateCopy==1 and s.payload==0 and s.gate==0 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.active==0 and s.critical==0),
(s.phase==13) implies (s.gate==0 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.active==0 and s.privateCopy==0 and s.critical==0),
(s.receipt==1) implies (s.phase==8 or s.phase==10 or s.phase==11 or s.phase==12 or s.phase==14),
(s.receipt==1) implies (s.privateCopy==0 and s.inputRef==0 and s.active==0 and s.gate==0 and s.valid==0),
(s.receipt==1 and s.exitAck==0) implies (s.result==2),
(s.phase==8) implies (s.receipt==1 and s.marker==1 and s.effects==0 and s.settled==0),
(s.phase==10) implies (s.receipt==1 and s.marker==0 and s.effects==1 and s.settled==0 and s.critical==1),
(s.phase==11 or s.phase==12 or s.phase==14) implies (s.receipt==1 and s.marker==0 and s.effects==1 and s.settled==1 and s.critical==0),
(s.effects==1) implies (s.phase==10 or s.phase==11 or s.phase==12 or s.phase==14),
(s.critical==1) implies ((s.phase==8 or s.phase==10) and s.gc==0 and s.code==1 and s.roots==1 and s.reply==0),
(s.gc==1) implies (s.code==1 and s.roots==1 and s.critical==0),
(s.dtor==1 or s.dtor==2) implies (s.phase==11 and s.payload==1 and s.captured==0 and s.code==1 and s.roots==1),
(s.dtor==3) implies (s.payload==0 and s.privateCopy==0),
(s.reply==1) implies ((s.phase==8 or s.phase==11) and s.critical==0),
(s.phase==12) implies (s.roots==0 and s.code==1 and s.payload==0 and s.privateCopy==0 and s.captured==0 and s.gc==0),
(s.phase==14) implies (s.roots==0 and s.code==0 and s.payload==0 and s.privateCopy==0 and s.captured==0 and s.gc==0),
(s.phase!=12 and s.phase!=14) implies (s.code==1 and s.roots==1),
(s.code==0) implies (s.phase==14),
(s.roots==0) implies (s.phase==12 or s.phase==14),
(s.exitAck==1) implies (s.inputRef==0),
(s.exitAck==1 and s.receipt==0) implies (s.phase==13)}
action reservePrivate=all{s.phase==0 and s.gc==0,s'={...s,phase:1,privateCopy:1}}
action beginWrap=all{s.phase==1 and s.gc==0,s'={...s,phase:2}}
action wrapSuccess=all{s.phase==2 and s.gc==0,s'={...s,phase:3,privateCopy:0,payload:1,inputRef:1,active:1}}
action wrapFailureReturned=all{s.phase==2 and s.gc==0,s'={...s,phase:5,privateCopy:0,result:1,dtor:3}}
action wrapFailureUnknown=all{s.phase==2 and s.gc==0,s'={...s,phase:9,gate:0}}
action auditPrivateDisposed=all{s.phase==9 and s.gc==0,s'={...s,phase:13,privateCopy:0,dtor:3}}
action bodyBadResult=all{s.phase==3 and s.gc==0,s'={...s,phase:4,active:0,result:1}}
action bodyGoodResult=all{s.phase==3 and s.gc==0,s'={...s,phase:4,active:0,result:2}}
action captureArgument=all{s.phase==3 and s.gc==0 and s.captured==0,s'={...s,captured:1}}
action dropInputReference=all{s.phase==4 and s.gc==0,s'={...s,phase:5,inputRef:0}}
action handlerCall=all{s.phase==5 and s.result==1 and s.gc==0,s'={...s,phase:6,active:1}}
action handlerBadResult=all{s.phase==6 and s.gc==0,s'={...s,phase:5,active:0,result:1}}
action handlerGoodResult=all{s.phase==6 and s.gc==0,s'={...s,phase:5,active:0,result:2}}
action finishResult=all{s.phase==5 and s.result==2 and s.gc==0,s'={...s,phase:7}}
action signFinalUse=all{s.phase==7 and s.gc==0,s'={...s,phase:8,gate:0,valid:0,receipt:1}}
action escapeOwner=all{(s.phase==3 or s.phase==4 or s.phase==5 or s.phase==6 or s.phase==7) and s.gc==0,s'={...s,phase:13,gate:0,active:0}}
action drainInputFromGuard=all{s.phase==13 and s.inputRef==1 and s.gc==0,s'={...s,inputRef:0}}
action ackExitedOwner=all{s.phase==13 and s.inputRef==0 and s.gc==0,s'={...s,exitAck:1}}
action signEscapedUse=all{s.phase==13 and s.exitAck==1 and s.gc==0,s'={...s,phase:8,valid:0,receipt:1}}
action beginMarkerRelease=all{s.phase==8 and s.critical==0 and s.gc==0 and s.reply==0,s'={...s,critical:1}}
action markerDrop=all{s.phase==8 and s.critical==1,s'={...s,phase:10,marker:0,effects:1}}
action commitMarkerRelease=all{s.phase==10 and s.critical==1,s'={...s,phase:11,settled:1,critical:0}}
action loseReply=all{(s.phase==8 or s.phase==11) and s.reply==0 and s.critical==0,s'={...s,reply:1}}
action queryReply=all{(s.phase==8 or s.phase==11) and s.reply==1,s'={...s,reply:0}}
action dropCaptured=all{s.phase==11 and s.captured==1 and s.gc==0,s'={...s,captured:0}}
action beginDestructor=all{s.phase==11 and s.payload==1 and s.captured==0 and s.dtor==0 and s.gc==0,s'={...s,dtor:1}}
action destructorReturned=all{s.phase==11 and s.dtor==1 and s.gc==0,s'={...s,dtor:3,payload:0}}
action destructorUnknown=all{s.phase==11 and s.dtor==1 and s.gc==0,s'={...s,dtor:2}}
action beginGc=all{s.roots==1 and s.code==1 and s.critical==0 and s.gc==0,s'={...s,gc:1}}
action finishGc=all{s.gc==1,s'={...s,gc:0}}
action retireRoots=all{s.phase==11 and s.payload==0 and s.captured==0 and s.gc==0 and s.reply==0,s'={...s,phase:12,roots:0}}
action retireCode=all{s.phase==12,s'={...s,phase:14,code:0}}
action step=any{reservePrivate,beginWrap,wrapSuccess,wrapFailureReturned,wrapFailureUnknown,auditPrivateDisposed,bodyBadResult,bodyGoodResult,captureArgument,dropInputReference,handlerCall,handlerBadResult,handlerGoodResult,finishResult,signFinalUse,escapeOwner,drainInputFromGuard,ackExitedOwner,signEscapedUse,beginMarkerRelease,markerDrop,commitMarkerRelease,loseReply,queryReply,dropCaptured,beginDestructor,destructorReturned,destructorUnknown,beginGc,finishGc,retireRoots,retireCode,all{s'=s}}
run normalPayloadLifetimeTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(all{assert(s.settled==1 and s.payload==1 and s.dtor==0 and s.code==1),assert(safe),s'=s})
run cleanupBeforeRetryTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyBadResult).then(dropInputReference).then(handlerCall).then(all{assert(s.inputRef==0 and s.active==1 and s.valid==1),assert(safe),s'=s})
run repeatedTypedConversionTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyBadResult).then(dropInputReference).then(handlerCall).then(handlerBadResult).then(handlerCall).then(handlerGoodResult).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(all{assert(s.settled==1 and s.payload==1),assert(safe),s'=s})
run failureDisposedTest=init.then(reservePrivate).then(beginWrap).then(wrapFailureReturned).then(handlerCall).then(handlerGoodResult).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(retireRoots).then(retireCode).then(all{assert(s.phase==14 and s.dtor==3),assert(safe),s'=s})
run failureUnknownTest=init.then(reservePrivate).then(beginWrap).then(wrapFailureUnknown).then(all{assert(s.privateCopy==1 and s.marker==1 and s.receipt==0 and s.code==1),assert(safe),s'=s})
run failureAuditedTest=init.then(reservePrivate).then(beginWrap).then(wrapFailureUnknown).then(auditPrivateDisposed).then(ackExitedOwner).then(signEscapedUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(retireRoots).then(retireCode).then(all{assert(s.phase==14),assert(safe),s'=s})
run escapedInputRetainedTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(escapeOwner).then(all{assert(s.inputRef==1 and s.payload==1 and s.marker==1 and s.receipt==0),assert(safe),s'=s})
run escapedGuardCleanupTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(escapeOwner).then(drainInputFromGuard).then(ackExitedOwner).then(signEscapedUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(all{assert(s.inputRef==0 and s.payload==1 and s.settled==1),assert(safe),s'=s})
run capturedPayloadTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(captureArgument).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(all{assert(s.captured==1 and s.payload==1 and s.valid==0),assert(safe),s'=s})
run captureThenDestructTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(captureArgument).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(dropCaptured).then(beginDestructor).then(destructorReturned).then(retireRoots).then(retireCode).then(all{assert(s.phase==14),assert(safe),s'=s})
run unknownDestructorTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(beginDestructor).then(destructorUnknown).then(all{assert(s.payload==1 and s.dtor==2 and s.roots==1 and s.code==1),assert(safe),s'=s})
run physicalGapTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(all{assert(s.effects==1 and s.settled==0 and s.critical==1 and s.payload==1),assert(safe),s'=s})
run lostRepliesTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(loseReply).then(queryReply).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(loseReply).then(queryReply).then(all{assert(s.effects==1 and s.marker==0),assert(safe),s'=s})
run gcPayloadTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(beginGc).then(finishGc).then(beginDestructor).then(destructorReturned).then(retireRoots).then(retireCode).then(all{assert(s.phase==14),assert(safe),s'=s})
run witnessInputDropIsNotDestructorTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(captureArgument).then(bodyGoodResult).then(all{assert(s.phase==4 and s.privateCopy==0 and s.payload==1 and s.inputRef==1 and s.active==0 and s.result==2 and s.gate==1 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==0 and s.captured==1 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessCloseBeforeNativeCleanupTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(all{assert(s.phase==4 and s.privateCopy==0 and s.payload==1 and s.inputRef==1 and s.active==0 and s.result==2 and s.gate==1 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==0 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessForgetPrivateOnUnknownTest=init.then(reservePrivate).then(beginWrap).then(all{assert(s.phase==2 and s.privateCopy==1 and s.payload==0 and s.inputRef==0 and s.active==0 and s.result==0 and s.gate==1 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==0 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessEscapeWithoutInputDrainTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(escapeOwner).then(all{assert(s.phase==13 and s.privateCopy==0 and s.payload==1 and s.inputRef==1 and s.active==0 and s.result==0 and s.gate==0 and s.valid==1 and s.receipt==0 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==0 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessMarkerDropUnloadsPayloadCodeTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(all{assert(s.phase==10 and s.privateCopy==0 and s.payload==1 and s.inputRef==0 and s.active==0 and s.result==2 and s.gate==0 and s.valid==0 and s.receipt==1 and s.marker==0 and s.effects==1 and s.settled==0 and s.critical==1 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessUnknownDestructorFreesPayloadTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(beginDestructor).then(all{assert(s.phase==11 and s.privateCopy==0 and s.payload==1 and s.inputRef==0 and s.active==0 and s.result==2 and s.gate==0 and s.valid==0 and s.receipt==1 and s.marker==0 and s.effects==1 and s.settled==1 and s.critical==0 and s.captured==0 and s.dtor==1 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessDropLeafAbandonedTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(all{assert(s.phase==8 and s.privateCopy==0 and s.payload==1 and s.inputRef==0 and s.active==0 and s.result==2 and s.gate==0 and s.valid==0 and s.receipt==1 and s.marker==1 and s.effects==0 and s.settled==0 and s.critical==1 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==0),assert(safe),s'=s})
run witnessReplyReplaysMarkerDropTest=init.then(reservePrivate).then(beginWrap).then(wrapSuccess).then(bodyGoodResult).then(dropInputReference).then(finishResult).then(signFinalUse).then(beginMarkerRelease).then(markerDrop).then(commitMarkerRelease).then(loseReply).then(all{assert(s.phase==11 and s.privateCopy==0 and s.payload==1 and s.inputRef==0 and s.active==0 and s.result==2 and s.gate==0 and s.valid==0 and s.receipt==1 and s.marker==0 and s.effects==1 and s.settled==1 and s.critical==0 and s.captured==0 and s.dtor==0 and s.code==1 and s.roots==1 and s.gc==0 and s.exitAck==0 and s.reply==1),assert(safe),s'=s})
}
