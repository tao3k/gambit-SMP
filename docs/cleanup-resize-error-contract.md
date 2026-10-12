# Cleanup Resize Error Contract

## Path Review

This path is worth investigating for correctness, not an expected speed gain.
The existing `vm_retirement_join_composition` already distinguishes an OS-exit
witness from a failed join. The new finding connects that obligation to the
actual global cleanup caller rather than repeating the local retirement model.
No end-to-end performance improvement is claimed.

Authority is the pinned submodule and
`evidence/fixtures/scheduler-retry-sync-participation/source.lock.json`.
Current `lib/setup.c:___vm_resize_pstate` publishes the reduced population,
calls `___thread_join`, transfers/frees a retired processor's memory only on
success, and otherwise retains the first join error in its return value.
`___cleanup` publishes setup state 2, disables interrupt handling, invokes
`___current_vm_resize(..., 1)` without checking its result, then calls
`___cleanup_pstate`, `___cleanup_vmstate` and global OS/memory cleanup.
`___cleanup_vmstate` states that callers must first drain all processors/users.
A reduced population does not itself establish that precondition.

PR793's setup-state guard addresses a different NULL-catcher throw during
cleanup. It does not check the resize result or establish retired OS-thread
quiescence. The older shutdown and retirement models are context references,
not imported/composed proofs of the new caller boundary.

## Source Observation

The fixture `cleanup_resize_error_contract.c` includes the exact locked
`___cleanup` definition as mechanically extracted source, without changing its
body. Configuration is SMP with the single-VM branch selected. Resize and
destruction functions are explicitly mocked. The injected nonzero return is an
arbitrary error sentinel, not a locally reproduced POSIX error code.

GNU GCC compilation succeeds in 0.160 seconds. The successful-resize control
records zero unsafe-release calls; the injected-error control records two
destruction calls while its unjoined witness remains set. Both fixture
executions exit zero because they report observations, not because both
protocol outcomes are correct. `unsafeReleases` counts calls to mocked cleanup
functions, not observed native frees or a reproduced use-after-free.

The source lock is independently materialized for this check. The receipt binds
materializer inputs, full candidate setup source, exact extracted function and
fixture hashes. No execution-cache path is a source authority. Evidence is under
`evidence/source-results/fixtures/scheduler-retry-sync-participation/cleanup-error/`.

## Model And Repair Boundary

`cleanup_resize_error_contract.qnt` records cleanup publication, population
reduction, successful/failed join outcome and reclamation. The current-policy
counterexample has seven distinct states; the conditional positive policy also
checks seven states and passes safety/fair completion. On failed join it produces
an explicit quarantine outcome without reclamation.

That positive policy is not implemented in the runtime. Quarantine is not
successful cleanup or leak-free recovery. A void cleanup API, later setup/reentry,
library unload, ownership of retained processors/resources, and communication of
the original error all require a coherent caller contract. An early return that
silently leaves resources allocated would not discharge these requirements.
The inspected `___setup` entry validates setup parameters, then overwrites
setup state and resets processor count without a preceding quarantine-state
check. The standalone main calls void `___cleanup` and assigns an OK exit code;
the pthread embedding example also invokes void cleanup. Therefore a silent
early-return patch would neither communicate failure nor prevent reuse of
retained state. These are source/caller observations, not an executed embedding
failure or proof of every external embedding contract.
The model assumes a successful join supplies an exit witness; actual reachability
of the injected failure and native lifetime behavior remain to be established.

Required next work is to compose error delivery/catcher withdrawal with failed
join and retained-resource ownership, audit embedding callers, establish an
explicit failure disposition, and validate source/native behavior before
promoting a patch. Full GC, native suites, bootstrap and Gerbil remain open.
