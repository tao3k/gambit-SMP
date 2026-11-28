module saved_result_retirement {
// A saved token, B old-current disposal, C a protected reentrant publication.
// Managed interception and authoritative backend ACKs are refinement premises.
type State={a:int,b:int,c:int,complete:int,observerGate:int,observer:int,issuer:int,recordLive:int,generation:int}
pure val initial:State={a:0,b:0,c:0,complete:0,observerGate:1,observer:0,issuer:1,recordLive:1,generation:1}
var s:State
action init=s'=initial
val safe=all{s.a>=0,s.b>=0,s.c>=0,s.complete>=0,s.observerGate>=0,s.observer>=0,s.issuer>=0,s.recordLive>=0,s.generation>=0,s.a<=6,s.b<=4,s.c<=4,s.complete<=1,s.observerGate<=1,s.observer<=1,s.issuer<=1,s.recordLive<=1,s.generation<=2,s.generation>=1,s.a==0 implies all{s.b==0,s.c==0},s.a==1 implies s.c==0,s.a==2 implies s.b>=2,s.a==3 implies all{s.b==4,(s.c==0 or s.c==4)},s.a>=4 and s.a<=6 implies all{(s.b==0 or s.b==4),(s.c==0 or s.c==4)},s.c>=1 implies s.b>=2,s.observer==1 implies s.recordLive==1,s.observerGate==1 implies s.recordLive==1,s.recordLive==0 implies all{s.complete==1,s.a==6,(s.b==0 or s.b==4),(s.c==0 or s.c==4),s.observerGate==0,s.observer==0,s.issuer==0},s.issuer==0 implies all{s.complete==1,s.a==6,(s.b==0 or s.b==4),(s.c==0 or s.c==4)}}
action saveA=all{s.a==0,s'={...s,a:1}}
action installB=all{s.a==1 and s.b==0,s'={...s,b:1}}
action beginRestore=all{s.a==1 and s.b==1,s'={...s,a:2,b:2}}
action reenterPublishC=all{s.a==2 and s.b==2 and s.c==0,s'={...s,c:1}}
action loseB=all{s.b==2,s'={...s,b:3}}
action ackB=all{(s.b==2 or s.b==3),s'={...s,b:4}}
action beginCRelease=all{s.c==1,s'={...s,c:2}}
action loseC=all{s.c==2,s'={...s,c:3}}
action ackC=all{(s.c==2 or s.c==3),s'={...s,c:4}}
action commitRestore=all{s.a==2 and s.b==4 and (s.c==0 or s.c==4),s'={...s,a:3}}
action beginDiscard=all{s.a==1 and s.b==0,s'={...s,a:4}}
action beginRestoredRelease=all{s.a==3,s'={...s,a:4}}
action loseA=all{s.a==4,s'={...s,a:5}}
action ackA=all{(s.a==4 or s.a==5),s'={...s,a:6}}
action completeFirst=all{s.generation==1 and s.issuer==1 and s.complete==0,s'={...s,complete:1}}
action completeSecond=all{s.generation==2 and s.issuer==1 and s.complete==0,s'={...s,complete:1}}
action lookupRecord=all{s.observerGate==1 and s.recordLive==1 and s.observer==0,s'={...s,observer:1}}
action returnRecord=all{s.observer==1,s'={...s,observer:0}}
action closeObserverGate=all{s.observerGate==1,s'={...s,observerGate:0}}
action closeIssuer=all{s.complete==1 and s.a==6 and (s.b==0 or s.b==4) and (s.c==0 or s.c==4) and s.issuer==1,s'={...s,issuer:0}}
action retireRecord=all{s.complete==1 and s.a==6 and (s.b==0 or s.b==4) and (s.c==0 or s.c==4) and s.observerGate==0 and s.observer==0 and s.issuer==0 and s.recordLive==1,s'={...s,recordLive:0}}
action reuseSlot=all{s.recordLive==0 and s.generation==1,s'={...s,a:0,b:0,c:0,complete:0,observerGate:1,issuer:1,recordLive:1,generation:2}}
action step=any{saveA,installB,beginRestore,reenterPublishC,loseB,ackB,beginCRelease,loseC,ackC,commitRestore,beginDiscard,beginRestoredRelease,loseA,ackA,completeFirst,completeSecond,lookupRecord,returnRecord,closeObserverGate,closeIssuer,retireRecord,reuseSlot,all{s'=s}}
run restoreTest=init.then(saveA).then(installB).then(beginRestore).then(ackB).then(commitRestore).then(beginRestoredRelease).then(ackA).then(completeFirst).then(closeObserverGate).then(closeIssuer).then(retireRecord).then(all{assert(safe),s'=s})
run discardTest=init.then(saveA).then(beginDiscard).then(ackA).then(completeFirst).then(closeObserverGate).then(closeIssuer).then(retireRecord).then(all{assert(safe),s'=s})
run reentrantTest=init.then(saveA).then(installB).then(beginRestore).then(reenterPublishC).then(ackB).then(beginCRelease).then(ackC).then(commitRestore).then(beginRestoredRelease).then(ackA).then(completeFirst).then(closeIssuer).then(closeObserverGate).then(retireRecord).then(all{assert(safe),s'=s})
run unknownRestoreTest=init.then(saveA).then(installB).then(beginRestore).then(loseB).then(completeFirst).then(all{assert(safe),s'=s})
run unknownDiscardTest=init.then(saveA).then(beginDiscard).then(loseA).then(completeFirst).then(all{assert(safe),s'=s})
run lateObserverTest=init.then(saveA).then(installB).then(beginRestore).then(ackB).then(commitRestore).then(beginRestoredRelease).then(ackA).then(lookupRecord).then(completeFirst).then(closeObserverGate).then(closeIssuer).then(returnRecord).then(retireRecord).then(reuseSlot).then(completeSecond).then(all{assert(safe),s'=s})
}
