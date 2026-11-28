module collector_ticket_claim {
  type State={serving:int,head:int,queuedView:int,phase:int,claims:List[int]}
  var t:State
  action init=t'={serving:0,head:0,queuedView:0,phase:0,claims:[]}
  action firstClaim=all{t.phase==0,
    t'={...t,claims:t.claims.append(t.head),head:t.head+1,phase:1}}
  action release=all{t.phase==1,t'={...t,serving:1,phase:2}}
  // Legacy volatile waiting does not invalidate a speculative protected read.
  action legacyAcquire=all{t.serving==1,t.phase==2,t'={...t,phase:3}}
  action acquireRead=all{t.serving==1,t.phase==2,
    t'={...t,queuedView:t.head,phase:3}}
  action secondClaim=all{t.phase==3,
    t'={...t,claims:t.claims.append(t.queuedView),phase:4}}
  def unique:bool=t.claims.indices().forall(i=>t.claims.indices().forall(j=>
    i==j or t.claims.nth(i)!=t.claims.nth(j)))
  run missingAcquireCounterexampleTest=init.then(firstClaim).then(release)
    .then(legacyAcquire).then(secondClaim).expect(not(unique) and t.claims==[0,0])
  run acquireReadsPublishedHeadTest=init.then(firstClaim).then(release)
    .then(acquireRead).then(secondClaim).expect(unique and t.claims==[0,1])
  run noAcquireBeforeReleaseTest=init.then(firstClaim).expect(t.serving==0 and t.phase==1)
}

