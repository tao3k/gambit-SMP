# Upstream SMP Report Audit

Audited 2026-10-10 using live GitHub issue, PR body, state, and review data.
This is a report audit, not a new benchmark or independent reproduction.
No native build or CI run was launched for this audit.

## Scope and evidence boundary

The sampled set contains 24 related candidates: 1003, 1004, 1007, 1010,
1014, 1016, 1019, 1022, 1023, 1024, 1026, 1029, 1031, 1032, 1034,
1035, 1036, 1037, 1038, 1039, 1040, 1041, 1047, and 1050.
At audit time, 20 were open, four were closed, none was merged, and the
review API returned no formal reviews for these candidates. Closed is not
equivalent to merged, rejected by a maintainer, or proved incorrect.

All pass counts below are author reports. A focused regression passing does
not certify a complete runtime, another compiler, another source revision,
default heap settings, or a combined patch stack. Our pinned Gambit revision
is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`; several submissions use
`ab6f255c` or `dcd677cd` instead. Do not silently transfer their results.

## Reported residual failures

| PR | Claimed repair | Explicit limit or remaining failure |
| --- | --- | --- |
| [1003](https://github.com/gambit/gambit/pull/1003) | Setup global-cell compile error | Original `mix.scm` failure is superseded by [rebased-head report](https://github.com/gambit/gambit/pull/1003#issuecomment-5275101971): 370 tests and full build pass; not local three-flag acceptance. |
| [1004](https://github.com/gambit/gambit/pull/1004) | SMP configuration enables real processors | Full build fails with heap overflow; core only passes |
| [1007](https://github.com/gambit/gambit/pull/1007) | Shell-command wait | `make check` and wider unit tests retain baseline failures |
| [1024](https://github.com/gambit/gambit/pull/1024), [1026](https://github.com/gambit/gambit/pull/1026) | Thread-group insertion | Mutex timeout stress test signal 11; do not count both as independent repairs |
| [1031](https://github.com/gambit/gambit/pull/1031) | Thread-group enumeration | One unresolved heap overflow; no full suite or cross-platform validation |
| [1032](https://github.com/gambit/gambit/pull/1032) | Priority preemption | Aggregate process-spawning runner does not complete on the Windows baseline |
| [1034](https://github.com/gambit/gambit/pull/1034) | Quantum accounting | p1 interrupt test still fails; intermittent patched mutex crashes disclosed |
| [1035](https://github.com/gambit/gambit/pull/1035) | Mutex abandonment lock order | 372/374 interpreted files; serialization failures remain; larger diagnostic crashes in both versions |
| [1037](https://github.com/gambit/gambit/pull/1037) | Shared pipe endpoint mutex | I/O suite 34/35 interpreted, 33/35 compiled; table decoding failure and compiler signal 11 |
| [1038](https://github.com/gambit/gambit/pull/1038) | Decoded-table rehash | Selected tests 12/12 interpreted, 11/12 compiled; compiler signal 11 and forced-GC-after-decoding failure remain |
| [1039](https://github.com/gambit/gambit/pull/1039) | Promise state transitions | Allocation-heavy candidate and baseline signal 11; optional module compiler failures |
| [1040](https://github.com/gambit/gambit/pull/1040) | Deadlock exception detection | Interrupt repeat control 24/30 patched versus 26/30 baseline; no full-green claim |
| [1041](https://github.com/gambit/gambit/pull/1041) | Blocking priority boost | 73/75 selected runs; unresolved 60-second timeout and p4 candidate crashes |
| [1050](https://github.com/gambit/gambit/pull/1050) | Mutex priority inheritance | 27/27 non-stress files at p2/p4, but full build heap overflow; two prerequisites |

These reports establish known acceptance blockers. They do not establish that
every reported signal 11 or heap overflow has one shared root cause. Labeling
a failure as present in baseline limits causal attribution; it does not
remove that failure from release acceptance.

## Narrow successes, not whole-runtime certification

- [1010](https://github.com/gambit/gambit/pull/1010): GC-root protection in
  `___make_sfun_stack_marker`; core and focused C-interface checks only.
- [1019](https://github.com/gambit/gambit/pull/1019): continuation break-frame
  marker repair; repeated Ackermann/thread-yield controls, not full-suite proof.
- [1014](https://github.com/gambit/gambit/pull/1014),
  [1036](https://github.com/gambit/gambit/pull/1036): startup heap and resize
  floor respectively; do not claim either repairs later GC scanning.
- [1023](https://github.com/gambit/gambit/pull/1023): mailbox loss reproduction
  repaired under an explicit 256 MB minimum heap; not default-profile proof.
- [1029](https://github.com/gambit/gambit/pull/1029): abandoned-mutex semantics,
  26-file non-stress directory interpreted/compiled; Apple Clang 17 evidence,
  explicit heap, no full `make check` or stress validation.
- [1047](https://github.com/gambit/gambit/pull/1047): terminated-target lock
  release; Windows clang-cl, targeted checks, not full-suite certification.
- [1016](https://github.com/gambit/gambit/pull/1016): Windows thread termination
  repair; platform-specific evidence cannot certify Darwin.

## Dependencies and duplicates

- 1037 and 1038 are related discoveries, but 1038 explicitly says it was
  built independently of 1037. No combined all-green receipt is reported.
- 1032 is stacked on 1022. 1050 is stacked on exact commits from 1022 and
  1041. 1041 overlaps quantum-accounting work in 1034. Do not apply every
  PR as an independent, non-overlapping patch.
- [988](https://github.com/gambit/gambit/pull/988) is explicitly retracted.
  On 2026-10-10 its exact head `be71ec38aaff06d4c310f5b23d916e3a31e31ca7`
  is closed, unmerged, with zero check runs and zero legacy statuses (aggregate
  state pending). Historical focused test reports are not a verified all-green
  suite. Its source remains useful input, not an accepted repair dependency.
  `rehash_lock_ownership.qnt` checks stripe-alias self-deadlock and separately
  the source-exclusivity obligation assumed when removing the outer lock.
  The unowned-source counterexample is conditional, not a reproduced native
  defect. Scheme `##table-resize!` publishes the new table before its copy loop;
  that is distinct from the C rehash comment's private-destination premise.
  Do not certify both entry paths with one ownership assumption.
  [989](https://github.com/gambit/gambit/pull/989) remains an unmerged broad
  proposal; its narrative is not approval or local acceptance evidence.

## Decision

Do not repeat known failing full builds merely to rediscover these reports.
Do not claim all-green acceptance or publish a stable threaded-VM profile
based on focused bounty regressions. Keep candidates isolated and audit
their exact source changes, prerequisite graph, and remaining GC/compiler
failures before choosing a new bounded experiment.

These correctness blockers are not a new Darwin performance optimization.
Retain the previously accepted package performance baseline separately.
The [bounty issue](https://github.com/gambit/gambit/issues/760) describes an
adoption requirement; submitting a claim is not proof of adoption or payment.
