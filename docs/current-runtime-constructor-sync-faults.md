# Current Runtime Constructor Synchronization Faults

## Existing Evidence Is Not Whole-Runtime Acceptance

The previous [owned rollback fixture](vm-constructor-owned-rollback-fixture.md)
checks projected source with substituted allocation/synchronization primitives.
Its positive and negative results remain valid at that source-unit boundary.
They do not establish failure of actual OS synchronization constructors in the
complete current runtime.

Current locked `lib/mem.c:___setup_mem_vmstate` checks VM scan mutex and condition
initialization and destroys only the initialized prefix. Current
`lib/setup.c:setup_sync_op_pstate` checks P0 synchronization initialization;
`___setup_vmstate` unwinds private memory, logs and interrupt resources before
returning. Publication follows successful P0 construction, not failure.

## Declared Next Native Scope

`smp-vector-arity-constructor-sync-faults` binds the completed vector-arity
runtime; no bootstrap is added. It retains the private memory model's full
configuration/failure domain with six unsafe-policy controls and the root
publication model with four controls. Whole budget is 300 seconds; each model
check is 15 seconds and native step 120 seconds. These are not acceptance claims.

The fixture proposes executable-local RTLD_NEXT interposition at four exact OS
objects: VM scan mutex/condvar and P0 sync mutex/condvar. Foreign C owner threads
do not migrate during these constructors, so per-host-thread control is scoped
to the actual address set, unlike the previously rejected Scheme join arming.
Each failure requires effective injection, exact error return, no published
VM, empty private roots/sections, cleared readiness flags and exactly one real
destruction for each successfully initialized prefix member. It then retries the
same private VM storage with actual construction and owned cleanup. Owner count
is derived from available CPUs with one position reserved for the root.

Neither runtime destruction functions nor successful OS initializers are replaced
by success stubs. Invalid destruction ends the test with failure rather than
invoking undefined OS behavior. This remains injected error coverage, not natural
OS error reachability, every allocator failure, root global initialization,
publication race coverage, GC/FFI correctness or leak freedom.

## Execution Boundary

Automatic safety review rejected this campaign before process launch because
RTLD_NEXT interposition and the candidate's exported `___cleanup_owned_vmstate`
were considered inconsistent with an official-loader/FFI-only boundary.
No indirect or sandbox fallback execution was attempted. Human authorization
for this test-only boundary has been requested and is pending. There is no
native result, no timing and no PASS receipt for this recipe.

Declarative graph/scope tests pass after correcting noncanonical step identifiers.
They verify all ten unsafe policies and both unchanged positive model domains
remain required, and no bootstrap capability exists. They do not compile or
execute the native fixture and do not discharge the lifecycle fault gate.
The actual current-runtime Gambit reader also reads all three top-level forms;
it does not evaluate the fixture or compile the embedded C. The explicit
[prelaunch observation](../evidence/research/vm-constructor-owned-rollback/runtime-sync-prelaunch-review.json)
separates the pending proposal's identities and unaffected checks from absent
native timing and acceptance evidence.

References: [native fixture](../models/gambit/native/vm_constructor_sync_faults.scm),
[recipe](../evidence/research/vm-constructor-owned-rollback/vector-arity-runtime-sync.recipe.json),
[current coverage](vector-arity-current-native-coverage.md).
