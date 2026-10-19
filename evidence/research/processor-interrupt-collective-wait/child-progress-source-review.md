# Child-progress witness, bounded to one runner copy

The supervised Grok model-review window produced three model/document files,
without editing the host adapter, suite, tests or ticket-lock model. Integration
subsequently added the host adapter and native execution records. Original
stress files remain untouched. The first verification retained six decoded counterexamples, then
rejected two initial-state-only fault encodings without decoded transition
traces. Those encodings now publish the bad claim on the admission transition,
rather than starting with an already-invalid published claim. The first receipt
remains retained; the corrected model requires a fresh check.

Model: `models/gambit/gsi_child_progress.qnt`.
Manifest: `evidence/research/processor-interrupt-collective-wait/child-progress.manifest.json`.
The manifest names case `gsi_child_progress`, positive initializer
`initAcceptedWitness`, invariant `safe`, and temporal property `completion`.
Eleven `old` initializers are expected counterexamples. Explicit context hashes
bind the host adapter, native Scheme forwarding asset, original runner/reporter
and reproducible candidate source lock/patch. Vendor correspondence is submodule
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.

## What the adapter may record

The stock runner launches `../gsi/gsi` with `-:debug-settings=-,io-settings=lu`
and `-f` on the original file (`tests/run-unit-tests.scm`, `run-gsi-under-debugger`).
`run` reads the child with `(read-line port #f)`, then `process-status`, and
returns that pair. `test` prints the filename, runs that child, and only then
updates the good/failed bar. `PASSED ALL` / `FAILED` and the process exit
remain the suite admission.

Public `process-pid` reads the pid of the port's process device
(`lib/_io.scm`, `##process-pid` / `process-pid`). The envelope pid is that
value for the port `open-process` returned, which is the inner gsi.

Public `gc-report-set!` stores `##gc-report?` (`lib/_nonstd.scm`). The default
is `#f`. `##display-gc-report` runs from the GC interrupt job registered by
`##add-gc-interrupt-job!`. It writes `*** GC:` only when debug level is at
least 5 or `##gc-report?` is true. The allocation figure is
`(##f64vector-ref stats 16)`, named `last-gc-alloc`, together with heap, live,
and movable counts. The write goes to `(##repl-output-port)`. The console
repl channel binds that output to stdout unless debug settings select
stdio-and-err (`lib/_repl.scm`). Default stdout redirection is
`macro-stdout-to-port`; default stderr redirection is
`macro-stderr-unchanged` (`lib/_io#.scm`). The inner child's report therefore
lands on the stdout pipe the runner owns. The runner's own stderr is a
different stream, and it is the stream the host already watches while the
runner is alive.

A hash-bound copy can, before `(load` of the original file), evaluate
`(gc-report-set! #t)` in that same child, call `(process-pid port)`, and write
a fresh nonce, that pid, and the file name around a completed `*** GC:` line
to the runner's stderr. The original file bytes, the child's stdout bytes, and
the status/exit protocol stay in place. `debug-settings=-` selects the stdio
REPL channel (`lib/main.c`); it does not clear the separate debug-level field.
The setter runs only in the child, so driver allocations and driver GC cannot
produce child-port reports.

## Renewal

The first allocation-frontier implementation was refuted by real child output:
allocation statistics became negative during both interrupt tests. That run
is retained as a DENY, with an explicit observer-contract cancellation of TFIB,
not a watchdog/deadlock claim. The two interrupt children naturally exited zero;
their observer-format denials are not original assertion failures.

The implemented integer now counts completed report lines read from the owned
child pipe, with an explicit per-child sequence in the source-bound driver.
It is not an allocation statistic. The host decodes only complete, framed
records and submits the sequence to Scheme; replaying a transport prefix or
sequence cannot advance its cursor. Reporting is explicitly selected per file,
without changing the general suite policy. The first occurrence-witness plan
selected only TFIB. Its unobserved interrupt2 child reached the 300-second
completed-file inactivity limit; that is not evidence of absence of internal
work or a deadlock. The closed attempt and the operator-cancelled, still-active
TFIB remain retained. The current configuration explicitly selects all four
files and uses the existing single-driver regime, which derives a fixed VM
population from available host capacity. It does not resize a running VM.
The completed four build stages remain reusable. This topology differs from
the previous three-driver configuration and is not a timing comparison.
The observation stream is declared
once per `(scope, actor, epoch, kind, source)`. The implementation kind is
`completed-child-gc`; the model's `gc-collection` is its abstract tag. Actor is the
pid from that child port. Source is the original file whose hash the host
checked. The existing progress rule renews only when the frontier is strictly
greater than the ready cursor. The same sample renews once and then stops.
A restored cursor is that equality. A smaller sample is the same rejection.

Child begin is a separate kind. A begin line with a higher integer is still
not completed GC work. Silence, CPU, and a repeated identical report do not
advance the cursor. File-exit stays a different kind with maximum cursor 1,
attributed only after `process-status`. It does not lengthen the interval in
which this child has produced no completed report. Suite admission remains
exit 0, the original stdout protocol, and one passing marker. A GC sample
does not set that admission. Exit 1 stays a failed suite.

## Missing mutator premise

