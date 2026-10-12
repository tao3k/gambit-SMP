# Abandoned Result State Candidate

## Native To Model Feedback

The rebuilt parent passed target-lock release but failed both normal and
exceptional registered result-owner cases: mutex acquisition returned `#t`
instead of an abandoned exception. The exact native denial is retained under
`evidence/source-results/fixtures/sfun-owned-unwind/ended-interrupt-result-abandon-denial`.

The extended QNT model now independently rejects leaked target lock, omitted
owned-mutex abandonment and lost abandoned-result exception. Positive safety
and assumed-fairness completion exhaust 13 distinct states. The third trace
ends with an unlocked target and abandoned result yet success reported. This
is the missing contract, not another instance of the old low-level lock leak.

## Minimal Source Delta

`evidence/fixtures/abandoned-result-state/source.lock.json` reproduces the
pinned submodule plus cumulative overlay. Relative to `sfun-owned-unwind`,
only `lib/_thread.scm` changes: the SMP mutex slow path checks both its original
`owner` and post-acquisition `state` for abandonment. The fast path, ownership
linking, lock release, scheduling and GC implementation are unchanged.

This is a platform-independent SMP correctness contract, not a Darwin timing
optimization. Disabling SMP or changing processor counts is not the fix.
The candidate still requires actual compiled regeneration and the same native
assertions; source replay and model success do not qualify the binary.

## Build Attempt Boundary

The original 420-second sealed source-core recipe materialized source, then
failed autoconf because sandboxed `m4` could not create its temporary directory
under `/var/tmp`. Seed and core compilation were blocked. This is an observed
environment denial, not a Gambit compiler or GC failure. The exact attempt
remains available as diagnostic evidence; no budget was increased and no native
repair pass is claimed. The next build must retain the original budgets and
run with authorized temporary-directory access.

Runtime/release/performance admission, full suites, complete GC composition,
multi-requester/cancellation refinement and Lean qualification remain open.
