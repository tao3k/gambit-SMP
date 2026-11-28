// Composition adapter, no new scheduler or context owner.
module link_context_composition {
 import iter_compiler_service.* from "../../../../../models/build/iter_compiler_service"
 import link_stage_contract.* from "./link_stage_contract"
 def attemptFromSession(n:int):Attempt={product:n,context:s.ctx.get(n),workspace:n,
   roots:s.roots.contains(n),frozen:s.born.get(n)==s.epoch and s.observed.get(n)==s.support}
 val admittedPair=s.cpu.contains(0) and s.cpu.contains(1) and live(0) and live(1) and
   parallelAllowed(attemptFromSession(0),attemptFromSession(1))
 action acquirePair=init.then(interfaceComplete).then(supportComplete).then(scheme(0)).then(scheme(1)).then(acquire(0,0)).then(acquire(1,1))
 run sessionPairBridgeTest=acquirePair.expect(safe and admittedPair)
 run sharedOwnerBridgeTest=acquirePair.then(borrowBusy(1,0)).expect(not(safe) and not(admittedPair))
 run pausedPairBridgeTest=acquirePair.then(pause(0)).expect(safe and s.roots.contains(0) and not(admittedPair))
 run editedSupportBridgeTest=acquirePair.then(editSupport).expect(safe and live(0) and not(admittedPair))
 run unknownPairBridgeTest=acquirePair.then(unknownOutcome(0)).expect(safe and s.roots.contains(0) and live(0) and not(admittedPair))
}
