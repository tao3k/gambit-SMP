# Foreign Call And Moving GC Boundary

## Source And Report

PR783's [maintainer analysis](https://github.com/gambit/gambit/pull/783#issuecomment-1265436976)
identifies cached generated-C frame state becoming stale across a synchronous
GC during a wait. The report prescribes storing the return address, publishing
cached state before the call, then reloading relocated state and the return
address. Later reports retain failures; this explanation does not establish
that every subsequent stack corruption has the same cause.

The pinned `lib/_kernel.scm` already contains the ordered protocol in
`##os-condvar-select!` (lines 4505-4524):

```text
FRAME_STORE_RA -> W_ALL -> os_condvar_select -> R_ALL -> FRAME_FETCH_RA
```

`include/gambit.h.in` defines frame access at lines 6580-6587 and selects
cached-state read/write macros at lines 6802-6803. Frame access is conditional
on `stack_break`; the new model covers an ordinary non-break frame and the
cached-state configuration, not every generated-host configuration.

The current `lib/os_io.c` call path prepares C device arrays, unlocks the
device queue around `___device_select`, then relocks and processes readiness
(lines 11699-11806). Direct GC service was not found in this inspected function
or the ticket-lock expansion. Actual interrupt-to-GC reachability, platform
heartbeat branches, callback implementations and C-local object lifetime
require a separate call-graph audit. The model assumes a GC-capable foreign
boundary as in the historical report; it does not prove that this particular
current wait executes GC internally. Do not infer a current stale-C-array bug
or change the existing boundary from that assumption.

## Composition And Native Feedback

`ffi_gc_frame_protocol.qnt` separates generated-code cache state, processor
root state, another processor's synchronous request, waiting participation,
atomic relocation, reload and host return. It permits zero, one or two GCs.
Three independent fault controls omit root writeback, state reload, or the
return-address root. Positive safety exhausts 22 distinct states, 25 generated,
zero queue (25.931 seconds). This is finite safety under ordered publication
and atomic collector steps, not weak-memory refinement, fairness, deadlock or
full collector correctness.

The first attempt changed model input during execution and is explicitly DENY;
its original outputs and invalidation remain local. The runner now snapshots
the exact model bytes for all checks, records that digest, checks source and
snapshot stability, and rejects explicitly invalidated receipts. Attempt 002
remains historical to the previous invariant. Attempt 003 supplies the three
frozen counterexamples and positive result for the current model.

`ffi_source_unit.py` extracts the unchanged embedded C from current source and
compiles it using GNU GCC 16.2.0. The fixture mocks macros, registers and zero
to two relocations: it is an extracted-source protocol test, not real moving
GC, Scheme reader verification, OS threads or Gambit ABI acceptance. Only
test copies receive the three fault injections; no runtime SCM was edited.

Source-unit attempt 001 failed its own expected-outcome gate: omitting `W_ALL`
also fails without GC because `R_ALL` restores an old register value. That
native mock observation strengthened the model's root identity invariant at
host return. The receipt is preserved as DENY. With corrected expectations,
attempt 002 passes all 12 cases: the unchanged current source passes all three
GC counts, while each injected defect produces the expected failure/control.
Portable receipts are in `evidence/model-results/ffi-*.json`.

## Decision

This narrows a historical contract and improves the model/source feedback loop;
it does not repair the remaining native compiler failure. The current source
already implements this boundary, so reapplying the historical fix or rerunning
the unchanged failing compiler solely on this result is rejected. Continue with
source-backed call/ownership hypotheses and complete artifact identity before
native bootstrap acceptance. Performance remains a separate later gate.

## Current Native Refinement Gap

The `darwin-ticket-ownership-acquire` complete compiled stress incident is
image-bound to its current interpreter and mapped through identical production
and debug object text/relocations. The fault is at JUMPRET following this exact
os-condvar-select wrapper. The register snapshot selected an ordinary frame,
with a fetched return value -44 and effective access address -53. This is not
the prior BTQ fault site and does not establish a common cause.

The positive model keeps savedRA as an independent scalar; it does not execute
the physical return slot, `mark_continuation` descriptor/link walk, stack
copying or the precise FRAME_FETCH_RA branch. Therefore model PASS cannot
exclude this native observation. Before a source repair, establish the actual
slot/caller correspondence and GC/interrupt reachability; do not assume that
GC ran inside the wait or reapply a protocol already present in current source.
Portable source/receipt correspondence is in the ticket fixture's
`kernel-return-symbolization.json`. The full native DENY and single-file PASS
both remain recorded.
