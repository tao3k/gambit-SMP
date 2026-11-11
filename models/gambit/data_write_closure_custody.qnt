// Research-only model: one operation/cohort, original 0 + helper 1.
// Certificates are abstract atomic observations, not C/POSIX implementation proofs.
module data_write_closure_custody {
  type State={members:Set[int],started:Set[int],closed:Set[int],pending:Set[int],
    enrollment:bool,manifest:bool,seal:bool,vm:bool,prepared:bool,independent:bool,
    psPins:int,cleaned:bool,envelope:bool,join:int,lease:bool,frozen:bool,
    late:bool,lost:bool,foreignEscape:bool}
  var s:State
  val actors=Set(0,1)
  val empty=Set()
  action init=s'={members:Set(0),started:Set(0),closed:empty,pending:empty,
    enrollment:true,manifest:true,seal:false,vm:false,prepared:false,independent:false,
    psPins:1,cleaned:false,envelope:true,join:0,lease:true,frozen:false,
    late:false,lost:false,foreignEscape:false}
  action registerHelper=all{s.enrollment,not(s.members.contains(1)),not(s.closed.contains(0)),
    s'={...s,members:s.members.union(Set(1))}}
  action startHelper=all{s.members.contains(1),not(s.closed.contains(1)),not(s.started.contains(1)),
    s'={...s,started:s.started.union(Set(1))}}
  action cancelUnstarted=all{s.members.contains(1),not(s.started.contains(1)),
    s'={...s,closed:s.closed.union(Set(1))}}
  action issue(a:int):bool=all{s.started.contains(a),not(s.closed.contains(a)),not(s.seal),not(s.pending.contains(a)),s.lease,
    s'={...s,pending:s.pending.union(Set(a))}}
  action apply(a:int):bool=all{s.pending.contains(a),
    s'={...s,pending:s.pending.exclude(Set(a)),late:s.late or s.seal or s.frozen or not(s.lease)}}
  action finish(a:int):bool=all{s.members.contains(a),s.started.contains(a),not(s.pending.contains(a)),
    s'={...s,closed:s.closed.union(Set(a))}}
  // Stops enrollment, not already registered/dequeued/native effects.
  action closeEnrollment=all{s.enrollment,s'={...s,enrollment:false}}
  val complete=s.members.subseteq(s.closed) and s.pending==empty and not(s.enrollment) and s.manifest and not(s.foreignEscape)
  action certify=all{complete,s'={...s,seal:true}}
  // Final original postlude/TLS/stack roots are separate from managed data closure.
  action releasePsPin=all{s.closed.contains(0),not(s.pending.contains(0)),s.psPins==1,s'={...s,psPins:0}}
  action prepareVm=all{s.envelope,s'={...s,prepared:true}}
  action auditBacking=all{s.prepared,s'={...s,independent:true}}
  action acceptVm=all{s.prepared,s.independent,s.envelope,s'={...s,vm:true}}
  action lostAcceptResponse=all{s.vm,s'=s}
  action queryCustody=all{s.envelope,s'=s}
  action cleanupPstate=all{s.vm,s.independent,s.closed.contains(0),not(s.pending.contains(0)),s.psPins==0,
    s'={...s,cleaned:true}}
  action joinFailed=all{s.join!=1,s'={...s,join:2}}
  action joinUnknown=all{s.join!=1,s'={...s,join:3}}
  // Exact successful join also needs runtime refinements; it is not success of the operation.
  action joinSuccess=all{s.closed.contains(0),not(s.pending.contains(0)),s.psPins==0,s'={...s,join:1}}
  action retireEnvelope=all{s.join==1,s.cleaned,s.seal,s.vm,s'={...s,envelope:false}}
  action releaseLease=all{s.seal,s.vm,s'={...s,lease:false}}
  action freeze=all{s.seal,s.vm,not(s.lease),s'={...s,frozen:true}}
  action noop=s'=s
  val admitted=all{
    not(s.seal) or complete,
    not(s.cleaned) or (s.vm and s.independent and s.closed.contains(0) and not(s.pending.contains(0)) and s.psPins==0),
    not(s.frozen) or (s.seal and s.vm and not(s.lease)),
    s.lease or (s.seal and s.vm),
    s.envelope or (s.join==1 and s.cleaned and s.seal and s.vm),
    not(s.late),not(s.lost)}
  action step=any{registerHelper,startHelper,cancelUnstarted,closeEnrollment,certify,
    releasePsPin,prepareVm,auditBacking,acceptVm,lostAcceptResponse,queryCustody,
    cleanupPstate,joinFailed,joinUnknown,joinSuccess,retireEnvelope,releaseLease,freeze,noop,
    {nondet a=actors.oneOf(); any{issue(a),apply(a),finish(a)}}}
  action helperInit=init.then(registerHelper)
  action closedOriginal=init.then(finish(0)).then(releasePsPin)
  action vmReady=closedOriginal.then(prepareVm).then(auditBacking).then(acceptVm)
  action ready=vmReady.then(closeEnrollment).then(certify)
  action badSeal=s'={...s,seal:true}
  action badCleanup=s'={...s,cleaned:true}
  action badRetire=s'={...s,envelope:false}
  action badJoinDowngrade=s'={...s,join:3}
  action badLose=s'={...s,lost:true}
  action badLateRegister=s'={...s,members:s.members.union(Set(1))}
  action badForeignEscape=s'={...s,foreignEscape:true}
  action badReenter=s'={...s,pending:s.pending.union(Set(0))}
  action badRelease=s'={...s,lease:false}
  run ordinaryClosureTest=ready.then(releaseLease).then(freeze).then(all{assert(admitted),s'=s})
  run registeredNotEnqueuedTest=helperInit.then(finish(0)).then(closeEnrollment).then(all{assert(not(complete) and admitted),s'=s})
  run enrolledHelperDrainsAfterCloseTest=helperInit.then(closeEnrollment).then(finish(0)).then(startHelper).then(issue(1)).then(apply(1)).then(finish(1)).then(certify).then(all{assert(admitted),s'=s})
  run unstartedHelperCancellationTest=helperInit.then(finish(0)).then(closeEnrollment).then(cancelUnstarted).then(certify).then(all{assert(admitted),s'=s})
  run postludePinSeparateTest=init.then(finish(0)).then(closeEnrollment).then(certify).then(all{assert(s.psPins==1 and admitted),s'=s})
  run pendingEffectAfterEnrollmentCloseTest=init.then(issue(0)).then(closeEnrollment).then(apply(0)).then(finish(0)).then(certify).then(all{assert(admitted),s'=s})
  run vmMayAcceptBeforeAllWritersCloseTest=helperInit.then(prepareVm).then(auditBacking).then(acceptVm).then(all{assert(s.vm and not(s.seal) and admitted),s'=s})
  run cleanupWhileVmHelperActiveTest=helperInit.then(finish(0)).then(releasePsPin).then(prepareVm).then(auditBacking).then(acceptVm).then(cleanupPstate).then(startHelper).then(issue(1)).then(apply(1)).then(all{assert(admitted),s'=s})
  run acceptResponseLostTest=vmReady.then(lostAcceptResponse).then(queryCustody).then(cleanupPstate).then(all{assert(s.vm and admitted),s'=s})
  run failedJoinRetainsEnvelopeTest=ready.then(cleanupPstate).then(joinFailed).then(all{assert(s.envelope and s.vm and admitted),s'=s})
  run unknownJoinRetainsEnvelopeTest=vmReady.then(joinUnknown).then(queryCustody).then(all{assert(s.envelope and s.lease and admitted),s'=s})
  run failedJoinDoesNotBlockQualifiedDataFreezeTest=ready.then(cleanupPstate).then(joinFailed).then(releaseLease).then(freeze).then(all{assert(s.envelope and admitted),s'=s})
  run joinSuccessWithoutHelperClosureTest=helperInit.then(finish(0)).then(releasePsPin).then(joinSuccess).then(closeEnrollment).then(all{assert(not(complete) and admitted),s'=s})
  run envelopeRetirementTest=ready.then(cleanupPstate).then(joinSuccess).then(retireEnvelope).then(all{assert(admitted),s'=s})
  run resultQueryKeepsStateTest=vmReady.then(queryCustody).then(queryCustody).then(all{assert(admitted),s'=s})
  run closeBeforeHelperEnrollmentTest=init.then(closeEnrollment).then(finish(0)).then(certify).then(all{assert(admitted),s'=s})
  run pendingSealCounterexampleTest=init.then(issue(0)).then(closeEnrollment).then(badSeal).then(all{assert(not(admitted)),s'=s})
  run originalOnlySealCounterexampleTest=helperInit.then(finish(0)).then(closeEnrollment).then(badSeal).then(all{assert(not(admitted)),s'=s})
  run enrollmentOpenSealCounterexampleTest=closedOriginal.then(badSeal).then(all{assert(not(admitted)),s'=s})
  run lateEnrollmentCounterexampleTest=ready.then(badLateRegister).then(all{assert(not(admitted)),s'=s})
  run reentryCounterexampleTest=ready.then(badReenter).then(all{assert(not(admitted)),s'=s})
  run rawEscapeCounterexampleTest=ready.then(badForeignEscape).then(all{assert(not(admitted)),s'=s})
  run noVmBeforeCleanupCounterexampleTest=closedOriginal.then(badCleanup).then(all{assert(not(admitted)),s'=s})
  run pointerCopyIsNotCustodyCounterexampleTest=closedOriginal.then(prepareVm).then(badCleanup).then(all{assert(not(admitted)),s'=s})
  run postludeAfterCleanupCounterexampleTest=init.then(finish(0)).then(prepareVm).then(auditBacking).then(acceptVm).then(badCleanup).then(all{assert(not(admitted)),s'=s})
  run failedJoinRetirementCounterexampleTest=ready.then(cleanupPstate).then(joinFailed).then(badRetire).then(all{assert(not(admitted)),s'=s})
  run unknownJoinRetirementCounterexampleTest=ready.then(cleanupPstate).then(joinUnknown).then(badRetire).then(all{assert(not(admitted)),s'=s})
  run vmAckLostDropsCustodyCounterexampleTest=vmReady.then(lostAcceptResponse).then(badLose).then(all{assert(not(admitted)),s'=s})
  run joinAloneReleasesDomainCounterexampleTest=closedOriginal.then(joinSuccess).then(badRelease).then(all{assert(not(admitted)),s'=s})
  run issuedEffectSurvivesBadSealCounterexampleTest=init.then(issue(0)).then(closeEnrollment).then(badSeal).then(apply(0)).then(all{assert(s.late and not(admitted)),s'=s})
  run knownJoinCannotDowngradeCounterexampleTest=ready.then(cleanupPstate).then(joinSuccess).then(retireEnvelope).then(badJoinDowngrade).then(all{assert(not(admitted)),s'=s})
  action negativeInit=helperInit.then(finish(0)).then(closeEnrollment)
  action negativeStep=badSeal
}
