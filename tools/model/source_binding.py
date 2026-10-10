"""Fail-closed lexical bindings for modeled runtime protocols.

This is an exact source-layout guard, not a C semantic proof. Changed function
boundaries require a fresh source audit rather than silently accepting drift.
"""
import re


def region(source, start, end):
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("source function boundary is missing or ambiguous")
    left, right = source.index(start), source.index(end)
    if left >= right:
        raise ValueError("source function boundaries are out of order")
    return re.sub(r"\s+", "", source[left:right])


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
