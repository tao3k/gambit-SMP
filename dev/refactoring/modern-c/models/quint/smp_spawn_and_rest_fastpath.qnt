// Adversarial Quint V2 protocol model challenging Gambit-SMP v18:
//   1. Direct posix_spawn (non-PTY Darwin) vs legacy multithreaded fork() os_once_t SIGKILL
//   2. One-shot cached rest-observation env probe vs legacy per-call getenv() global lock storm
//   3. NULL-catcher guard in current_vm_resize_request during multi-core cleanup_runtime()

module smp_spawn_and_rest_fastpath {
  // --- Sub-protocol 1: Multithreaded spawn & Darwin libsystem_notify os_once_t ---
  // os_once_state: "uninit" | "initializing" | "ready"
  var osOnceState: str
  var forkInChild: bool
  var atforkCorruption: bool
  var leakedChildFds: bool
  var spawnsCompleted: int
  var useDirectPosixSpawn: bool

  // --- Sub-protocol 2: Rest-parameter observation probe & hot-path lock contention ---
  var envObservationSet: bool
  var envProbedOnce: bool
  var mapOpened: bool
  var hotPathGetenvCalls: int
  var restCallsCompleted: int
  var cacheEnvProbe: bool

  // --- Sub-protocol 3: current_vm_resize_request NULL-catcher boundary ---
  var catcherPresent: bool
  var nullCatcherCrash: bool
  var resizeErrorsHandled: int
  var guardNullCatcher: bool

  // --- Sub-protocol 4: Apple Silicon 128B cache-line isolation & zero-write MESI rest disarm ---
  var cacheLineGuard128: bool
  var zeroWriteDisarm: bool
  var falseSharingFaults: int
  var hotPathGlobalWrites: int

  // --- Sub-protocol 5: Darwin direct posix_spawn child-env PATH resolution ---
  var resolveChildEnvPath: bool
  var childEnvPathMisses: int

  action initWith(directSpawn: bool, cacheProbe: bool, guardCatcher: bool, clGuard: bool, zeroDisarm: bool): bool = all {
    osOnceState' = "uninit",
    forkInChild' = false,
    atforkCorruption' = false,
    leakedChildFds' = false,
    spawnsCompleted' = 0,
    useDirectPosixSpawn' = directSpawn,
    envObservationSet' = false,
    envProbedOnce' = false,
    mapOpened' = false,
    hotPathGetenvCalls' = 0,
    restCallsCompleted' = 0,
    cacheEnvProbe' = cacheProbe,
    catcherPresent' = true,
    nullCatcherCrash' = false,
    resizeErrorsHandled' = 0,
    guardNullCatcher' = guardCatcher,
    cacheLineGuard128' = clGuard,
    zeroWriteDisarm' = zeroDisarm,
    falseSharingFaults' = 0,
    hotPathGlobalWrites' = 0,
    resolveChildEnvPath' = true,
    childEnvPathMisses' = 0,
  }

  action initWithSpawnPath(directSpawn: bool, resolveChildPath: bool): bool = all {
    osOnceState' = "uninit",
    forkInChild' = false,
    atforkCorruption' = false,
    leakedChildFds' = false,
    spawnsCompleted' = 0,
    useDirectPosixSpawn' = directSpawn,
    envObservationSet' = false,
    envProbedOnce' = false,
    mapOpened' = false,
    hotPathGetenvCalls' = 0,
    restCallsCompleted' = 0,
    cacheEnvProbe' = true,
    catcherPresent' = true,
    nullCatcherCrash' = false,
    resizeErrorsHandled' = 0,
    guardNullCatcher' = true,
    cacheLineGuard128' = true,
    zeroWriteDisarm' = true,
    falseSharingFaults' = 0,
    hotPathGlobalWrites' = 0,
    resolveChildEnvPath' = resolveChildPath,
    childEnvPathMisses' = 0,
  }

  action init = initWith(true, true, true, true, true)

