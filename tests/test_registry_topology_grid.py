"""Static scope contracts; these tests do not substitute for native execution."""
import json
import unittest

from gambit_smp.framework import ROOT


class RegistryTopologyGridTests(unittest.TestCase):
    def test_optimized_bootstrap_changes_only_explicit_compiler_levels(self):
        base = ROOT / "evidence/research/vm-registry-reader-lease"
        original = json.loads((base / "resize-grace-bootstrap.recipe.json").read_text())
        candidate = json.loads((base / "resize-grace-optimized-bootstrap.recipe.json").read_text())
        self.assertEqual(original["inputs"], candidate["inputs"])
        self.assertEqual(original["budgetSeconds"], candidate["budgetSeconds"])
        self.assertEqual(len(original["steps"]), len(candidate["steps"]))
        for before, after in zip(original["steps"], candidate["steps"]):
            expected = json.loads(json.dumps(before))
            if before["id"] == "configure":
                expected["arguments"].update(cOptimization=1, rtsOptimization=1)
            self.assertEqual(expected, after)

    def test_rts_candidate_preserves_dynamic_compiler_cost_configuration(self):
        base = ROOT / "evidence/research/vm-registry-reader-lease"
        original = json.loads((base / "resize-grace-bootstrap.recipe.json").read_text())
        candidate = json.loads((base / "resize-grace-rts-bootstrap.recipe.json").read_text())
        self.assertEqual(original["inputs"], candidate["inputs"])
        self.assertEqual(original["budgetSeconds"], candidate["budgetSeconds"])
        self.assertEqual(len(original["steps"]), len(candidate["steps"]))
        for before, after in zip(original["steps"], candidate["steps"]):
            expected = json.loads(json.dumps(before))
            if before["id"] == "configure":
                expected["arguments"]["rtsOptimization"] = 1
            self.assertEqual(expected, after)

    def test_successor_preserves_source_producer_and_original_caps(self):
        base = ROOT / "evidence/research/vm-registry-reader-lease"
        original = json.loads((base / "resize-grace-native.recipe.json").read_text())
        current = json.loads((base / "host-topology-grid.recipe.json").read_text())
        self.assertEqual(original["budgetSeconds"], current["budgetSeconds"])
        self.assertEqual([step["id"] for step in original["steps"]],
                         [step["id"] for step in current["steps"]])
        for before, after in zip(original["steps"], current["steps"]):
            self.assertEqual(before["budgetSeconds"], after["budgetSeconds"])
            if before["capability"] not in ("gambit.completed-runtime", "gambit.executable-test"):
                self.assertEqual(before, after)
        producer = next(step for step in current["steps"] if step["id"] == "producer")
        self.assertIn(producer["arguments"]["producer"], current["inputs"])

    def test_topology_has_no_two_vm_array_or_word_sized_membership_limit(self):
        text = (ROOT / "models/gambit/native/registry_topology_grid.scm").read_text()
        self.assertIn('getenv("GAMBIT_SMP_AVAILABLE_CPUS")', text)
        self.assertIn("count <= maximum", text)
        self.assertIn("base + (i < remainder)", text)
        self.assertIn("static _Thread_local int fixture_cohort", text)
        self.assertNotIn("threads[2]", text)
        self.assertNotIn("1u <<", text)
        self.assertIn("fixture_cycles = cpu > 16 ? (int)cpu : 16", text)

    def test_original_gc_pin_join_and_drain_assertions_remain(self):
        base = ROOT / "models/gambit/native"
        original = (base / "registry_resize_grace.scm").read_text()
        current = (base / "registry_topology_grid.scm").read_text()
        for line in original.splitlines():
            if any(marker in line for marker in (
                    "(require", "(##gc)", "(##thread-pin!", "___cleanup_owned_vmstate")):
                self.assertIn(line, current)
