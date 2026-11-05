# Repair-9: mark_array entry provenance and first-fault diagnostic contract

2026-10-23, Asia/Shanghai. Research only; native acceptance remains **8/12**. This extends the [verified producer/crash study](smp-repair9-tfib-crash-binding.md). The failing gsi remains SHA256 `5620dd70a28f46765551c07742bfc4b5877096008900f9addd486d90de1bf5ad`, UUID `c823a9d8-418b-35f6-88bf-1330cef04de5`, crash PID 66761 / shard parent 66760, `mark_array +104`. All line numbers below refer to the immutable archive-bound source captured in audit `f41ad62f11d049ee96c824b3a4587878`, unless explicitly marked as a proposed edit. No runtime/header/compiler/framework/Recipe changes, native execution, debugger attachment, signal or implementation-thread operations were performed.

## Result and the limit of reverse attribution

The saved fault proves an invalid header read after selecting a memory-allocated-looking word. It does not select the caller category. The audit enumerates **29 direct mark_array call sites** in the bound `mem.c`, plus an implicit cursor transition inside mark_array. Important new distinctions:

* `mark_array` can copy a pointer-bearing object, replace `cell` with the new copy's first field, and `goto again`. The original caller might be a register root, while the actual faulting cell is now a heap field. Its origin and its current cursor are different facts.
* The `scan_and_advance` pair fast path calls mark_array without entering ordinary `scan`. A `container_body` value left by a previous F64 scan would be stale evidence for this pair.
* Heap `___sFRAME` scanning has both GC-map-selected frame slots and a separate `&body[0]` return-label scan. Captured-continuation forwarding/link slots are another route. “Frame path” is not automatically “compiler GC map bug.”
* An invalid pointer field can contain bits that look like a double after an earlier overwrite. Those bits alone cannot distinguish a real F64 payload selection, wrong frame/map, bad root, wrong object extent or corrupted pointer field.

Existing debug fields are already **per pstate**, not a shared global: `reference_location_`, `container_body_`, `mark_array_call_line_` (`gambit.h:11464–11466`, mem.c aliases:315–319). They supply categories under `___DEBUG_GARBAGE_COLLECT`. They do not retain the current dynamic cell, tail-copy ancestry, complete selected span, frame descriptor generation or a crash-surviving snapshot. `mark_array_debug` stamps `__LINE__` (3624–3663); a line number does not replace those missing facts.

## Complete entry map and the exact fields to stamp

The [machine-readable entry map](../evidence/research/smp-retirement-study/mark-array-entry-map.json) retains each direct call's text, line, function/category and source hash. The grouped correspondence is:

| Entry / bound line | Selected cells and required provenance | Earliest useful capture |
| --- | --- | --- |
| mark_captured_continuation:3967 | Existing heap/forwarded continuation reference at `orig_ptr`, count 1. Preserve link/continuation identity; do not call this a scalar payload or ordinary frame-slot span. | Before delegating to mark_array; stack-copy branch separately records frame origin/forwarding. |
| mark_frame:4012,4034 | Contiguous GC-map-selected frame runs. Preserve `fp`, `fs`, frame/link/RA kind, original and current map word, map-word address/ordinal, `nextgcmap`, run `[j,i]`, selected start/count. | At frame entry and before each run; refresh when advancing to another map word. |
| mark_rc:4138 | `&h->data`, count 1. Record RC node address and owner pstate; an unscanned C payload is not itself a root. | After reading a valid current node, before the data-field call. |
| scan weak/will/hash:4207,4210,4231,4237 | Will action/testator or table key/value slot; retain subtype, header, words, index and `traverse_weak_refs`/table scan flags. | At dispatch using already-read arguments and each selected field. No strongification of weak fields. |
| scan symbol/key:4247 | Name field only, count 1. | At dispatch; a corrupt raw hash/character field is not an intended selected slot. |
| scan continuation:4252 | `body+1`, `words-1`, skipping the raw frame/link field. | Record body/header and the skipped prefix before subscan. |
| scan heap frame:4294,4299 | `mark_frame` selected payload, then the separate return-label cell `&body[0]`. Distinguish these two current-cursor roles. | Before descriptor decode, frame-run delegation and the final return-label call, respectively. |
| scan closure:4320 | Only free variables, `[CLO_FREEVARS, words)`. | Preserve closure header, prefix length, checked arithmetic and actual count. Do not read the low-level trampoline as a Scheme free variable. |
| scan generic:4327,4329 | First pointer field may already have been tail-marked for MOVABLE0/subtype <= BOXVALUES; one branch starts at `body+1`, otherwise at body. | Preserve **which branch** selected the interval, not just subtype. |
| scan_and_advance:4354 | Pair fast path scans `(ptr)+2`, `PAIR_SIZE-1`; its first field was handled by the copy/tail path. | Explicitly stamp PAIR context here; ordinary scan() never ran. |
| process_wills:5422,5428,5438,5448,5458 | Will-list local reference or testator at the current list node. Record executable/nonexecutable side, list/link role and weak phase. | At each selected local/list-field call, without traversing extra links for printing. |
| mark_registers:6915 | pstate register array with exact slot index/count. | At root wrapper; clear stale heap/frame context. |
| mark_saved:6930 | pstate saved-root array. | At wrapper, including array identity and owner. |
| mark_type_cache:6945 | pstate type-cache roots. | At wrapper; a “double-looking” invalid cache entry is still a cache-origin failure. |
| mark_processor_scmobj:6960 | Processor object's exact fixed root span. | At wrapper; retain PROCESSOR_SIZE and source identity. |
| mark_vm_scmobj:6978 | VM object's fixed root span. | At wrapper; retain VM_SIZE/VM identity and phase. |
| mark_global_variables:7019,7048 | Global value cell or segment slice. | Record selected global index or segment/offset/length; do not dereference a symbol name to label it. |
| mark_symkey_tables:7068,7069 | Address of symbol/keyword table root, count 1. | Distinguish the two root IDs before delegation. |
| mark_array:3757–3778 / `goto again` | **Implicit dynamic entry** to a copied object's first field. | Stamp previous parent object/header, source and destination, field 0, readiness and forward outcome before changing `cell` / looping. Keep original entry ID separately. |

