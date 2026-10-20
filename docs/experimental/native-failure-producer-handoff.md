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
the whole candidate to this older lock. The native owner must identify which
setup producer its checkpoint uses; this note does not reseal it or invalidate
unrelated historical stages. The structure source map also names cache files:
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

## Handoff Frontier And Validation Boundary

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
