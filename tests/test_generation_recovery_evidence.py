"""Conditional recovery evidence must leave native recovery/quiescence open."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest


class GenerationRecoveryEvidenceTests(unittest.TestCase):
    def test_model_has_actual_cross_generation_counterexample(self):
        proof = json.loads((ROOT / 'evidence/model-results/processor-interrupt-collective-wait/generation-recovery-qualified-04/receipt.json').read_text())
        self.assertTrue(proof['accepted'])
        self.assertTrue(proof['contextStable'])
        for name, sha in proof['inputs'].items():
            if name.startswith(('models/', 'patches/', 'evidence/research/')):
                self.assertEqual(digest(ROOT / name), sha, name)
        negative = next(row for row in proof['results'] if row['variant'] == 'old')
        self.assertEqual(negative['invariant'], 'noCross')
        self.assertEqual(negative['states']['distinct'], 4)
        self.assertNotEqual(negative['exit'], 0)
        self.assertEqual(proof['native']['status'], 'not-run')

    def test_scheme_keeps_native_gates_open_and_revokes_stale_support(self):
        doc, facts, catalog, _ = load(ROOT, 'evidence/scenarios/runtime-lifecycle/generation-recovery.view.json')
        queries = dict(doc['queries'], applicable='applicable')
        with engine_api() as (engine, _):
            initial, _ = evaluate(engine, facts, catalog, queries)
            for claim in ('runtime-successful-error-recovery', 'generation-recovery-native-handler-quiescence'):
                self.assertIn((claim,), initial['unclosed'])
            for witness, claim, contract, _ in facts['receipt']:
                self.assertIn((claim, witness), initial['applicable'])
                for key, _ in facts['current_binding']:
                    changed = dict(facts, current_binding=[(k, 'changed' if k == key else value) for k, value in facts['current_binding']])
                    after, _ = evaluate(engine, changed, catalog, queries)
                    self.assertNotIn((claim, witness), after['applicable'], key)


if __name__ == '__main__':
    unittest.main()
