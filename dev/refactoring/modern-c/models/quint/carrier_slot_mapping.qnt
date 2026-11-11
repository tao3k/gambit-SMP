module carrier_slot_mapping {
 // Fixed descriptor and lookup identities; physical slot aliasing differs from value equality.
 type State={alias:int,d0:int,d1:int,mem0:int,mem1:int,store0:int,store1:int,lookup0:int,lookup1:int,borrow0:int,borrow1:int,gc:int,round:int,m0:int,m1:int,task0:int,task1:int,updated0:int,updated1:int,word0:int,word1:int,processors:int,rejected:int}
 pure val initial:State={alias:1,d0:2,d1:0,mem0:1,mem1:0,store0:1,store1:0,lookup0:0,lookup1:0,borrow0:0,borrow1:0,gc:0,round:0,m0:0,m1:0,task0:0,task1:0,updated0:-1,updated1:-1,word0:7,word1:7,processors:2,rejected:0}
 var s:State
 action init=s'=initial
 val safe=all{s.alias>=0,
s.alias<=1,
s.mem0>=0,
s.mem0<=1,
s.mem1>=0,
s.mem1<=1,
s.store0>=0,
s.store0<=1,
s.store1>=0,
s.store1<=1,
s.borrow0>=0,
s.borrow0<=1,
s.borrow1>=0,
s.borrow1<=1,
s.gc>=0,
s.gc<=1,
s.m0>=0,
s.m0<=1,
s.m1>=0,
s.m1<=1,
s.d0>=2,
s.d0<=4,
s.d1==0 or s.d1==2 or s.d1==3 or s.d1==4,
s.lookup0>=0,
s.lookup0<=2,
s.task0>=0,
s.task0<=4,
s.updated0>=-1,
s.updated0<=s.round,
s.word0>=0,
(s.d0==2 or s.d0==3) implies s.mem0==1,
s.d0==4 implies s.mem0==0,
(s.lookup0>0 or s.borrow0==1) implies ((s.d0==2 or s.d0==3) and s.mem0==1),
(s.gc==1 and s.m0==1) implies (s.store0==1 and s.task0>=1),
s.task0>0 implies (s.gc==1 and s.m0==1 and s.store0==1),
s.task0==4 implies s.updated0==s.round,
s.lookup1>=0,
s.lookup1<=2,
s.task1>=0,
s.task1<=4,
s.updated1>=-1,
s.updated1<=s.round,
s.word1>=0,
(s.d1==2 or s.d1==3) implies s.mem1==1,
s.d1==4 implies s.mem1==0,
(s.lookup1>0 or s.borrow1==1) implies ((s.d1==2 or s.d1==3) and s.mem1==1),
(s.gc==1 and s.m1==1) implies (s.store1==1 and s.task1>=1),
s.task1>0 implies (s.gc==1 and s.m1==1 and s.store1==1),
s.task1==4 implies s.updated1==s.round,
s.round>=0,
s.rejected>=0,
s.processors==1 or s.processors==2,
s.d1==0 implies (s.mem1==0 and s.store1==0),
(s.d0==2 or s.d0==3) implies s.store0==1,
((s.d1==2 or s.d1==3) and s.alias==1) implies s.store0==1,
((s.d1==2 or s.d1==3) and s.alias==0) implies s.store1==1,
s.gc==1 implies ((s.m0==1 implies ((s.d0==2 or s.d0==3) or (s.alias==1 and (s.d1==2 or s.d1==3)))) and (((s.d0==2 or s.d0==3) or (s.alias==1 and (s.d1==2 or s.d1==3))) implies s.m0==1)),
s.gc==1 implies ((s.m1==1 implies (s.alias==0 and (s.d1==2 or s.d1==3))) and ((s.alias==0 and (s.d1==2 or s.d1==3)) implies s.m1==1)),
s.gc==0 implies (s.m0==0 and s.m1==0 and s.task0==0 and s.task1==0)}
 action registerAlias=all{(s.d0==2),(s.d1==0),(s.gc==0),s'={...s,d1:2,mem1:1,alias:1}}
 action registerCopy=all{(s.d0==2),(s.d1==0),(s.gc==0),s'={...s,d1:2,mem1:1,store1:1,alias:0,word1:s.word0}}
 action beginLookup0=all{(s.d0==2),(s.lookup0==0),(s.borrow0==0),s'={...s,lookup0:1}}
 action acceptBorrow0=all{(s.d0==2),(s.lookup0==1),(s.borrow0==0),s'={...s,lookup0:0,borrow0:1}}
 action lookupUnknown0=all{(s.lookup0==1),s'={...s,lookup0:2}}
 action resolveLookup0=all{(s.lookup0==2),s'={...s,lookup0:1}}
 action rejectLookup0=all{(s.lookup0==1),(s.d0==3),s'={...s,lookup0:0}}
 action returnBorrow0=all{(s.borrow0==1),s'={...s,borrow0:0}}
 action close0=all{(s.d0==2),s'={...s,d0:3}}
 action retire0=all{(s.d0==3),(s.lookup0==0),(s.borrow0==0),(s.gc==0),s'={...s,d0:4,mem0:0}}
 action lateRequest0=all{((s.d0==3 or s.d0==4)),s'={...s,rejected:s.rejected+1}}
 action claim0=all{(s.gc==1),(s.task0==1),s'={...s,task0:2}}
 action scan0=all{(s.gc==1),(s.task0==2),s'={...s,task0:4,updated0:s.round,word0:s.round+100}}
 action scanUnknown0=all{(s.gc==1),(s.task0==2),s'={...s,task0:3}}
 action resolveScan0=all{(s.gc==1),(s.task0==3),s'={...s,task0:4,updated0:s.round,word0:s.round+100}}
 action beginLookup1=all{(s.d1==2),(s.lookup1==0),(s.borrow1==0),s'={...s,lookup1:1}}
 action acceptBorrow1=all{(s.d1==2),(s.lookup1==1),(s.borrow1==0),s'={...s,lookup1:0,borrow1:1}}
 action lookupUnknown1=all{(s.lookup1==1),s'={...s,lookup1:2}}
 action resolveLookup1=all{(s.lookup1==2),s'={...s,lookup1:1}}
 action rejectLookup1=all{(s.lookup1==1),(s.d1==3),s'={...s,lookup1:0}}
 action returnBorrow1=all{(s.borrow1==1),s'={...s,borrow1:0}}
 action close1=all{(s.d1==2),s'={...s,d1:3}}
 action retire1=all{(s.d1==3),(s.lookup1==0),(s.borrow1==0),(s.gc==0),s'={...s,d1:4,mem1:0}}
 action lateRequest1=all{((s.d1==3 or s.d1==4)),s'={...s,rejected:s.rejected+1}}
 action claim1=all{(s.gc==1),(s.task1==1),s'={...s,task1:2}}
 action scan1=all{(s.gc==1),(s.task1==2),s'={...s,task1:4,updated1:s.round,word1:s.round+100}}
 action scanUnknown1=all{(s.gc==1),(s.task1==2),s'={...s,task1:3}}
 action resolveScan1=all{(s.gc==1),(s.task1==3),s'={...s,task1:4,updated1:s.round,word1:s.round+100}}
 action freeze000=all{(s.gc==0),(s.alias==0),((s.d0==0 or s.d0==4)),((s.d1==0 or s.d1==4)),s'={...s,gc:1,round:s.round+1,m0:0,m1:0,task0:0,task1:0}}
 action freeze001=all{(s.gc==0),(s.alias==0),((s.d0==0 or s.d0==4)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,m0:0,m1:1,task0:0,task1:1}}
 action freeze010=all{(s.gc==0),(s.alias==0),((s.d0==2 or s.d0==3)),((s.d1==0 or s.d1==4)),s'={...s,gc:1,round:s.round+1,m0:1,m1:0,task0:1,task1:0}}
 action freeze011=all{(s.gc==0),(s.alias==0),((s.d0==2 or s.d0==3)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,m0:1,m1:1,task0:1,task1:1}}
 action freeze100=all{(s.gc==0),(s.alias==1),((s.d0==0 or s.d0==4)),((s.d1==0 or s.d1==4)),s'={...s,gc:1,round:s.round+1,m0:0,m1:0,task0:0,task1:0}}
 action freeze101=all{(s.gc==0),(s.alias==1),((s.d0==0 or s.d0==4)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,m0:1,m1:0,task0:1,task1:0}}
 action freeze110=all{(s.gc==0),(s.alias==1),((s.d0==2 or s.d0==3)),((s.d1==0 or s.d1==4)),s'={...s,gc:1,round:s.round+1,m0:1,m1:0,task0:1,task1:0}}
 action freeze111=all{(s.gc==0),(s.alias==1),((s.d0==2 or s.d0==3)),((s.d1==2 or s.d1==3)),s'={...s,gc:1,round:s.round+1,m0:1,m1:0,task0:1,task1:0}}
 action finishRound=all{(s.gc==1),((s.task0==0 or s.task0==4)),((s.task1==0 or s.task1==4)),s'={...s,gc:0,m0:0,m1:0,task0:0,task1:0}}
 action freeStore0=all{(s.store0==1),(s.d0==4),(((s.d1==0 or s.d1==4) or s.alias==0)),(s.gc==0),s'={...s,store0:0}}
 action freeStore1=all{(s.store1==1),(s.d1==4),(s.alias==0),(s.gc==0),s'={...s,store1:0}}
 action exitProcessor=all{(s.processors==2),(s.gc==0),s'={...s,processors:1}}
 action step=any{registerAlias,registerCopy,beginLookup0,acceptBorrow0,lookupUnknown0,resolveLookup0,rejectLookup0,returnBorrow0,close0,retire0,lateRequest0,claim0,scan0,scanUnknown0,resolveScan0,beginLookup1,acceptBorrow1,lookupUnknown1,resolveLookup1,rejectLookup1,returnBorrow1,close1,retire1,lateRequest1,claim1,scan1,scanUnknown1,resolveScan1,freeze000,freeze001,freeze010,freeze011,freeze100,freeze101,freeze110,freeze111,finishRound,freeStore0,freeStore1,exitProcessor,all{s'=s}}
 run aliasOneTaskTest=init.then(registerAlias).then(freeze111).then(all{assert(s.m0==1 and s.m1==0 and s.task0==1 and s.task1==0 and safe),s'=s})
 run equalValuesDistinctTest=init.then(registerCopy).then(freeze011).then(all{assert(s.word0==s.word1 and s.m0==1 and s.m1==1 and safe),s'=s})
 run updateBothTest=init.then(registerCopy).then(freeze011).then(claim0).then(claim1).then(scan0).then(scan1).then(finishRound).then(all{assert(s.updated0==1 and s.updated1==1 and s.word0==s.word1 and safe),s'=s})
 run sourceRetiresAliasLivesTest=init.then(registerAlias).then(close0).then(retire0).then(freeze101).then(claim0).then(scan0).then(finishRound).then(all{assert(s.mem0==0 and s.mem1==1 and s.store0==1 and s.updated0==1 and safe),s'=s})
 run copyAllowsSourceCellReleaseTest=init.then(registerCopy).then(close0).then(retire0).then(freeStore0).then(freeze001).then(claim1).then(scan1).then(finishRound).then(all{assert(s.store0==0 and s.store1==1 and s.updated1==1 and safe),s'=s})
 run lateLookupDrainTest=init.then(beginLookup0).then(close0).then(rejectLookup0).then(retire0).then(lateRequest0).then(all{assert(s.mem0==0 and s.rejected==1 and safe),s'=s})
 run acceptedBorrowDrainTest=init.then(beginLookup0).then(acceptBorrow0).then(close0).then(returnBorrow0).then(retire0).then(all{assert(s.mem0==0 and safe),s'=s})
 run lookupUnknownRetainsTest=init.then(beginLookup0).then(lookupUnknown0).then(close0).then(all{assert(s.lookup0==2 and s.mem0==1 and safe),s'=s})
 run resolveUnknownTest=init.then(beginLookup0).then(lookupUnknown0).then(close0).then(resolveLookup0).then(rejectLookup0).then(retire0).then(all{assert(s.mem0==0 and safe),s'=s})
 run closeWhileScanningTest=init.then(registerAlias).then(freeze111).then(claim0).then(close0).then(close1).then(scan0).then(finishRound).then(all{assert(s.d0==3 and s.d1==3 and s.store0==1 and safe),s'=s})
 run scanUnknownRetainsTest=init.then(registerAlias).then(freeze111).then(claim0).then(scanUnknown0).then(close0).then(close1).then(all{assert(s.gc==1 and s.task0==3 and s.mem0==1 and s.mem1==1 and safe),s'=s})
 run allAliasesRetiredTest=init.then(registerAlias).then(close0).then(close1).then(retire0).then(retire1).then(freeStore0).then(all{assert(s.store0==0 and s.mem0==0 and s.mem1==0 and safe),s'=s})
 run nextRoundIndependentTest=init.then(registerCopy).then(exitProcessor).then(freeze011).then(claim0).then(claim1).then(scan0).then(scan1).then(finishRound).then(freeze011).then(claim0).then(claim1).then(scan0).then(scan1).then(finishRound).then(all{assert(s.processors==1 and s.updated0==2 and s.updated1==2 and safe),s'=s})
}
