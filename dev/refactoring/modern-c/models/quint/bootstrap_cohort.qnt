// Two coverage classes: Scheme-emitted C and linker-emitted C.
// Native inventories refine these classes; this is not a compiler-correctness proof.
module bootstrap_cohort {
  type Cohort = {host:bool, argv:bool, generated:Set[int], target:bool,
    selfGenerated:Set[int], selfBuilt:bool, semantics:bool, hostLinked:bool}
  var s:Cohort
  val classes=Set(0,1)
  pure val empty:Cohort={host:false,argv:false,generated:Set(),target:false,
    selfGenerated:Set(),selfBuilt:false,semantics:false,hostLinked:false}
  action init={s'=empty}
  action qualifyHost=all{not(s.host),s'={...s,host:true}}
  action canonicalize=all{s.host,not(s.argv),s'={...s,argv:true}}
  action emit={nondet i=classes.oneOf();all{s.host,s.argv,not(s.generated.contains(i)),
    s'={...s,generated:s.generated.union(Set(i))}}}
  action buildTarget=all{s.generated==classes,s.argv,not(s.target),s'={...s,target:true}}
  action selfEmit={nondet i=classes.oneOf();all{s.target,not(s.selfGenerated.contains(i)),
    s'={...s,selfGenerated:s.selfGenerated.union(Set(i))}}}
  action buildSelf=all{s.target,s.selfGenerated==classes,not(s.selfBuilt),s'={...s,selfBuilt:true}}
  // The native oracle must separately establish the real map/GC result.
  action observeSemantics=all{s.selfBuilt,not(s.semantics),s'={...s,semantics:true}}
  action step=any{qualifyHost,canonicalize,emit,buildTarget,selfEmit,buildSelf,observeSemantics,s'=s}
  val safe=all{
    s.generated.size()>0 implies (s.host and s.argv),
    s.target implies (s.generated==classes and s.argv),
    s.selfGenerated.size()>0 implies s.target,
    s.selfBuilt implies (s.target and s.selfGenerated==classes),
    s.semantics implies s.selfBuilt,
    not(s.hostLinked)
  }
  action check=all{safe,s'=s}
  run fullChainTest=init.then(qualifyHost).then(canonicalize).then(emit).then(emit)
    .then(buildTarget).then(selfEmit).then(selfEmit).then(buildSelf).then(observeSemantics).then(check)
  action legacyTarget={s'={...empty,host:true,argv:true,generated:Set(0),target:true}}
  action onlyProcessArgv={s'={...empty,host:true,generated:Set(0)}}
  action hostPassAsSelf={s'={...empty,host:true,argv:true,generated:classes,target:true,selfBuilt:true}}
  action nativeBeforeBootstrap={s'={...empty,semantics:true}}
  action importHostRuntime={s'={...empty,hostLinked:true}}
}
