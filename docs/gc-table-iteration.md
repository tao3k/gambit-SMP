# Eager Rehash And Callback Traversal

## Path Review

- Correct direction: a new public-API native fixture demonstrates omission and
  duplicate visits while its callback only runs GC and reads the source table.
- Prior work: existing rehash models abstract completed rehash/key preservation;
  they did not cover a physical slot cursor surviving a callback GC.
- Worth fixing: callback traversal also underlies table copying, folds and
  shared-object printing. Keep the useful PR988/1038 collector repairs.
- Expected benefit: correctness across relocation, not a quantified speedup.
  Snapshot allocation can add cost; performance gates remain required.

## Source Facts

`mem.c` selects eager rehash when multiple-threaded VMs are enabled. This is not
a Darwin-only conditional. The Scheme for-each/search/fold helpers traverse raw
GC-hash-table slot indexes and invoke allocating callbacks between increments.
A GC can physically rearrange entries without changing the logical table.

The new rooted 32-key fixture calls GC and table-ref in each callback. Original
candidate 018 visits 33 entries, with omissions and duplicates, in 1.384 seconds.
The original source is not edited; the fixture resides in the isolated suite.
Receipt/log: `native-table-iteration-018-deny.*` under `evidence/model-results`.

Other controls narrow but do not settle historical failures: in explicit p1,
thread-interrupt and table-search pass, while write_shared still fails. A
128-MiB minimum-heap control passes the observed shared-output fixture, whereas
default heap reports GC count 7 to 40 and fails. The passing upstream runner
suppresses child stdout, so zero GC in the large-heap control is not claimed.
These observations do not establish the cause of PR1038's historical crash.

## Model And Rejected Prototype

`gc_table_iteration.qnt` covers three rooted logical keys, all six physical
layouts and repeated callback rehashes. It freezes the old slot-cursor failure
and a separate wrong-tag copy control. Typed stable snapshot traversal exhausts
37 distinct states, 146 generated, zero queued. Capture atomicity, actual object
layout, concurrent table mutation, weak-entry lifetime and full heap graph
correctness remain source/native obligations, not consequences of this model.

The first prototype incorrectly used vector-copy on WEAK/SUBTYPED storage.
Current primary tags differ; its explicit native caller exited signal 11.
This rejected local prototype is indexed separately from upstream defects.
Intermediate reader and missing-header/primitive-dispatch errors remain denied
in their original local receipts; none is runtime acceptance.

## Typed Native Experiment And Candidate Patch

The corrected standalone experiment allocates a normal rooted vector, then
copies from SUBTYPED to VECTOR bodies using a non-allocating typed C memmove.
An explicit caller avoids compiled core procedures retaining old bindings.
The real compiled 32-key forced-GC regression passes in 10.068 seconds at the
host-selected 12 processors, under a 120-second declared mode budget.
Receipt: `native-table-snapshot-typed-ffi-pass.json`.

This FFI experiment is not a rebuilt runtime. The candidate source patch
`gc-table-iteration-snapshot.patch` adds the corresponding primitive and updates
the three callback traversal helpers. The current Gambit reader accepts the
source. The exact patch reverses to the admitted 018 `_system.scm`.
At this checkpoint the allocating serialization explode helper still needed
the same source audit; runtime023 later applies a separately model-bound repair
after a native concurrent-GC key-query failure. See `docs/gc-table-serialization.md`.
Do not treat the mixed shim campaign as shared-output
repair acceptance or repeat its failed implicit binding path unchanged.

## Actual Source Candidate 019

The isolated GNU GCC core rebuild passes in 28.642 seconds. Generated
`_system.c` was removed before rebuilding, and the interpreter, compiler and
runtime archive all have new artifact hashes. This is a core rebuild, not a
completed two-pass bootstrap or release admission.

Twelve selected files pass without runtime shims: the nine original table
files, original shared-output test, read-only forced-GC traversal regression,
and original PR1038 serialization fixture. Interpreter mode passes 12/12 in
5.435 seconds; compiled execution passes 12/12 in 105.352 seconds, each under
the declared 120-second mode budget. Processor selection is host-auto
(12 available on this run), not a fixed default.

The first attempt is retained as denied: the additional serialization fixture
was missing its unchanged local `#.scm` support file. The corrected snapshot
adds that support file, without changing assertions. Portable receipts are
`native-snapshot-core-019-build.json` and
`native-snapshot-core-019-twelve-files.json` under `evidence/model-results`.

## Remaining Gates

An isolated original `13-modules/prim_port.scm` run on candidate 019 reaches
its 20-second interpreter budget without completing (20.014 seconds). This
denial is preserved separately from the successful twelve-file campaign.
It does not establish GC deadlock or invalidate that scoped regression result.

The separate two-pass source bootstrap is denied at 600.039 seconds. The first
compiler was produced and the second core build was compiling GNU GCC objects;
no recursive build error is logged and handwritten source remains stable.
The final artifact set is incomplete. Retained receipt: `bootstrap-019-deny.json`.
Do not repeat this whole-budget path unchanged or reinterpret it as a pass.

Run forced-GC decode, complete upstream tests, two-pass bootstrap, Linux and Gerbil
correctness/performance. Preserve denials. No package-specific workaround or
unchanged failed-route retry is justified by this experiment.
