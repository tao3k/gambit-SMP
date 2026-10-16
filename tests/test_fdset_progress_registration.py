import json
from pathlib import Path
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT
from gambit_smp.protocol_evidence import bundle_facts


MANIFEST = "evidence/fixtures/fdset-abort-owned-rollback/progress-contract.json"
RECEIPT = "evidence/model-results/fixtures/fdset-abort-owned-rollback/progress/receipt.json"


class FDSetProgressRegistrationTests(unittest.TestCase):
    def test_published_progress_is_model_only_and_contains_temporal_completion(self):
        saved = json.loads((ROOT / RECEIPT).read_text())
        self.assertTrue(saved["accepted"])
        self.assertFalse(saved["runtimeAdmitted"])
        self.assertFalse(saved["releaseAdmitted"])
        self.assertEqual(saved["native"], {"status": "not-run"})
        positive = [row for row in saved["results"] if row["variant"] == "protocol"]
        self.assertEqual(len(positive), 1)
        self.assertEqual(positive[0]["temporal"], "completion")
        self.assertEqual(positive[0]["states"]["queued"], 0)
        log = (ROOT / RECEIPT).parent / positive[0]["log"]
        self.assertIn("Finished checking temporal properties", log.read_text())

    def test_published_readback_does_not_access_disposable_cache(self):
        original = Path.open
        def guarded(path, *args, **kwargs):
            if path.is_relative_to(ROOT) and ".data" in path.relative_to(ROOT).parts:
                raise AssertionError("disposable cache read: " + str(path))
            return original(path, *args, **kwargs)
        with patch.object(Path, "open", guarded):
            rows, inputs = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual([row[0] for row in rows["protocol_checked"]],
                         ["fdset_abort_setup_progress"])
        self.assertTrue(all(".data" not in Path(name).parts for name in inputs))

    def test_progress_does_not_admit_the_separately_registered_base(self):
        rows, _ = bundle_facts(ROOT,
            "evidence/fixtures/fdset-abort-owned-rollback/protocol-contract.json",
            "evidence/model-results/fixtures/fdset-abort-owned-rollback/protocol-qualification/receipt.json")
        self.assertIn("fdset_abort_setup_ownership", [row[0] for row in rows["protocol_model"]])
        self.assertEqual(rows["protocol_checked"], [])
        progress, _ = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual(progress["protocol_composes"],
                         [("fdset_abort_setup_progress", "fdset_abort_setup_ownership")])
        self.assertEqual(len(progress["protocol_obligation"]), 3)


if __name__ == "__main__":
    unittest.main()
