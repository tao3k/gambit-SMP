# Model-first Gerbil numeric investigation

Status: proposed specification, not an executable or verified model. Grok authored the draft; the auditor corrected the state decomposition, uncertainty rules, and validation gates. The original draft and failed write are retained in `.cache/grok-model-first-authored-04.md` and `.cache/grok-model-first-investigation-04.public.jsonl`. No runtime source was changed.

This specification describes a caller-owned finite abstraction. It records obligations before any source edit. It does not admit a Gambit bootstrap, a raised file cap, lower concurrency, a printing guard, native successful-error recovery, or preadmission handler quiescence. The historical aggregate stays 8/12. The independent complete-file observer and this model confer no sealed runtime or release admission. The retained no-admission boundary stands: legacy preflight DENY, original GSC aggregate DENY, and Gerbil stdlib exit 139 remain DENY.

## Object lifetime

The object of interest is the word pair read by `##wr-structure` at `_io.c:86248`: STRUCTURETYPE, then TYPEID, reached from `##wr-pair` at `_io.c:82020`. A diagnostic `_io.o` built with `-g` has the same 1,009,692 text bytes and SHA as the installed original. That identity check is necessary and incomplete. Mapping the faulting instruction to a Scheme constructor, a generation, or a heap epoch is an open obligation, not a proven source cause.

The proposed state is a product, not a single mutually exclusive lifecycle enum:

- `life`: absent / allocated / initialized / retired.
- `published`: boolean; `typeValid`: boolean; `typeIdValid`: boolean.
- `objectEpoch`, `referenceEpoch`: bounded identities, not assumed native addresses.
- `objectRooted`, `typeRooted`: boolean; `gcEpoch`, `referenceGcEpoch`: bounded epochs.
- `path`: ordinary / exception / unknown; `firstErrorObserved`: boolean.
- `mutation`: none / constructor / later-store / storage-reuse; `readAttempted`: boolean.

`allocate` creates private storage; `initialize` installs a valid type and TYPEID;
`publish` exposes the reference; `beginGc` and `relocate` may move the object AND
its type; `refreshRoot` updates rooted references; `laterStore` can invalidate
one field; `retire` and `reuse` change storage lifetime; `readTypeId` records a
consumer read. Each transition must frame every unchanged state component.
Neither relocation nor weak memory behavior is already proved to apply to this
native object: these are candidate mechanisms that require source mapping.

Candidate safety properties are (A) publication requires initialized storage
and valid type/TYPEID, (B) a read requires a live, current reference and valid
type/TYPEID, and (C) a rooted surviving reference is refreshed under the modeled
GC contract. A native implementation may permit private construction across a
safepoint; the abstraction must represent its actual root/initialization rules
before judging that schedule illegal. Native structure/type representation is
an explicit mapping obligation, not a definition chosen to make (A) pass.

Required negative schedules: publish before initialization, miss a root refresh
after relocation, overwrite the type after valid publication, and reuse storage
while an old reference survives. Required positive controls: initialize/publish/
read; rooted object AND type relocation with refresh; retire without a read.
Separate bad construction from overwrite, and stale GC references from reused
storage. A counterexample identifies a missing abstract premise, not the cause
of either retained crash.

Printing is an independent observation. An exception path can contain an object
that is malformed, stale, or overwritten. No hook marker means the prior-error
observation is UNKNOWN; it does not prove an ordinary path or exclude secondary
printing. The hook may not cover the triggering path or run before the crash.
Only a mapped first-error/consumer observation can discriminate these paths.
Do not make a positive model reject a possible native path merely because its
hook marker was absent. Both crash reports and all diagnostic failures remain
negative evidence. No printer guard is a candidate repair.

## Processor recovery, kept open

`lib/setup.c` is identical across the observed-retirement checkpoint and the mutex-return successor. `recover_retired_processors` at setup.c:1106 calls real `___thread_join`. Only success transfers memory, cleans the processor, clears pending, and decrements the count. Child VM cleanup may return an error and leave the processor retained for an exclusive owner retry. Root cleanup is a different contract: setup and cleanup return the same saved error before changing parameters or tearing down retained resources. Native normal mode has shown a real pending join and its successful completion. Detached-live-thread controls show an adversarial ownership fault and a real Darwin join error. A detached thread cannot be reattached, so those controls do not establish successful recovery after an error. Wrapper self-join, expired ids, join interposition, and writes to private pending fields are forbidden substitutes.

