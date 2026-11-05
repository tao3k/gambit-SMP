# Synchronization and Shutdown Support: Modern C and Zig

Reviewed: 2026-10-20. Design-only maintenance economics; no LOC estimate,
implementation, native test, timing, checked proof or positive bound is claimed.
The [protocol](device-release-sync-proof.md) and [evidence](device-release-sync-evidence.md)
add necessary obligations to the [previous support comparison](device-release-wait-cost-matrix.md).
This is the same complete modernization capability in C-full and Z-full.
C-ZT retains a modern C runtime with independently useful Zig tooling; adopting
the toolchain is not evidence that runtime implementation must also move to Zig.

The [RC custody support refinement](rc-payload-custody-cost-matrix.md) expands
actual nested payload, rooted-header, still-cursor and owner-dependency costs.
These refine WSM06--09 and their reuse boundaries; do not count the same
custody/ledger support again as an additional benefit.

## Matched Maintenance Matrix

Credit existing Scheme emission, C helper/failure funnels, pthread/native OS
primitives, source-derived ownership fixes and mature libraries first. Neither
candidate needs a new generic lock-free library, distributed termination detector,
persistent journal or signal bridge solely to support this selected cohort.
Rows identify obligations, not measured effort or separate duplicate libraries.

| ID / necessary support | Modern C-full / C-ZT construction and change work | Z-full construction and change work | Shared reuse and possible actual retirement | Zig-only incremental claim / countercondition |
| --- | --- | --- | --- | --- |
| WSM01 serial predicate + wake ordering | Mutex, durable reason/queue state, drain/check/wait discipline and exhaustive failure handling; generated state checks possible. | Same lock, predicate and protocol; Zig enums can help express state but do not prove ordering. | Reuse native mutex/pipe/select primitives and leaf interests. Retire implicit PSTATE scratch only for migrated runner. | No mechanism eliminates synchronization review. If C helpers/generation already express the state, syntax savings can be negligible. |
| WSM02 notification debt + endpoint leases | Count/identify pending notifiers, partial setup, EINTR/EAGAIN/fatal statuses, SIGPIPE profile and close/join ordering. | Same debts, leases, OS errors and lifetime law; allocator/defer affects private setup only. | Credit candidate ready/drain cleanup and existing failure funnels [SY-S10]. | Ignored legacy write must change in either language for this guarantee. Zig does not supply reliable wake or an independent failure detector. |
| WSM03 attempt/resource commit | Preallocated AttemptRecord, ResourceControl and atomic transition table; one issuer/claim lock. | Tagged unions may simplify state-specific access, but shared mutation and alias exclusivity remain manual. | Existing native allocations/control helpers can remain; replace conflicting release authorities. | No automatic linearizability or unique ownership. Added C/Zig ABI and invalid-alias support can exceed local checking reduction. |
| WSM04 observer/delivery cut | Attached/Ready/Claimed/Detached table, result pins, root/reentry handshake and cancellation semantics. | Same table and Gambit handshake; lexical scope does not model callback lifetime after return. | Keep admitted Scheme scheduler/managed root authority; retire only migrated direct observer paths. | Managed control and longjmp islands remain. Do not count all cleanup labels as independent C cost. |
| WSM05 staged native release | Explicit RD/WR/EAGAIN stage runner, partial-effect outcome and no-blind-replay rules. | Same leaf contracts and stage machine; error union may improve local propagation. | Reuse admitted close/select/release leaves; retire opaque device_cleanup as migrated authority. | Most semantic work is common. A destructor error and native storage disposition still require separate representation. |
| WSM06 root/discovery permits | Registration-origin census, close issuance, issued permit drain, final-GC and free_still_objs boundaries. | Same permits/census/ordering; no-GC implementation does not erase Gambit's GC producer. | Replace final-GC-only stop assumptions, never current synchronous work without routing its real users. | No Zig-specific reduction in finding omitted producers. A missing teardown producer breaks both. |
| WSM07 descendant/reservation ledger | Intrusive identity states or checked counters; reserve child before construction/parent completion; rollback remains counted. | Same ledger; allocator/error cleanup can help local builder but cannot issue/release shared credits implicitly. | Reuse local queue/record facilities; no distributed cornet subsystem is required. | Finite-work/overflow and cross-thread review are common. Generated C transition checks are a matched alternative. |
| WSM08 RC payload survivor custody | Either drain before cleanup_rc or change native storage/list/borrow ownership; joined-donor support has constrained preconditions. | Same choice and actual data transfer; Zig allocator cannot rescue RC memory freed by old C cleanup. | Credit existing donor transfer rather than price it as entirely absent C support. Retire unsafe old ownership only after raw users migrate. | Newly identified mandatory cost for both; cross-language allocator/list representation may add Z cost. |
| WSM09 outcome/retainer + shutdown | Separate service work, pending delivery, actual payload/library users, stop/join and endpoint cleanup. | Same dependency graph; explicit unknown state is useful but not self-draining. | Reuse OS/library close leaves when admitted; old group error/free body cannot remain drain authority. | RetainedUnknown is not a free successful path in either language. Required survivor domain has real support cost. |
| WSM10 private builder rollback | Existing C single-exit cleanup funnel/initialized fields or generated cleanup table, including partial pipe creation. | defer/errdefer can bind ordinary rollback to lexical success/error exits [SY-P06]. | One shared builder per service; not one new copy per registration expression. | Candidate saving only for unavoidable remaining private cleanup edits. No saving for accepted asynchronous custody, longjmp or independently reused C funnel. |
| WSM11 diagnostics + evolution | Stable IDs, reason/status/credit audit, source bindings, ABI/layout/error changes, exhaustion behavior. | Same evidence/diagnostics plus Zig compiler/std support and language/ABI upgrades. | Shared generated contracts can serve C and Zig; checks remain necessary after either language's changes. | Compiler-enforced cases can reduce omissions, but generator and tool qualification cost must be counted symmetrically. |

