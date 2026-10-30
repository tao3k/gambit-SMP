# Candidate Root Census And Final Consumers

## Identity And Scope

This continues [the handoff source map](host-root-participation-source-map.md)
against the retained mutex-return candidate, not merely the pinned baseline.
The reproducible identity is
`evidence/research/processor-interrupt-collective-wait/runtime-mutex-return-source.lock.json`
(SHA-256 `df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466`),
Gambit revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, and its versioned
`patches/fixtures/runtime-mutex-return-cumulative.patch`
(`49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`).
All 26 locked candidate files matched the retained source observation. The
unchanged `_t-c-1.scm`, `_t-c-3.scm` and `setup.h` also matched the pinned
submodule. No copied source tree or cache path is a reproduction prerequisite.
Line ranges below refer to the candidate reconstructed from this lock, unless
a vendor prefix is explicit. A newer handler-quiet patch exists separately;
its different identity is not silently incorporated into this research.

This is a current 9/12 research profile. It neither recounts that owner's native
gates nor claims that the unqualified source slice is the newest executable.
It does not modify runtime sources, locks, checkpoint or native test budgets.
The source lock explicitly does not reproduce the configured toolchain. Header
branches and generated-module register lists therefore remain configuration
premises, not evidence that every effective preprocessor expansion was checked.

## Physical Root And Work Graph

The table is the inspected consumer census and its producer obligations. A
consumer inventory is not an assertion that every listed field is live at
retirement, nor proof that no producer outside this inventory exists.

| Class | Producer, interpretation and consumer | Disposition and final-consumer boundary |
| --- | --- | --- |
| Active Scheme stack and captured continuation | `_t-c-2.scm` return-label generation supplies frame size/link/map; unchanged `_t-c-3.scm:471-500` builds map bits/chunks and `_t-c-1.scm:1933-2013` emits inline/out-of-line descriptors. `mem.c:4078-4390` interprets captured and active frames using RA and maps. | A relocated pointer alone is insufficient: its descriptor and backing storage must also be valid. The resize helper is not evidence that every saved stack was copied. Establish the surviving continuation owner or a valid absence argument for each retiring activation. |
| GVM registers and saved C roots | Header `6833-6834,8090-8095,10394-10418` selects generated register save/reload and the saved-slot operations; `mem.c:7181-7223` scans `r`, `saved`, `type_cache`. | These are traced slots, not automatically transferred by list splicing. Actual generated MR/PR register lists and nonlocal exit are separate premises. A stale non-live slot need not be copied merely because it is nonzero. |
| Processor and VM Scheme objects | `setup.c:1209-1236` removes a retiring processor from the VM deque before OS exit; `mem.c:7226-7257,7556-7574` scans processor objects on each processor and the VM object on P0. | Deque unlink is not proof that every externally referenced processor object or saved activation ceased to matter. Bind the actual remaining heap owner and callers; do not replace that audit with the processor count. |
| Global cells and symbol/keyword roots | `mem.c:7261-7347` partitions globals, using acquire loads of count/table/segments in the multiple-VM branch; P0 scans shared symbol/keyword roots. | Global metadata and per-VM value slots have different owners. A published segment/table does not prove every value store is ordered against a collector. Bind actual writers, admission and configuration. |
| Registered C/RC roots | `c_intf.c:6511-6550` saves `proc_or_false` across allocating the marker and reloads it; `mem.c:4393-4411,7562` scans each processor's `rc_head`. `mem.c:5499-5548` moves the donor RC list to its receiver. | The old P0-only RC-scanning deficiency is already repaired. Do not propose it again. The donor list is reset only after splice; recipient ownership keeps these data roots visible on later collections. This says nothing about unrelated stack slots or ended C catchers. |
| Still objects and their refcount roots | `mem.c:4636-4675` builds/consumes the still scan chain. `transfer_mem_pstate:5517-5534` splices `still_objs` and transfers both immediate/deferred accounting. | The linked allocation list is not the same object as an active `still_objs_to_scan` chain. A phase-correct drain or live owner is required before freeing donor memory; the transfer function's comment is not the caller proof. |
| Heap chunks and private scan work | `mem.c:3567-3609` publishes under the queue lock with ordered stores; `mem.c:7350-7460` claims/scans work, including local scan progress; `mem.c:7556-7581` inserts the root-copy barrier before parallel traversal. | An endpoint probe is only a hint; queue ownership and callback completion matter. The candidate already has the strong-root copy barrier. Stale cursor values after a completed phase do not alone demonstrate live work. |
| Weak work, wills and GC hash tables | `mem.c:5680-5740,7589-7660` processes wills, continuation movement, reached tables and unreachable still objects after strong marking. | Strong-root completion does not cover weak/cleanup phases. Establish callback completion at the actual transition into resize; do not infer it from an empty strong queue. |
| Foreign return marker and C origin | `c_intf.c:6511-6570` constructs and invalidates the marker; `setup.c:3757-3899` installs the Scheme-to-C return frame, handles marker-matched unwind, restores FP/RA and returns. | Marker invalidation ends that marker role, not every C tail/catcher. The SFUN admission gate counts live foreign frames and cannot grant arbitrary host attachment or cross-thread unwinding. |
| Sync slots, locks and condition variables | `setup.c:701-733,751-939` publishes barrier messages; `5140-5173` initializes once and destroys at VM cleanup, not ordinary shrink. | Receiver exit/join can precede a remote sender's unlock/signal. The channel storage outlives per-processor memory cleanup. VM teardown needs its own closed-admission/all-users contract; joining the receiver alone is insufficient. |

