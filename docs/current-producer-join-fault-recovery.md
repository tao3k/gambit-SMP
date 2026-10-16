# Current Producer Join Fault Recovery

## Protocol And Retained Counterexamples

The current vector-arity producer is consumed by
`smp-vector-arity-pending-join-errno-recovery` using `gambit.completed-runtime`.
No bootstrap is repeated. The successor preserves every step, dependency,
fixture assertion and budget from the previously verified
`smp-pending-join-errno-native-recovery`; only source/patch/producer bindings
and the recipe identity change.

Earlier faulty fixture routes remain in
[the native checkpoint](vm-global-cleanup-native-checkpoint.md): OS-thread-local
arming did not follow VM ownership, one C-lambda failed compilation, and an
exception expectation did not match the encoded errno returned by resize.
Those unchanged failed programs are not rerun. The unchanged corrected fixture
requires the exact `___FIX(___ERRNO_ERR(EINVAL))` result and effective injection
counts, not merely absence of a crash.

QNT checks bind completed-producer handoff, kernel/TLS entry, resize grace,
processor retirement, failed-join retention and global-cleanup preflight.
Positive checks, unsafe-policy counterexamples and declared trajectories all
remain required. The existing Scheme execution rules and ASCENT exact-step
verdict are used; no separate evidence engine is introduced.

## Actual Current-Producer Result

All 32 steps passed. Inspection returns PASS/CURRENT, with both runtime and
source-refinement admission still false.

| Measure | Observed seconds | Original cap |
| --- | ---: | ---: |
| Whole campaign | 89.477214 | 300 |
| Executable compilation | 3.067532 | Part of native step |
| Native execution | 0.851818 | Part of 120-second native step |

Native execution exited zero, produced the exact pass marker and no stderr,
and did not time out. The host-derived owner population reserves two CPU
positions and allocates at least two processors per concurrent VM. It is not
a fixed VM or processor count. Each owner checks private forced-GC roots,
one resize join failure, one owner-cleanup join failure, retained pending
ownership and successful retry before release. Global cleanup is rejected
while children retain pending joins, without changing ready setup state.

Outer receipt SHA-256:
`df909b01966a400907f96687d1178d4dc4b9a87724a36bf3ef83c8b8762070c8`.
Child receipt SHA-256:
`e9dd3c80ae04e1cda607e1fd7fa99aad092bb0b92142a8fa24d88e1a08e4070a`.
Engine:
`719dfb5cf4a184ea83e65cdfc6d80219e5b563a80e5e3c207257b994db10a30d`.

## Requirements Not Discharged

This bounded interposition test demonstrates recovery from injected POSIX join
errors, not natural OS error reachability or all lifecycle failures. Root VM
sticky cleanup failure, constructor rollback, direct-user ownership, API
reentry/linker generation, GC/FFI interaction and physical memory-order
refinement still require their own source-bound evidence. The complete GSC,
compiled PR and both stress gates remain open. No old timeout or counterexample
is erased by this result, and acceptance remains 3/12 coverage gates.

References: [current coverage](vector-arity-current-native-coverage.md),
[milestone requirements](smp-threaded-vm-milestone.md),
[retention model](../models/gambit/vm_registry_failed_join_retention.qnt),
[global preflight model](../models/gambit/vm_registry_global_cleanup_preflight.qnt),
[reproducible recipe](../evidence/research/vm-registry-reader-lease/vector-arity-pending-join-errno.recipe.json).
