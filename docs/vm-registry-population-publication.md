# VM Registry Population Publication

## Source Finding And Decision

The pinned base is the `vendor/gambit` submodule revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. The source successor extends
`foreign-origin-resize-domain`, not a new runtime or independent source tree.

In the candidate `lib/setup.c:barrier_sync_op`, `OP_SET_PROCESSOR_COUNT`
closed and drained registry readers only when shrinking. Growth and an
unchanged target performed an ordinary write to the volatile
`processor_count`. Global interrupt delivery reads that field under a registry
reader lease. Preparing new processor slots avoids an index-range hazard,
but does not establish synchronization for an overlapping count access.
[GNU GCC's volatile documentation](https://gcc.gnu.org/onlinedocs/gcc-8.1.0/gcc/Volatiles.html)
explicitly distinguishes volatile access from a memory barrier.

This path is worth auditing because it is a shared SMP publication protocol,
not an MCP-specific cost. Existing shrink grace evidence left growth unchanged;
existing GC membership evidence did not prove C memory ordering. The expected
benefit is correctness under concurrent interrupt delivery, not a quantified
speedup. No historical timeout or Darwin slowdown is uniquely attributed to it.

## Candidate And Evidence

After the old cohort arrives, every changed multi-VM count now commits inside
the existing mutex, registry-close/drain, publish, open, unlock and replay
sequence. An unchanged count does not write the shared field. The single-VM
branch is unchanged. This is a short publication section, not serialization
of GC or Scheme execution. The additional growth grace period still requires
real performance measurement.

- Source lock: `evidence/fixtures/foreign-origin-population-publication/source.lock.json`
  SHA-256 `86d43a3e04338a98f458d906947bd2947b8e9c38bc5089e37158bae1303aaae7`.
- Overlay: `patches/fixtures/foreign-origin-population-publication.patch`
  SHA-256 `579d51c58a537846e390f13b427d616b9f97eef89068cf0feba8cc02747ea70b`.
- Exactly `lib/setup.c` differs from the parent lock; the existing exporter
  reapplied and checked all 22 selected files.
- Model: `models/gambit/vm_registry_population_publication.qnt`.
- Contract: `evidence/fixtures/foreign-origin-resize-domain/population-publication-contract.json`.
- Portable receipt: `evidence/model-results/fixtures/foreign-origin-resize-domain/population-publication/receipt.json`.

The existing `verify` adapter completed in 14.059 seconds with host-auto
concurrency and unchanged 15-second per-check limits. Old growth produced an
access-order counterexample (31 distinct / 52 generated states); old unchanged
publication also violated safety (26 / 44). Positive safety and weak-fair
progress each exhausted 90 distinct / 150 generated states, queue zero.
Context hashes remained stable. Missing context snapshots were subsequently
copied with the existing storage adapter and verified against recorded hashes;
no executed check or receipt was changed. Publication returned
`PROTOCOL-EVIDENCE-OK`.

The existing bundle reader recovered one checked model, four open obligations
and 16 bound inputs. Focused protocol publication and source materialization
regressions passed: 37 tests in 4.463 seconds, using
`uv run --locked python -m unittest tests.test_protocol_evidence tests.test_source_materialize -q`.
An initial `uv run --locked pytest` invocation failed during collection because
the selected external pytest interpreter could not import `gambit_smp`; it
executed no tests and is not counted as a successful run. No test or framework
code was changed to obtain the successful result.

## Open Requirements

The three-slot topology distinguishes growth, shrink and unchanged count; it
is a semantic bound, not a hardcoded host CPU limit. One reader and one writer
are modeled. References to GC membership and shrink grace declare reused
obligations, not a whole-model semantic composition proof.

Physical C memory ordering, multiple-writer fairness, direct externally owned
VM/pstate users, signal storms, actual thread readiness/join, full parallel GC
and native source refinement remain open. The successor is not compiled or
bootstrapped, and no runtime or performance admission follows from QNT.
Keep historical failures and cumulative source-stage spending. Current
producer identity remains stale; that blocks its use as acceptance evidence,
not source-directed research. See `current-smp-qualification-audit.md`.