The matrix does not reduce the Experimental scope to a minimum patch. It names
the support needed by a complete reconstruction and prevents a new language
wrapper from hiding an unchanged release authority beneath it. Exact path
retirement still needs the [caller inventory](device-release-wait-contract.md)
and complete raw alias/user census; zero paths have been retired by this study.

## Change-Event Review Matrix

| ID / realistic maintenance event | Work that both candidates must perform | C versus Zig marginal opportunity / disproof |
| --- | --- | --- |
| WSE01 add a new wake reason or switch backend | Extend P/notification/debt/status/interest construction, prove drain-before-check and endpoint law, review signal/time/fd profile. | C generated table or Zig exhaustive switch can catch omissions. Neither proves wake progress; unsupported backend assumptions refute reuse. |
| WSE02 add a release origin or raw device user | Extend ResourceControl integration, registration permits, managed aliases and error/disposition semantics. | Main work is semantic/source census. A wrapper-only Zig change with old raw release authority fails the architecture gate. |
| WSE03 introduce a child cleanup task | Reserve child credit/pins before publication, failure rollback, parent completion, bounded admission and shutdown ancestry. | Lexical rollback can shorten private construction; it cannot free accepted/retained work on parent scope exit. |
| WSE04 move pstate/VM teardown earlier | Re-evaluate free_still_objs issuance, cleanup_rc custody, pending managed results and code/library lifetime. | Current joined-donor C support is reusable only with its real prerequisites. A new Zig allocator alone offers no transfer proof. |
| WSE05 tighten cancellation semantics | Distinguish preaccept abort, observer detach, cooperative stage stop and already claimed managed delivery; update caller-visible response law. | Tagged unions may help local representation. All-exit/root/foreign ABI review and possible handshake cost remain. |
| WSE06 upgrade compiler/OS/LLVM provider | Recheck endpoint/mutex profile, ABI/allocator boundary, provider callback/effect/domain and payload/code drain, while preserving common contract. | LLVM modularity is common benefit of the reconstructed boundary; Zig compiler/std/provider upgrade work is an additional explicit cost. |

