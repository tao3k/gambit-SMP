# Registry Retirement And Reuse: Independent Source-Component Review

## Decision

Prefer Scheme-owned lifecycle policy and retain the native compilation chain.
There is no assumed patch/boundary percentage. Do not replace Scheme execution
with Rust or infer that a foreign wrapper can repair collector-visible lifetime.

The reviewed current runtime already implements atomic reader admission,
close/drain, leased replay, prepared population publication and terminal sealing.
No new runtime defect was established in those mechanisms by this review. The
minimal runtime change is therefore **none**. Reapplying their historical fixes
would duplicate work. This review adds a missing deterministic same-address
reuse witness and its mutation controls, not a new registry/model/framework.

The independent native owner is qualifying the registry topology and extending
the existing multi-writer model's replay/lease composition. This review does not
edit that model, source overlay, recipe, view registry, producer or acceptance
receipt. Its component results do not close that owner's whole milestone gate.

## Source identities

- Repository snapshot: `693417636bd9aaaef298d5bdb21aa06b47f024a7`.
- Gambit baseline: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
- Current source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
- Cumulative overlay: `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
- Materialized `lib/setup.c`: `9e1d3b608f8b089435a5999e74a10ffea89e83a76318a8bc8b9a9b77a2a0cce3`.
- Chez: `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`.
- OCaml: `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.

All 26 materialized candidate source files match the current lock. Reference
source bytes match the existing Chez/OCaml source inventories. Model transitions
were not modified; the three reused model digests are recorded in `receipt.json`.

## Transfer from reviewed implementations

| Reference | Mechanism actually read | Gambit obligation and transfer limit |
|---|---|---|
| Chez `c/thread.c:264-352` | Flush remembered allocation state, close segments, transfer guardians, redirect and retain `thread_gc` because segments retain its identity; then free TC. | Ending execution is not permission to invalidate every referenced descriptor. Audit surviving references and retain/transfer them. This does not require keeping every Gambit VM allocation forever. |
| OCaml `runtime/domain.c:2262-2423` | Drain marking/sweeping, repeat when orphaning creates work; withdraw under membership lock only without pending requests; retain domain lock during teardown before state reuse. | Distinguish participation withdrawal, reader quiescence, destruction and reuse. A pending obligation can prevent withdrawal. This does not import OCaml's collector or backup thread architecture into Gambit. |
| Gambit current `lib/setup.c:122-218` | Atomically acquire reader admission, close before draining, and acquire a new reader lease for replay. | A second writer must wait for a replay reader, including when storage is reused at the same address. C source has this protocol; the multi-writer model composition is a separate obligation. |
| Gambit current `lib/setup.c:5304-5343` | Reject undrained cohorts/foreign frames, hold writer mutex, close/drain before cleanup, reopen secondary teardown only. | Registry leases do not cover arbitrary external PSTATE owners; callers must join them. Processor count alone does not establish successful OS joins. |

Scheme can own task admission, cancellation acknowledgement, join discipline,
structured cleanup and whether a handle remains usable. Signal-time C registry
pointer capture and atomic publication cannot be made safe merely by adding a
Scheme wrapper: the raw reader can execute before Scheme code regains control.
Keep this minimal native mechanism until a source-backed replacement has its
own correctness and cost evidence. Neither a host language change nor an
arbitrary serialization lock is selected here.

## Executable gap and minimal correction

The existing native topology fixture allocates/frees child VMs and tests later
populations, but does not force an allocator to return a specific address. A
successful repetition is not a deterministic same-address reuse witness.

`component.c` compiles the **unaltered current registry functions** extracted
from the locked `setup.c`. It supplies a deliberately small fake destination
list and interrupt sink; it does not substitute admission/drain/replay logic.
The three atomic macros use the selected source header's GNU sync builtins.

The test explicitly holds a reader, starts a closing writer, observes admission
closed with that reader still counted, and permits reuse only after release.
The same physical slot changes generation. A separate blocked replay delivery
keeps its reader lease while another writer attempts replacement. No sleeps or
probabilistic allocator behavior establish either ordering.

Other controls check a pending publication after a writer has already flushed,
requiring delivery without a future writer; terminal sealing must survive an
ordinary reopen attempt. A thousand bounded cycles check reentry and delivery.

Two source mutations test witness sensitivity: remove admission counting, or
bypass replay admission. Each must terminate with the targeted assertion and
SIGABRT (exit 134), rather than time out or be accepted. They are intentionally
mutated source components, not newly attributed historical runtime failures.

## Results

Apple clang 21.0.0, macOS arm64, native OS threads:

- Native component: four deterministic contracts and 1,000 cycles PASS.
- Separate ASan binary: same contracts and cycles PASS, no report.
- Separate TSan binary: same contracts and cycles PASS, no report.
- Two mutation controls: expected targeted assertions, exit 134.
- Existing `vm_registry_repeated_retirement`: 3 controls PASS.
- Existing `vm_registry_processor_retirement`: 3 controls PASS.
- Existing `vm_registry_failed_join_retention`: 4 controls PASS.

Quint 0.33.0 runs use seed `0x19`, one sample per declared run. These ten
explicit control traces are not exhaustive model checking or a new temporal
proof. The native component has a five-second alarm and never starts Gambit,
Rust, bootstrap, the original stress suite or a downstream build. The expected
mutation aborts do not create core dumps.

## Reproduce and limits

Given a separately materialized current source matching the existing lock:

```sh
evidence/review/registry-retirement-reuse/run.sh "$PWD" MATERIALIZED_SOURCE FRESH_OUTPUT
```

The output must be new; source SHA mismatch fails before compilation. Current
source results precede mutation controls. All logs are retained in the output.

This checks compiled registry-function behavior against fixture destinations.
It does **not** qualify real VM allocation, actual heap roots, generated Scheme
frames, signal-handler reentrancy, OS join failure, native descriptor release,
arbitrary population, weak-memory refinement or complete GC/FFI. ASan sees the
fixture's allocation/access boundaries, not internal Gambit object lifetimes;
TSan silence on this component is not whole-runtime race freedom. Sanitizer
costs are not release-performance samples. No 8/12 or stable runtime claim is
made here. The existing native owner's same-producer acceptance remains the
whole-registry gate, including the pending replay/second-writer composition.

The attempted Trajectory query in an isolated snapshot failed because the
installed ASCENT binding references rules outside that snapshot root. No query
result was admitted, no new routing layer was introduced, and the shared
reasoning database was not written. This is a tooling portability gap, not a
runtime failure or justification for duplicating the evidence framework.
