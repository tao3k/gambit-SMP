# C Backend Assets And Matched Rebuild Contract

## Architectural Objective

The reference-transfer objective is **reliable parallel Gambit without losing
its generated-C execution model**, not convergence on Chez or OCaml internals.
Scheme-to-C is an important Gambit asset, not a claim that only Gambit uses that
technique. Portability and performance potential are design properties; this
review establishes no ranking against other languages or measured speedup.

Pinned Gambit `README:21-35,61-67` describes portable properly tail-recursive C,
C FFI, executable/shared-library linking and dynamic loading. Its manual
`doc/gambit.txi:137-149` identifies C as the mature target and describes the
Scheme compiler/interpreter being compiled through it. Claims about generated
code below use the existing locked overlay, not newly produced binaries.

| Asset to preserve | Source contract | Consequence for GC/concurrency transfer |
| --- | --- | --- |
| Portable generated C and host C toolchain | Manual above; header module/procedure and jump macros at `6810-7002`. | Do not require a new machine-code backend, JIT or compiler-specific stack discovery to obtain Stage-One correctness. A target adapter may have an explicitly narrower supported profile. |
| Proper tail calls and separate Scheme continuations | Manual `19935-19992`; header continuation macros `6626-6750`. | Preserve Scheme/C stack separation, valid nested C -> Scheme calls and continuation semantics. Do not equate an OS stack with every live Scheme root. |
| Generated liveness and direct access | The existing [liveness audit](stage-one-closure-audit.md#generated-root-liveness-what-was-actually-established); header `3150-3166,6798-6807`. | Keep ordinary movable allocation and already-resolved module-global access outside new metadata guards. A new safepoint/root-map obligation belongs to the generator/ABI, not an untraced C-local backup. |
| Deliberate storage classes and FFI | Header `2895-2972`; `mem.c:1728-1965` and CFUN/SFUN adapters. | Distinguish movable, still and permanent lifetimes. A permanent symbol permits an address-stable result, not stable mutable table links or VM-independent Scheme values. |
| Existing process/VM/processor split | `configure.ac:1245-1336`; explicit pstate and VM global segments. | Repair ownership/publication at the right level. Do not replace per-VM values with a shared environment or add TLS merely to pass an existing context. |
| Dynamic C modules and embedding | `setup.c:1997-2026`; header `9481-9488` records layout sizes. | Layout, generated inline protocols, C callback effects and runtime generation must be reviewed separately. |

This preserves **semantics and useful fast-path structure**, not every current
macro or internal layout forever. A Stage-Two GC barrier may change code
generation when justified, but must account for generated Scheme writes, inline
C writes, FFI roots, tail-call/continuation behavior and sequential cost together.
Likewise, preserving a C target does not prohibit a better collector. A blanket
copy of OCaml's domain/heap protocol or Chez's compiler maps is not such a design.

Also avoid diagnosing Gambit as one undifferentiated shared heap:
`configure.ac:1245-1248` explicitly gives each VM its own environment/heap;
process metadata and same-VM processor sharing are different layers. Neither
replacing all globals with TLS nor abandoning shared objects follows from the
fact that some process-shared metadata contracts remain incomplete. The C
backend is not evidence that it causes those protocol defects.

## Authority And Scope

Baseline Gambit is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`; current runtime
line references use the existing
[source lock](../../evidence/research/processor-interrupt-collective-wait/source.lock.json)
and cumulative patch. `README` and `doc/gambit.txi` are pinned vendor baseline
documents, not guarantees extended by the repaired overlay. Chez is
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd`; OCaml is
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.

This reviews the consistency premises for the
[complete metadata package](shared-metadata-package.md). It does not implement
P/M guards, change TLS, rebuild extensions, run native tests or alter native
milestone status. The other lane's source and execution checkpoints remain owned
by that lane.

**Stage-One policy: one repaired source revision, effective configuration and
complete rebuild of runtime, generated C, libraries and extensions.** Defective
SMP protocols are replaced, not kept as fallback modes. Preserved compatibility
means supported Scheme/continuation/FFI semantics and C-backend strengths, not
concurrent interoperability with old inline instructions. Historical failures
and receipts remain evidence, not a supported old-protocol implementation.

## External Callback Reentry

The callback's **effect and entry context**, not its C signature, determine
whether it may execute under protection.

| Entry | Actual established contract | Stage-One boundary |
| --- | --- | --- |
| Ordinary generated SFUN/CFUN nested entry | Manual `19939-19981` explicitly supports nested C/Scheme calls and describes C-stack lifetime on continuation escape. Current marker/lease/ON_THROW and saved-frame mechanisms have separate models. | Preserve supported nesting outside the metadata/registry-owned leaf interval; no blanket callback ban. Roots, owning processor and original exception/continuation semantics still apply. |
| Arbitrary generic symbol visitor | `mem.h:225`, `mem.c:2405-2433` has a void callback; reviewed in-tree C caller is TTY (`os_tty.c:6835`). It is private header surface, not found in the public runtime function table/manual census. | Use a private reviewed leaf traversal for TTY. Preserve established callback semantics in rebuilt callers; do not silently hold nonrecursive M through an unknown visitor or claim a new concurrent/OOM-reporting snapshot API. |
| Procedural interrupt execute | Public registration `setup.c:252-264`; normal delivery releases the queue mutex before `execute_fn(..., TRU)` (`279-311`). | A normal execution callback and a teardown release callback have different ambient resources. Registration itself specifies no reentry effect. |
| Procedural interrupt release | Cleanup calls `execute_fn(..., FAL)` while queue ownership remains (`520-544`); processor/VM cleanup can additionally own V (`5125-5140,5280-5389`). Its returned SCMOBJ is ignored by that cleanup loop. | Leaf interning can follow V -> M -> P. A callback attempting V again, queue reentry, arbitrary Scheme entry or nonlocal exit has no newly established cleanup contract. Do not pretend a returned error provides rollback/unlock. |

The search covered the reviewed `lib/`, header, examples and manual surfaces,
not arbitrary external embeddings. Lack of a documented prohibition is not
proof of safe reentry; lack of an in-tree caller is not proof that no extension
uses it. Stage One preserves known supported calls and makes no new teardown
reentry guarantee. If an embedding depends on such reentry, it needs a separate
reviewed detach/drain/dispatch change rather than a new recursive mutex or an
unannounced compatibility break. Do not conflate that with banning supported
ordinary nested FFI calls.

Reference transfer: Chez's operation-level interner and OCaml's locked named
table are useful boundaries. OCaml `callback.c:434-445` also calls a C action
inside its table guard, but does not prove Gambit's callbacks have that action's
effects. Its `otherlibs/systhreads/caml/threads.h:31-79` distinguishes registered
foreign threads from acquired runtime ownership. Neither supplies Gambit's
processor/continuation cleanup contract.

## Rebuilt Generated Code And Runtime Consistency

Current header `5950-5958` embeds plain binding reads in `GLOBALVARSTRUCT` and
related macros. Old object code keeps those instructions after a runtime update.
`setup.c:2009-2026` checks compiler version and **sizes** of module, global, VM
and processor structures. It does not compare field offsets, every compiler
option, protocol generation or whether an inline reader uses acquire semantics.
Equal layout/accepted module load is therefore not a publication witness.

| Component state | Stage-One decision |
| --- | --- |
| Recompiled with the matched proposed header and flags | Candidate for the new live-discovery contract after all publisher/read sites and producer lineage are checked. Compilation alone is not qualification. |
| Object code generated with an older header or protocol | Rebuild it. External serialization and mixed-version fallback are not alternate Stage-One qualification paths. |
| New publisher paired with an old inline reader | Inconsistent producer set, not a compatibility feature. A writer-side release fence cannot retrofit the missing reader instruction. |
| Existing resolved generated globals | Preserve stable module records/per-VM cell addressing. A new metadata mutex is not required on every ordinary value operation. Payload races, module readiness and lifetime remain separate obligations. |

Account for changes to GSTATE/VM/PSTATE fields: generated modules record
their sizes, and generated/indirect runtime calls use their layouts. Private
control storage can reduce layout churn only if it is bound to the actual
runtime instance/generation. `LOCAL_GSTATE` (`header:8634-8668`) can use the
module's supplied global-state pointer; a universal process singleton cannot be
assumed equivalent in every embedding. No private-storage placement or version
bump is implemented here. Coordinated internal header/layout changes are allowed
when justified and rebuilt throughout; preserving defective instructions or
freezing every internal ABI is not required. No mixed-binary support milestone is
part of this package.

Reference transfer: OCaml's stable named slot is not immutable payload; Chez's
internal C headers are not Gambit binary-compatibility rules. Adopt explicit
ownership/publication distinctions, not another runtime's ABI assumptions.

## Initialization Failure And Rollback

There are two different boundaries: **failed private setup before admission**
and **restart after a published runtime generation**. They must not share a
single successful-retry claim.

Current source observations:

- `setup.c:7063-7073` sets setup state to 2 and initializes V without checking
  the POSIX boolean result; a later interrupt-prefix error can return before
  the normal memory/OS cleanup path. State 2 is not a completed teardown.
- `setup_os_and_mem:5057-5070` cleans OS on memory-setup error, not permanent
  sections. `setup_mem:5467-5494` can create the first permanent table and return
  an error on the second. The successful prefix's cleanup cannot be inferred
  merely from the returned error. This is source evidence, not an injected
  native failure or a claim that every setup failure leaks.
- The full cleanup entry refuses/reports certain active users and preserves
  failed-join state before reclamation. Do not use it as an unqualified failed
  prefix destructor; it has a different admission contract.

The Stage-One implementation must enroll **each successful prefix**: V where
present, P0 interrupt resources, OS setup, new P/M guards, and the entered
permanent-memory prefix. Each failure preserves the original error and unwinds
only owned resources, in dependency-safe order, under exclusive global lifecycle
ownership. An entered memory prefix may own partial storage even when its last
table allocation failed; free it before destroying guards it can use. No user
or Scheme callback may be invented to perform that rollback. Do not destroy
an uninitialized mutex, rely on normal `___cleanup` being admitted, or rewind
shared reservations once users exist.

At the first point where linker/module fixup mutates persistent structures,
private-prefix retry no longer establishes restart safety. Reuse
`global_linker_generation.qnt`, `module_fixup_publication.qnt` and the existing
unwind/VM-constructor models instead of resetting flags and claiming a clean
generation. Stage One does not silently promise full runtime restart.

Reference transfer: Chez `thread.c:27-49` initializes thread/collector resources
under boot-time ownership and even records a heap-restoration reset requirement;
its OOM abnormal-exit policy is not Gambit's recoverable-prefix protocol. OCaml
`startup_aux.c:173-252` counts startup calls but explicitly rejects startup after
shutdown. Mature runtime behavior does not imply universal restart support.

## Compilation And Platform Matrix

Configure controls **independent capabilities**, not a certificate for every
combination. The reviewed overlay `configure.ac:1245-1336` and `2194-2265` are
the source of this matrix; inspect effective generated macros, not flags alone.

| Effective configuration | Stage-One consequence |
| --- | --- |
| One VM, one processor, no OS thread system | New guards can be compiled out only under the supported exclusive-host contract. Header mutex operations may expand to nothing. No cross-host concurrency is inferred. |
| Multiple VMs, single-threaded per VM | P/M remain process-shared resources despite `SINGLE_THREADED_VMS`. V and per-VM root-slot publication apply. Two separately owned VM threads suffice to need protection. |
| Single VM, multiple-threaded VM | P/M apply to same-VM concurrency even without the Scheme SMP scheduler. V may be absent; do not add a reference to an absent registry field. Ownership/GC participation still apply. |
| Multiple VMs plus multiple-threaded VMs | Full proposed V -> M -> P package and per-VM root-range readiness. Scheduler on/off remains separate. |
| `--enable-smp` alone | Sets the Scheme feature separately; it does not itself establish multiple processors/host ownership. Qualify the effective backend, not the label. |
| Requested threads unavailable | Configure can fall back to single VM/single-threaded settings. Fail the intended concurrency-profile qualification rather than treating a sequential fallback as a parallel pass. |
| POSIX versus Windows | Header `10980-11009` uses boolean-returning pthread initialization versus void-returning CriticalSection operations. Normalize success/failure before enrolling ownership; do not apply `if (!MUTEX_INIT(...))` blindly. Protocol code must not depend on recursive acquisition. |
| Native GNU atomics absent | Header has Win32/emulated/sequential alternatives, but this overlay's multi-VM registry explicitly requires `USE_sync_builtins` (`setup.c:113-115`). That profile is currently unsupported without them. No Win32/all-compiler portability claim follows. |
| Word size, TCO/jump mode, low-level execution, C/C++ cleanup, static/dynamic modules | Preserve selected layout, alignment, generated maps, catchers and cell-address lifetime. Relevant branches are acceptance obligations, not profiles executed in this audit. |

The model's finite participants are counterexample witnesses, not runtime CPU
limits. Actual build/test parallelism remains host-adaptive; this turn starts
none. GCC/C-specific adaptations must remain confined to their declared profile,
without weakening the portable baseline or claiming Clang/Windows acceptance.

## Closed Design Boundary And Acceptance

The first implementation candidate is a **matched-source/header, effective
GNU-atomic profile**, with supported owned callers, builtin TTY/Geiser adaptation,
leaf P/M owners, V -> M ordering, and explicit private-prefix unwind. It requires
a complete matched rebuild, without an old-SMP fallback. It preserves
ordinary nested FFI outside owned leaf intervals and generated allocation/global
fast paths. Arbitrary teardown reentry, missing
atomic backends and post-publication runtime restart are not silently included.

This is a bounded design decision, not universal compatibility or native repair.
Before implementation acceptance, bind and test:

1. Actual effective macros/producer and all live discovery/publisher sites.
2. Supported nested FFI and cleanup callbacks with their ambient ownership;
   original errors/continuation semantics, not a blanket no-callback rule.
3. Failure at each setup-prefix cutpoint, exact-once cleanup, subsequent private
   setup where supported, and no stale module-generation claim.
4. Original stress, VM isolation and performance gates at the same candidate;
   generated map/reload evidence for any new safepoint.

The existing metadata model adds only a private guard/memory-prefix projection:
failure before guard initialization, failure after partial table storage,
rollback, and retry before publication. Negative controls leak the completed
prefix or destroy an uninitialized resource. Existing reservation/reader/order/
publication controls are reused for the other premises. The model does not
simulate Windows initialization, old machine instructions, the full OS/interrupt
prefix or runtime restart. Existing Lean interval/order/owned-exit results remain
conditional; no extra arithmetic theorem is presented as C-backend preservation.
See [validation](c-backend-compatibility-validation.md) for exact local results.
