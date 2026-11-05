"""Bind diagnostic numeric observations without admitting a continuous campaign."""
import json
import hashlib
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.output_observations import recorded
from tests.support import published_digest


BASE = ROOT / "evidence/source-results/fixtures/sfun-owned-unwind"


class NumericPhaseEvidenceTests(unittest.TestCase):
    def receipt(self, name, continuous=False):
        folder = BASE / name
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        for path, expected in archive["files"].items():
            self.assertEqual(published_digest(ROOT, folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertEqual(receipt["continuousPhaseCampaignPassed"], continuous)
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        self.assertFalse(receipt["performanceAdmitted"])
        self.assertNotIn("/Users/", (folder / "receipt.json").read_text())
        return folder, receipt

    def test_historical_adapter_continuous_campaign_is_scoped_and_bound(self):
        folder, receipt = self.receipt("numeric-continuous-loader-contract", continuous=True)
        self.assertEqual(receipt["status"], "PASS")
        self.assertTrue(receipt["sourceStable"])
        self.assertTrue(receipt["diagnosticOnly"])
        self.assertLessEqual(receipt["seconds"], receipt["wholeProbeBudget"])
        self.assertEqual(receipt["wholeProbeBudget"], 90)
        self.assertEqual(receipt["adapterSha256"], digest(folder / "compiler_cost.py"))
        # Historical execution binds the archived adapter, not today's code.
        archive = json.loads((folder / "archive.json").read_text())
        self.assertEqual(receipt["adapterSha256"], archive["files"]["compiler_cost.py"])
        _, prior = self.receipt("numeric-phase-loader-denial")
        self.assertEqual([r["artifactSha256"] for r in receipt["stages"][:2]],
                         [r["artifactSha256"] for r in prior["stages"][:2]])
        self.assertEqual(len(receipt["stages"]), 3)
        for row in receipt["stages"]:
            self.assertEqual(row["exit"], 0)
            self.assertTrue(row["accepted"])
            self.assertFalse(row["timeout"])
            self.assertTrue(row["process"]["parentReaped"])
            self.assertTrue(row["process"]["processGroupQuiescent"])
        self.assertEqual(recorded(ROOT, folder / "compiled-execution.log")['sha256'],
                         hashlib.sha256(b"COMPILER-PHASE:module-initialized,assertions-passed\n").hexdigest())

    def test_current_predicate_validates_witness_without_readmitting_history(self):
        from gambit_smp.compiler_phase_primitives import EXECUTION_WITNESS, stage_accepted
        folder, receipt = self.receipt("numeric-continuous-loader-contract", continuous=True)
        output = EXECUTION_WITNESS + '\n'
        self.assertEqual(recorded(ROOT, folder / "compiled-execution.log")['sha256'],
                         hashlib.sha256(output.encode()).hexdigest())
        self.assertTrue(stage_accepted(0, False, output, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, False, "", None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, False, output + output, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(70, False, output, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, True, output, None, EXECUTION_WITNESS))
        self.assertFalse(receipt["runtimeAdmitted"])

    def test_original_denial_is_loading_not_compile_timeout(self):
        folder, receipt = self.receipt("numeric-phase-loader-denial")
        self.assertEqual(receipt["status"], "DENY")
        self.assertTrue(receipt["sourceStable"])
        self.assertEqual([r["exit"] for r in receipt["stages"]], [0, 0, 70])
        self.assertEqual([r["accepted"] for r in receipt["stages"]], [True, True, False])
        for row in receipt["stages"]:
            self.assertFalse(row["timeout"])
            self.assertTrue(row["process"]["processGroupQuiescent"])
        self.assertIn("___LNK_probe_2e_o1", recorded(ROOT, folder / "compiled-execution.log")['linkerSymbols'])

    def test_identified_loader_binds_exact_module_and_original_failure_flag(self):
        folder, receipt = self.receipt("numeric-sentinel-load")
        _, prior = self.receipt("numeric-phase-loader-denial")
        _, coverage = self.receipt("numeric-coverage-guard-denial")
        self.assertEqual(receipt["moduleSha256"], prior["stages"][1]["artifactSha256"])
        self.assertEqual(receipt["priorReceiptSha256"], prior["rawReceiptSha256"])
        self.assertEqual(receipt["coverageGuardDenialSha256"], coverage["rawReceiptSha256"])
        self.assertEqual(receipt["identitySha256"], digest(folder / "identity.json"))
        self.assertEqual(receipt["sourceLockSha256"], digest(ROOT / "evidence/fixtures/sfun-owned-unwind/source.lock.json"))
        loader = ROOT / "models/gambit/native/numeric_phase_load.scm"
        self.assertEqual(receipt["loaderSha256"], digest(loader))
        self.assertEqual((folder / loader.name).read_text(), loader.read_text())
        self.assertTrue(receipt["identityUnchanged"])
        self.assertTrue(receipt["controlsPassed"])
        observed = receipt["observation"]
        self.assertEqual(observed["exit"], 0)
        self.assertFalse(observed["timeout"])
        self.assertTrue(observed["group_quiescent"])
        self.assertEqual(observed["stderr"], "")
        self.assertEqual(observed["stdout"], "NUMERIC-PHASE:failed=#f,procedure-records=0\nNATIVE-OK:numeric_phase_load\n")

    def test_skipped_body_and_failed_assertions_cannot_report_success(self):
        folder, receipt = self.receipt("numeric-sentinel-load")
        original = (folder / "numeric_phase_load.scm").read_text()
        load = '(##load module-path (lambda (script path) #f) #t #t "probe" #f)'
        self.assertEqual(original.count(load), 1)
        self.assertTrue(receipt["negativeControlsPassed"])
        self.assertEqual({r["name"] for r in receipt["negativeControls"]}, {"skip-module", "false-success"})
        for row in receipt["negativeControls"]:
            path = folder / (row["name"] + ".scm")
            self.assertEqual(digest(path), row["sourceSha256"])
            if row["name"] == "false-success":
                self.assertEqual(path.read_text(), original.replace(load, load + "\n(set! ##failed-test? #t)"))
            else:
                self.assertNotIn(load, path.read_text())
                self.assertIn("numeric-module-not-executed", path.read_text())
            observed = row["observation"]
            self.assertEqual(observed["exit"], 2)
            self.assertFalse(observed["timeout"])
            self.assertTrue(observed["group_quiescent"])
            self.assertNotIn("NATIVE-OK", observed["stdout"])


if __name__ == "__main__":
    unittest.main()
