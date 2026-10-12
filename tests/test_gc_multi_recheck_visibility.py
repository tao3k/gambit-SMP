"""Population extension evidence; not whole GC/native admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts


MANIFEST = "evidence/fixtures/sfun-owned-unwind/multi-recheck-visibility-contract.json"
FOLDER = "evidence/model-results/fixtures/sfun-owned-unwind/multi-recheck-visibility"


class MultiRecheckVisibilityTests(unittest.TestCase):
    def test_qualified_population_extension_is_not_gc_closure(self):
        facts, _ = bundle_facts(ROOT, MANIFEST, FOLDER + "/receipt.json")
        self.assertEqual(len(facts["protocol_control"]), 2)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        self.assertIn(("gc_multi_recheck_visibility", "gc_recheck_visibility_completion"),
                      facts["protocol_composes"])
        receipt = json.loads((ROOT / FOLDER / "receipt.json").read_text())
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        positive = next(row for row in receipt["results"] if row["variant"] == "protocol")
        self.assertEqual(positive["states"], {"generated": 735, "distinct": 435, "queued": 0})
        self.assertEqual(positive["temporal"], "completion")
        manifest = json.loads((ROOT / MANIFEST).read_text())
        imported = "models/gambit/gc_recheck_visibility.qnt"
        self.assertEqual(manifest["contextInputs"][imported], digest(ROOT / imported))
        self.assertIn("producer_retirement_and_zero_count_termination",
                      manifest["cases"][0]["openObligations"])

    def test_both_controls_have_finished_publishers_and_a_registered_sleeper(self):
        for invariant, policy in (("earlyRegistrationSafe", "early-unlock"),
                                  ("handoffVisibilitySafe", "ignore-handoff")):
            path = ROOT / FOLDER / ("gc_multi_recheck_visibility-old-" + invariant + ".trace.json")
            trace = json.loads(path.read_text())
            final = trace["states"][-1]["s"]
            self.assertEqual(final["policy"], policy)
            self.assertEqual(dict(final["producer"]["$integerMap"]), {2: "active", 3: "active"})
            self.assertIn("waiting", dict(final["waiter"]["$integerMap"]).values())
            self.assertEqual(final["published"]["$integerSet"], [2, 3])
            self.assertEqual(final["handedOff"]["$integerSet"], [2, 3])
            self.assertEqual(final["count"], 3)
            if policy == "ignore-handoff":
                waiting = next(w for w, phase in final["waiter"]["$integerMap"] if phase == "waiting")
                acquired = dict(final["acquired"]["$integerMap"])[waiting]
                self.assertEqual(acquired["$integerSet"], [2, 3])


if __name__ == "__main__":
    unittest.main()
