"""Real import-free consumer DSL; legacy queries are comparison observations."""
import unittest
import json
from pathlib import Path
from gambit_smp import evidence_index, reasoning_history
from gambit_smp.ascent_program import load_catalog, load_component_catalog, engine_api, query, SourceQueryOwner
from gambit_smp.framework import ROOT


class EvidenceDSLMainpaths(unittest.TestCase):
    def entry(self, name):
        scenario = json.loads((ROOT / 'evidence/scenarios/catalog-review-history/scenario.json').read_text())
        declaration = scenario['entries'][name]
        return load_component_catalog(ROOT / scenario['manifest'], entry=name,
                                      constructor=declaration['constructor'], trusted=True)

    def test_catalog_complete_inventory_matches_previous_native_rules(self):
        exported = evidence_index.export()
        catalog = self.entry('catalog')
        with engine_api() as (engine, _):
            new_metrics = {}
            actual = evidence_index.query(exported['facts'], catalog, engine=engine, metrics=new_metrics)
            prior = evidence_index.query(exported['facts'],
                        load_catalog(ROOT / 'evidence/catalog.ss'), engine=engine)
        self.assertEqual(actual, prior)
        self.assertEqual(new_metrics['ruleSyntax'], 'ascent.evidence-components.v1')
        self.assertIn(str(ROOT / 'evidence/dsl/catalog.ss'), new_metrics['ruleSourceInputs'])
        self.assertFalse(new_metrics.get('runtimeAdmitted', False))

    def test_review_dsl_keeps_failure_and_missing_premise_denials(self):
        from gambit_smp.ascent_review import REVIEW_OUTPUTS, collect
        facts, inputs, failures, *_ = collect(ROOT)
        catalog = self.entry('review')
        for path, sha in catalog['sourceInputs'].items():
            self.assertEqual(inputs[str(Path(path).relative_to(ROOT))], sha)
        with engine_api() as (engine, _):
            metrics = {}
            actual = query(facts, catalog, {name: name for name in REVIEW_OUTPUTS},
                           engine=engine, metrics=metrics)
            prior = query(facts, load_catalog(ROOT / 'evidence/review-rules.ss'),
                          {name: name for name in REVIEW_OUTPUTS}, engine=engine)
        self.assertEqual(actual, prior)
        self.assertTrue(failures)
        for failure in failures:
            self.assertIn((failure['id'], 'unchanged-failed-inputs'), actual['Denial'])
            self.assertIn((failure['id'], 'DENY'), actual['Decision'])
        self.assertEqual(metrics['ruleSyntax'], 'ascent.evidence-components.v1')

    def test_history_dsl_native_add_remove_retain_and_changed_input(self):
        exported = evidence_index.export()
        with engine_api() as (engine, backend):
            answers = evidence_index.query(exported['facts'], self.entry('catalog'), engine=engine)
            rows = [(name, reasoning_history.canonical(row))
                    for name, values in answers.items() for row in values]
            self.assertTrue(rows)
            bound = list(exported['inputs'].items()) + list(backend.items())
            facts = {'previous_row': rows, 'current_row': rows,
                     'previous_input': bound, 'current_input': bound}
            catalog = self.entry('history')
            owner = SourceQueryOwner(engine, {}, catalog)
            try:
                first, receipt = owner.evaluate(facts, reasoning_history.QUERIES, 1000000000)
                self.assertEqual(first['retained'], sorted(set(rows)))
                self.assertEqual(first['added'], [])
                self.assertEqual(first['removed'], [])
                explanation = owner.last_result.explanation('retained')
                owner.last_result.close()
                description = json.dumps(explanation.graph)
                self.assertIn('recorded-only', description)
                self.assertIn('per-row proof', description)
                self.assertIn(bound[0][1], description)
                explanation.close()
                with self.assertRaises(ValueError):
                    explanation.reference(0)
                withdrawn = dict(facts, current_row=rows[1:], current_input=bound[1:])
                second, reused = owner.evaluate(withdrawn, reasoning_history.QUERIES, 1000000000)
                self.assertEqual(second['removed'], [rows[0]])
                self.assertEqual(second['removedInputs'], [(bound[0][0],)])
                self.assertEqual(second['added'], [])
                restored, final = owner.evaluate(facts, reasoning_history.QUERIES, 1000000000)
                self.assertEqual(restored, first)
                self.assertEqual(receipt['nativeSessionHandle'], reused['nativeSessionHandle'])
                self.assertEqual(receipt['nativeSessionHandle'], final['nativeSessionHandle'])
                self.assertEqual(receipt['ruleSourceInputs'], catalog['sourceInputs'])
            finally:
                owner.close()
            with self.assertRaises((ValueError, RuntimeError)):
                owner.evaluate(facts, reasoning_history.QUERIES, 1000000000)

    def test_downstream_assets_have_no_scheme_package_or_import_scaffolding(self):
        directory = ROOT / 'evidence/dsl'
        for path in directory.rglob('*.ss'):
            text = path.read_text()
            for token in ('(import ', '(module ', '(export ', 'gerbil.pkg', 'gxc:'):
                self.assertNotIn(token, text)
        self.assertFalse((directory / 'gerbil.pkg').exists())
        self.assertFalse((directory / 'build.ss').exists())
        self.assertFalse((ROOT / 'evidence/scenarios/components/left.ss').exists())
        self.assertFalse((ROOT / 'evidence/scenarios/components/right.ss').exists())
        for name in ('catalog', 'review', 'history'):
            text = (directory / (name + '.ss')).read_text()
            self.assertIn('(define-evidence (make-' + name + ')', text)
            self.assertIn('(sources ', text)
            self.assertIn('(outputs ', text)
            self.assertIn('(relation ', text)
            self.assertNotIn('make-recorded-module', text)
            self.assertNotIn('relational-compose', text)
        history = (directory / 'history.ss').read_text()
        self.assertIn('<--', history)
        self.assertNotIn('(include ', history)
