# Modernization and C-to-Zig Evolution Matrix

This report separates mandatory modern-C foundations, runtime/semantic research
and a conditional Zig implementation change. It neither proposes two maintained
implementations of every component nor treats C as a fallback to be discarded.
Read the [foundation](gambit-modernization-foundation.md) and
[source/literature](gambit-modernization-foundation-evidence.md).

| ID / axis | Gambit asset or inspected limitation | Mandatory architectural work in modern C | Potential benefit and new cost | Evidence / decision |
|---|---|---|---|---|
| MV01 C core | Existing C target, generated FFI and native embedding | Explicit generated contracts and retained C capability | Remove duplicate semantic/layout decisions; pay schema/generator/ABI qualification | FS01, FS02; required foundation |
| MV02 true parallel execution | Processor queues and SMP mechanisms exist | Separate worker/context/VM rights; language memory model; shared-state publication | More useful simultaneous execution; scheduling, atomics and contention cost | FS04, FP01, FP03; source capability differs from installed qualification |
| MV03 GC | Movable full copying plus still mark/sweep; parallel STW source path | Root/update closure, nursery/promotion/barriers, independent collector work state | Avoid repeatedly tracing mature graph; pay barrier, promotion, remembered-set and capacity overhead | FS03, FS05, FP01; algorithm choice remains conditional |
| MV04 effects/control | Existing capture/graft, dynamic environment and mutable frames | Explicit delimited handler/resumption states alongside general continuations | Cheap common suspension and modular I/O; pay metadata, cleanup and multishot costs | FS05, FS06, FP02; not just a call/cc alias |
| MV05 C/FFI | Real blocking/callback/RC/marker/native-return paths | Effect-classified entries, rooted borrows, park/reentry and explicit control boundaries | Safe participation and resource custody; pay root publication/reload and adapter costs | FS06, FP02, FP03; native-frame capture not automatic |
| MV06 lifecycle | Existing root/worker/image state coupled to execution | Stable root carriers, resource last-use records and drain protocol | Retain safe progress/reclaim unrelated resources; pay metadata and reader/producer tracking | FO01; unknown host mutation still blocks unsafe actions |
| MV07 compiler/LLVM | Scheme target abstraction and C emitter already separate some responsibilities | Completed semantic plan, root/effect pass legality, independent artifacts/services | Higher-level optimization and shared machine-code infrastructure; pay maps/adapters/provider invalidation | FS01, FS02, FP05; Zig is not a prerequisite |
| MV08 diagnostics | Existing frame/point/source machinery is an asset | Shared source/point/image identity and real unwind/GC views | Debug across workers/effects/native boundaries; pay metadata/code lifetime and symbol work | FS05, FP02, FO01; debug stack and GC roots are distinct |
| MV09 Zig toolchain | Zig can compile C and interoperate with C | Independently qualify the selected tool and full effective configuration | Possible packaging/build integration; no automatic C-source or runtime-language rewrite | FP04; toolchain dependency has its own cost |
| MV10 C-to-Zig implementation | A selected modern-C module is the comparator | Preserve mandatory C contract and identify exact replaced owner/callers | Count eliminated implementation support minus Zig-specific support; duplicate implementation is not presumed | MF11, MF12, FP04, FO01; positive increment unresolved |

MQ01. Quantify algorithmic opportunity without fabricated speedups.

For one fixed workload let L be live movable words examined by the current full
cycle, Y surviving young words, R_y roots relevant to minor collection, D dirty
or remembered entries, W stores subject to the new barrier and P promoted words.
Compare work over the same allocation interval and account for less frequent
mature cycles; comparing one minor cycle with an entire old full cycle would
misstate total benefit.

```text
GC work removed over interval
  > new minor scans/copy + remembered-set work + W*barrier_cost
    + promotion work + mature collection work + extra coordination/metadata
```

Skipping mature continuation graphs additionally requires complete frame/denv/
FFI mutation coverage and dirty-edge tracking. Bounds on Y,D,W,P depend on
actual object lifetime and sharing; none is measured here. Generations alone
do not promise lower latency or lower memory.

MQ02. Quantify multicore and effects on different denominators.

Track useful managed work per worker, synchronization and queue operations,
GC pause distribution, root publication/reload, memory bandwidth, task capture/
resume/clone counts and retained suspended resources. A simple proposed elapsed
time model is serial work plus parallel work divided by worker count, then
coordination/imbalance/GC/memory costs. It is a conditional model, not a scaling
prediction; added workers can worsen these terms. Effects may improve composition
without reducing elapsed time. Single-worker overhead remains an independent gate.

MQ03. Count support owners, not languages in a comparison table.

The prior 13 necessary support families and seven coroutine record kinds are
logical obligations, not 26 systems or 14 duplicated records to maintain. One
Scheme schema and one selected implementation owner per mechanism is the
default. A Zig replacement may reduce private support while retaining the same
semantic obligation; only that concrete eliminated support earns language-specific
credit. Mandatory C-facing headers/wrappers are not necessarily a second full
implementation, but their remaining support still must be counted.

MQ04. Use two positive-benefit gates with hard semantic constraints.

Modernization must demonstrate useful capability/resource/ownership improvement
over current Gambit while preserving required semantics and bounded regressions.
A C-to-Zig replacement must separately show necessary support or resource gains
over the same modern-C design exceed its added provider/ABI/toolchain/upgrade
and migration obligations. Do not sum seconds, bytes and audit obligations into
an arbitrary score or use person-days. State each dimension, required bound and
tradeoff explicitly. No positive aggregate or Zig increment is established here.

MQ05. Research decision.

Modern C is mandatory. Proceed with the shared runtime and compiler foundation;
the OCaml papers inform design choices and counterexamples rather than prescribe
an implementation to copy. Keep C-to-Zig as a replacement hypothesis subject
to MF12. No default dual-runtime maintenance, runtime implementation, retired
path, native profile or promoted full gate results from this study.
