"""Bind real FFI regression scope; these checks do not admit native correctness."""
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import recipes


class CallbackRetirementNativeTests(unittest.TestCase):
    def test_official_roundtrip_keeps_original_budgets_and_model_controls(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/vector-arity-callback-retirement-roundtrip.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertEqual(300, recipe["budgetSeconds"])
        native = next(step for step in recipe["steps"] if step["capability"] == "gambit.executable-test")
        self.assertEqual(120, native["budgetSeconds"])
        self.assertEqual(30, native["arguments"]["executionBudgetSeconds"])
        self.assertEqual("host-managed", native["arguments"]["processorTopology"])
        self.assertIn("rc-safe", native["dependsOn"])
        self.assertIn("rc-retention-control", native["dependsOn"])
        self.assertIn("rc-transfer-control", native["dependsOn"])
        controls = [step["arguments"]["initializer"] for step in recipe["steps"]
                    if step["capability"] == "quint.verify" and step["arguments"]["negative"]]
        self.assertEqual(["initHeapOnly", "initWaitInsideCollective"], controls)
        self.assertFalse(any(step["capability"] == "gambit.bootstrap" for step in recipe["steps"]))

    def test_roundtrip_uses_live_c_frame_without_injection_or_rejection_oracle(self):
        program = (ROOT / "models/gambit/native/callback_retirement_roundtrip.scm").read_text()
        self.assertIn('(c-define (retirement-roundtrip target)', program)
        self.assertIn('(c-lambda (int) int "retirement_roundtrip")', program)
        self.assertIn('(##current-vm-processor-count)', program)
        self.assertIn('(##thread-pin! worker (##processor origin))', program)
        self.assertIn('(require (= (thread-join! worker) 42)', program)
        self.assertIn('(require (= (vector-ref root 31) 1042)', program)
        self.assertIn('(equal? (##current-vm-resize ##startup-processor! target) 0)', program)
        self.assertLess(program.index('(##gc)'), program.index('CALLBACK-ROUNDTRIP:BODY-RETURNING'))
        for forbidden in ('RTLD_NEXT', 'dlsym', 'pthread_join', '___cleanup_owned_vmstate',
                          'hook-set!', 'live C frame retirement was admitted'):
            self.assertNotIn(forbidden, program)

    def test_policy_probe_is_distinct_from_roundtrip(self):
        probe = ROOT / "evidence/research/vm-registry-reader-lease/vector-arity-callback-retirement-admission.recipe.json"
        recipes.load(ROOT, probe)
        program = (ROOT / "models/gambit/native/callback_retirement_admission.scm").read_text()
        self.assertIn('live C frame retirement was admitted', program)
        self.assertIn('(not (= result 0))', program)
