# Bootstrap Stage Reuse Audit

## Actual Failure And Duplicate Work

The current candidate's final original-budget continuation passed source,
configure, GNU GCC seed construction and native ASCENT causal review. The
two-pass bootstrap command received only 22.890 seconds and was interrupted.
It did not qualify the current candidate. Cumulative native progress remains
3/12; the interrupted candidate needs source-bound requalification.

The two retained successful seed inventories contain 65 object files each.
All 65 object SHA-256 values match. `include/gambit.h`, `include/config.h`,
`lib/makefile` and `config.status` also have identical bytes. Nevertheless,
the later configure consumed 37.104 seconds and seed consumed 31.866 seconds.
This is observed duplicate construction, not measured realized savings.

Pinned upstream `include/makefile.in:368` makes `gambit.h` depend on
`config.status`. Re-running configure refreshes this dependency, and
`lib/makefile.in:285` makes runtime objects depend on `gambit.h`. Keeping the
same directory alone does not preserve completed-stage reuse. Do not restore
timestamps to conceal changed flags or source bytes.

## Source-Directed Model

`models/gambit/bootstrap_stage_reuse.qnt` distinguishes the two compiler
generations required by upstream `makefile.in:140`: bootstrap, clean, core.
Admission requires both passes to commit against exact source, compiler,
profile and artifact identities. Interrupted passes remain uncommitted;
failed work stays charged and cache removal does not reset historical
milestone completion.

The first positive check found drift during active construction. Its denied
receipt, original snapshot and trace remain in
`evidence/model-results/research/bootstrap-stage-reuse/launch-drift-attempt`.
The corrected model separately binds launch-time validity and rechecks
current exactness at commit. Mid-execution drift therefore rejects commit,
without claiming an external edit could never occur.

Three negative controls found stale-cache launch, partial-pass admission and
cleanup-induced progress reset. Positive safety and conditional terminal
progress exhausted 29 states each. The checked campaign took 15.248 seconds;
the earlier denied campaign took 11.346 seconds. Both remain within the
original 40-second model allowance. The failed initial local-socket attempt
is retained separately and was not an evaluated model verdict.

The existing portable publisher registered the result in the existing
protocol bundle catalog. ASCENT receives one checked protocol, three controls
and five open obligations. There is no new Python orchestration framework,
constant temporal property, CPU limit or native acceptance claim.

## Required Native Refinement

The existing `research --read <run> --step <stage>` entry now reads successful
stage journals without requiring or creating an aggregate child receipt. It
requires a terminal quiescent outer observation, exact sealed generator,
original header and input bindings, durable history observation identities,
complete successful dependency closure, tool fingerprints, extra observed
inputs, stage artifact hashes and live final output inventory. Intermediate
in-place states may be retained only when a successful current successor
proves their replacement. Missing final bytes never become available merely
because a journal exists.

New step observations persist `toolInputs` inside the immutable stage record.
The actual older current-seed record is rejected with
`journal stage lacks immutable tool bindings`. This is not repaired by copying
an unbound `tools.json` into old evidence or substituting current tool hashes.
Ordinary Python capability exceptions now produce DENY, retain exception type
and traceback artifacts, and finish the failed child receipt. Process death
and cancellation still cannot be represented as successful completion.

The existing `gambit.seed-checkpoint` now consumes either a full successful-step
reference or a checked stage journal. In-place mode leases the exact selected
seed workspace, checks its locked source and full inventory, and publishes
that same directory without a source-tree copy. It still checks the original
GNU compiler identity, full profile and all three concurrency flags. Seed
storage reuse never upgrades it to a completed runtime.

The ledger-bound seed reference requires the producer's exact outer receipt
to have been settled in the same original ledger and the consumer to hold a
currently valid reservation in that ledger. Its allowance is the existing
reserved cap, not a replenished shared balance. Unrelated settlements may
change the shared balance without invalidating this consumer's legal hold.
Expired or uncharged producers, receipt substitutions and another ledger
reject consumption. Whole-run deadline checks remain active.

`checkpoint_budget_consumption.qnt` imports the actual budget model. Three
negative controls and positive safety/conditional-progress checks passed;
715 states were exhausted in 13.622 seconds. The first two import/type-check
denials remain retained, not converted into model passes. The portable result
is appended to the existing ASCENT protocol catalog, with five native
refinement obligations explicitly open.

This closes the framework connection, not the current-source native build.
The actual old seed journal lacks immutable tool bindings and remains denied.
No original receipt or locked budget was changed to make it consumable. A
fresh correctly bound native run is still required for real stage-reuse and
complete two-pass bootstrap acceptance.

The joint pipeline test uses actual immutable history writes, predecessor
inventories, stage readback, producer settlement, a consumer reservation and
in-place seed consumption. It does not mock `bound`, `seed_reference`,
`checkpoint_allowance` or the journal database. The sealed generator manifest
is a unit fixture and payloads are deliberately opaque, non-executable bytes;
this proves framework integration, not native compiler or SMP correctness.
The same inode is retained and the failed parent is not upgraded. The selected
framework regression suite passed 212 tests in 3.684 seconds.

Reuse must bind the successful stage's complete dependency closure and the
live exact artifact inventory, not just a source revision or cache pathname.
Compiler, profile, generated inputs and current source drift must reject it.
Two genuine compiler generations, complete native grid, Gerbil correctness
and release performance remain required. The model does not make the exhausted
original native budget available again, certify deleted artifacts or permit
reconstructing the interrupted campaign's missing final receipt.
