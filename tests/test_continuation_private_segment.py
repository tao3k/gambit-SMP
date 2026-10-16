"""Source/fixture contracts; these tests are not runtime qualification."""
import json
import unittest

from gambit_smp.framework import ROOT, digest


class ContinuationPrivateSegmentTests(unittest.TestCase):
    def test_wake_successor_preserves_scope_and_no_native_admission(self):
        parent = json.loads((ROOT / "evidence/fixtures/continuation-private-chunk-segment/source.lock.json").read_text())
        child = json.loads((ROOT / "evidence/fixtures/continuation-segment-wake-budget/source.lock.json").read_text())
        self.assertEqual(parent["revision"], child["revision"])
        self.assertEqual(set(parent["files"]), set(child["files"]))
        self.assertEqual({"lib/mem.c"}, {name for name in parent["files"]
                                        if parent["files"][name] != child["files"][name]})
        self.assertEqual(child["patchSha256"], digest(ROOT / child["patch"]))
        self.assertFalse(child["runtimeAdmitted"])
        self.assertFalse(child["releaseAdmitted"])

    def test_wake_protocol_has_real_control_and_exhausted_positive_checks(self):
        receipt = json.loads((ROOT / "evidence/model-results/fixtures/continuation-private-chunk-segment/wake-budget/receipt.json").read_text())
        self.assertTrue(receipt["accepted"])
        self.assertFalse(receipt["runtimeAdmitted"])
        controls = [row for row in receipt["results"] if row["variant"] == "old"]
        positives = [row for row in receipt["results"] if row["variant"] == "protocol"]
        self.assertEqual(len(controls), 1)
        self.assertEqual(controls[0]["exit"], 1)
        self.assertEqual({row["invariant"] for row in positives}, {"safe", "noStall"})
        for row in positives:
            self.assertEqual(row["exit"], 0)
            self.assertEqual(row["states"]["queued"], 0)
            self.assertEqual(row["temporal"], "progress")

    def test_successor_changes_only_collector_from_retirement_parent(self):
        parent = json.loads((ROOT / "evidence/fixtures/public-vm-retirement-composition/source.lock.json").read_text())
        child = json.loads((ROOT / "evidence/fixtures/continuation-private-chunk-segment/source.lock.json").read_text())
        self.assertEqual(parent["revision"], child["revision"])
        self.assertEqual(set(parent["files"]), set(child["files"]))
        self.assertEqual({"lib/mem.c"}, {name for name in parent["files"]
                                        if parent["files"][name] != child["files"][name]})
        self.assertEqual(child["patchSha256"], digest(ROOT / child["patch"]))
        self.assertFalse(child["runtimeAdmitted"])
        self.assertFalse(child["releaseAdmitted"])

    def test_public_regression_keeps_retained_frames_and_full_join_scope(self):
        text = (ROOT / "models/gambit/native/continuation_rollover_public.scm").read_text()
        for required in ("GAMBIT_SMP_AVAILABLE_CPUS", "GAMBIT_SMP_CONTINUATION_DEPTH",
                         "(##thread-pin!", "(##gc)", "(thread-join! worker)",
                         "(condition-variable-broadcast! released)",
                         "(vector-ref payload 1)", "(+ answer 1)"):
            self.assertIn(required, text)
        for forbidden in ("RTLD_NEXT", "dlsym", "___cleanup_owned_vmstate", "c-lambda", "c-declare"):
            self.assertNotIn(forbidden, text)
        self.assertLess(text.index("(##gc)"), text.index("(set! release? #t)"))
        self.assertLess(text.index("(thread-join! worker)"),
                        text.index("(##current-vm-resize ##startup-processor! 1)"))


if __name__ == "__main__":
    unittest.main()
