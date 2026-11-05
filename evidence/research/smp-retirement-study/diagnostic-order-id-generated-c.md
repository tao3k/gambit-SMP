# Diagnostic commit/load ordering and request identity through generated frames

2026-10-24, Asia/Shanghai. Evidence-only refinement of [the current-lock diagnostic cut](current-lock-minimal-diagnostics.md). No new queue, scheduler, lifetime, exception or retirement protocol. No runtime/generator/qualifier/Recipe/history change, Gambit compilation/execution, other-thread operation, commit or push. Recorded count remains8/12; it is not requalified here.

Authority remains main7c490c3 plus cohort-ack-rc lock SHA c5b2e0bd4db5b8b99dee274d3d5cfbdec8df387eb7ca9d4df4b6d971a3b8686d and patch3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7. Companion JSON binds the33 selected candidate files and protected20 inputs. These are a bounded source package, not an asserted complete native producer.

## 1. Three separate ordering obligations

The pre-cell/footer and pre-header/footer records proposed previously are not implemented in current mem.c. Required order is:

```
capture available scalar context -> write complete payload -> release commit
 -> compiler + target Store/Load ordering -> ORIGINAL cell read
 -> capture that read's actual word -> write HEADER_PENDING payload -> release commit
 -> compiler + target Store/Load ordering -> ORIGINAL header read
```

1. **Payload before commit:** an observer reading that publication must not accept incomplete context. This is the release/publication side.
2. **Commit before following ordinary read:** source order and a release store alone do not establish the required two-way machine ordering. `volatile`, an empty asm memory clobber or a signal fence is not a CPU Store/Load barrier. Changing only the footer store to seq_cst does not supply the selected full-barrier instruction on the controls below.
3. **Committed bytes survive the actual owned fault:** memory ordering does not establish process-exit carrier lifetime or external postmortem visibility. Inspect the actual produced object and validate its shared carrier after the exact fault/control group is quiescent. A full fence in this standalone C is not a native crash-durability proof. DMB orders accesses; it is not a promise of storage durability or the time accesses complete. Whether stronger completion ordering is necessary for the chosen Darwin carrier remains a platform/native control question; do not claim DMB alone settles it.

