module ticket_capability_retirement {
 // Two fixed TicketIds, tracked handle/borrow/scan IDs and one CaptureId.
 // No identity is reused; root/alias/exit observations are external proof inputs.
 type State={t0phase:int,t0exit:int,t0outcome:int,t0enters:int,t0settles:int,t0ack:bool,t0unknown:bool,t1phase:int,t1exit:int,t1outcome:int,t1enters:int,t1settles:int,t1ack:bool,t1unknown:bool,cap:int,messageGeneration:int,rejected:int,duplicateReplies:int,h0open:bool,h1issued:bool,h1open:bool,b0issued:bool,b0open:bool,b1issued:bool,b1open:bool,s0issued:bool,s0open:bool,s1issued:bool,s1open:bool,rawEscape:bool,aliasCensus:bool,maps:bool,maintenanceClosed:bool,rootRetired:bool}
 pure val initial:State={t0phase:0,t0exit:0,t0outcome:0,t0enters:0,t0settles:0,t0ack:false,t0unknown:false,t1phase:0,t1exit:0,t1outcome:0,t1enters:0,t1settles:0,t1ack:false,t1unknown:false,cap:1,messageGeneration:7,rejected:0,duplicateReplies:0,h0open:true,h1issued:false,h1open:false,b0issued:false,b0open:false,b1issued:false,b1open:false,s0issued:false,s0open:false,s1issued:false,s1open:false,rawEscape:false,aliasCensus:false,maps:false,maintenanceClosed:false,rootRetired:false}
 var s:State
 action init=s'=initial
 val safe=all{s.t0phase>=0,
s.t0phase<=4,
s.t0exit>=0,
s.t0exit<=2,
s.t0enters>=0,
s.t0enters<=1,
s.t0settles>=0,
s.t0settles<=1,
s.t0phase<2 implies s.t0enters==0,
s.t0phase>=2 implies s.t0enters==1,
s.t0phase<3 implies (s.t0settles==0 and s.t0outcome==0),
s.t0phase>=3 implies (s.t0settles==1 and s.t0outcome==s.t0exit and s.t0exit>0),
s.t0exit>0 implies s.t0phase>=2,
s.t1phase>=0,
s.t1phase<=4,
s.t1exit>=0,
s.t1exit<=2,
s.t1enters>=0,
s.t1enters<=1,
s.t1settles>=0,
s.t1settles<=1,
s.t1phase<2 implies s.t1enters==0,
s.t1phase>=2 implies s.t1enters==1,
s.t1phase<3 implies (s.t1settles==0 and s.t1outcome==0),
s.t1phase>=3 implies (s.t1settles==1 and s.t1outcome==s.t1exit and s.t1exit>0),
s.t1exit>0 implies s.t1phase>=2,
s.cap>=1,
s.cap<=3,
s.messageGeneration==6 or s.messageGeneration==7,
s.rejected>=0,
s.duplicateReplies>=0,
s.h1open implies s.h1issued,
s.b0open implies s.b0issued,
s.b1open implies s.b1issued,
s.s0open implies s.s0issued,
s.s1open implies s.s1issued,
s.aliasCensus implies not(s.rawEscape),
s.cap==3 implies (s.aliasCensus and s.maps and not(s.rawEscape) and not(s.h0open) and not(s.h1open) and not(s.b0open) and not(s.b1open) and s.t0phase==0 or s.t0phase>=3 and s.t1phase==0 or s.t1phase>=3),
s.maintenanceClosed implies s.cap==3,
s.rootRetired implies (s.cap==3 and s.maintenanceClosed and not(s.s0open) and not(s.s1open))}
 action reserve0=all{s.messageGeneration==7,s.t0phase==0,s.cap==1,s.h0open or s.h1open,s'={...s,t0phase:1}}
 action enter0=all{s.t0phase==1,s'={...s,t0phase:2,t0enters:1}}
 action observeSuccess0=all{s.t0phase==2,s.t0exit==0,s'={...s,t0exit:1}}
 action observeFailure0=all{s.t0phase==2,s.t0exit==0,s'={...s,t0exit:2}}
 action commit0=all{s.t0phase==2,s.t0exit>0,s'={...s,t0phase:3,t0outcome:s.t0exit,t0settles:1}}
 action query0=all{s.t0phase>=3,s.messageGeneration==7,s'={...s,t0ack:true,t0unknown:false}}
 action queryPending0=all{s.t0phase==1 or s.t0phase==2,s.messageGeneration==7,s'={...s,duplicateReplies:s.duplicateReplies+1}}
 action conflictingSettle0=all{s.t0phase>=3,s'={...s,rejected:s.rejected+1}}
 action loseReply0=all{s.t0phase>=1,s'={...s,t0ack:false,t0unknown:true}}
 action retainTombstone0=all{s.t0phase==3,s'={...s,t0phase:4}}
 action reserve1=all{s.messageGeneration==7,s.t1phase==0,s.cap==1,s.h0open or s.h1open,s'={...s,t1phase:1}}
 action enter1=all{s.t1phase==1,s'={...s,t1phase:2,t1enters:1}}
 action observeSuccess1=all{s.t1phase==2,s.t1exit==0,s'={...s,t1exit:1}}
 action observeFailure1=all{s.t1phase==2,s.t1exit==0,s'={...s,t1exit:2}}
 action commit1=all{s.t1phase==2,s.t1exit>0,s'={...s,t1phase:3,t1outcome:s.t1exit,t1settles:1}}
 action query1=all{s.t1phase>=3,s.messageGeneration==7,s'={...s,t1ack:true,t1unknown:false}}
 action queryPending1=all{s.t1phase==1 or s.t1phase==2,s.messageGeneration==7,s'={...s,duplicateReplies:s.duplicateReplies+1}}
 action conflictingSettle1=all{s.t1phase>=3,s'={...s,rejected:s.rejected+1}}
 action loseReply1=all{s.t1phase>=1,s'={...s,t1ack:false,t1unknown:true}}
 action retainTombstone1=all{s.t1phase==3,s'={...s,t1phase:4}}
 action cloneHandle1=all{s.messageGeneration==7,s.cap==1,s.h0open,not(s.h1issued),s'={...s,h1issued:true,h1open:true}}
 action dropHandle0=all{s.messageGeneration==7,s.h0open,s'={...s,h0open:false}}
 action dropHandle1=all{s.messageGeneration==7,s.h1open,s'={...s,h1open:false}}
 action duplicateDrop0=all{s.messageGeneration==7,not(s.h0open),s'={...s,duplicateReplies:s.duplicateReplies+1}}
 action borrowNative0=all{s.messageGeneration==7,s.cap==1,not(s.b0issued),s.h0open or s.h1open,s'={...s,b0issued:true,b0open:true}}
 action returnNative0=all{s.messageGeneration==7,s.b0open,s'={...s,b0open:false}}
 action borrowNative1=all{s.messageGeneration==7,s.cap==1,not(s.b1issued),s.h0open or s.h1open,s'={...s,b1issued:true,b1open:true}}
 action returnNative1=all{s.messageGeneration==7,s.b1open,s'={...s,b1open:false}}
 action duplicateNativeReturn0=all{s.messageGeneration==7,s.b0issued,not(s.b0open),s'={...s,duplicateReplies:s.duplicateReplies+1}}
 action closeCapability=all{s.cap==1,s'={...s,cap:2}}
 action discoverRawEscape=all{s.cap<3,s'={...s,rawEscape:true,aliasCensus:false}}
 action attestAliasCensus=all{s.cap==2,not(s.rawEscape),not(s.h0open),not(s.h1open),not(s.b0open),not(s.b1open),s.t0phase==0 or s.t0phase>=3,s.t1phase==0 or s.t1phase>=3,s'={...s,aliasCensus:true}}
 action attestRootMaps=all{true,s'={...s,maps:true}}
 action closeAuthority=all{s.cap==2,s.aliasCensus,s.maps,not(s.rawEscape),not(s.h0open),not(s.h1open),not(s.b0open),not(s.b1open),s.t0phase==0 or s.t0phase>=3,s.t1phase==0 or s.t1phase>=3,s'={...s,cap:3}}
 action pinScanner0=all{not(s.maintenanceClosed),not(s.rootRetired),not(s.s0issued),s'={...s,s0issued:true,s0open:true}}
 action unpinScanner0=all{s.s0open,s'={...s,s0open:false}}
 action pinScanner1=all{not(s.maintenanceClosed),not(s.rootRetired),not(s.s1issued),s'={...s,s1issued:true,s1open:true}}
 action unpinScanner1=all{s.s1open,s'={...s,s1open:false}}
 action closeMaintenance=all{s.cap==3,s'={...s,maintenanceClosed:true}}
 action retireRoot=all{s.cap==3,s.maintenanceClosed,not(s.s0open),not(s.s1open),s'={...s,rootRetired:true}}
 action selectStaleGeneration=all{true,s'={...s,messageGeneration:6}}
 action selectCurrentGeneration=all{true,s'={...s,messageGeneration:7}}
 action rejectStaleRequest=all{s.messageGeneration!=7,s'={...s,rejected:s.rejected+1}}
 action step=any{reserve0,enter0,observeSuccess0,observeFailure0,commit0,query0,queryPending0,conflictingSettle0,loseReply0,retainTombstone0,reserve1,enter1,observeSuccess1,observeFailure1,commit1,query1,queryPending1,conflictingSettle1,loseReply1,retainTombstone1,cloneHandle1,dropHandle0,dropHandle1,duplicateDrop0,borrowNative0,returnNative0,borrowNative1,returnNative1,duplicateNativeReturn0,closeCapability,discoverRawEscape,attestAliasCensus,attestRootMaps,closeAuthority,pinScanner0,unpinScanner0,pinScanner1,unpinScanner1,closeMaintenance,retireRoot,selectStaleGeneration,selectCurrentGeneration,rejectStaleRequest,all{s'=s}}
 run lostReplyQueryTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(loseReply0).then(query0).then(all{assert(s.t0settles==1 and s.t0ack and s.t0outcome==1 and safe),s'=s})
 run duplicateSettlementTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(query0).then(query0).then(conflictingSettle0).then(all{assert(s.t0settles==1 and s.t0outcome==1 and s.rejected==1 and safe),s'=s})
 run pendingRetryTest=init.then(reserve0).then(loseReply0).then(queryPending0).then(queryPending0).then(all{assert(s.t0phase==1 and s.t0enters==0 and s.t0settles==0 and safe),s'=s})
 run multiShotDistinctIdsTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(reserve1).then(enter1).then(observeSuccess1).then(commit1).then(all{assert(s.t0settles==1 and s.t1settles==1 and s.h0open and s.cap==1 and safe),s'=s})
 run wrongTicketControlTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(reserve1).then(enter1).then(conflictingSettle0).then(all{assert(s.t1phase==2 and s.t1settles==0 and s.t0settles==1 and safe),s'=s})
 run staleGenerationControlTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(selectStaleGeneration).then(rejectStaleRequest).then(all{assert(s.t0outcome==1 and s.t0settles==1 and s.rejected==1 and safe),s'=s})
 run lateQueryTombstoneTest=init.then(reserve0).then(enter0).then(observeSuccess0).then(commit0).then(retainTombstone0).then(loseReply0).then(query0).then(all{assert(s.t0phase==4 and s.t0outcome==1 and s.t0ack and safe),s'=s})
 run duplicateDropControlTest=init.then(cloneHandle1).then(dropHandle0).then(duplicateDrop0).then(all{assert(s.h1open and not(s.h0open) and not(s.rootRetired) and safe),s'=s})
 run duplicateNativeReturnTest=init.then(borrowNative0).then(borrowNative1).then(returnNative0).then(duplicateNativeReturn0).then(all{assert(s.b1open and not(s.b0open) and safe),s'=s})
 run acceptedBeforeCloseTest=init.then(reserve0).then(closeCapability).then(enter0).then(observeFailure0).then(commit0).then(all{assert(s.t0outcome==2 and s.t0settles==1 and safe),s'=s})
 run rawEscapeControlTest=init.then(closeCapability).then(discoverRawEscape).then(dropHandle0).then(attestRootMaps).then(all{assert(s.rawEscape and not(s.aliasCensus) and s.cap==2 and not(s.rootRetired) and safe),s'=s})
 run unknownExecutionControlTest=init.then(reserve0).then(enter0).then(loseReply0).then(closeCapability).then(dropHandle0).then(attestRootMaps).then(all{assert(s.t0phase==2 and s.t0unknown and s.cap==2 and safe),s'=s})
 run scannerDrainTest=init.then(pinScanner0).then(closeCapability).then(dropHandle0).then(attestAliasCensus).then(attestRootMaps).then(closeAuthority).then(closeMaintenance).then(unpinScanner0).then(retireRoot).then(all{assert(s.rootRetired and s.cap==3 and safe),s'=s})
 run authorityNotRootRetirementTest=init.then(pinScanner0).then(closeCapability).then(dropHandle0).then(attestAliasCensus).then(attestRootMaps).then(closeAuthority).then(closeMaintenance).then(all{assert(s.cap==3 and s.s0open and not(s.rootRetired) and safe),s'=s})
 run staleHandleRequestTest=init.then(selectStaleGeneration).then(rejectStaleRequest).then(all{assert(s.h0open and s.rejected==1 and safe),s'=s})
}
