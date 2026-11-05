# Repair And Architectural Redesign

## Two Research Lines, One Evidence Discipline

Current repair asks whether the supported runtime can complete its whole native
inventory correctly and remain stable across repeated use. Experimental asks
which ownership and participation mechanisms should change so that the same
classes of defects become harder to express. These questions share source
evidence and pure definitions, not acceptance credit.

The owner's current **9/12** is retained historical native progress, not an
independent recount here and not proof that the remaining three obligations are
the three research edges. Only the implementation owner's exact-candidate
inventory identifies native gates. Neither research line selects an Agent's
investigation order or forbids revisiting an old hypothesis under changed facts.

Both preserve Gambit's generated-C backend, supported continuations, proper
tail calls and FFI. Compilation to C is not evidence of the cause of these
failures. Neither shared-nothing heaps nor replacing the backend is a premise.

## Current Repair: Robustness Beyond A Single Pass

Use the [current Recipe](current-repair-research.md), the existing
[exit/handoff composition](../models/gambit/retirement_exit_handoff.qnt),
[Lean contracts](../models/gambit/lean/RetirementExitHandoff.lean) and
[stability contract](retirement-repair-test-contract.md). A missing source
correspondence remains current repair work; it does not automatically justify
an architectural refactor.

| Contract to close | Existing support | Evidence still required from the actual repair |
| --- | --- | --- |
| Origin-owned exit | Marker invalidation, C-tail completion and collective admission are separate. | Generated entry, direct host, nested error and supported continuation paths release each actually acquired effect on its live origin, preserving the original outcome. |
| Complete roots and interpretation | `rootSafe`, `generatedMapRelocation` and `descriptorRetirementExcludesConsumers` describe different premises. | Enumerated live roots, generated maps/descriptors, processor/VM ownership and collector-visible successor slots. Retained bytes or a copied C pointer alone do not suffice. |
| Phase-correct work and participation | Private, queued, claimed and recipient-owned work differ; stale census and remote-tail controls exist. | Actual phase/participant closure and last producers/borrowers. Recipient-owned work may remain after donor retirement; a whole-heap drain is not required by this research. |
| OS join, transfer and cleanup | Joined state, retained error, successful transfer and external release are distinct. | Same incarnation and exclusive legal owner; no second join after successful join; no retry of an invalidated foreign release function. |
| Outcome disposition | The model preserves the Scheme outcome and records the foreign release result separately. | Declare whether the real caller reports, retains or intentionally does not propagate each cleanup result. A memory-safe completion is not automatically an error-free cleanup or successful recovery. |
| Repeated stability | The existing campaign imports the retirement protocol rather than replacing it with receipt counters. | Real repeated VM/cohort operations, cancellation, source identity, resource-growth observations and full native/Gerbil inventory under the owner's existing runner semantics. |

