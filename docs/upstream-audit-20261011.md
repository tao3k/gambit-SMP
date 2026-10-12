# Upstream Audit: Discussion To Protocol

## Coverage, Not Just PR Numbers

Fresh discovery on 2026-10-11 returned the same **127 bounty-window PRs** as
the prior snapshot; **49 are open within that window**. No indexed head or
updated timestamp changed. This is NOT the repository's all-time open count.
The existing selected catalog has **33 PRs**, but 18 runtime reports still
lack explicit repair-model links and 13 adjacent-source reviews remain open.
Existing snapshot count must not be described as completed semantic audit.

This pass refreshed six exact-head PRs (#848, #1003, #1004, #1007, #1035,
#1043), their issue comments, reviews and inline comments, plus issue #912's
six comments. Portable snapshots are in `evidence/upstream/smp-20261011/`;
raw text and API patch pages are cached in `.data/upstream-audit-20261011/`.
Review endpoints returning zero records are recorded, not omitted. No patch
was applied and no known-failed native route was repeated.

## Decisions From Actual Reports And Source

| Evidence | Source / Protocol Consequence | Disposition |
| --- | --- | --- |
| #1003, `c687b002e812962edd688db3c1715d402eee6848` | Explicit processor context is needed for per-VM GLOCELL access. Candidate027 already passes context through MAKE_GLOBAL_PSD/PSV in `setup.c:1498,1675`; `gambit.h.in:6762` selects that VM. | Do not repeat the missing-ps repair. This does not yet prove concurrent shared symbol-table initialization. |
| #1003 comment 5275101971 | The old body says mix.scm fails; the later rebased-head report says full build and 370 unit tests pass. | Corrected the failure ledger while preserving both versions. This is author-reported, not local three-flag acceptance. |
| #1004, `b2d7700f556a75a5c937c776a79c24ad8ce53aeb` | Both configure inputs/outputs set threaded VMs when SMP is selected. Existing `vm_configuration_contract` distinguishes scheduler selection, per-VM processors and VM count. | Do not assume SMP alone proves threaded runtime activation. Body reports core pass but full-build heap overflow. Automatic flag implication is a configuration policy, not a GC repair. |
| #1007, `decff59da68b7a44c7311bfd28a1ddcba8089d26` | No-capture wait must observe process-device completion rather than consume an EOF stream that was not redirected. Candidate027 `lib/gambit/process/process.scm:128-133` still has the old read loop. | Model obligation remains open: child completion, capture/discard mode, close lifetime, GC participation and error propagation. The PR's 0.01-second polling interval is not a performance guarantee or a value to hardcode into a protocol model. |
| #1035, `ad2bd23fcc689ce76a96c725e4c579d77bcdc71d` | Releasing the thread lock reverses the mutex/thread cycle but opens an ownership-change window. Recheck the selected mutex; close admission via continuation marker; delay end-condvar clearing until cleanup finishes. | New bounded `thread_abandonment_completion` model; lock graph, waiter delivery and priority interactions remain separate obligations. |
| #848, `1ccd2f7ffa2345d5d54593243f1668f5ec666081` | Two names supplied by one descriptor may initialize twice. The inspected kernel hunk advances stages for every supplied name, not just the demanded alias. | Valuable idempotent initialization obligation. Stage-before-thunk also requires explicit reentrancy/failure semantics; stage need not mean successful completion. Full PR has 36 files with unrelated module/search changes: selective audit only, no wholesale adoption. |
| #1043, `b2f2f53a6b21bfe8c804fc4438c100e063d08cce` | This collector is test procedure-coverage collection, not garbage collection. All 118 inventory files are under tests. One follow-up describes corrected nested cond/case coverage output. | Supporting test evidence, NOT an SMP GC repair. Full semantic audit of all added tests remains open. Homebrew gsi pass does not qualify our source-built candidate. |

The #1035 author reports 18/18 regression repetitions over interpreted/compiled
and 1/2/4 processor configurations, but also 372/374 broader interpreted files,
shared serialization failures and a separate crash on both baseline/candidate.
The bounded model does not erase those residuals or imply all three configure
flags were qualified. See the exact public report and the unchanged failure
ledger for those boundaries.

## Issue 912: Reject Invalid Shortcuts

[Comment 5737147933](https://github.com/gambit/gambit/issues/912#issuecomment-5737147933)
reports Ubuntu 24.04/GCC13.3 at `a6237f30ad94e33bb3a22e096aaed0dffc18814f`,
verified release ancestry, `GAMBOPT=p1`, successful bootstrap followed by
bootclean, then a compiler-generation failure. Its September 20 follow-up
isolates one `_t-univ-2.c` regeneration: 13.104 seconds, SIGSEGV, no timeout,
with GC/synchronization in the stack. These are upstream reports, not our runs.

Therefore p1, serial compiler invocation, Linux or bootstrap completion alone
cannot discharge the reported failure. Nor does the issue title establish one
culprit commit: comment 2211949680 reports failure before the named eager-rehash
change. Do not rerun unchanged reports just to demonstrate these facts. Bind
any new diagnostic to a changed source hypothesis, actual generated-file
absence, ancestry, compiler and failed child identity. Do not attribute the
local crash to this historical report without a causal match.

## Model Review And Reading Queue

| Priority | Evidence Family | Missing Engineering Contract |
| --- | --- | --- |
| Current | #783, #788, #793, #1003, #1004, #1014, #1016, #1036 | Construction ownership, VM isolation, interruption, failure rollback and population admission. Working Session owns this implementation. |
| Current | #988, #989, #1010, #1019, #1038, #1052, issue #912 | Source-reachable stack origin, copy-ready publication, unique scan ownership, relocation, post-bootstrap regeneration. Existing paper/source models remain conditional. |
| New bounded slice | #1029, #1035, #1047 | Termination admission versus cleanup completion, ownership recheck after dropping locks, ordered transfer and waiter exception delivery. |
| Next source audit | #1024, #1026, #1031 | Thread-group insertion/enumeration interacting with termination; don't treat duplicate proposals as independent validation. |
| Next source audit | #1022, #1032, #1034, #1041, #1050 | Priority donation/preemption/quantum versus blocking and termination. Existing reported candidate failures stay open. |
| Next source audit | #1007, #1037, #1039, #1023 | Process wait and port closure, promises and mailboxes: callback/GC safety and shared-state lifetime, not only local exclusion. |
| Supporting only | #797, #1033, #1042, #1043 | Coverage and test machinery cannot establish a runtime repair. |
| Adjacent-source queue | #809, #824, #848, #868, #871, #891, #905, #926, #947, #948, #1027, #1028, #1030 | A file overlap is a reason to inspect, not proof of relevance or correctness. #848 now has a specific module-alias obligation, not a completed full-diff audit. |

Papers guide invariants but do not supply Scheme API contracts. The current GHC
3.4-3.5 reading supports separating private work, publication and termination;
it does not prove thread-join or abandonment semantics. Those obligations here
come from the actual source, PR diff and reports. Do not label a paper or a PR
fully read when only the protocol-relevant sections/hunks have been inspected.

Registry integration and native adapters remain separately reviewable. The
Working Session receives exact findings, models and open obligations; no
automatic merge, release, runtime-green declaration or performance claim is
authorized by this audit.
