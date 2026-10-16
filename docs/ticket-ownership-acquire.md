# Shared Ticket Ownership Acquire

## Why This Successor

The ALLOC-only successor bootstrapped, but its compiled tfib still failed.
The ticket/BTQ composition exposes a distinct caller-selection obligation:
mutual exclusion without visibility is insufficient if the successor observes
an already-removed minimum. This is a source-directed hypothesis, not proof
of the native crash's cause. The old native route is not repeated unchanged.

`darwin-ticket-ownership-acquire` retains all 23 locked files from the ALLOC
parent; only `include/gambit.h.in` differs. In the production ticket wait,
Darwin GNU with `__ATOMIC_ACQUIRE` support uses `__atomic_load_n` with acquire
ordering. Other compiler/platform branches retain their volatile load.
Ticket reservation, unlock, trylock and the debug implementation are unchanged.
The existing ALLOC and GC call-site fences are deliberately retained to avoid
combining an ordering repair with a fence-removal optimization.

The primitive is shared by Scheme locks and runtime locks. The source change
is therefore broader than an ALLOC repair despite its small diff. This is not
a portable ISO C atomic migration, a trylock audit, or evidence that the
underlying defect exists only on Darwin. No global serialization or SMP/VM
switch is disabled.

## Atomic Check

The sealed `darwin-ticket-ownership.recipe.json` projects the actual parent
configured header, applies an exact-byte delta, then reprojects and binds it.
The changed template is separately reproducible through the source lock and
full overlay. No third full source tree is created. Research C fixtures retain
their research-asset provenance; only the actual source header is required as
locked source consumption by each compilation.

GNU16/GNU23/O2 compilation passes. In `ticket_cursor_read`, reservation is
`ldaddal` at 0x8, the ownership poll is acquire `ldapr` at 0xc, and the protected
load is at 0x18. There is no added DMB in this wrapper. The existing comparison
wrapper retains its explicit `dmb ish`. This is projected-object codegen,
not full production/LTO codegen and not a measured performance improvement.

The real pthread fixture creates one worker per online CPU using `sysconf`,
each performing 10,000 lock-protected counter/mirror updates. It passed with
an exact final count and matching mirror. No worker number is hardcoded.
It is a single-lock test, not a VM/GC correctness gate. The full recipe took
14.006 seconds; the native test stage took 1.616 seconds. Exact source,
header, object and receipt identities are retained in
`evidence/fixtures/darwin-ticket-ownership-acquire/handoff-observation.json`.

## Qualification

The existing leased full source worktree is reused. The first attempt passed
configure and seed but failed review because the inherited intent still bound
the parent's header SHA. Bootstrap did not run. Preserve this denial; do not
relabel it as a compiler failure or bypass the review. The source remains
unchanged while a new intent binds the actual header and explicitly retains
historical failures without asserting their causes solved. Existing object
files are reused through ordinary make; seed is not relabeled as bootstrap.

At this local-lock checkpoint the next required checks were two-pass bootstrap,
unchanged compiled tfib and complete stress, followed by lifecycle/FFI, Gerbil
correctness and performance. Model and atomic test results do not increment
the 5/12 milestone.

## Full Native Outcome

The rebound review passed, followed by two complete bootstrap passes (all four
phases twice). Bootstrap stage: 138.169 seconds; whole run: 212.747 seconds.
The unchanged compiled tfib passed alone, but the complete host-parallel stress
run remained DENY: tfib failed with LO=11, terminate and interrupt passed, and
interrupt2 exceeded the original 300-second completed-file inactivity window.
Whole run: 311.866 seconds. A timeout does not prove deadlock. The single-file
pass is retained but cannot establish that the crash is repaired.

The image-bound incident now faults in `___H___kernel`, not the earlier BTQ
removal. An exact configured-command debug object was obtained without another
configure or bootstrap. Its text and all 5,954 text relocations match production.
DWARF maps the fault to generated kernel line 22807: JUMPRET after the existing
os-condvar-select register/frame restore. The ordinary-frame branch fetched
value -44; accessing offset -9 yields the reported address -53. This does not
show who wrote that value or establish moving GC inside the foreign call.

The existing FFI frame model already represents ordered publication/reload,
but assumes a saved return address survives as an abstract scalar. Source
refinement must now address the actual physical frame slot, descriptor/stack
walk and reload boundary. Do not simply reapply the historical wrapper or
repeat this unchanged native candidate. See the fixture's full stress and
kernel-return-symbolization observations. Milestone remains 5/12.
