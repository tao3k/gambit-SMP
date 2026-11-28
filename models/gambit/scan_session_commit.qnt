// Conditional diagnostic protocol, not the current C implementation.
// Two setup attempts, two one-use slots and two publications. No native admission.
module scan_session_commit {
  type State = {
    mode:int, bug:int, epoch:int, phase:int, seen:bool, mapping:bool, opened:bool,
    used:Set[int], ready:Set[int], counts:int->int, cap:bool, localEpoch:int,
    attached:bool, prepares:int, reentered:bool, rejected:bool, coverage:bool,
    seq:int, footer:int, commit:int, a:int, b:int, prevOk:bool,
    pub:int, tx:int, stage:int, pending:int, selected:int, token:int, tokenStage:int,
    closedDuring:bool, crashed:bool, fired:bool, certified:bool,
    read:bool, accepted:bool, finished:bool
  }
  var s:State
  pure def initial(mode:int,bug:int):State = {
    mode:mode,bug:bug,epoch:0,phase:0,seen:false,mapping:false,opened:false,
    used:Set(),ready:Set(),counts:Map(0->0,1->0),cap:false,localEpoch:0,
    attached:false,prepares:0,reentered:false,rejected:false,coverage:true,
    seq:0,footer:0,commit:0,a:0,b:0,prevOk:false,pub:0,tx:0,stage:0,
    pending:0,selected:0,token:0,tokenStage:0,closedDuring:false,
    crashed:false,fired:false,certified:false,read:false,accepted:false,finished:false
  }
  action initTwoOwners=s'=initial(0,0)
  action initSetupRetry=s'=initial(1,0)
  action initPartialClaim=s'=initial(2,0)
  action initSetupReentry=s'=initial(3,0)
  action initCut5=s'=initial(4,0)
  action initRefusedCut=s'=initial(5,0)
  action initCloseInflight=s'=initial(6,0)
  action initRepeatSetup=s'=initial(7,0)
  action initExhaustion=s'=initial(8,0)
  action initStaleToken=s'=initial(9,0)
  action initPrepareFailure=s'=initial(10,0)
  action initPreparingReentry=s'=initial(11,0)
  action initOwnerSetupFailure=s'=initial(12,0)
  action initBeforePrepareFailure=s'=initial(13,0)
  action initLocalRetry=s'=initial(14,0)
  action initResetSession=s'=initial(1,1)
  action initReclaimSlot=s'=initial(2,2)
  action initReenterPrepare=s'=initial(3,3)
  action initMixedCut5=s'=initial(4,4)
  action initUncommittedCut=s'=initial(5,5)
  action initOldToken=s'=initial(9,5)
  action initTokenBeforeFooter=s'=initial(6,6)
  action initOldAttachment=s'=initial(7,7)
  action initNestedWriter=s'=initial(0,8)
  action initClaimBeforeReady=s'=initial(2,9)
  action initLocalStaleCapability=s'=initial(14,10)

