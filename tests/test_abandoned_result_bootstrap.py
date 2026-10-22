import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import validate
from gambit_smp.protocol_evidence import bundle_facts
from tests.support import published_digest
from gambit_smp.output_observations import recorded, TRANSCRIPT_SUFFIXES


class AbandonedResultBootstrapTests(unittest.TestCase):
    def test_two_pass_identity_flags_and_post_bootstrap_coverage(self):
        folder = ROOT / "evidence/source-results/fixtures/abandoned-result-state"
        bootstrap = folder / "two-pass-bootstrap"
        archive = json.loads((bootstrap / "archive.json").read_text())
        for name, sha in archive["files"].items():
            self.assertEqual(published_digest(ROOT, bootstrap / name), sha)
            if (bootstrap / name).suffix not in TRANSCRIPT_SUFFIXES:
                self.assertNotIn("/Users/", (bootstrap / name).read_text())
        receipt = json.loads((bootstrap / "receipt.json").read_text())
        self.assertEqual(receipt["status"], "PASS")
        self.assertEqual(receipt["target"], "from-scratch")
        self.assertEqual(receipt["observedParentExit"], 0)
        self.assertEqual(receipt["wholeBootstrapBudget"], 600)
        self.assertEqual(receipt["processorSelection"], "host-auto")
        self.assertTrue(receipt["repairProofInputsStable"])
        self.assertTrue(receipt["originalSourceStable"])
        self.assertTrue(receipt["immutableSourceStable"])
        self.assertEqual(receipt["recursiveBuildErrors"], [])
        stage = receipt["steps"][0]
        self.assertEqual(stage["exit"], 0)
        self.assertFalse(stage["timeout"])
        self.assertTrue(stage["process"]["parentReaped"])
        self.assertTrue(stage["process"]["processGroupQuiescent"])
        self.assertLessEqual(stage["seconds"], receipt["wholeBootstrapBudget"])
        for flag in ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"):
            self.assertIn(flag, receipt["configurationOptions"])
        output = recorded(ROOT, bootstrap / "bootstrap.log")
        for phase in range(1, 5):
            self.assertEqual(output['buildPhases'][str(phase)], 2)
        rebuilt = json.loads((bootstrap / "candidate.json").read_text())
        seed = json.loads((folder / "native-sync/identity.json").read_text())
        self.assertEqual(rebuilt["sourceFiles"]["lib/_thread.c"], seed["sourceFiles"]["lib/_thread.c"])
        self.assertEqual(set(receipt["changedSourceFiles"]), {"lib/_std.c", "lib/_module.c"})
        for subfolder, count in (("bootstrap-native-sync", 9), ("waiter-transfer-native", 1)):
            native = folder / subfolder
            validate(ROOT, str((native / "archive.json").relative_to(ROOT)))
            identity = json.loads((native / "identity.json").read_text())
            self.assertEqual(identity, rebuilt)
            result = json.loads((native / "receipt.json").read_text())
            self.assertEqual(len(result["selectedFiles"]), count)
            self.assertEqual({row["mode"] for row in result["results"]}, {"gsi", "gsc"})
            self.assertTrue(all(row["accepted"] and row["sourceStable"] for row in result["results"]))
        for field in ("runtimeAdmitted", "releaseAdmitted", "performanceAdmitted", "generatedByteParity"):
            self.assertFalse(receipt[field])

    def test_native_success_corrected_the_wrong_dispatch_abstraction(self):
        manifest = "evidence/fixtures/abandoned-result-state/waiter-dispatch-contract.json"
        folder = "evidence/model-results/fixtures/abandoned-result-state/waiter-dispatch"
        facts, _ = bundle_facts(ROOT, manifest, folder + "/receipt.json")
        self.assertEqual(len(facts["protocol_control"]), 2)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        audit = ROOT / "evidence/model-results/fixtures/abandoned-result-state/waiter-transfer/source-dispatch-audit/archive.json"
        correction = json.loads(audit.read_text())
        self.assertFalse(correction["runtimeDefectEstablished"])
        for name, sha in correction["files"].items():
            self.assertEqual(published_digest(ROOT, audit.parent / name), sha)


if __name__ == "__main__":
    unittest.main()
