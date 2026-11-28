"""Apply checked DEV probes to an isolated, complete memory source snapshot."""
from pathlib import Path
import re
import sys


def edit(path: Path, pairs: list[tuple[str, str]]) -> None:
    text = path.read_text()
    for old, new in pairs:
        if text.count(old) != 1:
            raise ValueError(f"{path.name}: expected one anchor {old!r}")
        text = text.replace(old, new)
    path.write_text(text)


def instrument(lib: Path) -> None:
    edit(lib / "mem.c", [('#include <string.h>', '#include <string.h>\n#include "gc-collector-overlay.h"')])
    mem = lib / "_mem"
    path = mem / "collection-round.inc"
    edit(path, [
        ('  ___ACTLOG_BEGIN_PS(gc,red);', '  gc_enter(___PROCESSOR_ID(___ps,___vms), ___vms);\n  ___ACTLOG_BEGIN_PS(gc,red);'),
        ('    ___ACTLOG_END_PS();return 1;', '    gc_leave();\n    ___ACTLOG_END_PS();return 1;'),
        ('  return overflow;', '  gc_leave();\n  return overflow;'),
        ('=plan_copy_round(___ps);', '=GC_VALUE(gc_plan, plan_copy_round(___ps));'),
        ('= resize_heap (___vms, requested_words_still);', '= GC_VALUE(gc_resize, resize_heap (___vms, requested_words_still));'),
        ('      scan_still_objs_to_scan (work);\n      scan_movable_objs_to_scan (work);',
         '      GC_TIMED(gc_scan, scan_still_objs_to_scan (work));\n'
         '      GC_TIMED(gc_scan, scan_movable_objs_to_scan (work));'),
        ('  if (!___root_round_scan(___ps,rc_epoch))', '  if (!GC_VALUE(gc_scan, ___root_round_scan(___ps,rc_epoch)))'),
        ('      for (i = (np-1)', '      uint64_t steal_start = GC_START();\n      for (i = (np-1)'),
        ('              scan_complete_heap_chunk (work, ptr, 3);',
         '              gc_record(gc_steal, steal_start);\n'
         '              GC_TIMED(gc_scan, scan_complete_heap_chunk (work, ptr, 3));'),
        ('      /* Signal being idle', '      gc_record(gc_steal, steal_start);\n\n      /* Signal being idle'),
        ('          ___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);',
         '          GC_TIMED(gc_idle, ___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex));'),
    ])
    text = path.read_text()
    if text.count('BARRIER();') < 10:
        raise ValueError("GC collective barrier inventory changed")
    path.write_text(text.replace('BARRIER();', 'GC_BARRIER(BARRIER());'))
    edit(path, [
        ('rc_contract_error("Frozen root union cannot retire before member restoration");\n  GC_BARRIER(BARRIER());',
         'rc_contract_error("Frozen root union cannot retire before member restoration");\n  GC_BARRIER_PUBLISH(BARRIER());'),
    ])
    edit(mem / "object-scanning.inc", [
        ('ptr=take_heap_chunk(work,work)', 'ptr=GC_VALUE(gc_take, take_heap_chunk(work,work))'),
    ])
    path = mem / "heap-sections.inc"
    text = path.read_text()
    if text.count('ALLOC_MEM_LOCK();') != 3:
        raise ValueError("Allocator gate inventory changed")
    path.write_text(text.replace('ALLOC_MEM_LOCK();', 'GC_ALLOCATOR_GATE(ALLOC_MEM_LOCK());'))
    edit(mem / "copy-planning.inc", [
        ('___ALLOC_MEM(capacity*sizeof(*c->queue))', 'GC_VALUE(gc_alloc_call, ___ALLOC_MEM(capacity*sizeof(*c->queue)))'),
        ('if(c->retired)___FREE_MEM(c->retired);', 'if(c->retired)GC_TIMED(gc_alloc_call, ___FREE_MEM(c->retired));'),
    ])
    edit(mem / "aligned-allocation.inc", [
        ('___ALLOC_MEM_HEAP(extra + (words+modulus) * ___WS)', 'GC_VALUE(gc_alloc_call, ___ALLOC_MEM_HEAP(extra + (words+modulus) * ___WS))'),
        ('___ALLOC_MEM(extra + (words+modulus) * ___WS)', 'GC_VALUE(gc_alloc_call, ___ALLOC_MEM(extra + (words+modulus) * ___WS))'),
        ('___FREE_MEM(*cptr);', 'GC_TIMED(gc_alloc_call, ___FREE_MEM(*cptr));'),
        ('___FREE_MEM_HEAP(*cptr);', 'GC_TIMED(gc_alloc_call, ___FREE_MEM_HEAP(*cptr));'),
    ])


def instrument_worker_phases(lib: Path) -> None:
    """Apply the same inclusive counters to either DEV collector arm."""
    mem = lib / "_mem"
    edit(lib / "mem.c", [
        ("#include <string.h>", '#include <string.h>\n#include "gc-collector-overlay.h"'),
    ])
    path = mem / "collection-round.inc"
    edit(path, [
        ("  ___ACTLOG_BEGIN_PS(gc,red);",
         "  gc_enter(___PROCESSOR_ID(___ps,___vms), ___vms);\n  ___ACTLOG_BEGIN_PS(gc,red);"),
        ("    ___ACTLOG_END_PS();return 1;",
         "    gc_leave();\n    ___ACTLOG_END_PS();return 1;"),
        ("  return overflow;", "  gc_leave();\n  return overflow;"),
        ("      scan_still_objs_to_scan (work);",
         "      GC_TIMED(gc_scan, scan_still_objs_to_scan (work));"),
        ("      scan_movable_objs_to_scan (work);",
         "      GC_TIMED(gc_scan, scan_movable_objs_to_scan (work));"),
        ("  if (!___root_round_scan(___ps,rc_epoch))",
         "  if (!GC_VALUE(gc_scan, ___root_round_scan(___ps,rc_epoch)))"),
        ("          ___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);",
         "          GC_TIMED(gc_idle, ___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex));"),
    ])
    for name in ("collection-round.inc", "object-scanning.inc", "heap-sections.inc"):
        path = mem / name
        text = path.read_text()
        text = re.sub(r"take_heap_chunk\(work,(victim|owner|work)\)",
                      r"GC_VALUE(gc_take, take_heap_chunk(work,\1))", text)
        text = re.sub(
            r"(?m)^( +)___CONDVAR_SIGNAL\(scan_termination_condvar\);$",
            r"\1{ uint64_t start = GC_PARK_START(); "
            r"___CONDVAR_SIGNAL(scan_termination_condvar); gc_park_record(park_notify,start); }",
            text,
        )
        if name == "collection-round.inc":
            sites = iter(range(32))
            text, count = re.subn(r"\bBARRIER\(\);",
                                  lambda _: f"GC_BARRIER_SITE({next(sites)}, BARRIER());",
                                  text)
            final = "GC_BARRIER_SITE(17, BARRIER());"
            before, separator, after = text.partition(final)
            if count != 18 or not separator or "___root_round_end(___ps)" not in before[-420:]:
                raise ValueError("final GC barrier no longer follows round close")
            text = before + "GC_BARRIER_SITE_PUBLISH(17, BARRIER());" + after
            text = re.sub(r"(scan_complete_heap_chunk\s*\(work,[^;]+,\s*3\));",
                          r"GC_TIMED(gc_scan, \1);", text)
        path.write_text(text)



