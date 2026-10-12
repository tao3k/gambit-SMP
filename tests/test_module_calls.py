"""Agent transport consumes actual upstream objects, not Catalog projection."""
import copy
from pathlib import Path
import tempfile
import unittest
from gambit_smp.ascent_program import definitions, load_evidence_catalog, modules


class AgenticModuleCalls(unittest.TestCase):
    def test_agent_uses_upstream_operator_and_first_class_plan(self):
        with modules(':gerbil-ascent/program/interface') as (module, identity):
            self.assertEqual(identity['entry'], 'trusted-native-module-calls.v1')
            self.assertTrue(identity['compiledSources'])
            self.assertFalse(identity['sourceRefinementAdmitted'])
            with module.call('relational-op-source', {'type': 'symbol', 'value': 'input'},
                             2, [[1, 2]]) as source:
                with module.call('relational-op-project', source.reference(), [1]) as operator:
                    self.assertIn('opaque', str(operator.graph))
                    with module.call('relational-op-fragment', operator.reference(),
                                     {'type': 'symbol', 'value': 'output'}) as fragment:
                        with module.call('relational-compose', [fragment.reference()],
                                         16, 64, 128) as program:
                            with module.call('relational-admit', program.reference()) as admitted:
                                with module.call('relational-solve', admitted.reference()) as solution:
                                    with module.call('relational-query', solution.reference(),
                                                     fragment.reference(),
                                                     {'type': 'symbol', 'value': 'output'}) as result:
                                        self.assertEqual(result.graph['format'], 'native-value-graph.v1')
                                        self.assertIn("'value': '2'", str(result.graph))
        with self.assertRaises(ValueError): operator.reference()

    def test_unknown_producer_module_does_not_fall_back_to_fragment(self):
        with self.assertRaisesRegex(ValueError, 'not bound'):
            with modules(':unbound/custom-evidence'):
                self.fail('unbound module was admitted')

    def test_definition_owner_binds_actual_bytes_and_rejects_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'definitions.ss'
            source.write_text('(def (make-value x) (lambda () x))\n')
            bound = load_evidence_catalog(source, trusted=True)
            forged = copy.deepcopy(bound)
            forged['nativeEvidence']['source'] = '(def (make-value x) 0)'
            with self.assertRaisesRegex(ValueError, 'differ from'):
                with definitions(forged):
                    self.fail('unbound source bytes executed')
            with self.assertRaisesRegex(ValueError, 'changed during'):
                with definitions(bound) as (module, identity):
                    with module.call('make-value', 7) as closure:
                        with closure.apply() as result:
                            self.assertIn("'value': '7'", str(result.graph))
                    source.write_text('(def (make-value x) x)\n')
            with self.assertRaises(ValueError):
                closure.apply()


if __name__ == '__main__': unittest.main()
