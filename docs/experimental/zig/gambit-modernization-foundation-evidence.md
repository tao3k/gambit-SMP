# Foundation Evidence and Learning Boundaries

Exact source and prior-study hashes are bound by the
[traceability ledger](gambit-modernization-foundation-traceability.json).
Local source claims concern the inspected checkout, not a configured/loaded
runtime. The public documentation below was read as primary design/API evidence;
its examples and performance figures are not Gambit measurements.

FS01. Existing Scheme target separation.

[_back.scm](../../../vendor/gambit/gsc/_back.scm#L150), 150–195 and 388–430,
constructs target descriptions and selects dump/primitive/frame/jump/object
interfaces. This supports an existing compiler seam. It does not prove a
complete neutral HostGraph/FrameSpec exporter, semantic completeness or a Zig
backend already exists.

FS02. C is a real backend and interface asset.

[_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm#L224), 224–277, registers the C
target and callbacks; 337–355 consumes C-interface declarations/procedures/
initializers/objects during emission. [tcltk.scm](../../../vendor/gambit/examples/tcltk/tcltk.scm#L289),
289–343, is a real C-FFI producer with native client data, managed object/RC
custody and command registration. These are concrete obligations for a C-to-Zig
implementation migration, not a reason to remove C capability.

FS03. Actual collector mechanism.

[mem.c](../../../vendor/gambit/lib/mem.c#L130), 130–165, documents the actual
object tags; 6938–7047 shows synchronized setup/strong/weak/cleanup/resize phases.
The earlier [mechanism audit](gc-current-mechanism-audit.md), CA01–CA12, supplies
the wider section, forwarding, writer, root, weak and configured-profile evidence.
It finds no active generational algorithm in the inspected path and identifies
parallel copying/scanning source support. Header generation names are not proof
of selective young collection, and source support is not loaded-profile acceptance.

FS04. Scheduling and execution are already multi-processor concepts.

[_thread.scm](../../../vendor/gambit/lib/_thread.scm#L679), 679–710, selects
processor run queues and pinning; 1438–1486 captures a thread continuation via
interrupt and starts threads under locks. This establishes existing scheduling
mechanisms, not a proof of scalable or fully qualified same-VM execution on the
selected host. Independent VM, same-VM execution and scheduler capabilities
must remain distinct.

FS05. Continuation frames and collector coupling are concrete.

[_kernel.scm](../../../vendor/gambit/lib/_kernel.scm#L3145), 3145–3164, accesses
and mutates continuation frame/denv; 3463–3535 contains frame slot access and
mutation. [Previous map/continuation study](map-continuation-gc-design.md) and
[worker/root contract](shared-runtime-root-custody-design.md) retain writer,
root map, worker and last-use obligations. Mature continuation scan elimination
therefore needs actual mutation closure rather than a language-feature claim.

FS06. Foreign callback and native control duties.

[tcltk.scm](../../../vendor/gambit/examples/tcltk/tcltk.scm#L50), 50–195 and
289–343, supplies real native entry/callback/RC roots and result/control
handling. The [coroutine invariant study](tcl-coro-invariants-design.md) is a
specific stress case for native stack and logical activation pairing. It does
not define the whole Gambit modernization program or prove arbitrary effect
escape from C safe.

FP01. Learn collector tradeoffs from the parallelism research.

[Retrofitting Parallelism onto OCaml](https://arxiv.org/pdf/2004.11663), sections
3–4, develops collector/coordination/barrier alternatives under compatibility
and sequential-cost constraints. Its private-minor/read-barrier and parallel
STW-minor alternatives demonstrate that more concurrency can introduce new
load costs. Application here is an inference: choose Gambit's own nursery,
sharing and mature-heap profile together with its existing continuation/C
semantics. No benchmark magnitude or existing OCaml implementation is copied
as a Gambit result or mandatory architecture.

FP02. Learn control/resource boundaries from the effects research.

[Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf),
sections 2.3, 3.1–3.2, 4.2 and 5.6, distinguishes stack maps, managed/native
frames, resumptions and retained-resource cleanup. The design refuses effects
that capture C frames. Inference for Gambit: preserve general Scheme control
and define cheaper delimited modes with explicit native/resource limits; simply
adding a handler API or changing implementation language does not prove them.

FP03. Separate current OCaml language mechanisms and liabilities.

The official [parallelism chapter](https://ocaml.org/manual/5.3/parallelism.html),
sections 1, 4 and 6, distinguishes domains from concurrency, gives synchronized
sharing guarantees and warns that C global-state assumptions change under
parallel domains. The [effects chapter](https://ocaml.org/manual/5.3/effects.html),
sections 24.5–24.6, documents linear resumption and native callback restrictions.
These are scoped reference facts, not guarantees inherited by Gambit or a
claim that one-shot control replaces Scheme general continuations.

FP04. Zig interoperability is a mechanism, not automatic adoption evidence.

The official [Zig overview](https://ziglang.org/learn/overview/), C integration,
C compiler and C ABI export sections, documents importing C interfaces,
compiling C and exporting C-callable code. Those are three different engineering
choices. A build.zig file is maintained Zig source even if all runtime code is
C. None proves a Gambit speedup, removes its collector or licenses native stack
escape. Live examples are not a pinned project compiler/API support profile.

FP05. MLIR does not depend on a Zig language layer.

The official [MLIR C API](https://mlir.llvm.org/docs/CAPI/), Design/Scope and
ownership sections, exposes low-level IR operations through C-compatible
interfaces and explicitly disclaims current stability guarantees. C callers
are supported in the interface design. Therefore Zig is not a prerequisite for
access; either realization still owns its dialect/semantic wrappers, lifetime
and provider upgrade boundary. This is API evidence, not a qualified installed
provider or a claim the C API covers every dialect/service.

FP06. Gambit's own design supports semantic/target cooperation.

[Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
section 2 and its frontend/backend discussion, describes bidirectional target
information for primitives, closures, frames and calling conventions. The lesson
is a useful semantic/target interface, not freezing a historical machine layout
or moving all semantics into a backend. The current target source (FS01/FS02)
is the implementation evidence; this historical paper's performance is not a
modern Gambit forecast. The separate historical native-backend PDF could not
be fetched in this turn; no new claim depends on its unread contents.

FO01. Existing architecture and proof gaps are reused.

[Complete native system](modernization-system-architecture.md),
[shared operation contract](shared-runtime-contract-design.md),
[root/worker study](shared-runtime-root-custody-design.md),
[map continuation/GC design](map-continuation-gc-design.md), and
[C/Zig theory comparison](zig-vs-modern-c-net-benefit.md) are predecessor designs.
This study clarifies the user-directed mandatory C foundation and conditional
C-to-Zig evolution, and reconnects localized FFI findings to the whole runtime.
It neither revokes prior failures nor promotes full runtime, semantic-domain,
retirement, total-cost or Zig-increment gates. Source/conditional reasoning,
checked proof, native acceptance and performance remain separate evidence.
