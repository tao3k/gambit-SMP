import json
from pathlib import Path
import unittest

from gambit_smp import model_progress as progress


class ModelProgressTests(unittest.TestCase):
    def setUp(self):
        self.case = json.loads((progress.ROOT / "evidence/progress-obligations.json").read_text())["cases"][0]
        self.source = (progress.ROOT / "models/gambit/sync_resource_users.qnt").read_text()

    def test_overlay_preserves_every_original_state_transition_byte(self):
        for blocked in (True, False):
            projected = progress.generated(self.source, self.case, blocked)
            self.assertTrue(projected.startswith(self.source.rstrip()[:-1]))
            self.assertIn("enabled(obligationStep)", projected)
            self.assertIn("weakFair(obligationStep, Set(s))", projected)
            self.assertIn("eventually(obligationTerminal)", projected)
            self.assertIn("not(" + ("true" if blocked else "false") + " and", projected)

    def test_wrong_module_and_path_like_case_are_rejected(self):
        for case in ({**self.case, "id": "wrong"}, {**self.case, "id": "../escape"}):
            with self.assertRaises(ValueError):
                progress.generated(self.source, case, False)

    def test_existing_overlay_and_missing_state_identity_are_rejected(self):
        with self.assertRaises(ValueError):
            progress.generated(self.source + "// obligationTerminal\n", self.case, False)
        for variables in ([], ["s); malicious"], ["../s"]):
            with self.assertRaises(ValueError):
                progress.generated(self.source, {**self.case, "stateVariables": variables}, False)
