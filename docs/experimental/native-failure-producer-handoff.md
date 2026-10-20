# Native Failure Producer Handoff

## Scope And Authority

Research snapshot: 2026-10-20. This note transfers four discriminating contracts
to the native/Grok owner. It changes no runtime, acceptance framework, source
lock, Grok launcher, native checkpoint or numerical completion count. No native
build, bootstrap, debugger, stress test or model campaign was run for this note;
raw LLDB memory/register logs were not read. Grok owns experiment selection and
implementation. These are evidence conditions and alternatives, not an agent
workflow or a restriction on new hypotheses.

Preserve Gambit's generated C, proper tail calls, supported continuations/FFI,
VM-local values and resolved-access fast paths. Use one repaired revision and
effective configuration with correctly rebuilt affected artifacts; do not mix
object identities or silently adopt a different compiler profile. Reuse the
native owner's applicable checkpoint rather than repeating bootstrap here.

Reproducible reference sources are the existing submodules: Gambit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, Chez
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Source locations below are these
baselines, **not** source/ABI certification of the native owner's newer overlay.
The existing [root contract](root-map-lifetime-contract.md),
[handoff Recipe](stage-one-handoff-recipe.md) and
[compatibility boundary](c-backend-compatibility.md) remain in force.

The separately checked [retirement handoff composition](retirement-handoff-model.md)
lives in `models/experimental/`: its proposed root/handler obligations are not
current native guarantees. Its explicit campaign is separate from this note's
source audit and does not change the native owner's milestone or checkpoint.

### Observation Identity, Not Cache Authority

These are inspected summaries/receipts. Cache locations identify historical
observations, not reproducible source inputs or permission to reuse binaries.
Do not copy their personal absolute paths into Git. Local native-owner models
listed below were not in published research HEAD `74a9c04`; their names and
hashes describe inspected snapshots, not a claim that this PR publishes them.

| Inspected observation | SHA-256 |
| --- | --- |
| `.cache/grok-gerbil-freeze-20261020/report.md` | `bcca7c5541ba6548316aa91311f6464cfee7f5abad1905c25808706b3ebbcbeb` |
| `.cache/gerbil-relink-auditor-smoke-02/receipt.json` | `ef83b6116b35920cc797f86525d5e053bd73043650f47abb97eec612f36d7208` |
| `.cache/numeric-ealias-direct-auditor-04/receipt.json` | `794e6d2b52f6a5e01cbc93a19e3dfc71a0a87f1c2d86c97ead54b78f6b0bec4f` |
| Its `phase-index.json` | `7bc8edf90fe278de1a8c4d73293f307423b8285599c7979f0d703aea8a952d10` |
| `.cache/grok-root-handler-quiescence-20261020/report.md` | `6e08b17bde8af1c19e14a8838162bd3ae86b7ee4d1aa062843bf41e1cebf3f7b` |
| `.cache/grok-runtime-cancel-20261020/EARLY-REPORT.md` | `48f85fb5938a821c1fb65d4e6d7eb05be0e180d08fd162f398bf176a04fc233d` |
| Owner-local `structure-lifetime-source-map.json` under `evidence/research/processor-interrupt-collective-wait/` | `7c2d7f810c8efa5e8657e7a9a7d3048d0cb678043ddbed86f73ba24d46401533` |

The supplied root-signal source lock pins `setup.c` to `bc6867d...`, while the
inspected mutable candidate file hashes to
`9b86f40c780b68e0a285ee50f3391676c6b4f6a9351ba6d73a32af293b8ac34a`.
Its `os_thread.c` and `os_setup.c` still match that lock. Do not silently attach
the whole candidate to this older lock. Follow-up correction: the existing
`runtime-mutex-return-source.lock.json` has SHA
`df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466`
and binds that newer `setup.c`; all 26 candidate files independently matched
its recorded candidate hashes. This is a different, identified producer, not
unowned drift. Matching these inputs does not by itself bind an executable or
prove which producer a native checkpoint used. This note does not reseal it or
invalidate unrelated historical stages. The structure source map also names cache files:
its source correspondences are partial observations until the owner binds the
actual source recipe, generated C, compiler/header configuration and executable.

## Structure Type Consumption And Producer Attribution

| Layer | Established boundary |
| --- | --- |
| Source fact | Gambit [`_io.scm`](../../vendor/gambit/lib/_io.scm):11889-12090 traverses type/name/field metadata while printing structures. This is a shared consumer, not an allocation-site identity. The owner's mapped collector copy tail-marks field zero before the remainder scan; skipping that field in the remainder is not itself a missing-root defect. |
| Model | Owner-local `structure_type_lifetime.qnt`, SHA `9c34ba8de2c08dc4cf43821895915d6c0b1ddc4b80061099d5805f960a69b6e6`, separates publication, overwrite/reuse, object/type epochs, refresh and unknown exception path. Its independent roots are controls, not a requirement for two native roots: a traced object can supply its type edge. `safeRead` guards on the desired read predicate, so its positive projection is conditional, not proof that generated code establishes it. |
| Assumption | A matched object instance, legal storage/shape, descriptor edge, actual producer and coherent read event must be identified. Correct tag bits, a nonzero pointer or matching ABI do not establish all these facts. |
| Native unproved | Three images passed a six-processor/six-worker small GC control, but not stdlib equivalence. The frozen stdlib launch naturally SIGBUSed at 96.6 s, without READY or object scene. The `0`/`0x2046` gate did not publish. Neither descriptor contents, ordinary/error path nor a GC cause follows. |