  val alive=not(s.finished) and not(s.crashed) and not(s.fired)
  val complete=s.commit>0 and s.footer==s.commit
  action beginSetup=all {alive,s.phase==0,s.epoch<2,s.pub==0,
    s'={...s,epoch:s.epoch+1,phase:1,seen:true,opened:false,
      cap:false,attached:false,localEpoch:0,pending:0,token:0}}
  action prepare=all {alive,s.phase==1,(s.mode!=11 or s.reentered),
    not(s.mode==13 and s.epoch==1),
    s'={...s,phase:2,mapping:not(Set(10,13).contains(s.mode)),
      opened:(s.epoch==1 or s.bug==1) and not(Set(10,13).contains(s.mode)),
      prepares:if(s.epoch==1) s.prepares+1 else s.prepares}}
  action reenterPrepare=all {alive,
    (s.mode==3 and s.phase==2) or (s.mode==11 and s.phase==1),not(s.reentered),
    s'={...s,reentered:true,rejected:s.bug!=3,
      prepares:if(s.bug==3) s.prepares+1 else s.prepares}}
  action failSetup=all {alive,s.epoch==1,
    (Set(1,10).contains(s.mode) and s.phase==2) or
    (s.mode==2 and s.phase==2 and s.used.contains(0) and not(s.ready.contains(0))) or
    (s.mode==12 and s.phase==2 and s.ready.contains(0)),
    s'={...s,phase:0,opened:false,cap:false,attached:false}}
  action failBeforePrepare=all {alive,s.mode==13,s.epoch==1,s.phase==1,
    s'={...s,phase:0,opened:false,cap:false,attached:false}}
  action claim=all {alive,s.phase==2,s.epoch==1,s.opened,
    s.mode!=1,(s.mode!=3 or s.reentered),
    nondet id=Set(0,1).oneOf()
    all {not(s.used.contains(id)),id==0 or (Set(0,14).contains(s.mode) and s.ready.contains(0)),
      s'={...s,used:s.used.union(Set(id)),counts:s.counts.set(id,s.counts.get(id)+1)}}}
  action ready=all {alive,s.phase==2,s.epoch==1,
    nondet id=Set(0,1).oneOf()
    all {s.used.contains(id),not(s.ready.contains(id)),s.mode!=2,
      s'={...s,ready:s.ready.union(Set(id)),cap:s.cap or id==0,
        localEpoch:if(id==0) s.epoch else s.localEpoch}}}
  action attach=all {alive,s.phase==2,not(Set(12,14).contains(s.mode)),s.opened,s.cap,s.localEpoch==s.epoch,
    s.ready.contains(0),(s.mode!=0 or s.ready.contains(1)),
    s'={...s,phase:3,attached:true}}
  action cleanSetup=all {alive,s.mode==7,s.phase==3,s.epoch==1,
    s'={...s,phase:0,opened:false,cap:false,attached:false}}
  action refusedSetup=all {alive,s.phase==2,s.epoch==2,not(s.opened),s.bug!=2,s.bug!=7,
    s'={...s,rejected:true,finished:true}}
  action endReentry=all {alive,Set(3,11).contains(s.mode),s.phase==3,s.rejected,
    s'={...s,finished:true}}
  action badReclaim=all {alive,s.bug==2,s.phase==2,s.epoch==2,
    s'={...s,counts:s.counts.set(0,s.counts.get(0)+1)}}
  action badOldAttach=all {alive,s.bug==7,s.phase==2,s.epoch==2,s.mapping,
    s'={...s,attached:true,cap:true,localEpoch:1}}
  action badClaimReady=all {alive,s.bug==9,s.phase==2,s.used.contains(0),
    not(s.ready.contains(0)),s'={...s,attached:true,cap:true,localEpoch:s.epoch}}
  action localFailureRetry=all {alive,s.mode==14,s.phase==2,
    s.ready==Set(0,1),not(s.rejected),
    s'={...s,rejected:true,cap:s.bug==10,attached:s.bug==10,
      localEpoch:if(s.bug==10) s.localEpoch else 0}}
  action localRetryRefused=all {alive,s.mode==14,s.rejected,not(s.cap),
    s'={...s,finished:true}}

  action arm=all {alive,s.phase==3,s.attached,s.opened,s.coverage,s.pending==0,
    s.pub==0,s.mode!=3,s.mode!=7,
    (s.mode!=4 and s.mode!=9) or s.seq==1,
    s'={...s,pending:if(s.mode==4) 5 else if(s.mode==0 or s.mode==9) 2 else 1}}
  action refuseAfterArm=all {alive,s.phase==3,s.pub==0,s.pending>0,
    Set(5,8,9).contains(s.mode),not(s.rejected),
    s'={...s,opened:false,coverage:false,rejected:true,
      seq:if(s.mode==8) 2 else s.seq}}
  action declinedPublication=all {alive,s.phase==3,s.pub==0,s.pending>0,
    not(s.opened) or not(s.coverage) or s.seq==2,
    s'={...s,pending:0,token:if(s.bug==5) s.token else 0,finished:s.bug!=5,
      fired:s.bug==5,certified:false}}
  action endScanUnmatched=all {alive,s.mode==0,s.pub==0,s.seq==1,s.pending==2,
    s'={...s,pending:0,token:0,finished:true}}
  action startPublication=all {alive,s.phase==3,s.pub==0,s.opened,s.coverage,s.seq<2,
    (s.mode==4 or s.mode==9) and s.seq==0 or
      (s.pending>0 and not(Set(5,8,9).contains(s.mode))),
    val nextStage=if(s.mode==0 and s.seq==1) 2 else if(s.mode==9 and s.seq==1) 2 else 1
    s'={...s,pub:1,tx:s.seq+1,seq:s.seq+1,stage:nextStage,token:0,
      prevOk:if(complete) s.a==s.commit and s.b==s.commit else s.prevOk,
      selected:if(s.pending>=3 or s.pending==nextStage) s.pending else 0,
      pending:if(s.pending>=3 or s.pending==nextStage) 0 else s.pending}}
  action nestedWriter=all {alive,s.mode==0,s.pub==1,not(s.reentered),
    s'={...s,reentered:true,rejected:s.bug!=8,
      tx:if(s.bug==8) s.tx+1 else s.tx}}
  action closeInflight=all {alive,s.mode==6,s.pub==1,not(s.closedDuring),
    s'={...s,opened:false,closedDuring:true}}
  action invalidate=all {alive,s.pub==1,(s.mode!=0 or s.reentered),
    (s.mode!=6 or s.closedDuring),
    s'={...s,pub:2,footer:if(s.bug==4) s.footer else 0}}
  action payloadPrefix=all {alive,s.pub==2,s'={...s,pub:3,a:s.tx}}
  action cut5=all {alive,s.pub==3,s.selected==5,
    s'={...s,crashed:true}}
  action payloadRest=all {alive,s.pub==3,s.selected!=5,
    s'={...s,pub:4,b:s.tx}}
  action commitWord=all {alive,s.pub==4,s'={...s,pub:5,commit:s.tx}}
  action earlyFault=all {alive,s.bug==6,s.pub==5,
    s'={...s,token:s.tx,fired:true,certified:false}}
  action footer=all {alive,s.pub==5,s'={...s,pub:6,footer:s.tx}}
  action commitReceipt=all {alive,s.pub==6,
    s'={...s,pub:0,token:s.tx,tokenStage:s.stage}}
  action fault=all {alive,s.pub==0,s.token>0,
    Set(1,2).contains(s.selected),s.selected==s.tokenStage,
    s'={...s,fired:true,certified:s.token==s.tx and s.footer==s.tx and
      s.commit==s.tx and s.a==s.tx and s.b==s.tx}}
  action readAfterFault=all {(s.crashed or s.fired),not(s.read),
    s'={...s,read:true,accepted:complete}}
  action idle= s'=s
  action step=any {beginSetup,prepare,reenterPrepare,failSetup,failBeforePrepare,claim,ready,attach,
    cleanSetup,refusedSetup,endReentry,badReclaim,badOldAttach,badClaimReady,
    localFailureRetry,localRetryRefused,arm,refuseAfterArm,
    declinedPublication,endScanUnmatched,startPublication,nestedWriter,closeInflight,invalidate,
    payloadPrefix,cut5,payloadRest,commitWord,earlyFault,footer,commitReceipt,
    fault,readAfterFault,idle}

  val safe=all {
    s.prepares<=1,
    s.counts.get(0)<=1 and s.counts.get(1)<=1,
    not(s.opened) or s.epoch==1,
    not(s.attached) or (s.cap and s.localEpoch==s.epoch and s.ready.contains(0)),
    not(s.mode==14 and s.rejected) or (not(s.cap) and not(s.attached)),
    s.pub==0 or s.tx==s.seq,
    not(s.fired) or s.certified,
    not(s.read and s.accepted) or (s.a==s.commit and s.b==s.commit)
  }
}
