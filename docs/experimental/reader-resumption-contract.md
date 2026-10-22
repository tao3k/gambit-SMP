# Reader Resumption: Snapshot Lifetime And Reference Transfer

## Research Boundary

This closes a modeling omission identified in the existing
[wait/root/exit audit](metadata-wait-roots-exits.md), not an implementation defect
reproduced in a native program. That audit already requires Scheme-owned capture
before callbacks and permits effects repeated by explicit continuation use.
The old capture projection explicitly excludes continuation reinvocation. This
follow-up models that boundary inside the existing `gc_table_iteration.qnt` and
adds conditional results to the existing Lean module. No runtime source, Python
inference, native fixture, build or native milestone is changed.

The [Stage-One Recipe](stage-one-handoff-recipe.md) remains the handoff. This
document supplies its capture/callback/exit join, rather than another workflow.
One repaired revision/configuration and full regeneration/rebuild remain required
for any future implementation. Preserve Gambit's C backend, proper tail calls,
supported continuations and nested FFI, not defective-old-SMP or mixed binaries.

## Pinned Source Correspondence

Reference revisions remain Chez `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`,
OCaml `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`, and Gambit vendor baseline
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Runtime source applicability still
requires the implementation owner's then-current locked overlay; these are not
receipts for that newer candidate.

| Source | Actual mechanism | Transfer condition / limit |
| --- | --- | --- |
| Chez `s/prims.ss:587-603` | `call/1cc` and `call/cc` are separate entry points. | Do not silently narrow a general Scheme continuation into a one-shot handle. A shared name such as continuation is not semantic equivalence. |
| Chez `s/cpnanopass.ss:5014-5065` | `nuate-help` distinguishes multi-shot from an already-used one-shot continuation and has a multi-shot stack restoration/copy path. | Learn the ownership distinction and retained activation contract, not the native-code generator or stack representation. This is not a proof of all Chez continuation/FFI/GC interactions. |
| OCaml `runtime/fiber.c:641-675` | Continuation use marks/darkens when required, takes the stack field by clearing it, and reports an already-resumed continuation when no stack remains. | Taking ownership once is appropriate to this effect-continuation operation. It does not justify rejecting a second supported Gambit Scheme continuation invocation. |
| Gambit `doc/gambit.txi:19935-19992` | Nested C/Scheme calls are supported within stated C-stack lifetime and threading restrictions; Scheme continuation and C stack are separate. | A Scheme-owned enumeration suffix may be resumed without retaining a metadata guard. This does not authorize returning into an expired C activation or arbitrary foreign-thread migration. Keep existing origin/marker/unwind obligations. |
| Gambit baseline `lib/_kernel.scm:3616-3727` | Continuation copying/traversal belongs to the runtime representation, not a user C buffer or mutex lifetime. | Actual generated roots/maps and supported control paths must retain the snapshot. A local C pointer or a lifetime lease alone is not that proof. |
| Existing `gc_table_iteration.qnt` capture projection | Preparation, capacity/root reload, protected copy and unlocked normal/error delivery are finite checks. It frees its abstract buffer at terminal delivery and explicitly excludes re-entry. | Do not reinterpret that terminal cleanup as the lifetime of a Scheme object retained by another reachable continuation. The new projection addresses the omitted join; it does not prove the collector. |
| Existing `nested_foreign_unwind.qnt` | Cleanup is attributed to the correct origin and frame; markers, retirement and errors remain separate. | Exactly-once native resource cleanup does not imply exactly-once user callback effects across explicit continuation invocation. No new FFI migration/return permission follows. |

## Added Projection And What It Checks

The resumption projection assumes a typed membership snapshot `{0,1}` has been
captured under protection. It releases protection before Scheme delivery and
retains a continuation inside the first callback. The origin either returns
normally or raises before the second callback. Afterward, a collection and a
source membership insertion may occur; the retained continuation is explicitly
invoked twice and then discarded.

Those bounds discriminate lifetime and replay errors; they are not a limit on
real continuation invocations, CPU count or legal agent reasoning. The model
abstracts collector enumeration as `traced`; it does not derive actual root maps.

The negative controls distinguish four incorrect transfers:

1. **Free on origin return:** releasing a manually owned C snapshot on first
   return leaves a live continuation able to refer to reclaimed storage.
2. **Retained but untraced:** keeping raw bytes/pointers is insufficient when
   a collection cannot discover the retained snapshot through its true owner.
