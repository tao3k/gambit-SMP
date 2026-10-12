"""Real native Scheme DSL policy tests, not a Python recovery decision engine."""
import unittest

from gambit_smp.ascent_program import engine_api, load_catalog, query
from gambit_smp.framework import ROOT


class RecoveryPolicyTests(unittest.TestCase):
    def setUp(self):
        self.catalog = load_catalog(ROOT / "evidence/dsl/recovery.ss")
        self.facts = {name: [["source"], ["core"]] for name in (
            "checkpoint", "receipt_bound", "producer_pass", "artifact_bound", "input_bound",
            "process_quiescent", "clock_bound", "budget_remaining", "recovery_reviewed")}
        self.facts["checkpoint_dependency"] = [["core", "source"]]

    def evaluate(self):
        with engine_api() as (engine, _):
            return query(self.facts, self.catalog,
                {"resumable": "resumable", "gaps": "recovery_gap", "readable": "evidence_readable"},
                engine=engine)

    def test_closed_checkpoints_and_dependencies_are_resumable(self):
        result = self.evaluate()
        self.assertEqual([("core",), ("source",)], result["resumable"])
        self.assertEqual([], result["gaps"])

    def test_each_missing_obligation_blocks_descendants(self):
        for name in ("receipt_bound", "producer_pass", "artifact_bound", "input_bound",
                     "process_quiescent", "clock_bound", "budget_remaining", "recovery_reviewed"):
            with self.subTest(obligation=name):
                original = self.facts[name]
                self.facts[name] = [["core"]]
                result = self.evaluate()
                self.assertEqual([], result["resumable"])
                self.assertIn(("core", "dependency-unqualified"), result["gaps"])
                self.facts[name] = original

    def test_expired_evidence_is_readable_not_resumable(self):
        self.facts["budget_remaining"] = []
        result = self.evaluate()
        self.assertEqual([], result["resumable"])
        self.assertEqual([("core",), ("source",)], result["readable"])

    def test_unknown_dependency_blocks_downstream_checkpoint(self):
        self.facts["checkpoint_dependency"] = [["core", "absent"]]
        result = self.evaluate()
        self.assertEqual([("source",)], result["resumable"])
        self.assertIn(("core", "dependency-missing"), result["gaps"])

    def test_dependency_cycle_is_not_a_recovery_proof(self):
        self.facts["checkpoint_dependency"].append(["source", "core"])
        result = self.evaluate()
        self.assertEqual([], result["resumable"])
        self.assertIn(("source", "dependency-cycle"), result["gaps"])
