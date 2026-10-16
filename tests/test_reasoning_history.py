import json
from contextlib import closing
from pathlib import Path
import sqlite3
import tempfile
import subprocess
import unittest
from unittest.mock import patch

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp import reasoning_history as history


class NativeHistoryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.rules = self.root / "claims.ss"
        self.rules.write_text("(ascent-fragment (relation fact ((value symbol?))) "
                              "(relation claim ((value symbol?))) ((claim X) <-- (fact X)))")

    def observe(self, rows, inputs=None, *, limits=None):
        backend = {}
        answers = query({"fact": rows}, load_catalog(self.rules),
                        {"claims": "claim"}, metrics=backend)
        return history.record(self.root, "test", inputs or {"evidence": "one"}, answers, backend,
                              limits=limits, bound_inputs={})

    def test_repeated_observation_is_native_derived_and_not_execution_authority(self):
        first = self.observe([["known-failure"]])
        second = self.observe([["known-failure"]])
        self.assertIsNone(first["previousObservation"])
        self.assertEqual(first["observation"], second["previousObservation"])
        self.assertEqual(first["observation"], second["observation"])
        self.assertEqual([], second["delta"]["added"])
        self.assertEqual([("claims", ["known-failure"])], second["delta"]["retained"])
        self.assertFalse(second["runtimeAdmitted"])
        self.assertFalse(second["persistedResultReuse"])

    def test_changed_evidence_withdraws_old_conclusion_and_tracks_missing_premise(self):
        self.observe([["model-passed"]])
        result = self.observe([["missing-source-proof"]], {"evidence": "two"})
        self.assertEqual([("claims", ["model-passed"])], result["delta"]["removed"])
        self.assertEqual([("claims", ["missing-source-proof"])], result["delta"]["added"])
        self.assertEqual([("evidence",)], result["delta"]["changedInputs"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_large_history_repeat_rejects_complete_inventory_over_input_bound(self):
        from ascent import EngineError, FactLimits
        # Two complete snapshots exceed the ceiling even for a smaller wheel.
        inputs = {"evidence-" + str(n): "sha-" + str(n) for n in range(4096 // 2 + 1)}
        rows = [["claim-" + str(n)] for n in range(100)]
        first = self.observe(rows, inputs)
        with self.assertRaisesRegex(EngineError, "source fact budget exceeded"):
            self.observe(rows, inputs, limits=FactLimits(input=4096))
        with closing(sqlite3.connect(self.root / ".cache/reasoning/history.sqlite3")) as db:
            self.assertEqual(db.execute("SELECT id FROM heads WHERE scope='test'").fetchone()[0],
                             first["observation"])
            self.assertEqual(db.execute("SELECT count(*) FROM observations").fetchone()[0], 1)
            failed = json.loads(db.execute("SELECT body FROM analysis_results ORDER BY rowid DESC LIMIT 1").fetchone()[0])
            self.assertEqual(failed["status"], "failed")

    def test_default_unlimited_history_preserves_large_inventory_across_growth(self):
        inputs = {"evidence-" + str(n): "sha-" + str(n) for n in range(1100)}
        rows = [["claim-" + str(n)] for n in range(100)]
        first = self.observe(rows, inputs)
        second = self.observe(rows, inputs)
        self.assertEqual(second["previousObservation"], first["observation"])
        self.assertEqual(len(second["delta"]["retained"]), 100)
        self.assertEqual(second["backend"]["nativeFactLimits"],
                         {"input": "unlimited", "derived": "unlimited", "output": "unlimited"})
        inputs["new-evidence"] = "new-sha"
        third = self.observe(rows + [["new-claim"]], inputs)
        self.assertEqual(third["previousObservation"], second["observation"])
        self.assertEqual(third["delta"]["added"], [("claims", ["new-claim"])])
        self.assertIn(("new-evidence",), third["delta"]["addedInputs"])
        with closing(sqlite3.connect(self.root / ".cache/reasoning/history.sqlite3")) as db:
            self.assertEqual(db.execute("SELECT count(*) FROM observations").fetchone()[0], 2)

    def test_repeat_within_complete_input_bound_retains_native_path(self):
        inputs = {"evidence-" + str(n): "sha-" + str(n) for n in range(400)}
        rows = [["claim-" + str(n)] for n in range(100)]
        first = self.observe(rows, inputs)
        second = self.observe(rows, inputs)
        self.assertEqual(second["previousObservation"], first["observation"])
        self.assertEqual(second["observation"], first["observation"])
        self.assertEqual(len(second["delta"]["retained"]), 100)
        self.assertEqual(second["delta"]["added"], [])
        self.assertEqual(second["delta"]["removed"], [])
        self.assertEqual(second["delta"]["changedInputs"], [])
        self.assertFalse(second["runtimeAdmitted"])

    def test_corrupt_observation_is_rejected(self):
        self.observe([["known-failure"]])
        with closing(sqlite3.connect(self.root / ".cache/reasoning/history.sqlite3")) as db, db:
            row = db.execute("SELECT id,body FROM observations").fetchone()
            changed = json.loads(row[1])
            changed["queries"] = {}
            db.execute("UPDATE observations SET body=? WHERE id=?", (json.dumps(changed), row[0]))
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            self.observe([["known-failure"]])

    def test_unbound_or_non_native_result_cannot_enter_history(self):
        for backend in ({}, {"name": "ascent-c-abi"}, {"name": "python", "inputs": {"x": "y"}}):
            with self.assertRaisesRegex(ValueError, "identity-bound"):
                history.record(self.root, "test", {}, {}, backend)

    def test_missing_api_does_not_run_an_alternate_engine(self):
        from ascent.build import runtime_identity
        identity = dict(runtime_identity(), sourceRoot=str(self.root / "missing-source"))
        with patch('ascent.build.runtime_identity', return_value=identity):
            with self.assertRaises(FileNotFoundError):
                self.observe([["known-failure"]])
        self.assertFalse((self.root / ".cache/reasoning/history.sqlite3").exists())

    def test_changed_loaded_implementation_fails_closed(self):
        with patch("gambit_smp.ascent_program._loaded_identity", {"ascent._core": "stale"}):
            with self.assertRaisesRegex(ValueError, "loaded process"):
                self.observe([["known-failure"]])
