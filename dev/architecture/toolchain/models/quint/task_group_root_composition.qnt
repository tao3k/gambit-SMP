// Product-state adapter for one preparation member, not a new owner.
module task_group_root_composition {
 import preparation_reuse as P from "./preparation_reuse"
 import task_group_roots as R from "./task_group_roots"
 action begin=all{P::beginProducer,R::r'=R::r}
 action reserve=all{P::reserveFromParent(1,0),R::r'=R::r}
 action initialize=all{P::initializeMember(1,0),R::r'=R::r}
 action publishMember=all{P::publishMember(1,0),R::r'=R::r}
 action claimMember=all{P::claimMember(1,0),R::r'=R::r}
 action spawn=reserve.then(initialize).then(publishMember).then(claimMember)
 action write=all{P::writeFromChild(1,0),R::r'=R::r}
 action settle=all{P::settleChild(1,0),R::r'=R::r}
 action parent=all{P::parentSuccess,R::r'=R::r}
 action verify=all{P::verifyOutputs,R::r'=R::r}
 action seal=all{P::sealSuccessor,R::r'=R::r}
 action uncheckedKnown=all{P::recordMemberResult(1,0,0),R::r'=R::r}
 action registerPayload=all{R::registerPayload,P::s'=P::s}
 action transferSource=all{R::transferSource,P::s'=P::s}
 action publishRooted=all{R::publish,P::s'=P::s}
 action claimRooted=all{R::claim,P::s'=P::s}
 action rootReady=registerPayload.then(transferSource).then(publishRooted).then(claimRooted)
 action exit=all{R::schemeExit,P::s'=P::s}
 action effects=all{R::closeEffects,P::s'=P::s}
 action rootResult=all{R::registerResult,P::s'=P::s}
 action commit=all{R::commitResult,P::s'=P::s}
 action launch=all{R::launchUnknown,P::s'=P::s}
 action observer=all{R::pin(1,0),P::s'=P::s}
 action close=all{R::closeObservers,P::s'=P::s}
 action freezeRoots=all{R::freeze,P::s'=P::s}
 action scanRoots=all{R::scan,P::s'=P::s}
 action thawRoots=all{R::thaw,P::s'=P::s}
 action start=all{P::init,R::init}.then(begin).then(spawn).then(rootReady)
 val localKnown=R::r.resultKnown and R::r.process!=1 and R::r.effectsClosed
 val safe=P::safe and R::safe and
   (Set(4,5,7).contains(P::s.phase.get(0)) implies localKnown) and
   (P::s.members.contains(0) implies R::r.contextHeld and R::r.descriptorHeld and (R::r.sourceHeld or R::r.roots.contains(0)))
 action recordKnown=all{localKnown,P::recordMemberResult(1,0,0),R::r'=R::r}
 action finishLocal=exit.then(effects).then(rootResult).then(commit)
 run rootedMemberCompositionTest=start.expect(safe and P::s.members.contains(0) and R::r.roots.contains(0))
 run unknownProcessCompositionTest=start.then(launch).then(exit).expect(safe and not(localKnown) and not(R::canRetire))
 run knownDrainCompositionTest=start.then(write).then(finishLocal).then(recordKnown).then(settle).then(parent).then(verify).then(seal).expect(safe and P::s.sealed and not(R::r.retired))
 run pinnedSuccessorCompositionTest=start.then(write).then(finishLocal).then(observer).then(recordKnown).then(settle).then(parent).then(verify).then(seal).then(close).expect(safe and P::s.sealed and not(R::canRetire))
 run gcUpdateCompositionTest=start.then(freezeRoots).then(scanRoots).then(thawRoots).expect(safe and R::currentSlot(0))
 run uncheckedKnownNegativeCompositionTest=start.then(launch).then(exit).then(uncheckedKnown).expect(not(safe))
}
