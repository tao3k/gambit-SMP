# Retained Slot Resources Fixture

The semantic Fixture `sync-slot-retained-resources` extends the locked
`pstate-scan-lock-owned-lifecycle` candidate. Only `lib/setup.c` and
`include/gambit.h.in` differ from that parent; all thirteen source files remain
bound to the pinned submodule plus the cumulative overlay. Disposable working
copies are not reproduction origins. The legacy materializer CLI rejects this
thirteen-file inventory; the sealed `gambit.materialize` capability reproduces
and checks it. No legacy file whitelist was weakened.

## Repair And Model Boundary

Each slot records whether its sync mutex/condition pair is owned. Successful
initialization sets ownership; partial POSIX failure still rolls back the
mutex. Reuse resets messages without reinitializing the pair. Fresh VM setup
initializes ownership metadata for every capacity slot. Private P0 publication
failure releases the owned pair; repeated owned cleanup is harmless. Normal
resource destruction occurs in VM cleanup, whose caller must close admission
and drain all processors and remote users first.

The preceding 41-state retained-resource design supports this protocol under
its stated premises. Its receipt remains bound to its original parent context;
it is not silently promoted to a C refinement proof for these new bytes.
The ABI changes and a coherent rebuild is required.

## Actual C Observations

The sealed native callee campaign passed in 8.600 seconds. Actual locked setup
and cleanup bodies passed 38 positive checks: fourteen returning POSIX failure
and reuse checks, ten void-backend checks and fourteen real POSIX checks. Two
VM resource lifetimes each include three slot reuses. In the real POSIX case,
an old sender holds the mutex across the actual setup helper's message reset,
then unlocks/signals and is joined before owned cleanup. The host atomics only
coordinate this schedule; they do not prove production message memory order.

The parent setup-only injected control performs fourteen checks and exits 1.
It uses a no-op cleanup stub because the parent has no owned cleanup helper;
this is not a full parent runtime or a real undefined POSIX reinit attempt.
The mock detects reinitialization before invoking an OS primitive.

Full GNU GCC memory/setup objects and the mutex-backed spin branch passed in
56.763 seconds with all three SMP/multiple-VM/threaded-VM flags enabled.
These are object builds, not bootstrap or performance results.

The first native campaign ended DENY solely because its verdict declaration
used wrong column meanings and omitted source bindings. All C commands had
completed with their declared exits. The exact incorrect Recipe is retained as
`callees-inventory-deny.json`. The correction changes only expected inventory;
source/C/rules and budgets remain unchanged, and the accepted run binds its
prior DENY. Portable summaries retain raw receipt/stream hashes, not complete
producer archives.

## Remaining Full-Chain Conditions

Actual fresh-VM metadata initialization and private-publication caller rollback
need a complete native caller check. Failed joins do not establish safe
reclamation. External/embedding admission and all remote sender drain must be
source-grounded, not inferred from joining a victim alone. Procedural-interrupt
mutex initialization/reuse is a distinct unresolved resource protocol; this
repair does not change it or establish that every slot resource is safe.
Foreign cleanup callbacks and C message memory order also remain open.

No same-candidate full GC, source-regenerated linked runtime, complete bootstrap
or Gerbil full build/test acceptance was run. Runtime and release admission
remain false. Neither the native callee observations nor the model authorize
unchanged retries of historical compiler/bootstrap failures.

## Reproduction

```sh
gambit-smp research --run sync-slot-retained-resources-callees \
  --engine "$SEALED_ENGINE" --allow-native --out "$FRESH_CALLEE_RUN"
gambit-smp research --run sync-slot-retained-resources-objects \
  --engine "$SEALED_ENGINE" --allow-native --out "$FRESH_OBJECT_RUN"
```

Both Recipes retain a 150-second whole budget. The engine seal is immutable;
the source lock, overlay, harness and declarative rules are durable inputs.
