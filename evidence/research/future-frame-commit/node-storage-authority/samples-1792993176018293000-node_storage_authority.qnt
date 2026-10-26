module node_storage_authority {
// Proposed stable registration/admission; current raw list publication is not a binding receipt.
type State={stage:int,ownerReady:int,listVisible:int,layout:int,mapReady:int,coverage:int,aliasSeen:int,gate:int,metaLease:int,payloadLease:int,tailAuth:int,nodeRole:int,unknown:int,receipt:int,cacheLive:int,cacheGen:int,nodeAllocGen:int,queryGen:int,cleanupReady:int,opaqueSeen:int,currentSeen:int}
pure val initial:State={stage:0,ownerReady:0,listVisible:0,layout:0,mapReady:0,coverage:0,aliasSeen:0,gate:0,metaLease:0,payloadLease:0,tailAuth:1,nodeRole:0,unknown:0,receipt:0,cacheLive:1,cacheGen:1,nodeAllocGen:1,queryGen:1,cleanupReady:0,opaqueSeen:0,currentSeen:0}
var s:State
action init=s'=initial
val safe=all{all{s.stage>=0,s.stage<=10},all{s.ownerReady>=0,s.ownerReady<=1},all{s.listVisible>=0,s.listVisible<=1},all{s.layout>=0,s.layout<=1},all{s.mapReady>=0,s.mapReady<=1},all{s.coverage>=0,s.coverage<=1},all{s.aliasSeen>=0,s.aliasSeen<=1},all{s.gate>=0,s.gate<=1},all{s.metaLease>=0,s.metaLease<=1},all{s.payloadLease>=0,s.payloadLease<=1},all{s.tailAuth>=0,s.tailAuth<=1},all{s.nodeRole>=0,s.nodeRole<=2},all{s.unknown>=0,s.unknown<=1},all{s.receipt>=0,s.receipt<=1},all{s.cacheLive>=0,s.cacheLive<=1},all{s.cacheGen>=0,s.cacheGen<=2},all{s.nodeAllocGen>=0,s.nodeAllocGen<=1},all{s.queryGen>=0,s.queryGen<=1},all{s.cleanupReady>=0,s.cleanupReady<=1},all{s.opaqueSeen>=0,s.opaqueSeen<=1},all{s.currentSeen>=0,s.currentSeen<=1},s.nodeAllocGen==1,s.queryGen==1,s.cacheGen>=1,s.stage==0 implies s.listVisible==0,s.stage>=1 implies s.listVisible==1,s.stage<=1 implies s.ownerReady==0,s.stage>=2 implies s.ownerReady==1,s.stage<=2 implies all{s.mapReady==0,s.gate==0,s.metaLease==0,s.payloadLease==0,s.coverage==0,s.aliasSeen==0},s.stage>=3 implies all{s.mapReady==1,s.layout==1,s.ownerReady==1},s.stage==3 implies s.coverage==0,s.stage==4 implies all{s.coverage==1,s.aliasSeen==0},s.stage>=5 and s.stage<=9 implies all{s.coverage==1,s.aliasSeen==0},s.stage<=4 implies all{s.tailAuth==1,s.nodeRole==0,s.unknown==0,s.receipt==0},s.stage>=5 and s.stage<=9 implies all{s.tailAuth==0,s.nodeRole>=1},s.stage==10 implies all{s.aliasSeen==1,s.coverage==0,s.gate==0,s.cacheLive==1,s.receipt==0,s.tailAuth==1,s.nodeRole==0,s.unknown==0,s.payloadLease==0},s.unknown==1 implies all{s.stage==5,s.receipt==0,s.cacheLive==1,s.cleanupReady==0,s.cacheGen==1,s.gate==1},(s.stage==5 or s.stage==6) implies s.receipt==0,s.stage>=7 and s.stage<=9 implies s.receipt==1,s.stage>=3 and s.stage<=7 implies s.gate==1,s.stage>=8 implies s.gate==0,s.stage==9 implies all{s.cacheLive==0,s.cacheGen==2,s.metaLease==0,s.payloadLease==0,s.cleanupReady==1},s.stage!=9 implies all{s.cacheLive==1,s.cacheGen==1},s.cleanupReady==1 implies all{(s.stage==8 or s.stage==9),s.metaLease==0,s.payloadLease==0},s.payloadLease==1 implies all{s.stage==4,s.tailAuth==1}}
action publishRawList=all{s.stage==0,s'={...s,stage:1,listVisible:1}}
action initializeOwner=all{s.stage==1,s'={...s,stage:2,ownerReady:1}}
action attestDisjoint=all{s.stage==2 and s.layout==0,s'={...s,layout:1}}
action bindNodeMap=all{s.stage==2 and s.ownerReady==1 and s.layout==1,s'={...s,stage:3,mapReady:1,gate:1}}
action sealReaderClosure=all{s.stage==3 and s.aliasSeen==0,s'={...s,stage:4,coverage:1}}
action exposeAlias=all{s.stage==3 and s.aliasSeen==0,s'={...s,aliasSeen:1}}
action revokeSeal=all{s.stage==4 and s.payloadLease==0,s'={...s,stage:3,coverage:0,aliasSeen:1}}
action rejectAlias=all{s.stage==3 and s.aliasSeen==1 and s.payloadLease==0,s'={...s,stage:10,gate:0}}
action acquireMetadata=all{s.mapReady==1 and s.gate==1 and s.metaLease==0,s'={...s,metaLease:1}}
action returnMetadata=all{s.metaLease==1,s'={...s,metaLease:0}}
action acquirePayload=all{s.stage==4 and s.coverage==1 and s.tailAuth==1 and s.payloadLease==0,s'={...s,payloadLease:1}}
action returnPayload=all{s.payloadLease==1,s'={...s,payloadLease:0}}
action knownHandoff=all{s.stage==4 and s.coverage==1 and s.payloadLease==0,s'={...s,stage:5,tailAuth:0,nodeRole:1}}
action unknownHandoff=all{s.stage==4 and s.coverage==1 and s.payloadLease==0,s'={...s,stage:5,tailAuth:0,nodeRole:1,unknown:1}}
action consumerAllocate=all{s.stage>=5 and s.stage<=9 and s.nodeRole==1,s'={...s,nodeRole:2}}
action fixSourceLast=all{s.stage==5 and s.unknown==0,s'={...s,stage:6}}
action publishCompletion=all{s.stage==6,s'={...s,stage:7,receipt:1}}
action closeAdmission=all{s.stage==7,s'={...s,stage:8,gate:0}}
action attestCleanup=all{s.stage==8 and s.metaLease==0 and s.payloadLease==0 and s.cleanupReady==0,s'={...s,cleanupReady:1}}
action retireCache=all{s.stage==8 and s.cleanupReady==1 and s.metaLease==0 and s.payloadLease==0,s'={...s,stage:9,cacheLive:0,cacheGen:2}}
action lookupOpaque=all{s.mapReady==1 and s.opaqueSeen==0,s'={...s,opaqueSeen:1}}
action probeCurrentCache=all{s.mapReady==1 and s.metaLease==1 and s.gate==1 and s.cacheLive==1 and s.cacheGen==s.queryGen and s.coverage==1 and s.aliasSeen==0 and s.currentSeen==0,s'={...s,currentSeen:1}}
action step=any{publishRawList,initializeOwner,attestDisjoint,bindNodeMap,sealReaderClosure,exposeAlias,revokeSeal,rejectAlias,acquireMetadata,returnMetadata,acquirePayload,returnPayload,knownHandoff,unknownHandoff,consumerAllocate,fixSourceLast,publishCompletion,closeAdmission,attestCleanup,retireCache,lookupOpaque,probeCurrentCache,all{s'=s}}
run rawListOnlyTest=init.then(publishRawList).then(all{assert(safe),s'=s})
run normalTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(fixSourceLast).then(publishCompletion).then(all{assert(safe),s'=s})
run metadataOnlyAfterTransferTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(acquireMetadata).then(probeCurrentCache).then(lookupOpaque).then(all{assert(safe),s'=s})
run unknownConsumerTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(unknownHandoff).then(consumerAllocate).then(all{assert(safe),s'=s})
run revokedTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(revokeSeal).then(rejectAlias).then(all{assert(safe),s'=s})
run lateOpaqueTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(fixSourceLast).then(publishCompletion).then(closeAdmission).then(attestCleanup).then(retireCache).then(lookupOpaque).then(all{assert(safe),s'=s})
run payloadLeaseTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(acquirePayload).then(returnPayload).then(knownHandoff).then(all{assert(safe),s'=s})
run rawNotReadyTest=init.then(publishRawList).then(all{assert(not(s.mapReady==1 and s.gate==1 and s.metaLease==0)),assert(safe),s'=s})
run oldTailNoReadTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(all{assert(not(s.stage==4 and s.coverage==1 and s.tailAuth==1 and s.payloadLease==0)),assert(safe),s'=s})
run leaseBlocksHandoffTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(acquirePayload).then(all{assert(not(s.stage==4 and s.coverage==1 and s.payloadLease==0)),assert(safe),s'=s})
run revokedNoSealTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(revokeSeal).then(all{assert(not(s.stage==3 and s.aliasSeen==0)),assert(safe),s'=s})
run unknownNoRetireTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(unknownHandoff).then(consumerAllocate).then(all{assert(not(s.stage==8 and s.cleanupReady==1 and s.metaLease==0 and s.payloadLease==0)),assert(safe),s'=s})
run metadataBlocksFreeTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(fixSourceLast).then(publishCompletion).then(acquireMetadata).then(closeAdmission).then(all{assert(not(s.stage==8 and s.metaLease==0 and s.payloadLease==0 and s.cleanupReady==0)),assert(safe),s'=s})
run reusedNoCacheReadTest=init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap).then(sealReaderClosure).then(knownHandoff).then(fixSourceLast).then(publishCompletion).then(closeAdmission).then(attestCleanup).then(retireCache).then(all{assert(not(s.mapReady==1 and s.metaLease==1 and s.gate==1 and s.cacheLive==1 and s.cacheGen==s.queryGen and s.coverage==1 and s.aliasSeen==0 and s.currentSeen==0)),assert(safe),s'=s})
}
