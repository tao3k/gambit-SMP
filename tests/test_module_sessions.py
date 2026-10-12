"""Real, source-bound native Evidence modules through the consumer API."""
from pathlib import Path
import os
import tempfile
import unittest

from gambit_smp.ascent_program import close_queries, evaluate, load_module_catalog, engine_api

MODULE = ':gerbil-ascent/t/qualification/evidence-api-module'


class ModuleSessionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()
        producer = cls.engine.build_receipt['producerBuild']
        bound = producer['linkedSchemeSources'][MODULE.lstrip(':')]
        cls.module_source = Path(os.environ.get('ASCENT_EVIDENCE_MODULE_SOURCE', bound['path']))

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def tearDown(self):
        close_queries(self.engine)

    def test_constructor_sources_retained_session_and_withdrawal(self):
        catalog = load_module_catalog(MODULE, 'make-values', [[1, 2]], inputs=[self.module_source])
        rows, first = evaluate(self.engine, {}, catalog, {'out': 'output'})
        self.assertEqual(rows['out'], [(1,), (2,)])
        rows, second = evaluate(self.engine, {}, catalog, {'in': 'input'})
        self.assertEqual(rows['in'], [(1,), (2,)])
        self.assertTrue(second['nativeResultReused'])
        self.assertEqual(first['nativeSessionHandle'], second['nativeSessionHandle'])
        self.assertEqual(second['ruleSyntax'], 'trusted-native-evidence-module.v1')
        rows, withdrawn = evaluate(self.engine, {'input': []}, catalog, {'out': 'output'})
        self.assertEqual(rows['out'], [])
        self.assertGreater(withdrawn['sourceGeneration'], second['sourceGeneration'])

    def test_native_values_do_not_require_scalar_projection(self):
        catalog = load_module_catalog(MODULE, 'make-values',
                                      [[{'type': 'number', 'value': '1/3'}]], inputs=[self.module_source])
        rows, metrics = evaluate(self.engine, {}, catalog, {'out': 'output'})
        self.assertEqual(rows['out']['value']['format'], 'native-value-graph.v1')
        self.assertIn('1/3', str(rows))
        self.assertEqual(metrics['proofProjection'], 'unsupported')
        self.assertEqual(metrics['resultEncoding'], 'partial')

    def test_identity_drift_retires_the_owner(self):
        with tempfile.TemporaryDirectory() as directory:
            context = Path(directory) / 'context.txt'
            context.write_text('one')
            catalog = load_module_catalog(MODULE, 'make-values', [[1]], inputs=[self.module_source, context])
            evaluate(self.engine, {}, catalog, {'out': 'output'})
            context.write_text('two')
            with self.assertRaisesRegex(ValueError, 'source generation changed'):
                evaluate(self.engine, {}, catalog, {'out': 'output'})
            self.assertEqual(self.engine._gambit_query_owners, {})

    def test_unbound_source_inventory_cannot_claim_the_compiled_module(self):
        with tempfile.TemporaryDirectory() as directory:
            unrelated = Path(directory) / 'not-module.ss'
            unrelated.write_text('(void)')
            catalog = load_module_catalog(MODULE, 'make-values', [[1]], inputs=[unrelated])
            with self.assertRaisesRegex(ValueError, 'does not match the compiled producer'):
                evaluate(self.engine, {}, catalog, {'out': 'output'})
