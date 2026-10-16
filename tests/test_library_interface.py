"""Public Library roles, without a redundant implementation namespace."""
import unittest
import copy
import json
from pathlib import Path
from unittest.mock import patch

import ascent
from gambit_smp.ascent_program import engine_api, load_component_catalog, SourceQueryOwner, _api_inventory


class ArtifactBoundaryTests(unittest.TestCase):
    def test_duplicate_bindings_hash_each_path_once_per_boundary_not_across_boundaries(self):
        from gambit_smp.ascent_program import _file_identities
        path = Path("/bound/resource")
        files = {"source:a": path, "package:a": path}
        with patch("gambit_smp.ascent_program.digest", side_effect=["before", "after"]) as sha:
            self.assertEqual(_file_identities(files), {"source:a": "before", "package:a": "before"})
            self.assertEqual(_file_identities(files), {"source:a": "after", "package:a": "after"})
            self.assertEqual(sha.call_count, 2)


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
            self.assertTrue(hasattr(ascent, name))
            self.assertFalse(hasattr(ascent, 'Native' + name))

    def test_dsl_calls_return_the_public_owned_types(self):
        source = '(define-evidence (answer) (sources) (outputs value) (relation value ((x exact-integer?)) ((42))))'
        with self.engine.dsl(source, trusted=True) as owner:
            self.assertIsInstance(owner, ascent.CoreSession)
            with owner.run(result_format='typed-rows') as value:
                self.assertIsInstance(value, ascent.CoreValue)
                self.assertEqual(value.value()['relations']['value'], [[42]])
        with self.assertRaises(ValueError):
            value.value()
        with self.assertRaises(ascent.EngineError):
            self.engine.dsl('(def (answer) 42)', trusted=True)

    def test_build_binds_the_responsibility_named_modules(self):
        producer = _api_inventory()[1]
        self.assertEqual(producer['schema'], 'ascent.rust-build.v1')
        self.assertTrue(producer['rayon'])
        payloads = producer['sourceInputs']
        self.assertEqual(set(payloads), set(producer['sourceOrigins']))
        self.assertTrue(all(path.endswith('/source.bin') for path in payloads))
        sources = {path.removesuffix('/source.bin'): sha for path, sha in payloads.items()}
        for path in ('rust/ascent/src/source/evidence.rs',
                     'rust/ascent/src/source/components.rs',
                     'rust/ascent/src/source/graphs.rs',
                     'rust/ascent/src/object_graph.rs',
                     'rust/ascent-python/src/rust_api.rs',
                     'rust/ascent-python/src/rust_components.rs',
                     'rust/ascent-python/src/lib.rs', 'rust/Cargo.lock'):
            self.assertIn(path, sources)
        # The build-only execution IR origin remains a real source input,
        # not a linked Scheme module or a runtime VM dependency.
        self.assertEqual({path for path in sources if path.endswith(('.ss', '.scm'))},
                         {'program/rust-execution.ss'})
        self.assertEqual(producer['backend'], 'rust')
        self.assertNotIn('interface/generated-resources.ss', sources)
        self.assertNotIn('bindings/native-build-entry.ss', sources)

    def test_component_assets_through_the_actual_library(self):
        root = Path(__file__).resolve().parents[1] / 'tests/fixtures/components'
        cases = json.loads((root / 'cases.json').read_text())
        catalog = load_component_catalog(root / 'declarative.json', entry=cases['entry'],
                                         constructor='make-investigation', trusted=True)
        declaration = catalog['nativeComponents']
        with self.engine.components(declaration['manifest'], declaration['sources'],
                                    declaration['entry'], trusted=True) as owner:
            self.assertEqual(set(owner.components), set(cases['loaded']))
            for component, constructor, expected in [('left', 'make-left', 1), ('right', 'make-right', 2)]:
                with owner.call(constructor, component=component) as declaration:
                    with declaration.open_session() as session:
                        receipt = session.run()
                        with session.result(receipt) as result:
                            self.assertEqual(result.rows('answer')['rows'], [[expected]])
            for call in cases['rejections']:
                with self.assertRaises(ascent.EngineError):
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
            with self.assertRaises(ascent.EngineError):
                self.engine.components(manifest, declaration['sources'], 'investigation', trusted=True)


if __name__ == '__main__':
    unittest.main()
