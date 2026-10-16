module darwin_dynamic_modulo_scope {
  // Flag-scope abstraction only: no compiler correctness or speed claim.
  type State = { host: str, compiler: str, surface: str, optEnabled: bool,
    supported: bool, policy: str, applied: bool, changed: bool,
    instructionSchedule: bool, rtsOpt: int, smp: bool, release: bool }
  var s: State
  pure def initial(host: str, compiler: str, surface: str, optEnabled: bool,
    supported: bool, policy: str): State = {
    host: host, compiler: compiler, surface: surface, optEnabled: optEnabled,
    supported: supported, policy: policy, applied: false, changed: false,
    instructionSchedule: true, rtsOpt: 3, smp: true, release: false,
  }
  // Separate actions avoid Quint's shared init-action TLA conversion restriction.
  action init = {
    nondet host = Set("darwin", "linux", "windows").oneOf()
    nondet compiler = Set("gnu", "clang", "llvm").oneOf()
    nondet surface = Set("dynamic", "rts", "executable").oneOf()
    nondet optEnabled = Set(false, true).oneOf()
    nondet supported = Set(false, true).oneOf()
    s' = initial(host, compiler, surface, optEnabled, supported, "dynamic-only")
  }
  action initShared = {
    nondet host = Set("darwin", "linux", "windows").oneOf()
    nondet compiler = Set("gnu", "clang", "llvm").oneOf()
    nondet surface = Set("dynamic", "rts", "executable").oneOf()
    nondet optEnabled = Set(false, true).oneOf()
    nondet supported = Set(false, true).oneOf()
    s' = initial(host, compiler, surface, optEnabled, supported, "shared-flags")
  }
  action initPlatform = {
    nondet host = Set("darwin", "linux", "windows").oneOf()
    nondet compiler = Set("gnu", "clang", "llvm").oneOf()
    nondet surface = Set("dynamic", "rts", "executable").oneOf()
    nondet optEnabled = Set(false, true).oneOf()
    nondet supported = Set(false, true).oneOf()
    s' = initial(host, compiler, surface, optEnabled, supported, "all-platforms")
  }
  action initCompiler = {
    nondet host = Set("darwin", "linux", "windows").oneOf()
    nondet compiler = Set("gnu", "clang", "llvm").oneOf()
    nondet surface = Set("dynamic", "rts", "executable").oneOf()
    nondet optEnabled = Set(false, true).oneOf()
    nondet supported = Set(false, true).oneOf()
    s' = initial(host, compiler, surface, optEnabled, supported, "all-compilers")
  }
  val expected = s.host == "darwin" and s.compiler == "gnu"
    and s.surface == "dynamic" and s.optEnabled and s.supported
  action apply = all {
    not(s.applied),
    s' = { ...s, applied: true, changed:
      (s.host == "darwin" or s.policy == "all-platforms")
      and (s.compiler == "gnu" or s.policy == "all-compilers")
      and (s.surface == "dynamic" or s.policy == "shared-flags")
      and s.optEnabled and s.supported },
  }
  action step = any { apply, s' = s }
  val safe = (not(s.applied) or s.changed == expected)
    and s.instructionSchedule and s.rtsOpt == 3 and s.smp and not(s.release)
  val dynamicOnly = not(s.changed) or s.surface == "dynamic"
  val platformOnly = not(s.changed) or s.host == "darwin"
  val compilerOnly = not(s.changed) or s.compiler == "gnu"
  temporal completion = weakFair(apply, s).implies(eventually(s.applied))
}
