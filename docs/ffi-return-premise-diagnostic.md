# Return Address Premise Diagnostic

## Established Input

The exact current ticket-runtime incident has x23 = -44 at the return-label
metadata read, and x21 = 0xffffffff0a000020 after the C wait result. A sealed
configured-header compilation and native test confirms these are respectively
ABSENT and FIX(ERRNO_ERR(EINTR)), not an unspecified pointer and random C result.
The classification is bound to the captured registers, ABI fixture and recipe.
It does not identify the interrupt sender or who produced ABSENT.

The production kernel object stores incoming R0 at the ordinary frame pointer
before publishing state and calling C. After C it reloads FP, reads the
conditional return slot and dispatches. The generated **active SMP** wait
procedure assigns an explicit return label before calling os-condvar-select.
Do not use the second, non-SMP scheduler branch to explain this run.

The direct heartbeat path calls raise_interrupt; raise_interrupt_pstate records
flags, trips the stack check and aborts select. It does not directly execute
Scheme or GC. Virtual device callbacks/platform branches are not all excluded.
The original tfib workload creates/joins threads and does not explicitly resize
VMs. Existing idempotent idle-deque removal and stack-overflow undo invalidation
are already present; they are not new fixes to reapply.

## Preimplementation Review

The physical-frame composition assumes a valid incoming RA but cannot establish
it from the later crash. Distinguishing an invalid input from save/call/reload
loss is therefore more informative than another unchanged stress run. No
runtime speedup is expected or claimed.

The diagnostic successor changes only lib/_kernel.scm relative to the ticket
candidate. Under Darwin/GNU, it checks R0 for ABSENT immediately before storing
the return address and immediately after fetching it on C return. The two
distinct fatal messages are emitted **only on violation**. No normal-path log,
heartbeat, GC service, scheduler policy, assertion relaxation or injection hook
is added. The existing reader/compiler and full two-pass bootstrap validate
the embedded C; the rejected general Scheme scanner is not substituted back.

The first source-edit draft placed the entry check in a similarly shaped
unrelated C block. The bounded diff review caught and corrected it **before**
source-lock export, workspace adoption or native execution. Only the two
intended locations are in the exported candidate.

This is a diagnostic source lock, not a release patch or repair. A marker at
entry challenges the model input premise; a return-only marker narrows the
interval. Neither alone identifies the writer or proves a GC defect. A run
without either marker is inconclusive, not a fixed crash. Retain prior native
DENY and all unchanged stage windows; reuse the existing full source workspace.

## Observed Outcome

The diagnostic source completed two bootstrap passes: 127.740 seconds bootstrap
stage, 201.976 seconds whole attempt. Both marker strings are in the actual
interpreter. The full unchanged compiled stress then accepted three files and
failed tfib with LO=11; no timeout (58.205 seconds native stage, 66.564 whole).
All three terminal group logs contain zero entry/return ABSENT markers.

The current image-bound incident instead returns to the same BTQ remove L9
right-child color read (host-relative 33864). A new exact configured-command
debug object matches production text and all 5,840 text relocations; DWARF maps
to generated thread line 11553. This does not validate the earlier foreign wait
path. Do not broaden or retain these checks as a repair. The next primary
obligation remains physical GC/edge validity and source/caller composition,
not another unchanged return-premise stress run.

The inspected direct notification path, already-present sync acquire/release,
idle-deque detachment and stack-undo invalidations remain source facts, not
proven whole-system correctness. A GCC IPA workaround mentioned in configure
targets shared/high-optimization conditions; the current static RTS/O1 run does
not establish that workaround's applicability. The brief GNU issue search
returned older/different-target optimizer reports, not a current GCC16 Darwin
match; no compiler-disable candidate was admitted from that search.
Screened primary references: [AArch64 modulo-scheduler patch discussion](https://gcc.gnu.org/pipermail/gcc-patches/2025-April/681849.html)
and [AArch64 early-RA bookkeeping fix](https://gcc.gnu.org/pipermail/gcc-cvs/2024-February/399107.html).
These are leads with different scope, not causal evidence for this incident.

Portable receipts, image mapping and source identity are retained under
`evidence/fixtures/darwin-ffi-return-premise/`. Milestone remains 5/12.
