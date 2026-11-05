"""Real open-file consumers distinguish takeover from cache reclamation."""
import json
import subprocess
import sys
import unittest
from gambit_smp import workspace as w
from tests import test_workspace as fixtures

class TakeoverTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def hold(self, relative):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("owned bytes")
        child = subprocess.Popen([sys.executable, "-c",
            "import sys; f=open(sys.argv[1]); print('READY',flush=True); sys.stdin.read()",
            str(path)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, start_new_session=True)
        self.assertEqual("READY", child.stdout.readline().strip())
        def close():
            child.communicate(timeout=5)
            self.assertEqual(0, child.returncode)
        self.addCleanup(close)
        self.consumer = child
        return path

    def invoke(self, operation):
        if operation == "resume":
            return w.resume(self.root, "repair")
        with w.execution_scope(self.root, "repair"):
            self.assertIsNotNone(w.inherited_lease(self.root, "repair"))

    def test_real_metadata_reader_does_not_block_either_entry(self):
        w.start(self.root, "repair", adopt=True)
        path = self.hold(".cache/tasks/repair/agents/research/request.ss")
        for operation in ("resume", "execute"):
            with self.subTest(operation=operation):
                self.invoke(operation)
                self.assertEqual("owned bytes", path.read_text())

    def test_real_build_consumer_blocks_both_entries(self):
        w.start(self.root, "repair", adopt=True)
        self.hold(".cache/tasks/repair/build/gambit-core/source/input.c")
        for operation in ("resume", "execute"):
            with self.subTest(operation=operation), self.assertRaisesRegex(ValueError, "occupied"):
                self.invoke(operation)

    def test_process_owned_build_consumer_blocks_both_entries(self):
        w.start(self.root, "repair", adopt=True)
        self.hold(".cache/tasks/repair/processes/audit/build/gambit-core/source/input.c")
        for operation in ("resume", "execute"):
            with self.subTest(operation=operation), self.assertRaisesRegex(ValueError, "occupied"):
                self.invoke(operation)

    def test_kernel_lease_blocks_both_entries(self):
        w.start(self.root, "repair", adopt=True)
        with w.lease(self.root, "repair"):
            for operation in ("resume", "execute"):
                with self.subTest(operation=operation), self.assertRaises(BlockingIOError):
                    self.invoke(operation)

    def test_real_registered_consumer_blocks_without_open_build_file(self):
        w.start(self.root, "repair", adopt=True)
        self.hold(".cache/tasks/repair/agents/research/request.ss")
        # The actual live consumer owns a distinct process group. Its metadata
        # file alone is harmless, but its registered outstanding work is not.
        row = self.root / ".state/task-processes/repair/previous/consumer.json"
        row.parent.mkdir(parents=True)
        row.write_text(json.dumps(dict(event="started", token="consumer",
            process="audit", pgid=self.consumer.pid)))
        for operation in ("resume", "execute"):
            with self.subTest(operation=operation), self.assertRaisesRegex(ValueError, "child process group"):
                self.invoke(operation)
        self.consumer.communicate(timeout=5)
        self.assertEqual(0, self.consumer.returncode)
        for operation in ("resume", "execute"):
            self.invoke(operation)
