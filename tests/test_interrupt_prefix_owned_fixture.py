import json
import unittest

from gambit_smp.framework import ROOT, digest


class InterruptPrefixOwnedFixtureTests(unittest.TestCase):
    fixture = "interrupt-prefix-owned-lifecycle"

    def test_source_delta_preserves_parent_and_locks_abi(self):
        parent = json.loads((ROOT / "evidence/fixtures/sync-slot-retained-resources/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({"lib/setup.c", "include/gambit.h.in"},
                         {p for p in lock["files"] if lock["files"][p] != parent["files"][p]})
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        patch = (ROOT / lock["patch"]).read_text()
        self.assertIn("+    ___BOOL procedural_interrupts_ready;", patch)
        self.assertTrue("+___HIDDEN void cleanup_interrupt_resources_pstate" in patch)
        self.assertFalse(lock["runtimeAdmitted"])

    def test_receipts_bind_current_inputs_and_preserve_component_boundary(self):
        summary = json.loads((ROOT / f"evidence/source-results/fixtures/{self.fixture}/observation.json").read_text())
        for path, expected in summary["inputs"].items():
            self.assertEqual(expected, digest(ROOT / path), path)
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertFalse(summary[key])
        for run in summary["runs"].values():
            self.assertEqual("PASS", run["outcome"])
            self.assertLess(run["wholeSeconds"], run["budgetSeconds"])
            self.assertTrue(all(step["outcome"] == "PASS" for step in run["steps"]))
        cases = [s for s in summary["runs"]["caller"]["steps"] if s["id"].endswith("-test")]
        self.assertEqual(3, len(cases))
        for step in cases:
            self.assertEqual([1 if step["id"].startswith("negative-") else 0],
                             [c["exit"] for c in step["commands"]])
            self.assertTrue(all(not c["timeout"] for c in step["commands"]))

    def test_constructor_control_is_locked_parent_not_altered_assertion(self):
        recipe = json.loads((ROOT / f"evidence/research/{self.fixture}/caller.recipe.json").read_text())
        control = next(s for s in recipe["steps"] if s["id"] == "control")
        self.assertEqual("gambit.materialize", control["capability"])
        self.assertEqual("evidence/fixtures/sync-slot-retained-resources/source.lock.json",
                         control["arguments"]["sourceLock"])
        cases = next(s for s in recipe["steps"] if s["id"] == "negative-threaded-test")["arguments"]["cases"]
        self.assertEqual(1, cases[0]["expectedExit"])
        self.assertEqual('{"checks":10,"invalid":2}\n', cases[0]["stdout"])
