"""Auditor checks Grok model receipts and real Scheme admission boundaries."""
import json
import unittest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest

VIEW = 'evidence/scenarios/runtime-lifecycle/structure-lifetime.view.json'
CLAIM = 'structure-lifetime-bounded-controls'
WITNESS = CLAIM + '-witness'
NATIVE = ('structure-lifetime-native-cause', 'structure-lifetime-native-fix')

class StructureLifetimeEvidenceTests(unittest.TestCase):
    def test_current_receipt_has_independent_controls_without_native_credit(self):
        proof = json.loads((ROOT/'evidence/model-results/processor-interrupt-collective-wait/structure-independent-audit-01/receipt.json').read_text())
        self.assertEqual(proof['status'], 'PASS')
        self.assertTrue(proof['testsPassed'])
        self.assertEqual(proof['testCount'], 12)
        self.assertEqual(proof['sourceMapping'], 'PARTIAL')
        self.assertFalse(proof['exhaustive'])
        self.assertFalse(proof['nativeAdmitted'])
        for name, sha in proof['inputs'].items():
            self.assertEqual(digest(ROOT/name), sha, name)
        source_map = json.loads((ROOT/'evidence/research/processor-interrupt-collective-wait/structure-lifetime-source-map.json').read_text())
        for row in source_map['mappings']:
            if not {'.cache', '.data'}.intersection(row['path'].split('/')):
                self.assertEqual(digest(ROOT/row['path']), row['sha256'], row['path'])
            else:
                # The retained PARTIAL map is a historical declaration, not a
                # portable current-source witness or a reason to publish Cache.
                self.assertEqual(len(row['sha256']), 64)
                self.assertEqual(proof['sourceMapping'], 'PARTIAL')
        from gambit_smp.output_observations import recorded
        tests = recorded(ROOT, ROOT/'evidence/model-results/processor-interrupt-collective-wait/structure-independent-audit-01/tests.log')['passedQuintTests']
        for name in ('objectOnlyRelocateRefreshReadTest', 'typeOnlyRelocateRefreshReadTest', 'missingObjectRootReadTest', 'missingTypeRootReadTest', 'legalReadThenRelocateTest'):
            self.assertIn(name, tests)

    def test_scheme_support_is_revoked_by_any_required_binding(self):
        doc, facts, catalog, _ = load(ROOT, VIEW)
        queries = dict(doc['queries'], applicable='applicable')
        with engine_api() as (engine, _):
            initial, _ = evaluate(engine, facts, catalog, queries)
            self.assertIn((CLAIM, WITNESS), initial['applicable'])
            for claim in NATIVE:
                self.assertIn((claim,), initial['unclosed'])
                self.assertFalse(any(row[0] == claim for row in initial['applicable']))
            for key, _ in facts['current_binding']:
                changed = dict(facts, current_binding=[(k, 'changed' if k == key else v) for k,v in facts['current_binding']])
                after, _ = evaluate(engine, changed, catalog, queries)
                self.assertNotIn((CLAIM, WITNESS), after['applicable'], key)
            # Retained predecessor identity cannot authenticate current controls.
            old = digest(ROOT/'evidence/model-results/processor-interrupt-collective-wait/structure-independent-audit-01/predecessor-model.qnt')
            changed = dict(facts, binding=[(w,k,old if k == 'model' else v) for w,k,v in facts['binding']])
            after, _ = evaluate(engine, changed, catalog, queries)
            self.assertNotIn((CLAIM,WITNESS), after['applicable'])
            changed = dict(facts, receipt=[(w,c,k,'DENY') for w,c,k,_ in facts['receipt']])
            after, _ = evaluate(engine, changed, catalog, queries)
            self.assertNotIn((CLAIM,WITNESS), after['applicable'])

if __name__ == '__main__':
    unittest.main()
