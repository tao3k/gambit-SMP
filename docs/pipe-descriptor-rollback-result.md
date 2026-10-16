# Pipe Descriptor Rollback Result

## Model-First Observation

The source-directed ownership Recipe completed all 9 steps with PASS in
29.014405292 seconds, under its 50-second model ceiling. The positive protocol
exhausted 159 distinct / 268 generated states, with zero states left queued.
Four independent controls produced decoded counterexamples:

| Control | Counterexample States | Obligation |
| --- | ---: | --- |
| Old helper, close-on-error | 3 | One current fd must not be closed twice |
| Old helper, retain-on-error | 5 | Returned descriptors remain live; superseded ones do not leak |
| Opener reads unpublished output | 7 | Failed open must not clean uninitialized output fields |
| Omitted temporary cleanup | 5 | Rollback leaves no owned temporary descriptors |

This validates a bounded ownership protocol, not exact C refinement, actual
syscall failure reachability, or arbitrary fd aliases. The model ran against
the predecessor source lock before the C successor was applied.

Engine ID:
`fc943732ddf04239f2dd9426f57ad71f00af2b384ff04ecd77337fadffa7ff2b`.
Outer receipt SHA-256:
`81db2f56c1872bb423e35e08f1616b381a3d7978939e14d663867b8613651e9a`.
Child receipt SHA-256:
`5b9f6f1bfa97e5a0f51c900b17395985bfedcac730377874066a37b35b0e0101`.

## Candidate Source Successor

`evidence/fixtures/pipe-descriptor-owned-rollback/source.lock.json`:
SHA-256 `4a8654ce656940381614ca35b2135e11769081c945780e55a1db9d443ad3c088`.

Overlay `patches/fixtures/pipe-descriptor-owned-rollback.patch`:
SHA-256 `2ac3c902c6eac5a637b12d71349edbf4d9c64dfcac7d56fa5646726a7f7dec58`.

All 22 SFUN predecessor file identities are unchanged. Only lib/os_setup.c is
added to the candidate lock, giving 23 files. Its pinned base SHA-256 is
`df72976936ef3226c85220af1f6e77dae84d666fab7a2dfd48da0b59dce5b2aa`;
candidate SHA-256 is
`d5a27e6ae705e30a0fabe09fad25ce4cd18fd7f0abda480714ce49a7d4badedd`.
The existing exporter mechanically reapplied the full overlay to pinned Git
bytes and verified every selected candidate identity. Only the one retained
source tree was edited; no additional retained checkout was created.

The helper queues the old descriptor only after dup succeeds and updates the
current fds entry. On failure, the current entries and queued entries are
disjoint; close_on_error selects whether current entries are retained. Cleanup
still restores the original dup errno. The opener publishes hdp fields only on
success and does not clean unpublished output on failure. Successful execution
has the same number of dup/close calls and no new locks or syscalls; close order
among owned superseded descriptors changes. No numerical speedup is claimed.

The finding is generic POSIX error handling, not Darwin-only. It applies to
select-abort pipe setup as well as other callers. Distinct, exclusively owned
input descriptors remain an explicit assumption; duplicate input aliases and
platform close/EINTR behavior are not repaired here.

## Source Checks, Not Native Qualification

GNU GCC 16 syntax-only checks passed before and after the repair, including
retained HAVE_CONFIG_H, PRIMAL/LIBRARY and O3 configuration defines. The
preprocessed source contains move_fds_to_non_std, open_half_duplex_pipe and the
new ownership transfer, so this was not an excluded-branch syntax pass. This
uses retained configuration, not a fresh configure/bootstrap or linked binary.

No loader fault injection, private VM cleanup entry point or RTLD_NEXT fixture
was executed. Real public-path setup-failure and resource stability tests,
bootstrap, complete compiled/stress suites and release performance remain open.
The model receipt cannot qualify the source successor merely because its
overlay and syntax check succeed.

Four counterexamples are copied byte-for-byte under the candidate fixture:

- old-helper: `08cee7bcdd19cb1c7a03f7c7883ab373b001cbc2b9ff1280fd57988371d10f19`
- old-retain: `b03b1a934dc7eee2f1aab95bdc081346adff70e6ab4b26a4332a78e3a3c84ce7`
- unpublished-output: `846790f0c40e2e58afc60344c3e7ad1b94d680a58464f93b2439d3986bdc971a`
- leaked-temp: `99847698dd6b9ad6352e60ce7bcf4f0721bd71e30c708b1b3225fbef75386b30`

## Milestone Boundary

Cumulative native progress is still 3/12. Complete/PR GSC, GSI/GSC stress,
registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release
performance remain open. The qualification ledger remains 468.695876834 / 600
seconds, with no fresh bootstrap budget. This candidate remains research-only;
it has not been promoted to a fully green release patch.

The TLS/PSTATE audit performed before this finding did not establish another
runtime defect. Public cleanup models already state joined direct users as a
caller premise. The public topology fixture joins Scheme workers, shrinks to
P0, checks pending joins, cleans, clears TLS and then frees the VM. Those source
checks do not prove arbitrary foreign callers obey that contract; no global
lock was added on that basis.