Chez's generated continuation tracing (`s/mkgc.ss`:245-270,970-991) and Gambit's
own [slot/RA/scanner chain](root-map-lifetime-contract.md#concrete-map-producer-and-scanner)
make **the actual graph edge and its interpretation** the useful transfer unit.
Do not infer a missing standalone type root when object tracing already owns
that edge. OCaml [`printexc.ml`](../../vendor/ocaml/stdlib/printexc.ml):342-375
captures the original backtrace before cleanup/printing, distinguishes a failing
uncaught-exception handler and contains a fallback. This does not make printing
arbitrary corrupt objects safe; it motivates separating primary failure from
secondary formatter failure without formatting the suspect object again.

### Minimal Independent Projection And Falsifiable Options

Reuse the existing structure model; add an observation/provenance projection
only when its owner has the corresponding source events. It needs object
incarnation, producer label/storage class, initialization/publication events,
descriptor-edge version, observed relocation/refresh, first-error event and
consumer event. Keep `unknown` for missing events. A legal-read invariant alone
cannot derive the last writer or choose between construction, overwrite,
stale alias, fixup, reuse and collector publication.

| Competing explanation | Discriminating observation | What does not decide it |
| --- | --- | --- |
| Bad construction/early publication | A source-mapped producer exposes a specific instance before its required type fields are initialized. | The final TYPEID fault or a type-shaped immediate. |
| Valid instance later overwritten/reused | A coherent initialized instance and a subsequent source-mapped write/reuse precede the consumer. | Repeated address equality without incarnation/relocation correspondence. |
| Stale object or type alias | Actual relocation and owner/reload history connects the stale reference to that consumer. | An abstract independent-root counterexample. |
| Printer is the second failure | An independently retained first-error boundary precedes the printer, with the suspect instance's relationship recorded. | An absent hook marker or simply removing the printer. |

The narrow observation option is a producer/read boundary record, not another
literal-value-only gate. Record primitive event/producer metadata without
calling a Scheme object printer, serial-number allocator or generic callback.
An address is not a root or stable identity across GC/reuse. If a Scheme value
must survive observation, its existing traced owner and observer effect must
be explicit; adding a strong diagnostic root can mask the lifetime defect.
Publish a complete snapshot before acknowledging it. Do not claim all mutators
are stopped or dereference a potentially invalid descriptor merely to validate
the gate. The image/relink/observer difference needs its own matched control.

Negative controls: no scene remains unknown; a missed literal gate stays a
non-hit; a valid earlier read stays valid after a later GC; object tracing may
retain the type; deliberately malformed publication and post-publication
overwrite are distinct traces. No control establishes the native producer.

## Numeric Host Representation And Compiler Cost

| Layer | Established boundary |
| --- | --- |
| Source fact | Gambit [`gambit.h.in`](../../vendor/gambit/include/gambit.h.in):1231-1254 already distinguishes single/multiple hosts and label-count fallback. At 6776-6840, module/procedure boundaries select host bodies; host exit publishes `pc` and cached state, with profile-specific trampoline/tail-call behavior. This is an existing semantic boundary, not just a GCC flag. |
| Model | Reuse [`ffi_gc_frame_protocol.qnt`](../../models/gambit/ffi_gc_frame_protocol.qnt) for state/RA publication, root ownership and reload. A new partition projection, if needed after selecting a source change, must simulate logical control/state transfer; SSA syntax is not a points-to constraint system. |
| Assumption | The generated C/header/profile, host grouping, return-label ownership and full compiler phase must be bound. A solver set equivalence or high PHI arity is not a proof of the dominant algorithm or cost. |
| Native unproved | The unchanged dump-enabled C compile was capped at 60.077 s. Early-alias output is 201494614 bytes; later-alias output is 25537605 bytes and truncated. The receipt labels phase completeness unknown. No completed object or speedup follows; the unchanged full numerical gate remains open. |

Early dump SHA `9e05f071ae204b03b6b5a04d8e912bddd6464f0e8ee7003f0928e04afb5bbca6`
and later dump SHA `2e822b9b12cbc78cad532fb9cb2986a265cb5b12f7e57b38ac255c59538d135f`
bind those observations. A trailing newline and the existence of later output
do not certify the whole pass. The native owner additionally reports 105311 CFG
blocks, 161691 edges, dispatcher width 7975, maximum lexical PHI arity 15539,
`ESCAPED` same-as `_19` and `NONLOCAL` same-as `___lp`. That derived report was
not independently located/recomputed here: keep its producer/provenance open,
do not encode the numbers as axioms or treat the upstream PR127758 hypothesis
as this workload's cause. SSA/PHI, emitted constraints and points-to solutions
are separate artifacts and must remain phase-labelled.

OCaml [`asmgen.ml`](../../vendor/ocaml/asmcomp/asmgen.ml):136-166 resets per-function
register state and runs selection, polling, repeated liveness, spill/live-range
split and register allocation before emission. Its `Split.fundecl` is **live-range
splitting**, not evidence that OCaml arbitrarily divides a giant dispatcher.
Chez [`cpnanopass.ss`](../../vendor/chez/s/cpnanopass.ss):8200-8290 generates code
with label-offset/alignment convergence assumptions. Neither runtime proves
that subdividing Gambit's C host is correct or profitable; the transferable
lesson is explicit compilation-unit/state-transfer boundaries and checked
label/return-point interpretation, not their native-code backend.

Two source-representation options deserve conditional review, not flag sweeps:

- Partition at existing valid procedure/host transfer boundaries; keep strongly
  connected intra-host labels together until a cross-host transfer is explicitly
  represented. Preserve all cached registers, FP/HP/RA, return kind, calling
  context, root maps, exception/nonlocal return and FFI entry. A logical tail
  transfer must not accumulate C frames. An inline label cannot silently become
  a cross-function C `goto`. Audit both sides of every cut.
- Factor repeated diagnostic/state-transfer expansion only if single evaluation,
  ordering, types, diagnostic protection, root liveness and ABI are preserved.
  Moving state into memory can increase aliasing and runtime traffic; outlining
  can recreate inlining/IPA cost elsewhere. The retained noinline timeout is a
  negative result, not an untried fix.

The smallest partition model relates decoded boundary state before/after a
cut and permits internal stuttering; every target/return descriptor has a valid
owner. Include a GC at transfer and an error/nonlocal-return control. Omitting a
live register, using the old RA map or growing C frames must fail. This proves
only the finite transfer contract, never GCC complexity. A useful experiment
would change the generated representation at a proved boundary, retain the full
workload/profile and measure completed phase/object output plus runtime semantic
regressions. It must not count fewer SSA nodes as fewer PTA constraints or use
lower concurrency/disabled optimization as the repair.

## Old Signal Entry, Fresh Metadata And Cross-Generation Quiet

| Layer | Established boundary |
| --- | --- |
| Source fact | The curated owner report distinguishes registry reopen from generated-image reuse. `setup.c` fixup mutates module/linker metadata; the baseline's early flag and destructive resolve are already covered by the existing fixup/generation research. An OS-delivered handler stopped before admission contributes zero readers. Mask/action replacement in the supplied excerpts does not join it. |
| Model | Owner-local `root_signal_retirement.qnt` SHA `58447c434aace3f557f994c40512562e6005637ee2252d3685a4f603b70e36b5` models a terminal sealed generation; its invariant forbids reopening it. `runtime_generation_recovery.qnt` SHA `b580ca7e3a91811d3f2e9a1d424fff25e1490af5d6d8ba185310998d49fccd75` makes the missing host-quiet premise explicit. Reuse [`module_fixup_publication`](../../models/gambit/module_fixup_publication.qnt) and [`global_linker_generation`](../../models/gambit/global_linker_generation.qnt); abstract reconstruction is not a whole-image restore recipe. |
| Assumption | Reopen needs fresh correctly owned module metadata, old interpretation consumers drained/retained, old OS-handler admission settled and new callback publication. These are independent witnesses. |
| Native unproved | Repeated setup on the generated image, isolated fresh-DSO ownership and old-handler quiescence remain unqualified. Whole DATA/BSS/common restoration and its `REPEAT_OK` are rejected, not a positive control. |

OCaml [`signals.c`](../../vendor/ocaml/runtime/signals.c):112-137 records process
signal delivery in atomic pending bits and explicitly avoids assuming an OCaml
thread/TLS context; its comment identifies GCC dynamic-link/TLS signal-safety
concerns. This suggests separating notification from runtime dispatch, **not**
that pending bits identify a VM generation. Chez [`schsig.c`](../../vendor/chez/c/schsig.c):839-865
routes SIGINT through its thread/root assumptions; it also supplies no proof of
Gambit's cross-generation host quiescence. Do not transplant either protocol.

Minimum composition adds `delivered-before-entry`, `admitted`, delivery source
ownership/epoch, module interpretation identity, retained consumers, terminal
seal and distinct fresh generation. A global epoch loaded only after the old
handler resumes cannot reveal its earlier delivery epoch. Include this trace:
old delivery -> pause before admission -> zero-reader seal -> new callback/root
publication -> old handler resumes. The model must not quietly replace that
schedule with a handler already counted by the seal.

Conditional design alternatives remain open:

- A host contract continuously blocks the relevant signal on every participating
  host thread before installation, uses a runtime-owned synchronous receiver,
  and joins/drains that receiver before generation replacement. Masking only
  the cleanup caller is insufficient; host compliance and pending-signal policy
  need an actual handshake. No such contract is proved here.
- A genuinely generation-owned event source supplies stable delivery identity
  before dispatch. Its storage must outlive the old delivery. Ordinary POSIX
  signal arguments do not magically provide that token. Process-scoped pending
  bits instead require an explicit policy about delivery to a replacement root;
  they cannot claim no cross-generation delivery under the old contract.
- Fresh generated metadata must separate immutable templates and correctly
  reinitialized/owned fixups from runtime lifecycle/OS state. A DSO must prove
  symbol/storage ownership and dependencies, not assume a new pathname or
  `dlclose` gives fresh data. A fresh process is only an independent image
  control, not an in-process-reopen repair. Never copy entire writable segments.

Admission drain plus module freshness still does not imply old-handler quiet;
handler quiet plus stale static fixups is also insufficient. Retain the matched
negative controls for both omissions. Preserve terminal sealing per generation;
creating a qualified new generation is not reopening/reusing a destroyed one.

## Pending Join, Root Retention And Exclusive Owner Transfer

| Layer | Established boundary |
| --- | --- |
| Source fact | The inspected owner report places `recover_retired_processors` only in child owned cleanup, after non-root/single-processor checks. Root sticky cleanup returns the retained error before that helper; bare child setup has no pending worker. The mutable setup file differs from the supplied lock, so these reported callsites must be rebound to the actual producer before native admission. |
| Model | Owner-local `child_pending_join_callsite.qnt` SHA `2139ff3ec6396f6f37436d6cdf079b84668fe12d688b947f95af7be6aaedc9ce` distinguishes bare child, scheduler bootstrap, root sticky, detach and platform-only controls. No transition sets `legitimateRecovery=true`: its no-false-recovery property classifies exclusions, but cannot prove a reachable recovery success. |
| Assumption | Same VM/cohort/thread incarnation, actual recoverable error, still-joinable worker, exclusive legal runtime owner and reachable recovery callsite are needed before a successful real join can discharge pending ownership. Root/child policies are not interchangeable. |
| Native unproved | The platform two-thread EDEADLK handoff is not the Gambit join graph. A legitimate public sequence reaching runtime pending-error then recovery remains absent; manufactured errno/private writes/self-join/detach and bulk reset cannot fill it. |

Chez [`thread.c`](../../vendor/chez/c/thread.c):261-341 processes remembered data
and closes thread-local allocation before releasing thread context; `thread_gc`
is explicitly retained/recycled because segments may still name its creator.
Thread disappearance is not the lifetime of all collector metadata. OCaml
[`domain.c`](../../vendor/ocaml/runtime/domain.c):1346-1390 roots termination state,
publishes a result without blocking the dying domain, then unlocks joiners only
after domain termination, with synchronization storage kept alive independently.
Transfer the owner/root/result ordering, not their mutexes or scheduler ABI.

The minimum composition tracks cohort identity, retiring processors, retained
root/collector metadata, live participants, pending joins, exclusive cleanup
authority, source-reachable recovery and actual join outcome. A pending/error
processor needs an explicit GC-root transfer or continued enumerated ownership;
merely retaining its bytes does not make them scanned. A completed call or
removed VM-list entry does not discharge host/collector dependencies. Only a
qualified successful join/termination event can remove that pending obligation;
an error retains both the error and required storage. No handle/storage reuse
may turn another incarnation's join into success for this cohort.

A positive model path must derive, rather than assign, its qualification from
an earlier real-error transition, a legal same-owner handoff and the matching
reachable retry/join-zero event. For the present root sticky contract, that
retry edge is not established. The options are to demonstrate an existing legal
public sequence, or propose a separately reviewed explicit lifecycle transfer/
recovery operation and its error states. Repeating bare setup or a platform
control cannot decide this architectural choice. Do not promise a retryable
POSIX error without a supported source/OS contract.

## Source-Discriminating Refinement Of The Four Tracks

This follow-up changes the research correspondence, not the running candidate.
The source pins above still apply. Existing model runs are not rerun or promoted;
the following are explicit refinement obligations for their owners, not another
parallel set of models. In particular, no new guard may simply require the
desired read/recovery result to make a positive trace pass.

### Descriptor View Is More Than Root Reachability

Chez [`mkgc.ss`](../../vendor/chez/s/mkgc.ss):337-377 selects record size, space
and field scanning using its record descriptor. At 811-889, field-mask traversal
has mode/dirty/parallel branches; at 1549-1577, `trace-early-rtd` emission treats
copy/mark differently from measure/sweep/check, including avoiding inspection of
descriptor data overwritten by forwarding. Thus even a retained descriptor has
an **interpretation phase**, not merely an address and a live/dead bit.
Chez [`alloc.c`](../../vendor/chez/c/alloc.c):832-838 is a useful counterweight:
`S_record` obtains storage and returns it without installing the descriptor.
This primitive alone proves neither complete construction nor safe publication.
Its callers and collector-entry envelope remain necessary premises; it is not
evidence that Chez publishes malformed records.

For Gambit, relate any proposed fix to the actual object/type edge, storage
class and scanner/consumer phase. Do not transplant Chez's forwarding marker or
assume Gambit's TYPEID follows Chez's layout. The owner model's `typeValid` and
epoch equality do not currently express this view/phase correspondence; the
published `generatedMapRelocation` theorem also assumes a correct relocation
function rather than deriving a valid object descriptor. Extending either
requires actual source events, not a second independent-root policy.

The refutation distinguishes a well-initialized object whose descriptor alias
is read through the wrong relocation view from an object exposed before fill.
Record the source-mapped edge before and after its legitimate update, with the
consumer phase and incarnation. If the actual path never crosses a relevant
move/fixup/reuse boundary, this explanation loses support; it is not a default
GC diagnosis. The existing absent-scene and primary-versus-printer unknowns stay.

### Host Cuts Must Preserve Label Discovery As Well As Execution

Gambit [`gambit.h.in`](../../vendor/gambit/include/gambit.h.in):6901-6948 adds a
constraint to the earlier host/state proposal. With label values enabled, the
host owns a static label-address table; a `pc == FIX(0)` entry returns that
table through `ps->pc` without ordinary Scheme dispatch. Normal dispatch jumps
through the label descriptor, and `JUMPFAST` checks its host before taking a
computed goto. At 8097-8104, `JUMPINT` changes from a local C goto to a regular
procedure transfer when selecting multiple hosts. This is a generator/header/
fixup contract, not permission to split a C function at arbitrary lexical braces.

A representation Recipe must therefore bind both the label-discovery entry
and every executable/return label to its owning host. Preserve the effective
profile's state publication, reload, return-kind/RA maps and proper tail transfer.
OCaml's per-function liveness passes remain a contrast, not proof of this cut.
The existing FFI projection has state/RA obligations but no computed-label-table
discovery event. Its positive result cannot certify this missing boundary.

Falsification conditions include a table entry that names another function's
local C label, a discovery call that executes Scheme code, and a return label
whose owner/map differs from the generated host. Keep a separate success
criterion for completed C compilation and unchanged runtime semantics. A correct
cut can still be slower; neither fewer PHIs nor a smaller dump decides its cost.
No SINGLE_HOST/MULTIPLE_HOSTS flag experiment was run by this research lane.

### A Pending Signal Bit Is A Policy, Not An Event Identity

OCaml [`signals.c`](../../vendor/ocaml/runtime/signals.c):43-103,112-137 uses a
process-scoped bit vector. Recording uses atomic OR; dispatch clears a selected
bit with compare/exchange before executing the handler, then reloads pending
state. Two recordings of one already-pending signal need not yield two retained
events. These excerpts carry neither VM generation nor delivery-instance ID.
They support deferred, coalescing notification, not a per-generation queue or
proof that an old OS handler has ceased executing.

For the existing `root_signal_retirement`/`runtime_generation_recovery` models,
keep notification policy separate from terminal generation sealing and physical
handler lifetime. The latter's `hostQuiet` is still an external premise. A
process-level notification policy could explicitly allow a replacement root to
consume pending notification, but must not call that no-cross-generation
delivery. An alternative generation-owned event queue needs a source that binds
ownership before delayed dispatch, plus token-storage lifetime. Neither choice
follows automatically from adopting atomics.

The distinguishing counterexample is old delivery paused before admission,
followed by new-root publication and delayed old dispatch. A second control
records the same signal twice while its bit is set: it refutes an exactly-once
event interpretation, not ordinary coalescing semantics. A native notification
contract and supported host mask/receiver topology must decide the policy before
implementation; a zero admitted-reader count cannot decide it.

### Retirement Can Create New Collector Work

OCaml [`domain.c`](../../vendor/ocaml/runtime/domain.c):2262-2360 makes the
retirement/GC composition explicit. It finishes sweeping, empties the minor
heap while still participating in incoming STW work, and orphans ephemerons and
finalizers. Orphaning can create new marking/sweeping work, so completion is
rechecked. Removal from the STW participant set is serialized against new STW
requests, only when no interrupt is queued. The subsequent comment distinguishes
slot reuse from state teardown: the domain lock still prevents a new owner from
touching the state. This is stronger than retaining a pointer or broadcasting a
termination result, and relies on OCaml's collector/domain design.

Chez's retained `thread_gc` supplies a different implementation of a related
obligation: other heap segments may still refer to creator metadata after the
thread context is gone. Neither source licenses retaining Gambit bytes without
enumerated scanner ownership. Gambit baseline [`mem.c`](../../vendor/gambit/lib/mem.c):6996-7041
has phased collective setup/strong marking/weak marking/cleanup barriers; its
participation contract must be matched to the actual candidate, not replaced by
OCaml's STW lock or Chez's free-list policy.

The existing quarantine model retains resources after join failure, but does not
enumerate these roots or a handoff that may create fresh collector obligations.
The callsite model classifies unreachable recovery paths; it does not establish
a positive public sequence. Its abstract successful join cannot be imported into
the root sticky branch. The existing Lean dependency/lifetime theorem requires
a complete consumer census and does not prove this collector-participant census.

The source handoff needs distinct witnesses for result publication, last GC
participation/root transfer, OS termination/join, and permission to reuse the
same slot/incarnation. Relevant counterexamples remove a participant while a
collective request is pending, free creator metadata still named by retained
objects, or recycle a slot before its former owner's teardown finishes. A safe
retained error is not yet a recovery success. If legal public entry cannot reach
the needed retry, either the supported contract remains terminal or an explicit
reviewed lifecycle operation is needed; changing the model alone cannot add it.

### Existing Model Correspondence And Research Admission

| Existing projection | Reusable result | Remaining source refinement, not assumed closed |
| --- | --- | --- |
| `structure_type_lifetime` | Separate construction, overwrite/reuse, relocation and event-time read validity. | Actual descriptor view and producer/read source events; `safeRead` remains conditional. |
| `ffi_gc_frame_protocol` / `generatedMapRelocation` | Published cached state, RA/root map coverage, reload and interpretation lifetime. | Label-discovery entry and cross-host control simulation; compiler cost is outside the theorem. |
| `root_signal_retirement` / `runtime_generation_recovery` | Terminal sealing, admitted consumers and explicit missing host-quiet premise. | Coalescing/event policy, pre-admission delivery identity and actual host quiet; fresh module metadata remains separate. |
| `runtime_retirement_quarantine` / callsite projection / `descriptorRetirementExcludesConsumers` | Retained error/storage and conditional consumer lifetime, with excluded false recovery routes. | Enumerated GC/root handoff, queued collective work, source-reachable same-cohort retry and delayed reuse. |

### Cross-Model Composition Conditions

The following joins reuse existing models; no model code or native run was
changed. A local invariant is not a proof that the input assumptions of the next
model hold. In particular, object incarnation, moving-GC epoch, scheduler-cohort
epoch and runtime-generation identity have different meanings. Source may use
stable owned storage and quiescence rather than adding a new runtime counter;
this review does not require a universal ID allocator or hot-path instrumentation.

| Join | Existing coverage and source support | Unclosed condition and refutation |
| --- | --- | --- |
| Descriptor -> relocated input -> consumer | `structure_type_lifetime`, `gc_forward_publication` and `gc_scan_claim_transfer` distinguish object/type epochs, early canonical identity and copy-ready exclusive scan ranges. | They do not establish that their abstract objects/physical slots denote the same failed instance, or that the formatter was the first failing consumer. Two aliases of an object are not evidence of revisiting the same relocated slot. Require the matched producer/edge/phase; neither a valid address nor an injected duplicate-slot trace supplies it. |
| Generated host -> state/RA -> loader | Existing FFI/root-map contracts apply once the actual read/write resource sets, return kind, discovery order and map extent match. | The loader's current-host cursor has no direct state in those models. A-B-A regrouping with unchanged table layout refutes arbitrary host partitioning. A proposal whose effective generated representation matches a previously rejected one is not a new cost experiment. |
| Retired cohort -> roots -> delayed publisher | `scan_barrier_quiescence`, `shared_msection_copy_retirement` and `resize_queue_epoch_reuse` already cover callback-return aggregation, borrower/range premises and delayed stale publication as separate abstractions. | Aggregate completion does not establish valid copy bounds; kept bytes do not enumerate roots; a changed epoch does not transfer a publisher's payload. The epoch/reject protocol is proposed in the model, not automatically implemented by similarly named scheduler fields. |
| Root seal -> OS delivery -> fresh image | Existing root-signal, recovery and module-fixup models expose distinct admitted-reader, host-quiet and metadata-freshness premises. | A delayed queue publisher's epoch guard is not an OS delivery token. Scheduler startup readiness is neither old-handler quiescence nor fresh static fixups. Each source must supply its own ownership and lifetime correspondence before these models compose. |

The range model's `finishCopyPhase` clears abstract borrowers after all copies;
the source must establish that this list includes all actual borrowers. Its
valid-range guard is also a premise, not a proof that a generated RA describes
the native frame. Similarly `resize_queue_epoch_reuse.rejectStalePublisher`
marks abstract payload ownership moved: a real rejection path needs a collector-
visible destination owner or continued traced ownership, not merely an error
return or a newer scheduler number. `generatedMapRelocation` supplies no such
destination by itself. Preserve the original error and existing valid FFI exits.

### Normal Collective Return Provides A Narrow Bridge

The inspected mutex-return candidate remains bound to the source lock above.
`mem.c`:7720-7821 has phase barriers followed by an epilogue and return; that
last phase barrier is not itself completion of every callback's epilogue.
However, `setup.c`:1338-1404 dispatches `OP_GARBAGE_COLLECT`, and 1428-1530
returns normally to the collective loop before entering its next
`barrier_sync_op`. In 755-925, that operation takes the old population, receives
child messages up the tree, and only then handles `OP_SET_PROCESSOR_COUNT` at
the root before propagating the result. This supplies a source-order bridge for
the model's callback-return/upward-aggregation premise on this normal route.

The bridge assumes the same collective cohort, ordinary callback return and
all relevant queue borrowers participating in the protocol. It is not a C
memory-model proof or a complete census of nested/foreign/signal consumers.
Nonlocal throws, startup admission and OS-thread join/storage reuse remain
distinct paths. Thus "no final barrier in the GC function" is insufficient
evidence of premature queue destruction. A low-cost implementation Recipe
should reuse this normal collective closure, audit the exceptional/missing-
borrower edges, and repair only a demonstrated missing edge. Do not insert a
second unconditional global barrier or equate callback return with OS join.

### Retained Refutation Of A Representation-Equivalent Host Candidate

The inspected auditor receipt
`.cache/codex-repair-audit-20261020/host-equivalence-02/exact-location-comparison.json`
has SHA `33da602826bbed9bdeac68e71a620cbf79285999c3329223c966ae50ce79ee75`.
It records identical preprocessed text after explicit source-path and diagnostic-
location normalization: 3307 diagnostic literals adjusted by a seven-line source
offset, zero remaining different lines, normalized SHA
`44d34e1be88bbe72b3bc388dd8eed02080d497d4d59ca0ed1b937981a0817d4c`,
and `nativeAdmitted=false`. This is a historical comparison receipt, not a source
Recipe input, binary-equivalence proof or newly executed experiment here.

It refutes treating that candidate as a distinct effective host representation
for another full compile. Do not reuse this normalization to erase semantic
constants, labels, types or configuration differences in an unrelated proposal.
The open research direction is an actually different, semantics-preserving
resource/label/control cut with a bounded cost hypothesis, not another spelling
of the same threshold. No native compiler or stress test was rerun for this audit.

These correspondences are registered using the existing `source_section` and
`transfer_premise` relations in `runtime-entry-facts.json`. Coverage stays
`partial`, and `satisfies` stays empty. Owner-local models retain the snapshot
qualification stated earlier; no unpublished model is made a reproducible input
merely by naming it here. No QNT/Lean implementation proof or native pass is
claimed for these newly identified composition obligations.

### Low-Cost Scope Versus A Separate Architectural Milestone

| Track | Conditional first-stage scope | Separate milestone / evidence that rejects the small Recipe |
| --- | --- | --- |
| Structure/type | Repair the identified producer's initialization/exposure or its existing traced-owner reload boundary, once actual events distinguish them. | No identified producer yet. A new descriptor/collector representation or blanket pinning is not justified by a formatter crash. |
| Numeric host | Reuse an already supported host/procedure boundary with complete label discovery, state/map and tail-transfer correspondence. | Arbitrary intra-procedure partition, new cross-host continuation representation, or a required change to supported FFI belongs to a separately reviewed generator milestone. No completed compile improvement has been measured. |
| Signal generation | Preserve terminal sealing and make existing notification policy/ownership explicit within its supported lifecycle. | A new all-host mask contract, receiver thread, generation-token event source or reusable module image changes embedding/lifecycle assumptions. Do not call it a local atomic-counter repair. |
| Retirement/join | Finish a source-reachable same-owner retirement and explicit root/metadata handoff without slot reuse before completion. | If the public contract has no legal retry edge, adding restart/recovery authority is a new lifecycle capability; a model-only successful retry does not make it a small repair. |

These are feasibility boundaries, not selected fixes or promises of a particular
gain. The implementation lane must bind the actual supported caller and failed
event before choosing between them. None requires replacing Gambit's C backend,
narrowing valid continuations or serializing independent VM execution.

## Reusing The Deeper Publication And Work Models

This additional research follows `ba59caa`; it changes neither the existing
model algorithms nor runtime source. The initial structure/FFI correspondence
is not the entire available model inventory. Four published projections already
address parts of the more concrete collector protocol and must be reused before
considering another model:

| Existing model | Relevant transition/predicate | Source correspondence and remaining premise |
| --- | --- | --- |
| `gc_forward_publication.qnt` | `claim`, `redirect`, `copyWord`, `publish`, `scan`; `publicationSafe`, `terminationSafe`, `destinationSafe` | Baseline `mem.c`:3568-3628 claims a forwarding destination before copying its payload; a loser redirects a reference and continues rather than scanning that unfinished copy. Completed-chunk publication at 3251-3312 and scanning at 4320-4387 are separate events. The model assumes stopped mutators, abstract queue visibility and correctly classified input slots. It does not establish that the failed native reader followed this protocol. |
| `gc_scan_claim_transfer.qnt` | `exportTail`, `acquire`, `scan`, `nextEpoch`; `ownershipSafe`, `inputSafe`, `readySafe`, `epochSafe` | A copy-ready frontier and exclusive logical scan range are different from canonical object identity. Two aliases of one object are permitted; rescanning the same physical relocated input slot is a different schedule. Actual source ownership/cursor ranges, storage reuse and RA interpretation must instantiate the model's slots and epochs. |
| `gc_queue_probe_access.qnt` | `probe`, `recheck`, `retire`; `raceFree`, `hintIsNotAuthority` | Candidate `mem.c`:3566-3575,7397-7442 uses atomic endpoint hints and protected payload/recheck access. An empty unlocked hint alone cannot authorize idling or retirement. The model's abstract conflict flag is an access-discipline control, not a C11 data-race proof. |
| `gc_queue_wait_composition.qnt` | `releasePublication`, `acquireSignalMutex`, `probeRecheckQueue`, `registerWait`, `resume`; `countSafe`, `producerLifetimeSafe`, `closureSafe` | Candidate `mem.c`:3586-3607 releases queue Q before acquiring termination M for notification; 7430-7482 rechecks queues under M, then decrements/counts/waits and restores the count on nonterminal wake. The model's combined policy is the relevant comparison; its older source policy is not automatically the current candidate. Copy-ready work and finite counted producers remain premises. |

The inspected four model files are unchanged from the published research tree.
No old verifier campaign was rerun. Their finite worker/word bounds describe
abstract schedules, not a machine-concurrency configuration. The forwarding
model's shared `WorkObligations.canonicalReferences` says where aliases point;
it does not establish at-most-once physical-slot scanning or complete payload.
Do not replace those distinct predicates with one generic "valid object" flag.

For the host Recipe, generator `targ-begin-cod` at `_t-c-1.scm`:2132-2192
derives declaration/reload/writeback sets from actual read/write resources and
emits label entries in procedure order. Loader `setup.c`:1750-1842 retains only
`current_host`, not an independent cursor for each host. A new A -> B -> A
host ordering would query A's table from its start again, so it cannot silently
reuse the old table order for a later A label run. Preserve contiguous matching
host/table runs, or explicitly redesign and verify the fixup correspondence.
This conditional layout counterexample rejects arbitrary regrouping, not the
existing single-host or per-procedure-host encodings. Neither the FFI state
model nor `generatedMapRelocation` currently represents this discovery cursor.

### Two Publication Frontiers And The Lock Handoff

A forwarding CAS can expose **identity** before the winner has copied all
payload words. A later queue handoff exposes **scannable completed work**. In
the bound candidate, continuation copying can also accumulate a private segment
before `publish_heap_chunk_segment` makes it stealable. Its relaxed endpoint
loads are hints; they are not the release/acquire payload contract by themselves.
The Q critical section and complete private-to-shared handoff must be checked.
Making the earlier forwarding CAS stronger cannot publish stores that occur
after it. Conversely, this ordering is not itself a race: the existing stopped-
mutator and queue/scanner discipline can make early identity publication valid.

The small-refactor review therefore has a concrete target: retain the existing
queue publication/claim helpers, verify their actual copy-ready frontier and
range ownership, and repair only a demonstrated consumer or ownership violation.
Do not add a second queue, pin every descriptor or globally serialize GC. For
lock order, the observed producer uses Q then releases Q before taking M; the
waiter holds M while briefly checking Q and releases M before scanning. This
excerpt does not contain a Q-held-while-waiting-for-M edge. All other callers,
recursive scans and callbacks must still be audited before claiming a complete
lock-order proof. A notification is not durable work storage: either the waiter
sees queued work on its protected recheck or the publisher synchronizes with its
wait-registration boundary. Private producers must remain counted throughout.

The reusable counterexamples already distinguish early payload publication,
uncounted producers, duplicate relocated input slots, stale epoch claims,
retained local ownership after export, stale empty hints, lost notifications and
failure to restore active count on wake. Keep their source-reachability status:
an extracted/injected duplicate-slot schedule is not proof that the full native
root enumerator produces it. These are discriminators for a proposed repair,
not eight new diagnosed native bugs.

### Lean Premises Must Be Instantiated, Not Renamed

`WorkAccounting.zeroCountAndEmptyQueuesExcludeHiddenWork` quantifies over a list
of workers and needs `ProducerLifetimeSafe` in addition to zero count and empty
queues. The source must enumerate all private producers in that list; the
theorem does not discover a producer missing from it. Its existing
`missingLifetimeCounterexample` and `reopenedWorkRevokesZeroCount` are directly
relevant to OCaml's retirement that can create new marking/sweeping work. Reuse
them rather than asserting that a one-time empty observation stays true.

`RuntimeEntryContracts.generatedMapRelocation` separately requires complete
live-to-mapped coverage and a correct `scanned` relocation relation. It says
nothing about a half-copied descriptor, host-label discovery or whether a native
slot can be revisited. `descriptorRetirementExcludesConsumers` requires a
complete live-consumer dependency census; interpreting `available` as merely
"allocated bytes exist" would not supply scanner interpretation readiness.
`ownedNestedExitAccounting` assumes balanced entries and preserved original
errors; it neither creates an OS join retry nor proves the ownership handoff.

OCaml `stdlib/domain.ml`:264-307 completes the previously one-sided termination
reference: `Domain.join` waits under the termination mutex until `Finished`,
then returns the result or raises the captured exception/backtrace. The C-side
signal before teardown does not alone let the joiner pass the still-held mutex.
This is language-domain result synchronization, not evidence of a retryable
POSIX join error. Keep exception delivery, root retention, collector completion
and OS thread ownership as separate obligations for Gambit's supported FFI.

The signal model needs the same distinction in interpreting results:
`runtime_generation_recovery.safe` permits the deliberately selected cross-
generation control; `noCross` is the property that rejects that trace. A union
characterization passing `safe` cannot establish no cross-generation dispatch.
Likewise a model field named `nativeQualified` is only a modeled conjunction,
not admission of an executable or a source-reachable recovery. No new native
result or model-proof completeness is inferred from this correspondence audit.

## Handoff Frontier And Validation Boundary

### Follow-Up Source Cuts For Implementation Review

The following additional source audit was performed after publication of
`8c41b60`; it is not covered by that commit's CI. No runtime was changed and
no native test was rerun. The candidate observations below use the identified
mutex-return source lock, not the older root-signal lock. Relevant candidate
hashes are: `_kernel.scm` `dede9ab818a272de32ec4984be72fdc35ac1a442365f71603ef4bee684093bc8`,
`mem.c` `11402bbbc1efc9ff42d4b1ae10a5909cc9ff15778251835e1ac8dbb1d26023b5`,
`setup.c` `9b86f40c780b68e0a285ee50f3391676c6b4f6a9351ba6d73a32af293b8ac34a`.
These are inspected source observations, not a new reproducible candidate
recipe or executable/checkpoint binding published by this research lane.

**Constructor cut.** The candidate `_kernel.scm`:5019-5048 saves `type_` in
GC_SAVE1 around allocation, restores it, then initializes the structure payload
before returning the result. The local allocation macros at 43-116 publish
cached state/RA around their slow allocation/collection paths; the following
fill contains no explicit Scheme callback or allocation. This is counterevidence
to the blanket claim that this constructor simply forgot to protect its type.
It is not proof of all nested callees, actual generated roots, later setters or
the failed instance's constructor. The source cut for a small repair is the
first demonstrated init/exposure or relocation/reload mismatch, not another
unqualified GC_SAVE slot. Preserve the type field while filling payload fields;
the suspected writer/first read must be matched to the same incarnation.

Chez's generator provides a more precise comparison: `s/mkgc.ss`:1736-1762
installs `copy-extra-rtd` into the destination during copy generation, with a
special tag-reflexive/counting case. It is an emitted descriptor-edge operation,
not a universal extra root. The source refinement needs the edge-update event,
the view used to interpret it and its consumer; epoch equality alone cannot
derive those. A proposed fix is refuted if the bound failed path shows no such
mismatch or if observation itself adds a retaining root that removes the fault.

**Host/fixup cut.** Gambit baseline `gsc/_t-c-1.scm`:1870-1905,2066-2125 emits
module and procedure host bodies and their label tables from procedure records.
Baseline `lib/setup.c`:1750-1842 iterates the generated label table: it queries
the host when ownership changes, skips INTRO entries, writes host-local label
addresses, and advances out-of-line map storage using frame size and return
kind. This closes the source reference from generator through header discovery
to loader consumption; it does not close the proposed representation change.
The handoff artifact for any cut must associate each label's host, position,
INTRO treatment, return kind and map extent with its generated source. Changed
host grouping without corresponding discovery/fixup/table changes is not an
admissible C-only optimization. Preserve the existing switched-dispatch profile
as a separate supported encoding, not a false computed-goto control. Whether
this cut reduces the actual alias-analysis cost remains experimentally unknown.

**Notification cut.** Candidate `setup.c`:116-179,256-309 already uses a pending
bitset and admission-aware replay, with a distinct deferred root-only USER bit.
The signal path does not take the VM-list mutex. Therefore adopting OCaml's
pending-bit idea is not a new missing mechanism here. The unresolved contract
is who owns an OS delivery paused before admission, and which generation may
consume it. Copying OCaml's all-domain notification would additionally lose
Gambit's root-only versus broadcast distinction unless independently preserved.
The small Recipe is a source-bound policy/ownership repair within the supported
lifecycle; a new receiver or generation-event source needs the separate host
contract already described above. Test or model the routing class independently
from handler lifetime, replay, freshness and admitted-reader drainage.

**Retirement cut.** Candidate `setup.c`:1270-1299 publishes pending joins before
the collective count reduction. On successful OS join it transfers donor memory,
cleans memory state, then clears pending ownership. The retry helper at
1106-1133 follows the same success order. Candidate `mem.c`:5499-5566 transfers
the still-object chain, associated counters and RC list under the miscellaneous
memory lock. It does not itself implement an arbitrary saved-frame/queue/root
transfer; its comment requires the caller to have completed GC/queue borrower
drain. Thus a second generic retention/transfer implementation is not indicated.

The open proof is that this exact caller establishes the donor/receiver identity,
GC and queue borrower census, no concurrent users and valid pending lifetime.
`cleanup_owned_vmstate`:5408-5447 requires a non-root single-processor VM, invokes
recovery before closing foreign admission, and assumes direct users already
joined; closing that admission first is not automatically compatible with worker
interrupt progress. Root `cleanup_checked`:5609-5686 instead seals and preserves
a sticky resize/join failure; repeated cleanup returns the error before calling
child recovery. Neither a bare child nor normal successful shrink witnesses
recovery from an actual join error. A child-owner retry remains conditional on a
legal sequence that starts and retires a real cohort and preserves joinability;
no supported retryable OS error has been demonstrated here.

The implementation decision is consequently narrow: retain the existing
success-path transfer, prove or repair its missing borrower/ownership bridge,
and explicitly choose terminal versus recoverable error for each supported
entry. A new root recovery operation is a lifecycle capability, not a call to
the child helper under a different pointer. The existing model's
`joinSuccess`/`resourcesLive` do not supply that bridge. Its refinement needs
distinct OS-exit/join, scanner ownership and permission-to-reuse events, with
the queued-collective counterexample from OCaml's retirement audit retained.

The discriminating frontier is producer/first-error identity; a semantics-safe
representation cut with completed cost evidence; OS-delivery and module-image
generation ownership; and a source-reachable same-cohort recovery transition.
Existing conditional Lean results (`generatedMapRelocation`,
`descriptorRetirementExcludesConsumers`, `vmCellWriteFrame` and
`ownedNestedExitAccounting`) expose coverage/ownership premises, not these
missing native witnesses. Do not repeat a model solely to reproduce an already
documented counterexample. Extend its composition when a new real event or
source contract is available; preserve failures and unknowns in the existing DSL.

CI at published `74a9c04` has finished: patch contracts/build and GC-FFI,
compile-execute, both interrupt modules and terminate passed; upstream, threads
and TFIB failed. Framework failed before tests while downloading Lean 4.34.1
with TLS error 35. Thus the previous four framework-test corrections are not
remotely qualified by this run. This note does not fix CI, rerun it or promote
local proof results into native acceptance. See the
[framework job](https://github.com/tao3k/gambit-SMP/actions/runs/39284711008/job/118167266861)
and [native run](https://github.com/tao3k/gambit-SMP/actions/runs/39284711041).

Follow-up CI at `8e0bef313e7628369cdd01fe55b610d884289915`:
[framework run 39346446928](https://github.com/tao3k/gambit-SMP/actions/runs/39346446928)
and job `118380093541` completed successfully. Artifact `12231462524` reports
1809 outcomes, all pass, zero failures/errors/skips/expected failures/unexpected
successes, complete test inventory, no changed inputs, `frameworkValidated=true`
and `runtimeAdmitted=false`; elapsed framework time is 381.301 seconds. The
artifact's `test-result.json` SHA is
`f9cbacc3ccba2d051d47873fc2fcc6a2ffab7a0fdb5cddeb23681eebe8749118`.
This qualifies that published framework revision, not these subsequent research
edits or the current native overlay. The docs push also triggered a duplicate
native workflow (`39346446959`) through cumulative PR paths; it was cancelled
without rerunning the earlier native failures. No new native result follows.

At `8c41b602aa87273ec1e34b4f6d1ab0d2f1fb47eb`,
[framework run 39347919635](https://github.com/tao3k/gambit-SMP/actions/runs/39347919635)
also completed successfully: 1809 tests, zero failures/errors/skips/expected
failures/unexpected successes, complete inventory, unchanged inputs,
`frameworkValidated=true`, `runtimeAdmitted=false`, 400.217 seconds. Artifact
`12231888454` has `test-result.json` SHA
`fd6827c903c440df8840451fd7f406e7730140672346a0c91a23bea39840abf6`.
The audited source-cut follow-up was then published as `ba59caa`; its duplicate
native run `39348868607` was cancelled. No observation in this later research
section upgrades those framework results into GC or join-recovery acceptance.

At `21021240ebd627ae51ee6fffdce58783d2e23960`,
[framework run 39349474528](https://github.com/tao3k/gambit-SMP/actions/runs/39349474528)
completed successfully: 1809 tests, zero failures/errors/skips, complete
inventory, unchanged inputs, `frameworkValidated=true`, `runtimeAdmitted=false`,
348.188 seconds. Artifact `12232711875` has `test-result.json` SHA
`ed6fcab89ed7cf34d3ee8e447eea84ab79ca32275eb123674dea465fa2b1ae4e`.
This is exact-head framework qualification, not evidence of a native speedup or
closure of the later cross-model source assumptions recorded in this document.
