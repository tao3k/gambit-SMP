import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import BUNDLES, bundle_facts, checked_rows
from gambit_smp.verify_protocols import load_manifest


class VmRetirementJoinCompositionTests(unittest.TestCase):
    base = "evidence/fixtures/interrupt-prefix-owned-lifecycle"
    receipt = "evidence/model-results/fixtures/interrupt-prefix-owned-lifecycle/retirement-join-design-contract/receipt.json"

    def test_complete_composition_is_bound_and_preserves_conditional_progress(self):
        manifest_path = self.base + "/retirement-join-design-contract.json"
        manifest = load_manifest(ROOT / manifest_path)
        self.assertIn((manifest_path, self.receipt), BUNDLES)
        rows = checked_rows(ROOT, manifest, ROOT / self.receipt)[0][1]
        self.assertEqual(4, len(rows))
        self.assertEqual(3, sum(r["variant"] == "old" and r["exit"] == 1 for r in rows))
        positive = next(r for r in rows if r["variant"] == "protocol")
        self.assertEqual(0, positive["exit"])
        self.assertEqual("progress", positive["temporal"])
        self.assertEqual({"generated": 262, "distinct": 138, "queued": 0}, positive["states"])
        self.assertIn("successful_join_recovery_or_explicit_noncompletion", manifest["cases"][0]["openObligations"])
        model = (ROOT / "models/gambit/vm_retirement_join_composition.qnt").read_text()
        for call in ("lock", "publish", "unlock", "signal", "childExit", "joinAndReuse", "destroyVmResources"):
            self.assertIn("S::" + call, model)
        self.assertIn('joinOld: "waiting"', model)
        self.assertIn("vm.flow == 6 and S::terminal", model)

    def test_native_negative_is_observed_uncorrected_caller_not_green_repair(self):
        path = "evidence/source-results/fixtures/interrupt-prefix-owned-lifecycle/retirement-join-observation.json"
        saved = json.loads((ROOT / path).read_text())
        for name, expected in saved["inputs"].items():
            self.assertEqual(expected, digest(ROOT / name), name)
        self.assertNotRegex(json.dumps(saved), r"/(?:Users|home)/")
        for flag in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertFalse(saved[flag])
        run = saved["runs"]["caller"]
        self.assertEqual("PASS", run["outcome"])
        tests = [s for s in run["steps"] if s["id"].endswith("-test")]
        self.assertEqual(1, len(tests))
        self.assertEqual([0, 1], [c["exit"] for c in tests[0]["commands"]])
        self.assertTrue(all(not c["timeout"] for c in tests[0]["commands"]))

    def test_datalog_fact_recovery_binds_current_composition_inputs(self):
        manifest = self.base + "/retirement-join-design-contract.json"
        facts, inputs = bundle_facts(ROOT, manifest, self.receipt)
        self.assertTrue(facts)
        self.assertEqual(digest(ROOT / manifest), inputs[manifest])
        self.assertEqual(digest(ROOT / self.receipt), inputs[self.receipt])
        source = "models/gambit/vm_retirement_join_composition.qnt"
        self.assertEqual(digest(ROOT / source), inputs[source])
