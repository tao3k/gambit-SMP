# Stack write and poll coverage

The owner-limit successor has completed both bootstrap passes, but its full
compiled stress remains DENY. The TFIB shard process is PID 601; the retained
Crash Report is PID 1047 with parent 601. Its binary hash and UUID match the
completed producer. This is a new native failure, not the retired whole-wall
accounting denial. Interrupt2 independently reaches its original inactivity
timeout. No unchanged native retry is justified.

The production and DWARF `_thread.o` have identical complete text renderings
and named text relocations. The fault at `___H___thread +100592` maps to
generated `_thread.c:11361`, `___SET_STK(9,___R1)` in `##btq-insert!`.
The instruction stores an eight-byte value at `x19 - 72`. The register and
fault-address relation is exact. It is a Scheme stack spill, not a BTQ field
store. The protected prefix does not identify the processor's active section
or establish a write to the 24-byte administrative header.

The existing owner-limit QNT assumes every bounded write burst has a poll.
The compiler's `seal-bb` explicitly omits polling in interrupts-disabled code;
the SMP rbtree implementation uses that declaration. Absence of a local poll
does not prove that the caller failed to reserve enough stack. The refinement
imports the existing protocol and withdraws only its poll-coverage premise.
Its unpolled negative must underflow even with the owner-limit guard retained.
The diagnostic control stops before an escaped write, not at successful work
completion. Neither control identifies the native preceding interleaving.

Two hypotheses remain: exhaustion between effective polls, and installation
or restoration of an invalid frame pointer. An additional possibility is that
the protected allocation is not the processor's active stack generation.
The Crash Report has no processor-state memory to separate these explanations.

The next Darwin/GNU-only diagnostic checks the target of `___SET_STK` against
the current processor's allocation lower bound before the original store. On
failure it reports the generated source site, actual frame pointer, saved
processor frame pointer, stack start/break, owner limit, interrupt trip,
allocation bounds and stack/heap section identities, then aborts. It does not
clamp a pointer, move a frame, retry allocation, drop a write or return success.
Other compilers retain the original macro. The existing page guard remains.

This adds one predictable comparison on this diagnostic path. It can change
timing and does not observe all raw stores. It cannot prove the first damaging
write, generation identity, C memory-model refinement or complete poll coverage.
The complete bootstrap and original stress inventories must use the existing
sealed framework, source lease, flags, host-selected topology and unchanged
inactivity budgets. Only a new discriminating observation may justify a repair.
The cumulative milestone count remains 5/12, with seven gates open.
