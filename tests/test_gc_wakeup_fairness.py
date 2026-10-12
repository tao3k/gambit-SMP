import copy
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.wakeup_fairness import audit


class WakeupFairnessModelTests(unittest.TestCase):
    def test_focus_imports_original_actions_and_labels_assumption(self):
        model = (ROOT / "models/gambit/gc_wakeup_fairness.qnt").read_text()
        self.assertIn('import gc_recursive_queue_wait.* from "./gc_recursive_queue_wait"', model)
        self.assertIn("action stepBounded = any { copyWord, helperSteps, spuriousWake }", model)
        self.assertIn("action stepUnbounded = any { copyWord, helperSteps, wakeUnbounded }", model)
        self.assertIn("weakFair(copyWord, Set(s))", model)
        self.assertIn("not a runtime repair", model)
        self.assertNotIn("spuriousUsed:", model)

    def ir(self):
        path = ROOT / "evidence/model-results/gc-wakeup-fairness-ir/protocol-ir.json"
        return json.loads(path.read_text())

    def test_real_ir_keeps_all_original_branches_except_explicit_wakeup_variant(self):
        result = audit(self.ir())
        self.assertEqual(result["importedOriginalBranches"], 21)
        self.assertEqual(len(result["variantActions"]), 22)
        self.assertFalse(result["sourceFairnessProved"])
        self.assertFalse(result["wakeBodyEquivalenceProved"])
        self.assertTrue(result["focusedSubrelationChecked"])
        self.assertEqual(len(result["focusedActions"]), 10)
        self.assertFalse(result["fullNextChecked"])
        self.assertFalse(result["positiveResultTransfers"])

    def test_focused_missing_duplicate_alias_and_recursive_branches_are_rejected(self):
        for fault in ("missing", "duplicate", "alias", "recursive", "extra"):
            ir = copy.deepcopy(self.ir())
            local = next(module for module in ir["modules"] if module["name"] == "gc_wakeup_fairness")
            helper = next(item for item in local["declarations"] if item.get("name") == "helperSteps")
            if fault == "missing":
                helper["expr"]["args"].pop()
            elif fault == "duplicate":
                helper["expr"]["args"].append(copy.deepcopy(helper["expr"]["args"][0]))
            elif fault == "alias":
                helper["expr"] = {"kind": "name", "name": "resume"}
            else:
                helper["expr"]["args"].append({"kind": "name", "name": "helperSteps" if fault == "recursive" else "finished"})
            with self.subTest(fault=fault), self.assertRaises(ValueError):
                audit(ir)

    def test_missing_duplicate_or_shadowed_original_action_is_rejected(self):
        for fault in ("missing", "duplicate", "shadow"):
            ir = copy.deepcopy(self.ir())
            local = next(module for module in ir["modules"] if module["name"] == "gc_wakeup_fairness")
            full = next(item for item in local["declarations"] if item.get("name") == "fullUnbounded")
            if fault == "missing":
                full["expr"]["args"].pop()
            elif fault == "duplicate":
                full["expr"]["args"].append(copy.deepcopy(full["expr"]["args"][0]))
            else:
                local["declarations"].append({"kind": "def", "name": "copyWord", "qualifier": "action"})
            with self.subTest(fault=fault), self.assertRaises(ValueError):
                audit(ir)