`last-gc-alloc` is a VM total, and the real negative values refute its assumed
monotonicity in this candidate. The setter only changes a Boolean; the report
job was already registered. Actual reporting may allocate while formatting
numbers and strings and obtaining the output port. Those bytes are inside
the same total. The model stores
`observerAlloc` and `vmAlloc` and has no action that sets `mutatorKnown`.
`initObserverOnly` is the case where the two allocations are equal and the
witness still claims mutator work. `attributionSafe` requires
`mutatorKnown` before `claimsMutator`. The positive state keeps the claim
false, with observer allocation 1 inside a VM total of 2, so the mixed total
is visible and still not split.

A completed forwarded report proves one finished collection and the statistics
that report printed, for the pid and file in a fresh envelope, from a runner
and reporter whose hashes the host accepted. It leaves the mutator share
unknown. It does not prove a TFIB root result, progress of `short-delay`,
termination, absence of deadlock, or the identity of a ticket holder or
`sop.op`. The interpreted four-file stop, the diagnostic root stall at 503
of 5000, and the historical failures stay recorded.

Enabling `gc-report-set!` and writing the runner stderr envelope changes
timing and I/O. `interferenceSafe` fails when that enablement is hidden.
The positive witness discloses it. Disclosure is not removal of the interference.

## Stock runner, and no forced next step

`initHeldUntilEof` renews while `stockReadUntilEof` is set and the report has
not been forwarded. That state is the current `run` loop: the GC bytes sit in
the child stdout result until `read-line` returns at EOF, so they are not a
mid-run stderr sample. `streamSafe` fails there. The accepted state is the
copy that forwards during the read, with the copy's hash disclosed. The
unchanged runner does not supply that sample.

`initNoForcedNext` asserts `forcedNext` with no completed collection and only
an idle step. `livenessSafe` fails. The positive temporal property is weak
fairness on recording a witness that is already presented. There is no
collect action and no root-completion action. A child that only runs
`busy-sleep` can produce no report; the model does not turn that silence into
progress or into an inevitable next GC.

## Expected counterexamples

| Initializer | Invariant | Fault |
| --- | --- | --- |
| `initWrongChild` | `identitySafe` | Envelope pid differs from `process-pid` of the child port, or the nonce/runner/reporter binding fails |
| `initWrongSource` | `sourceSafe` | File or source hash is not the original file |
| `initWrongEpoch` | `epochSafe` | Attempt id differs |
| `initReplay` | `replaySafe` | Sample equals the cursor, or is smaller |
| `initBegin` | `beginSafe` | Kind `begin` renews even when the integer increases |
| `initIncompleteGc` | `collectionSafe` | Forwarded line without a completed collection |
| `initHiddenInterference` | `interferenceSafe` | `gc-report-set!` enabled and undisclosed |
| `initObserverOnly` | `attributionSafe` | VM total equals observer allocation and is labeled mutator work |
| `initFailureExit` | `exitSafe` | Suite admitted on child exit 1 |
| `initNoForcedNext` | `livenessSafe` | Claims a next GC or TFIB root must occur |
| `initHeldUntilEof` | `streamSafe` | Stock read-until-eof treated as a live forwarded report |

`safe` on `initAcceptedWitness` is the conjunction of those obligations for a
disclosed copy, a strict `gc-collection` advance, and no suite admission.
This finite check is not an SMP proof and not a native result.

## Completed collection correspondence

The candidate `lib/mem.c` increments `nb_gcs` and raises `___INTR_GC` only in
processor 0 after the collection, cleanup, resize and heap-fudge phases.
`##handle-gc-interrupt!` runs the registered jobs with interrupts disabled;
`##display-gc-report` is registered once. The original selected files contain
no other invocation or fabricated copy of this report. Under this pinned
source premise, each complete line actually read from that child's owned pipe
witnesses a dispatched collection completion, possibly coalescing collections.
The driver sequence is an occurrence identity, not a periodic timer, CPU
measurement or guessed mutator counter. Source changes that violate these
premises require new correspondence, not trust in the prefix spelling alone.

The observer still changes allocation and timing. Collection activity can
coexist with a stalled mutator, so a collection renewal does not establish
mutator progress, freedom from livelock or eventual test success. Only the
unchanged original suite's natural exit and assertions establish its result.

The forwarding procedure lives in `models/gambit/native/child_gc_forwarder.scm`,
selected as a declared source asset by the existing suite configuration. It is
an interpreted native-test observation procedure, not Evidence DSL or a second
query engine. Python binds safe launch metadata and transports complete child
records into the registered Scheme Session. No downstream package compilation
or Python Scheme parser was added.

## Native report-framing counterexample

The subsequent host-capacity run contains interleaved and truncated reports;
see `host-capacity-child-progress-result.md`. A completed collection and an
authentic child identity do not by themselves authenticate a complete record.
The model now represents this independently as `reportFramed` and checks an
`initInterleavedGc` negative control against `framingSafe`. The current positive
and all twelve negative controls have accepted outcomes; receipt SHA-256:
`b30a099d412a631ceca49f0f2b972d2c839f3d4d31dcb806347412918c0dc9a1`.
The decoder regression rejects the same structural corruption without renewing
the cursor, then accepts a subsequent properly framed report. Neither check
establishes that the observed process must emit another report or finish TFIB.
