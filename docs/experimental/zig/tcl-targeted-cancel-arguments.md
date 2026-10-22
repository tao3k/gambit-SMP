# Targeted Settlement: Conditional Arguments and Counterexamples

These are source-composed, handwritten arguments for the
[proposed contract](tcl-targeted-cancel-design.md). No model, solver, prover,
implementation, native scenario or performance experiment was run. Assumptions
are obligations, not established capabilities. See [evidence](tcl-targeted-cancel-evidence.md)
and the machine-readable [inert cases](tcl-targeted-cancel-cases.json).

## Conditional Proof Obligations

TP01. **Identity and custody.** Assume generation registration precedes exposure,
all managed pointer use holds a provider/target lease, equality includes the full
identity, and counters cannot wrap. A stale managed request cannot validate against
a replacement target at the same address: at least its registration, interpreter
or image generation differs. A copied receipt has no live issuer/ticket authority.
Raw callers bypassing generation remain dependent on original pointer lifetime
closure. This argument is safety only; it does not prove all callers were found.
[TD02–TD04, TX05, TE01]

TP02. **No already-selected old installer.** Assume the registered owner is outside
all real AsyncInvoke/native/callback scopes, including nested ones, with no
unaccounted non-local exit. A callback selected by AsyncInvoke must lie inside such
a scope until its physical return. Thus none can remain after the idle witness;
ready=0 alone could not prove this. Closing/joining old attributed senders before
settlement then prevents a later old mark. The busy branch changes no token and
never waits while holding its own required locks. [TD06–TD09, TX03, TX07]

TP03. **Attribution and terminal coverage.** Assume managed acceptance reserves
storage before mutation, commits coverage and attributed mark under L,C,A, and
only that path has attribution privilege. Every accepted old sequence is either
covered by a callback-applied selected batch, a coalesced member whose batch has a
terminal outcome, or settled-after-return. Unknown marks fail validation. Detach
cannot lose accepted work without a custodian, and it does not turn application
into observed/delivered cancellation. Raw overwrites and arbitrary mixed histories
are outside this clean proof. [TD03–TD05, TD07, TD09, TD13, TX01–TX04]

TP04. **Unrelated work and processing order.** Assume owner idleness, an unchanged
registered list and A serialization. Targeted removal never changes another
handler's ready bit or next link. A remaining-ready scan includes a concurrent
mark ordered before its lock, and a later mark restores readiness itself. Normal
AsyncInvoke still chooses the first ready list entry on each pass. No marked
unrelated callback is lost or reordered by list surgery. Event timing/wake-count
and global callback-code transformations are not claimed identical across adding
a new managed settlement operation. No lock-free or bounded-time progress result
follows. [TD06, TD09–TD10, TX02–TX03]

TP05. **Raw preservation with a stated domain boundary.** Assume every raw entry
stamps rawInterference under C and follows the original raw payload/mark behavior;
no private side path can modify raw state unnoticed. A raw call before provisional
settlement blocks it. A call between provisional and final phases changes the
serial/taint and blocks reset. A call concurrent with the final critical interval
either wins C and blocks reset or loses C and runs after fresh publication. In
none of those schedules does old-managed cleanup erase it. A raw request already
installed by idle async service still blocks because taint is not cleared by the
ready bit or reset counter. Full general mixed-domain observational refinement is
not proved; RawOnly semantics and the prohibition against disposing raw idle debt
are mandatory. [TD04–TD05, TD11–TD14, TX08, TL01]

TP06. **Reset to publication.** Assume every precondition is checked for the entire
same-owner frontier under L,C,A, selected reset is callback-free/no-fail, no
allocation/destruction/delivery can reenter, and fresh readers obey synchronization.
No CancelEval can enter C to mark between final validation/reset/publication.
No owner callback can reinstall flags because the owner is executing this operation
under its exclusive ticket. The same binding/tree/coverage facts therefore support
ResetReceipt and publication at the chosen critical transition. A relaxed epoch
store, unlocked gap or recursive log would break a premise. A receipt only proves
this cutoff, not that no authorized fresh/raw cancellation occurs afterward.
[TD13–TD16, TX04, TX06, TX09, TL01–TL02]

TP07. **Failure and descendants.** Assume complete same-owner ancestor/descendant
frontier validation and pre-reserved commit storage. Failure before mutation leaves
pending bytes/marks with the old owner; provisional detachment followed by failure
leaves terminal custody recorded and prevents replay. Raw/unknown state is retained.
Failure after any reset quarantines the whole frontier without fresh publication.
Cleanup records are not complete until actual cleanup returns and any derived work
is charged. This is a safety/custody proof, not termination: a hostile callback,
unjoined producer, owner starvation or permanently pending raw request may prevent
reuse indefinitely. [TD09, TD11, TD14, TD16, TE01, TL03]

