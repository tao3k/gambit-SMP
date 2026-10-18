"""Transport actual execution receipts without converting them to admission."""
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.framework import ROOT
from tests.historical_view import projection


class FFIExecutionViewTests(unittest.TestCase):
    def test_native_component_and_setup_failure_keep_runtime_duties_open(self):
        document, facts, catalog, inputs = projection(ROOT,
            "evidence/scenarios/concurrent-gc/ffi-execution.view.json")
        self.assertGreater(len(inputs), 70)
        with engine_api() as (engine, _):
            result, _ = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(result["open"]), 9)
            self.assertEqual(len(result["missing_metric"]), 6)
            self.assertEqual(len(result["missing_flag"]), 3)
            outcomes = {row[1] for row in result["observed"]}
            self.assertIn("component-positive-exit0", outcomes)
            self.assertIn("component-negative-exit1", outcomes)
            self.assertIn("DENY-before-FFI-compile", outcomes)
            self.assertEqual(len(result["source_gap"]), 6)


if __name__ == "__main__":
    unittest.main()
