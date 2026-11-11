# Host Root Participation Source Map

## Scope And Relation To The Existing Recipe

This refines the current-entry research in
[Host Root Publication Recipe](host-root-publication-recipe.md). It does not
change the runtime, qualify the active native candidate, or add host attachment.
The existing lifetime model and its receipts remain unchanged. Its atomic
`publishAndBlock` coarsens an important source obligation: a published record
does not by itself establish that its host has stopped changing root values.

Keep three obligations separate:

1. The complete record and declared root-slot inventory become visible.
2. The host saves its final root state and hands off execution; the collector
   observes those stores before scanning. Visibility of the record alone is
   insufficient, even when its payload happens to match.
3. After relocation, the supported owner reloads state. Both the scanner and
   the returning host finish their last accesses before that record is freed.

These are logical edges, not a request for three physical locks or fences. One
existing mutex or collective can implement multiple edges when its participants,
ordering, root stores and ownership conditions are actually established.

Pinned reference revisions are Gambit `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`,
Chez `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, and OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Line ranges below describe these
sources, not the other thread's unqualified candidate overlay.

## OCaml: Follow Ownership Past The Master Lock

In `vendor/ocaml/otherlibs/systhreads/st_stubs.c:241-323`, the owner saves
stack, C-stack, GC registers, exception and local-root state before releasing
the thread lock; acquisition precedes restoration. The inactive-thread scanner
at lines 208-234 visits the registered non-active stacks, local roots and GC
registers. Active state was already scanned by the runtime root walker.

The complete ordering bridge is not just an atomic scan-hook pointer:

- `st_pthreads.h:123-147` runs the master-lock callbacks while its mutex is held.
- `st_stubs.c:75-103` connects those callbacks to domain-lock ownership and
  backup-thread transitions. Inspect the actual call argument, not just the
  misleading release-parameter name, when deriving the backup condition.
- `runtime/domain.c:1163-1226` acquires the domain lock before a backup thread
  services incoming interrupts in the blocking state, and rechecks its state
  while waiting for the entering-OCaml transition.
- `st_stubs.c:630-640` establishes the thread chain before installing the scan
  hook; `runtime/roots.c:32-67` separately walks active local roots/stack/GC
  registers, calls that hook, and scans final roots.

Thus atomic hook publication is not a proof that arbitrary mutable root values
are frozen or that an arbitrary C caller may attach. Domain ownership and the
saved-root census are separate premises. `st_stubs.c:376-404,441-453,666-702`
also requires ended C users and successor-owner installation before freeing
thread information. A saved C-stack pointer does not extend stack lifetime.

## Chez: Scheme Entry And Generated Root Interpretation

`vendor/chez/s/7.ss:812-840` enters collection under `with-tc-mutex` and checks
that one executor remains. `s/cmacros.ss:2210-2218` uses dynamic-wind around
interrupt exclusion and TC-mutex ownership. `c/gcwrapper.c:1187-1210` explicitly
relies on Scheme acquiring that mutex before `S_do_gc`; this is an entry
contract, not a promise that each sweep worker can acquire the same mutex.

`c/types.h:363-405` retains current code and updates active state under that
ownership. `c/gc.c:1239-1269` visits or routes registered contexts, while
`s/mkgc.ss:961-1024,2545-2546` generates the interpretation of stack frames,
C-chain, stack link, winders, attachments, handlers and other roots. Retaining
the TC pointer alone therefore does not establish a complete root graph.
The sweep restrictions in `c/gc.c:120-180` constrain a different execution role
from the Scheme entry lock; treating them as contradictory would lose the
actual caller contract.

`c/thread.c:209-244,261-341` has configuration-dependent activation and cleanup
ordering. Work/guardians are closed before freeing execution context; a retained
segment-creator carrier is not permission to retain or use an ended C frame.
Reuse the obligations, not Chez's stack layout or an unconditional global lock.

## Gambit: Existing Edges To Bind, Not Replace

| Obligation | Existing source | Required implementation correspondence |
| --- | --- | --- |
| Save physical roots | `include/gambit.h.in:8059-8064` | `GC_SAVE1` is an ordinary saved-slot store, not a cross-thread publication primitive. Enumerate all live slots, not just this example. |
| Generated C handoff | `include/gambit.h.in:6801-6803,10325-10349` | Bind the selected MR/PR expansion and CFUN path, RA, root maps and reload. `W_ALL` is not itself a hardware fence. Out-of-line entry differs. |
| Request participation | `lib/setup.c:1132-1151,1182-1198` | `garbage_collect` requests the operation on all processors. Raising the sync interrupt is not an acknowledgement that a host has saved roots or stopped mutating. |
| Observe participation | `lib/setup.c:1028-1029,1049-1129` | Follow `execute_sync_op_loop`, `barrier_sync_op` and the actual collector participant set; pending operation, barrier arrival and operation execution are distinct events. |
| Interpret roots and finish phases | `lib/mem.c:3969-3989,4525-4564,6508-6663,6938-7038` | RC/root consumers and existing GC phase barriers already exist. Bind the complete current root graph, stores and observation edges before proposing another mechanism. |
| Reload and last access | `include/gambit.h.in:8059-8064,10325-10349`; `lib/setup.c:3294-3422`; `lib/c_intf.c:6510-6570` | Restore selected generated state and retain each record through its own last access. Marker death is not proof that the returning C path ended. |

The current native owner's root-transfer repair is not duplicated here. A
complete source refinement must inspect that exact candidate and configuration;
this baseline source map cannot grant it acceptance or identify a native cause.

The root-consumer map is broader than the two logical model roles:
`mem.c:6508-6663` separately scans processor registers, saved slots, type cache,
processor object, VM object, global cells, and symbol/keyword tables. Global
cell scanning differs between `SINGLE_VM` and multiple-VM configurations. RC
roots, generated stack maps and phase-private work remain additional inputs;
this list is an observed consumer inventory, not a completeness declaration for
all supported producers or candidate configurations. Chez's generated root
walker and OCaml's active-plus-inactive walkers show why each producer, slot
interpretation and backing lifetime must be connected, rather than counting
context pointers as a complete graph.

## Executable Composition And Limits

`models/gambit/host_root_participation.qnt` imports the unchanged current
root-publication/lifetime composition and a second, independently identified
instance of its existing publication abstraction. It separates record
publication, one possible last root-value store, freezing, execution handoff,
collector observation, owner return and record reclamation.

A single initializer chooses an immutable scenario tag: corrected handoff (0),
record mistaken for readiness (1), or missing handoff acquire (2). This avoids
Quint's shared-init conversion restriction without copying imported machines.
Safety/progress are checked for cohort 0; each negative property is conditional
on its own omission cohort. The successful changed-root cleanup witness must
come from cohort 0, so omission cohorts cannot supply the positive witness.

Controls distinguish scanning a published-but-still-running host from observing
the final state without an acquire edge. A positive reachability control must
also demonstrate a changed root being observed and the record eventually freed;
retaining every record forever is not the design. The finite census, legal
owner, root relocation/reload and actual C ordering remain assumptions. A ghost
transition rank changes on every nonterminal protocol move, including imported
metadata-only moves; terminal stuttering leaves it unchanged. Thus weak fairness
does not omit the last reclamation step. Its boundedness follows from the
acyclic protocol cohort, not a CPU limit. It is not a native progress witness or
heartbeat, and proves no OS scheduler or C weak-memory refinement.

`models/gambit/lean/HostRootParticipation.lean` reuses `WorkAccounting` and
states conditional consequences for arbitrary live slots: a frozen complete
handoff composed with relocation gives the expected observed roots. Equal
values alone do not supply acknowledgement. It does not establish those
premises for generated C or refine the QNT transition relation.

## Handoff Recipe And Acceptance Boundary

For the current 9/12 repair, hand the implementing thread this bounded task:
enumerate supported entry/configuration paths and physical root producers;
identify where each owner stops mutation; map that edge to the collector's
actual observation/participation protocol; map relocation to resumed generated
state; enumerate per-record final consumers and failure/nonlocal exits. Record
uncovered paths explicitly instead of inferring completeness from an empty list.

A source change is justified only by a missing correspondence, not by the mere
presence of a non-atomic saved-slot store. Unified fixed sources/configuration
and full rebuild remain the implementation acceptance contract. Existing model
qualification is reusable research, not a replacement for that thread's native
stress, exception/FFI paths, final cleanup and performance acceptance. This
research runs none of those tests and changes no runtime source.

General foreign-thread attachment, new stable root carriers, registry epochs,
backup-thread service and a new root ABI remain mechanism-level decisions in
[Experimental](experimental/host-root-registration.md), not current repair
features. Their existing partial models are not evidence of implementation.
