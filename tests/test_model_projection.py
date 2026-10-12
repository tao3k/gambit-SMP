import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.model_projection import bound_path, project_body, render


class ModelProjectionTests(unittest.TestCase):
    contract = "evidence/fixtures/interrupt-prefix-owned-lifecycle/resize-result-membership-projection.json"

    def test_real_quint_resolved_projection_is_reproducible(self):
        saved = json.loads((ROOT / self.contract).read_text())
        generated = render(ROOT, saved)
        self.assertEqual((ROOT / saved["target"]).read_text(), generated)
        self.assertIn("type Retire_State", generated)
        self.assertIn("action retire_joinOld", generated)
        self.assertIn("joinOld: str", generated)
        self.assertNotIn("retire_joinOld: str", generated)
        self.assertIn("S::initial(0)", generated)

    def test_source_hash_drift_is_rejected_before_projection(self):
        name = "models/gambit/vm_retirement_join_composition.qnt"
        with self.assertRaisesRegex(ValueError, "input drift"):
            bound_path(ROOT, name, "0" * 64)
        self.assertEqual(ROOT / name, bound_path(ROOT, name, digest(ROOT / name)))

    def test_cache_absolute_and_traversing_origins_are_not_authority(self):
        for name in (".data/source.qnt", "../source.qnt", str(ROOT / "source.qnt")):
            with self.assertRaisesRegex(ValueError, "durable relative"):
                bound_path(ROOT, name, "0" * 64)

    def test_invalid_ir_and_namespace_are_not_silently_renamed(self):
        with self.assertRaisesRegex(ValueError, "invalid parsed"):
            project_body("", ROOT / "model.qnt", "model", "retire_",
                         {"errors": ["unresolved"]}, {})
        with self.assertRaisesRegex(ValueError, "invalid parsed"):
            project_body("", ROOT / "model.qnt", "model", "../escape",
                         {"errors": []}, {})