  // Sibling thread begins lazy libsystem_notify os_once initialization (e.g. open-tcp-server)
  action siblingBeginNotifyOnce = all {
    osOnceState == "uninit",
    osOnceState' = "initializing",
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    mapOpened' = mapOpened,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  action siblingFinishNotifyOnce = all {
    osOnceState == "initializing",
    osOnceState' = "ready",
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    mapOpened' = mapOpened,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  // Worker calls open-process: direct posix_spawn bypasses libSystem_atfork_child completely;
  // legacy fork() while sibling is initializing os_once corrupts os_once_t -> SIGKILL!
  // When custom child environment supplies PATH=<dir> for a bare executable name,
  // direct posix_spawn MUST resolve along child's PATH (posix_spawnp ignores child env PATH!).
  action spawnProcess = all {
    spawnsCompleted < 6,
    if (useDirectPosixSpawn) all {
      forkInChild' = false,
      atforkCorruption' = atforkCorruption,
      leakedChildFds' = leakedChildFds,
      spawnsCompleted' = spawnsCompleted + 1,
      childEnvPathMisses' = if (resolveChildEnvPath) childEnvPathMisses else childEnvPathMisses + 1,
    } else all {
      forkInChild' = true,
      atforkCorruption' = (atforkCorruption or (osOnceState == "initializing")),
      leakedChildFds' = leakedChildFds,
      spawnsCompleted' = spawnsCompleted + 1,
      childEnvPathMisses' = childEnvPathMisses,
    },
    osOnceState' = osOnceState,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    mapOpened' = mapOpened,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
  }

  // Hot-path rest-parameter call invokes ___rest_note_attempt_entry + ___rest_disarm_attempt
  // across adjacent SMP cores accessing pstate[i]/execution_contexts[i]
  action restParameterCall = all {
    restCallsCompleted < 10,
    if (mapOpened) all {
      envProbedOnce' = envProbedOnce,
      mapOpened' = true,
      hotPathGetenvCalls' = hotPathGetenvCalls,
    } else if (cacheEnvProbe and envProbedOnce) all {
      envProbedOnce' = true,
      mapOpened' = false,
      hotPathGetenvCalls' = hotPathGetenvCalls,
    } else all {
      envProbedOnce' = true,
      mapOpened' = envObservationSet,
      hotPathGetenvCalls' = hotPathGetenvCalls + 1,
    },
    falseSharingFaults' = if (cacheLineGuard128) falseSharingFaults else falseSharingFaults + 1,
    hotPathGlobalWrites' = if (zeroWriteDisarm or mapOpened) hotPathGlobalWrites else hotPathGlobalWrites + 7,
    restCallsCompleted' = restCallsCompleted + 1,
    osOnceState' = osOnceState,
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  // Explicit C test call ___rest_observation_open("/explicit/path") must still succeed even after envProbedOnce
  action explicitRestObservationOpen = all {
    not(mapOpened),
    mapOpened' = true,
    osOnceState' = osOnceState,
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  // Enter cleanup_runtime() where ___ps->catcher == NULL
  action enterCleanupRuntime = all {
    catcherPresent,
    catcherPresent' = false,
    osOnceState' = osOnceState,
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    mapOpened' = mapOpened,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    nullCatcherCrash' = nullCatcherCrash,
    resizeErrorsHandled' = resizeErrorsHandled,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  // current_vm_resize_request catches a sibling error during resize
  action resizeErrorReturn = all {
    resizeErrorsHandled < 4,
    if (catcherPresent or guardNullCatcher) all {
      nullCatcherCrash' = nullCatcherCrash,
      resizeErrorsHandled' = resizeErrorsHandled + 1,
    } else all {
      nullCatcherCrash' = true,
      resizeErrorsHandled' = resizeErrorsHandled + 1,
    },
    osOnceState' = osOnceState,
    forkInChild' = forkInChild,
    atforkCorruption' = atforkCorruption,
    leakedChildFds' = leakedChildFds,
    spawnsCompleted' = spawnsCompleted,
    useDirectPosixSpawn' = useDirectPosixSpawn,
    envObservationSet' = envObservationSet,
    envProbedOnce' = envProbedOnce,
    mapOpened' = mapOpened,
    hotPathGetenvCalls' = hotPathGetenvCalls,
    restCallsCompleted' = restCallsCompleted,
    cacheEnvProbe' = cacheEnvProbe,
    catcherPresent' = catcherPresent,
    guardNullCatcher' = guardNullCatcher,
    cacheLineGuard128' = cacheLineGuard128,
    zeroWriteDisarm' = zeroWriteDisarm,
    falseSharingFaults' = falseSharingFaults,
    hotPathGlobalWrites' = hotPathGlobalWrites,
    resolveChildEnvPath' = resolveChildEnvPath,
    childEnvPathMisses' = childEnvPathMisses,
  }

  action step = any {
    siblingBeginNotifyOnce,
    siblingFinishNotifyOnce,
    spawnProcess,
    restParameterCall,
    explicitRestObservationOpen,
    enterCleanupRuntime,
    resizeErrorReturn,
  }

  val noAtforkCorruption = not(atforkCorruption)
  val boundedEnvProbes = hotPathGetenvCalls <= 1
  val noNullCatcherDeref = not(nullCatcherCrash)
  val noFalseSharing = falseSharingFaults == 0
  val zeroHotGlobalWrites = hotPathGlobalWrites == 0
  val noChildEnvPathMiss = childEnvPathMisses == 0
  val inv = noAtforkCorruption and boundedEnvProbes and noNullCatcherDeref and not(leakedChildFds) and noFalseSharing and zeroHotGlobalWrites and noChildEnvPathMiss

  // --- Positive protocol tests ---
  run fixedDirectSpawnDuringNotifyOnceTest = {
    initWith(true, true, true, true, true)
      .then(siblingBeginNotifyOnce)
      .then(spawnProcess)
      .then(spawnProcess)
      .then(siblingFinishNotifyOnce)
      .expect(inv and spawnsCompleted == 2 and not(forkInChild))
  }

  run fixedCachedEnvProbeAndExplicitOpenTest = {
    initWith(true, true, true, true, true)
      .then(restParameterCall)
      .then(restParameterCall)
      .then(restParameterCall)
      .expect(hotPathGetenvCalls == 1 and not(mapOpened) and hotPathGlobalWrites == 0 and falseSharingFaults == 0)
      .then(explicitRestObservationOpen)
      .then(restParameterCall)
      .expect(inv and mapOpened and hotPathGetenvCalls == 1)
  }

  run fixedCleanupNullCatcherResizeErrorTest = {
    initWith(true, true, true, true, true)
      .then(enterCleanupRuntime)
      .then(resizeErrorReturn)
      .expect(inv and resizeErrorsHandled == 1)
  }

  // --- Adversarial mutation-killers (each proves a legacy v17/v18 defect breaks `inv`) ---
  run legacyMultithreadedForkMutantKilledTest = {
    initWith(false, true, true, true, true)
      .then(siblingBeginNotifyOnce)
      .then(spawnProcess)
      .expect(atforkCorruption and not(inv))
  }

  run legacyPerCallGetenvMutantKilledTest = {
    initWith(true, false, true, true, true)
      .then(restParameterCall)
      .then(restParameterCall)
      .expect(hotPathGetenvCalls == 2 and not(boundedEnvProbes) and not(inv))
  }

  run legacyNullCatcherLongjmpMutantKilledTest = {
    initWith(true, true, false, true, true)
      .then(enterCleanupRuntime)
      .then(resizeErrorReturn)
      .expect(nullCatcherCrash and not(noNullCatcherDeref) and not(inv))
  }

  run legacyFalseSharingPstateContextMutantKilledTest = {
    initWith(true, true, true, false, true)
      .then(restParameterCall)
      .expect(falseSharingFaults == 1 and not(noFalseSharing) and not(inv))
  }

  run legacyUnconditionalDisarmWriteMutantKilledTest = {
    initWith(true, true, true, true, false)
      .then(restParameterCall)
      .expect(hotPathGlobalWrites == 7 and not(zeroHotGlobalWrites) and not(inv))
  }

  run legacyPosixSpawnpIgnoresChildEnvPathMutantKilledTest = {
    initWithSpawnPath(true, false)
      .then(spawnProcess)
      .expect(childEnvPathMisses == 1 and not(noChildEnvPathMiss) and not(inv))
  }
}
