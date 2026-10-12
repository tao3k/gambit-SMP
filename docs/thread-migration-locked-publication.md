# Locked Migration Publication

## Evidence and Causal Review

The archived native SIGSEGV report matches PID 15021 and the executable Mach-O
UUID `e8b96f0e-daa1-3955-9868-149370c7d2e4`. Its faulting frame is
`##btq-remove!`, called from `##thread-schedule-with-acquired-processor!`.
The selected crash projection omits personal paths and host identifiers:
`evidence/source-results/fixtures/thread-migration-shared-regeneration-budget/concurrent-interrupt-crash.json`.
This locates the fault; it does not uniquely prove the interleaving.

Source audit found that migration captured the continuation, detached current
execution and inserted the target queue without holding the thread lock.
Interrupt propagation holds that lock across queue removal and its later
execution-state check. A migration can consequently publish between those
steps, allowing the interrupt callback to insert the same thread again.
By contrast, the established `##thread-yield!` path owns the thread lock while
saving and publishing its continuation.

`thread_migration_interrupt_publication.qnt` reproduces duplicate queue
membership under that unlocked policy: 48 generated / 30 distinct states.
The locked design passes safety and weak-fair completion: 18 generated /
16 distinct states. Queue mutation is abstract atomic; actual tree pointers,
memory ordering, processor trylock progress and GC remain open obligations.
The model is registered with its immutable source/failure context and published
checker artifacts. It is not a complete scheduler proof.

## Source Repair and Build

`evidence/fixtures/thread-migration-locked-publication/source.lock.json` binds
the reproducible 17-file cumulative overlay. The migration function locks the
current thread before capture and releases it only after target queue insertion
has completed and the processor lock has been released. The destination field
and pre-interrupt target-consumption changes are inherited from the metadata
candidate. The rejected explicit-GAMBOPT recipe additions are absent.

The actual isolated GNU GCC core rebuild passed in 10.935708 seconds, with
host-adaptive make concurrency and the original 180-second cap. This is an
incremental source repair build, not a cold build performance measurement or
full two-pass bootstrap. Source and binary identities were checked around each
native observation.

## Stronger Native Checks Reject Full Acceptance

The unchanged compiled canonical migration fixture passed in 0.628165 seconds.
The original concurrent interrupt fixture exited successfully in 0.516638
seconds, but reported 1,159 deliveries against at most 1,152 sends for this
detected host. The raw receipt is preserved, and a separate admission audit
rejects its insufficient exit/marker-only verdict. No silent receipt rewrite
or full-green claim is made.

The strengthened fixture records per-token delivery and preserves the original
fixture bytes alongside their historical receipts. First execution failed via
`thread-join!` with an opaque worker exception. A changed diagnostic fixture
unwraps that reason: `interrupt token delivered twice 52` (exit 70).

A further diagnostic distinguishes replay of a sender iteration from replay
of the same allocated request closure. Sender reservation slots and a fresh
per-request ticket reject both separately. The observed failure is:

```text
same interrupt request callback invoked twice 5
```

Compilation passed in 1.193349 seconds; execution failed with exit 70 after
0.657788 seconds, without timeout, and with a quiescent process group.
Source/binary/fixture hashes are retained in `interrupt-ticket-origin-deny.json`.
These changed checks are diagnostics, not unchanged retries to seek a passing
schedule. The exact callback/request failure must now inform the model.

## Remaining Closure

The lock repair has a positive signal regression, but full native acceptance
remains DENY. Callback claiming, forwarding between processor/thread queues,
completion/acknowledgment, exceptional completion and continuation replay need
joint refinement. A guard that merely suppresses repeated callbacks would not
by itself establish delivery or sender progress. Retired processors, saved
stack/GC roots, failed rollback, complete upstream suites, bootstrap and
Gerbil acceptance remain open. Do not repeat the unchanged duplicate request
campaign until a causal source repair or a new discriminating observation is
available.

The new native-modules sealed ASCENT engine independently passed all 21
guarded retry-inference tests with no skips in 46.459 seconds. The focused
protocol/reflection/build-capacity tests passed 38/38 with no skips. These
framework/native-Datalog outcomes do not override the Gambit callback DENY.
