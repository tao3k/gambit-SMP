# Callback Result Physical Relocation Observation

## Exact Scope

The unchanged callback-result source candidate was tested with a new independent
fixture against its freshly regenerated, identified source-core producer.
Source authority remains `vendor/gambit` at the locked revision plus
`evidence/fixtures/callback-return-owned-result/source.lock.json` and the sealed
source-core recipe, not the disposable execution directory. The durable
receipts retain compiler/driver identity, source/fixture hashes, original
budgets, process outcomes and generated fixture C snapshots.

`callbackrelocation.scm` returns a 32-element Scheme vector through a C-defined
`scheme-object` result. The return migration hook forces GC after migration
back to the C-frame owner. It does **not** close over the payload. An integer
records the tagged address before migration; this is not registered as a root
and the old address is never dereferenced. C checks the returned vector's length
and every element before cleanup or another Scheme invocation.

## Native Results

| Migrate | GC in return hook | Address changed | Payload intact | Exit | Seconds |
| --- | --- | --- | --- | --- | --- |
| No | No | No | Yes | 0 | 0.716 |
| No | Yes | No | Yes | 0 | 0.712 |
| Yes | No | No | Yes | 0 | 0.709 |
| Yes | Yes | **Yes** | **Yes** | 0 | 0.707 |

The hook is only invoked for a cross-processor return; the no-migration,
GC-option control therefore does not itself execute that forced collection.
All four cases have no exception, timeout or leftover process group. GNU GCC
build took 0.682 s. Host capacity was discovered as 12: four simultaneous cases
requested three processors each, not a hardcoded 12-processor setting. The
compile budget remains 60 s and each native budget 30 s. These are atomic
correctness observations on the diagnostic source core, not production build
or test speed comparisons.

The earlier compile failed because the C predicate macro required its standard
`___temp` scratch local. Its receipt, exact prior fixture snapshot and log remain
in `physical-relocation-fixture-compile-denial`; it is not a runtime denial or
an admitted result. The successful observations are in
`evidence/source-results/fixtures/callback-return-owned-result/physical-relocation-controls`.

## Generated Root Map

The identified producer's generated `_kernel.c` requires two helper arguments,
saves `R2` into the continuation before calling the one-argument hook, and
reloads it into `R1` on return. Its return descriptor is
`IFD(RETN,5,1,0x6)`. With frame reserve 3 and alignment 4, frame space is 8 words.
The save is at base-relative slot 3 and `STK(-5)` after the 8-word adjustment
reloads that same slot. GC map 0x6 marks slots 2 and 3: the result is a marked root.

The source collector gets the return descriptor, subtracts the frame space to
recover the frame base and passes that map to `mark_frame`, which scans marked
slots. These exact generated/source slices, producer hashes, arithmetic and
the moving-object receipt are bound in
`generated-result-root-map/receipt.json`. This closes one concrete generated
result-slot audit and observes relocation on one actual path, not all register
maps, all continuation transfers or a universal native GC proof.

## Still Open

Nested callbacks, hook exceptions, multiple values, C-frame/processor retirement
reachability, whole GC interaction, complete bootstrap, Gerbil correctness and
matched native performance/stability remain open. The separate
[retirement composition](callback-retirement-composition.md) finds obligations
that this successful relocation observation does not discharge. No runtime or
release admission is granted and no existing performance gate changes.