Frame address arithmetic matters: bound `___FP_STK(fp,k)` is `fp[-k]`. The inclusive run at 4012 starts at `fp-i` with count `i-j+1`; the other run starts at `fp-(i-1)` with count `i-j`. `mark_array` advances upward in memory, which reverses the frame-slot ordinal. A recorder must preserve both raw address and selected ordinal; assuming `cell-start` is the original frame slot would mislabel the failure. Integer address differences require checked arithmetic; unrelated C pointer subtraction is not a safe validator.

The scalar skip in `scan` at 4188–4189 is already present. Direct intact F64 dispatch should never produce a payload mark_array call. A trustworthy snapshot of a F64 payload selected for header reading therefore needs the actual current container/header/offset and branch; a stale `container_body` or numeric word pattern is insufficient.

## First-invalid-scan record: fields, sources and unavailable values

The proposed helpers below are names for the design, **not implemented functions**. The [diagnostic plan data](../evidence/research/smp-retirement-study/first-invalid-scan-plan.json) maps fields to capture sites and separates existing fields from proposed metadata.

| Record group | Required fields / actual source | Why required |
| --- | --- | --- |
| Identity | Run/producer gsi SHA+UUID in carrier header; VM/pstate address, processor ID; per-pstate operation sequence; local GC sequence, GC phase, cohort/semispace; commit sequence/version and presence bits | A prior epoch or another worker's complete record is still the wrong evidence. Addresses/PIDs alone can be reused. |
| Original entry | Stable root/call-site ID, source line, outer root array/slot or RC/global node identity | Describes how the traversal started. Must be reset by root wrappers. |
| Current cursor | Cell address, scan start/count, consumed index, role (root/heap/frame/RA/link), last known parent body/header/type/length and selected branch/skip prefix | Describes the value actually about to be read, including pair fast paths and copy-tail transitions. |
| Pre-cell operation | `CELL_PENDING`, exact cell/span, **rawWordPresent=false** | If `obj=*cell` faults due to an escaped extent, there is no safely captured input word. Record before dereferencing cell. |
| Pre-header operation | `HEADER_PENDING`, exact original tagged word as 64-bit hex, tag configuration, computed header target, word-present=true | Commit after the actual cell read/tag test but **before** `head=body[-1]` at 3686. Do not infer the original low bits from the fault address. |
| Header/forwarding | After a successful header read only: captured old header/type/size and forwarding outcome. For tail traversal: source parent and copied destination/field, copy complete/queued/scanner state | Never read the suspected target again to populate a diagnostic header. An unavailable header stays unavailable. |
| Frame/map | Current and saved `fp`, break/stack bounds, original/actual RA and internal-return branch, `fs/link`, selected map word and source address/ordinal, run start/end, frame allocation/capture generation when known | Valid-looking map bits can belong to the wrong RA/frame. Descriptor generation must be proven, not inferred from an in-range address. |
| Allocation/write witness | Region/section, semispace, allocation identity and serial/generation when instrumented, reservation interval, first observed violating write site/target/width, relation to selected cell, sequence/order proof | Same address, wrong generation; same object, disjoint write; or an unordered/later write cannot establish the fault's writer. |
| Coverage | Context chain depth/truncation, map-word availability, carrier/commit validity, unsupported region/generation and missing ordering flags | Unknown metadata must cause an incomplete diagnostic, not an invented classification or PASS. |

