module formatter_restore_reentry {
 // Alternative legacy and managed worlds; no claim they share one physical slot.
 type State={phase:int,writer:int,generation:int,savedWriter:int,installGen:int,epoch:int,scopeEpoch:int,tickets:int,borrowers:int,captures:int,attempts:int,demand:int,certGen:int,certEpoch:int,legacyPc:int,legacyWriter:int,legacySaved:int,legacyCaptureSaved:int,legacyGen:int,legacyResumes:int,legacyTarget:int,active:bool,frameClosed:bool,registrationClosed:bool,custody:bool,errorSeen:bool,qualified:bool,certificate:bool,retired:bool,legacyCaptured:bool,legacyNewer:bool,legacyClobbered:bool}
 pure val initial:State={phase:0,writer:1,generation:1,savedWriter:1,installGen:0,epoch:1,scopeEpoch:1,tickets:0,borrowers:0,captures:0,attempts:0,demand:1,certGen:0,certEpoch:0,legacyPc:0,legacyWriter:1,legacySaved:1,legacyCaptureSaved:1,legacyGen:1,legacyResumes:0,legacyTarget:0,active:false,frameClosed:false,registrationClosed:false,custody:false,errorSeen:false,qualified:false,certificate:false,retired:false,legacyCaptured:false,legacyNewer:false,legacyClobbered:false}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
s.phase<=5,
s.writer>=0,
s.writer<=2,
s.savedWriter>=0,
s.savedWriter<=2,
s.generation>=1,
s.installGen>=0,
s.epoch>=1,
s.scopeEpoch>=1,
s.tickets>=0,
s.borrowers>=0,
s.captures>=0,
s.attempts>=0,
s.demand>=0,
s.demand<=2,
s.certGen>=0,
s.certEpoch>=0,
s.active implies (s.phase==1 or s.phase==2),
(s.phase==1 or s.phase==2) implies s.active,
s.frameClosed implies not(s.active),
(s.active or s.tickets>0 or s.borrowers>0 or s.captures>0 or s.certificate) implies s.custody,
s.certificate implies ((s.phase==3 or s.phase==5) and s.registrationClosed and s.frameClosed and s.writer==s.savedWriter and s.generation==s.certGen and s.epoch==s.certEpoch and s.epoch==s.scopeEpoch and s.tickets==0 and s.borrowers==0 and s.captures==0 and s.demand==1 and not(s.errorSeen) and s.qualified),
s.retired implies (s.phase==5 and s.certificate),
s.phase==5 implies s.retired,
s.legacyPc>=0,
s.legacyPc<=4,
s.legacyWriter>=0,
s.legacyWriter<=2,
s.legacySaved>=0,
s.legacySaved<=2,
s.legacyCaptureSaved>=0,
s.legacyCaptureSaved<=2,
s.legacyGen>=1,
s.legacyResumes>=0,
s.legacyTarget>=0,
s.legacyTarget<=2}
 action beginScope=all{s.phase==0,not(s.registrationClosed),s'={...s,phase:1,active:true,custody:true,savedWriter:s.writer,writer:0,generation:s.generation+1,installGen:s.generation+1,scopeEpoch:s.epoch,frameClosed:false}}
 action bodyReturns=all{s.phase==1,s.active,s'={...s,phase:2}}
 action restoreOwned=all{s.phase==2,s.active,not(s.frameClosed),s.generation==s.installGen,s.writer==0,s.epoch==s.scopeEpoch,s'={...s,phase:3,writer:s.savedWriter,generation:s.generation+1,active:false,frameClosed:true}}
 action escapeOwned=all{s.phase>=1,s.phase<=2,s.active,s.generation==s.installGen,s.writer==0,s.epoch==s.scopeEpoch,s'={...s,phase:4,writer:s.savedWriter,generation:s.generation+1,active:false,frameClosed:true,errorSeen:true,certificate:false,qualified:false}}
 action publishOther=all{s.phase<=4,s'={...s,writer:2,generation:s.generation+1,certificate:false,qualified:false}}
 action publishSameIdentity=all{s.phase<=4,s'={...s,writer:s.savedWriter,generation:s.generation+1,certificate:false,qualified:false}}
 action yieldConflict=all{s.phase>=1,s.phase<=2,s.active,(s.generation!=s.installGen or s.epoch!=s.scopeEpoch),s'={...s,phase:4,active:false,frameClosed:true,errorSeen:true,certificate:false,qualified:false}}
 action changeEpoch=all{s.phase<=4,s'={...s,epoch:s.epoch+1,certificate:false,qualified:false}}
 action acceptTicket=all{s.phase<=3,not(s.registrationClosed),s'={...s,tickets:s.tickets+1,custody:true,certificate:false,qualified:false}}
 action startTicket=all{s.phase<=4,s.tickets>0,s'={...s,tickets:s.tickets-1,borrowers:s.borrowers+1,custody:true,certificate:false,qualified:false}}
 action finishBorrower=all{s.phase<=4,s.borrowers>0,s'={...s,borrowers:s.borrowers-1}}
 action capture=all{s.phase<=4,(s.active or s.borrowers>0),s'={...s,captures:s.captures+1,custody:true,certificate:false,qualified:false}}
 action rejectStalePermit=all{s.phase<=4,s.captures>0,s'={...s,attempts:s.attempts+1}}
 action detachCapture=all{s.phase<=4,s.captures>0,s'={...s,captures:s.captures-1}}
 action closeRegistration=all{s.phase<=4,s'={...s,registrationClosed:true}}
 action namedDemand=all{s.phase<=4,s'={...s,demand:1}}
 action namedSupply=all{s.phase<=4,s'={...s,demand:s.demand}}
 action rawMetadata=all{s.phase<=4,s'={...s,demand:2,certificate:false,qualified:false}}
 action ioFailure=all{s.phase<=4,s'={...s,errorSeen:true,certificate:false,qualified:false}}
 action qualifyProfile=all{s.phase==3,s.registrationClosed,s.tickets==0,s.borrowers==0,s.captures==0,s.writer==s.savedWriter,s.epoch==s.scopeEpoch,not(s.errorSeen),s.demand==1,s'={...s,qualified:true}}
 action issue=all{s.phase==3,s.registrationClosed,s.tickets==0,s.borrowers==0,s.captures==0,s.writer==s.savedWriter,s.epoch==s.scopeEpoch,not(s.errorSeen),s.demand==1,s.qualified,s'={...s,certificate:true,certGen:s.generation,certEpoch:s.epoch}}
 action consumeSecond=all{s.phase==3,s.certificate,s.generation==s.certGen,s.epoch==s.certEpoch,s'={...s,phase:5,retired:true}}
 action legacyEnter=all{s.legacyPc==0,s'={...s,legacySaved:s.legacyWriter,legacyWriter:0,legacyGen:s.legacyGen+1,legacyPc:1}}
 action legacyCapture=all{s.legacyPc==1,not(s.legacyCaptured),s'={...s,legacyCaptured:true,legacyCaptureSaved:s.legacySaved}}
 action legacyEscape=all{s.legacyPc==1,s'={...s,legacyPc:4}}
 action legacyPublish=all{s.legacyPc>=1,s.legacyPc<=4,s'={...s,legacyWriter:2,legacyGen:s.legacyGen+1,legacyNewer:true}}
 action legacyResolve=all{s.legacyPc==1,s'={...s,legacyTarget:s.legacyWriter}}
 action legacyReturn=all{s.legacyPc==1,s'={...s,legacyPc:2}}
 action legacyRestore=all{s.legacyPc==2,s'={...s,legacyWriter:s.legacySaved,legacyGen:s.legacyGen+1,legacyPc:3,legacyClobbered:s.legacyClobbered or (s.legacyNewer and s.legacySaved!=2)}}
 action legacyResume=all{(s.legacyPc==3 or s.legacyPc==4),s.legacyCaptured,s'={...s,legacyPc:1,legacySaved:s.legacyCaptureSaved,legacyResumes:s.legacyResumes+1}}
 action legacyLateEntry=all{(s.legacyPc==3 or s.legacyPc==4),s'={...s,legacySaved:s.legacyWriter,legacyWriter:0,legacyGen:s.legacyGen+1,legacyPc:1}}
 action step=any{beginScope,bodyReturns,restoreOwned,escapeOwned,publishOther,publishSameIdentity,yieldConflict,changeEpoch,acceptTicket,startTicket,finishBorrower,capture,rejectStalePermit,detachCapture,closeRegistration,namedDemand,namedSupply,rawMetadata,ioFailure,qualifyProfile,issue,consumeSecond,legacyEnter,legacyCapture,legacyEscape,legacyPublish,legacyResolve,legacyReturn,legacyRestore,legacyResume,legacyLateEntry,all{s'=s}}
 run managedCompleteTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(qualifyProfile).then(issue).then(consumeSecond).then(all{assert(safe and s.retired),s'=s})
 run legacyEscapeTest=init.then(legacyEnter).then(legacyEscape).then(all{assert(safe and s.legacyWriter==0),s'=s})
 run legacyOverwriteTest=init.then(legacyEnter).then(legacyPublish).then(legacyReturn).then(legacyRestore).then(all{assert(safe and s.legacyWriter==1 and s.legacyClobbered),s'=s})
 run multiShotClobberTest=init.then(legacyEnter).then(legacyCapture).then(legacyReturn).then(legacyRestore).then(legacyPublish).then(legacyResume).then(legacyReturn).then(legacyRestore).then(legacyPublish).then(legacyResume).then(legacyReturn).then(legacyRestore).then(all{assert(safe and s.legacyResumes==2 and s.legacyClobbered and s.legacyWriter==1),s'=s})
 run lateOldHookTest=init.then(legacyEnter).then(legacyReturn).then(legacyRestore).then(legacyPublish).then(legacyLateEntry).then(legacyReturn).then(legacyRestore).then(all{assert(safe and s.legacySaved==2 and s.legacyWriter==2 and not(s.legacyClobbered)),s'=s})
 run operatorBeforeTest=init.then(legacyEnter).then(legacyResolve).then(legacyPublish).then(all{assert(safe and s.legacyTarget==0 and s.legacyWriter==2),s'=s})
 run operatorAfterTest=init.then(legacyEnter).then(legacyPublish).then(legacyResolve).then(all{assert(safe and s.legacyTarget==2),s'=s})
 run preserveNewWriterTest=init.then(beginScope).then(publishOther).then(yieldConflict).then(all{assert(safe and s.writer==2 and s.custody and not(s.certificate)),s'=s})
 run managedFaultTest=init.then(beginScope).then(escapeOwned).then(all{assert(safe and s.writer==1 and s.errorSeen and not(s.certificate)),s'=s})
 run lateLeaseTest=init.then(acceptTicket).then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(startTicket).then(finishBorrower).then(qualifyProfile).then(issue).then(consumeSecond).then(all{assert(safe and s.retired),s'=s})
 run liveCaptureTest=init.then(beginScope).then(capture).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(rejectStalePermit).then(rejectStalePermit).then(all{assert(safe and s.captures==1 and s.attempts==2 and not(s.certificate)),s'=s})
 run qualifiedDetachTest=init.then(beginScope).then(capture).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(detachCapture).then(qualifyProfile).then(issue).then(consumeSecond).then(all{assert(safe and s.retired),s'=s})
 run canonicalNamedTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(namedSupply).then(namedDemand).then(namedSupply).then(closeRegistration).then(qualifyProfile).then(issue).then(consumeSecond).then(all{assert(safe and s.retired),s'=s})
 run sameIdentityRevokesTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(qualifyProfile).then(issue).then(publishSameIdentity).then(all{assert(safe and s.writer==1 and not(s.certificate)),s'=s})
 run rawRevokesTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(qualifyProfile).then(issue).then(rawMetadata).then(all{assert(safe and s.demand==2 and not(s.certificate)),s'=s})
 run captureForgedControlTest=init.then(beginScope).then(capture).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(all{s'={...s,qualified:true,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run staleGenControlTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(qualifyProfile).then(issue).then(all{s'={...s,generation:s.generation+1}}).then(all{assert(not(safe)),s'=s})
 run lateTicketControlTest=init.then(acceptTicket).then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(all{s'={...s,qualified:true,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run priorErrorControlTest=init.then(beginScope).then(bodyReturns).then(restoreOwned).then(closeRegistration).then(ioFailure).then(all{s'={...s,qualified:true,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run lostCustodyControlTest=init.then(beginScope).then(all{s'={...s,custody:false}}).then(all{assert(not(safe)),s'=s})
}
