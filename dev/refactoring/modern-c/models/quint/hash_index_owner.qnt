// Existing contract extended with the observed GC/cursor counterexample.
// Two keys, one reader, two layouts/addresses. No concurrent writer/liveness
// claim, C pointer proof, or duplicate Lean scheduler is introduced.
module hash_index_owner {
  type State = {scheme:bool, address:int, semantic:int, placement:int,
    frozen:bool, debt:bool, addressDebt:bool, callbackInGC:bool,
    looked:bool, linear:bool, layout:int, reader:bool, readLayout:int,
    cursor:int, seen:Set[int], duplicate:bool,
    building:bool, constructionRoot:bool, installed:bool, slotAddress:int}
  var s:State
  pure def fresh(scheme:bool):State={scheme:scheme,address:0,semantic:0,
    placement:0,frozen:false,debt:false,addressDebt:false,
    callbackInGC:false,looked:false,linear:false,layout:0,reader:false,
    readLayout:0,cursor:0,seen:Set(),duplicate:false,
    building:false,constructionRoot:true,installed:false,slotAddress:0}
  action init={nondet owner=Set(false,true).oneOf();s'=fresh(owner)}
  action freeze=all{not(s.frozen),s'={...s,frozen:true,looked:false}}
  // Reference repair changes addresses, never physical slot order.
  action relocate=all{s.frozen,s'={...s,address:1-s.address,
    slotAddress:if(s.installed and (not(s.building) or s.constructionRoot))
      1-s.address else s.slotAddress,
    addressDebt:if(s.scheme) false else true}}
  action repairStable=all{s.frozen,s'=s}
  action resume=all{s.frozen,s'={...s,frozen:false}}
  // Existing deserialize debt is distinct from KEY_MOVED and survives GC.
  action deserialize=all{not(s.frozen),not(s.reader),s'={...s,debt:true,looked:false}}
  // Exclusivity is a caller precondition, not an implemented C reader lock.
  // union/find is a writer even for find=true (path compression).
  action ownedRebuild=all{not(s.frozen),not(s.reader),not(s.building),s.debt or s.addressDebt,
    s'={...s,debt:false,addressDebt:false,looked:false,layout:1-s.layout,
      placement:if(s.scheme) s.semantic else s.address}}
  action lookup=all{not(s.frozen),not(s.debt),not(s.building),
    s'={...s,looked:true,linear:not(s.scheme) and s.addressDebt}}
  action beginRead=all{not(s.frozen),not(s.reader),not(s.debt),not(s.building),
    s'={...s,reader:true,readLayout:s.layout,cursor:0,seen:Set(),duplicate:false}}
  action visit=all{s.reader,not(s.frozen),s.cursor<2,
    val key=if(s.layout==0)s.cursor else 1-s.cursor;
    s'={...s,cursor:s.cursor+1,seen:s.seen.union(Set(key)),
      duplicate:s.duplicate or key.in(s.seen)}}
  action finishRead=all{s.reader,not(s.frozen),s.cursor==2,s'={...s,reader:false}}
  // One representative installed heap key. Its external root remains live;
  // before commit, both decoders must also repair the construction slot.
  action beginConstruction=all{not(s.frozen),not(s.reader),not(s.building),
    s'={...s,building:true,constructionRoot:true,installed:false,looked:false}}
  action installKey=all{s.building,not(s.frozen),not(s.installed),
    s'={...s,installed:true,slotAddress:s.address}}
  action commitConstruction=all{s.building,not(s.frozen),s.installed,
    s'={...s,building:false,debt:true,looked:false}}
  action step=any{freeze,relocate,repairStable,resume,deserialize,ownedRebuild,
    lookup,beginRead,visit,finishRead,beginConstruction,installKey,
    commitConstruction,s'=s}
  val safe=all{not(s.callbackInGC),not(s.duplicate),s.cursor==s.seen.size(),
    s.installed implies s.slotAddress==s.address,
    s.reader implies s.layout==s.readLayout,
    s.scheme implies not(s.addressDebt),
    not(s.debt) and not(s.addressDebt) implies
      s.placement==(if(s.scheme)s.semantic else s.address),
    s.looked implies all{not(s.frozen),not(s.debt),
      s.addressDebt implies s.linear,
      not(s.linear) implies s.placement==(if(s.scheme)s.semantic else s.address)}}
  action check=all{safe,s'=s}
  run schemeSurvivesGCTest=init.then(s'=fresh(true)).then(freeze).then(relocate)
    .then(resume).then(lookup).then(check)
  run nativeDeferredReadTest=init.then(s'=fresh(false)).then(freeze).then(relocate)
    .then(resume).then(lookup).expect(safe and s.linear and s.addressDebt)
  run nativeWriterRebuildTest=init.then(s'=fresh(false)).then(freeze).then(relocate)
    .then(resume).then(ownedRebuild).then(lookup)
    .expect(safe and not(s.linear) and not(s.addressDebt))
  run stableKeyNoDebtTest=init.then(s'=fresh(false)).then(freeze).then(repairStable)
    .then(resume).then(lookup).expect(safe and not(s.linear) and not(s.addressDebt))
  run debtSurvivesGCTest=init.then(s'=fresh(true)).then(deserialize).then(freeze)
    .then(relocate).then(resume).then(ownedRebuild).then(lookup).then(check)
  run movingCursorTest=init.then(s'=fresh(false)).then(beginRead).then(visit)
    .then(freeze).then(relocate).then(resume).then(lookup).then(visit)
    .then(finishRead).expect(safe and s.seen==Set(0,1) and s.linear)
  run stableCursorTest=init.then(s'=fresh(false)).then(beginRead).then(visit)
    .then(freeze).then(repairStable).then(resume).then(visit).then(finishRead)
    .expect(safe and s.seen==Set(0,1))
  run writerAfterReaderTest=init.then(s'=fresh(false)).then(beginRead).then(visit)
    .then(freeze).then(relocate).then(resume).then(visit).then(finishRead)
    .then(ownedRebuild).then(lookup).expect(safe and not(s.addressDebt))
  run partialConstructionGCTest=init.then(s'=fresh(false))
    .then(beginConstruction).then(installKey).then(freeze).then(relocate)
    .then(resume).then(commitConstruction).then(ownedRebuild).then(lookup)
    .expect(safe and s.installed and not(s.building))
  run constructionBeforeFirstStoreGCTest=init.then(s'=fresh(true))
    .then(beginConstruction).then(freeze).then(relocate).then(resume)
    .then(installKey).then(freeze).then(relocate).then(resume)
    .then(commitConstruction).then(ownedRebuild).then(lookup).expect(safe)
  action legacyBeginConstruction=all{not(s.frozen),not(s.reader),not(s.building),
    s'={...s,building:true,constructionRoot:false,installed:false,looked:false}}
  action legacyConstructionStep=any{legacyBeginConstruction,installKey,
    freeze,relocate,resume,commitConstruction,s'=s}
  run unscannedConstructionCounterexampleTest=init.then(s'=fresh(false))
    .then(legacyBeginConstruction).then(installKey).then(freeze).then(relocate)
    .expect(not(safe) and s.slotAddress!=s.address)
  // Old eager GC can maintain hash validity and still invalidate a cursor.
  action legacyEagerRelocate=all{s.frozen,not(s.scheme),
    s'={...s,address:1-s.address,placement:1-s.address,
      addressDebt:false,layout:1-s.layout}}
  action legacyStableReorder=all{s.frozen,not(s.scheme),s'={...s,layout:1-s.layout}}
  action legacyStep=any{beginRead,visit,freeze,legacyEagerRelocate,
    legacyStableReorder,resume,finishRead,s'=s}
  run eagerCursorCounterexampleTest=init.then(s'=fresh(false)).then(beginRead)
    .then(visit).then(freeze).then(legacyEagerRelocate).then(resume).then(visit)
    .expect(s.duplicate and not(safe) and s.placement==s.address)
  run stableCursorCounterexampleTest=init.then(s'=fresh(false)).then(beginRead)
    .then(visit).then(freeze).then(legacyStableReorder).then(resume).then(visit)
    .expect(s.duplicate and not(safe) and s.placement==s.address)
  action wrongNativeRehash={s'={...fresh(true),address:1,placement:1}}
  action callbackInCollector={s'={...fresh(true),frozen:true,callbackInGC:true}}
  action readWithDebt={s'={...fresh(true),debt:true,looked:true}}
  action lostOwner={s'={...fresh(false),address:1,placement:0}}
  run algorithmOwnerControlTest=init.then(wrongNativeRehash).expect(not(safe))
  run collectorCallbackControlTest=init.then(callbackInCollector).expect(not(safe))
  run deserializeReadControlTest=init.then(readWithDebt).expect(not(safe))
  run missingAddressDebtControlTest=init.then(lostOwner).expect(not(safe))
}
