import importlib
import os
from pathlib import Path
import sys
import unittest

from gambit_smp.ascent_program import engine_api, artifact_paths
from gambit_smp.framework import ROOT, execute


class BindingCleanupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()
        cls.extension = artifact_paths()['ascent._core']
        cls.binding = Path(importlib.import_module("ascent").__file__).resolve().parent.parent

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def run_child(self, suffix, limit):
        script = '''import os
from ascent import Engine, EngineError
engine = Engine()
source = """(define-evidence (make-work)
    (sources input) (outputs output)
    (relation input ((x exact-integer?)) [[1]])
    (relation output ((x exact-integer?)))
    ((output X) <-- (input X)))"""
session = engine.evidence(source, "make-work", trusted=True)
try:
    session.run(0, queries=["output"])
except EngineError as error:
    assert "deadline" in str(error).lower(), str(error)
else:
    raise AssertionError("exhausted deadline admitted a result")
assert session.run(queries=["output"])["complete"] is True
session.close()
engine.close()
print("NATIVE-DEADLINE-CLOSED", flush=True)
''' + suffix
        env = {key: value for key, value in os.environ.items() if not key.startswith("GERBIL")}
        env["PYTHONPATH"] = str(self.binding)
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