## Conditional Net Benefit and Quantification

Let K be the necessary **post-reuse** support work in WSM01--11 and future
change events E in WSE01--06 over a declared maintenance horizon. Count one
shared helper once; do not sum a support row and the same change as two independent
benefits. For language L, define:

`Cost(L) = BuildSupport(L,K) + ReviewRefinement(L,K) + Migrate(L) + ToolABI(L)
         + Sum(Change(L,e), e in E) + ResidualRisk(L)`.

`ZigIncrement = Cost(C-full) - Cost(Z-full)` for matched capabilities and the
same treatment of uncertainty. Common modernization benefit is evaluated
separately against the actual baseline. C-ZT can capture independently useful
Zig build/tooling gains without the runtime migration term; do not count those
gains twice or assign them only to Z-full.

| ID | Positive condition to establish | Refutation / current status |
| --- | --- | --- |
| WSN01 local support saving | Bound unavoidable C private rollback/state-maintenance work remaining after shared helpers/generation; bound the corresponding Zig work lower. | If reused C funnel/generated table covers it, remaining difference can be zero. No positive lower bound established. |
| WSN02 amortization | A concrete set of necessary components share the same admitted identity/lease/attempt/ledger service without semantics-specific copies. | Ten registration expressions sharing one helper are not ten independent savings. Managed/async-signal/foreign profiles can require different adapters; their cost cannot vanish. |
| WSN03 whole incremental cost | Conservative lower bound on C-minus-Z support/change effort exceeds upper bound on added Zig migration, ABI, toolchain and residual work. | No such numeric/ordinal bounded comparison is available. New payload-custody/teardown/notification obligations enlarge common K and possible Z-specific ABI costs. |
| WSN04 runtime resource burden | Declare expected publication/notification/lease/child/retained-work counts and bounds for each profile. | No-GC syntax does not remove locks, wake syscalls, task allocations, native payload lifetime or library work. No speedup is inferred. |
| WSN05 nonpositive countermodel | If unavoidable K has no strictly cheaper Zig work and added Zig integration/upgrade cost is positive, ZigIncrement < 0. | This is a valid theoretical countercondition, not measured evidence that every Z-full design loses. The present evidence cannot exclude it. |

A future theoretical budget must name the following denominators before any
empirical validation is considered; this turn does not authorize that validation.

| Budget item | Symbolic accounting boundary | What it can and cannot mean |
| --- | --- | --- |
| Reason publication | n reason commits, n installed notification intents in the selected conservative protocol | One intent per commit; scheduling/OS retry counts are not necessarily n. A coalescing optimization needs its own proof and cost. |
| Wake I/O | Successful writes + qualified coalesces + EINTR retries + fatal unresolved attempts | At least a disposition per intent; no fixed syscall-latency or platform speed bound. |
| Synchronization | Publish/check/claim/move/settle operations under L | Count contention and writer progress as open costs, not a zero-cost replacement of old PSTATE access. |
| Resident support | I producer permits + J task/reservation states + N notification debts + D physical dependencies | Identity records can share storage; do not simply add sets that represent overlapping lifetime aspects as unique allocations. Bound peak live records separately. |
| Shutdown | Outstanding children, undiscovered teardown producers, pending observers and retained dependencies | Empty queue is insufficient. A finite numerical upper bound needs finite-work/peer-progress premises. |
| Maintenance | Shared support creation plus actual E changes over one horizon | Review obligations and trace rows are not person-days, LOC, runtime events or net-benefit witnesses. |

The theoretical gate is still open: the architecture now excludes more unsound
shortcuts, but no positive total or Zig-only cost bound follows from that fact.
All full-runtime/provider/retirement/total/increment requirements remain unresolved.
