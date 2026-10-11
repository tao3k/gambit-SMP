"""Fail-closed lexical bindings for modeled runtime protocols.

This is an exact source-layout guard, not a C semantic proof. Changed function
boundaries require a fresh source audit rather than silently accepting drift.
"""
import re
import hashlib


def vector_increment_source_hash(original):
    start = b"      (define (make-ref-set!-cas!-inc!-expander type-check? kind)"
    end = b"      ;; inline make-vect and ##make-vect"
    if original.count(start) != 1 or original.count(end) != 1:
        raise ValueError("vector expander boundaries changed; audit required")
    before, remainder = original.split(start, 1)
    body, after = remainder.split(end, 1)
    old = (b"                  (and value-checker\n"
           b"                       (not (eq? kind 'ref))\n"
           b"                       (value-checker source env (caddr vars))))")
    new = (b"                  (if (eq? kind 'inc!)\n"
           b"                      (and type-check?\n"
           b"                           (= (length vars) 3)\n"
           b"                           (gen-call-prim-vars-notsafe source env\n"
           b"                             **fixnum?-sym\n"
           b"                             (list (caddr vars))))\n"
           b"                      (and value-checker\n"
           b"                           (not (eq? kind 'ref))\n"
           b"                           (value-checker source env (caddr vars)))))")
    if body.count(old) != 1:
        raise ValueError("vector increment value guard changed; audit required")
    return hashlib.sha256(before + start + body.replace(old, new, 1) + end + after).hexdigest()


def serialization_snapshot_source_hash(original):
    gc_table_snapshot(original.decode())
    start = b"(define-prim (##explode-gc-hash-table gcht)"
    end = b"\n(define-prim (##implode-gc-hash-table re fields)"
    if original.count(start) != 1 or original.count(end) != 1:
        raise ValueError("serializer boundaries changed; audit required")
    before, remainder = original.split(start, 1)
    body, after = remainder.split(end, 1)
    replacements = (
        (b"  (let ((len (##gc-hash-table-length gcht)))",
         b"  (let* ((snapshot (##gc-hash-table-snapshot gcht))\n         (len (##vector-length snapshot)))"),
        (b"(##gc-hash-table-field-ref gcht i)", b"(##vector-ref snapshot i)"),
        (b"(##gc-hash-table-field-ref gcht (##fx+ i 1))", b"(##vector-ref snapshot (##fx+ i 1))"),
        (b"(macro-gc-hash-table-size gcht)",
         b"(##fxwraplogical-shift-right\n                  (##fx- len (macro-gc-hash-table-key0))\n                  1)"),
        (b"(macro-gc-hash-table-flags gcht)", b"(##vector-ref snapshot 1)"),
        (b"(macro-gc-hash-table-count gcht)", b"(##vector-ref snapshot 2)"),
        (b"(macro-gc-hash-table-min-count gcht)", b"(##vector-ref snapshot 3)"),
        (b"(macro-gc-hash-table-free gcht)", b"(##vector-ref snapshot 4)"),
    )
    for old, new in replacements:
        if body.count(old) != 1:
            raise ValueError("serializer live cursor or metadata changed; audit required")
        body = body.replace(old, new, 1)
    return hashlib.sha256(before + start + body + end + after).hexdigest()


def shared_pipe_source_hash(original):
    old = (b"                 (whi2 (,macro-vect-port-whi port2)))\n"
           b"             (,macro-vect-port-wbuf-set! port1 wbuf2)")
    new = (b"                 (whi2 (,macro-vect-port-whi port2)))\n"
           b"             ;; Both endpoints access shared buffers and wait predicates.\n"
           b"             ;; Serialize them with one mutex so publication cannot race\n"
           b"             ;; with the peer checking a predicate and beginning to wait.\n"
           b"             (macro-port-mutex-set! port2 (macro-port-mutex port1))\n"
           b"             (,macro-vect-port-wbuf-set! port1 wbuf2)")
    if original.count(old) != 1:
        raise ValueError("pipe endpoint construction changed; audit required")
    return hashlib.sha256(original.replace(old, new, 1)).hexdigest()


def ended_interrupt_source_hash(original):
    start = b"(define-prim (##thread-intr-propagate! interrupt)"
    if original.count(start) != 1:
        raise ValueError("interrupt propagation definition changed; audit required")
    before, body = original.split(start, 1)
    function, separator, after = body.partition(b"\n(define-prim ")
    old = b"       (if (##not (macro-terminated-thread-given-initialized? thread))"
    new = (b"       (if (macro-terminated-thread-given-initialized? thread)\n\n"
           b"           ;; The target may end after the initial interruptability check.\n"
           b"           ;; The helper still holds its lock on this path.\n"
           b"           (macro-unlock-thread! thread)")
    if function.count(old) != 1 or not separator:
        raise ValueError("ended-target lock branch changed; audit required")
    return hashlib.sha256(before + start + function.replace(old, new, 1) + separator + after).hexdigest()


