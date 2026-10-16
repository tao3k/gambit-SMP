# Callback Retirement Native Counterexample

## Native Failure, Not An Injected Fault

The exact vector-arity completed producer has an official `c-define` /
`c-lambda` roundtrip which fails after successful processor shrink and GC.
It uses no `RTLD_NEXT`, join interposition, private cleanup, custom loader or
changed SMP flags. The donor is the last actual processor in the host-managed
VM, not a hardcoded processor identity or CPU count.

The callback retains a Scheme vector, requests shrink to one processor,
requires the successful result, forces GC, checks the vector payload and then
returns integer 42. The original caller must receive 42 through its real C
invocation and complete the worker join. These are native assertions, not a
Python semantic oracle.

Actual output stops at:

```text
CALLBACK-ROUNDTRIP:ENTER
CALLBACK-ROUNDTRIP:SHRUNK
CALLBACK-ROUNDTRIP:BODY-RETURNING
```

`C-RETURNED` and final `PASS` are absent. Native execution reaches its original
30-second cap: 30.006542 seconds, exit -9, timeout true. The native child is
reaped and the process group quiescent. The containing recipe is DENY after
90.329459 seconds within its original 300-second budget; its own timeout is
false. Do not conflate these two timeout scopes.

Native compilation passed in 1.961337 seconds. The pipeline's current-producer
handoff model and existing callback-retirement positive/negative model checks
passed, but the native stage did not. Model PASS is not runtime PASS.

## Source And Model Correspondence

All source claims refer to the versioned
`evidence/fixtures/vector-increment-arity-parity/source.lock.json` and its
overlay, not a build-cache source path.

- `lib/_kernel.scm`, `##current-vm-resize`: migrates the Scheme requester to P0
  before calling the raw resize primitive.
- `lib/setup.c`, `___vm_resize_pstate`: lowers the population, joins retired OS
  threads and transfers/cleans their memory on successful join.
- `lib/_kernel.scm`, `##c-return-on-other-processor`: invokes the configured
  origin-return hook before returning the preserved result.
- `lib/_thread.scm`: that hook migrates to the marker's origin processor;
  `##thread-migrate-to!` publishes the continuation to that processor's queue.

The trace proves that callback body execution and its post-shrink GC completed
but the real C roundtrip did not complete under the cap. The source/model
interpretation is a return-to-retired-origin progress failure; it is not an
instrumented proof of the exact final queue location or a demonstrated heap
corruption. No alternate origin-return hook was installed by this fixture.

`callback_retirement_composition.qnt` already models the distinction between
a heap-saved continuation and its live origin C frame. The existing heap-only
and wait-inside-collective controls remain actual counterexamples. This run
binds that design requirement to a concrete native path rather than adding
another disconnected model.

## Retained Earlier Policy Probe

The separate admission probe required shrink rejection while the callback was
active. The runtime instead returned success, then the probe's rejection
assertion caused exit 70 (0.518400 seconds native). This is failure of a
proposed rejection contract, not by itself a callback-return crash.
The roundtrip successor does not require rejection: it requires successful
shrink, intact GC payload and actual C return. Its timeout is therefore an
independent native lifecycle failure, not the removed policy assertion.
Both original receipts remain unchanged.

## Reproduction And Receipt Identity

Use the existing framework recipes with a fresh bound engine and the selected
completed producer. Neither recipe builds another Gambit toolchain:

- `smp-vector-arity-callback-retirement-admission`
- `smp-vector-arity-callback-retirement-roundtrip`

Roundtrip outer SHA-256:
`49dbaf90f806cdc1b121b1ae44637c46d491d23e64464fe6e8929631cf579d6f`.
Roundtrip child SHA-256:
`5582bd40532b48a4dd693f3bd6891aa1081f9e16441babc3b631b5e516bc0497`.
Admission-probe outer SHA-256:
`3f656fe53858c21b205a298e2e7c29f14eca7a0c8ea67344332dd575cc20849f`.
Diagnostic engine:
`be2acb890384e5bcf8e36535f02a7c2282bc9d0b5777f1cd0f5210af21109eb8`.

The exact declared assets are the two SCM fixtures and Recipes in
`evidence/research/vm-registry-reader-lease`; imported model source is also
declared. Failed native acceptance is preserved. Do not rerun the unchanged
roundtrip merely to obtain another timeout.

## Repair Requirements

Migration of Scheme continuation storage alone is insufficient. Before
retirement, the runtime must account for live external C frames by origin
processor and incarnation. A repair may reject unsafe shrink before collective
entry or otherwise preserve the actual origin OS/C frame until return; merely
redirecting the return hook to P0 cannot relocate a native C stack.

Use the existing `foreign_call_admission.qnt` protocol as a starting point,
with explicit source refinement for atomic admission/close, allocation failure,
conversion failure, nonlocal unwind and exact-once release. Runtime `___run`
markers must not be mistaken for external SFUN leases. Rejecting shrink of a
live origin must not deadlock inside a collective or prevent unrelated VM/GC
work. Origins retained by the target population need separate treatment;
an overly broad all-callback global ban is not established as necessary.

These are unimplemented repair requirements. Native failed-join roots and
exit-tail ownership are additional obligations, not solved by this finding.
SMP remains three of twelve complete gates; full GC/FFI and lifecycle coverage
are still open.
