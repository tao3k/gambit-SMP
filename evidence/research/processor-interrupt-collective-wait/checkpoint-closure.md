# Evidence/checkpoint implementation closure

These are implementation and integration checks, not whole-SMP admission.

## Current three-contract closure

| Contract | Implemented owner | Executed connection check |
| --- | --- | --- |
| Declaration completeness | Existing ASCENT Scheme support declarations/witnesses, host custody | Missing member/witness is not explicit empty success; retained history and current support stay distinct |
| Traceable checkpoint identity and recovery | Existing exchange fragment, Session and immutable execution store | Missing receipt source is visible; restoration removes the counter; fresh query owner and cache cleanup retain evidence without inheriting live-process authority |
| Genuine progress and inactivity | Registered ASCENT progress fragment, existing checkpoint constructor and host timer/recorder | Exact actor incarnation/source/kind, witnessed completion and strict cursor advancement; live child can exceed the idle window, replay/heartbeat is killed, failed exit stays failed |

The downstream registry now imports the upstream progress fragment into the same
`make-checkpoint-state` constructor. Host `EvidenceProgress` only transports
collector batches and Scheme-selected cursors. The collector cannot overwrite
declared context, and missing batch witnesses are explicitly cleared rather
than inherited. The existing Recipe wrapper retains the witness, and each
admitted renewal has its own immutable process record. No new CLI, workflow
planner, checkpoint database, task-specific branch or timeout increase was added.

The installed upstream checkpoint suite passes 20 tests. The positive
`ProgressWitness` model exhausts 657 states; eleven mutations produce expected
counterexamples. Lean's context/completion/cursor theorems pass under the locked
Guard. Real subprocess tests cover continued work, replay, heartbeat, failure,
journal persistence, and a fresh owner after disposable files are deleted.
The latter preserves the exact prefix and cursor but cannot renew because no
current actor has been independently attested. This is process/cache recovery,
not a physical machine reboot experiment.

### Same-round complete framework qualification

The existing `review_validation --profile full --timeout 300` completed with
**1,777/1,777 passing, zero failures/errors/skips**, unchanged inputs, natural
exit zero, a reaped parent and quiescent process group. Suite time was
288.342700334 seconds; supervisor time was 291.499878583 seconds. The unchanged
300-second setting is completed-test inactivity, not a total-wall pass gate.
The actual sealed domain passed with six host-selected workers in 8.036280625
seconds; its cases are already included in the total, not an extra test count.
The frozen engine is
`66ea0120b26f1f81e3e6348ea983fd915a0cf214c6a891434dfbedddbd98d5ea`.
The receipt SHA-256 is
`c7aa41273f0cfd67895750c3afeba4607171cd7d5271b2426304994c7c3c7070`.

The earlier bare-unittest attempt ran 1,776 cases and failed: 38 errors correctly
rejected execution of sealed-domain tests from editable code, two formal checks
could not bind their local checker endpoints, and one recovery check did not
observe the required quiescence. It is retained, not reclassified as a pass.
Its log SHA-256 is
`2aa1eb588a15f007483418b5eb006d5efa7f246b19e7188edc012180cf6e7092`.
The corrected run used the existing domain-dispatching supervisor, the needed
local endpoint/process observations, and the same inactivity threshold. It did
not bypass source-origin verification. One additional timer regression verifies
that inference or record-writing delay cannot invent a later work timestamp:
the host anchors renewal to observation arrival, before that processing.

This closes the three stated framework contracts under their explicit host
premises. It is local qualification of this frozen implementation, not GitHub
publication, a locked-revision installation receipt, a native GC proof, or a
change to the historical SMP milestone. The application-specific Gambit work
witness remains the next domain integration obligation, using these contracts.

## Subsequent architecture-first correction

A new negative case found that a valid receipt with a missing query-source
association vanished from Clue even though its historical receipt remained
valid. The old checks below did not cover that connection. ASCENT's existing
Scheme exchange now exposes `provenance-unavailable` from the claim declaration
and retains `receipt-source-unavailable` as its reason. No Python inference or
alternative query endpoint was added. Host custody/receipt admission remains
independent of query provenance.

