# Experimental Concurrent Generational GC

This is design research, not a runtime patch, accepted collector, source
refinement, nonblocking proof or performance result. Existing Gambit SMP,
multiple-VM and threaded-VM obligations remain unchanged. Actor optimization
is paused and is unrelated to these new model assets.

## Source And Literature Boundaries

The pinned vendor Gambit revision is
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
`vendor/gambit/lib/mem.c:61-84` distinguishes permanent, still and movable
objects. Still objects do not move but may be reclaimed; their fields can
therefore still participate in tracing. Nonmoving addresses alone do not
justify concurrent reclamation or omission of cross-generation barriers.
The `MOVABLE0` representation comment is not evidence of a complete
generational or concurrent protocol. No barrier source refinement is claimed.

The existing Chez `GenerationCards.qnt` model explicitly assumes stopped
mutators. Its remembered-card experiments are useful prerequisites but are
not concurrent marking evidence. The existing shared GC work contracts retain
their original stopped-mutator bounds; they have not been silently widened.

Primary research references screened for this experiment:

- Marlow, Harris, James and Peyton Jones, *Parallel Generational-Copying
  Garbage Collection with a Block-Structured Heap*, ISMM 2008:
  https://www.microsoft.com/en-us/research/publication/parallel-generational-copying-garbage-collection-with-a-block-structured-heap/
- GHC RTS documentation distinguishes its generational copying collector from
  the concurrent mark-and-sweep oldest-generation option:
  https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html#rts-options-to-control-the-garbage-collector
- Petrank's research index links the Stopless/Clover/Chicken concurrent
  collector work and explicitly discusses nonblocking progress:
  https://csaws.cs.technion.ac.il/~erez/projects.html
- The JDK 27 ZGC guide describes the current generational collector and the
  allocation headroom needed during concurrent collection:
  https://docs.oracle.com/en/java/javase/27/gctuning/z-garbage-collector.html

Screening is not section-by-section paper reading. Exact algorithm assumptions,
implementation revisions, C memory ordering and compiler barriers require
separate source/paper ledgers before selecting an implementation design.

## Three Equal-Status Experiments

`ConcurrentSATB.qnt` models a single mutator and collector, old and still
holders, snapshot-live young targets, a born-black allocation, private barrier
logs, publication, draining and a terminal admission handshake. Fault controls
omit the pre-write barrier, ignore private logs at completion or omit the
Still holder's remembered card. The handshake may pause admission; the model
does not claim a pause-free collector. The born-black allocation rule is an
explicit assumption, not observed Gambit behavior.

`ConcurrentCopyWrite.qnt` models one movable object's payload and version,
copy/retry/publication, reference resolution after forwarding, and a raw C
lease that delays source reclamation. Fault controls omit the version check,
reference barrier or lease drain. Safe copying here depends on atomic
publication/version validation and a bounded single write. It does not prove
lock-freedom, wait-freedom, unbounded retry progress or actual FFI compliance.

`ColoredReferenceRelocation.qnt` adds a modern load-barrier/colored-reference
alternative. Two roots and in-flight local references may retain an old epoch
while an old page is reused. The positive profile resolves stale references
through retained forwarding metadata. Three faults omit the load barrier,
retire metadata early or ignore in-flight local roots. This is inspired by
the architecture described in https://dev.java/learn/jvm/tool/garbage-collection/zgc-deepdive/,
not a faithful source model of ZGC. It omits repeated epochs/ABA, weak roots,
real color-bit placement, generational store-barrier implementation and memory
ordering. These are explicit future obligations, not presumed correct details.
The linked deep dive describes an older JDK 19 architecture; it is a conceptual
reference, not a qualification of the current generational ZGC implementation.

All three models assume sequentially consistent atomic actions, finite objects and
no weak references, ephemerons, arbitrary graphs, interior pointers, allocation
failure or nested collection. The shared location identifiers are abstractions,
not Gambit pointer encodings or two permitted runtime workers.

## Engineering Decision Gates

Treat the alternatives as equal experimental candidates: repair the
existing parallel STW protocol, add generations/remembered sets under STW,
or combine a moving young generation with concurrent nonmoving old/Still
collection, or use colored/load-barrier-assisted concurrent movement with
generational store barriers. No older design is a prerequisite or preferred
answer: suitability follows from source constraints, counterexamples and
matched real measurements. A read barrier is distinct from an atomic
memory-ordering fence. GC parallelism is distinct from mutator concurrency.

Native qualification must cover generated C loads/stores, mutable pairs,
vectors, closures, globals, stacks/continuations, FFI roots and uninstrumented
C stores; VM/processor startup, retirement and failure rollback; Still-to-young
edges; forwarding publication; and global work/log closure. The three Gambit
flags must be on together for an eventual matching runtime candidate. Finite
controls cannot discharge those obligations.

Measure identical real workloads and survival ratios: pause distribution and
maximum, throughput, mutator barrier CPU/allocation overhead, peak/steady RSS,
copy volume, repeated scans, retries, FFI latency and multicore scaling. A
lower pause bought by excessive CPU or memory is not an unqualified speedup.

## Execution Contract

