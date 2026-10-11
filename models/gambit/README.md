# Gambit SMP Models

## Decision before implementation

This is a finite abstraction of specific source protocols, not a proof of
Gambit's C implementation or a macOS performance improvement. The PR reports
and their residual failures are catalogued in
[`smp-upstream-report-audit.md`](../../docs/smp-upstream-report-audit.md).

| Path | Already investigated? | Why model it? | Expected benefit |
| --- | --- | --- | --- |
| 1038 decode/rehash | Yes, upstream selected regressions | Eager versus lazy repair and mixed-key fallback have explicit source changes | Reject broken publication/fallback designs before native compilation |
| 1037 shared pipe mutex | Yes, upstream request/reply checks | Explore check-empty, publication, and wait-registration interleavings | Preserve a minimal lost-wakeup regression |
| 1036 heap floor | Yes, local startup and upstream resize evidence | Separate missing capacity floor from later collector failures | Prevent rediscovery of a known startup defect |
| 1010 C argument root | Yes, upstream focused C-interface checks | Allocation may move a reference held only in a C local | Preserve the save/restore obligation across allocation |

No wall-clock gain or repair-rate percentage is predicted. These are generic
runtime correctness models, not Darwin-only workarounds. Each PR is modeled
independently; no combined patch-stack correctness is claimed.

## Source correspondence and bounds

`cases.json` pins our source revision, upstream candidate heads where available,
source symbols, native fixtures, and unresolved failures.

- `table_decode.qnt`: four combinations of lazy/eager access and uniform/mixed
  keys, through decode, publication, and lookup. `ordered` abstracts the result
  of a *correct* rehasher; it does not prove collision handling or the C hash
  algorithm. Mixed keys must retain `NEED_REHASH` and clear `KEY_MOVED` before
  the table-specific fallback. The rehasher's uniform-key restriction is an
  explicit modeling assumption derived from the PR, not a newly diagnosed bug.
- `pipe_wait.qnt`: one reader, one writer, one message. Wait registration and
  releasing the predicate mutex are atomic; the shared mutex must exclude
  publication between checking the predicate and registering the waiter.
  The invariant excludes a waiter sleeping with published data. It is not
  a scheduler fairness or complete I/O liveness proof.
- `heap_floor.qnt`: one VM, processor counts 1/2/4, unlimited maximum heap,
  available allocation. Two abstract sections per processor preserve the
  capacity inequality, not the actual byte budget. Finite max-heap limits,
  allocator failure, and multiple simultaneous VMs are not covered yet.
- `root_marker.qnt`: one movable argument, allocation with or without GC,
  save/restore, and installation into the marker. This is a root-relocation
  obligation, not the complete parallel collector/barrier protocol. A native
  C/FFI adapter is deliberately pending rather than a fake Scheme equivalent.
- `gc_stack_lifecycle.qnt`: exhaustive choice between processor setup, a
  nonempty copied stack, and a fresh break frame. The old variant also models
  the locally observed wrong-function edit; it is not an allegation about
  upstream processor setup. Null writes, unrelated frame writes, and stale
  undo markers are distinct safety obligations. These bounded lifecycle
  states do not prove the full collector or arbitrary stack depth.
- `gc_rehash_protocol.qnt`: six legal combinations of C pointer-hash versus
  Scheme hash consumers and GC versus decode entry. C eq? tables' separate
  immediate/allocated-key partitions are an explicit source-derived bound.
  Decoder omission, mixed-key encoding and repair-flag consumption are modeled
  together, followed by up to two moving GCs. `initDecodedOld` isolates a
  repaired decoder with unrepaired GC callers; its `gcSafe` counterexample
  first completes successful publication/access, then corrupts a mixed key.
  Pointer collision handling and actual Scheme rebuilding remain
  abstractions; passing this model does not prove the C implementation.
- `gc_key_reference.qnt`: two worker scan orders and one strongly held allocated
  key shared by an external root and a table slot. Canonical CAS forwarding is
  abstracted, not proved. `initMissingScan` is an explicitly injected missing
  key-slot scan, NOT an observed native flag or a diagnosed upstream defect.
  The positive control assumes the actual allocated-key dispatch flag. This
  tests a boundary omitted by the layout-only rehash model; it is not a repair.