These are source/refinement and test obligations, not six new native gates.
The [test contract](retirement-repair-test-contract.md#test-matrix-and-independent-oracles)
already specifies independent native oracles. Reuse its campaign and arbitrary
finite-trace Lean accounting rather than create a duplicate stability framework.

Independent concurrently running VMs, multiple processors sharing one VM, and
supported foreign-host entry are different populations. A pass for one cannot
cover the others. Bind each required population to the owner's effective build
profile and one corrected source/configuration identity, with the affected
generated/header-dependent closure rebuilt. This research does not toggle flags
or require compatibility with the defective old SMP protocol.

### Newly Audited Outcome Boundary

At the pinned Gambit revision, `c_intf.c`:1683-1713 invalidates the foreign
release function and pointer before calling external C and returns a nonzero
cleanup result when supplied. `mem.c`:4387-4453 invokes that function in GC and
still-object cleanup without consuming its return value. The manual
`gambit.txi`:19006-19045 specifies at-most-once release and permits custom C
cleanup. These observations do not establish that ignoring a result violates
the collector's contract or causes the current native failure.

The preserved `run-5qjmzoay/noSuccessfulHandoff` model witness has
`releaseError=9`, `releaseCalls=1`, `releasePhase=4`, `reclaimed=true`, and
`original=delivered=7`. Its successful property is structural handoff with live
recipient work, not zero cleanup error. The cache location is only a historical
receipt locator: the reproducible definitions are `returnRelease`, `reclaim`,
`terminal` and `noSuccessfulHandoff` in the versioned QNT source. That older
current-model check was not rerun or relabeled in this audit.

The existing `checked_cleanup_failure_disposition.qnt` rejects hiding a host
cleanup/join failure. It does **not** establish the caller policy for foreign
object release. The [Scheme facts](../evidence/research/repair-and-redesign/facts.json)
therefore declare `release-error-disposition` as an uncovered interface, not a
new pass, automatic error propagation requirement or demonstrated C bug.

The next source join is now explicit: `_kernel.scm`:3884-3894 consumes the
`___release_foreign` result in `foreign-release!`, returns void for zero and
raises an OS exception for a nonzero result. At that point the release function
and pointer have already been invalidated. Explicit release and GC cleanup
therefore have different baseline result policies; an exception does not make
the release function retryable. This closes the baseline caller distinction,
not the current overlay's correspondence or native failure cause.

The bounded native Recipe is correspondingly split. Through the official FFI,
an explicit-release fixture can supply a documented C release callback returning
an error and counting invocations: observe the Scheme exception, released-object
state and no second callback on a subsequent release. A collector fixture must
instead make the object genuinely unreachable and observe the separate C
counter; keeping the Scheme object rooted to inspect it would invalidate that
test. Do not require collector-context exception propagation merely because the
explicit wrapper raises, or interpose a fake platform error. This research only
specifies these independent oracles; the implementation owner runs them against
its actual supported configuration.

The helper's check/invalidate/call sequence is not evidence that simultaneous
foreign releases of one object have a supported concurrent-call contract.
The wrapper's interrupt declaration does not establish cross-processor exclusion.
Each proposed fixture needs the actual legal object/entry owner; this audit
neither declares a reachable race nor proposes an atomic-field or locking patch.

## Experimental: Change Mechanisms, Not Just Add Guards

The concrete motivation is the source-specific coupling of allocation/work
ownership, collector participation, frame interpretation and C-container
lifetime. A changing runtime needs an explicit account of who can still use
each of them. Neither all global state nor Gambit's C backend is established
as the single root cause. Chez and OCaml are mechanism references, not evidence
that their collector or ABI can be transplanted.

| Architectural question | Pinned reference and useful mechanism | Existing model and missing composition |
| --- | --- | --- |
| Can an owner descriptor outlive its execution context? | Chez `thread.c`:274-335 closes allocation/remembered work, transfers guardians and retains/recycles `thread_gc` because segments still name it. | Existing Experimental root/handler composition distinguishes logical owners. It does not model the entire descriptor graph, generation-safe recycling or bounded retained metadata. A stable carrier must have actual last-consumer and reclamation rules, not permanent leakage. |
| Can blocked/retiring execution stop delaying a collective without losing work? | OCaml `domain.c`:2262-2360 finishes/orphans work, rechecks newly created work, and serializes STW-set removal against incoming requests. | Existing wait/retirement models expose conditional participation and return tails. The Experimental handoff starts after cohort preflight: it does not derive that preflight or implement a Gambit participant-removal handshake. |
| Can synchronization and result owners survive VM teardown? | OCaml `domain.c`:1346-1390,1450-1455 retains `term_sync` through teardown and final unlock, then removes its root. | Existing Experimental QNT/Lean distinguish independent synchronization liveness, payload roots and waiter tails. Gambit's mutex/condvar storage is embedded in C VM state; an independent container/owner protocol would be a genuine mechanism change. |
| Can supported foreign entry/unwind have explicit acquired-effect ownership? | Chez `thread.c`:209-244 and `schlib.c`:217-289 distinguish activation effects and maintain C return chains. | Reuse current nested-frame/root contracts. General host attachment, migration and nonlocal cleanup need an explicitly supported Gambit contract; neither an entry lease nor a TLS pointer grants execution ownership. |

References are the pinned submodules recorded by the current Recipe. Each row
needs its own allocation-failure, cancellation, ordering and reclamation argument.
The existing Experimental model's sequentially consistent actions and finite
returning environment do not prove C weak-memory publication or OS progress.

### Milestones And Promotion Conditions

| Milestone | Deliverable and decision boundary |
| --- | --- |
| Contract selection | Enumerate the concrete source conflict and compare retaining the current container with a lifetime-owned carrier. Record counterevidence, unsupported entry modes and the retained-memory/fast-path tradeoff. |
| Composed mechanism | Extend the relevant existing Experimental machine only after the proposed admission, root publication, GC participation, revalidation and final-use events have source meanings. Combine negative controls with reachable completion and retention. Keep C-ordering premises explicit. |
| Coordinated prototype | A separately owned uniform-revision/configuration implementation with all affected generated/header-dependent objects rebuilt; no compatibility promise to broken old SMP behavior. This research thread does not implement it. |
| Native and cost qualification | Independent source-bound correctness, repeated multi-VM/SMP stability, failure/cancellation cleanup and separately matched single-/multicore cost measurements. No global serialization, disabling SMP or relaxed thresholds is credited as success. |

A useful Experimental condition can inform a current repair without requiring
the whole refactor. Promotion requires an implemented bounded contract, actual
source mapping and native witnesses; moving a model or reusing a finite pass is
not promotion. Conversely, reaching 12/12 does not establish that these
architectural questions have been solved.

### Newly Checked Participant/Publication Projection

The [source-backed projection](experimental/participant-exit-publication.md)
now supplements the existing post-preflight architecture without changing it.
It imports the public retirement machine and separately checks work reopened by
orphaning, request/member snapshot exclusion and shared mutation after membership
exit. It keeps exclusive host ownership and joined direct OS users as premises.
Its five Lean contracts reuse `WorkAccounting`; model/source and native closure
remain different obligations. The exact checked inputs and preserved failures
are recorded in its [validation](../evidence/research/participant-exit-publication/validation.md).

OCaml `domain.c`:1730-1786 is important counterevidence to a universal STW guard:
cleanup after participant removal may overlap a subsequent STW, and callback
return is not a universal barrier before all mutators resume. Chez `gc.c`:
1042,1159,2216-2217 also gives a consumer-side bridge for its retained creator
carrier; `thread.c`:76-108 recycles and resets it. Thus the transferable idea is
source-defined work routing and last-use ownership, not permanent original-thread
authority or an unbounded never-free policy.

The [root-registry continuation](experimental/root-registry-retirement.md)
further binds post-exit exclusion to OCaml's dedicated root-list mutex, its
same-scanner deletion/tombstone rule and narrowly permitted finalizer effects.
Its composition reuses `vm_list_reader_retirement`; root payload updates and
moving-GC visibility remain separate from topology and storage lifetime. Chez's
Scheme/C collector entry also supplies the context-mutex bridge for retained
carrier reuse, while sweeping explicitly forbids ordinary execution TLS lookup.

For the current RC repair, the already existing inspected patch transfers RC
lists and marks each processor's list; a successful-retirement native fixture
already exists. Do not duplicate those implementations or rerun that fixture
from this thread. The current remaining source question is legal concurrent
host/handle access versus forced container cleanup, not whether those two
source changes were ever written. These observations are not new native passes.

The same [source audit](experimental/root-registry-retirement.md#entry-ownership-and-collector-phase-are-separate)
now distinguishes domain entry ownership from process-global exclusion and
the collector's global-root completion handshake. OCaml explicitly permits
cross-domain C execution while both domain locks are held; its root-scanning
phases independently prevent mutator resumption before global roots complete.
The existing Experimental root model adds that phase projection without
claiming a payload barrier or same-slot writer protocol. Actual Gambit RC
callers are mapped separately, including architecture-disabled trampoline
counterevidence. The current Recipe asks whether existing entry/collective
contracts already exclude the supported users before selecting any new lock.

## Evidence And Current Limits

The fact document uses the existing parallel-GC constructor and relations.
It separates current-error disposition from Experimental collective-exit
handshake, binds the new finite checks, retains partial model scopes and has no
`satisfies` or source composition binding. No Python semantic layer, new CLI,
execution plan or
registration protocol is introduced. It is a direct research input to the
existing Scheme component, not a newly registered Session/Clue view.

Its focused regression checks exact input identities, native Scheme inference,
cross-scope binding refusal, reference withdrawal and result reuse. These are
separate from the new Experimental QNT/Lean campaign above and are not a current
native acceptance run. The checked model
receipts retain their original source hashes; changed working models do not
inherit those receipts. Current and Experimental obligations remain open until
their respective witnesses exist.

Local command: `.venv/bin/python -m unittest tests.test_repair_redesign_evidence -v`.
These focused checks qualify only this research data and existing Scheme
inference, not the entire working tree, QNT/Lean source refinements, remote CI
or either native milestone.