`nb_gcs_` exists as a VM floating-point statistic: it is incremented by P0 at GC end (mem.c:7491), not a ready-made globally committed diagnostic epoch. Keep it as an advisory observed value. A proposed integer diagnostic GC sequence must be published consistently at the existing collective boundary, or record pstate-local sequence/phase and mark cross-worker epoch joins unresolved. Do not reuse startup/scheduler/resize epochs as if they were GC allocation generations. A lifetime serial for still/permanent allocations is **not** already supplied by these debug fields; unknown remains unknown until a covered allocation path records it.

## Minimum viable diagnostic: preserve the pending load without a new crash handler

A last-attempt record in ordinary process memory will not solve this incident: the retained Apple IPS has registers/stacks but no pstate/heap bytes. Simply enabling `validate_old_obj` is also insufficient. That routine eventually dereferences an unclassified target outside known msections (mem.c:3110ff), while `bug -> explain_problem/print_object` may follow corrupt objects. A secondary diagnostic fault can destroy the primary context. The existing optional `os_setup.c:crash_signal_handler` calls `___fatal_error` and may print backtraces/history; do not assume it is an async-signal-safe fixed-record exporter or change its failure semantics blindly.

The smallest proposed first-stage carrier is a **preallocated, bounded shared file mapping** with isolated per-pstate records in the existing diagnostic run's output. It avoids a new SIGSEGV/SIGBUS handler, per-object text logs, locks/allocations inside GC, and reliance on a normal-return finalizer. Two committed slots per pstate can retain the last completed record and an in-progress record. An output consumer reads only after the native process/group has terminated naturally or been reaped under the original supervisor.

Proposed edit surfaces, if later authorized for a source-bound diagnostic producer:

1. **State and lifetime:** diagnostic-only raw record layout near the existing per-pstate debug fields in `include/gambit.h.in`; bounded carrier setup in `___setup_mem_vmstate` / `___setup_mem_pstate` (4892/4757). Preallocate/map outside GC. Retain file contents on crash. Normal cleanup at `___cleanup_mem_pstate` / `___cleanup_mem_vmstate` (5277/5295) may unmap only after the last writer is gone. Failure to provision/persist the carrier is a diagnostic limitation, not native success. Diagnostic snapshots are raw observations, not additional Scheme roots to be scanned or resumed.
2. **Provenance:** private `gc_diag_begin_context` / `gc_diag_note_frame` / `gc_diag_note_tail` in mem.c at the entries above. Store fields already read by the real code. Root wrappers reset heap/frame metadata; pair fast path stamps its own header/interval; `goto again` changes cursor parent while keeping the original root. A nested context token must be copied inline or checked against its matching snapshot; a pointer into an overwritten context ring is not sufficient.
3. **Pending operations:** private `gc_diag_pre_cell` immediately before `obj=*cell`; `gc_diag_pre_header` after tag acceptance and immediately before the header read. Fill the inactive record, then commit a matching sequence/footer using the required compiler/architecture ordering. A pre-header record cannot cover a fault in the earlier cell load. Record `HEADER_READ_OK` only after the original read succeeds; do not prefill a guessed header.
4. **Collection/admission:** retain the exact carrier as an existing output artifact and match run/gsi/UUID, owner, epoch, sequence, operation and actual fault PC/address before admitting it. Torn/stale/mixed records yield UNKNOWN. A timeout between record commit and load is a pending operation, **not proof that that load faulted**. Freeze the crash-selected record; do not overwrite it with handler/pretty-printer activity. Do not skip the invalid value, repair a pointer or continue collection.

Compiler and native-memory correspondence remain explicit gates. Source order or `volatile` alone is not a store-before-fault proof. The diagnostic build must verify in disassembly that payload/commit stores and the selected barriers precede the cell/header loads, and a matched control must verify carrier survival after a real child fault. File mapping/preallocation and platform atomic/coherence behavior must also be checked; the QNT does not prove Darwin persistence. Do not add a memory probe, heap walk or unknown-header dereference while constructing the record. Unsupported metadata gets a presence/coverage flag.

The bounded record adds stores/order constraints to a hot path and may change timing. Inline full snapshots are simpler to admit than separately overwritten context buffers but may be costly. No claim of negligible overhead is made. Original budgets stay fixed; a diagnostic timeout is retained as timeout and cannot rule out the bug. This plan is **not activated** in this research run.

