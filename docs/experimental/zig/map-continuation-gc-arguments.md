# Conditional GC Closure for Map and Its Continuations

Handwritten conditional arguments and counterexamples. No model/prover,
compiler or native tests were run. The [design](map-continuation-gc-design.md)
and [source ledger](map-continuation-gc-evidence.md) identify the necessary
producers/readers. These local arguments do not establish whole-runtime closure.

CA01. **Root/young reachability.** Assume every live young or stack-region
reference lies in an acknowledged active/native root, owned capture anchor,
young object or admitted remembered non-young source; every reader understands
its exact TraceSpec/normal/internal frame representation. At the frozen minor
cut, induction over strong graph edges reaches all live young objects and
stack-backed captures. Materializing the latter adds their edges to the same
work set. A missing foreign cell or frame/denv mutation invalidates the premise;
rooting k's shell alone does not expose an unregistered stack chain. [CG02–CG07]

CA02. **Dynamic sharing and forwarding.** Assume one canonical destination per
source object/dynamic frame instance, valid source lifetime, initialized
destination bodies and counted pending edge-fix/scan work. All aliases then
resolve to the same promoted/materialized object after closure. Shared mutable
fields retain their identity. A forwarding address does not imply that its
body's referents were all processed: major readers/mutators cannot observe an
unfinished relocation graph. Counterexamples: use FrameSpec as dynamic identity,
deep-copy aliased shells' frames, or resume when only one worker is done.
[CE03–CE05; CG05–CG08]

CA03. **Remembered-source completeness.** Assume each published mature-to-young
strong write records a source location with retained owner/layout identity
before a cut acknowledgement; dirty reset cannot erase a later write. Minor
scanning updates every such location. Unchanged fully mature frames need no
recursive minor traversal after their prior processing. Counterexample:
`##frame-set!` writes a young value into a mature live slot and the next minor
classifies only k as mature, overlooking that slot. If this family is uncovered,
the selective-scan benefit must be withdrawn and a fully accounted conservative
strategy used. A nonmoving native address alone does not establish root liveness.
[CE05, CE09; CG09–CG10, CG13]

CA04. **Major snapshot and root deletion.** Assume a start cut publishes actual
retained mature root values, not mutable stack addresses; all snapshot work
survives processing; heap deletion, promotion/new-object publication and root
adoption protocols preserve required reachability during marking. The snapshot
graph's required mature objects stay traceable until the selected major close.
Dropping an already snapshotted active root needs no extra retention solely
because of that drop. Counterexample: enqueue the address of map's pending
result slot, resume and overwrite it before marking; the old value was never
snapshotted. This optional specialization covers neither arbitrary root writes
nor managed field deletion. Weak acquisition also needs its admitted policy.
[CG07, CG09, CG11]

CA05. **Scanner/mutation agreement.** Assume scanner/writer leases and C atomic
access rules agree; no frame/control metadata changes meaning mid-read; writer
capacity is prepared before a no-safepoint commit; lease holders cooperate with
minor rendezvous. Then a scan sees a permitted stable field/layout state and
barriers preserve required edges across mutation. Counterexamples: ordinary C
loads racing a raw frame setter; writer holds a lease while allocating and
waiting for a minor which waits for that lease; a reused remembered slot points
into freed storage. Exact orders, bounded buffers and fairness/progress remain
obligations, not properties conferred by a state-name table. [CG09–CG10]

CA06. **Replay and winding.** Assume saved source frames remain reusable,
destination frames/root frontier are enrolled before old carriers disappear,
and every dynamic-wind/exception/callback stage retains its live values/code
across control transfer. A legal repeated invocation restores the captured
computation without consuming its source or mutating earlier map results through
implementation reuse. Heap references can still share ordinary mutable user
objects; the contract does not clone user state or guarantee deep immutability
of result elements. Counterexamples: first return frees a native arena containing
captured results; winding collects while k/value exists only in a C temporary;
one-shot restoration invalidates the second invocation. [CE04, CE08; CG12]

CA07. **Reconstruction and mutation classification.** Assume `##implode-frame`,
frame/continuation setters and shallow-copy/next operations preserve actual
aliases and descriptor interpretation, initialize trace-visible words safely
and apply the proper private/published store protocol. They can coexist with
minor remembering and concurrent major scanning. Counterexamples: mark every
serialization write private despite a possible collection; copy a shell and
silently break its shared-frame alias; let a control-slot edit change the GC
map without validating the replacement. Interrupt masking is not a no-GC proof.
Complete caller and structural-slot acceptance remains open. [CE05–CE06; CG10]

CA08. **Termination and source reclamation.** Assume frozen producer membership,
accounted roots/remembering/capture/publication work, unique forwarding, no
unacknowledged native readers and all worker debts settled. Zero remaining
obligations then permits source-young and obsolete stack-storage reuse. Queue
emptiness alone does not: a worker may hold an unqueued scan or capture rewrite.
Once a forwarding/root update is public, partial failure must retain source
and destination custody, not rewind locally and run mutators against stale
references. Capacity reserve and bounded foreign response are additional
premises; no finite progress theorem is established. [CG06–CG08, CG11]

CA09. **Work reduction is conditional.** Given the same retained payload and a
history where it survives several baseline copy events, direct promotion plus
nonmoving mature storage reduces repeat copying. Complete remembering can also
replace mature captured-graph minor traversal with dirty-source visits. Added
early materialization, promotion, mutation/access, roots, major work and memory
pressure must still fit `G > A`. Counterexamples include k_i=0 early promotion,
tiny uncaptured maps, many dirty frames and long active stacks. No positive
time result follows merely from fewer copied bytes. [CB02–CB06]

CA10. **Scope of the result.** The selected map/capture/reconstruction paths
expose necessary obligations, not all writers or callbacks. Full weak/will/
ephemeron processing, raw foreign borrows, same-owner and cross-context control,
serializer integration and every primitive/runtime-role caller must join the
profile. Until then the whole modern collector and path retirement remain
unresolved. Learning from OCaml provides mechanisms/questions, not a proof
that Gambit's different object/control graph satisfies them. [CE01–CE09,
CG14–CG15, CL01–CL06]
