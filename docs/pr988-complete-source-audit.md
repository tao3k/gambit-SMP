# PR 988 Source And Report Audit

## Identity And Scope

Reference: https://github.com/gambit/gambit/pull/988

Audited head: `be71ec38aaff06d4c310f5b23d916e3a31e31ca7`.
Base: `920b945890add21a223c806c36862cf9c18dc98b`.
The complete diff contains 36 files, 106,304 additions and 98,621 deletions
(17,647,214 bytes). `src/gambit_smp/upstream_audit.py` checks every file's numstat
against the API inventory and binds the full diff digest and revisions.
Portable evidence: `evidence/upstream/pr988-inventory.json`. The raw full diff
remains a local cache artifact; this repository records its digest, not a claim
that the complete generated output has been semantically validated.
No change from this PR is applied wholesale.

This is a historical repair reference, not an accepted upstream patch: the PR
is closed and unmerged, with its body marking it retracted. Successful reports
remain useful evidence for selecting source-backed obligations; they do not
establish correctness of every change or of our current pinned source.

## All 36 Files

| Group | Files | Audit boundary |
| --- | --- | --- |
| Configuration (1) | `configure` | Autoconf regeneration; not an SMP protocol repair. Do not import unrelated regeneration churn. |
| Runtime source (2) | `lib/mem.c`, `lib/os_io.c` | Handwritten synchronization, GC and process-wait changes reviewed. |
| Scheme source (3) | `lib/_system.scm`, `lib/_thread.scm`, `lib/_repl.scm` | Hash-table retry/publication and lazy startup reviewed. |
| Report (1) | `smp.md` | Full report reviewed; distinguish individual stress runs from bootstrap acceptance. |
| Generated compiler C (16) | `gsc/_front.c`, `gsc/_gambitgsc.c`, `gsc/_gsc_.c`, `gsc/_prims.c`, `gsc/_ptree2.c`, `gsc/_t-c-2.c`, `gsc/_t-c-3.c`, `gsc/_t-cpu-abstract-machine.c`, `gsc/_t-cpu-backend-arm.c`, `gsc/_t-cpu-backend-riscv.c`, `gsc/_t-cpu-backend-x86.c`, `gsc/_t-univ-1.c`, `gsc/_t-univ-2.c`, `gsc/_t-univ-3.c`, `gsc/_t-univ-4.c`, `gsc/_utils.c` | Complete downloaded diff and file inventory validated, not a proof of regenerated semantic parity. |
| Generated interpreter C (2) | `gsi/_gambitgsi.c`, `gsi/_gsi_.c` | Same generation/link closure requirement. |
| Generated library C (11) | `lib/_eval.c`, `lib/_gambit.c`, `lib/_io.c`, `lib/_kernel.c`, `lib/_module.c`, `lib/_nonstd.c`, `lib/_num.c`, `lib/_repl.c`, `lib/_std.c`, `lib/_system.c`, `lib/_thread.c` | Rebuild from current source; do not copy historical generated files. |

## Repair Obligations

| Source mechanism | Existing evidence or model | Remaining obligation |
| --- | --- | --- |
| GC root-phase barrier and copied-stack markers | `gc_scan_barrier`, `gc_stack_marker`, lifecycle/source guards; overlap with PRs 1019/1038 | Whole collector/native bootstrap, not just bounded model invariants. The copying loop already uses `MISC_MEM_LOCK`; do not repeat the missing-lock hypothesis. |
| Table stripes, atomic still-reference counts, removal of outer rehash lock | `rehash_lock_ownership`: nested same-stripe deadlock and unowned-copy negative controls | Ownership differs across C private destination and Scheme resize. Scheme publishes the new table before copying; private-publication assumptions do not prove that path. |
| Scheme table probe, lock, validate, retry | Source audit of `_system.scm` | Custom predicates can allocate/GC; cross-processor publication, retry and exception exits require transaction-level modeling. |
| Symbol/global table lock | Source audit of `mem.c`; related PR 989 | Callback reentrancy and GC while holding the lock remain unproved. |
| Process error-pipe polling and GC service | `exec_gc_polling`: blocking-read and failed-nonblocking-setup counterexamples | Actual code ignores `F_GETFL`/`F_SETFL` failures. A checked setup is an abstract obligation, not an applied repair. Cleanup and register/root visibility remain outside this model. |
| Lazy processor startup | `lazy_vm_startup`: resize failure leaves a false ready flag | Do not simply move the flag: recursive startup callbacks/concurrent callers need an explicit startup ownership protocol. Native tests must confirm actual processor count. |
| Generated module consistency | Report describes stale `_system.c` type/label mismatch | Bind Scheme source, generated C, archive, compiler and executable linkage; interpreter success does not validate compiled linkage. |

## Report Coverage

`smp.md` reports interpreted/compiled table tests at one/two processors,
box stress, SMP tests 12/15/18, and later broader SMP test success. It also
describes symbol stress, Gerbil standard-library runs and an `open-process`
failure rate reduced from roughly 75% to roughly 6%: the residual failure is
not green. The public follow-up comment describes compiler progress beyond
initial crashes, not a complete self-bootstrap receipt.

One crucial report correction is that a compiled test linked the installed
archive while the interpreter used the build-tree runtime. Another is stale
generated C after Scheme source edits. Both are artifact-closure obligations,
not reasons to accept apparently successful mixed-toolchain results.

The report catalog retains other PRs and their separate negative obligations.
The new models strengthen this reference without treating it as the sole
source of truth. No native bootstrap or release acceptance follows from this
audit, inventory validation, historical reports, or TLC success alone.
