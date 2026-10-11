# Residual SMP Engineering Audit

Audit date: 2026-10-11. This is a bounded review of existing evidence, not a
new runtime admission. The audit session owns `research-audit.json`,
`research-rules.dl`, `research_audit.py`, its tests, and this handoff. The
Working session owns candidate source, protocol models and their manifest.
Concurrent changes must not be overwritten.

## Reuse Before Experiment

The upstream snapshots in `evidence/upstream/smp-20261010/` already index 21
reported residuals. Six high-priority audit issues are selected in
`evidence/research-audit.json`; this is not a claim that all reports have been
fully audited. Source revision, patch composition, fixture bytes, mode and
stage must accompany every inherited result.

| Existing value | What remains, and what not to repeat |
| --- | --- |
| PR988 contains useful individually reviewable repairs, despite withdrawal. | Review surviving hunks and assumptions against the selected source. Neither blanket rejection nor blanket adoption is justified. A historical green report is not current toolchain admission. |
| PR1037 repairs pipe endpoint synchronization. | Preserve cross-processor coverage: unpinned or p1 success is insufficient. Its reported `write_shared` result isolates a compiler-stage problem: unicore-produced code runs on both SMP runtimes. Do not treat that as another pipe failure or as proof of a particular GC cause. |
| PR1038 repairs the pre-GC decoder publication omission, independently of PR1037. | Its forced-postdecode-GC and SMP compiler residuals have distinct evidence. Local later work already covers part of the former; do not reproduce the unchanged upstream failure. |
| PR1039 separates promise identity repair from an allocation crash. | Ordinary-procedure controls also crash. Preserve that negative attribution evidence instead of treating every crash as a promise-lock defect. |

