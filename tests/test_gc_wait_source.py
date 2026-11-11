import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import json

from gambit_smp import gc_wait_source as schedule


class GCWaitSourceTests(unittest.TestCase):
    @staticmethod
    def source():
        names = ("___PSTATE_MEM", "___VMSTATE_MEM", "alloc_heap_ptr", "alloc_heap_chunk_start",
                 "heap_chunks_to_scan_lock", "heap_chunks_to_scan_head", "heap_chunks_to_scan_tail",
                 "scan_ptr", "scan_termination_mutex", "scan_termination_condvar", "NULL_CHUNK_LINK")
        macros = "\n".join("#define " + name + " example" for name in names)
        return macros + "\n___HIDDEN void end_heap_chunk\n{ publish(); }\n" \
            "___HIDDEN void set_heap_msection\n{ other(); }\n" \
            "      /* Signal being idle and wait for more work or termination */\n" \
            "      ___MUTEX_LOCK(scan_termination_mutex);\n      idle();\n    }\n\n#endif\n}\n"

    def test_extraction_keeps_source_publisher_and_wait_block(self):
        publisher, wait = schedule.extract(self.source())
        self.assertIn("{ publish(); }", publisher)
        self.assertNotIn("set_heap_msection", publisher)
        self.assertEqual("      ___MUTEX_LOCK(scan_termination_mutex);\n      idle();", wait)

    def test_ambiguous_publisher_or_macro_is_denied(self):
        source = self.source()
        with self.assertRaisesRegex(ValueError, "boundaries changed"):
            schedule.extract(source + "___HIDDEN void end_heap_chunk\n")
        with self.assertRaisesRegex(ValueError, "unique source macro"):
            schedule.extract("#define scan_ptr duplicate\n" + source)

    def test_missing_wait_or_macro_boundary_is_denied(self):
        source = self.source()
        with self.assertRaisesRegex(ValueError, "idle block boundary"):
            schedule.extract(source.replace("Signal being idle", "Changed idle"))
        with self.assertRaisesRegex(ValueError, "unique source macro"):
            schedule.extract(source.replace("#define scan_ptr example\n", ""))

    def test_changed_context_is_rejected_before_compiler_execution(self):
        from tests.support import task_fixture
        with task_fixture('gc-wait-context') as (root, cache):
            from gambit_smp.cli import main as dispatch
            (root / "evidence").mkdir()
            source, header = root / "mem.c", root / "gambit.h"
            source.write_text("changed")
            header.write_text("changed")
            (root / "evidence/gc-wait-notification.json").write_text(json.dumps({"contextInputs": {}}))
            argv = ["gc-wait-schedule", "--source", str(source), "--header", str(header),
                    "--gcc", "unused-gcc", "--out", str(cache / 'run')]
            with patch.object(schedule, "ROOT", root), patch.object(schedule, "checked_rows"), \
                    patch.object(schedule, "gnu_compiler") as compiler:
                with self.assertRaisesRegex(ValueError, "differs from reviewed model context"):
                    dispatch(['--historical-reproduction', '--task', 'gc-wait-context',
                              'gc-wait-schedule', *argv[1:]])
                compiler.assert_not_called()


if __name__ == "__main__":
    unittest.main()
