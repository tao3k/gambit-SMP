import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import validate
from gambit_smp.protocol_evidence import bundle_facts


class EndedInterruptResultLifecycleTests(unittest.TestCase):
    def test_native_failure_has_a_corresponding_model_counterexample(self):
        manifest = "evidence/fixtures/sfun-owned-unwind/ended-interrupt-result-contract.json"
        folder = "evidence/model-results/fixtures/sfun-owned-unwind/ended-interrupt-result-native-feedback"
        facts, _ = bundle_facts(ROOT, manifest, folder + "/receipt.json")
        self.assertEqual(len(facts["protocol_control"]), 3)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        trace = json.loads((ROOT / folder / "ended_interrupt_result_lifecycle-old-outcomeSafe.trace.json").read_text())
        final = trace["states"][-1]["s"]
        self.assertEqual(final["result"], 2)
        self.assertEqual(final["outcome"], 3)
        self.assertFalse(final["locked"])
        archive = "evidence/source-results/fixtures/sfun-owned-unwind/ended-interrupt-result-abandon-denial/archive.json"
        validate(ROOT, archive)
        native = (ROOT / archive).parent
        receipt = json.loads((native / "receipt.json").read_text())
        self.assertEqual(receipt["status"], "DENY")
        self.assertFalse(receipt["results"][0]["timeout"])
        log = (native / "gsi-0.log").read_text()
        self.assertEqual(log.count("FAILED (test-error abandoned-mutex-exception? (mutex-lock! request)) GOT #t"), 2)

    def test_source_candidate_changes_only_the_smp_slow_path(self):
        parent = json.loads((ROOT / "evidence/fixtures/sfun-owned-unwind/source.lock.json").read_text())
        candidate = json.loads((ROOT / "evidence/fixtures/abandoned-result-state/source.lock.json").read_text())
        self.assertEqual(candidate["revision"], parent["revision"])
        self.assertEqual(set(candidate["files"]), set(parent["files"]))
        self.assertEqual([name for name in parent["files"]
                          if candidate["files"][name] != parent["files"][name]], ["lib/_thread.scm"])
        self.assertEqual(candidate["patchSha256"], digest(ROOT / candidate["patch"]))
        patch = (ROOT / candidate["patch"]).read_text()
        self.assertIn("+                           (if (or (##eq? owner (macro-mutex-state-abandoned))", patch)
        self.assertIn("+                                   (##eq? state (macro-mutex-state-abandoned)))", patch)
        self.assertFalse(candidate["runtimeAdmitted"])
        self.assertFalse(candidate["releaseAdmitted"])


if __name__ == "__main__":
    unittest.main()