def instrument_queue_outcomes(lib: Path) -> None:
    """Count own-queue outcomes and the last observation at idle without changing takes."""
    edit(lib / "mem.c", [
        ("#include <string.h>", r"""#include <string.h>
#include <stdatomic.h>
#include <stdio.h>
enum { dev_take_busy = 1, dev_take_empty = 2, dev_take_acquired = 3 };
static _Thread_local unsigned dev_last_own_take;
static _Atomic unsigned long dev_own_take_counts[___MAX_PROCESSORS][4];
static _Atomic unsigned long dev_idle_take_counts[___MAX_PROCESSORS][4];
static void dev_record_own_take(___collector_worker *work,
                                ___collector_worker *owner, unsigned result)
{
  if (work != owner) return;
  dev_last_own_take = result;
  atomic_fetch_add_explicit(&dev_own_take_counts[work->id][result],1,memory_order_relaxed);
}
__attribute__((destructor)) static void dev_report_queue_outcomes(void)
{
  for (unsigned i=0;i<___MAX_PROCESSORS;i++)
    for (unsigned result=0;result<4;result++) {
      unsigned long takes=atomic_load_explicit(&dev_own_take_counts[i][result],memory_order_relaxed);
      unsigned long idle=atomic_load_explicit(&dev_idle_take_counts[i][result],memory_order_relaxed);
      if (takes || idle)
        fprintf(stderr,"DEV-QUEUE worker=%u outcome=%u own=%lu idle=%lu\n",
                i,result,takes,idle);
    }
}"""),
    ])
    edit(lib / "_mem/heap-sections.inc", [
        ("  if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)\n    return 0;",
         "  if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0) {\n"
         "    dev_record_own_take(work,owner,dev_take_busy); return 0;\n  }"),
        ("      unlock_chunk_fifo(owner);\n      return 0;",
         "      dev_record_own_take(work,owner,dev_take_empty);\n"
         "      unlock_chunk_fifo(owner);\n      return 0;"),
        ("  work->chunks_claimed_++;\n  unlock_chunk_fifo(owner);",
         "  work->chunks_claimed_++;\n"
         "  dev_record_own_take(work,owner,dev_take_acquired);\n  unlock_chunk_fifo(owner);"),
    ])
    edit(lib / "_mem/collection-round.inc", [
        (" continue_local_scan:\n",
         " continue_local_scan:\n  dev_last_own_take = 0;\n"),
        ("      if (--(*workers_count) == 0)",
         "      atomic_fetch_add_explicit(&dev_idle_take_counts[work->id]"
         "[dev_last_own_take],1,memory_order_relaxed);\n"
         "      if (--(*workers_count) == 0)"),
    ])



def instrument_queue_depth(lib: Path) -> None:
    """Extend outcome observations with a single-VM, gate-updated depth ledger."""
    edit(lib / "mem.c", [
        ("static _Thread_local unsigned dev_last_own_take;", """static _Thread_local unsigned dev_last_own_take;
static _Atomic long dev_queue_depth[___MAX_PROCESSORS];
static _Atomic unsigned long dev_last_idle_votes, dev_last_idle_queued;
static _Atomic unsigned long dev_idle_own_busy_queued, dev_depth_invalid;
static _Atomic uintptr_t dev_depth_vm;
static void dev_depth_change(___collector_worker *owner, long delta)
{
  uintptr_t expected=0, vm=(uintptr_t)owner->vm;
  if (!atomic_compare_exchange_strong(&dev_depth_vm,&expected,vm) && expected!=vm)
    atomic_fetch_add(&dev_depth_invalid,1);
  long old=atomic_fetch_add(&dev_queue_depth[owner->id],delta);
  if (old+delta<0) atomic_fetch_add(&dev_depth_invalid,1);
}"""),
        ("  for (unsigned i=0;i<___MAX_PROCESSORS;i++)",
         r"""  fprintf(stderr,"DEV-DEPTH last=%lu queued=%lu busy-own-queued=%lu invalid=%lu\n",
          atomic_load(&dev_last_idle_votes),atomic_load(&dev_last_idle_queued),
          atomic_load(&dev_idle_own_busy_queued),atomic_load(&dev_depth_invalid));
  for (unsigned i=0;i<___MAX_PROCESSORS;i++)
    if (atomic_load(&dev_queue_depth[i])!=0)
      fprintf(stderr,"DEV-DEPTH residual worker=%u depth=%ld\n",i,atomic_load(&dev_queue_depth[i]));
  for (unsigned i=0;i<___MAX_PROCESSORS;i++)"""),
    ])
    edit(lib / "_mem/heap-sections.inc", [
        ("  work->chunks_claimed_++;", "  work->chunks_claimed_++;\n  dev_depth_change(owner,-1);"),
        ("      heap_chunks_to_scan_tail = new_tail;",
         "      heap_chunks_to_scan_tail = new_tail;\n      dev_depth_change(work,1);"),
    ])
    edit(lib / "_mem/collection-round.inc", [
        ("      if (--(*workers_count) == 0)",
         "      if (dev_last_own_take==dev_take_busy && atomic_load(&dev_queue_depth[work->id])>0)\n"
         "        atomic_fetch_add(&dev_idle_own_busy_queued,1);\n"
         "      if (--(*workers_count) == 0)"),
        ("          /* Scan has terminated */",
         "          atomic_fetch_add(&dev_last_idle_votes,1);\n"
         "          for(int dev_w=0;dev_w<np;dev_w++)\n"
         "            if(atomic_load(&dev_queue_depth[dev_w])>0)\n"
         "              atomic_fetch_add(&dev_last_idle_queued,1);\n"
         "          /* Scan has terminated */"),
    ])



def instrument_private_idle(lib: Path) -> None:
    """Observe only this worker's private scan fields before idle."""
    edit(lib / "mem.c", [
        ("static _Atomic long dev_queue_depth[___MAX_PROCESSORS];",
         "static _Atomic long dev_queue_depth[___MAX_PROCESSORS];\n"
         "static _Atomic unsigned long dev_private_idle[5];\n"
         "static _Atomic unsigned long dev_private_checks;"),
        ("  for (unsigned i=0;i<___MAX_PROCESSORS;i++)\n"
         "    if (atomic_load(&dev_queue_depth[i])!=0)",
         '  fprintf(stderr,"DEV-PRIVATE checks=%lu",atomic_load(&dev_private_checks));\n'
         '  for(unsigned j=0;j<5;j++) fprintf(stderr," field%u=%lu",j,atomic_load(&dev_private_idle[j]));\n'
         '  fprintf(stderr,"\\n");\n'
         "  for (unsigned i=0;i<___MAX_PROCESSORS;i++)\n"
         "    if (atomic_load(&dev_queue_depth[i])!=0)"),
    ])
    edit(lib / "_mem/collection-round.inc", [
        ("      if (--(*workers_count) == 0)",
         "      atomic_fetch_add(&dev_private_checks,1);\n"
         "      if(work->scan_ptr_!=work->arena.cursor) atomic_fetch_add(&dev_private_idle[0],1);\n"
         "      if(work->still_objs_to_scan_!=0) atomic_fetch_add(&dev_private_idle[1],1);\n"
         "      if(work->active_scan_chunk_!=0) atomic_fetch_add(&dev_private_idle[2],1);\n"
         "      if(work->tail_started_!=work->tail_completed_) atomic_fetch_add(&dev_private_idle[3],1);\n"
         "      if(work->local_scan_chunk_!=work->alloc_heap_chunk_start_) atomic_fetch_add(&dev_private_idle[4],1);\n"
         "      if (--(*workers_count) == 0)"),
    ])