`runtime_generation_recovery.qnt` exhausts 15 states. The receipt `generation-recovery-qualified-04` passes characterization and no-false-recovery. `noCross` fails with a four-state witness. Progress is fairness over the finite model, not an OS join or handler-lifetime theorem. A handler outside `vm_registry_enter` is not an admitted reader. Uninstall plus seal/drain does not account for a handler paused before admission. Reopening the same global admission state lets that abstract handler observe the new generation. A counter at the first C instruction cannot count a handler that has not reached it. An immutable token at delivery is not assumed. Host removal in the model is an extra premise, not a runtime patch and not native cross-generation closure. Both native gates stay OPEN: a real error followed by a runtime-owned successful join while the original thread remains joinable and the owner exclusive (no eligible natural error observed); and quiescence of old OS handlers before reopening. A host thread paused before the API is an external-producer control, not evidence of an already delivered handler. The syntax failure, initializer-alias conversion failure, and original model bytes stay retained. Lifecycle fixtures already passed (10.741s) cover root SIGINT, same-storage constructor retry, external producers, normal/pending/sticky joins, and terminal drain. They do not close these two premises.

## Numeric structure

`_num.scm` missed its unchanged 90s cap with no competing C compiler at launch. Scheme-to-C alone finished in 23.371s and wrote 5,541,691 bytes. A later original-command run produced C about 14.909s after launch and had no module before the deadline. One passive sample, about eight seconds into a GCC descendant, was inside the C parser. The file has 8008 labels, one procedure holding 7613. Separate 60s controls that disabled late scheduling, or set the existing single-host label fallback to 4096, both timed out. These quantities are different axes: C bytes, label cardinality, maximum syntactic statement nesting (not yet measured), preprocessing versus parsing, and wall time. One parser sample does not identify the 60/90-second distribution and does not license a complexity inference. No compiler repair, cap increase, or expectation change is admitted. Original GSI after the mutex-void repair is 374/374 COVERAGE-PASS in 19.074s on the same inventory that was 373/374 DENY in 20.201s; that is not a full-mode timing claim. Original GSC remains 373/374 DENY at 1797.7s. The inventory is 374 files, not a 380-file campaign. The successor changed only `lib/_thread.scm` and regenerated `lib/_thread.c`; the 16.614s rebuild of `_thread.o`, the archive, and the GSI/GSC links is not a two-pass bootstrap. `mutex_unlock_plain.scm` failed because the no-waiter helper returned the mutex; both terminating branches now return `##void` after releasing locks. The failed write, malformed hunk, and supervisor exit-code mistake stay retained. Output directories stay immutable; failed campaigns are not resumed or overwritten. Five frozen traces remain `historical_frozen_negative` against predecessor SHAs `f0a453a1ad8e46a2f557169e09ce1732fa4fb319fbcba28396bd121269186bfa` and `9c5a8c76cd136f9cfb49a6e065d874a31f568778efdaef8474cc45e05156d802`.

## Discrimination matrix

| Claim | Would support | Would falsify |
| --- | --- | --- |
| Malformed construction | Header word illegal before any later store or reuse, at the first TYPEID read | Header was legal at construction and changed later |
| Stale root | Root identity survives free, reuse, or generation replacement | Storage and header epoch match the root at the read |
| Overwrite | A store after `WellFormed` replaces STRUCTURETYPE or TYPEID | No store between well-formed publication and the read |
| Secondary printing | An independently captured first error precedes this printer call | Complete mapped path evidence establishes an ordinary call; missing hook output alone is inconclusive |
| Constructor attribution | Allocation/store history connects the bad object to a constructor | PC mapping reaches only a shared consumer; identical text validates PC mapping but does not identify the producer |
| Natural join recovery | Real error, same thread still joinable, exclusive owner, then real `___thread_join` success | Detach, self-join, expired id, interposition, or private-field write |
| Preadmission quiescence | Every old OS handler is accounted for before admission reopens | Seal/drain of admitted readers only, or a thread paused before the API |
| Numeric cause | A repeated split of preprocess, parse, and later GCC phases explains the 90s miss | One eight-second parser sample or a label count alone |

