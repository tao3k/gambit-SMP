import unittest

from gambit_smp.evidence_index import export


class FrozenTraceHistoryBindingsTest(unittest.TestCase):
    """Historical table/FFI traces stay predecessor facts from evidence_index.export."""

    CASES = ("ffi_gc_frame_protocol", "gc_table_iteration")

    def test_stale_traces_bind_verified_predecessors_not_current_models(self):
        facts = export()["facts"]
        historical = list(facts["historical_frozen_negative"])
        current = {row[0] for row in facts["frozen_negative"]}
        bound = [row for row in historical if row[0] in self.CASES]
        self.assertGreaterEqual(len(bound), 5)
        for case in self.CASES:
            self.assertNotIn(case, current)
            snapshots = [row[3] for row in bound if row[0] == case]
            self.assertTrue(snapshots)
            for snapshot in snapshots:
                self.assertTrue(
                    snapshot.startswith("evidence/model-results/frozen-trace-predecessors/" + case + "-"))
        names = current | {row[0] for row in historical}
        self.assertNotIn("predicate_lock_retry_rooting", names)


if __name__ == "__main__":
    unittest.main()