- `serial_number_transaction.qnt`: two callers on the same or distinct objects,
  with atomic numbering and atomic individual table accesses. The old control
  still changes the same object's returned number. The repaired protocol
  serializes the entire lookup/numbering/publication transaction. This stronger
  negative control shows why PR989's per-operation C table locks alone do not
  prove the compound Scheme operation. No native GC-safe lock is implemented;
  collection, resize, number wrapping and reverse-table internals are excluded.
- `sync_message_acquire.qnt`: one spin-path barrier message with explicit weak
  visibility/reordered-load choices. A sender fence before the flag and a
  receiver fence after polling are paired obligations. Separate release-only
  and acquire-only controls reject incomplete fixes. This is not a complete
  C memory-model proof, tree-barrier generation/liveness proof, or native
  diagnosis. PR989 is context for parallel GC, not the author of this repair.
- `sync_tree_rounds.qnt`: four processors and two consecutive barriers, ordered
  child reads/replies, clearing and reusing up/down mailboxes. Checks wrong-round
  consumption, overwrite, terminal channel draining and absence of dead-end
  states. This characterizes the source protocol, not an old/fixed repair pair.
  Coherent atomic mailbox visibility and a fixed population are assumptions;
  weak memory, dynamic VM resizing and scheduler fairness are not proved.
- `sync_wait_handshake.qnt`: receiver predicate recheck under the same mutex,
  POSIX atomic condition wait, and the actual sender unlock-before-signal order.
  A ready mailbox with an unscheduled awakened thread is legal. Its split-wait
  negative control is fault injection, NOT a diagnosed Gambit defect. Source
  binding checks the mutex and statement order; it is not a semantic C proof.
- `heap_allocation_headroom.qnt`: observed section/word budgets, overflow
  reserve and next-section admission. A two-sections-per-processor floor can
  pass while the allocator still immediately asks for GC. The candidate adds
  allocation headroom; larger occupied heaps and configured caps need separate
  validation. Native admission requires this receipt and mem.c source binding.
- `rehash_lock_ownership.qnt`: PR988's stripe-alias self-deadlock plus a separate
  conditional unowned-source control. Removing an outer lock avoids alias
  deadlock only under a source-ownership/private-destination protocol. The model
  does not establish that every Scheme resize/rehash caller meets that premise,
  implement an ownership lock, or validate the withdrawn PR as a whole.

TLC breadth-first search checks all reachable states of each finite model.
The old mechanism must produce an invariant counterexample, while the repaired
mechanism must complete with an exhausted queue. Compiler/tool errors and
timeouts are not accepted as counterexamples. This does not turn unexplained
`Heap overflow` or signal 11 reports into proved causes.
Characterization cases instead verify each declared invariant from `init`;
they do not fabricate a failing upstream mechanism or label a pass as a fix.

For protocols with several distinct reported failures, `oldInvariants` requires
a separate failing check for each obligation. `gc_rehash_protocol` checks the
decoder, uniform-hash and post-decode GC obligations in addition to the composite invariant.
The repaired composite invariant covers all of them. Reused receipts must
contain exactly the required checks; missing, duplicate or stale checks deny
native admission. A single earliest counterexample is not counted as coverage
of every failure in a PR.
`oldInitializers` selects fault-specific initial states; reused evidence must
also match that initializer, not only the invariant and model digest.

## Local Model Gate

`vm_resize_rollback` records the source-corresponding failed-setup cleanup
pointer and target restoration obligations. `source_unit.py` separately tests
the extracted C function with deterministic stubs; it is not full runtime
fault injection. A selected native candidate attesting this repair requires
`--resize-model-receipt` and the current `setup.c` digest plus lexical guard.
`gc_scan_termination` combines queue work, counted participation and two GC
phase boundaries. Its detached-publisher negative is a fault control, not an
observed native bug. See `docs/paper-source-obligations.md` for design sources
and the exact boundaries of these claims.

