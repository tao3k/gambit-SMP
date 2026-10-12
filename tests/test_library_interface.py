"""Public Library roles, without a redundant implementation namespace."""
import unittest
import copy
import json
from pathlib import Path

import ascent_engine
from gambit_smp.ascent_program import engine_api, load_component_catalog, SourceQueryOwner


class LibraryInterfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def test_public_objects_are_named_for_their_roles(self):
        for name in ('Module', 'Value', 'Result', 'Explanation'):
            self.assertTrue(hasattr(ascent_engine, name))
            self.assertFalse(hasattr(ascent_engine, 'Native' + name))

    def test_dsl_calls_return_the_public_owned_types(self):
        with self.engine.dsl('(def (answer) 42)', trusted=True) as module:
            self.assertIsInstance(module, ascent_engine.Module)
            with module.call('answer') as value:
                self.assertIsInstance(value, ascent_engine.Value)
                self.assertEqual(value.graph['root']['value'], '42')
        with self.assertRaises(ValueError):
            value.reference()

    def test_build_binds_the_responsibility_named_modules(self):
        producer = self.engine.build_receipt['producerBuild']
        self.assertEqual(producer['entryModule'], ':gerbil-ascent/interface/entry')
        sources = producer['sourceInputs']
        for path in ('bindings/artifact.ss', 'bindings/build-entry.ss',
                     'interface/generated-resources.ss', 'interface/value-graph.ss',
                     'interface/runtime.ss', 'interface/entry.ss'):
            self.assertIn(path, sources)
        self.assertNotIn('bindings/native-build-entry.ss', sources)

    def test_component_assets_through_the_actual_library(self):
        root = Path(__file__).resolve().parents[1] / 'tests/fixtures/components'
        cases = json.loads((root / 'cases.json').read_text())
        catalog = load_component_catalog(root / cases['manifest'], entry=cases['entry'],
                                         constructor='make-investigation', trusted=True)
        declaration = catalog['nativeComponents']
        with self.engine.components(declaration['manifest'], declaration['sources'],
                                    declaration['entry'], trusted=True) as owner:
            self.assertEqual(list(owner.components), cases['loaded'])
            for call in cases['calls']:
                with owner.call(call['export'], component=call['component']) as value:
                    self.assertEqual(value.graph['root'], call['root'])
            for call in cases['rejections']:
                with self.assertRaises(ascent_engine.EngineError):
                    owner.call(call['export'], component=call['component'])
        with self.assertRaises(ValueError):
            owner.call('verify')
        query_owner = SourceQueryOwner(self.engine, {}, catalog)
        try:
            for rows in cases['sourceReplacements']:
                answers, receipt = query_owner.evaluate({'input': rows}, {'answer': cases['relation']}, 1000000000)
                self.assertEqual(answers['answer'], [tuple(row) for row in rows])
                self.assertEqual(receipt['ruleSyntax'], 'ascent.evidence-components.v1')
        finally:
            query_owner.close()

    def test_component_dependency_rejections_are_native(self):
        root = Path(__file__).resolve().parents[1] / 'tests/fixtures/components'
        catalog = load_component_catalog(root / 'components.json', entry='investigation',
                                         constructor='make-investigation', trusted=True)
        declaration = catalog['nativeComponents']
        for dependency in ({'component': 'absent', 'bindings': []},
                           {'component': 'investigation', 'bindings': []},
                           {'component': 'left', 'bindings': ['hidden']}):
            manifest = copy.deepcopy(declaration['manifest'])
            manifest['components'][0]['dependencies'] = [dependency]
            with self.assertRaises(ascent_engine.EngineError):
                self.engine.components(manifest, declaration['sources'], 'investigation', trusted=True)


if __name__ == '__main__':
    unittest.main()
