module rest_gc_resume_envelope {
  // Bounded design histories: p=2, a=5, r=4, first crossing after k=1.
  // 15 words = 4 no-handle pairs + 3-word carrier. Destination 20 is a
  // deliberately abstract backing envelope, not a measured Gambit section.
  type State={phase:int,built:int,remaining:int,hp:int,end:int,carrier:bool,
    framed:bool,root:bool,fromLive:bool,toLive:bool,forwarded:bool,
    committed:bool,known:bool,entry:bool,captured:bool,lease:bool,
    deadProved:bool,reclaimed:bool,quarantine:bool,q:int,fresh:int,peak:int,floor:int}
  var s:State
  pure def occ(t:State):int=(if(t.fromLive)15 else 0)+(if(t.toLive)20 else 0)+2+t.fresh
  pure def record(t:State):State={...t,peak:if(t.peak>occ(t))t.peak else occ(t),
    floor:if(t.floor>occ(t))t.floor else occ(t)}
  action init=s'={phase:0,built:0,remaining:4,hp:0,end:15,carrier:false,
    framed:false,root:false,fromLive:true,toLive:false,forwarded:false,
    committed:false,known:false,entry:false,captured:false,lease:true,
    deadProved:false,reclaimed:false,quarantine:false,q:0,fresh:0,peak:17,floor:17}
  val safe=s.hp<=s.end and s.hp>=0 and s.built+s.remaining==4 and
    s.hp==3*s.built+(if(s.carrier)3 else 0) and s.peak>=occ(s) and s.peak>=s.floor and
    (not(s.forwarded) or (s.framed and s.root and s.toLive)) and
    (not(s.entry) or (s.committed and s.known and s.phase==4)) and
    (not(s.reclaimed) or (s.deadProved and not(s.captured) and not(s.lease))) and
    (not(s.quarantine) or (s.fromLive and s.toLive and not(s.entry))) and
    (s.q==0 or (s.q==4 and s.toLive and s.fresh==0)) and
    (s.phase!=1 or s.hp+3*s.remaining+3<=s.end)
  action crossing=all{s.phase==0,s'= {...s,phase:1,built:1,remaining:3,hp:3}}
  action completeOne=all{s.phase==1,s.remaining>0,
    s'={...s,built:s.built+1,remaining:s.remaining-1,hp:s.hp+3}}
  action publishCarrier=all{s.phase==1,s.remaining==0,
    s'={...s,phase:2,hp:s.hp+3,carrier:true,framed:true,root:true}}
  action acquireQg=all{s.phase==2,not(s.toLive),s'=record({...s,toLive:true,q:4})}
  action acquireFresh=all{s.phase==2,not(s.toLive),s'=record({...s,toLive:true,fresh:4})}
  action forward=all{s.phase==2,s.framed,s.root,s.toLive,
    s'={...s,phase:3,forwarded:true}}
  action commitUnknown=all{s.phase==3,s'={...s,committed:true,known:false}}
  action readBack=all{s.phase==3,s.committed,s'={...s,known:true}}
  action resumeToFirstPoll=all{s.phase==3,s.known,s.committed,
    s'={...s,phase:4,entry:true}}
  action capture=all{s.phase==4,s'={...s,captured:true}}
  action detachRoot=all{s.phase==4,s'={...s,entry:false,phase:5}}
  // root remains a GC-visible history root in this abstraction after forwarding.
  // Lexical detachment is not a last-alias proof or an object free.
  action proveDead=all{s.phase==5,not(s.captured),s'={...s,deadProved:true}}
  action drainReaders=all{s.phase==5,s'={...s,lease:false}}
  action reclaim=all{s.phase==5,s.deadProved,not(s.captured),not(s.lease),
    s'={...s,reclaimed:true}}
  action lateRefund=all{s.phase==4,s.fresh==4,s'={...s,fresh:0}}
  action failAfterForward=all{s.phase==3,s'={...s,quarantine:true,phase:9}}
  action refuse=all{s.phase==0,s'={...s,phase:8}}
  action stutter=s'=s
  action step=any{crossing,completeOne,publishCarrier,acquireQg,acquireFresh,
    forward,commitUnknown,readBack,resumeToFirstPoll,capture,detachRoot,
    proveDead,drainReaders,reclaim,lateRefund,failAfterForward,refuse,stutter}
  action finish=completeOne.then(completeOne).then(completeOne).then(publishCarrier)
  action collect=forward.then(commitUnknown).then(readBack).then(resumeToFirstPoll)
  action ready= crossing.then(finish).then(acquireQg).then(collect)
  run completionAndResumeTest=init.then(ready).expect(safe and s.hp==15 and s.peak==37)
  run exactSuffixTest=init.then(crossing).expect(safe and s.hp+3*s.remaining+3==15)
  run zeroHeapRestoreTest=init.then(ready).expect(safe and s.hp==15 and s.entry)
  run unknownCustodyTest=init.then(crossing).then(finish).then(acquireQg).then(forward)
    .then(commitUnknown).expect(safe and s.fromLive and s.toLive and not(s.entry))
  run afterForwardFailureTest=init.then(crossing).then(finish).then(acquireQg).then(forward)
    .then(failAfterForward).expect(safe and s.quarantine)
  run capturedCarrierTest=init.then(ready).then(capture).then(detachRoot)
    .expect(safe and s.captured and not(s.reclaimed))
  run deadAndDrainedTest=init.then(ready).then(detachRoot).then(proveDead)
    .then(drainReaders).then(reclaim).expect(safe and s.reclaimed)
  run lateRefundTest=init.then(crossing).then(finish).then(acquireFresh).then(collect)
    .then(lateRefund).expect(safe and s.peak==41 and occ(s)==37)
  run refusalTest=init.then(refuse).expect(safe and not(s.forwarded))
  run smallCompletionControlTest=init.then(crossing).then(s'={...s,end:14}).expect(not(safe))
  run earlyGcControlTest=init.then(crossing).then(s'={...s,forwarded:true,toLive:true})
    .expect(not(safe))
  run unknownResumeControlTest=init.then(crossing).then(finish).then(acquireQg).then(forward)
    .then(commitUnknown).then(s'={...s,entry:true,phase:4}).expect(not(safe))
  run carrierFreeControlTest=init.then(ready).then(capture).then(detachRoot)
    .then(s'={...s,reclaimed:true}).expect(not(safe))
  run doubleCreditControlTest=init.then(ready).then(s'={...s,fresh:4}).expect(not(safe))
  run lostInitializerControlTest=init.then(crossing).then(finish).then(acquireQg).then(forward)
    .then(s'={...s,toLive:false}).expect(not(safe))
  run peakRewriteControlTest=init.then(crossing).then(finish).then(acquireFresh).then(collect)
    .then(lateRefund).then(s'={...s,peak:occ(s)}).expect(not(safe))
  // Ghost floor preserves the historical maximum; it is not runtime metadata.
}
