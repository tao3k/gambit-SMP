module registry_slot_issuance {
 // Two storage incarnations; fixed lookup/borrow identities; signed native premises remain explicit.
 type State={storage:int,generation:int,request:int,lo:int,hi:int,key:int,keyGeneration:int,savedGeneration:int,fresh:int,freshLo:int,freshHi:int,reg:int,mode:int,lease:int,boundGeneration:int,boundPayload:int,payload:int,copy:int,known:int,borrow:int,lookup:int,scan:int,gc:int,sourceBorrow:int,backing:int,rejected:int,queries:int}
 pure val initial:State={storage:1,generation:1,request:0,lo:0,hi:0,key:0,keyGeneration:0,savedGeneration:0,fresh:0,freshLo:0,freshHi:0,reg:0,mode:0,lease:0,boundGeneration:0,boundPayload:0,payload:0,copy:0,known:0,borrow:0,lookup:0,scan:0,gc:0,sourceBorrow:0,backing:0,rejected:0,queries:0}
 var s:State
 action init=s'=initial
 val safe=all{s.key>=0,
s.key<=1,
s.fresh>=0,
s.fresh<=1,
s.lease>=0,
s.lease<=1,
s.copy>=0,
s.copy<=1,
s.known>=0,
s.known<=1,
s.borrow>=0,
s.borrow<=1,
s.gc>=0,
s.gc<=1,
s.sourceBorrow>=0,
s.sourceBorrow<=1,
s.backing>=0,
s.backing<=1,
s.storage>=1,
s.storage<=3,
s.generation>=1,
s.generation<=2,
s.request>=0,
s.request<=4,
s.reg>=0,
s.reg<=4,
s.mode>=0,
s.mode<=2,
s.lookup>=0,
s.lookup<=2,
s.scan>=0,
s.scan<=2,
s.keyGeneration>=0,
s.keyGeneration<=2,
s.savedGeneration>=0,
s.savedGeneration<=2,
s.boundGeneration>=0,
s.boundGeneration<=2,
s.lo>=0,
s.hi>=s.lo,
s.freshLo>=0,
s.freshHi>=s.freshLo,
s.payload>=0,
s.boundPayload>=0,
s.boundPayload<=s.payload,
s.rejected>=0,
s.queries>=0,
s.request==1 implies (s.lo==2 and s.hi==4),
s.request==2 implies (s.lo==8 and s.hi==12),
s.request==3 implies (s.lo==6 and s.hi==10),
s.request==4 implies (s.lo==0 and s.hi==8),
s.fresh==1 implies (s.freshLo>=8 or s.freshHi<=0),
s.key==1 implies s.keyGeneration>=1,
s.savedGeneration>0 implies s.savedGeneration<=s.generation,
s.keyGeneration<=s.generation,
s.lease==1 implies ((s.storage==1 or s.storage==2) and s.boundGeneration==s.generation and s.boundPayload==s.payload),
(s.mode==1 and (s.reg==1 or s.reg==2 or s.reg==3)) implies s.lease==1,
(s.mode==2 and (s.reg==2 or s.reg==3)) implies s.copy==1,
(s.reg==1 or s.reg==2 or s.reg==3) implies (s.mode==1 or s.mode==2),
s.reg==0 implies (s.mode==0 and s.lease==0 and s.copy==0 and s.known==0),
s.known==1 implies (s.reg==2 or s.reg==3 or s.reg==4),
(s.borrow==1 or s.lookup>0 or s.scan>0) implies (s.reg==2 or s.reg==3),
s.sourceBorrow==1 implies (s.storage==1 or s.storage==2),
s.storage==3 implies (s.lease==0 and s.sourceBorrow==0),
s.scan>0 implies s.gc==1,
s.gc==1 implies s.scan>0,
(s.mode==2 and (s.reg==2 or s.reg==3) and s.known==0) implies s.lease==1}
 action probeSubview=all{(s.storage==1),(s.request==0),s'={...s,request:1,lo:2,hi:4}}
 action probeAdjacent=all{(s.storage==1),(s.request==0),s'={...s,request:2,lo:8,hi:12}}
 action probeOverlap=all{(s.storage==1),(s.request==0),s'={...s,request:3,lo:6,hi:10}}
 action probeUnownedExact=all{(s.storage==1),(s.request==0),s'={...s,request:4,lo:0,hi:8}}
 action issueSubview=all{(s.storage==1),(s.request==1),(s.lo>=0),(s.hi<=8),s'={...s,request:0,key:1,keyGeneration:s.generation}}
 action issueFresh=all{(s.storage==1),(s.request==2),(s.fresh==0),((s.lo>=8 or s.hi<=0)),s'={...s,request:0,fresh:1,freshLo:s.lo,freshHi:s.hi}}
 action rejectOverlap=all{(s.request==3),s'={...s,request:0,rejected:s.rejected+1}}
 action rejectUnownedExact=all{(s.request==4),s'={...s,request:0,rejected:s.rejected+1}}
 action saveKey=all{(s.key==1),(s.savedGeneration==0),s'={...s,savedGeneration:s.keyGeneration}}
 action prepareAlias=all{(s.storage==1),(s.key==1),(s.keyGeneration==s.generation),(s.reg==0),(s.gc==0),s'={...s,reg:1,mode:1,lease:1,boundGeneration:s.generation,boundPayload:s.payload}}
 action prepareCopy=all{(s.storage==1),(s.key==1),(s.keyGeneration==s.generation),(s.reg==0),(s.gc==0),s'={...s,reg:1,mode:2,lease:1,boundGeneration:s.generation,boundPayload:s.payload}}
 action materializeCopy=all{(s.reg==1),(s.mode==2),(s.lease==1),(s.gc==0),s'={...s,copy:1}}
 action publishAlias=all{(s.reg==1),(s.mode==1),(s.lease==1),(s.gc==0),s'={...s,reg:2}}
 action publishCopy=all{(s.reg==1),(s.mode==2),(s.copy==1),(s.lease==1),(s.gc==0),s'={...s,reg:2}}
 action queryCommit=all{((s.reg==2 or s.reg==3)),s'={...s,known:1,queries:s.queries+1}}
 action releaseCopyLease=all{(s.mode==2),((s.reg==2 or s.reg==3)),(s.copy==1),(s.known==1),(s.gc==0),s'={...s,lease:0}}
 action beginLookup=all{(s.reg==2),(s.lookup==0),(s.borrow==0),s'={...s,lookup:1}}
 action acceptBorrow=all{(s.reg==2),(s.lookup==1),(s.borrow==0),s'={...s,lookup:0,borrow:1}}
 action lookupUnknown=all{(s.lookup==1),s'={...s,lookup:2}}
 action resolveLookup=all{(s.lookup==2),s'={...s,lookup:1}}
 action rejectLookup=all{(s.lookup==1),(s.reg==3),s'={...s,lookup:0}}
 action returnBorrow=all{(s.borrow==1),s'={...s,borrow:0}}
 action closeRegistry=all{(s.reg==2),s'={...s,reg:3}}
 action beginScan=all{((s.reg==2 or s.reg==3)),(s.gc==0),s'={...s,scan:1,gc:1}}
 action finishScan=all{(s.scan==1),s'={...s,scan:0,gc:0}}
 action scanUnknown=all{(s.scan==1),s'={...s,scan:2}}
 action resolveScan=all{(s.scan==2),s'={...s,scan:0,gc:0}}
 action retireRegistry=all{(s.reg==3),(s.known==1),(s.mode==1 or s.lease==0),(s.lookup==0),(s.borrow==0),(s.scan==0),(s.gc==0),s'={...s,reg:4}}
 action releaseRetiredAliasLease=all{(s.mode==1),(s.reg==4),(s.lookup==0),(s.borrow==0),(s.scan==0),(s.gc==0),s'={...s,lease:0}}
 action abortCandidate=all{(s.reg==1),(s.gc==0),s'={...s,reg:4,lease:0}}
 action sourceWrite=all{(s.storage==1),(s.lease==0),(s.gc==0),s'={...s,payload:s.payload+1}}
 action sourceBorrowBegin=all{(s.storage==1),(s.sourceBorrow==0),s'={...s,sourceBorrow:1}}
 action sourceBorrowReturn=all{(s.sourceBorrow==1),s'={...s,sourceBorrow:0}}
 action closeStorage=all{(s.storage==1),(s.request==0),s'={...s,storage:2}}
 action settleBacking=all{(s.storage==2),(s.gc==0),s'={...s,backing:1}}
 action reclaimStorage=all{(s.storage==2),(s.lease==0),(s.sourceBorrow==0),(s.backing==1),(s.gc==0),s'={...s,storage:3}}
 action reuseStorage=all{(s.storage==3),(s.generation<2),(s.lease==0),(s.sourceBorrow==0),(s.gc==0),s'={...s,storage:1,generation:s.generation+1,payload:s.payload+1,backing:0}}
 action rejectStaleKey=all{(s.savedGeneration>0),(s.savedGeneration!=s.generation),s'={...s,rejected:s.rejected+1}}
 action step=any{probeSubview,probeAdjacent,probeOverlap,probeUnownedExact,issueSubview,issueFresh,rejectOverlap,rejectUnownedExact,saveKey,prepareAlias,prepareCopy,materializeCopy,publishAlias,publishCopy,queryCommit,releaseCopyLease,beginLookup,acceptBorrow,lookupUnknown,resolveLookup,rejectLookup,returnBorrow,closeRegistry,beginScan,finishScan,scanUnknown,resolveScan,retireRegistry,releaseRetiredAliasLease,abortCandidate,sourceWrite,sourceBorrowBegin,sourceBorrowReturn,closeStorage,settleBacking,reclaimStorage,reuseStorage,rejectStaleKey,all{s'=s}}
 run subviewCanonicalTest=init.then(probeSubview).then(issueSubview).then(all{assert(s.key==1 and s.keyGeneration==s.generation and s.fresh==0 and safe),s'=s})
 run adjacentFreshTest=init.then(probeAdjacent).then(issueFresh).then(all{assert(s.fresh==1 and s.freshLo==8 and safe),s'=s})
 run partialOverlapRefusedTest=init.then(probeOverlap).then(rejectOverlap).then(all{assert(s.fresh==0 and s.rejected==1 and safe),s'=s})
 run unownedExactRefusedTest=init.then(probeUnownedExact).then(rejectUnownedExact).then(all{assert(s.key==0 and s.rejected==1 and safe),s'=s})
 run unknownPublicationRetainsLeaseTest=init.then(probeSubview).then(issueSubview).then(prepareCopy).then(materializeCopy).then(publishCopy).then(all{assert(s.known==0 and s.lease==1 and s.copy==1 and safe),s'=s})
 run copyLeaseReleaseTest=init.then(probeSubview).then(issueSubview).then(prepareCopy).then(materializeCopy).then(publishCopy).then(queryCommit).then(releaseCopyLease).then(sourceWrite).then(all{assert(s.payload==1 and s.boundPayload==0 and s.lease==0 and safe),s'=s})
 run aliasLeaseAcrossCloseTest=init.then(probeSubview).then(issueSubview).then(prepareAlias).then(publishAlias).then(queryCommit).then(closeRegistry).then(all{assert(s.lease==1 and s.boundPayload==s.payload and safe),s'=s})
 run aliasBorrowDrainTest=init.then(probeSubview).then(issueSubview).then(prepareAlias).then(publishAlias).then(queryCommit).then(beginLookup).then(acceptBorrow).then(closeRegistry).then(returnBorrow).then(retireRegistry).then(releaseRetiredAliasLease).then(sourceWrite).then(all{assert(s.lease==0 and s.payload==1 and safe),s'=s})
 run unknownLookupRetainsTest=init.then(probeSubview).then(issueSubview).then(prepareAlias).then(publishAlias).then(beginLookup).then(lookupUnknown).then(closeRegistry).then(all{assert(s.lookup==2 and s.lease==1 and safe),s'=s})
 run unknownScanRetainsTest=init.then(probeSubview).then(issueSubview).then(prepareAlias).then(publishAlias).then(beginScan).then(scanUnknown).then(closeRegistry).then(all{assert(s.scan==2 and s.gc==1 and s.lease==1 and safe),s'=s})
 run copyStorageReuseTest=init.then(probeSubview).then(issueSubview).then(prepareCopy).then(materializeCopy).then(publishCopy).then(queryCommit).then(releaseCopyLease).then(closeStorage).then(settleBacking).then(reclaimStorage).then(reuseStorage).then(all{assert(s.generation==2 and s.copy==1 and s.boundGeneration==1 and safe),s'=s})
 run staleGenerationRefusedTest=init.then(probeSubview).then(issueSubview).then(saveKey).then(closeStorage).then(settleBacking).then(reclaimStorage).then(reuseStorage).then(rejectStaleKey).then(all{assert(s.savedGeneration==1 and s.generation==2 and s.rejected==1 and safe),s'=s})
 run candidateAbortReleasesTest=init.then(probeSubview).then(issueSubview).then(prepareAlias).then(abortCandidate).then(sourceWrite).then(all{assert(s.lease==0 and s.payload==1 and safe),s'=s})
 run unknownAckAtCloseTest=init.then(probeSubview).then(issueSubview).then(prepareCopy).then(materializeCopy).then(publishCopy).then(closeRegistry).then(all{assert(s.known==0 and s.lease==1 and s.reg==3 and safe),s'=s})
}
