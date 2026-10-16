"""Read actual portable model evidence without upgrading it to native green."""
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.protocol_evidence import bundle_facts
from gambit_smp.framework import digest

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = "evidence/research/continuation-retained-seed-bootstrap/stage-reuse-contract.json"
RECEIPT = "evidence/model-results/research/bootstrap-stage-reuse/checked/receipt.json"


class BootstrapStageReuseModelTests(unittest.TestCase):
    def test_checked_bundle_has_controls_and_retains_native_obligations(self):
        facts, _ = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        self.assertEqual(len(facts["protocol_control"]), 3)
        self.assertEqual(len(facts["protocol_obligation"]), 5)
        receipt = json.loads((ROOT / RECEIPT).read_text())
        positives = [row for row in receipt["results"] if row["variant"] == "protocol"]
        self.assertEqual({row["invariant"] for row in positives}, {"safe", "noStall"})
        self.assertTrue(all(row["accepted"] and row["states"]["queued"] == 0 for row in positives))
        self.assertTrue(all(row["temporal"] == "progress" for row in positives))
        self.assertFalse(receipt["runtimeAdmitted"])

    def test_failed_launch_drift_attempt_remains_nonadmitted(self):
        path = ROOT / "evidence/model-results/research/bootstrap-stage-reuse/launch-drift-attempt/archive.json"
        archive = json.loads(path.read_text())
        self.assertTrue(archive["archiveOnly"])
        self.assertFalse(archive["runtimeAdmitted"])

    def test_charged_consumption_composes_actual_budget_model(self):
        manifest_name = "evidence/research/continuation-retained-seed-bootstrap/charged-consumption-contract.json"
        receipt_name = "evidence/model-results/research/bootstrap-stage-reuse/charged-consumption/receipt.json"
        manifest = json.loads((ROOT / manifest_name).read_text())
        receipt = json.loads((ROOT / receipt_name).read_text())
        frozen = ROOT / "evidence/source-results/fixture-history/step-checkpoint-before-history-ancestry.py"
        self.assertEqual(digest(frozen), manifest["contextInputs"]["src/gambit_smp/step_checkpoint.py"])
        # Replay the original context as data; never execute archived Python.
        with tempfile.TemporaryDirectory() as directory:
            historical_root = Path(directory).resolve()
            for name in manifest["contextInputs"]:
                source = frozen if name == "src/gambit_smp/step_checkpoint.py" else ROOT / name
                self.assertEqual(digest(source), manifest["contextInputs"][name])
                target = historical_root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target)
            for name, sha in receipt["modelSources"].items():
                target = historical_root / "models/gambit" / Path(name).name
                target.parent.mkdir(parents=True, exist_ok=True)
                source = (ROOT / receipt_name).parent / name
                self.assertEqual(digest(source), sha)
                shutil.copyfile(source, target)
            target = historical_root / receipt_name
            shutil.copytree((ROOT / receipt_name).parent, target.parent)
            target = historical_root / manifest_name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / manifest_name, target)
            facts, _ = bundle_facts(historical_root, manifest_name, receipt_name)
        self.assertEqual(facts["protocol_composes"], [("checkpoint_budget_consumption", "checkpoint_budget_ledger")])
        self.assertEqual(len(facts["protocol_checked"]), 1)
        self.assertEqual(len(facts["protocol_control"]), 3)
        self.assertEqual(len(facts["protocol_obligation"]), 5)
        self.assertFalse(receipt["runtimeAdmitted"])
        current, _ = bundle_facts(ROOT, manifest_name, receipt_name)
        self.assertNotEqual(digest(ROOT / "src/gambit_smp/step_checkpoint.py"), digest(frozen))
        self.assertEqual(current["protocol_checked"], [])
        self.assertEqual(current["protocol_control"], facts["protocol_control"])
        self.assertEqual(current["protocol_obligation"], facts["protocol_obligation"])