## Ordered QNT and Scheme DSL plan

Do this before any source edit. Keep `runtime_generation_recovery.qnt` and its receipt unchanged.

1. Encode the product state and frame conditions in isolated QNT. Run the safe
   protocol and each deliberately weakened protocol separately. Require explicit
   witnesses for the four negative schedules; reject vacuous positive runs with
   reachable read and relocation coverage checks. Preserve every failing model.
2. Bind each proposed transition to actual source operations and a pinned source
   identity. Mark missing mappings OPEN. GC ordering, visibility and validity
   assumptions must be stated separately; QNT checking does not establish them.
3. Add Scheme evidence associations for current model/control digests. Test that
   changing any required binding revokes support and that predecessor traces
   supply historical negatives only. This is evidence admission, distinct from
   Scheme/native structure allocation or printing execution.
4. For numeric compilation define a structural tuple: generated/preprocessed
   bytes, macro expansion, total labels, largest host/procedure label count,
   maximum statement depth, per-phase elapsed time and sampling coverage. The
   first cheap observation is structural analysis of the retained exact C and
   its header macros. No new numeric compile is justified merely by a timeout.
5. Propose controlled equivalent layouts only after the structural model gives
   a distinguishing prediction: hold semantics and bytes/labels as appropriate,
   vary one structural axis, retain compiler identity and original acceptance
   caps. Check parser structure using C-aware tooling, not brace counts presented
   as syntax depth. A label count is not an asymptotic cost proof; repeated
   samples give coverage, not a universal complexity result.
6. STOP before runtime edits if multiple causes remain observationally
   indistinguishable, source mappings are absent, or a control requires assuming
   the desired outcome. Choose the smallest observation that separates the live
   hypotheses. Diagnostic observations must remain DENY/inconclusive as needed.
7. Once a source-causal explanation survives positive/negative controls, Grok
   authors a bounded source fix; the auditor reviews it. Clone the accepted
   checkpoint, rebuild only affected products, and run the matched failing case
   plus full native/Gerbil build/test. Reuse unchanged Gerbil core products only
   when their dependency identities remain valid; otherwise rebuild affected
   Gerbil stages without repeating Gambit bootstrap.

The Scheme DSL admission work and numeric discriminating experiments have NOT executed. The initial object-model slice below has executed only the stated bounded checks. Existing generation-recovery checks
remain separate, with successful join-error recovery and old unadmitted handler
quiescence OPEN natively. Neither an assumed join success nor a host-quiescent
action supplies that missing native evidence. All four aggregate gates remain
open at their current boundaries; 8/12 is unchanged.

## Executed initial abstraction slice

Grok authored `models/gambit/structure_type_lifetime.qnt`. Eight directed runs
passed initially. An additional seeded safe-protocol simulation found a real
model bug: relocation after a valid read retroactively violated a sticky
`readDone` predicate. The auditor retained the original model and counterexample,
changed read validity to an event snapshot, and added a targeted ninth test.
Typecheck, all nine directed tests, and 100 sampled traces with an eight-step
bound then passed. This is sampled checking, NOT exhaustive verification.

Receipt and the original failing trace are retained under
`evidence/model-results/processor-interrupt-collective-wait/structure-lifetime-audit-01/`.
The receipt records the exact model digest and commands. The correction and
remaining source-mapping boundary were sent back to Grok; no substantive final
review from that feedback call is counted as evidence.

This slice still combines object/type relocation and refresh. It does not yet
separate missing object roots from missing type roots, represent native GC
barriers or weak memory, cover all safe initializers by exhaustive checking,
or establish a native producer identity. These are declared modeling gaps,
not silently assumed guarantees. The unknown-path test keeps absence of a
marker inconclusive. Native source causality, Scheme evidence admission, and
all four remaining aggregate gates stay OPEN. No runtime edit, bootstrap,
new Gerbil build, or repeat of the unchanged numerical timeout occurred.
