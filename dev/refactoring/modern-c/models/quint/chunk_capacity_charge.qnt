module chunk_capacity_charge {
 // One allocator slice. Closed chunks and nodes persist across the phase cut.
 type State={phase:int,capacity:int,limitWords:int,visitBudget:int,visits:int,thresholds:int,early:int,openCount:int,starts:int,markers:int,committed:int,closedSpan:int,span:int,grant:int,cancelled:int,cutStarts:int,cutWords:int,cutVisits:int,cutSpan:int,forwarded:bool,noFit:bool}
 pure val initial:State={phase:0,capacity:7,limitWords:1020,visitBudget:3,visits:1,thresholds:0,early:0,openCount:1,starts:1,markers:0,committed:0,closedSpan:0,span:0,grant:0,cancelled:0,cutStarts:0,cutWords:0,cutVisits:0,cutSpan:0,forwarded:false,noFit:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.phase>=0,s.phase<=2,s.limitWords>=0,s.visitBudget>=1,s.capacity>=s.visitBudget,
 s.limitWords<255*(s.capacity-s.visitBudget+1),
 s.visits>=1,s.visits<=s.visitBudget,s.thresholds>=0,s.early>=0,s.openCount>=0,s.openCount<=1,
 s.visits==s.early+s.openCount,s.starts==s.thresholds+s.visits,s.markers==s.thresholds+s.early,
 s.starts<=s.capacity,s.committed>=0,s.committed<=s.limitWords,s.closedSpan>=0,s.span>=0,
 s.committed==s.closedSpan+s.span,255*s.thresholds<=s.closedSpan,
 (s.grant==0 or s.grant==1 or s.grant==254 or s.grant==257),s.cancelled>=0,
 s.grant>0 implies (s.openCount==1 and s.span<255 and not(s.noFit) and s.committed+s.grant<=s.limitWords),
 s.forwarded implies s.grant>0,
 s.openCount==0 implies (s.span==0 and s.grant==0 and s.noFit),
 s.noFit implies s.grant==0,
 s.phase==0 implies (s.cutStarts==0 and s.cutWords==0 and s.cutVisits==0 and s.cutSpan==0),
 s.phase>=1 implies (s.cutStarts>=1 and s.cutStarts<=s.starts and s.cutWords>=0 and s.cutWords<=s.committed and s.cutVisits>=1 and s.cutVisits<=s.visits and s.cutSpan>=0 and s.cutSpan<255),
 s.phase==2 implies (s.grant==0 and s.openCount==1 and not(s.noFit) and s.span<255)}
 action reserveOne=all{s.phase<2,s.openCount==1,s.grant==0,s.span<255,not(s.noFit),s.committed+1<=s.limitWords,s'={...s,grant:1}}
 action reserveNear=all{s.phase<2,s.openCount==1,s.grant==0,s.span<255,not(s.noFit),s.committed+254<=s.limitWords,s'={...s,grant:254}}
 action reserveOvershoot=all{s.phase<2,s.openCount==1,s.grant==0,s.span<255,not(s.noFit),s.committed+257<=s.limitWords,s'={...s,grant:257}}
 action publishForward=all{s.phase<2,s.grant>0,not(s.forwarded),s'={...s,forwarded:true}}
 action commit=all{s.phase<2,s.grant>0,s.forwarded,s'={...s,committed:s.committed+s.grant,span:s.span+s.grant,grant:0,forwarded:false}}
 action cancel=all{s.phase<2,s.grant>0,not(s.forwarded),s'={...s,cancelled:s.cancelled+s.grant,grant:0}}
 action closeThreshold=all{s.phase<2,s.openCount==1,s.grant==0,s.span>=255,s'={...s,thresholds:s.thresholds+1,markers:s.markers+1,starts:s.starts+1,closedSpan:s.closedSpan+s.span,span:0}}
 // noFit is an imported physical observation; the source predicate is an open obligation.
 action observeNoFit=all{s.phase<2,s.openCount==1,s.grant==0,s.span<255,not(s.noFit),s'={...s,noFit:true}}
 action closeEarly=all{s.phase<2,s.openCount==1,s.grant==0,s.noFit,s'={...s,early:s.early+1,markers:s.markers+1,closedSpan:s.closedSpan+s.span,span:0,openCount:0}}
 action advanceVisit=all{s.phase<2,s.openCount==0,s.visits<s.visitBudget,s'={...s,visits:s.visits+1,starts:s.starts+1,openCount:1,noFit:false}}
 action cutToWeak=all{s.phase==0,s.grant==0,s.openCount==1,not(s.noFit),s.span<255,s'={...s,phase:1,cutStarts:s.starts,cutWords:s.committed,cutVisits:s.visits,cutSpan:s.span}}
 action closeCapacity=all{s.phase==1,s.grant==0,s.openCount==1,not(s.noFit),s.span<255,s'={...s,phase:2}}
 action step=any{reserveOne,reserveNear,reserveOvershoot,publishForward,commit,cancel,closeThreshold,observeNoFit,closeEarly,advanceVisit,cutToWeak,closeCapacity,all{s'=s}}
 action one=reserveOne.then(publishForward).then(commit)
 action near=reserveNear.then(publishForward).then(commit)
 run carriedRemainderTest=init.then(near).then(cutToWeak).then(one).then(closeThreshold).then(closeCapacity).then(all{assert(safe and s.cutSpan==254 and s.thresholds==1 and s.starts==2),s'=s})
 run overshootTest=init.then(reserveOvershoot).then(publishForward).then(commit).then(closeThreshold).then(all{assert(safe and s.committed==257 and s.thresholds==1),s'=s})
 run partialCloseTest=init.then(one).then(observeNoFit).then(closeEarly).then(advanceVisit).then(all{assert(safe and s.visits==2 and s.starts==2 and s.closedSpan==1),s'=s})
 run emptyCloseTest=init.then(observeNoFit).then(closeEarly).then(advanceVisit).then(all{assert(safe and s.markers==1 and s.starts==2 and s.committed==0),s'=s})
 run cancelAfterRolloverTest=init.then(observeNoFit).then(closeEarly).then(advanceVisit).then(reserveNear).then(cancel).then(all{assert(safe and s.starts==2 and s.committed==0 and s.cancelled==254),s'=s})
 run lastVisitNoSpaceTest=init.then(observeNoFit).then(closeEarly).then(advanceVisit).then(observeNoFit).then(closeEarly).then(advanceVisit).then(observeNoFit).then(closeEarly).then(all{assert(safe and s.visits==s.visitBudget and s.openCount==0 and s.starts<s.capacity),s'=s})
 run weakKeepsEmptyNodeTest=init.then(observeNoFit).then(closeEarly).then(advanceVisit).then(cutToWeak).then(all{assert(safe and s.cutStarts==2 and s.starts==2 and s.cutWords==0),s'=s})
 run thresholdCreditControlTest=init.then(near).then(all{s'={...s,thresholds:1,markers:1,starts:2,closedSpan:254,span:0}}).then(all{assert(not(safe)),s'=s})
 run emptyMarkerRefundControlTest=init.then(observeNoFit).then(closeEarly).then(all{s'={...s,markers:0}}).then(all{assert(not(safe)),s'=s})
 run weakResetControlTest=init.then(observeNoFit).then(closeEarly).then(advanceVisit).then(cutToWeak).then(all{s'={...s,starts:1,visits:1,early:0}}).then(all{assert(not(safe)),s'=s})
 run abandonedForwardControlTest=init.then(reserveOne).then(publishForward).then(all{s'={...s,grant:0}}).then(all{assert(not(safe)),s'=s})
 run visitInflationControlTest=init.then(all{s'={...s,visits:4,early:3,starts:4}}).then(all{assert(not(safe)),s'=s})
}