TP08. **Local lock order, not global deadlock freedom.** Assume every added path
obeys L -> C -> A, no callback/wait occurs under them, and any existing owner work
returns before ticket acquisition. A cycle consisting only of these acquisitions
would require a reverse edge, excluded by the hierarchy. Current Invoke's A release
before callback-C is crucial. This does not prove extensions follow the hierarchy,
Tcl allocation has no exceptional process termination, or unreviewed lifecycle
hooks never call back. Those are separate qualification conditions. [TD06–TD08,
TD14, TX01–TX06]

TP09. **Positive value is conditional.** For identical admitted request and raw
semantics, let the old reuse barrier's actually avoidable cost be D, targeted
validation/scan/receipt/commit cost be S, additional hot-path/custody cost be M,
and additional maintained policy/ABI obligations be K. Runtime work falls only
when D > S + M over equivalent complete histories; total engineering support is
improved only if genuinely retired duplicate obligations exceed K and retained
new obligations. Delaying unrelated work is not reducing its total cost. Neither
proof depends on Zig, and neither establishes a positive Zig increment. [TD17–TD18,
TV01–TV08]

## Distinguishing Interleavings and Missing Premises

| Case | Counterexample schedule | Required outcome / missing premise |
| --- | --- | --- |
| TC01 | Delete token; allocator reuses its address; old job submits saved pointer | Full identity plus lease rejects managed ABA; raw stale-pointer closure remains necessary |
| TC02 | Remove target and recreate it after a different ready handler | Handler priority changes; keep original registration/list position |
| TC03 | Invoke selects token and clears ready; callback has not taken C; host sees zero | Busy; physical callback scope must finish before settlement |
| TC04 | Callback is active; marker sets ready while asyncActive=1 and asyncReady=0 | Zero global readiness is not completion; joined writers and true owner idle required |
| TC05 | Managed accept increments host counter, allocation fails before mark/coverage | No accepted receipt; retain caller custody or roll back reservation before exposure |
| TC06 | Attributed mark unlocks A; generic marker increments serial; host then reads serial | Host cannot attribute that mark; attribution and mark commit together under A |
| TC07 | Two pending requests have different flags/messages; receipt claims both observed FIFO | Pending coalescing is last-payload; distinguish coalesced/applied/observed outcomes |
| TC08 | UNWIND already installed; later pending request has no UNWIND | Installed UNWIND stays sticky until valid reset; do not infer it from the last pending flags |
| TC09 | Raw idle cancellation precedes managed settlement; helper clears all ready/flags | Block clean reuse and preserve raw next-script obligation |
| TC10 | Raw callback runs in an idle event poll; ready becomes zero; host resets | rawInterference still blocks; installed flags cannot identify consumed next-script debt |
| TC11 | Provisional receipt issued; raw mark arrives before final reset | Final serial/taint validation fails before reset; raw state survives |
| TC12 | Final validator releases C; raw accepts; private reset then clears flags/token | Invalid design; hold C through reset and descriptor publication |
| TC13 | Raw waits on C while final publication commits | Raw runs afterward and may cancel next script; do not retroactively erase it |
| TC14 | Helper clears global asyncReady although unrelated handler is still ready | Repair readiness by locked scan; preserve other handlers |
| TC15 | Helper leaves asyncReady true with no remaining ready handlers | Possible empty service progress; use scan, disclose already emitted alerts |
| TC16 | Helper takes A then C; CancelEval holds C waiting for A | Lock cycle; retain C -> A, with callback unlocked |
| TC17 | Parent token cleared; child has independent raw pending cancel | Whole frontier validation blocks; parent receipt is insufficient |
| TC18 | Reset returns OK with numLevels nonzero | Existing reset can be no-op; true idle/zero nesting plus postcondition required |
| TC19 | Reset flags, then log invokes Scheme/Tcl before fresh publication | Ticket invalid; allocation/log/cleanup outside commit, renew closure |
| TC20 | First child reset succeeds; next target fails; host publishes partial tree | Quarantine whole frontier; no fresh epoch or rollback fiction |
| TC21 | Generic AsyncMark targets private cancel token without a request record | Unknown debt blocks clean receipt; mark behavior retained |
| TC22 | Builtin interp cancel is labeled managed by a host wrapper it never crossed | Raw provenance hook at actual core entry; mixed-domain reuse remains unqualified |
| TC23 | Dropped raw request is called an optimization; deferred unrelated handlers called eliminated work | Neither is same-semantics total-work saving |
| TC24 | Zig defer/allocator is credited with proving no Tcl callback/root/marker gap | Protocol and Gambit custody remain necessary in either provider |

All cases are inert written scenarios, not runtime observations. Complete source,
installed producer coverage, exception/control behavior and progress remain
unresolved; [traceability](tcl-targeted-cancel-traceability.json) records the boundary.
