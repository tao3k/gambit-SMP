# Processor Scan Lock Owned Lifecycle Fixture

## Source Repair

Canonical inputs are `evidence/fixtures/pstate-scan-lock-owned-lifecycle/source.lock.json`
and `patches/fixtures/pstate-scan-lock-owned-lifecycle.patch`. The cumulative
thirteen-file overlay preserves the preceding VM constructor repair. Only
`lib/mem.c` and `include/gambit.h.in` change relative to that Fixture.

Processor memory setup resets the ownership bit before fallible log setup.
For POSIX mutex-backed spin locks it checks the initializer result; failure
releases the already-owned processor log and returns before stack/heap setup.
Ticket and void initializer paths retain their existing result contracts.
Success records ownership. Memory cleanup destroys only an owned lock and
clears ownership, including the repeated P0 memory cleanup in global/VM cleanup.

The processor-state layout changes. Consumers and the complete runtime require
a coherent source rebuild; an old linked binary cannot qualify these bytes.

## Model And Native Observations

The QNT contract explicitly covers two cleanup entries and two slot generations,
log/lock failure, ticket/POSIX/void backends and single-thread mode. Four controls
reject ignored failure, leaked ownership, double destruction and late admission.
Safety and progress finish with 271 generated / 203 distinct / zero queued states.

The locked full `mem.c` and `setup.c` compile with GNU GCC, SMP, multiple VMs and
multiple threaded VMs. The extra memory object uses mutex-backed spin locks.
The typed native callee Recipe projects complete `___setup_mem_pstate` and
`___cleanup_mem_pstate` bodies, not a rewritten approximation. Returning
log/lock/msection/reference-count primitives are injected. Four configurations
pass eight checks each; the parent source is a real exit-1 control.

The first callee campaign passed all C tests but its terminal Datalog inventory
declared two columns for a four-column relation. That DENY remains recorded.
Corrected data declares four positive tuples and the negative tuple, including
binding and boolean polarity. Rules, source/C bodies and budgets are unchanged;
the corrected complete campaign passes. This was an experiment declaration
error, not a source-runtime failure or a relaxed acceptance condition.

Portable observation summaries preserve original receipt and stream hashes,
not complete raw producer archives. Raw runs are disposable; Recipes, locked
submodule/overlay, model sources and native Fixture are committed reproduction
inputs. No maintained experiment-specific Python producer was added.

## Quiescence And Remaining Gates

The source-shaped barrier QNT check now completes safety/progress over 696
distinct states (1,834 generated, zero queued), populations 2..5 and every legal
retained prefix. Local-return-only cleanup and next-GC admission before root
convergence produce separate counterexamples. A live-queue invariant checks
that the next GC uses the retained population, not the old population.

The native `scan-barrier-quiescence-native` Recipe projects actual sync message
macros/wait, tree barrier, operation loop and scan-lock cleanup. POSIX threads,
mutexes and condition variables are real; thread population comes from host
`sysconf(_SC_NPROCESSORS_ONLN)`, not a fixed worker constant. The callbacks are
controlled implementations of GC queue access and cleanup, not Gambit's full
GC/resize functions. Positive convergence drains users before repeated cleanup;
the deliberate early-cleanup control exits 1. Source volatile message fields
and barriers are retained, so a native pass is not a C weak-memory theorem.

The initial loop byte range accidentally selected a forward declaration and
included unrelated function bodies. Two compile-DENY runs are retained; the
second was dispatched before a failed data edit completed. Selecting the
actual definition fixes the projection; no source/C/budget weakening was used.
Neither compile failure is counted as the accepted native negative control.
Portable summaries omit configure-command macros containing host paths while
retaining the original producer stream/receipt hashes.

Ownership is not synchronization. Callers must stop admission and drain remote
scan-queue users before memory cleanup. Current resize enters through
`execute_sync_op_loop`, serializes GC and resize operations, then updates the
processor count synchronously before shrinking processors clean themselves.
Failed growth cleanup applies to constructed but unpublished/unstarted states.
These source locators support the intended boundary, not an independently
verified C barrier/weak-memory theorem. The model assumes this caller contract.

Do not claim asynchronous retirement green from a returning-primitive callee
test. Actual allocator/OS lifetime, native caller quiescence, failed joins,
cross-VM readers, full GC, source bootstrap and Gerbil correctness/performance
remain open. General embedding cleanup requires the same no-active-user
contract. The earlier VM-constructor composition is bound to its own Fixture;
its receipt does not silently qualify this changed ABI/source context.

## Reproduction

### Linked Seed Boundary

The `pstate-scan-lock-owned-lifecycle-seed` Recipe passed in 59.395 seconds
inside the execution receipt (59.582 seconds including the sealed launcher).
GNU GCC built `gsi`, `gsc` and `libgambit.a`; the producer selected the host
processor count automatically. The portable observation binds all thirteen
locked materialized source hashes and the three binary hashes. Runtime source
inventory omits `configure.ac`; materialization records it separately.

This operation uses pre-generated Scheme C. It does not prove regeneration of
the modified SCM, complete bootstrap, full native GC or Gerbil acceptance.
The ownership-field ABI change requires a coherent rebuild, not replacement of
one object in an existing runtime. Both runtime and release admission remain
false. Do not repeat known failing bootstrap routes without a causal review.

### Actual Modified Scheme Regeneration

The `pstate-scan-lock-owned-lifecycle-system-regeneration` Recipe completed in
77.786 seconds, including fresh configure/seed and evidence evaluation.
Actual `lib/_system.scm` regeneration took 16.744 seconds and produced C with
SHA-256 `c891bed9e5b1b217dbc7d19ead7f94faa46727c3521e5af39689579f30b928d8`.
The observation binds the modified SCM hash and the same-campaign seed `gsc`
hash; inputs remained stable and all commands exited zero without timeout.

The existing typed-artifact graph requires a seed from the same campaign, so
this run rebuilt that prerequisite rather than importing an untyped cached
binary. The seed budgets did not expand. This is neither a replay of the known
full `from-scratch` failures nor the numeric test compiler failure route.
The generated C is not linked: other modified SCM, complete bootstrap, full
native GC and Gerbil acceptance remain pending. No runtime/release admission
or performance improvement is inferred from this compilation.

### GC Callback Closure Audit

The locked `mark_reachable_from_marked` releases scan-queue locks before
scanning and releases the termination mutex on its normal exit branches.
`___garbage_collect_pstate` places barriers after strong/weak marking and heap
cleanup. These control-flow observations support the callback-drain premise;
they do not prove complete payload reachability or C weak-memory correctness.

`___release_foreign` clears its release function and pointer before calling the
custom C release function. This prevents repeating that same object's release,
but is not a general prohibition of GC/VM reentry through other objects.
The pinned `doc/gambit.txi` permits custom release functions; the examined
foreign-release documentation does not establish a complete no-reentry
contract. Preserve this as an open composition condition, not a reproduced bug
or a proved runtime guarantee.

Use the stable sealed research engine and a fresh output directory:

```sh
gambit-smp research --run pstate-scan-lock-owned-lifecycle-objects \
  --engine "$SEALED_ENGINE" --allow-native --out "$FRESH_OBJECT_RUN"
gambit-smp research --run pstate-scan-lock-owned-lifecycle-callees \
  --engine "$SEALED_ENGINE" --allow-native --out "$FRESH_CALLEE_RUN"
```

The object Recipe budget is 150 seconds and callee Recipe budget is 120 seconds;
model checks retain the 90-second per-check bound. Local host permission for
autoconf/m4 temporary files is environmental, not a changed budget or source.
