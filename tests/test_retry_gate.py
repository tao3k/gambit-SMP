import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import retry_gate
from gambit_smp.framework import digest


class RetryGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.empty = {name: [] for name in retry_gate.audit.index.export()["facts"]}

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        evidence = self.root / "evidence"
        evidence.mkdir()
        for name in ("rules.dl", "research-rules.dl"):
            shutil.copyfile(retry_gate.audit.ROOT / "evidence" / name, evidence / name)
        self.runtime = self.root / "runtime"
        for name in ("gsi/gsi", "gsc/gsc", "bin/gambuild-C",
                     "tests/unit-tests/case.scm"):
            target = self.runtime / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(name)
        self.candidate = {"binarySha256": digest(self.runtime / "gsi/gsi"),
                          "gscSha256": digest(self.runtime / "gsc/gsc")}
        self.receipt = self.root / "candidate.json"
        self.receipt.write_text(json.dumps(self.candidate))
        old = {"status": "DENY", "gsiSha256": self.candidate["binarySha256"],
               "gscSha256": self.candidate["gscSha256"],
               "atomicBatchBudgetPerMode": 30,
               "sourceFiles": {"unit-tests/case.scm":
                               digest(self.runtime / "tests/unit-tests/case.scm")},
               "buildDriver": {"relativePath": "bin/gambuild-C",
                               "sha256": digest(self.runtime / "bin/gambuild-C")},
               "results": [{"mode": "gsc", "accepted": False}]}
        (self.root / "old.json").write_text(json.dumps(old))
        (evidence / "native-failures.json").write_text(json.dumps({"failures": [
            {"id": "failure", "file": "case.scm", "receipt": "old.json"}]}))

    def check(self, files=None, modes=None, budget=30, hypotheses=None):
        with patch.object(retry_gate.audit.index, "export",
                          return_value={"facts": self.empty, "inputs": {}}):
            return retry_gate.preflight(self.root, self.runtime, self.receipt,
                files or [Path("case.scm")], modes or ["gsc"], budget, hypotheses)

    def test_unchanged_failure_is_denied_without_launching_a_candidate(self):
        result = self.check()
        self.assertEqual("DENY", result["decision"])
        self.assertIn(("failure:gsc", "unchanged-tested-inputs"), result["retryDenials"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual([], result["routes"][0]["changedTestedInputs"])

    def test_changed_artifact_with_hypothesis_is_review_not_permission_to_run(self):
        (self.runtime / "gsc/gsc").write_text("changed compiler")
        self.candidate["gscSha256"] = digest(self.runtime / "gsc/gsc")
        self.receipt.write_text(json.dumps(self.candidate))
        result = self.check(hypotheses={"failure": {
            "cause": "model-bound compiler delta", "expectedObservation": "assertion passes"}})
        self.assertEqual("REVIEW_REQUIRED", result["decision"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(["gscSha256"], result["routes"][0]["changedTestedInputs"])

    def test_budget_expansion_and_unbound_artifacts_fail_closed(self):
        (self.runtime / "gsc/gsc").write_text("unbound")
        result = self.check(budget=31)
        reasons = {row[1] for row in result["retryDenials"]}
        self.assertEqual("DENY", result["decision"])
        self.assertIn("budget-expanded", reasons)
        self.assertIn("unreviewed-artifact-identity", reasons)

    def test_unfailed_file_or_mode_does_not_inherit_a_compiler_denial(self):
        self.assertEqual("NOT_REQUIRED", self.check(files=[Path("other.scm")])["decision"])
        self.assertEqual("NOT_REQUIRED", self.check(modes=["gsi"])["decision"])

    def test_modes_remain_separate_datalog_routes(self):
        old_path = self.root / "old.json"
        old = json.loads(old_path.read_text())
        old["results"].append({"mode": "gsi", "accepted": False})
        old_path.write_text(json.dumps(old))
        result = self.check(modes=["gsi", "gsc"])
        self.assertEqual({"failure:gsi", "failure:gsc"}, {row["route"] for row in result["routes"]})

    def test_tested_patched_snapshot_not_original_is_compared(self):
        snapshot = self.root / "snapshot"
        snapshot.mkdir()
        (snapshot / "case.scm").write_text("previously tested patch")
        old_path = self.root / "old.json"
        old = json.loads(old_path.read_text())
        old["fixturePatches"] = [{"derivedFiles": {
            "unit-tests/case.scm": digest(snapshot / "case.scm")}}]
        old_path.write_text(json.dumps(old))
        with patch.object(retry_gate.audit.index, "export",
                          return_value={"facts": self.empty, "inputs": {}}):
            result = retry_gate.preflight(self.root, self.runtime, self.receipt,
                [Path("case.scm")], ["gsc"], 30, tested_unit=snapshot)
        self.assertEqual("DENY", result["decision"])
        self.assertIn(("failure:gsc", "unchanged-tested-inputs"), result["retryDenials"])
        self.assertEqual([], result["routes"][0]["changedTestedInputs"])

    def test_tested_snapshot_cannot_escape_its_root_through_a_symlink(self):
        snapshot = self.root / "snapshot"
        snapshot.mkdir()
        (snapshot / "case.scm").symlink_to(self.runtime / "tests/unit-tests/case.scm")
        with self.assertRaises(ValueError):
            retry_gate.preflight(self.root, self.runtime, self.receipt,
                [Path("case.scm")], ["gsc"], 30, tested_unit=snapshot)
