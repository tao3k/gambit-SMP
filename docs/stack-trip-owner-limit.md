# Owner Stack Limit Across Interrupt Publication

The page-guard incident binds an actual Scheme stack store 40 bytes before the
payload. It does not bind a header-field write or the preceding interleaving.

`___raise_interrupt_pstate` can run on another native thread. Its
`___STACK_TRIP_ON` expands to a load of `stack_start` followed by a store into
`stack_trip`. `___stack_limit`, GC and overflow undo change `stack_start` and
call `prepare_mem_pstate`, which installs the current owner `stack_limit` and
refreshes interrupts before resume. An interrupt sender can sample the old
lower-addressed start, be delayed across that update, and publish the old start
afterward. The post-store barrier does not make the earlier sample current.
A poll using only that stale value can miss the new section's allocation limit.
This is a source-reachable SC interleaving, not an observed native interleaving
or a complete C memory-model proof.

The Darwin GNU candidate retains the complete page-guard parent, changing only
`___STACK_TRIPPED` to also compare the local frame pointer with the current
owner `stack_limit`. No new ABI field or extra allocation is required. The
existing limit already includes the reserved fudge and shared-section split;
it is stronger than a separate absolute section floor. Interrupt publication
can request an earlier poll but cannot disable the owner's allocation check.
Linux and other compilers retain their original expansion.

The QNT executes split sender sampling/publication, owner section switching,
polls and bounded frame writes. Old and new sections occupy distinct ranges
of one abstract arena. Three frame burst sizes are checked; omitting the owner
check must yield an actual underflow counterexample. This SC projection does
not prove compiler poll coverage, arbitrary frame sizes, C data-race freedom,
interrupt liveness, or the exact historical crash cause. The compiler emits
polls through `_front.scm` and `_t-c-2.scm`; the bounded burst premise remains
conditional until exact native behavior qualifies this source.

No unchanged parent stress retry is required. Both bootstrap passes and the
unchanged complete native inventories must be checked on this new source,
with the original flags, topology selection and inactivity budgets. The page
guard stays enabled to preserve an independent physical underflow detector.
Model PASS never grants native, Gerbil or performance acceptance.
