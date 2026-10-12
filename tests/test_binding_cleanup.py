import importlib
import os
from pathlib import Path
import sys
import unittest

from gambit_smp.ascent_program import engine_api
from gambit_smp.framework import ROOT, execute


class BindingCleanupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()
        cls.api = Path(importlib.import_module("_ascent_cffi").__file__).resolve().parent
        cls.binding = Path(importlib.import_module("ascent_engine").__file__).resolve().parent.parent

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def run_child(self, suffix, limit):
        script = '''from ascent_engine import Engine
engine = Engine()
source = """(def (make-work)
  (ascent
    (relation input ((x exact-integer?)) [[1]])
    (relation output ((x exact-integer?)))
    ((output X) <-- (input X))))"""
session = engine.evidence(source, "make-work", trusted=True)
result = session.run(0, queries=["output"])
assert result["complete"] is False
session.close()
engine.shutdown()
print("NATIVE-DEADLINE-CLOSED", flush=True)
''' + suffix
        env = dict(os.environ, PYTHONPATH=os.pathsep.join([str(self.api), str(self.binding)]),
                   GERBIL_PATH="/unavailable", GERBIL_HOME="/unavailable")
        metadata = {}
        result = execute([sys.executable, "-B", "-c", script], ROOT, limit, env=env, metadata=metadata)
        return result, metadata

    def test_failed_child_status_is_not_consumed_by_gambit(self):
        (code, log, timed_out, _), metadata = self.run_child("raise SystemExit(23)\n", 20)
        self.assertEqual(23, code, log)
        self.assertFalse(timed_out)
        self.assertIn("NATIVE-DEADLINE-CLOSED", log)
        self.assertTrue(metadata["parentReaped"])
        self.assertTrue(metadata["processGroupQuiescent"])

    def test_wall_timeout_reaps_native_host_and_entire_process_group(self):
        (code, log, timed_out, _), metadata = self.run_child("import time\ntime.sleep(60)\n", 5)
        self.assertTrue(timed_out, log)
        self.assertNotEqual(0, code)
        self.assertIn("NATIVE-DEADLINE-CLOSED", log)
        self.assertTrue(metadata["parentReaped"])
        self.assertTrue(metadata["processGroupQuiescent"])


if __name__ == "__main__":
    unittest.main()
