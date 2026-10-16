module compiler_scheduling_diagnostic {
  type State = { changed: bool, control: bool, bound: bool, sameOpt: bool, sameRts: bool,
    sameAbi: bool, smp: bool, budget: int, launched: bool, release: bool }
  var s: State
  action init = s' = { changed:true, control:false, bound:true, sameOpt:true, sameRts:true,
    sameAbi:true, smp:true, budget:90, launched:false, release:false }
  action initUnchanged = s' = { changed:false, control:false, bound:true, sameOpt:true, sameRts:true,
    sameAbi:true, smp:true, budget:90, launched:false, release:false }
  action initDefaultControl = s' = { changed:false, control:true, bound:true,
    sameOpt:true, sameRts:true, sameAbi:true, smp:true, budget:90,
    launched:false, release:false }
  val eligible = (s.changed or s.control) and s.bound and s.sameOpt and s.sameRts and s.sameAbi
    and s.smp and s.budget <= 90 and not(s.launched)
  action launch = all { eligible, s' = { ...s, launched:true } }
  action hold = s' = s
  action step = any { launch, hold }
  val safe = s.launched.implies((s.changed or s.control) and s.bound and s.sameOpt and
    s.sameRts and s.sameAbi and s.smp and s.budget <= 90) and not(s.release)
  run diagnosticTest = init.then(launch).then(all { assert(safe), s' = s })
  run unchangedControlTest = initUnchanged
    .then(all { assert(not(eligible)), s' = s })
  run defaultControlTest = initDefaultControl.then(launch)
    .then(all { assert(safe and not(s.changed) and not(s.release)), s' = s })
}
