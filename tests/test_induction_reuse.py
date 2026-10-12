import copy
import json
from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
import unittest

from gambit_smp import induction_reuse as reuse
from gambit_smp.framework import ROOT


BASE = "evidence/model-results/gc-induction-cartesian-contract-ir/receipt.json"
DELTA = "evidence/model-results/gc-source-wait-new-action-induction/receipt.json"
MANIFEST = "evidence/gc-source-wait-induction.json"


class InductionReuseTests(unittest.TestCase):
    def test_actual_archives_compose_twenty_reused_and_two_new_branches(self):
        result = reuse.compose(ROOT, BASE, DELTA, MANIFEST)
        self.assertTrue(result["symbolicObligationsComplete"])
        self.assertEqual(22, len(result["coverage"]))
        self.assertEqual(20, sum(row["reused"] for row in result["coverage"]))
        self.assertEqual({"orderedRecheck", "unboundedWake"},
                         {row["action"] for row in result["coverage"] if not row["reused"]})
        self.assertTrue(result["generatorContract"]["contractVerified"])
        for key in ("accepted", "runtimeAdmitted", "releaseAdmitted", "temporalProved",
                    "inductiveSafetyAdmitted", "solverCoverageProved"):
            self.assertFalse(result[key])

    def test_module_identity_ignores_only_parser_ids(self):
        before = {"modules": [{"name": "shared", "id": 1, "declarations": [
            {"name": "safe", "expr": {"kind": "bool", "id": 2, "value": True}}]}]}
        after = copy.deepcopy(before)
        after["modules"][0]["id"] = 123
        reuse.modules_equal(before, after, ["shared"])
        after["modules"][0]["declarations"][0]["expr"]["value"] = False
        with self.assertRaisesRegex(ValueError, "dependency changed"):
            reuse.modules_equal(before, after, ["shared"])

    def test_changed_current_source_or_archived_log_cannot_be_reused(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            config = json.loads((ROOT / MANIFEST).read_text())
            for receipt in (BASE, DELTA):
                path = Path(receipt).parent
                shutil.copytree(ROOT / path, root / path)
            paths = [MANIFEST, config["model"], config["protocol"], *config["dependencies"]]
            paths += ["src/gambit_smp/" + name + ".py" for name in
                      ("induction_reuse", "induction_matrix", "generator_contract", "framework", "protocol_evidence", "reasoning_history")]
            for name in paths:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, path)
            reuse.compose(root, BASE, DELTA, MANIFEST)
            model = root / config["protocol"]
            original = model.read_bytes()
            model.write_bytes(original + b"// drift\n")
            with self.assertRaisesRegex(ValueError, "dependency differs"):
                reuse.compose(root, BASE, DELTA, MANIFEST)
            model.write_bytes(original)
            log = root / Path(DELTA).parent / "preservation-orderedRecheck.log"
            log.write_text("invented pass")
            with self.assertRaisesRegex(ValueError, "artifact drift"):
                reuse.compose(root, BASE, DELTA, MANIFEST)
