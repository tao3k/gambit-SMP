# Checked Processor Initialization Candidate

## Model-First Admission Order

The local candidate below is not permission to advance runtime changes. First
review paper-derived protocol obligations against pinned source and recorded PR
failures. Then check independent fault controls, composed safety and explicit
progress assumptions. Audit caller/callee ownership and source correspondence
before implementing the complete repair. Extracted-source checks, rebuilt native
binaries, bootstrap and Gerbil acceptance follow in that order. A local model or
fixture result cannot admit an incomplete composition or replace native green.

`patches/candidate-checked-pstate-init-owned-rollback.patch` is an isolated candidate
over runtime026, not an admitted release patch. It modifies `lib/setup.c` only.
The seven-control, 91-state setup model precedes this implementation; the unchanged
OS/memory helper fixture establishes its delegated rollback boundary.

The candidate checks POSIX interrupt-mutex and sync-mutex initialization, stops
before condition initialization on mutex failure, and releases the successfully
initialized sync mutex when condition initialization fails. Error return codes
use Gambit's existing `___UNKNOWN_ERR` contract; pthread errno cannot be recovered
from the existing boolean macros. Windows and other void initialization macros
remain outside the boolean-check branch.

`___setup_pstate` propagates errors before success can reach resize publication.
The failed-setup helper cleans OS/memory only if their combined setup completed;
it does not double-clean the OS resource already unwound on a memory setup error.
Only the owned interrupt queue is drained, before memory cleanup; its mutex is
released afterwards. VM0 processor0's borrowed interrupt queue/mutex is preserved.
The early global interrupt constructor also propagates initialization failure.

GNU GCC 16.2.0 successfully compiled the complete actual `setup.c` translation
unit to `setup.o`, and the patch applies cleanly to the exact baseline. The
generated header/preprocessor selects multiple VMs and multiple-threaded VMs;
the inherited configure command includes SMP. This is not a rebuilt-executable
or runtime flag qualification. Compilation elapsed time was not recorded.
Artifact hashes and the explicit acceptance boundary are in
`evidence/model-results/pstate-init-candidate-027.json`.

## Required Next Gates

Actual candidate fault injection must check both sync initialization failure sites,
interrupt failure, owned and borrowed rollback, and the void-macro branch. The
current C compilation does not substitute for those semantic checks.

That local gate now passed with GNU GCC: the actual candidate helpers AND
`___setup_pstate` caller were extracted unchanged. POSIX passed 20 checks
(1.299-second compilation, 1.109-second execution); the void initialization
compatibility branch passed 10 checks (2.124-second compilation, 0.737-second
execution). These use mocked primitive resources and layout, not native POSIX
threads or a Windows OS run. A named injected policy which ignores sync init
errors compiled successfully and failed the expected-error assertion at runtime
(0.452 seconds). Evidence is `pstate-init-source-027-pass.json` and three portable
logs under `evidence/model-results/`. The preceding fixture compile denial is
preserved separately; missing mock handler fields and inherited signed-index
warnings were corrected in the fixture, not candidate C.

## Newly Confirmed Caller Gate

Local success cannot admit this candidate. The outer global setup prefix owns
`vm_list_mut` and the early VM0 interrupt mutex, while public cleanup is disabled;
an early interrupt-init error must unwind the already-created list mutex. Global
OS/memory setup failure also needs that global ownership cleanup. The separate
`setup_outer_ownership` model covers this prefix, not the entire constructor.

There is a later, distinct source-backed handoff gap. `___setup_vmstate` sets
`processor_count` to 1 before P0 setup and directly returns P0's error. Candidate
P0 failure has already cleaned its OS/memory, but `___setup` subsequently calls
`___cleanup` on error. The unchanged global cleanup interprets count1 as a ready
P0 and enters processor shutdown/cleanup again. A VM-constructor-only correction
to count0 is also insufficient: current `___cleanup` then returns early, retaining
global resources. This is source reachability evidence, not a native reproduced
crash or attribution to the historical compiler failure.

`pstate_vm_failure_handoff.qnt` and its manifest model these two ownership layers,
including the existing VM-helper-failure count0 path. Its positive protocol is a
required repair contract, not implemented C. It assumes callee partial allocation
rollback, successful destructors and externally quiescent global setup; normal
shutdown list-lock ownership, arbitrary allocator failures, other VMs and GC
remain outside this bound. Verification and source-bound caller regression are
required before promoting a rebuilt binary or full bootstrap candidate.

The first composed check completed in `.data/pstate-vm-handoff-model-001`:
all three independent negative controls produced their expected counterexamples.
The positive protocol exhausted 23 distinct states (27 generated, zero queued)
and completed safety and temporal progress in 22.487 seconds. Model and input
context remained stable; worker capacity was detected from the host. This is
bounded protocol evidence only: the complete positive repair is not implemented
in candidate027, and native/runtime/release admission remains false.

Fresh unpublished-slot ownership is a required precondition. Existing slot reuse
and synchronization resource retirement remain an independent repair obligation:
this candidate does not add a destructor to child cleanup or establish sender
drain/quiescence. It does not qualify repeated initialization of retained objects.
Do not merge or promote it while that obligation remains open.

Rebuild and bind actual binaries before GC/multi-VM tests and complete bootstrap;
do not execute the copied old binaries and label them candidate tests. Full Gerbil
correctness and performance acceptance remain pending. No package-specific branch,
machine CPU count or test-file exception is introduced.
