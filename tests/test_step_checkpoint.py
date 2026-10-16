"""Generic closure/accounting controls; no synthetic native acceptance."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.step_checkpoint import ancestry, bound, content_id, expenditures


def step(name, dependencies=(), **changes):
    row = {"id": name, "dependsOn": list(dependencies), "outcome": "PASS"}
    row.update(changes)
    return row


class StepCheckpointClosureTests(unittest.TestCase):
    def test_exact_successful_ancestry_excludes_failed_descendant(self):
        rows = [step("source"), step("config", ["source"]), step("seed", ["config"]),
                step("review", ["seed"], outcome="TIMEOUT")]
        self.assertEqual(["source", "config", "seed"], [r["id"] for r in ancestry(rows, "seed")])

    def test_failed_prerequisite_is_not_a_checkpoint(self):
        for outcome in ("DENY", "TIMEOUT", "STALE", "BLOCKED"):
            with self.subTest(outcome=outcome), self.assertRaises(ValueError):
                ancestry([step("source", outcome=outcome), step("seed", ["source"])], "seed")

    def test_missing_cyclic_and_duplicate_dependencies_are_rejected(self):
        for rows in ([step("seed", ["absent"])], [step("a", ["b"]), step("b", ["a"])],
                     [step("a"), step("seed", ["a", "a"])], [step("seed"), step("seed")]):
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                ancestry(rows, "seed" if any(r["id"] == "seed" for r in rows) else "a")

    def test_unverified_native_teardown_rejects_even_pass_label(self):
        command = {"exit": 0, "timeout": False, "parentReaped": True, "processGroupQuiescent": True}
        for key, value in (("exit", 1), ("timeout", True), ("parentReaped", False),
                           ("processGroupQuiescent", False)):
            with self.subTest(key=key), self.assertRaises(ValueError):
                ancestry([step("seed", commands=[{**command, key: value}])], "seed")

    def test_non_finite_observations_cannot_get_a_content_identity(self):
        with self.assertRaises(ValueError):
            content_id({"seconds": float("nan")})

    def test_missing_reference_closure_cannot_be_reconstructed(self):
        with self.assertRaises(ValueError):
            bound(Path("."), {"schema": "successful-step-checkpoint.v1", "run": "old"})


class StepCheckpointExpenditureTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.store = self.root / ".data/fixtures"

    def record(self, name, previous=None, **changes):
        row = {"schema": "sealed-research-run.v1", "recipe": "campaign", "outcome": "DENY",
               "budgetSeconds": 60, "wholeSeconds": 10, "parentReaped": True,
               "processGroupQuiescent": True, "prior": previous}
        row.update(changes)
        path = self.store / name / "receipt.json"
        path.parent.mkdir(parents=True)
        raw = json.dumps(row).encode()
        path.write_bytes(raw)
        return {"run": name, "sha256": hashlib.sha256(raw).hexdigest()}

    def test_every_failed_predecessor_is_charged(self):
        first = self.record("first")
        second = self.record("second", {"receiptSha256": first["sha256"]}, budgetSeconds=50)
        result = expenditures(self.root, {"outerReceiptSha256": second["sha256"]}, [first, second])
        self.assertEqual(40, result["remainingSeconds"])
        self.assertFalse(result["prefixReusable"])

    def test_omitted_failure_cannot_reset_the_budget(self):
        first = self.record("first")
        second = self.record("second", {"receiptSha256": first["sha256"]})
        with self.assertRaisesRegex(ValueError, "missing"):
            expenditures(self.root, {"outerReceiptSha256": second["sha256"]}, [second])

    def test_unrelated_extra_receipts_are_rejected(self):
        first = self.record("first")
        extra = self.record("unrelated", recipe="other")
        with self.assertRaises(ValueError):
            expenditures(self.root, {"outerReceiptSha256": first["sha256"]}, [first, extra])

    def test_record_drift_and_duplicate_are_rejected(self):
        record = self.record("first")
        for records in ([record, record], [{**record, "sha256": "0" * 64}]):
            with self.subTest(records=records), self.assertRaises(ValueError):
                expenditures(self.root, {"outerReceiptSha256": record["sha256"]}, records)


if __name__ == "__main__":
    unittest.main()
