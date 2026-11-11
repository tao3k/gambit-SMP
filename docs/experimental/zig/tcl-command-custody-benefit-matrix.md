# Tcl Custody: Modern Generated C and Zig Net Benefit

Design-only runtime/value accounting. No implementation, timings, invented
speedup or human-day estimate. Read the [design](tcl-command-custody-design.md),
[arguments](tcl-command-custody-arguments.md) and
[evidence](tcl-command-custody-evidence.md).

TV01. The immediate benefit is a specified and potentially admissible lifecycle
for modern GC/VM operation. Preventing an unowned candidate, invalid callback
or skipped cleanup is a correctness requirement, not a number of saved CPU
cycles. The inspected `scheme_call_cmd` has no post-return cd read; do not turn
delete timing alone into a measured use-after-free claim or an assumed saving.

| Necessary component | Existing support credited | Modern generated C responsibility | Zig responsibility | Net-benefit condition / falsifier |
| --- | --- | --- | --- | --- |
| Creation reconciliation | Existing RC/still carrier, normal allocation-failure cleanup | Builder/publication holds, identity, failure disposition and reentrant replacement policy | Same state/owner/receipt rules, optional tagged representation | Eliminates an actual duplicate or missing ownership branch after migration; cannot count old-command deletion as rollback |
| Owner and callback admission | Existing Scheme event loop and GVM entry | Tcl creating-thread confinement, event/eval scopes, root-before-effect and independent nesting | Same Tcl affinity, VM/root/control protocol; another provider boundary if introduced | Can reuse existing owner service rather than a second executor; generic cross-thread pool is not a valid substitute |
| Revoke and drain | Existing delete callback, RC scan/donor patch | Counted invocation/outcome/work/scan users and pre-dispatch scope grace | Same lifetime proof; ordinary defer does not remove deferred users | Safety enabling; extra retention and counters may increase time/space |
| Root and marker | Existing still vector, precise GVM frames and marker checks | Reuse representation, typed stores/reload, scratch reservation and C catcher | Same Scheme GC and native return-capability laws | Avoid redundant per-call vectors/roots only where donor support already suffices; cannot retire marker validity |
| Result and image | Existing native string copy and custom free callback | Explicit result ownership, allocator pairing, module last-return; copy only if chosen | Same ownership and ABI; typed owner wrappers may express states | Separate bytes from continuation graph to reduce unnecessary retention; added snapshot/copy cost must be charged |
| Cross-library cleanup | Tcl normal return/error cleanup | Explicit closed-return or result boundary; general jump remains unresolved | Same library obligation plus qualified C corridor where required | No positive correctness credit for unsupported jump; changing error semantics is not equivalent optimization |
| Shared generator | Existing Scheme conversion/type knowledge | Emit one effect/exit/ownership plan replacing actual raw cohort recipes | Consume same plan or add separate emitter/toolchain support | Actual retired duplicate representations must exceed additional provider/ABI/upgrade surface |

TV02. Source-grounded quantities: a successfully registered command currently
uses one RC allocation with one data field and one one-slot still vector for
proc. The candidate can retain those same two allocations, adding control
metadata if needed; this research demonstrates **zero existing allocation
removed** by either language. There is one invocation claim per live native
callback and one scope claim per callback-capable foreign operation. These
are logical claims, not necessarily heap allocations. Nesting depth and queued
work determine simultaneous retention, not the count of command names.
[TE01–TE06]

TV03. A safe lower-cost design may use one owner-thread counter/epoch registry
for builder, publication and active users rather than independent atomic
refcounts everywhere. Scanner and remote-message synchronization still needs
the shared GC/queue contract. Choose either an explicit owner registry or a
qualified Preserve/EventuallyFree adapter for native storage; do not layer both
without distinct users. Preserve does not replace Scheme rooting or raw-jump
cleanup. Both modern C and Zig can reuse the chosen service. [TX03, ND01–ND02]

TV04. Quantify a fixed admitted history without assigning fake coefficients:

```text
Ncreate, Nentry, Ndelete, Nscope, Nresult   actual operation counts
Nmessage, Nroot, Ngrace                   extra protocol operations
D_k                                     real duplicated work retired in family k
s_k, c_x                                comparable future per-operation costs
Delta_copy, Delta_gc                    extra copying and GC work

net_saved_time = sum_k(D_k*s_k)
                 - sum_x(N_x*c_x) - Delta_copy - Delta_gc
```

Only marginal added operations belong in N_x; retained old conversion and
trampoline costs cancel. A safety obligation newly made correct is not entered
as positive D_k. Root/graph scan savings use the prior callback matrix and
are counted once. Current evidence gives no positive numerical lower bound
for the sum of retired duplicate work in this Tcl adapter.

TV05. Retention can be quantified independently:

```text
retained_native_bytes(t) = sum of distinct live record/ledger/result byte extents
retained_managed_bytes(t) = union of managed objects retained by actual roots
retention_area = integral of excess retained bytes over time
```

A single long pre-frontier event scope may retain many revoked records, so
“one increment per callback” understates space cost. Result bytes should keep
their native allocator/image lease rather than the whole managed graph unless
the release implementation actually needs that graph. A more precise dispatch
receipt could reduce conservative scope retention, but its maintenance/runtime
cost and complete Tcl dispatch coverage are not established here.

TV06. Language increment is a separate comparison under identical accepted
behavior. Let S be actual common support replaced by the Zig provider, and Z
the added provider/C-island/representation/upgrade cost in the chosen runtime
and maintenance dimensions. Positive Zig increment requires S>Z in the stated
dimension, without shifting uncounted work to C or Scheme. Tagged unions,
ordinary cleanup and error unions may improve expression; they eliminate
none of Tcl's thread, root, marker, adoption, drain or nonlocal-control laws.
Zero such required law has been proved removable by choosing Zig. [TL03–TL04]

TV07. Decision matrix:

| Claim | Defensible result now |
| --- | --- |
| Controlled ordinary-return lifecycle can close in theory | Conditional on TP01–TP05 and complete caller/user premises |
| Arbitrary current cross-Tcl continuation escape is equivalent and clean | Unresolved; TP06 gives concrete counterexamples |
| Old responsibilities retired by this study | 0; retirement requires migrated create/invoke/delete/event/result/shutdown users |
| Existing per-command allocations eliminated | 0 demonstrated; reuse is distinct from removal |
| Root/graph work saved | Prior conditional scan terms, not credited twice here |
| Positive runtime net saving of this lifecycle redesign | Not established without retired-work and marginal-cost evidence |
| Positive incremental Zig value over generated C | Unresolved; generated C remains the mainline |

The architectural gain is making Gambit's native cooperation deliberate enough
for GC/VM evolution. It does not require a language switch to become meaningful.
