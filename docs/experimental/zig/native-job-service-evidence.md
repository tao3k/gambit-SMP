# Native Job Service Evidence Ledger

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Local bindings
identify working-copy bytes, including the materialized patched Gerbil source.
No implementation, native/compiler/performance test or ASCENT run occurred.

## 1. Direct Source Evidence

| ID | Inspected anchor | Finding / limit |
| --- | --- | --- |
| J01 | [_gsclib.scm](../../../vendor/gambit/gsc/_gsclib.scm):265-393,451-542 | Existing compile and executable requests produce mode-specific params, native exit handling and output paths. Generated temporary deletion precedes the status branch on the inspected ordinary path; cleanup/error ordering is part of migration. |
| J02 | [_gsclib.scm](../../../vendor/gambit/gsc/_gsclib.scm):544-593 | `##gambuild` chooses target driver/op, environment prefixes/install directories, resets TTY, calls `##run-subprocess` without output capture or stdin redirection and supplies output cwd. These are concrete replacement obligations. |
| J03 | [gambuild-C.unix.in](../../../vendor/gambit/bin/gambuild-C.unix.in):62-175,177-283,285-411 | Metadata reduction, package queries/path precedence, string accumulation, template substitution and eval serve obj/dyn/exe. Query cflags then libs, including object mode; missing tool writes to `/dev/tty`. Replacing final CC invocation alone does not retire resolver support. |
| J04 | [patched Gerbil driver](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/driver.ss):1054-1113,1190-1205 | Darwin generates runtime C once, copies static C, invokes native object construction, then env/gambuild bundle with distinct metadata and alias. Generic invoke also serves semantic GSC calls; it cannot be globally removed by native caller migration. |
| J05 | [process.scm](../../../vendor/gambit/lib/gambit/process/process.scm):67-146 | Existing process utility supports cwd/env/stdio and status; capture path reads Scheme string data. Typed Scheme direct execution is a real reuse alternative. New bounded byte protocols are design, not proof current capture is byte-for-byte identical. |
| J06 | [os_io.c](../../../vendor/gambit/lib/os_io.c):3519-3561,8501-8562,9127-9345,9547-9562 | Generic process cleanup/status already exists. Selected POSIX signal handler waits for any child then searches registered devices. Exec branch sets child cwd/env and reports launch errors through a pipe. Independent in-process reaper conflict is a conditional design hazard, not reproduced behavior or proof of installed flags. |
| J07 | [_io.scm](../../../vendor/gambit/lib/_io.scm):7336-7387 | Process status uses Gambit I/O waiting, timeout and error delivery, then returns the runtime status. Native enum/integer substitution alone does not preserve caller behavior or GC/control cooperation. |
| J08 | [caller-retirement plan](native-caller-retirement-plan.md):sections 2-5; [E matrix](native-argv-equivalence-matrix.md):E01-E32 | Source-reviewed G/V caller lists and prior admission design constrain M2-M8. These are retained research premises, not fresh native observations or completed retirement proofs. |
| J09 | [RFD design](return-frame-planner-case.md):sections 3-7; [provider evidence](planner-facade-support-evidence.md):FP01/FP02/FP08 | RFD exact arrays need no runner/growing container. LLVM ordinary-return output normalization and provider lifetimes remain distinct. These reviewed premises cannot be added again as new saving. |

The caller inspection is bounded to these paths and the prior G/V inventory;
it is not an exhaustive census of third-party script users. NJR01-NJR08 are
conditional dispositions. Worker deployment, incidence edges SA01-SA09 and
cost inequality are project deductions, not behaviors already present in code.

## 2. Primary Platform / Library Evidence

The following reading identities are upstream sources, not pinned downloaded
bytes, installed versions or jointly qualified host/provider cohorts. Published
examples and tests were not executed. Failed initial raw-source/POSIX page
requests supply no evidence of missing capabilities.

**P01 — Zig has reusable process primitives, with a narrower contract than NJS.**
[Zig 0.15.1 Child.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/process/Child.zig),
init/spawn/wait/collectOutput/run, supplies argument, environment, cwd and stream
controls. Collection is not termination; run returns owned buffers and uses
ignored stdin plus piped outputs. Our design requires a separate inherited
stdio path, guarded transfers, quotas and result policy. This reading establishes
reuse opportunities, not qualification or automatic project cleanup correctness.

**P02 — A serious C process reuse alternative exists.**
[libuv process documentation](https://docs.libuv.org/en/v1.x/process.html),
options/spawn/close, supplies args/env/cwd/stdio and exit/signal callbacks. Handle
closure is required even on spawn failure; premature Unix close can leave a
child unreaped. Our inference: C need not own every platform primitive, while
loop/drain/lifetime integration remains an incremental cost. This is not a local
libuv dependency selection or proof it meets every E/TTY requirement.

**P03 — Shared library ownership does not eliminate upgrade work.**
[Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html),
Process, environment/arguments and atomic/temporary files, documents concrete
I/O/process API changes. Our inference is to charge shared upgrade ownership
once plus actual affected use sites; neither annual frequency nor cost is known.
The 0.15.1 reading is not a recommendation to freeze an old support profile.

**P04 — Provider access and ownership are language-independent.**
[MLIR C API](https://mlir.llvm.org/docs/CAPI/), design/ownership/stability,
offers C-accessible handles without a stability guarantee. NJS may host an
adapter; neither C imports nor worker isolation establishes IR/runtime meaning.
The existing [provider ledger](native-layout-provider-evidence.md) records
versioned LLVM target/object APIs and separate tail/layout/cohort gates.

**P05 — Gambit's abstraction boundary has a paper basis.**
[Feeley and Miller, PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
sections 2 and 4, treats frontend/backend negotiation and logical references
explicitly. The design retains that semantic boundary while separating native
jobs. The paper does not prescribe this worker, Zig, modern process libraries
or a transferable maintenance/performance ratio.

## 3. Structural Quantification and Unresolved Evidence

For N migrated Gambit native requests, the design removes N target-C script
dispatch edges from the selected route. It still needs actual tool invocations.
For P admitted package requests all succeeding through both queries, the old
sequence requires 2P query actions; the managed plan must preserve them where
observable. Failures can stop earlier. Counts are source/design equations,
not observed executions; helper subprocess counts and elapsed time are unknown.

If K worker lifetimes serve those requests, worker start is K, while submission,
delivery, per-job validation and actual tool work remain. No K<N assumption,
throughput gain, cache hit or persistent-daemon requirement is established.
For direct Gerbil GCC callers, the old route differs: do not credit removal of
a Gambit script edge that they never used. No reduction in semantic `gsc -c`
generation is claimed for J04, which already generates its C once.

The portfolio formula counts support artifacts/change events once, with actual
consumer edges. More operation modes are not more backend implementations.
No positive cost interval follows from 2P, N, K, source counts or SA row counts.
The native worker versus typed-Scheme comparison is an independent necessary
gate; passing the C/Zig worker comparison would not close it.

Unresolved: selected host ABI/library/signal/wait cohort; Scheme gateway and
GC/control; byte capture/output decoding and limits; inherited fd/TTY semantics;
launch/status/result delivery; shutdown/orphan/unknown outcome; selected caller
and E closure; actual private C support left after reuse; shared and marginal
cost bounds. Earlier L1/L2/ES/DTrace observation gaps remain open. Nothing here
reclassifies historical failures or supplies native/theory witnesses.
