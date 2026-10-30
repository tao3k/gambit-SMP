// Source-shaped two-node litmus: old A was consumed; new B is the one sender.
// This is NOT a complete ARM memory model or proof of the observed first writer.
// The weak profile permits an unrefreshed tail observation after ticket grant.
module result_mutex_ticket_visibility {
  type State={acquireAfterGrant:bool,casEntry:bool,phase:int,head:int,tail:int,
    nextA:int,nextB:int,cached:bool,seenTail:int,oldPopped:bool,granted:bool,
    waiting:bool,claimedB:bool,thunkB:bool}
  var s:State
  pure def initial(a:bool,c:bool):State={acquireAfterGrant:a,casEntry:c,phase:0,
    head:1,tail:1,nextA:0,nextB:0,cached:false,seenTail:0,oldPopped:false,
    granted:false,waiting:false,claimedB:false,thunkB:false}
  action initNoAcquire=s'=initial(false,false)
  action initAcquireAfterWait=s'=initial(true,false)
  action initSuccessfulTrylock=s'=initial(true,true)
  action reserveTicket=all{s.phase==0,s'={...s,phase:1}}
  // A protected data read is not forced to observe the predecessor's release
  // without a grant-completion acquire. This is the explicit weak premise.
  action observeOldTail=all{s.phase==1,not(s.cached),not(s.oldPopped),
    s'={...s,cached:true,seenTail:s.tail}}
  // Exact get-next last-node assignments: head=null; A.next=null; tail=null.
  action popOldA=all{s.phase==1,not(s.oldPopped),
    s'={...s,head:s.nextA,nextA:0,tail:0,oldPopped:true}}
  action acceptGrant=all{s.phase==1,s.oldPopped,
    s'={...s,phase:2,granted:true,
      seenTail:if(s.acquireAfterGrant or not(s.cached)) s.tail else s.seenTail}}
  // Exact raise-high-level assignments, split to expose which old value is used.
  action clearNextB=all{s.phase==2,s'={...s,phase:3,nextB:0}}
  action publishTailB=all{s.phase==3,s'={...s,phase:4,tail:2}}
  action linkB=all{s.phase==4,s'={...s,phase:5,
    head:if(s.seenTail==0) 2 else s.head,
    nextA:if(s.seenTail==1) 2 else s.nextA}}
  action senderSecondLock=all{s.phase==5,s'={...s,phase:6,waiting:true}}
  action claimB=all{s.phase==6,s.head==2,not(s.claimedB),
    s'={...s,head:0,tail:0,claimedB:true}}
  action executeB=all{s.phase==6,s.claimedB,not(s.thunkB),
    s'={...s,thunkB:true,waiting:false}}
  val done=s.thunkB
  val stranded=s.waiting and not(s.thunkB) and s.head==0 and s.tail==2 and
    s.nextA==2 and not(s.claimedB)
  val noLost=not(stranded)
  action step=any{reserveTicket,observeOldTail,popOldA,acceptGrant,clearNextB,
    publishTailB,linkB,senderSecondLock,claimB,executeB,
    all{done or stranded,s'=s}}
  temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