[GCC atomic builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html) distinguishes release/acquire, sequential atomic order and thread/signal fences, and assumes a data-race-free program. [Arm's synchronization overview, sections2.2–2.3](https://documentation-service.arm.com/static/62b4777131ea212bb66241e6) distinguishes one-way release/acquire from DMB/DSB. A release followed by a suitable acquire can have additional Arm ordering; the original scan here is an **ordinary** read, not that acquire. These references do not prove recovery after an invalid C dereference: such a dereference has no portable ISO C crash contract.

### Actual compiler controls, not a runtime fix

`diagnostic-order-control.c` is standalone evidence, never linked or executed, with ordinary pointer-parameter reads and no Gambit headers. GCC16.2.0 and Apple Clang21.0.0 each compiled it with `-O2` and `-O3`, `-std=c11 -S`, under registered audit and30-second per-command caps. Actual commands, versions, process-reaping metadata and assembly SHA are retained in the JSON-linked receipt.

| Variant, four compiler/optimization combinations | Actual assembly finding | Diagnostic acceptance |
| --- | --- | --- |
| release_only | Payload stores, release commit, ordinary load; no DMB | Insufficient for this Store/Load evidence gate |
| signal_only | Same, no DMB | Compiler-only ordering insufficient |
| store_seqcst | Same, no DMB | Stronger footer name alone insufficient |
| full_barrier | Payload, release commit, `dmb ish`, ordinary load | Selected ordering shape present; no crash-survival claim |
| two_reads | Twice payload/commit/DMB/load, with actual first value stored before second commit | Representative two-read shape present; not Gambit tag decoding |

GCC emits `stlur` and Clang `stlr`; both must be recognized as release instructions. Arm's [STLUR instruction reference](https://documentation-service.arm.com/static/67e40f3398aa3c3b6eea6a85) identifies STLUR as store-release with unscaled addressing. No helper call is emitted in these functions; aligned64-bit lock-free footer is a compile-time control. Do not infer the actual producer's flags/architecture/LTO choices from host compiler defaults.

The initial automated extraction reported GCC checks false because it expected Clang-style `.cfi_endproc` and only `stlr`; the raw failure receipt is retained. The corrected read-only replay accepts GCC `LFE` boundaries and `stlur`, verifies payload/commit/barrier/load offsets, and reuses the same four assembly files without recompiling. It does not pretend that parser failure demonstrated a compiler defect.

### Current read placements and observer boundary

Current `mem.c:3926..3930` selects cell then reads `obj=*cell`; `3944..3945` computes body then reads `head=body[-1]`. Final disassembly must prove each record uses the same cell/header address as that original read, that the record is complete before it, and that no earlier inlined/header validation read faults first. If consistency validation at3940..3941 is enabled, that access must be covered or explicitly rejected as an uncovered fault PC. Tail `goto again:4045` requires a fresh matching context and attempt, not the outer span. No extra header read for logging.

The original bounded carrier is read after the owned process group has stopped. A footer acquire does **not** make concurrent non-atomic payload overwrite safe: do not add a live seqlock-style reader and assume a second sequence read fixes the C data race. Require actual single-writer ownership, a complete retained version and matching context sequence; reject interrupted/reentered/overwritten records. If live reading becomes necessary, it requires a separate proven mechanism and is outside this cut. The carrier mapping must outlive the child and remain owned through the read; no file-cache or disk-durability claim follows from a CPU fence.

## 2. The ID is an immediate value; the associated objects are roots

Use the previously proposed private mutex-request third element, an immediate nonwrapping fixnum serial with session/VM prefix. Nothing in current candidate implements it. Slot0 remains the one next link, slot1 the mutex, mutex.name the thunk and mutex.specific the target/result. Validate private shape before reading metadata; procedure interrupts must not acquire an unconditional slot2 read. Use actual configured fixnum limits; if a serial cannot be represented or diagnostics overflow, stop attribution/reuse and leave original request behavior intact. Do not allocate a bignum or wrap an identity.

The serial's bits do not relocate. It needs **value liveness** through generated returns/captured continuations; it need not have a pointer-specific GC map bit merely because it is an ID. If emitted in a normal Scheme-scanned slot, its immediate tag is safe. Request, mutex, target/thread, resume-thunk and heap result have separate pointer-root obligations while semantically live. Save the serial independently before dropping the node; never reread node[2] after callback/lock2 to keep the node alive for logs. Keeping otherwise dead nodes/targets/results as extra strong roots can hide the bug under diagnosis. Raw native record addresses are observations, never roots or cross-GC lookup keys.

| Current lock edge | Exact value/root requirement | What Grok must extract from newly generated SMP C |
| --- | --- | --- |
| `thread-intr!:1439..1461`, construction1451..1454 | Serial survives metadata/mutex allocations; mutex/thunk/target follow normal roots. ISSUE means a real initialized request, not merely a reserved serial. No WAIT2 event for failed construction. | Allocation checks, live scalar storage and actual saved/reloaded roots before publication. A constructor failure leaves an unused serial, not a pending request. |
| propagate1463ff, sync participation1484, restored lexical node1487, splices1507..1517/1530..1534 | Node/mutex/thread/P values used after GC must be the current values. Serial copied to scalar local before a node may become dead; owner changes do not create a new ID. | Each sync return label, frame-space/descriptor/map, pre-call saves and post-call reloads for precisely live objects. No cached C node/slot pointer across safepoint. |
| other1542..1574, resume2877..2911, thunk1571/2906 | Capture scalar serial before calling thunk. Mutex remains live until store/unlock, result through mutex.specific, resume-thunk if later used. Node need not remain live solely for diagnostics. | Actual call to thunk; its return label; serial and mutex saves/reloads; result store preceding unlock, including any generated slow/sync branches. |
| result store1571/2906 to unlock1572/2907; macro-unlock1785..1798 | Result remains reachable through rooted mutex's field11 across every **emitted** safepoint; result logging cannot create a new safepoint or retain it longer. | Expand the actual emitted lock/waiter branches. Source macro heap-check does not establish a generated collection point. W_ALL declaration is not executed saving. |
| sender lock2 at1459, unlock1460, result read1461 | Keep scalar serial and semantically required mutex alive through lock2. Preserve return result while emitting terminal observation; do not let the recorder allocate or clobber it. | Actual lock2 continuation's serial value, mutex root/reload, final read/return and error edges; genuine WAIT2_RETURN, not merely propagate return. |
| `thread-migrate-to!:3316..3336`, save3320 and sync3324; consume target2884..2890 | Serial travels in the suspended Scheme activation/continuation; native actor changes but request identity does not. Each emitted event records its actual actor; TLS/current-P is not identity. | Save/capture map, destination rooted thread/continuation, restored local serial and relocated mutex, actual destination execution. Two actors using same ID must not overwrite each other's event as an authoritative global phase. |

`mark_frame:4253..4327` tests map bits for FP_STK ordinals starting1; `mark_captured_continuation:4090..4249` copies frames; `mark_continuation:4334..4401` decodes descriptors. These are existing mechanisms to audit, not proof that an ungenerated serial local has been saved.

### Concrete generated-C evidence and its limits

Current source-package `_thread.c:14320..14352` saves resume-thunk at STK2 and passes node as R1 to a one-argument procedure. Its other-interrupt19061..19085 is procedure-only. These correspond to non-SMP source bodies and cannot certify the mutex/thunk SMP paths or new ID. No emitted new label/frame/map is available here. Do not hand-edit this file or infer a new label from an older build.

A separately SHA-bound historical SMP sample provides a **method control**, not the current producer: other-interrupt15797..15803 saves mutexSTK(-2), ADJFP4, calls thunk with zero arguments, then stores result via STK(-6), field11. Resume19744..19752 saves resume-thunkSTK2 and mutexSTK3, ADJFP8, then stores result via STK(-5). Its sync-lock helper13101..13105 saves objectSTK2 then ADJFP8; return13079..13082 reloads STK(-6). Descriptor fs5/frame-space8/map0x3 selects scanner ordinal2 for that helper (`8-6`), not 'bit6'. Historical companion has five checked map rows. No serial exists in these bytes, and the sample mem.c is not the original crashing mem.c. This turn verifies all six historical input hashes, not a new native binding.

New producer B must supply the corresponding actual labels, descriptors, ordinal translation, values and reloads for its changed generated C. Inspect configured/preprocessed W_ALL/R_ALL expansion at native helpers that can collect: candidate header6833..6834 aliases these macros, while old kernel12380..12386 executes them around service. Neither alias nor a PW_ALL declaration alone certifies a new helper's register save. A diagnostic helper must stay no-allocation/no-GC/no-callback; audit its argument evaluation too.

## 3. Exception/escape coverage is intentionally bounded

Normal callback return, Scheme exception/continuation escape and native THROW are different control edges. No new catcher, finally handler, dynamic-wind or result-mutex repair belongs in this observational change.

* Normal return: scalar ID is restored with the activation; log actual result store/unlock/lock2 return. Early reply does not mean the dispatcher has stopped consuming the request. Keep only native diagnostic metadata until all recorded actors are finished; do not pin the Scheme node for the reader.
* A Scheme exception caught inside the thunk may later return normally. One escaping across the dispatcher does not execute its after-call event. A continuation escape may resume later; absence of ACTION_RETURN is not proof of a permanent error. Record a terminal error only at an **existing** error/abandon edge which still has the actual ID and verified roots. Current terminal-thread1744..1817 has no request-serial association; a raw mutex address after GC is not a substitute. Otherwise leave R's terminal correlation unavailable/unfinished, not CONSUME_OR_ERROR.
* Native boundary: header10056..10062 installs/restores catcher and passes error through ps->longjmp_err;10068..10080 has the C++ alternative. Candidate setup4337..4356 and4366..4386 bracket host/trampoline/staged-body calls. An abandoned C activation cannot run its normal recorder epilogue. Do not put 'current R' in a native local, jump away and recover it at an unrelated catch. In particular, a modified nonvolatile automatic in the setjmp-containing function is not a reliable post-longjmp value; see [GNU's nonlocal-exit details](https://snapshots.sourceware.org/glibc/trunk/latest/manual/html_node/Non_002dLocal-Details.html). Making that scalar volatile would not root any Scheme pointer or transfer it across Scheme migration. Only an existing trustworthy activation association can justify an error event; none is newly implemented here.
* Nested requests have distinct IDs and their own activations. On child return the parent's saved scalar must be unchanged. No TLS parent inference, global current-R, guessed depth or parent-pointer root is introduced. Unsupported parent/error association is explicitly absent.

This closes the diagnostic specification by making unsupported paths UNKNOWN; it does not claim every opaque C escape is traceable. If an actual failure depends on such an uncovered path, the minimum diagnostic evidence is insufficient and must say so before selecting a runtime repair.

## 4. Minimum native checks and acceptance, all on one producer B

These are Grok's next native steps, **not commands/tests reported as run here**. The hooks have no working current CLI. Preserve original limits, inputs, topology and failures; no full inventory is needed for diagnosis.

1. Freeze source delta, configured generator/compiler/headers/SMP flags, preprocessed C, generated C, final object/archive and gsi SHA/UUID plus schema. Confirm both mutex dispatch paths exist. Fill the preceding value/root table with exact generated labels and object instructions. Reject old package C, unrelated producer or missing macros/configuration.
2. For the two scan hooks, review final machine address operands and payload/commit/barrier/original-read order, including inlining/LTO and earlier validation accesses. Record compiler flags and absence of helper calls/allocations. The standalone twenty shape checks are a control, not this step's receipt.
3. In an owned diagnostic child using B's actual recorder/carrier/compile mode, deliberately fault once at cell and once at header. After original watchdog/reaping, require committed record+context, run/VM/native-owner/attempt identity, exact new faultPC and operand address; header record has actual loaded raw value, cell record does not. Check reentry/torn/stale/overflow controls reject. A standalone crash in another helper proves only that helper's carrier, not every inlined mark_array site. No PC reuse from old mark_array+104. No new signal handler or other-thread sampling.
4. Using the same B, check one ordinary synchronous request, early reply, an existing permitted GC while waiting/callback, callback migration with GC, nested child request, supported error/abandon and ordinary procedure interrupt. Require evidence an actual GC/migration/exception occurred; test names/counters alone do not force the edge. Place controls only at legal existing safepoints, never force GC while holding T/P locks. Match ID before/after, the expected native actor change, relocated object/root reload, stored result and actual unlock/lock2 return. The ID may stay numerically equal while the object's address changes. Reject retained old pointer, lost scalar, parent ID replaced by child ID, wrong node shape, invented terminal event or logging-induced strong retention. Unsupported escape must stay unresolved.
5. Rehash B unchanged, then original TFIB `(go 15 5000)` and retained interrupt/flood workloads under their original harness and caps. A valid scan fault cut classifies the actual scan origin; a blocked R needs a complete serial-bound owner trail/census, not just empty queue heads. Timeout without a faultPC cannot select the latest scan record as the fault. Lost instrumentation coverage means UNKNOWN. If full barriers alter timing enough to prevent reproduction or exceed budget, record that limitation, do not declare repair or widen the cap.

Accept only the conjunction of source/configuration identity, generated value/root preservation, emitted access order, carrier survival, and the request/fault-specific observation. A checked QNT trace does not prove C compiler ordering, physical root maps or post-crash memory visibility; no unchanged model was rerun. Neither these controls nor a valid diagnosis is9/12 or a lifecycle recovery receipt.

The [repair decision and final carrier/escape boundary](fault-carrier-root-remedy.md) makes the external reader the final carrier consumer and separates the coherent delivery repair from unsupported TFIB attribution. No additional catch is recommended.
