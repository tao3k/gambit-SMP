"""Fresh, bounded suite artifacts are transport evidence, not semantic proofs."""
import json
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp import suite_observations as observations
from gambit_smp import recipes, native_capabilities


class SuiteObservationsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.work = self.root / "shard"
        self.work.mkdir()
        self.declared = {"diagnostic.scm": "observations/cost.json"}

    def test_only_selected_shard_requires_output(self):
        self.assertEqual({}, observations.prepare(self.work, self.declared, ["other.scm"]))
        self.assertFalse((self.work / "observations").exists())

    def test_exact_bytes_frozen_with_no_semantic_admission(self):
        selected = observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        raw = b'{"seconds":0.25,"owners":3}\n'
        path = self.work / "observations/cost.json"
        path.write_bytes(raw)
        result = observations.capture(self.work, selected, self.root / "snapshot")
        self.assertEqual(raw, (self.root / "snapshot/cost.json").read_bytes())
        self.assertFalse(result[0]["semanticAdmitted"])
        path.write_text('{}')
        self.assertEqual(raw, (self.root / "snapshot/cost.json").read_bytes())

    def test_stale_file_rejected_before_launch(self):
        observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        (self.work / "observations/cost.json").write_text('{}')
        with self.assertRaisesRegex(ValueError, "absent before execution"):
            observations.prepare(self.work, self.declared, ["diagnostic.scm"])

    def test_symlink_directory_or_file_rejected(self):
        (self.work / "observations").symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symlinks"):
            observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        (self.work / "observations").unlink()
        selected = observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        (self.work / "observations/cost.json").symlink_to(self.root / "elsewhere")
        with self.assertRaisesRegex(ValueError, "symlinks"):
            observations.capture(self.work, selected, self.root / "snapshot")

    def test_missing_oversized_or_nonobject_output_rejected(self):
        selected = observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        with self.assertRaises(FileNotFoundError):
            observations.capture(self.work, selected, self.root / "missing")
        path = self.work / "observations/cost.json"
        path.write_bytes(b' ' * (observations.MAX_BYTES + 1))
        with self.assertRaisesRegex(ValueError, "bounded regular"):
            observations.capture(self.work, selected, self.root / "oversized")
        path.write_text('[]')
        with self.assertRaisesRegex(ValueError, "JSON object"):
            observations.capture(self.work, selected, self.root / "nonobject")

    def test_contract_rejects_escape_aliases_and_unselected_owner(self):
        for contract in ({"diagnostic.scm": "../cost.json"},
                         {"other.scm": "observations/cost.json"},
                         {"diagnostic.scm": "observations/../cost.json"},
                         {"diagnostic.scm": "observations/cost.scm"},
                         {"diagnostic.scm": "observations/cost.json",
                          "other.scm": "observations/cost.json"}):
            with self.subTest(contract=contract), self.assertRaises(ValueError):
                observations.validate(contract, ["diagnostic.scm", "another.scm"])
        observations.validate(self.declared, ["diagnostic.scm"])

    def test_nonfinite_json_not_admitted(self):
        selected = observations.prepare(self.work, self.declared, ["diagnostic.scm"])
        (self.work / "observations/cost.json").write_text('{"seconds":NaN}')
        with self.assertRaisesRegex(ValueError, "nonfinite"):
            observations.capture(self.work, selected, self.root / "nonfinite")

    def run_group(self, code, timeout=False):
        runtime = self.root / "runtime"
        for name in ("gsi", "gsc", "lib", "include", "bin"):
            (runtime / name).mkdir(parents=True)
        copied = self.root / "tests"
        (copied / "unit-tests").mkdir(parents=True)
        (copied / "unit-tests/diagnostic.scm").write_text("fixture")
        directory = self.root / "run"
        directory.mkdir()
        ctx = recipes.ExecutionContext(self.root, directory, directory, {},
            time.monotonic() + 10, {}, {}, {})
        def executed(argv, cwd, cap, **kwargs):
            (cwd / "observations/cost.json").write_text('{"seconds":0.1}')
            return code, "PASSED ALL 1 UNIT TESTS\n", timeout, 0.1
        with patch.object(recipes, "execute", side_effect=executed):
            return native_capabilities.run_suite_groups(ctx, runtime, copied,
                {"mode": "gsi", "regime": "whole-parallel", "observationFiles": self.declared},
                [Path("diagnostic.scm")], 1, "p1")

    def test_successful_group_captures_declared_payload(self):
        rows = self.run_group(0)
        self.assertTrue(rows[0]["accepted"])
        self.assertEqual("diagnostic.scm", rows[0]["observations"][0]["fixture"])
        self.assertFalse(rows[0]["observations"][0]["semanticAdmitted"])

    def test_failed_group_cannot_admit_a_prepared_payload(self):
        rows = self.run_group(-9, timeout=True)
        self.assertFalse(rows[0]["accepted"])
        self.assertEqual([], rows[0]["observations"])
        self.assertFalse((self.root / "run/suite-observations").exists())

    def test_structured_recipe_preserves_original_workload_and_caps(self):
        from gambit_smp.framework import ROOT
        folder = ROOT / "evidence/research/smp-threaded-vm-native-grid"
        old = json.loads((folder / "vector-arity-busy-delay-observation.recipe.json").read_text())
        current = json.loads((folder / "vector-arity-structured-busy-delay.recipe.json").read_text())
        recipes.load(ROOT, folder / "vector-arity-structured-busy-delay.recipe.json")
        self.assertEqual(old["budgetSeconds"], current["budgetSeconds"])
        self.assertEqual([row["budgetSeconds"] for row in old["steps"]],
                         [row["budgetSeconds"] for row in current["steps"]])
        before = next(row for row in old["steps"] if row["id"] == "busy-delay-gsi")
        after = next(row for row in current["steps"] if row["id"] == "busy-delay-gsi")
        for key in ("expectedFiles", "mode", "regime", "fileBudgetSeconds"):
            self.assertEqual(before["arguments"][key], after["arguments"][key])
        self.assertNotIn("processors", after["arguments"])
        program = ROOT / after["arguments"]["additionalFixtures"]["diagnostics/busy_delay_calibration.scm"]["source"]
        self.assertIn("(define repetitions 250)", program.read_text())
        self.assertIn("(define (short-delay) (busy-sleep 6000))", program.read_text())
