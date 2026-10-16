# Process Group Terminal Observation

## Retained Failure

The dispatched-retainer fault campaign remains a DENY. Its retirement checker
exited zero with an exhausted queue, but group probing returned permission
denied and the resulting `processGroupQuiescent` was null. Later native steps
were BLOCKED. Checker success and parent reaping do not establish absence of
remaining process-group members. The previous receipt is not rewritten.

## Framework Contract

`process_observation.probe_group` uses only signal-zero probes: it cannot kill
or change the observed process. ESRCH establishes absence; a successful probe
establishes presence and immediately returns false. Permission denial and EINTR
remain unknown. They may be reobserved for at most 50 milliseconds, bounded
also by the original process deadline. Exhaustion returns null, never true.
An already expired deadline permits the initial observation but no retry wait.
No process, capability or whole-campaign budget is expanded.

Command receipts retain `processGroupProbes` in order, as well as parent reaping,
the terminal quiescence value and total elapsed time. In particular,
`["permission-denied", "absent"]` supports a later absence witness; repeated
permission errors do not. This observation concerns a process group, not
arbitrary detached descendants or correctness of the executed program.

Focused tests cover resolved denial, sustained denial, present groups, expired
budgets and interrupted probes. QNT
`models/gambit/process_group_terminal_observation.qnt` complements them with a
finite two-observation model: accepted implies parent reaped and actual absent
observation. Guessing unknown as absent and ignoring parent reaping must produce
counterexamples. The model abstracts time as remaining observation slots; the
actual monotonic deadline is checked by Python tests, not proved by Quint.

## Native Closure Requirement

`smp-vector-arity-root-sticky-terminal-observation` retains the full previous
owner/root fixture and every model check, then adds mandatory terminal-observation
positive/negative/trajectory checks. It uses the same completed source producer
and the original 300-second whole / 120-second native caps. Framework code changes
require a new immutable seal, not a new runtime bootstrap. Unknown teardown or
failed native assertions still deny the exact ASCENT inventory.

References: [retained root observations](root-cleanup-sticky-retention.md),
[model](../models/gambit/process_group_terminal_observation.qnt),
[recipe](../evidence/research/vm-registry-reader-lease/vector-arity-root-terminal-observation.recipe.json).