Sources: [PR988](https://github.com/gambit/gambit/pull/988),
[PR1037](https://github.com/gambit/gambit/pull/1037),
[PR1038](https://github.com/gambit/gambit/pull/1038),
[PR1039](https://github.com/gambit/gambit/pull/1039).
The corresponding head identities and body digests are in the pinned snapshots.

## Forced GC Is Not An Unwritten Test

`models/gambit/native/table_decode.scm` already performs five explicit GCs
between decoding and lookup, covering text/binary serialization and three
equality predicates. Candidate 018 already has three successful rounds:

| Round | Interpretation | Executable compilation | Compiled execution |
| --- | ---: | ---: | ---: |
| 1 | 1.949 s | 13.139 s | 1.850 s |
| 2 | 1.906 s | 11.892 s | 1.912 s |
| 3 | 1.184 s | 13.572 s | 1.614 s |

These are inherited receipts, not new measurements by this audit. See
`gc-postcopy-headroom.md` and
`evidence/model-results/native-postcopy-decode-host-pass.json`,
`native-postcopy-decode-host-repeat1-pass.json`, and
`native-postcopy-decode-host-repeat2-pass.json` in the same directory.
They bind the fixture and the 018 binary identities. They do not automatically
admit candidate 026, complete bootstrap, or all weak-table and collector cases.

The different `native/pr1038/serialization_gc.scm` checks allocation during
serialization with a peer requesting GC. It does not impose the same exact
decode/GC/lookup ordering. Keep both scopes; do not replace one with the other.
The later rooted snapshot repair has its own evidence in
`gc-table-serialization.md`, including the 022 failure and 023 pass.

For a later candidate, first compare the relevant source and patch inventories.
Unchanged model bytes can reuse model receipts. Changed collector/source bytes
require impact analysis and targeted native coverage; an old binary receipt is
not transferable merely because a fixture has the same name.

## Priority 1: Compose Membership And Work Closure

Current `gc_sync_membership.finishScan` abstracts closure completion;
`gc_work_closure` uses a fixed two-worker population and atomic queue visibility.
A `contracts` dependency edge records an obligation, not a refinement proof.

Paper guidance: GHC sections 3.4-3.5 retain private scan/allocation work and
count workers until they cannot produce more work. An empty pending set alone
does not establish termination. HotSpot section 3.3 keeps workers active through
local/overflow work and reactivation before stealing. These are design inputs,
not evidence that Gambit's implementation satisfies the same protocol.
See [GHC parallel GC](https://simonmar.github.io/bib/papers/parallel-gc.pdf)
and [HotSpot parallel GC](https://www.usenix.org/event/jvm01/full_papers/flood/flood.pdf).
Use the cached PDFs/text in `.data/papers/`; no repeated download is needed.

The missing executable interface should carry:

1. GC epoch, snapshotted participants, parked mutators and root completion.
2. Private unexported work, published queue work, active scanners and pending
   producers as separate state; forwarding identity is not copy completion.
3. A phase completion certificate derived from all of those states, replacing
   the unconstrained `finishScan` transition.
4. Population commit only after the old epoch is drained, followed by new-worker
   setup/join before the next epoch. Reused processor IDs must not accept stale
   messages or count a previous incarnation's acknowledgement.

Required controls: early root completion, early idle while private work remains,
population replacement before old-epoch closure, and stale-epoch acknowledgement.
The positive model must check safety and nonterminal deadlock independently.
Eventual completion additionally needs explicit fairness, finite graph and
successful-allocation assumptions; finite safety exploration is not a liveness
proof. This proposes model obligations, not a new source repair.

Source review anchors: `execute_sync_op_loop` and processor-count operations in
`lib/setup.c`; the GC root/strong-scan/final-barrier phases in `lib/mem.c`.
Do not introduce dynamic membership into an active GC just to generalize the
model: the source's nested old-population GC must be preserved.

## Priority 2: Preserve Scan Ownership And Relocation Contracts

`gc-old-space-input-contract.md` records a concrete repeated physical-body
visit, not just a hypothetical missing fence. `gc-queue-ticket-handoff.md`
records queue/local scan provenance but also explains why that observation
alone does not establish the parent of every invalid reference.

The next model refinement must distinguish physical slot identity from logical
object identity, collector epoch, source/destination space, queue ownership,
local scan cursor and valid scan extent. Required counterexamples are:

1. Exporting a chunk without retiring the owner's local scan claim.
2. Re-reading a rewritten slot as though it still contained a from-space input.
3. Scanning beyond the copy-ready frontier after observing a forwarding identity.
4. Reusing an address in a later epoch and misclassifying it as a same-epoch
   duplicate visit.

Bind these to the existing `mark_array` input contract and queue ticket handoff
before proposing another fence. GHC's copy-before-forward ordering is not
Gambit's forward-before-copy design; transplanting the former's visibility
assumptions would make the model prove the wrong implementation.

Do not mask an invalid input by accepting every to-space pointer. Do not infer
deadlock from the old queue-only stack snapshot: the same diagnostic process
subsequently advanced from GC cycle 97 to 169. Preserve that refutation.

## Priority 3: Retire Synchronization Resources Safely

The reviewed runtime 026 `SYNC_SEND_MSG` publishes under `sync_mut`, unlocks,
then signals `sync_cv`. Initialization occurs in `setup_sync_op_pstate`; the
reviewed cleanup lacks matching synchronization-resource destruction. Adding
destructors without a lifetime protocol is not a safe repair.

The Working session's initial `sync_resource_retirement.qnt` correctly models
late signaling across reuse, but its `dispose` guard `sender >= 3` excludes
retirement after publication while the sender still holds the mutex. Expand
that coverage if source admission permits the receiver fast path at that point;
otherwise bind the exclusion to a demonstrated source guard.

Separate admitted senders, lock holders, sleeping waiters and late signalers.
Seal new admission, drain every owner, destroy only initialized resources, and
then advance the processor-slot generation. Joining the retired processor alone
does not drain a foreign sender. Also cover partial initialization failure and
rollback. Abstract `users == 0` is a required contract, not proof of an existing
source implementation. This audit finding is a coverage obligation, not a
claim of a newly reproduced native crash.

## Compiler Boundary And Retry Admission

Runtime 026's `_num.scm` compiled atomic campaign already ends in DENY at its
300-second bound. Earlier compiler-stage receipts isolate Scheme-to-C progress
from expensive C compilation. No unchanged retry, renamed output directory,
or larger budget can turn that into causal evidence of a collector repair.
Likewise, the PR1037 compiler crash is not the same observation as a later
GNU C compiler budget expiry. Keep those failure classes separate.

Run the audit and focused unit tests from the repository root:

```sh
uv run --locked gambit-smp audit --check
uv run --locked python -m unittest discover -s tests -p test_research_audit.py -v
```

The preflight accepts an explicit `gambit-retry-proposal.v1` document with
failure ID, candidate receipt, runtime, fixture, mode, budget and causal
hypothesis. It compares actual binary/fixture/build-driver bytes with the
failed receipt, including previously patched fixture bytes.

- Exit 2: DENY. No candidate is executed.
- Exit 3: changed evidence requires human/source review, not automatic admission.
- `--check` exit 0: audit inputs were consistent, not SMP correctness or release
  readiness.

The preflight is currently standalone, not wired into every native runner.
Working should integrate it at failed-route admission, preserving this limited
scope. Environment-only changes and broader campaign regrouping need explicit
review; this first version must not silently interpret them as fixes.

## Audit Receipt

`.data/research-audit-003/receipt.json` records six audit blockers, 27
PR/model/source paths, 12 paper/model paths and four reusable undesignated
model receipts. Fifteen matching legacy records cover two models (`table_decode`
and `promise_publication`) but lack source-stability attestation. They are
evidence-format review, not untested models and not silently upgraded passes.
Four issue/model pairs lack matching current receipts in this scoped search;
search historical evidence before scheduling any new run.

All 14 audit unit tests passed. A real negative preflight against unchanged
runtime 026 returned DENY without launching a compiler. The persistent
evidence files and Datalog rules capture the audit; local `.data/` receipts are
not a substitute for final source-bound native/bootstrap acceptance.

## Executable Follow-Up

The subsequent audit implemented three new protocol models and the eight-way
build-configuration model. See `protocol-extension-validation.md` for source
mapping, finite bounds, 15 retained counterexamples and all four positive
safety/temporal results. Portable receipts live in
`evidence/model-results/protocol-extensions/` and
`evidence/model-results/configuration-model/`.

`research_audit.py` now reports four `protocol_verified` models and zero
`protocol_remaining` entries for this extension set. This closes the specified
bounded modeling work, not the separate source-refinement and native/bootstrap
barriers. Working owns integration into the primary `cases.json` manifest and
any runtime repair; these new models already run through one shared adapter.
