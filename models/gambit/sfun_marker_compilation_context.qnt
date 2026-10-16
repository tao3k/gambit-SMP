module sfun_marker_compilation_context {
  var localState: bool
  var stateBound: bool
  var passedProcessor: bool
  var emitted: bool
  var sharedState: bool
  action init = {
    nondet local = Set(false,true).oneOf()
    all { localState'=local, stateBound'=true, passedProcessor'=true, emitted'=false, sharedState'=false }
  }
  action initOld = all { localState'=true, stateBound'=false,
    passedProcessor'=false, emitted'=false, sharedState'=false }
  action initStatic = all { localState'=true, stateBound'=true,
    passedProcessor'=true, emitted'=false, sharedState'=true }
  action emit = all { not(emitted), localState'=localState,
    stateBound'=stateBound, passedProcessor'=passedProcessor, emitted'=true, sharedState'=sharedState }
  action hold = all { localState'=localState, stateBound'=stateBound,
    passedProcessor'=passedProcessor, emitted'=emitted, sharedState'=sharedState }
  action step = any { emit, hold }
  val compiles = emitted.implies(not(localState) or stateBound)
  val owner = emitted.implies(passedProcessor)
  val safe = compiles and owner and not(sharedState)
  run contextTest = init.then(emit).then(all { assert(safe), hold })
  run missingContextControlTest = initOld.then(emit)
    .then(all { assert(not(compiles)), assert(not(owner)), hold })
  run staticBindingControlTest = initStatic.then(emit)
    .then(all { assert(compiles), assert(not(safe)), hold })
}