The generator bridge is real but conditional: map generation tests liveness;
emission preserves frame kind/size/link and map representation; the collector
reads those through the actual RA convention. None of those individual steps
proves all live slots were declared, that the selected compiled module matches,
or that an external C frame still exists. Keep C generation, continuations and
the supported FFI rather than importing another runtime's object/stack layout.

## Actual Ordering And Its Limits

1. Generated `W_ALL`/`GC_SAVE1` stores are ordinary root publication into the
   supported processor state, not standalone hardware synchronization.
2. `setup.c:701-733` uses a release store for the sync flag and an acquire load
   when receiving it. Payload assignment precedes send; payload consumption
   follows receive (`751-939`). `lib/setup.h:64-66` selects the no-op single-
   threaded barrier or `barrier_sync_noop`. The threaded bridge is concrete;
   the arbitrary-call-site root-saving and full C memory model are not proved.
3. Collection recovers FP/HP, sets up heaps, marks strong and weak roots, cleans
   up and resizes under distinct barriers (`mem.c:7655-7821`). It republishes
   resumed stack/heap state through `PREPARE_MEM_PSTATE`. The additional strong-
   root barrier precedes cross-processor graph scanning, not just GC return.
4. A subsequent tree arrival can attest that a participant finished its prior
   callback; P0 arrival represents the old cohort only when every child
   publishes after its own callback and aggregates its children. Do not replace
   this with a flag meaning only P0 returned.
5. Resize's heap guard (`setup.c:1173-1198`) invokes GC conditionally. In
   particular, this is not a mandatory saved-continuation promotion on every
   shrink. `resize_saved_stack_retirement_isolated.copyFrames` needs its own
   source correspondence. If a live raw donor continuation exists, identify
   the actual copy/retention mechanism or record that premise as unclosed.
6. P0 sets pending join state, changes the processor population through the
   collective, joins the retiring thread, then transfers RC/still ownership and
   cleans donor memory (`1266-1305`). Join failure leaves ownership pending;
   recovery repeats transfer only after join succeeds (`1106-1133`). Neither
   joining nor splicing enumerates the complete root graph.

The old cohort/callback argument concerns old GC queue users. A later message
sender tail concerns channel objects. These are different last consumers:
proving the former does not discharge the latter, and retaining channel objects
does not retain an ended Scheme/C activation. The source profile reuses
`scan_barrier_quiescence`, `sync_slot_retained_resources` and
`resize_saved_stack_retirement_isolated` separately to preserve these scopes.
No universal new barrier, global lock, TLS rewrite or forced full GC is selected.

## Chez And OCaml Counterchecks

Chez `vendor/chez/c/thread.c:261-341` removes the registered context under
`tc_mutex`, processes remembered data, closes allocation and transfers guardians
before freeing `tc`. Its `thread_gc` stays as a recycled segment-creator carrier.
Keeping that carrier does not keep an ended C stack alive. The actual generated
root interpretation remains `s/mkgc.ss:961-1024,2545-2546` and its collector entry
contract remains Scheme's TC-mutex protocol, not permission for sweep workers
to acquire arbitrary runtime locks.

OCaml `vendor/ocaml/runtime/domain.c:2262-2366` finishes/orphans work, repeats
when orphaning creates more work, and serializes participant removal against
incoming STW requests. A finished local scan is not global participant closure.
At `1346-1455`, the termination result is rooted through domain teardown and
the **final mutex unlock**; only afterwards is the root removed. Earlier callback
inputs have a shorter lifetime. This is a concrete counterexample to assigning
all roots a universal 'until join' or 'until GC returns' release point.

The transferable low-cost method is per-class disposition plus per-record last
consumer, with an actual ordering edge. OCaml's major/minor organization and
Chez's segment carrier are not drop-in Gambit mechanisms.

## Current Repair Handoff And Experimental Boundary

The implementing thread should receive the following open correspondence, not
another test campaign:

- For active/saved continuations, establish heap promotion, retained backing or
  valid absence at each supported retiring path. The conditional resize GC
  cannot discharge this by itself.
- For the entire physical inventory, record absent, receiver-owned-and-traced,
  or retained-under-a-live-owner for every applicable class. RC/still splice is
  an implemented subset, not a general root-copy routine. A valid empty class
  is allowed; mere lack of an observed failure is not its absence witness.
- Bind final root stores, descriptor liveness, generation and reload to the
  actual generated module/configuration. The acquire flag orders eligible
  preceding stores but does not discover omitted slots or fix an ended origin.
- Separate completed collector borrowers, joined donor, remote channel sender,
  returning host and VM teardown. Preserve error, nested FFI and continuation
  semantics, and forbid double transfer/cleanup after a failed join.

This narrows proof obligations; it does not identify the cause of an active
native failure or establish which remaining gate is closed. Current models stay
under `models/gambit`; the new Lean census contract is conditional source
classification, not another collector design. Existing source-bound formal
receipts remain historical and unchanged.

General independent root carriers, new attachment/migration rights, changed
root ABI, per-domain heaps or a new generational collector remain in
[Experimental](experimental/host-root-registration.md). This source audit does
not select those mechanisms, duplicate their models or impact native acceptance.