The local package was rebuilt and installed through the package manager. Its
14 checkpoint tests pass, including a fresh-process checkpoint continuation
that exposes the counterevidence once and does not replay it. The projection
QNT positive exhausts 26,880 states; its eight negative controls fail as expected.
Lean's source-loss/history properties pass under the locked LeanPoo Guard.
These are local architecture results; they do not increment the native milestone
or certify a published revision. Original TFIB and native failure receipts are
unchanged. No new SMP source candidate or native rerun was started in this
architecture-first correction.

| Gap | Existing owner and implementation | Executed falsifier |
| --- | --- | --- |
| Missing declarations mistaken for complete support | ASCENT Scheme checkpoint fragment: enumerated bindings, commands and dependencies plus a bound completeness witness | Removing the declared input/command observations makes the claim unclosed; the same omission reaches Clue and a fresh process |
| Source, evidence reads and execution recovery collapsed into one status | ASCENT checkpoint projection and Clue delta; downstream declaration associates distinct claim, scope and source identities | Changed support is surfaced without erasing historical completion; a fresh process continues acknowledged evidence without gaining execution authority |
| Material presence confused with custody or aggregate success | Python host observation reports materialStatus independently of custodyStatus; existing stage checkpoint retains successful prefix | Stale custody does not invent missing files; source/configure/seed/core reused from a DENY aggregate with all four executionLaunched flags false |

No independent scheduler or Python inference implementation was introduced.
Domain obligations, source associations and diagnostic limitations use the
existing registered `make-modeling-guidance` Scheme declaration. The current
candidate has a separate view so its source identity cannot be joined into the
old candidate's claim identities.

## Executed checks

- ASCENT checkpoint contracts: 11 passed.
- Checkpoint projection Quint positive and seven expected negative mutations.
- Lean checkpoint properties checked under LeanPoo's guarded runner.
- Clue presentation regression: two Rust unit cases and the existing wide-scope
  integration case passed; incomplete pages do not acknowledge hidden evidence.
- SMP focused checkpoint, model applicability and progressive Clue checks:
  59 passed before the new native candidate was registered.
- Storage, Recipe and real sealed recovery: 86 passed with no skipped recovery
  case. Source-core inactivity watcher regression: five passed.
- Current registered candidate/model guidance: 13 passed. The first relevant
  TFIB relation query returns the incomplete original suite; continuation returns
  no repeated family and leaves exploration open. Report review is applicable,
  but original interpreted qualification is still unclosed.

These local results use the current dirty ASCENT installation. They are not an
exact-revision published dependency qualification. Publication and lock update
remain separate from source/native acceptance.

## Remaining semantic boundary

The original TFIB run was interrupted by a completed-file inactivity watcher.
Its artificial delay was calibrated for compilation, and a separate interpreted
cost observation is registered. The watcher proves absence of a completed file
within its window, not absence of all mutator progress. Neither a larger timeout,
CPU activity, nor a synthetic heartbeat may silently convert that observation
into a pass. The generic actor-bound progress contract and its host integration
are now implemented as described above. A Gambit-specific collector must still
establish the source/model correspondence for genuine target-child work; this
framework result does not pretend that TFIB already emits such a witness.

Current observations and receipts are in `native-observation.md`. In particular,
compiled stress passed, original interpreted stress remains incomplete, actual
sampled lock holder and barrier type remain unidentified, and historical SMP
progress remains 6/12.

## Real Grok continuation

The resumed session completed ten turns in 136.130 seconds. Its first tool
queried the old compiled requirement; the second terminal query broadened the
relational selection, retained its checkpoint, and exposed this candidate's
report. It subsequently narrowed by the new source lock rather than attributing
the old incomplete compiled result to the new source. No concrete query recipe
or hypothesis was supplied in the continuation message.

The public assessment retained aggregate DENY, the compiled component pass,
the original interpreted noncompletion, and the different capacity of the
isolated terminate run. It checked the release-before-device-select source
counterexample and rejected an unsupported holder/barrier attribution. It also
noticed that the model's immutable membership does not cover resize, id reuse
or teardown. These are observed quality corrections, not a measured general
reasoning-speed improvement or proof that source repair is complete.

Public transcript SHA-256:
`5e8359794ca3a8baa8987b850671ce8b68090b520dddecc19f5feba6c1933de4`.
The transcript is a cache artifact; this record describes only public queries,
tool results and the final assessment, not private reasoning.