3. **Consume on first use:** importing one-shot stack ownership rejects a later
   invocation allowed by the modeled Scheme-only continuation contract.
4. **Reacquire current membership:** resumption must continue the saved capture
   and cursor, not silently substitute a newly enlarged table.

A fifth negative query asks whether user effects are globally exactly once.
Its violation under the correct protocol is a **legal replay witness**, not a
bug or a failed repair. The positive safety property accounts for each explicit
resumption, preserves saved membership, checks storage availability and requires
no metadata guard during Scheme delivery. Weak-fair completion is conditional
on the finite modeled callback/collector actions completing; it is not a native
latency or termination guarantee for arbitrary user code.

Lean's `replayedSuffixMembership` establishes that elements delivered from the
saved suffix belong to the saved membership. `explicitReplayMayRepeat` proves
that repeating a nonempty effect sequence can exceed its single-traversal count.
They are parameterized logical results, not generated-code or GC refinement.
The existing binding/root correspondence theorem can express the separate
reachability bridge; it does not establish the bridge's source premises.

## Implementation Owner's Acceptance Recipe

The native owner needs one source-bound regression specification with independent
oracles for the following outcomes. These are acceptance obligations, not a new
executable interface or instructions fixing an agent's investigation order.

- Capture a known finite interned membership and retain a Scheme continuation
  during a fold callback. Let the original traversal return; insert fresh names
  and force collection before invoking the retained continuation twice through
  a valid Scheme control boundary. Verify each resumed suffix belongs to the
  saved membership and does not add fresh names from the current table.
- Record callback effects per explicit traversal/resumption. A repeated suffix
  is expected; loss, corruption or an artificial one-shot rejection is not.
  A global exactly-once assertion would itself be a wrong oracle.
- Cover normal return, a caught callback error/nonlocal escape and retention
  after the original dynamic extent ends. Check original error/value behavior,
  snapshot liveness/relocation and eventual reclamation only after all relevant
  Scheme references are gone. Retention while a continuation is reachable is
  required liveness, not automatically a memory leak.
- Establish P/M release before any callback, collection or continuation escape;
  distinguish Scheme object reachability from native guard/C-buffer ownership.
  Preserve valid nested FFI using the existing origin/marker rules. Do not use
  expired C frames, unsupported migration or arbitrary teardown reentry as a
  supposed passing fixture.
- Bind the actual generated frame maps, relocated inputs and return state to
  the repaired compiler/runtime/header identity. Run on the completely rebuilt
  candidate, not an old bootstrap artifact or the unadopted cache prototype.
  Reuse unchanged applicable checkpoints only through the existing contracts.

The cost hypothesis is retaining a shared Scheme membership capture through
ordinary reachability, not copying an entire environment on every resumption or
adding a mutex to each value access. This can retain memory longer when users
retain continuations. Actual allocation, retention, GC delay and sequential/
parallel costs need measurement; no gain is predicted from model state counts.

## Stage-One Gap Ledger

| Join | Research/model contribution | Still required from implementation/native evidence |
| --- | --- | --- |
| Entry -> waiting -> collective progress | Existing leaf/parked wait and service-envelope projections; actual Chez/OCaml acquisition/hook distinctions. | Whole enabled-caller census and true owner completion/GC participation, including callbacks and platform effects. |
| Reservation/topology -> binding -> VM roots | Existing reservation/order profiles and imported binding/constructor composition. | Actual C visibility, all discovery readers, same-name/many-writer identity and initialized live-VM slots. |
| Capture -> callback -> retained resumption | Existing capture/root projection plus this bounded multi-shot ownership/suffix projection. | True generated roots, collector enumeration, supported error/control exits, reclamation and callback semantic oracles. |
| Partial init -> retirement -> generation | Existing private-prefix, nested-unwind and linker-generation obligations. | Match the native owner's current lifecycle repair; full startup/drain/rollback and generation joins are not proved here. |
| Unified source -> artifacts -> acceptance | Existing lock/profile/Session/checkpoint contracts and coordinated milestone. | Complete regeneration/rebuild, original bootstrap/stresses/GSI/GSC/Gerbil/FFI correctness and preserved performance gates. |

The research makes the outstanding conditions explicit; it does not claim that
every cross-product is now formally composed or the native milestone is closed.
Concurrent reclamation, a new root-frame ABI, arbitrary raw-table concurrency,
general foreign attachment and runtime restart remain separate Experimental
decisions when genuinely new capabilities are proposed. A required existing
behavior cannot be deferred merely to obtain a green result.
