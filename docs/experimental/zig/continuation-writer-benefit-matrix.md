# Captured Graph Scan Elision: Net Runtime Benefit

Design-only work model. No measurements, implementation or native tests.
Source evidence establishes necessary writer/root families and mechanisms;
their occurrence counts do not establish execution frequencies or speedup.
Human implementation days are not used as a value criterion.

CV01. The opportunity is a retained mature map continuation graph with complete
young-boundary coverage. An unchanged k can still share mutable denv binding
pairs or frames with other users. The question is whether the runtime can cover
those writes and roots more cheaply than repeatedly traversing the graph.
The [edge-cut proof](continuation-minor-scan-proof.md) makes that a conditional
soundness result; the [caller matrix](continuation-writer-caller-matrix.md)
identifies real support and remaining open domains. [CW01–CW13]

## Benefit and Added Work Matrix

| Scope | Work potentially removed | Work added or retained | Positive condition / decisive negative case |
| --- | --- | --- | --- |
| Mature saved frames and denv graph | Recursive minor visits to unchanged mature descendants | Young-source remembering across every alias, new-frame processing and root classification | Large stable retained graph across many cuts; an uncovered binding-pair or frame write rejects elision |
| Frame / continuation mutation | Avoid full rescans when only a few slots change | Typed slot/control validation, access coordination, dirty storage/leases and current-major protection | Sparse modifications; heavy structural edits or fallback rescans can consume the saving |
| Dynamic parameter lookup | Keep mature graph traversal out of minor fast path | Cache2/cache3/lookup-hit paths still write caches; first-cache hits do not | Charge path-dependent cache write rates, not “read-only denv” or a write on every lookup |
| Parameter assignment and environment tree | Preserve persistent-node sharing rather than clone the denv graph | Pair cdr/default-descriptor updates; active non-SMP tree mutation; private construction publication | Writer discipline follows feature branch; do not price commented SMP env-insert! as executed work |
| Reconstruction | A completed mature reconstructed graph can later skip whole traversal | Allocation/root save, safe initial fill, per-slot initialization/publication, code/map binding and any real deferred callbacks | Fully classified constructor/fill/caller; a mature allocation with raw young field writes invalidates the claim |
| Scheduler / replay | Mature saved graph remains reusable while active roots are scanned separately | Transfer source/destination roots, clear/store barriers, denv/cache changes, active-frame scans and restore copies | No elimination of mandatory active root scans or multi-shot restoration |
| Native roots enumerated each minor | Mature pointee traversal can be skipped with global interior-writer coverage | Stable native root-cell visits, owner/epoch synchronization, marker/RC lifetime | Fewer graph visits even without root-cell elision; raw unregistered native values remain unsupported |
| Cooperatively classified native roots | Skip unchanged mature root cells in addition to graph traversal | Every native root write reclassifies/re-enrolls, plus registration/withdrawal ordering | Root changes rarer than minor cuts; one direct untracked write invalidates the subset |
| Unknown foreign writer | No safe saving assumed | Sufficient bounded fallback scan or profile rejection; unresolved root/borrow/access gaps | Scanning k's graph alone is insufficient for arbitrary external managed writes |
| Repeated mature copying | Nonmoving mature representation avoids later copying of retained payload | First promotion, major tracing/sweep, fragmentation and publication work | Separate from scan elision; do not count the same byte/slot work twice |

CV02. The selected C implementation already contains root save/init work,
lazy capture, per-processor structures, generic mutation support and retained
patch repairs. Credit these assets. New generated C must replace hidden raw
writers with declared operations and native policies, rather than add a second
semantic analysis. Neither generated types nor local cleanup implements root
closure, phase termination or alias preservation. [WE01–WE14]

## Quantitative Conditions