def checked_negate_header_hash(original):
    old = b"? (var=___FIXNEGP(x),1) \\\n"
    new = b"? ___FIXNEGP_NOTFALSEP(var,x) \\\n"
    if original.count(old) != 1:
        raise ValueError("checked-negation source branch changed; audit required")
    return hashlib.sha256(original.replace(old, new, 1)).hexdigest()


def postcopy_headroom(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    body = region(source, "___HIDDEN ___BOOL resize_heap\n", "___BOOL ___stack_limit_debug\n")
    floor = ("lower_bound_nb_sections+=compute_nb_msections_allocation_headroom();"
             "SET_MAX(lower_bound_nb_sections,"
             "nb_msections_assigned+compute_nb_msections_allocation_headroom());")
    capped = "SET_MIN(target_nb_sections,upper_bound_nb_sections);"
    if body.count(floor) != 1 or body.count(capped) != 1:
        raise ValueError("postcopy floor and existing maximum-heap cap required")
    admission = "SET_MAX(target_nb_sections,lower_bound_nb_sections);"
    if body.count(admission) != 1 or not body.index(floor) < body.index(admission) < body.index(capped):
        raise ValueError("postcopy floor must precede target admission and maximum-heap cap")
    return {"postcopyHeadroomSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}


def queue_acquire_handoff(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    owned = region(source, "___HIDDEN void scan_movable_objs_to_scan\n",
                   "___HIDDEN void free_unmarked_still_objs\n")
    stolen = region(source, "___HIDDEN void mark_reachable_from_marked\n",
                    "___HIDDEN void garbage_collect_setup_phase\n")
    fence = "___SHARED_MEMORY_BARRIER();"
    for body, lock, count in (
        (owned, "___SPINLOCK_LOCK(heap_chunks_to_scan_lock);", 2),
        (stolen, "___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);", 1)):
        if body.count(lock) != count or body.count(lock + fence) != count:
            raise ValueError("queue reads require a post-ticket acquire at every consumer lock")
    return {"queueAcquireHandoffSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}


def vm_resize_rollback(source):
    body = region(source, "___SCMOBJ ___vm_resize_pstate\n", "\n\nvoid execute_sync_op\n")
    cleanup = ("while(--i>=initial)"
               "___cleanup_pstate(___PSTATE_FROM_PROCESSOR_ID(i,___vms));"
               "___vms->mem.target_processor_count_=initial;BARRIER();returnerr;")
    if cleanup not in body:
        raise ValueError("failed VM growth must clean decremented processor IDs and restore target before barrier")
    return {"vmResizeRollbackSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}


def region(source, start, end):
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("source function boundary is missing or ambiguous")
    left, right = source.index(start), source.index(end)
    if left >= right:
        raise ValueError("source function boundaries are out of order")
    return re.sub(r"\s+", "", source[left:right])


def gc_table_snapshot(source):
    def procedure(name):
        marker = "(define-prim (" + name + " "
        if source.count(marker) != 1:
            raise ValueError("snapshot procedure is missing or ambiguous")
        start = source.index(marker)
        end = source.find("\n(define-prim ", start + len(marker))
        if end == -1:
            raise ValueError("snapshot procedure boundary is missing")
        return re.sub(r"\s+", "", source[start:end])
    capture = procedure("##gc-hash-table-snapshot")
    allocate = "(let((snapshot(##make-vector(##gc-hash-table-lengthgcht))))"
    copy = ("memmove(___BODY_AS(___ARG2,___tVECTOR),"
            "___BODY_AS(___ARG1,___tSUBTYPED),"
            "___HD_WORDS(___HEADER(___ARG1))*___WS);")
    if allocate not in capture or copy not in capture or capture.index(allocate) >= capture.index(copy):
        raise ValueError("snapshot must allocate before non-allocating typed body copy")
    if "___RESULT=___ARG2;" not in capture or "gchtsnapshot)))" not in capture:
        raise ValueError("snapshot must return its rooted vector")
    for name in ("##gc-hash-table-for-each", "##gc-hash-table-search", "##gc-hash-table-foldl"):
        body = procedure(name)
        if ("(snapshot(##gc-hash-table-snapshotgcht))" not in body
            or "(##vector-refsnapshoti)" not in body
            or "(##vector-refsnapshot(##fx+i1))" not in body
            or "##gc-hash-table-field-ref" in body):
            raise ValueError("callback traversal must use the rooted stable snapshot")
    return {"gcTableSnapshotSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}


def stack_markers(source):
    setup = region(source, "___SCMOBJ ___setup_mem_pstate\n", "___SCMOBJ ___setup_mem_vmstate\n")
    copy = region(source, "___HIDDEN void move_continuation\n", "___HIDDEN void determine_occupied_words\n")
    # Both debug/non-debug signatures share this single function body.
    fresh = region(source, "___BOOL ___stack_limit_debug\n", "___WORD ___stack_overflow_undo_if_possible\n")
    slot = "-___FIRST_BREAK_FRAME_STACK_MSECTION"
    null = "___CAST(___WORD,___CAST(___msection*,NULL))"
    initial = "___FP_SET_STK(alloc_stack_ptr," + slot + "," + null + ")"
    copied = "___FP_SET_STK(___ps->stack_break," + slot + "," + null + ")"
    if initial not in setup or copied in setup:
        raise ValueError("processor setup must not dereference unassigned stack_break")
    if setup.index(initial) >= setup.index("___ps->stack_break=alloc_stack_ptr;"):
        raise ValueError("processor setup marker initialization order changed")
    if copied not in copy or initial in copy:
        raise ValueError("copied marker must target move_continuation's actual break frame")
    if initial not in fresh:
        raise ValueError("fresh break frame marker is not initialized")
    return {"stackMarkerSourceBinding": "passed"}


def sync_messages(source):
    source = re.sub(r"/\*.*?\*/", "", source.replace("\\\n", ""), flags=re.DOTALL)
    receive = region(source, "#define SYNC_GET_MSG(expr)", "#define SYNC_SEND_MSG(ps,field,val)")
    send = region(source, "#define SYNC_SEND_MSG(ps,field,val)", "___HIDDEN void ___sync_wait")
    fence = "___SHARED_MEMORY_BARRIER();"
    if not receive.endswith("}" + fence + "}while(0)"):
        raise ValueError("receive fence must follow the complete polling loop")
    if fence + "ps->field=val;" not in send:
        raise ValueError("payload publication fence must precede the flag store")
    return {"syncMessageSourceBinding": "passed"}


def sync_protocol(source):
    source = re.sub(r"/\*.*?\*/", "", source.replace("\\\n", ""), flags=re.DOTALL)
    receive = region(source, "#define SYNC_GET_MSG(expr)", "#define SYNC_SEND_MSG(ps,field,val)")
    send = region(source, "#define SYNC_SEND_MSG(ps,field,val)", "___HIDDEN void ___sync_wait")
    wait = region(source, "___HIDDEN void ___sync_wait", "___HIDDEN int barrier_sync_op")
    if ("___MUTEX_LOCK(___ps->sync_mut);if((expr)==SYNC_WAITING)"
        "___sync_wait(___ps);___MUTEX_UNLOCK(___ps->sync_mut);") not in receive:
        raise ValueError("slow receive must recheck the predicate under the wait mutex")
    if "___CONDVAR_WAIT(___ps->sync_cv,___ps->sync_mut);" not in wait:
        raise ValueError("condition wait must use the receiver's predicate mutex")
    sequence = ["___MUTEX_LOCK(ps->sync_mut);", "ps->field=val;",
                "___MUTEX_UNLOCK(ps->sync_mut);", "___CONDVAR_SIGNAL(ps->sync_cv);"]
    positions = [send.index(token) if send.count(token) == 1 else -1 for token in sequence]
    if -1 in positions or positions != sorted(positions):
        raise ValueError("sender lock/publication/unlock/signal order changed")
    return {"syncWaitSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}


def heap_headroom(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL).replace("\\\n", "")
    compact = re.sub(r"\s+", "", source)
    macro = ("#definecompute_nb_msections_allocation_headroom()"
             "(___CEILING_DIV(normal_overflow_reserve,___MSECTION_SIZE)+1)")
    setup = region(source, "___SCMOBJ ___setup_mem_vmstate\n", "___SCMOBJ ___setup_mem ___PVOID")
    resize = region(source, "___HIDDEN ___BOOL resize_heap\n", "___HIDDEN void mark_registers\n")
    if macro not in compact or (
        "SET_MAX(init_nb_sections,(compute_nb_msections_min(___vms->processor_count)+"
        "compute_nb_msections_allocation_headroom()));") not in setup:
        raise ValueError("initial heap must include the reserve and next-section headroom")
    floor = ("SET_MAX(lower_bound_nb_sections,(compute_nb_msections_needed(occupied_words_movable)+"
             "nb_msections_stacks));")
    added = "lower_bound_nb_sections+=compute_nb_msections_allocation_headroom();"
    if floor + added not in resize:
        raise ValueError("post-GC headroom must follow the occupied/processor floor")
    cap = "SET_MIN(target_nb_sections,upper_bound_nb_sections);"
    if cap not in resize or resize.index(added) >= resize.index(cap):
        raise ValueError("headroom must not bypass the configured maximum-heap clamp")
    return {"heapHeadroomSourceBinding": "passed", "bindingKind": "lexical-not-semantic"}
