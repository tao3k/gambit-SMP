"""Agent transport consumes actual upstream objects, not Catalog projection."""
import copy
from pathlib import Path
import tempfile
import unittest
from gambit_smp.ascent_program import definitions, load_evidence_catalog, engine_api


class AgenticModuleCalls(unittest.TestCase):
    def test_agent_uses_library_relation_graph_and_independent_session(self):
        import ascent
        from ascent import FactLimits
        self.assertFalse(hasattr(ascent, 'Plan'))
        with engine_api() as (engine, identity):
            self.assertTrue(identity)
            with engine.source_graph('input', 2, [[1, 2]]) as source:
                with source.project([1]) as graph:
                    self.assertIsInstance(graph, ascent.Graph)
                    self.assertEqual(graph.width, 1)
                    session = graph.open_session('output', limits=FactLimits(16, 64, 128))
            # The admitted session owns the graph after construction handles close.
            with session:
                observed = session.run()
                result = session.result(observed)
                try:
                    self.assertEqual(result.rows('output')['rows'], [[2]])
                    self.assertEqual(result.graph('output')['format'], 'native-value-graph.v1')
                finally:
                    result.close()
                session.replace({'input': []})
                withdrawn = session.run()
                result = session.result(withdrawn)
                try:
                    self.assertEqual(result.rows('output')['rows'], [])
                finally:
                    result.close()
            with self.assertRaises(ValueError):
                graph.open_session('output')

    def test_unknown_producer_module_does_not_fall_back_to_fragment(self):
        with engine_api() as (engine, _):
            self.assertFalse(hasattr(engine, 'module'))
            self.assertFalse(hasattr(engine, 'open_module'))
            self.assertFalse(hasattr(engine, 'source_plan'))

    def test_definition_owner_binds_actual_bytes_and_rejects_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'definitions.ss'
            source.write_text('(define-evidence (value) (sources) (outputs answer) (relation answer ((x exact-integer?)) ((7))))\n')
            bound = load_evidence_catalog(source, trusted=True)
            forged = copy.deepcopy(bound)
            forged['nativeEvidence']['source'] = '(define-evidence (value) (sources) (outputs answer) (relation answer ((x exact-integer?)) ((0))))'
            with self.assertRaisesRegex(ValueError, 'differ from'):
                with definitions(forged):
                    self.fail('unbound source bytes executed')
            with self.assertRaisesRegex(ValueError, 'changed during'):
                with definitions(bound) as (module, identity):
                    with module.run(result_format='typed-rows') as result:
                        self.assertEqual(result.value()['relations']['answer'], [[7]])
                    source.write_text('(define-evidence (value) (sources) (outputs answer) (relation answer ((x exact-integer?)) ((8))))\n')
            with self.assertRaises(ValueError):
                module.run()

    def test_fixed_graph_closure_retains_captures_without_a_vm(self):
        with engine_api() as (engine, _):
            graph = {'algorithm': 'projection', 'source': 'input', 'width': 2,
                     'rows': [[1, 7]], 'output': 'answer', 'captures': {'columns': [1]}}
            with engine.core_graph(graph, trusted=True) as owner:
                owner.replace({'input': [[2, 9]]}).value()
                with owner.run(result_format='typed-rows') as result:
                    self.assertEqual(result.value()['relations']['answer'], [[9]])
            with self.assertRaises(ValueError):
                owner.run()


if __name__ == '__main__': unittest.main()
