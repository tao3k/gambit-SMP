"""Write a DEV-only setup translation unit with checked rendezvous anchors."""
from pathlib import Path
import sys


def instrument(source: str) -> str:
    def replace(old: str, new: str) -> None:
        nonlocal source
        if source.count(old) != 1:
            raise ValueError(f"Expected one GC timing anchor: {old}")
        source = source.replace(old, new)

    replace('#include <stddef.h>', '#include <stddef.h>\n#include "gc-pause-overlay.h"\nstatic _Thread_local int dev_gc_post_collect_sync;')
    replace(
        '  for (;;)\n    {\n      ___sync_op_struct sop = *sop_ptr;\n'
        '      int winner_id = barrier_sync_op (___PSP &sop);',
        '  int pause_collections = 0;\n  for (;;)\n    {\n'
        '      ___sync_op_struct sop = *sop_ptr;\n'
        '      uint64_t pause_arrival = pause_now();\n'
        "      if (pause_collections) pause_record(id, ___vms, '[', pause_arrival);\n"
        "      dev_gc_post_collect_sync = pause_collections != 0;\n"
        '      int winner_id = barrier_sync_op (___PSP &sop);\n'
        "      dev_gc_post_collect_sync = 0;\n"
        "      if (pause_collections) pause_record(id, ___vms, ']', pause_now());\n"
        "      if (sop.op == OP_GARBAGE_COLLECT) {\n"
        "        pause_record(id, ___vms, 'A', pause_arrival);\n"
        "        ++pause_collections;\n"
        "      }",
    )
    replace(
        '          else\n            execute_sync_op (___PSP &sop);',
        "          else if (sop.op == OP_GARBAGE_COLLECT) {\n"
        "            pause_record(id, ___vms, 'B', pause_now());\n"
        "            execute_sync_op (___PSP &sop);\n"
        "            pause_record(id, ___vms, 'C', pause_now());\n"
        "          } else\n            execute_sync_op (___PSP &sop);",
    )
    replace(
        '  ___lifecycle_drain(___ps);\n  if (id == 0',
        "  if (pause_collections) pause_record(id, ___vms, '(', pause_now());\n"
        "  ___lifecycle_drain(___ps);\n"
        "  if (pause_collections) pause_record(id, ___vms, ')', pause_now());\n"
        "  if (pause_collections)\n"
        "    pause_record(id, ___vms, pause_collections == 1 ? 'U' : 'M', pause_now());\n"
        "#ifdef DEV_GC_RESUME_LABELS\n"
        "  if (pause_collections) dev_gc_arm_resume(id, ___vms);\n"
        "#endif\n"
        "  if (id == 0",
    )
    replace(
        '  ___raise_interrupt_vmstate (___vms, ___INTR_SYNC_OP);',
        "  if (sop_ptr->op == OP_GARBAGE_COLLECT)\n"
        "    pause_record(requester, ___vms, 'Q', pause_now());\n"
        "  ___raise_interrupt_vmstate (___vms, ___INTR_SYNC_OP);",
    )
    return source


if __name__ == "__main__":
    Path(sys.argv[2]).write_text(instrument(Path(sys.argv[1]).read_text()))