CV03. Fix a declared history and collection-cut comparison. Let F_j count
mature saved-graph slot visits in the full-traversal control at cut j; D_j the
candidate's dirty-source/slot visits, and N_j extra new/materializing graph
visits attributed to that comparison. Active/restored stack root visits and
ordinary native root-cell visits remain separate. A local traversal opportunity
is `sum_j(F_j-D_j-N_j)`; extra dirty sources outside k's graph and their global
tracking costs must still be charged. Matching cut definitions does not assert
that the current and candidate runtimes trigger GC identically.

CV04. A simple break-even form exposes the regime without invented values.
For a declared approximately stationary interval of K comparable cuts, let F
be full mature-graph visits per cut, d the candidate's visits, lambda the
time per avoided visit under a bounded cost model, a other incremental time
per cut, and rho_t/c_t the average count and incremental time of writer family
t per cut. Let A0 be incremental one-time stabilization/construction cost.

`K * [lambda*(F-d) - a - sum_t(rho_t*c_t)] > A0`.

If the bracket is positive, the break-even cut count is
`K > A0 / [lambda*(F-d) - a - sum_t(rho_t*c_t)]`.
If it is zero or negative, merely retaining k for more cuts cannot establish
gain in this model. If rates or costs vary, use the event sum and qualified
interval bounds instead; no constant-rate assumption is imposed on real map.
Root/capture/reconstruction/FFI work must be allocated once between A0, d, a
and writer terms. Major phase/space-pressure effects cannot silently disappear
from a when they are incremental costs. [CV01–CV03]

CV05. Root-cell elision is a distinct possible benefit. With time-weighted
cell visits saved V and root reclassification/epoch overhead U, it contributes
only `V-U`. Do not count the mature descendant graph again in V: the ordinary
minor algorithm already skips it under interior-writer coverage. OCaml's
generational-root API documents exactly the need for cooperative updates before
less frequent root scanning; the analogous Gambit policy still needs its own
owner/marker/RC and callback proof. [WP01; CW08–CW10]

CV06. For copying, retain the preceding study's identity-based ledger:
`sum_i b_i*(k_i-p_i)`, where b_i is declared payload bytes and k_i/p_i are
baseline/candidate copy counts excluding execution restoration unless both
ledgers include it. Early promotion with k_i=0 is a negative contribution.
Converting this already-net byte difference to a time term must not charge
the same promotion twice. Saved copy time and saved field-classification time
also need nonoverlapping definitions. [RD01]

CV07. Space and progress require their own limits: remembered-source leases,
native roots, fixup closures, snapshots and code references can retain objects
longer; logs and access coordination consume memory/cache traffic. Queue
exhaustion, long native borrowing and scan/commit lock dependencies affect
pauses and throughput. A positive local scan budget does not establish a
shorter pause distribution, lower peak memory or positive whole-program result.

## Learning and Gambit-Specific Choice

CV08. Learn three things from the primary research and source. First, less
frequent root scanning is purchased with a restricted update protocol, not
root age alone. Second, old-referent protection, young remembering and stack
activation scanning solve different problems. Third, the early concurrent
Caml collector relied on compile-time mutability/identity assumptions. Gambit's
generic mutation and shared multi-shot control require their own argument;
the historical duplication/private-heap assumptions do not transfer wholesale.
[WP01–WP07]

The current candidate therefore retains shared identities and explicit roots,
uses coordinated young evacuation and admits mutation through typed policies.
It may keep enumerated native roots where write cooperation is unavailable,
while rejecting unprotected borrows/unknown managed writers. Alternative
collector or root policies remain legitimate research directions if their
preconditions and costs are made explicit. No human-day or borrowed benchmark
score selects this architecture.

CV09. Current conclusion: the mechanism can remove repeated traversal for a
qualified stable mature graph. The source has concrete compiler/runtime and
native paths that must be migrated, including cache writes and scheduler root
handoffs. Full writer/extension/FFI, serialization/control-domain, weak,
memory-order/progress and workload-specific positive-net admission remain
unresolved. The design has not retired any path or qualified a native profile.
