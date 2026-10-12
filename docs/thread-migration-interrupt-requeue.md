# Migration Interrupt Requeue Audit

## Review Before Source Changes

The resume gate candidate prevents remote stealing but does not retain a
migration destination across every queue operation. This is a distinct gap
from the previously reproduced immediate migration return failure. No new
runtime failure is claimed here and no source repair is admitted by this audit.

The candidate remains reproducible from
`evidence/fixtures/thread-migration-resume-gate/source.lock.json` and its
cumulative overlay. The lock digest is
`753e288571bf732add80dfd7bbd585162fd1a05c93b85c88f525971e2bd70564`.

Source correspondence in the locked `_thread.scm`:

- `##thread-intr-propagate!` removes the existing queue entry through
  `##thread-lock-remove-btq-toq!`, records the interrupt, and requeues a
  non-current thread using the preferably-current-processor helper.
- That helper selects the user-pinned processor, or the interrupt sender's
  processor when the thread is unpinned. It does not inspect pending migration.
- The candidate's remote steal guard recognizes the migration completion
  action. Local queue extraction is still allowed, including extraction from
  a queue selected by the interrupt helper.

This path is worth repairing for destination correctness, not a measured
performance gain. Repeating the unchanged parent migration failure or a full
bootstrap would not establish closure of this new queue interaction.

## Finite Model Observation

`models/gambit/thread_migration_interrupt_requeue.qnt` starts after saved
continuation publication. Donor, destination and interrupt sender are roles;
they do not impose a processor limit. An interrupt can remove/requeue the
thread before local claim. The design variant retains the explicit destination
while the migration gate is pending, independently of user affinity.

Executed with Quint 0.33.0 and its TLC backend:

```sh
quint typecheck models/gambit/thread_migration_interrupt_requeue.qnt
quint verify models/gambit/thread_migration_interrupt_requeue.qnt \
  --backend tlc --init initOld --invariant safe
quint verify models/gambit/thread_migration_interrupt_requeue.qnt \
  --backend tlc --init initFixed --invariant safe --temporal completion
```

- Typecheck passed.
- Existing routing: invariant violation, 6 generated / 5 distinct states.
  Trace: destination queue -> interrupt sender queue -> sender claims thread.
- Destination-preserving design: safety and fair completion passed,
  16 generated / 12 distinct states, including initially pinned/unpinned cases.

These are direct checker observations, not a published protocol bundle or
source-bound implementation proof. The model does not cover cancellation,
nested migration, processor retirement, failed publication, GC frame copying,
or arbitrary interrupt histories. Completion assumes weak fairness of modeled
steps. Those requirements remain open before any full-green claim.

## Native Datalog Test Boundary

The previously reported 66 framework tests contained 45 actual passes and
21 skipped native inference tests. The guarded class requires a sealed native
engine, including loading its implementation rather than editable Python.

The shared-build-budget engine's manifest, complete inventory and host tool
digests passed verification. Engine ID:
`e91e7d2c531584b80650e8c760dfb3de26eb2924e7d242f4f32d570820f821d9`.

With the sealed package first on `PYTHONPATH`, all 21 tests were attempted:
10 passed and 11 errored in 11.074 seconds. The native worker rejects its
installed API because `describe` does not advertise `open-sources`:
`installed ASCENT engine lacks the upstream native DSL entry`.
This is a provider/interface blocker, not 11 failed Gambit assertions.

A single diagnostic rerun retained worker stderr through the existing
`GAMBIT_SMP_TEST_ARTIFACTS` hook. No guards, expected results, deadlines,
Python framework code or native provider code were changed. Do not repeat the
same sealed-engine campaign until its provider interface identity changes.

### Updated Native Provider Observation

The provider pairing changed to the native-modules sealed engine with ID
`883d44c14ee0b614413a80e8862fadb2087611af6d7c1351f40ad6f68ff69f56`.
The calling task independently verified its complete 1,290-file inventory,
manifest identity and host-tool hashes before running the guarded class with
the sealed package first on `PYTHONPATH`.

`tests.test_native_retry_review.NativeRetryInferenceTests` then completed:
21 tests, 46.459 seconds, exit 0, no failures, errors or skips. This is a direct
unittest execution observation, not a sealed research campaign receipt or
complete Gambit native qualification. No guards or expectations were changed.
The old provider failure remains historical evidence; it is not the current
blocker. The current native blocker is the separately recorded duplicate
callback failure in `thread-migration-locked-publication.md`.

## Next Source Requirements

Pending migration needs an explicit destination identity that survives queue
removal/reinsertion and is consumed only by the intended owner. Do not overload
the public pinned field, thread-specific data, or last-processor execution
history. Audit any new metadata against thread constructors, generated layout,
root scanning, interrupt reentrancy, cancellation and destination retirement.
Model those interactions before changing the cumulative source overlay.