## Conditional second stage: locate an earlier write only after origin is known

Stage one identifies the faulting traversal. It cannot guarantee the earliest illegal access or first corruption across all workers: a previous bad pointer may reference mapped memory, an overwrite may occur outside covered stores, and per-pstate sequence is not a global clock.

If a complete record identifies a pointer-bearing field whose type/extent is intact, add a focused **diagnostic** first-write witness at the implicated source surface, not a general root-cause claim based on 0.02:

| Implicated edge | Concrete capture/check site | Required discrimination |
| --- | --- | --- |
| Current mutator stack spill | `gambit.h` `___SET_STK -> ___FP_SET_STK` (6765/6759), using `fp[-offset]`, with source file/line and active region identity | Check actual target/width against the correct frame/section/reservation and generation. Current processor's stack limit is not a universal bound for captured heap frames. Unknown ownership is not OOB proof. |
| Constructor heap burst | `___BEGIN_ALLOC_STRUCTURE` / `___ADD_STRUCTURE_ELEM` / `___END_ALLOC_STRUCTURE`; generated thread constructor 14119–14157; typed F64 burst 14165–14173 | Capture 38-word structure and 8-word F64 footprints and original allocator state before writes. A safe default policy cannot fix an allocation outside its reservation. No producer change is proposed merely because the constructor is allocation-heavy. |
| GC object copy | mark_array copy reservation/CAS/body loop (3685–3778) | Record source header/size, destination reservation, winner/loser outcome and published chunk. CAS-before-copy is legal; do not call it an ordering bug without a consumer-before-ready witness. |
| Captured-frame copy/restore | mark_captured_continuation:3821–3967; THREAD_SAVE/RESTORE macros | Bind RA/fs/link/map and saved frame to the actual allocation/capture generation. Distinguish copied stack frames, heap frames and forwarding slots. A same-address old-generation writer is not the current writer. |

Check arithmetic without overflow and without introducing unrelated-pointer subtraction. Record the attempted violating write before it executes; failing closed is a diagnostic abort, not successful computation or an automatic production repair. Correlate address interval **and** allocation generation **and** a demonstrated preceding relation. A record from another pstate with only a smaller local sequence cannot establish ordering. Uninstrumented/raw C/FFI stores remain explicitly outside coverage.

## Discriminating QNT and executed evidence

The [observation-protocol QNT](../models/gambit/tfib_scan_origin.qnt) and [named trajectory module](../models/gambit/tfib_scan_origin_tests.qnt) complement the existing 19-check GC/handoff envelope. They model two actual epochs/recorder owners, separate original entry/current cursor, pre-cell/pre-header commits, F64/frame/root/pair/extent routes, matched versus unavailable writer evidence, freeze/failure disposition and a surviving versus unavailable carrier.

The classifier reads captured context, not a hidden scenario label. The **same invalid word class** can yield F64 selection, frame-path failure, root contamination, an extent failure, a matched prior-write witness or a heap-field origin with writer unresolved. Frame category is not a compiler-bug verdict. A complete-looking record cannot create a missing allocation-generation, overlap or order witness.

Final validation: **29 accepted checks** under the unchanged 30-second combined cap per check, 12 TLC workers, 1 GiB heap and 8 MiB stack: typecheck; three positive safety/conditional-terminal scenarios (all thirteen fault contexts, normal two-epoch execution, and unavailable-carrier failure retention); **18 decoded negative controls**; seven explicitly selected TypeScript trajectories. The complete all-context positive has **180 distinct states**; normal and unavailable-carrier positives each have 14. Retention/diagnostic completion is not native success. [Validation receipts and source correspondence](../evidence/research/smp-retirement-study/tfib-scan-origin-validation.json) preserve all model hashes, checker results and counterexamples.

Controls reject lost tail ancestry, stale pair context, missing frame fields, late header records, mixed worker identity, torn records, unsafe pretty-printing, invented writers, range-as-generation, overwritten fault records, lost private-only records, stale epochs, skip-and-continue, missing pre-cell records, word-only attribution, same-address old writers, disjoint writes and unordered writes. The initial model's positive correctly failed because a prior-epoch accepted report was incorrectly left current after epoch transition; it was fixed by retaining the old record while clearing current admission. That failed attempt and the successful narrower 25-check model remain separate historical receipts.

This is an observation/refinement contract, **not** an implementation, native reproduction, classification of the saved missing scan cell or a proof of the first writer. Carrier persistence, native ordering, actual map/frame validity, all allocation paths and all-worker coverage remain unproved. No runtime gate is promoted; next repair selection still depends on a trustworthy source-origin/write witness.