def apply_guarded_park(lib: Path) -> None:
    """Experimental handoff for the complete, isolated DEV collector snapshot."""
    mem = lib / "_mem"
    edit(mem / "heap-sections.inc", [
        ("___HIDDEN ___WORD *take_heap_chunk\n"
         "   ___P((___collector_worker *work, ___collector_worker *owner),\n"
         "        (work, owner)\n___collector_worker *work;\n___collector_worker *owner;)\n"
         "{\n  ___WORD *node;\n#ifndef ___SINGLE_THREADED_VMS\n"
         "  if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)\n    return 0;\n#endif",
         "___HIDDEN ___WORD *take_heap_chunk_after_gate"
         "(___collector_worker *work, ___collector_worker *owner)\n"
         "{\n  ___WORD *node;"),
        ("  return node+1;\n}\n\n\n___HIDDEN void end_heap_chunk",
         "  return node+1;\n}\n\n"
         "___HIDDEN ___WORD *take_heap_chunk"
         "(___collector_worker *work, ___collector_worker *owner)\n{\n"
         "#ifndef ___SINGLE_THREADED_VMS\n"
         "  if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)\n    return 0;\n#endif\n"
         "  return take_heap_chunk_after_gate(work,owner);\n}\n\n"
         "___HIDDEN void end_heap_chunk"),
        ("      unlock_chunk_fifo(work);\n#ifndef ___SINGLE_THREADED_VMS\n"
         "      ___CONDVAR_SIGNAL(scan_termination_condvar);",
         "      unlock_chunk_fifo(work);\n#ifndef ___SINGLE_THREADED_VMS\n"
         "      uint64_t notify_start = GC_PARK_START();\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "      gc_park_record(park_notify,notify_start);"),
    ])
    edit(mem / "collection-round.inc", [
        ("      ___MUTEX_LOCK(scan_termination_mutex);\n\n"
         "      if (--(*workers_count) == 0)",
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      /* Obtain an actual queue observation before publishing idle. */\n"
         "      uint64_t recheck_start = GC_START();\n"
         "      for (i=0; i<np; ++i)\n"
         "        {\n"
         "          ___collector_worker *owner = &___COLLECTORS(___vms)[(id+i)%np];\n"
         "          lock_chunk_fifo(owner);\n"
         "          ___WORD *ptr = take_heap_chunk_after_gate(work,owner);\n"
         "          if (ptr != 0)\n"
         "            {\n"
         "              ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "              gc_park_record(park_recheck_hit,recheck_start);\n"
         "              gc_record(gc_steal,recheck_start);\n"
         "              GC_TIMED(gc_scan, scan_complete_heap_chunk(work,ptr,3));\n"
         "              goto continue_local_scan;\n"
         "            }\n"
         "        }\n"
         "      gc_park_record(park_recheck_empty,recheck_start);\n"
         "      gc_record(gc_steal,recheck_start);\n\n"
         "      if (--(*workers_count) == 0)"),
    ])



def apply_explicit_take_observation(lib: Path) -> None:
    """Materialize the typed take boundary in a DEV source snapshot.

    This is the take component of the joint candidate. It still uses the
    original termination authority, so it does not qualify phase closure.
    """
    vendor_lib = Path(__file__).resolve().parents[4] / "vendor/gambit/lib"
    targets = ("_mem/heap-sections.inc", "_mem/object-scanning.inc",
               "_mem/collection-round.inc")
    if any((lib / name).samefile(vendor_lib / name) for name in targets):
        raise ValueError("DEV take overlay requires a private source snapshot")

    mem = lib / "_mem"
    edit(mem / "heap-sections.inc", [
        ("___HIDDEN ___WORD *take_heap_chunk",
         "enum dev_gc_take_state { DEV_GC_BUSY, DEV_GC_EMPTY, DEV_GC_CLAIMED };\n"
         "struct dev_gc_take { enum dev_gc_take_state state; ___WORD *chunk; };\n\n"
         "___HIDDEN struct dev_gc_take take_heap_chunk"),
        ("if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)\n    return 0;",
         "if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)\n"
         "    return (struct dev_gc_take){DEV_GC_BUSY, 0};"),
        ("unlock_chunk_fifo(owner);\n      return 0;",
         "unlock_chunk_fifo(owner);\n      return (struct dev_gc_take){DEV_GC_EMPTY, 0};"),
        ("unlock_chunk_fifo(owner);\n  return node+1;",
         "unlock_chunk_fifo(owner);\n  return (struct dev_gc_take){DEV_GC_CLAIMED, node+1};"),
    ])
    edit(mem / "object-scanning.inc", [
        ("while ((ptr=take_heap_chunk(work,work)) != 0)",
         "for (;;)"),
        ("scan_complete_heap_chunk (work, ptr, 2);",
         "struct dev_gc_take take = take_heap_chunk(work,work);\n"
         "          if (take.state != DEV_GC_CLAIMED) break;\n"
         "          scan_complete_heap_chunk (work, take.chunk, 2);"),
    ])
    edit(mem / "collection-round.inc", [
        ("___WORD *ptr = take_heap_chunk(work,victim);",
         "struct dev_gc_take take = take_heap_chunk(work,victim);"),
        ("if (ptr != 0)\n            {\n              scan_complete_heap_chunk (work, ptr, 3);",
         "if (take.state == DEV_GC_CLAIMED)\n"
         "            {\n              scan_complete_heap_chunk (work, take.chunk, 3);"),
    ])


def apply_sequenced_park(lib: Path) -> None:
    """DEV candidate for ordered queue observation and normal worker park.

    The added state belongs to the collector-private root round. Unknown-exit settlement is a separate gap.
    """
    vendor = Path(__file__).resolve().parents[4] / "vendor/gambit"
    root_header = lib / "root.h"
    if root_header.samefile(vendor / "lib/root.h"):
        raise ValueError("DEV park overlay requires a private memory layout")
    if (lib / "mem.c").samefile(vendor / "lib/mem.c"):
        raise ValueError("DEV park overlay requires a private translation unit")
    apply_explicit_take_observation(lib)
    edit(lib / "mem.c", [
        ('#include "rc.h"', '#include "root.h"\n#include "rc.h"'),
    ])
    edit(root_header, [
        ("  ___gc_resume_space resume[___MAX_PROCESSORS];\n} ___root_round;",
         "  ___gc_resume_space resume[___MAX_PROCESSORS];\n"
         "  ___UWORD dev_gc_available_;\n"
         "  ___UWORD dev_gc_chunk_debt_;\n"
         "  unsigned dev_gc_resume_;\n"
         "} ___root_round;"),
    ])

    mem = lib / "_mem"
    edit(mem / "heap-sections.inc", [
        ("      work->chunks_published_++;\n\n      lock_chunk_fifo(work);",
         "      work->chunks_published_++;\n"
         "#ifndef ___SINGLE_THREADED_VMS\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      ++___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_chunk_debt_;\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "#endif\n\n"
         "      lock_chunk_fifo(work);"),
        ("      ___CONDVAR_SIGNAL(scan_termination_condvar);",
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      ++___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_available_;\n"
         "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);"),
        ("  scan_workers_count[0] = nw;",
         "  ___ROOT_UNION(___vms)->dev_gc_available_ = 0;\n"
         "  ___ROOT_UNION(___vms)->dev_gc_chunk_debt_ = 0;\n"
         "  scan_workers_count[0] = nw;"),
    ])
    edit(mem / "object-scanning.inc", [
        ("  require_chunk_transition(work,start,2,3);\n  work->chunks_completed_++;",
         "  require_chunk_transition(work,start,2,3);\n"
         "  work->chunks_completed_++;\n"
         "#ifndef ___SINGLE_THREADED_VMS\n"
         "  ___MUTEX_LOCK(scan_termination_mutex);\n"
         "  if (___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_chunk_debt_ == 0)\n"
         "    {\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "      abort(); /* DEV queued chunk completed without debt */\n"
         "    }\n"
         "  --___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_chunk_debt_;\n"
         "  ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "#endif"),
    ])
    edit(mem / "collection-round.inc", [
        ('  BARRIER(); /* publishes the one RootTask/worker assignment */',
         '  if (___PROCESSOR_ID(___ps,___vms)==0)\n'
         '    ___ROOT_UNION(___vms)->dev_gc_resume_ = 0;\n'
         '  BARRIER(); /* publishes the one RootTask/worker assignment */'),
        ('    if(___COLLECTION(___vms).decision==3)\n'
         '      rc_contract_error("Unknown planning result retains frozen roots and native buffers");\n'
         '    if(___PROCESSOR_ID(___ps,___vms)==0 && !___root_round_refuse(___ps))\n'
         '      rc_contract_error("Known refusal cannot retire an already started root task");\n'
         '    BARRIER();',
         '    if(___COLLECTION(___vms).decision!=2) abort();\n'
         '    if(___PROCESSOR_ID(___ps,___vms)==0)\n'
         '      {\n'
         '        if(!___root_round_refuse(___ps)) abort();\n'
         '        ___ROOT_UNION(___vms)->dev_gc_resume_ = 1; /* refused before copy */\n'
         '      }\n'
         '    BARRIER();\n'
         '    if (___ROOT_UNION(___vms)->dev_gc_resume_ != 1) abort();'),
        ('  if (___PROCESSOR_ID(___ps,___vms)==0 && !___root_round_end(___ps))\n'
         '    rc_contract_error("Frozen root union cannot retire before member restoration");\n'
         '  BARRIER();',
         '  if (___PROCESSOR_ID(___ps,___vms)==0)\n'
         '    {\n'
         '      if (!___root_round_end(___ps)) abort();\n'
         '      ___ROOT_UNION(___vms)->dev_gc_resume_ = 2; /* restored */\n'
         '    }\n'
         '  BARRIER();\n'
         '  if (___ROOT_UNION(___vms)->dev_gc_resume_ != 2) abort();'),
        ("      if (--(*workers_count) == 0)",
         "      if (*workers_count == 1 && ___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_chunk_debt_ != 0)\n"
         "        {\n"
         "          ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "          abort(); /* DEV phase closure with live chunk debt */\n"
         "        }\n"
         "      if (--(*workers_count) == 0)"),
        ("      /* Signal being idle and wait for more work or termination */\n\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);",
         "      ___UWORD observed;\n"
         "      int busy = 0;\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      observed = ___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_available_;\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "      for (i = 0; i < np; ++i)\n"
         "        {\n"
         "          ___collector_worker *owner = &___COLLECTORS(___vms)[(id+i)%np];\n"
         "          struct dev_gc_take take = take_heap_chunk(work,owner);\n"
         "          if (take.state == DEV_GC_CLAIMED)\n"
         "            {\n"
         "              scan_complete_heap_chunk(work,take.chunk,3);\n"
         "              goto continue_local_scan;\n"
         "            }\n"
         "          busy |= take.state == DEV_GC_BUSY;\n"
         "        }\n"
         "      if (busy) continue;\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      if (observed != ___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps))->dev_gc_available_)\n"
         "        {\n"
         "          ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "          continue;\n"
         "        }"),
    ])


def apply_waiter_gated_park(lib: Path) -> None:
    """DEV variant using the phase count as the pre-recheck wait registration."""
    apply_guarded_park(lib)
    mem = lib / "_mem"
    edit(mem / "collection-round.inc", [
        ("      /* Obtain an actual queue observation before publishing idle. */",
         "      ___WORD remaining = ___WORD_LOAD_ACQUIRE(workers_count)-1;\n"
         "      ___WORD_STORE_RELEASE(workers_count,remaining);\n"
         "      /* Register before taking every FIFO gate. */"),
        ("              ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "              gc_park_record(park_recheck_hit,recheck_start);",
         "              ___WORD_STORE_RELEASE(workers_count,remaining+1);\n"
         "              ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "              gc_park_record(park_recheck_hit,recheck_start);"),
        ("      if (--(*workers_count) == 0)", "      if (remaining == 0)"),
        ("          if (*workers_count == 0)",
         "          ___WORD active = ___WORD_LOAD_ACQUIRE(workers_count);\n"
         "          if (active == 0)"),
        ("          (*workers_count)++;",
         "          ___WORD_STORE_RELEASE(workers_count,active+1);"),
    ])
    edit(mem / "heap-sections.inc", [
        ("      uint64_t notify_start = GC_PARK_START();\n"
         "      ___MUTEX_LOCK(scan_termination_mutex);\n"
         "      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
         "      ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "      gc_park_record(park_notify,notify_start);",
         "      ___VOLATILE ___WORD *count = &scan_workers_count[traverse_weak_refs];\n"
         "      ___WORD workers = ___COLLECTION(work->vm).worker_count;\n"
         "      if (___WORD_LOAD_ACQUIRE(count) < workers)\n"
         "        {\n"
         "          uint64_t notify_start = GC_PARK_START();\n"
         "          ___MUTEX_LOCK(scan_termination_mutex);\n"
         "          ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
         "          ___MUTEX_UNLOCK(scan_termination_mutex);\n"
         "          gc_park_record(park_notify,notify_start);\n"
         "        }"),
    ])


def apply_post_gc_root_wake(path: Path) -> None:
    """Move only processor zero's post-GC tree signal under the recipient mutex."""
    continuation = " " + chr(92) + "\n"
    edit(path, [
        ("#define SYNC_SEND_MSG(ps,field,val)",
         "static _Thread_local int post_gc_sync;\n\n#define SYNC_SEND_MSG(ps,field,val)"),
        (continuation.join(('     ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     ___CONDVAR_SIGNAL(ps->sync_cv);')) + continuation,
         continuation.join(('     int signal_locked = post_gc_sync && id == 0;',
                            '     if (signal_locked) ___CONDVAR_SIGNAL(ps->sync_cv);',
                            '     ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     if (!signal_locked) ___CONDVAR_SIGNAL(ps->sync_cv);')) + continuation),
        ('  for (;;)\n    {\n      ___sync_op_struct sop = *sop_ptr;',
         '  int previous_gc = 0;\n'
         '  for (;;)\n    {\n      ___sync_op_struct sop = *sop_ptr;'),
        ('      int winner_id = barrier_sync_op (___PSP &sop);',
         '      post_gc_sync = previous_gc;\n'
         '      int winner_id = barrier_sync_op (___PSP &sop);\n'
         '      post_gc_sync = 0;\n'
         '      previous_gc = sop.op == OP_GARBAGE_COLLECT;'),
    ])


def apply_post_gc_root_wake_argument(path: Path) -> None:
    """Pass notification scope through the actual sync call, without TLS."""
    source = path.read_text()
    calls = r"\bbarrier_sync_op\s*\(___PSP &(sop|message)\)"
    if len(re.findall(calls, source)) != 5:
        raise ValueError(f"{path.name}: unexpected sync caller set")
    apply_post_gc_root_wake(path)
    edit(path, [
        ("static _Thread_local int post_gc_sync;\n\n", ""),
        ("___HIDDEN int barrier_sync_op\n"
         "   ___P((___PSD\n"
         "         ___sync_op_struct *sop_ptr),\n"
         "        (___PSV\n"
         "         sop_ptr)\n"
         "___PSDKR\n"
         "___sync_op_struct *sop_ptr;)",
         "___HIDDEN int barrier_sync_op\n"
         "   ___P((___PSD\n"
         "         ___sync_op_struct *sop_ptr,\n"
         "         int post_gc_sync),\n"
         "        (___PSV\n"
         "         sop_ptr,\n"
         "         post_gc_sync)\n"
         "___PSDKR\n"
         "___sync_op_struct *sop_ptr;\n"
         "int post_gc_sync;)"),
        ("      post_gc_sync = previous_gc;\n"
         "      int winner_id = barrier_sync_op (___PSP &sop);\n"
         "      post_gc_sync = 0;",
         "      int winner_id = barrier_sync_op (___PSP &sop, previous_gc);"),
    ])
    rewritten, count = re.subn(calls, r"barrier_sync_op (___PSP &\1, 0)", path.read_text())
    if count != 4:
        raise ValueError(f"{path.name}: incomplete ordinary sync caller coverage")
    path.write_text(rewritten)


def apply_post_gc_root_wake_probe(path: Path) -> None:
    """Keep trace sites fixed across unlocked and locked diagnostic arms."""
    continuation = " " + chr(92) + "\n"
    edit(path, [
        ('  int pause_collections = 0;', '  int pause_collections = 0;\n  int previous_gc = 0;'),
        ('      dev_gc_post_collect_sync = pause_collections != 0;',
         '      dev_gc_post_collect_sync = previous_gc;'),
        ('      dev_gc_post_collect_sync = 0;',
         '      dev_gc_post_collect_sync = 0;\n'
         '      previous_gc = sop.op == OP_GARBAGE_COLLECT;'),
        (continuation.join(('     ___MUTEX_UNLOCK(ps->sync_mut);', '     if (dev_gc_site) {')),
         continuation.join(('     int locked_signal = DEV_GC_LOCK_ROOT_WAKE && !dev_gc_site &&',
                            '                         dev_gc_post_collect_sync && id == 0;',
                            '     if (!locked_signal) ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     if (dev_gc_site) {'))),
        ('       DEV_GC_SIGNAL_KERNEL(recipient, token, 1);' + continuation,
         continuation.join(('       DEV_GC_SIGNAL_KERNEL(recipient, token, 1);',
                            '       if (locked_signal) ___MUTEX_UNLOCK(ps->sync_mut);')) + continuation),
    ])


def instrument_join_paths(path: Path) -> None:
    """Count the generated branches with no changes to Scheme or frame layouts."""
    wait = "__23__23_thread_2d_join_2d_wait_21_"
    register = "__23__23_thread_2d_join_2d_register_21_"
    anchors = {
        f"___DEF_GLBL(___L{wait})": "join_wait",
        f"___DEF_GLBL(___L5{wait})": "join_fast",
        f"___DEF_GLBL(___L4{wait})": "join_timeout",
        f"   ___JUMP_CONTINUATION_CAPTURE3(___JUMPNOTSAFE)\n___DEF_SLBL(1,___L1{wait})": "join_capture_return",
        f"___DEF_GLBL(___L{register})": "join_register",
        f"___DEF_SLBL(2,___L2{register})": "join_enqueued",
        f"___DEF_GLBL(___L8{register})": "join_race",
        f"___DEF_GLBL(___L10{register})": "join_race",
        f"___DEF_GLBL(___L9{register})": "join_register_timeout",
    }
    pairs = [('#include "gambit.h"', '#include "gambit.h"\n#include "gc-join-path-overlay.h"')]
    for anchor, event in anchors.items():
        marked = anchor + f"\n   dev_join_count(___ps, {event});"
        if event == "join_capture_return":
            marked = "   dev_join_count(___ps, join_capture);\n" + marked
        pairs.append((anchor, marked))
    edit(path, pairs)


def instrument_join_epochs(path: Path) -> None:
    """Join GC reply publication and acquire with the next Scheme interval."""
    apply_post_gc_root_wake_argument(path)
    continuation = " " + chr(92) + "\n"
    edit(path, [
        ('#define SYNC_GET_MSG(expr)',
         '#define SYNC_GET_MSG(expr) do { unsigned ignored = 0; uint64_t enter = 0, end = 0; SYNC_GET_MSG_ROUTE(expr, ignored, 0, enter, end); } while (0)\n'
         '#define SYNC_GET_MSG_ROUTE(expr, route, sample, enter, end)'),
        (continuation.join(('             ___MUTEX_LOCK(___ps->sync_mut);',
                            '             if ((expr) == SYNC_WAITING)',
                            '               ___sync_wait (___ps);')),
         continuation.join(('             if ((route) == 0) (route) = 1;',
                            '             ___MUTEX_LOCK(___ps->sync_mut);',
                            '             if ((expr) == SYNC_WAITING) {',
                            '               (route) = 2;',
                            '               if (sample) (enter) = join_epoch_wait_clock(id);',
                            '               ___sync_wait (___ps);',
                            '               if (sample) (end) = join_epoch_wait_clock(id);',
                            '             }'))),
        ('      SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));',
         '      unsigned receipt_route = 0;\n'
         '      uint64_t wait_enter = 0, wait_return = 0;\n'
         '      SYNC_GET_MSG_ROUTE(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0), receipt_route, post_gc_sync && n == 3, wait_enter, wait_return);'),
        ('#include "gambit.h"', '#include "gambit.h"\n#include "gc-join-epoch-overlay.h"'),
        ('     int signal_locked = post_gc_sync && id == 0;',
         '     int signal_locked = DEV_GC_LOCK_ROOT_WAKE && post_gc_sync && id == 0;'),
        ('     ___WORD_STORE_RELEASE(&ps->field,val);',
         continuation.join(('     if (post_gc_sync && id == 0 && n == 3)',
                            '       join_epoch_publish(___PROCESSOR_ID(ps,___vms));',
                            '     if (post_gc_sync && id == 0 && n == 3)',
                            '       join_epoch_release(___PROCESSOR_ID(ps,___vms), 0);',
                            '     ___WORD_STORE_RELEASE(&ps->field,val);',
                            '     if (post_gc_sync && id == 0 && n == 3)',
                            '       join_epoch_release(___PROCESSOR_ID(ps,___vms), 1);'))),
        ('      sop = ___ps->sync_op0;\n      SYNC_ACK_MSG',
         '      if (post_gc_sync && n == 3) join_epoch_consume(id, receipt_route, wait_enter, wait_return);\n'
         '      sop = ___ps->sync_op0;\n      SYNC_ACK_MSG'),
        ('   * Propagate winning operation to children processors.\n   */',
         '   * Propagate winning operation to children processors.\n   */\n'
         '  if (post_gc_sync && id == 0 && n == 3) join_epoch_begin();'),
    ])


def apply_final_wake_treatment(lib: Path, setup: Path) -> None:
    """Route only the final in-collector reply through the DEV treatment."""
    edit(lib / "mem.c", [
        ('#include "setup.h"', '#include "setup.h"\n'
         'extern void dev_gc_final_barrier(___PSDNC);'),
    ])
    edit(lib / "_mem/collection-round.inc", [
        ('  if (___PROCESSOR_ID(___ps,___vms)==0 && !___root_round_end(___ps))\n'
         '    rc_contract_error("Frozen root union cannot retire before member restoration");\n'
         '  BARRIER();',
         '  if (___PROCESSOR_ID(___ps,___vms)==0 && !___root_round_end(___ps))\n'
         '    rc_contract_error("Frozen root union cannot retire before member restoration");\n'
         '  dev_gc_final_barrier(___PSPNC);'),
    ])
    continuation = " " + chr(92) + "\n"
    edit(setup, [
        ("#define SYNC_SEND_MSG(ps,field,val)",
         "#if !defined(DEV_GC_FINAL_SIGNAL_LOCKED) || "
         "(DEV_GC_FINAL_SIGNAL_LOCKED != 0 && DEV_GC_FINAL_SIGNAL_LOCKED != 1)\n"
         "#error DEV_GC_FINAL_SIGNAL_LOCKED must be 0 or 1\n"
         "#endif\n"
         "static _Thread_local int dev_gc_final_exchange;\n"
         "#define SYNC_SEND_MSG(ps,field,val)"),
        (continuation.join(('     ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     ___CONDVAR_SIGNAL(ps->sync_cv);')) + continuation,
         continuation.join((
             '     int dev_gc_locked = DEV_GC_FINAL_SIGNAL_LOCKED && dev_gc_final_exchange &&',
             '                         id == 0 && n == 3 && &ps->field == &ps->sync_id0;',
             '     if (dev_gc_locked) ___CONDVAR_SIGNAL(ps->sync_cv);',
             '     ___MUTEX_UNLOCK(ps->sync_mut);',
             '     if (!dev_gc_locked) ___CONDVAR_SIGNAL(ps->sync_cv);',
         )) + continuation),
        ('void barrier_sync_noop\n',
         'void dev_gc_final_barrier(___PSDNC)\n'
         '{\n'
         '  dev_gc_final_exchange = 1;\n'
         '  barrier_sync_noop(___PSPNC);\n'
         '  dev_gc_final_exchange = 0;\n'
         '}\n\n'
         'void barrier_sync_noop\n'),
    ])


_FINAL_SIGNAL_TREATMENT = (
    '     int dev_gc_locked = DEV_GC_FINAL_SIGNAL_LOCKED && dev_gc_final_exchange &&',
    '                         id == 0 && n == 3 && &ps->field == &ps->sync_id0;',
    '     if (dev_gc_locked) ___CONDVAR_SIGNAL(ps->sync_cv);',
    '     ___MUTEX_UNLOCK(ps->sync_mut);',
    '     if (!dev_gc_locked) ___CONDVAR_SIGNAL(ps->sync_cv);',
)


def instrument_final_epoch(
    lib: Path, setup: Path, *, wake_treatment: bool = False, observe_wait: bool = False
) -> None:
    """Mark final GC tree exchange by exact VM, carrier, and frozen epoch."""
    if observe_wait and not wake_treatment:
        raise ValueError("Final wait observation requires the matched signal treatment")
    mem = lib / "_mem"
    barrier = ("dev_gc_final_barrier(___PSPNC);" if wake_treatment
               else "GC_BARRIER_SITE_PUBLISH(17, BARRIER());")
    signal = (
        '     ___MUTEX_UNLOCK(ps->sync_mut);',
        '     ___CONDVAR_SIGNAL(ps->sync_cv);',
    )
    if wake_treatment:
        signal = _FINAL_SIGNAL_TREATMENT
        edit(setup, [
            ('#include <stddef.h>', '#include <stddef.h>\n#include "gc-pause-overlay.h"'),
        ])
    edit(lib / "mem.c", [
        ('#include <string.h>', '#include <string.h>\n'
         'extern void dev_gc_final_enter(unsigned, const void *, ___UWORD, double);\n'
         'extern void dev_gc_final_leave(unsigned, const void *);'),
    ])
    edit(mem / "collection-round.inc", [
        (barrier,
         "dev_gc_final_enter(___PROCESSOR_ID(___ps,___vms), ___vms, rc_epoch,\n"
         "                     ___PROCESSOR_ID(___ps,___vms)==0 ? real_time : 0.0);\n"
         f"  {barrier}\n"
         "  dev_gc_final_leave(___PROCESSOR_ID(___ps,___vms), ___vms);"),
    ])
    continuation = " " + chr(92) + "\n"
    edit(setup, [
        ('#include "gc-pause-overlay.h"',
         '#include "gc-pause-overlay.h"\n'
         'static _Thread_local int dev_gc_final_active;\n'
         'void dev_gc_final_enter(unsigned id, const void *vm, ___UWORD epoch, double reported_gc_seconds)\n'
         '{\n'
         '#ifdef DEV_GC_ADJACENT_EPOCHS\n'
         '  dev_gc_final_active = epoch % 16 < 2;\n'
         '#else\n'
         '  dev_gc_final_active = epoch % 16 == 0;\n'
         '#endif\n' 
         '  if (dev_gc_final_active) {\n'
         "    pause_record(id, vm, '@', epoch);\n"
         '#ifdef DEV_GC_ADJACENT_EPOCHS\n'
         '    if (id == 0)\n'
         "      pause_record(id, vm, '%', (uint64_t)(reported_gc_seconds * 1000000000.0 + 0.5));\n"
         '#endif\n'
         "    pause_record(id, vm, '<', pause_now());\n"
         '  }\n'
         '}\n'
         'void dev_gc_final_leave(unsigned id, const void *vm)\n'
         '{\n'
         "  if (dev_gc_final_active) pause_record(id, vm, '>', pause_now());\n"
         '  dev_gc_final_active = 0;\n'
         '}'),
        (continuation.join(('     ___WORD_STORE_RELEASE(&ps->field,val);',
                            *signal)) + continuation,
         continuation.join(('     int dev_gc_down = dev_gc_final_active && id == 0 &&',
                            '                       &ps->field == &ps->sync_id0;',
                            '     uint64_t dev_gc_before = dev_gc_down ? pause_now() : 0;',
                            '     ___WORD_STORE_RELEASE(&ps->field,val);',
                            '     uint64_t dev_gc_after = dev_gc_down ? pause_now() : 0;',
                            *signal,
                            '     if (dev_gc_down) {',
                            "       pause_record(id, ___vms, '#', ___PROCESSOR_ID(ps,___vms));",
                            "       pause_record(id, ___vms, '{', dev_gc_before);",
                            "       pause_record(id, ___vms, '}', dev_gc_after);",
                            '     }')) + continuation),
        ('      SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));',
         '      SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));\n'
         "      if (dev_gc_final_active) pause_record(id, ___vms, '=', pause_now());"),
    ])

    if observe_wait:
        instrument_final_wait_exposure(setup)


def instrument_final_wait_exposure(setup: Path) -> None:
    """Extend a prepared final-epoch treatment with recipient wait events."""
    continuation = " " + chr(92) + "\n"
    signal = _FINAL_SIGNAL_TREATMENT
    # Keep the normal epoch trace readable. Exposure events are separate
    # and emitted only for the final downward reply.
    edit(setup, [
        ('static _Thread_local int dev_gc_final_active;',
         'static _Thread_local int dev_gc_final_active;\n'
         'static _Thread_local int dev_gc_final_receiving;'),
        ('      SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));',
         '      dev_gc_final_receiving = dev_gc_final_active;\n'
         '      SYNC_GET_MSG(sid = ___WORD_LOAD_ACQUIRE(&___ps->sync_id0));\n'
         '      dev_gc_final_receiving = 0;'),
        ('  ___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);',
         '  if (dev_gc_final_receiving) {\n'
         '    ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);\n'
         '    unsigned receiver = ___PROCESSOR_ID(___ps, vm);\n'
         "    pause_record(receiver, vm, 'w', pause_now());\n"
         '    ___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);\n'
         "    pause_record(receiver, vm, 'z', pause_now());\n"
         '  } else ___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);'),
        (continuation.join(signal) + continuation,
         continuation.join((
             *signal[:2],
             '     if (dev_gc_down) {',
             "       pause_record(id, ___vms, 'q', ___PROCESSOR_ID(ps,___vms));",
             "       pause_record(id, ___vms, 'l', dev_gc_locked);",
             '     }',
             '     if (!dev_gc_locked) ___MUTEX_UNLOCK(ps->sync_mut);',
             "     if (dev_gc_down) pause_record(id, ___vms, 's', pause_now());",
             '     ___CONDVAR_SIGNAL(ps->sync_cv);',
             "     if (dev_gc_down) pause_record(id, ___vms, 't', pause_now());",
             '     if (dev_gc_locked) ___MUTEX_UNLOCK(ps->sync_mut);',
         )) + continuation),
    ])


def instrument_barrier_wait(path: Path) -> None:
    """Pair the sync condition call with its enclosing sampled GC barrier."""
    continuation = " " + chr(92) + "\n"
    edit(path, [
        (continuation.join(('     ___WORD_STORE_RELEASE(&ps->field,val);',
                            '     ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     ___CONDVAR_SIGNAL(ps->sync_cv);')) + continuation,
         continuation.join(('     unsigned dev_gc_site = dev_gc_barrier_publication_site();',
                            '     uint64_t dev_gc_before = dev_gc_site ? pause_now() : 0;',
                            '     ___WORD_STORE_RELEASE(&ps->field,val);',
                            '     uint64_t dev_gc_after = dev_gc_site ? pause_now() : 0;',
                            '     ___MUTEX_UNLOCK(ps->sync_mut);',
                            '     if (dev_gc_site) {',
                            '       unsigned recipient = ___PROCESSOR_ID(ps,___vms);',
                            '       uint64_t identity = ((uint64_t)dev_gc_site << 32) | recipient;',
                            '       DEV_GC_PUBLISH_KERNEL(id, identity, dev_gc_after);',
                            '       ___CONDVAR_SIGNAL(ps->sync_cv);',
                            "       pause_record(id, ___vms, 'b', dev_gc_before);",
                            "       pause_record(id, ___vms, 'c', dev_gc_after);",
                            "       pause_record(id, ___vms, 'f', identity);",
                            '     } else if (dev_gc_post_collect_sync && id == 0) {',
                            '       unsigned recipient = ___PROCESSOR_ID(ps,___vms);',
                            '       uint64_t token = pause_now();',
                            '       DEV_GC_SIGNAL_KERNEL(recipient, token, 0);',
                            '       ___CONDVAR_SIGNAL(ps->sync_cv);',
                            '       DEV_GC_SIGNAL_KERNEL(recipient, token, 1);',
                            '     } else ___CONDVAR_SIGNAL(ps->sync_cv);')) + continuation),
        ('#include "gc-pause-overlay.h"', '#include "gc-pause-overlay.h"\n'
         'extern uint64_t dev_gc_barrier_wait_begin(void);\n'
         'extern unsigned dev_gc_barrier_wait_site(void);\n'
         'extern unsigned dev_gc_barrier_publication_site(void);\n'
         '#ifdef DEV_GC_KERNEL_CLOCK\n'
         'extern void dev_gc_kernel_publication(unsigned sender, uint64_t identity, uint64_t after);\n'
         'extern void dev_gc_kernel_signal(unsigned recipient, uint64_t token, unsigned end);\n'
         '#define DEV_GC_SIGNAL_KERNEL(recipient, token, end) dev_gc_kernel_signal(recipient, token, end)\n'
         '#define DEV_GC_PUBLISH_KERNEL(sender, identity, after) dev_gc_kernel_publication(sender, identity, after)\n'
         '#else\n'
         '#define DEV_GC_PUBLISH_KERNEL(sender, identity, after) ((void)0)\n'
         '#define DEV_GC_SIGNAL_KERNEL(recipient, token, end) ((void)0)\n'
         '#endif\n'
         'extern void dev_gc_barrier_wait_end(uint64_t start);\n'
         '#ifdef DEV_GC_TAIL_TRACE\n'
         'extern void dev_gc_tail_enable(void);\n'
         'static _Thread_local unsigned dev_gc_tail_carrier;\n'
         'static _Thread_local const void *dev_gc_tail_vm;\n'
         '#ifdef DEV_GC_ENTRY_TRACE\n'
         'void dev_gc_phase_entry(unsigned id, const void *vm)\n'
         '{\n'
         '  dev_gc_tail_carrier = id;\n'
         '  dev_gc_tail_vm = vm;\n'
         "  pause_record(id, vm, 'I', pause_now());\n"
         '}\n'
         '#endif\n'
         '#ifdef DEV_GC_ALLOCATOR_OS\n'
         'void dev_gc_allocator_anchor(void)\n'
         '{\n'
         '  unsigned id = dev_gc_tail_carrier;\n'
         '  uint64_t tid = 0;\n'
         '  if (pthread_threadid_np(NULL, &tid) != 0) return;\n'
         '  uint64_t stamp = pause_now();\n'
         '  int status = dev_gc_kernel_clock(id, tid, stamp);\n'
         "  pause_record(id, dev_gc_tail_vm, 'T', tid);\n"
         "  pause_record(id, dev_gc_tail_vm, status == 0 ? 'K' : 'E', stamp);\n"
         '}\n'
         'void dev_gc_allocator_interval(uint64_t start, uint64_t end)\n'
         '{\n'
         "  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, 'm', start);\n"
         "  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, 'n', end);\n"
         '}\n'
         '#endif\n'
         '#ifdef DEV_GC_ROUND_TOTALS\n'
         'void dev_gc_phase_total(unsigned bucket, uint64_t elapsed)\n'
         '{\n'
         "  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, \"23456789xyz\"[bucket - 2], elapsed);\n"
         '}\n'
         '#endif\n'
         'void dev_gc_tail_interval(unsigned bucket, uint64_t start, uint64_t end)\n'
         '{\n'
         '  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, \'i\', bucket);\n'
         '  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, \'j\', start);\n'
         '  pause_record(dev_gc_tail_carrier, dev_gc_tail_vm, \'k\', end);\n'
         '}\n'
         '#endif\n'
         '#ifdef DEV_GC_COND_CLOCK\n'
         '#if defined(DEV_GC_LONG_WAIT_NS) && !defined(DEV_GC_RAW_UPTIME)\n'
         '#error "long wait capture requires the shared raw uptime clock"\n'
         '#endif\n'
         '#ifndef DEV_GC_COND_SAMPLE_STRIDE\n'
         '#define DEV_GC_COND_SAMPLE_STRIDE 64u\n'
         '#endif\n'
         'static_assert(DEV_GC_COND_SAMPLE_STRIDE > 0 &&\n'
         '              (DEV_GC_COND_SAMPLE_STRIDE & (DEV_GC_COND_SAMPLE_STRIDE - 1u)) == 0,\n'
         '              "wait sample stride must be a positive power of two");\n'
         'static _Thread_local unsigned dev_gc_wait_sequence;\n'
         'static void dev_gc_wait_clock(unsigned id, const void *vm)\n'
         '{\n'
         '  if (dev_gc_clock_tid) {\n'
         '    uint64_t stamp = pause_now();\n'
         '    int status = dev_gc_kernel_clock(id, dev_gc_clock_tid, stamp);\n'
         '    pause_record(id, vm, status == 0 ? \'K\' : \'E\', stamp);\n'
         '  }\n'
         '}\n'
         '#endif'),
        ('  ___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);',
         '  uint64_t dev_gc_wait_start = dev_gc_barrier_wait_begin();\n'
         '#ifdef DEV_GC_COND_CLOCK\n'
         '  unsigned dev_gc_stride = dev_gc_barrier_publication_site() ? 2u : DEV_GC_COND_SAMPLE_STRIDE;\n'
         '  int dev_gc_observe_wait = dev_gc_wait_start && (dev_gc_wait_sequence++ & (dev_gc_stride - 1u)) == 0;\n'
         '  if (dev_gc_observe_wait)\n'
         '  {\n'
         '    ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);\n'
         '    unsigned id = ___PROCESSOR_ID(___ps,vm);\n'
         '    dev_gc_wait_clock(id, vm);\n'
         '    pause_record(id, vm, \'w\', pause_now());\n'
         '  }\n'
         '#endif\n'
         '  ___CONDVAR_WAIT(___ps->sync_cv, ___ps->sync_mut);\n'
         '#ifdef DEV_GC_COND_CLOCK\n'
         '#ifdef DEV_GC_LONG_WAIT_NS\n'
         '  uint64_t dev_gc_wait_end = dev_gc_wait_start ? pause_now() : 0;\n'
         '  int dev_gc_long_wait = dev_gc_wait_start && dev_gc_wait_end >= dev_gc_wait_start &&\n'
         '    dev_gc_wait_end - dev_gc_wait_start >= DEV_GC_LONG_WAIT_NS;\n'
         '  if (dev_gc_observe_wait || dev_gc_long_wait)\n'
         '#else\n'
         '  if (dev_gc_observe_wait)\n'
         '#endif\n'
         '  {\n'
         '    ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);\n'
         '    unsigned id = ___PROCESSOR_ID(___ps,vm);\n'
         '#ifdef DEV_GC_LONG_WAIT_NS\n'
         '    if (!dev_gc_observe_wait) pause_record(id, vm, \'w\', dev_gc_wait_start);\n'
         '    pause_record(id, vm, \'e\', dev_gc_wait_end);\n'
         '#else\n'
         '    pause_record(id, vm, \'e\', pause_now());\n'
         '#endif\n'
         '    pause_record(id, vm, \'v\', dev_gc_barrier_wait_site());\n'
         '    if (dev_gc_observe_wait) dev_gc_wait_clock(id, vm);\n'
         '#ifdef DEV_GC_TAIL_TRACE\n'
         '    dev_gc_tail_carrier = id;\n'
         '    dev_gc_tail_vm = vm;\n'
         '#ifdef DEV_GC_LONG_WAIT_NS\n'
         '    if (!dev_gc_barrier_publication_site() || dev_gc_long_wait)\n'
         '#endif\n'
         '      dev_gc_tail_enable();\n'
         '#endif\n'
         '  }\n'
         '#endif\n'
         '  dev_gc_barrier_wait_end(dev_gc_wait_start);'),
    ])


def materialize_sequenced_park(source_lib: Path, output: Path) -> None:
    """Publish the translation unit and overlay leaves under workspace custody."""
    import hashlib
    import json
    import os

    from gambit_smp.workspace import inherited_lease, task_output

    root = Path.cwd()
    task = os.environ.get("GAMBIT_SMP_TASK_ID")
    if not task or inherited_lease(root, task) is None:
        raise ValueError("DEV overlay materialization requires an inherited task lease")
    output = output.resolve()
    if task_output(root, output).resolve() != output:
        raise ValueError("DEV overlay output must belong to the current task")

    leaves = ("mem.c", "root.h", "_mem/heap-sections.inc", "_mem/object-scanning.inc",
              "_mem/collection-round.inc")
    inputs = {name: (source_lib / name).read_bytes() for name in leaves}
    identity = {
        "scope": "dev-overlay-source-only",
        "generatorSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "inputs": {name: hashlib.sha256(data).hexdigest()
                   for name, data in inputs.items()},
        "nativeExecuted": False,
    }
    lib = output / "lib"
    receipt_path = output / "source-receipt.json"

    def output_hashes():
        return {name: hashlib.sha256((lib / name).read_bytes()).hexdigest()
                for name in leaves}

    if output.exists():
        if not receipt_path.is_file():
            raise ValueError("incomplete DEV overlay requires workspace reconciliation")
        if json.loads(receipt_path.read_text()) != dict(identity, outputs=output_hashes()):
            raise ValueError("existing DEV overlay does not match this exact request")
        return

    output.mkdir(parents=True, exist_ok=False)
    for name, data in inputs.items():
        path = lib / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    apply_sequenced_park(lib)

    receipt = dict(identity, outputs=output_hashes())
    pending_receipt = receipt_path.with_suffix(".pending")
    pending_receipt.write_text(json.dumps(receipt, indent=2) + "\n")
    pending_receipt.replace(receipt_path)


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "sequenced-park":
        materialize_sequenced_park(Path(sys.argv[2]), Path(sys.argv[3]))
    else:
        instrument(Path(sys.argv[1]))