`evidence/research/experimental-concurrent-gc/control.recipe.json` uses only
existing sealed parse/typecheck/verify/Evidence capabilities. Its whole budget
is initially 90 seconds and each model/check step is at most 15 seconds. The
first executed campaign used 39.887 seconds and failed colored-profile type
checking; its eight completed SATB/copy controls are retained but are not the
complete three-profile result. The corrected full rerun receives only 48
seconds, keeping both executed attempts below the original 90-second cap.
Twelve outcomes
are required: three positive checks and nine decoded negative controls. Every
actual exit, timeout, counterexample and log remains in a fresh run directory.
An execution failure is not an expected negative control. No native or
performance admission follows from a terminal PASS.

## Observed Campaign Boundary

The immutable local runs are `.data/experimental-concurrent-gc-002` and
`.data/experimental-concurrent-gc-003`. Run 002 retained eight completed
SATB/copy controls, but failed colored-profile type checking. Run 003 follows
the actual `Set.exclude` argument correction; it is not an unchanged-input
retry. Its parent timed out and exited -9, with the parent reaped and process
group quiescent. No terminal Evidence acceptance was produced.

Run 003 completed the colored positive profile (169 distinct states) and
decoded a counterexample for the omitted load barrier. The early-metadata
check timed out; the in-flight-local-root control and terminal evaluation did
not complete. Neither incomplete check is a successful negative control.
The two parent whole durations were 40.624 and 48.587 seconds, approximately
89.211 seconds together. The remaining budget is not reset for another run.

The complete campaign remains DENY. A checker/process timeout is not a
counterexample to the collector design and does not rank the modern candidate
below the other alternatives. Further experiments need an explicit new causal
design or tool change and their own reviewed budget. These observations prove
neither Gambit source correctness nor a throughput, latency or nonblocking
property. Historical run inputs precede this documentation update and retain
their original identities; they are not relabeled as current receipts.

## Two-Round And Lifecycle Extension

`RelocationEpochRoots.qnt` and `ForwardingVisibility.qnt` add two relocation
rounds with wrapping colors, continuation and Still roots, a foreign lease,
and explicitly delayed payload visibility. This is still a bounded protocol
experiment, not the current ZGC algorithm or a full C/ARM memory model. The
checked full-generation stamp is a ghost obligation: a real implementation
needs an equivalent epoch/quiescence protocol. Metadata retirement abstracts
joint source-reclamation eligibility; pin acquisition races and raw C payload
coherence are not modeled. The baseline Gambit runtime has not acquired these
barriers merely because the experimental models exist.

The new sealed campaign is
`evidence/research/experimental-relocation-lifecycle/control.recipe.json`.
Attempt 001 retained a current fdset producer custody DENY: the successful seed
journal's final artifact inventory was unavailable or changed. It did not run
the models. Attempt 002 explicitly used a historical locked model fixture,
never the current runtime, and failed the state-reading `pure def` effect
check. The actual declaration correction allowed attempt 003 to complete two
positive and six decoded fault controls plus terminal Evidence evaluation.
The positive state counts are 168 and 7, both with zero queued states. The ABA
counterexample reaches epoch 2 with color wrap and an old continuation target.

Parent whole times were 8.603373, 20.841931 and 40.814452 seconds, totaling
70.259756 seconds under the original 90-second campaign cap. Remaining attempt
caps decreased from 90 to 75 to 55 seconds; individual steps stayed at most
15 seconds. Attempt 003 exited 0 without timeout, with its parent reaped and
process group quiescent. All prior DENY/type failures remain in the original
directories. No runtime or source-refinement admission follows.

`evidence/scenarios/concurrent-gc/current.view.json` binds the current fdset
23-file overlay with per-file hashes, the reported bootstrap identity, three
configure-argument JSON pointers and the new model observations. Its ordinary
declarative Scheme DSL generates 11 read-only Action Catalog entries. Eight
source/native obligations and six performance metrics remain open even after
model PASS. The current producer custody failure is visible, not hidden by the
historical model fixture. The reported full bootstrap inventory is not a new
whole-runtime qualification by this view.

The actual Python/C ABI consumer exercised discovery, authorized selection,
observation, flag/source withdrawal, answer restoration and retained-session
reuse. Consumer 002 retained its missing-host-authorization failure; the test
was corrected to first check rejection, then request explicitly authorized
read-only execution. Consumer 003 passed two tests without skips in 6.470607
seconds, after the prior 3.886588 seconds, below the original 15-second cap.
Raw stdout/stderr and exits are local in those receipt directories. They are
not Git-archived evidence or a rebuilt complete current graph.
An earlier observation-harness import failed before any test started because
`framework.write_json` does not exist; correcting receipt serialization did
not alter the DSL or tests. Its tool-output failure is retained, not disguised
as a test result. A subsequent actual `research --read` of model attempt 003
reported CURRENT identity/bindings and available outputs, while keeping
runtime/source-refinement admission false.

No concurrent collector implementation or same-input GC performance result
exists yet. Checker time and Evidence session reuse are not GC benchmarks.
The scenario README records the required matched workload, binary/toolchain,
three-flag, heap and topology identities before any performance conclusion.
The release/acquire litmus is informed by the C memory-model rationale:
https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1479.htm
