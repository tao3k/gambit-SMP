import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import protocol_evidence
from gambit_smp.verify_protocols import load_manifest


class PublicationPartitionsTests(unittest.TestCase):
    def test_complete_policy_campaign_is_bound_without_native_admission(self):
        base = "evidence/fixtures/vm-constructor-owned-rollback/"
        manifest = load_manifest(ROOT / (base + "publication-rollback-contract.json"))
        receipt = ROOT / "evidence/model-results/fixtures/vm-constructor-owned-rollback/publication-rollback-dedicated-init-dependency/receipt.json"
        cases = protocol_evidence.checked_rows(ROOT, manifest, receipt)
        rows = [row for _, case_rows in cases for row in case_rows]
        self.assertEqual(7, len(rows))
        controls = [row for row in rows if row["variant"] == "old"]
        self.assertEqual(3, len(controls))
        self.assertTrue(all(row["exit"] == 1 and not row["timeout"] for row in controls))
        complete = [row for row in rows if row["variant"] == "protocol"]
        self.assertEqual(4, len(complete))
        self.assertEqual(2214156, sum(row["states"]["distinct"] for row in complete))
        self.assertTrue(all(row["exit"] == 0 and not row["timeout"] and
                            row["states"]["queued"] == 0 and
                            row["temporal"] == "constructorProgress" for row in complete))
        repaired = next(row for row in complete if row["case"] == "vm_constructor_repaired")
        self.assertEqual("constructorSafe", repaired["invariant"])
        self.assertEqual(564510, repaired["states"]["distinct"])
        saved = json.loads(receipt.read_text())
        self.assertFalse(saved["runtimeAdmitted"])
        self.assertFalse(saved["releaseAdmitted"])

    def test_all_policy_instances_are_exact_template_specializations(self):
        template = (ROOT / "models/gambit/vm_constructor_publication_rollback.qnt").read_text()
        cases = {
            "vm_constructor_repaired": 0,
            "vm_constructor_early_count": 1,
            "vm_constructor_early_return": 2,
            "vm_constructor_blanket_rollback": 3,
        }
        self.assertEqual({0, 1, 2, 3}, set(cases.values()))
        for name, policy in cases.items():
            expected = template.replace("module vm_constructor_publication_rollback {",
                                        "module " + name + " {", 1).replace(
                "  const policyDomain: Set[int]", "  pure val policyDomain = Set(" + str(policy) + ")", 1)
            self.assertEqual(expected, (ROOT / ("models/gambit/" + name + ".qnt")).read_text())
        manifest = json.loads((ROOT /
            "evidence/fixtures/vm-constructor-owned-rollback/publication-rollback-contract.json").read_text())
        self.assertEqual(set(cases), {case["id"] for case in manifest["cases"]})
        for case in manifest["cases"]:
            self.assertEqual("constructorProgress", case["temporal"])
            self.assertEqual("constructorStep", case["step"])
            self.assertEqual({"initConstructor"}, set(case["protocolInitializers"].values()))
