"""Source-unit exception coverage and non-admitted diagnostic cost."""
import csv
import json
import statistics
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts


BASE = "evidence/source-results/fixtures/sfun-owned-unwind"


class SfunExceptionCostTests(unittest.TestCase):
    def receipt(self, name):
        folder = ROOT / BASE / name
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        self.assertFalse(archive["runtimeAdmitted"])
        self.assertFalse(archive["performanceAdmitted"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        saved = json.loads((folder / "receipt.json").read_text())
        self.assertFalse(saved["accepted"])
        self.assertFalse(saved["runtimeAdmitted"])
        return saved

    def test_both_exception_macros_all_families_and_allocation_failures(self):
        saved = self.receipt("exception-config-source-unit")
        self.assertEqual(saved["sourceSha256"], digest(ROOT / "models/gambit/native/sfun_catcher_unit.c"))
        self.assertEqual({r["configuration"] for r in saved["results"]},
                         {"setjmp-c", "exceptions-cpp"})
        expected = []
        for kind in range(3):
            for mode in range(4):
                made = 0 if mode == 1 else 1
                calls = 0 if mode == 1 else 2 if mode == 3 else 1
                expected.append(f"SFUN-CATCHER:kind={kind},mode={mode},made={made},"
                                f"killed={made},calls={calls},caught={int(mode != 0)}")
        for row in saved["results"]:
            self.assertEqual(row["build"]["exit"], 0)
            self.assertEqual(row["build"]["stderr"], "")
            obs = row["observation"]
            self.assertEqual(obs["exit"], 0)
            self.assertFalse(obs["timeout"])
            self.assertTrue(obs["group_quiescent"])
            self.assertEqual(obs["stdout"].splitlines(), expected)

    def test_matched_cost_keeps_all_work_and_an_inconclusive_decision(self):
        for name, iterations in (("short-matched-cost", 100000),
                                 ("long-matched-cost", 3200000)):
            saved = self.receipt(name)
            self.assertEqual(saved["performanceDecision"], "INCONCLUSIVE")
            self.assertFalse(saved["performanceAdmitted"])
            self.assertEqual(len(saved["runs"]), 24)
            self.assertEqual(saved["order"], ["parent", "candidate", "candidate", "parent"] * 2)
            timings = []
            for row in saved["runs"]:
                obs = row["observation"]
                self.assertEqual(obs["exit"], 0)
                self.assertFalse(obs["timeout"])
                self.assertTrue(obs["group_quiescent"])
                self.assertEqual(obs["stderr"], "")
                fields = dict(cell.split("=", 1) for cell in next(csv.reader(
                    [obs["stdout"].strip().removeprefix("SFUN-COST:")])))
                for key in ("iterations", "completed", "made", "killed"):
                    self.assertEqual(int(fields[key]), iterations)
                self.assertEqual(int(fields["kind"]), row["kind"])
                timings.append({"wave": row["wave"], "policy": row["policy"],
                                "kind": row["kind"], "seconds": float(fields["seconds"])})
            self.assertEqual(timings, saved["validatedTimings"])
            for comparison in saved["abbaComparisons"]:
                values = {policy: [r["seconds"] for r in timings if
                    r["wave"] // 4 == comparison["block"] and
                    r["kind"] == comparison["kind"] and r["policy"] == policy]
                    for policy in ("parent", "candidate")}
                self.assertEqual(comparison["candidateOverParent"],
                                 statistics.mean(values["candidate"]) / statistics.mean(values["parent"]))
            if name == "long-matched-cost":
                self.assertTrue(saved["binaryIdentityUnchanged"])
                self.assertTrue(any(r["candidateOverParent"] > 1.10 for r in saved["abbaComparisons"]))
                self.assertTrue(any(r["candidateOverParent"] < 0.90 for r in saved["abbaComparisons"]))

    def test_error_family_model_import_is_bound_and_complete(self):
        manifest = "evidence/fixtures/sfun-owned-unwind/exception-family-contract.json"
        receipt = "evidence/model-results/fixtures/sfun-owned-unwind/error-family-composition/receipt.json"
        facts, _ = bundle_facts(ROOT, manifest, receipt)
        self.assertEqual(len(facts["protocol_control"]), 5)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        contract = json.loads((ROOT / manifest).read_text())
        self.assertEqual(contract["cases"][0]["composes"], ["sfun_catcher_cleanup"])
        self.assertEqual(contract["contextInputs"]["models/gambit/sfun_catcher_cleanup.qnt"],
                         digest(ROOT / "models/gambit/sfun_catcher_cleanup.qnt"))
        saved = json.loads((ROOT / receipt).read_text())
        row = next(r for r in saved["results"] if r["variant"] == "protocol")
        self.assertEqual(row["temporal"], "completion")
        self.assertEqual(row["states"]["queued"], 0)
        self.assertFalse(saved["runtimeAdmitted"])
