"""Transport/accounting checks, not a prefix-continuation qualification."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.recipe_continuation import remaining_budget


class ContinuationBudgetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def receipt(self, name, **changes):
        value = {"schema": "sealed-research-run.v1", "parentReaped": True,
                 "processGroupQuiescent": True, "outcome": "DENY",
                 "wholeSeconds": 10, "budgetSeconds": 60}
        value.update(changes)
        path = self.root / name
        raw = json.dumps(value).encode()
        path.write_bytes(raw)
        return path, hashlib.sha256(raw).hexdigest()

    def test_failed_outer_expenditure_is_not_reset_or_admitted(self):
        observations = [self.receipt("first", wholeSeconds=156.5627377500059, budgetSeconds=600),
                        self.receipt("retry", wholeSeconds=216.5974320420064, budgetSeconds=443)]
        result = remaining_budget(600, observations)
        self.assertAlmostEqual(226.8398302079877, result["remainingSeconds"])
        self.assertEqual(2, len(result["observations"]))
        self.assertFalse(result["prefixReusable"])
        self.assertFalse(result["producerAdmitted"])

    def test_changed_receipt_is_rejected(self):
        observation = self.receipt("first")
        observation[0].write_text("{}")
        with self.assertRaisesRegex(ValueError, "identity"):
            remaining_budget(60, [observation])

    def test_duplicate_receipt_is_rejected(self):
        observation = self.receipt("first")
        with self.assertRaisesRegex(ValueError, "duplicate"):
            remaining_budget(60, [observation, observation])

    def test_non_quiescent_observation_is_rejected(self):
        for field in ("parentReaped", "processGroupQuiescent"):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "quiescent"):
                remaining_budget(60, [self.receipt(field, **{field: False})])

    def test_bad_numeric_values_are_rejected(self):
        for value in (True, -1, 0, float("nan"), float("inf")):
            with self.subTest(value=value), self.assertRaises(ValueError):
                remaining_budget(60, [self.receipt(str(value), wholeSeconds=value)])

    def test_expanded_cap_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "non-expanded"):
            remaining_budget(60, [self.receipt("expanded", budgetSeconds=61)])

    def test_budget_exhaustion_includes_outer_teardown(self):
        with self.assertRaises(TimeoutError):
            remaining_budget(60, [self.receipt("exhausted", wholeSeconds=60.1)])


if __name__ == "__main__":
    unittest.main()
