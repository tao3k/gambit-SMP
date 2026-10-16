"""Source-bound Rust DSL sessions; no compiled Scheme module contract."""
from pathlib import Path
import tempfile
import unittest

from gambit_smp.ascent_program import close_queries, evaluate, load_evidence_catalog, engine_api, _query_owners
from gambit_smp.framework import digest


class ModuleSessionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()
        cls.module_source = Path(__file__).parent / 'fixtures/evidence/session-values.ss'

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def tearDown(self):
        close_queries(self.engine)

    def test_constructor_sources_retained_session_and_withdrawal(self):
        catalog = load_evidence_catalog(self.module_source, constructor='make-values', trusted=True)
        rows, first = evaluate(self.engine, {}, catalog, {'out': 'output'})
        self.assertEqual(rows['out'], [(1,), (2,)])
        rows, second = evaluate(self.engine, {}, catalog, {'in': 'input'})
        self.assertEqual(rows['in'], [(1,), (2,)])
        self.assertTrue(second['nativeResultReused'])
        self.assertEqual(first['sessionOwner'], second['sessionOwner'])
        self.assertEqual(second['ruleSyntax'], 'trusted-evidence-dsl.v1')
        rows, withdrawn = evaluate(self.engine, {'input': []}, catalog, {'out': 'output'})
        self.assertEqual(rows['out'], [])
        self.assertGreater(withdrawn['sourceGeneration'], second['sourceGeneration'])

    def test_native_values_do_not_require_scalar_projection(self):
        catalog = load_evidence_catalog(self.module_source, constructor='make-fraction-values', trusted=True)
        rows, metrics = evaluate(self.engine, {}, catalog, {'out': 'output'})
        self.assertEqual(rows['out']['value']['format'], 'native-value-graph.v1')
        self.assertIn('1/3', str(rows))
        self.assertEqual(metrics['proofProjection'], 'supported')
        self.assertEqual(metrics['resultEncoding'], 'partial')

    def test_identity_drift_retires_the_owner(self):
        with tempfile.TemporaryDirectory() as directory:
            context = Path(directory) / 'context.txt'
            context.write_text('one')
            catalog = load_evidence_catalog(self.module_source, constructor='make-values', trusted=True)
            catalog['sourceInputs'][str(context.resolve())] = digest(context)
            evaluate(self.engine, {}, catalog, {'out': 'output'})
            context.write_text('two')
            with self.assertRaisesRegex(ValueError, 'source generation changed'):
                evaluate(self.engine, {}, catalog, {'out': 'output'})
            self.assertEqual(_query_owners.get(self.engine, {}), {})

    def test_unbound_source_inventory_cannot_claim_the_compiled_module(self):
        with tempfile.TemporaryDirectory() as directory:
            unrelated = Path(directory) / 'not-module.ss'
            unrelated.write_text('(void)')
            catalog = load_evidence_catalog(self.module_source, constructor='make-values', trusted=True)
            catalog['sourceInputs'] = {str(unrelated.resolve()): digest(unrelated)}
            with self.assertRaisesRegex(ValueError, 'inventory omits a bound source'):
                evaluate(self.engine, {}, catalog, {'out': 'output'})
