"""Actual process interruption, disk recovery, and current Library analysis."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from gambit_smp import reasoning_history as history
from gambit_smp.ascent_program import load_component_catalog, query


class HistoryRecoveryTests(unittest.TestCase):
    def test_process_exit_between_append_and_analysis_preserves_pending_and_recovers(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            backend = {}
            catalog = load_component_catalog(history.RULES.parent / "components.json", entry="history",
                                              constructor="make-history", trusted=True)
            query({}, catalog, history.QUERIES, metrics=backend)
            environment = dict(os.environ, HISTORY_BACKEND=json.dumps(backend), HISTORY_ROOT=temporary)
            child = subprocess.run([sys.executable, "-B", "-c", """
import json,os
from gambit_smp.reasoning_history import append_observation,_prepare
root=os.environ['HISTORY_ROOT']
observation=append_observation(root,'task',{'fixture':'sha'}, {'claim':[['retained']]},
                               json.loads(os.environ['HISTORY_BACKEND']))
_prepare(root,observation,None,None)
os._exit(7)
"""], env=environment, capture_output=True, timeout=5)
            self.assertEqual(child.returncode, 7, child.stderr.decode())
            before = history.read_journal(root, "task")
            self.assertIsNone(before["head"])
            self.assertEqual(len(before["pendingAttempts"]), 1)
            self.assertEqual(len(before["observations"]), 1)
            observation = next(iter(before["observations"]))
            result = history.analyze_observation(root, observation)
            self.assertEqual(result["delta"]["added"], [("claim", ["retained"])])
            after = history.read_journal(root, "task")
            self.assertEqual(after["head"], observation)
            self.assertEqual(after["pendingAttempts"], before["pendingAttempts"])
            self.assertEqual(len(after["results"]), 1)
            self.assertFalse(after["runtimeAdmitted"])


if __name__ == "__main__":
    unittest.main()
