"""Real evidence through downstream DSL and a Python-only Library entry."""
import json
import unittest
from ascent import EngineError

from gambit_smp.ascent_program import definitions, evaluate, load_component_catalog, engine_api
from gambit_smp import ascent_program
from gambit_smp.evidence_index import export
from gambit_smp.framework import ROOT, digest


class EvidenceInvestigationScenario(unittest.TestCase):
    def test_complete_inventory_update_withdrawal_and_native_explanation(self):
        entry = json.loads((ROOT / 'evidence/scenarios/investigation/entry.json').read_text())
        index = export()
        inventory_path = ROOT / 'evidence/native-failures.json'
        inventory = json.loads(inventory_path.read_text())
        self.assertEqual(index['inputs']['evidence/native-failures.json'], digest(inventory_path))
        facts = {name: [list(row) for row in index['facts'][source]]
                 for name, source in entry['sourceBindings'].items()}
        facts['inventory'] = [[row['id'], row['category'], row['status']]
                              for row in inventory['failures']]
        with engine_api() as (engine, identity):
            catalog = load_component_catalog(ROOT / entry['manifest'], entry=entry['entry'],
                constructor=entry['constructor'],
                arguments=entry['arguments'], trusted=True)
            answers, first = evaluate(engine, facts, catalog, entry['queries'])
            self.assertEqual(answers['inventory'], [(len(facts['inventory']),)])
            self.assertEqual(answers['observations'], [(len(facts['observation']),)])
            self.assertEqual(len(answers['failures']), len(facts['process']))
            self.assertEqual(answers['fields'], answers['lattice'])
            for parent, child, obligation in facts['contracts']:
                self.assertIn((parent, child), answers['dependencies'])
            repeated, second = evaluate(engine, facts, catalog, entry['queries'])
            self.assertEqual(answers, repeated)
            self.assertEqual(first['sourceGeneration'], second['sourceGeneration'])
            self.assertTrue(second['nativeResultReused'])
            owner = next(iter(ascent_program._query_owners[engine].values()))
            explanation = owner.last_result.explanation('missing')
            owner.last_result.close()
            text = json.dumps(explanation.graph)
            self.assertIn('recorded-only', text)
            self.assertIn('per-row proof', text)
            self.assertIn(facts['field'][0][2], text)
            self.assertIn(facts['field'][0][3], text)
            explanation.close()
            with self.assertRaises(ValueError):
                _ = explanation.graph
            # Withdraw an actual existing required field, then restore its bytes.
            withdrawn = next(row for row in facts['field'] if row[1] == 'fixture-sha')
            updated = dict(facts, field=[row for row in facts['field'] if row != withdrawn])
            changed, third = evaluate(engine, updated, catalog, entry['queries'])
            self.assertIn((withdrawn[0], withdrawn[1]), changed['gaps'])
            self.assertNotIn((withdrawn[0], withdrawn[1]), answers['gaps'])
            self.assertGreater(third['sourceGeneration'], second['sourceGeneration'])
            self.assertEqual(changed['fields'], changed['lattice'])
            self.assertEqual(dict(changed['fields'])[withdrawn[0]],
                             dict(answers['fields'])[withdrawn[0]] - 1)
            restored, fourth = evaluate(engine, facts, catalog, entry['queries'])
            self.assertEqual(restored, answers)
            self.assertGreater(fourth['sourceGeneration'], third['sourceGeneration'])
            self.assertEqual(first['sessionOwner'], fourth['sessionOwner'])
            # The explicitly approved contract uses precompiled Graph closures,
            # not runtime ordinary Scheme procedures or a host interpreter.
            edges = [row[:2] for row in facts['contracts']]
            for workers in (1, 2, 4):
                from ascent import Engine
                with Engine(workers=workers) as graph_engine:
                    graph = {'algorithm': 'transitive', 'source': 'contracts', 'width': 2,
                             'rows': edges, 'output': 'ancestry', 'captures': {}}
                    with graph_engine.core_graph(graph, trusted=True) as updater:
                        for current in (facts, dict(facts, contracts=facts['contracts'][1:]), facts):
                            expected, _ = evaluate(engine, current, catalog, entry['queries'])
                            updater.replace({'contracts': [row[:2] for row in current['contracts']]}).value()
                            with updater.run(result_format='typed-rows') as result:
                                actual = result.value()['relations']['ancestry']
                                ancestry = [[{'type': 'string', 'value': value} for value in row]
                                            for row in expected['dependencies']]
                                self.assertEqual(actual, ancestry)
                        self.assertFalse(updater.runtime().value()['schemeVm'])
                    with self.assertRaises(ValueError):
                        updater.run()
            self.assertTrue(identity)
        with self.assertRaises(ValueError):
            owner.session.run()


if __name__ == '__main__':
    unittest.main()
