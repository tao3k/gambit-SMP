from pathlib import Path
import re
import unittest

from gambit_smp.framework import ROOT


class GCInductionTests(unittest.TestCase):
    def test_proof_layer_imports_real_step_without_filtering_successors(self):
        model = (ROOT / "models/gambit/gc_recursive_queue_induction.qnt").read_text()
        self.assertIn('import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"', model)
        self.assertNotRegex(model, r"action\s+step\s*=")
        self.assertNotIn(".then(", model)
        self.assertIn("safeOf(candidate)", model)
        self.assertIn("val candidateInvariant = shape and safeOf(s) and discoveryShapeOf(s) and lockShapeOf(s) and phaseShapeOf(s)", model)
        self.assertIn("st.work.get(edge.get(o)) != -1", model)

    def test_protocol_actions_unchanged_by_pure_predicate_extraction(self):
        current = ROOT / "models/gambit/gc_recursive_queue_wait.qnt"
        prior = ROOT / "evidence/model-results/gc-recursive-queue-wait-sequential-probes-deny/gc_recursive_queue_wait.qnt"
        def actions(path):
            text = path.read_text()
            declarations = list(re.finditer(r"^  (?:action|(?:pure )?val|(?:pure )?def) (\w+)",
                                             text, re.MULTILINE))
            return {match.group(1): text[match.start():declarations[i + 1].start()
                    if i + 1 < len(declarations) else len(text)].strip()
                    for i, match in enumerate(declarations) if text[match.start():].startswith("  action")}
        self.assertEqual(actions(prior), actions(current))


if __name__ == "__main__":
    unittest.main()