PR 988's `exec_gc_polling` and `lazy_vm_startup` cases separately cover failed
nonblocking configuration and failed resize after premature startup publication.
Their repairs are abstract obligations, not accepted native patches. Recursive
startup and process cleanup remain outside their bounds. The complete 36-file
source/report audit is in `docs/pr988-complete-source-audit.md`; the generic
`src/gambit_smp/upstream_audit.py` refuses incomplete or mismatched inventories.

Requires Quint **0.33.0**, Java, and the Quint TLC/Apalache backend. Verification
uses a local checker service. Every invocation needs a fresh output directory:

```sh
uv run --locked gambit-smp check --out .data/smp-model-check-001
uv run --locked python -m unittest discover -s tests -p 'test_*.py' -v
```

For the wait protocol's optional fail-closed source-layout binding:

```sh
uv run --locked gambit-smp check --case sync_wait_handshake \
  --sync-source .data/local-threaded/source/src/gambit/lib/setup.c \
  --out .data/sync-wait-handshake-next
```

Use `--case table_decode` for an atomic check. Generated logs, scalar JSON
counterexamples, model/manifest digests, timings, and exit codes live only under
the selected output directory. Tracked counterexamples contain no host paths.
TLC's ITF export is not used: its textual states are decoded with a restricted,
fail-closed Boolean/integer decoder. Existing output directories are refused.

## Native Admission

Default execution runs **no native build or test**. No global `gsi` is resolved.
After selecting a new repaired toolchain, explicitly supply its executable and
artifact receipt. Required receipt fields are `sourceRevision`, `binarySha256`
(interpreter digest), `multipleThreadedVms: true`, `patches` (exact identities),
and `modeledCases` (for example `["table_decode"]`). A case attestation is not
a claim that its entire referenced PR was applied. If compiling, also supply `gscSha256`.
These are producer attestations, not independently proved source/binary parity.
The gate rejects a binary digest mismatch, revision mismatch, or a receipt
that does not attest the selected repair. It never applies upstream patches.

```sh
uv run --locked gambit-smp check --case table_decode \
  --out .data/smp-native-001 \
  --native-gsi "$TOOLCHAIN/bin/gsi" --native-gsc "$TOOLCHAIN/bin/gsc" \
  --toolchain-receipt "$TOOLCHAIN/identity.json"
```

Fixtures cover mixed heap/immediate keys and text/binary serialization (1038),
with and without five forced GCs after decoding,
three public pipe types on distinct processors (1037), and VM resize (1036).
They are source-corresponding regressions, **not automatic replay of model
scheduling into native C**. Native runs record interpreted, compilation, and
compiled-test times separately; require exit zero and an exact success marker;
and kill/reap the process group on a total timeout. Without `--native-gsc`, the
compiled test remains explicitly `not-run`.

For a build-tree toolchain, add `--runtime-root "$GAMBIT_SOURCE"` to select
that tree's lib/bin/include rather than a configured global installation.

Use `--model-receipt` to reuse an admitted TLC result only when both old and
fixed variants match the current model digest. A stack-marker candidate also
requires `--source-model-receipt` for `gc_stack_lifecycle`, the source tree's
`lib/mem.c` digest, and the exact function-layout check in `source_binding.py`.
This lexical guard rejects the observed accidental change to processor setup;
it does not independently prove source/binary parity or C semantics.
A rehash-protocol candidate also requires `--rehash-model-receipt`, admission
for all four negative obligations plus the fixed check, and matching digests
for `lib/mem.c`, `lib/_system.scm` and its generated `lib/_system.c`.
A sync-message candidate requires `--sync-model-receipt`, all three fault
controls plus the fixed check, the exact `lib/setup.c` digest, and lexical
checks that both fences are outside/in the appropriate polling/publication
positions. Source drift or a one-sided fence rejects native admission.

Do not run the old native baseline just to repeat its recorded failure. Do not
re-run the known forced-GC/whole-bootstrap failure until a new source-backed
hypothesis targets it. Those blockers remain in every receipt. Model success
does not admit the threaded toolchain for release or replace full native suites
and the established package performance gates.
