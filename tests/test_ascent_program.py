import unittest
import tempfile
from pathlib import Path
from unittest.mock import Mock, patch
import json

from gambit_smp.ascent_program import evaluate, load_catalog, load_inert_catalog, load_evidence_catalog, engine_api, SourceQueryOwner, INERT_RULE_CONTRACT
from gambit_smp.framework import ROOT


class RuleEntryContractTests(unittest.TestCase):
    def test_checked_inventory_projection_reuses_only_exact_seal_and_declaration(self):
        from gambit_smp import ascent_program as api
        api._bound_api_inventory.cache_clear()
        self.addCleanup(api._bound_api_inventory.cache_clear)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            declaration = root / 'pyproject.toml'
            declaration.write_text('first declaration')
            files = {'binding': root / 'binding.py'}
            build = {'nested': {'value': 'original'}}
            manifest = {'engineId': 'first', 'files': {'binding.py': 'sha'}}
            with patch.object(api, 'ROOT', root), patch(
                    'gambit_smp.ascent_runtime.inventory', return_value=(files, build)) as inventory:
                token = api._verified_api.set((root, manifest))
                try:
                    selected, metadata, _ = api._api_inventory()
                    selected.clear()
                    metadata['nested']['value'] = 'caller mutation'
                    again, metadata, _ = api._api_inventory()
                    self.assertEqual(again, files)
                    self.assertEqual(metadata['nested']['value'], 'original')
                    self.assertEqual(inventory.call_count, 1)
                    declaration.write_text('changed declaration')
                    api._api_inventory()
                    self.assertEqual(inventory.call_count, 2)
                    manifest = dict(manifest, engineId='second')
                    api._verified_api.set((root, manifest))
                    api._api_inventory()
                    self.assertEqual(inventory.call_count, 3)
                finally:
                    api._verified_api.reset(token)

    def test_engine_boundary_closes_only_owned_temporary_engines(self):
        from gambit_smp import ascent_program
        for owned, retain, fail in ((True, False, False), (True, False, True),
                                    (False, False, False), (True, True, False)):
            with self.subTest(owned=owned, retain=retain, fail=fail):
                engine = Mock()
                with patch.object(ascent_program, '_api_entry', return_value=(
                        engine, {}, {}, owned, ('checked', {}))), \
                        patch.object(ascent_program, 'close_queries'):
                    try:
                        with engine_api(retain=retain) as (selected, _):
                            self.assertIs(selected, engine)
                            if fail:
                                raise RuntimeError('caller failed')
                    except RuntimeError:
                        self.assertTrue(fail)
                if owned and not retain:
                    engine.close.assert_called_once_with()
                else:
                    engine.close.assert_not_called()

    def test_retained_engine_exit_closes_engine_even_if_session_cleanup_fails(self):
        from gambit_smp import ascent_program
        import os
        import threading
        engine = Mock(closed=False)
        with patch.object(ascent_program, '_retained_engine', engine), \
                patch.object(ascent_program, '_retained_owner', (os.getpid(), threading.get_ident())), \
                patch.object(ascent_program, 'close_retained_queries', side_effect=RuntimeError('cleanup')):
            with self.assertRaisesRegex(RuntimeError, 'cleanup'):
                ascent_program._close_retained_at_exit()
        engine.close.assert_called_once_with()

    def test_inventory_uses_only_the_installed_rust_provider(self):
        from gambit_smp import ascent_program
        with tempfile.TemporaryDirectory() as directory:
            extension = Path(directory).resolve() / '_core.abi3.so'
            extension.write_bytes(b'identity transport fixture, not executable')
            build = {'schema': 'ascent.rust-build.v1', 'rayon': True,
                     'sourceInputs': {'file.rs': 'source-sha'}, 'runtimeInputs': {'/module.o1': 'runtime-sha'}}
            with patch('gambit_smp.ascent_runtime.inventory',
                       return_value=({'ascent._core': extension}, build)) as inventory:
                files, actual, identity = ascent_program._api_inventory()
            self.assertEqual(extension, files['ascent._core'])
            self.assertEqual(build, actual)
            self.assertNotIn('library', files)
            self.assertNotIn('buildReceipt', files)
            self.assertEqual(64, len(identity))
            inventory.assert_called_once_with(sealed_root=None, verify=False)

    def test_unsealed_boundary_rejects_binding_inventory_growth(self):
        from gambit_smp import ascent_program
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'binding.py'
            source.write_text('original fixture\n')
            engine = Mock()
            files = {'binding': source}
            from gambit_smp.framework import digest
            with patch.object(ascent_program, '_api_entry', return_value=(
                    engine, {'binding': digest(source)}, files, False, None)), \
                    patch.object(ascent_program, 'artifact_paths', return_value={
                        **files, 'new-binding': Path(directory) / 'new.py'}):
                with self.assertRaisesRegex(ValueError, 'changed during audit'):
                    with ascent_program.engine_api(engine=engine):
                        pass

    def test_missing_compiled_sources_do_not_fall_back(self):
        from gambit_smp import ascent_program
        from ascent.build import runtime_identity
        build = runtime_identity()
        build['sourceInputs'] = {}
        with patch('ascent.build.runtime_identity', return_value=build):
            with self.assertRaisesRegex(ValueError, 'complete compiled ASCENT inputs'):
                ascent_program._api_inventory()

    def test_packaged_inventory_does_not_require_an_sdk_environment(self):
        from gambit_smp import ascent_program
        with patch.dict('os.environ', {}, clear=True):
            files, build, receipt = ascent_program._api_inventory()
        self.assertTrue(build['sourceInputs'])
        self.assertTrue(build['installedInputs'])
        self.assertIn('ascent._core', files)
        self.assertTrue(receipt)

    def test_sealed_projection_uses_only_verified_exact_inventory(self):
        from gambit_smp.ascent_program import _sealed_api_identities
        root = Path('/seal')
        manifest = {'files': {'native/syntax/resource.ss': 'checked-sha'}}
        self.assertEqual(_sealed_api_identities(
            {'resource': root / 'native/syntax/resource.ss'}, root, manifest),
            {'resource': 'checked-sha'})
        for path in (Path('/other/native/syntax/resource.ss'),
                     Path('/seal/native/../native/syntax/resource.ss'),
                     Path('native/syntax/resource.ss'), Path('/seal/native/unlisted.ss')):
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'escaped'):
                _sealed_api_identities({'resource': path}, root, manifest)

    def test_inert_entry_binds_exact_sources_without_switching_full_dsl(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'rules.ss'
            path.write_text('(ascent-fragment (relation Seed ((n integer?))))')
            full = load_catalog(path)
            inert = load_inert_catalog(path)
            self.assertEqual(full['sourceInputs'], inert['sourceInputs'])
            self.assertEqual(full['sourceTexts'], inert['inertRuleTexts'])
            self.assertNotIn('inertRuleTexts', full)
            self.assertNotIn('sourceTexts', inert)

    def test_missing_or_wrong_inert_contract_never_falls_back(self):
        for description in ({'operations': ['open-sources']},
                            {'operations': ['open-rule-sources'], 'ruleTextContract': 'other'}):
            with self.subTest(description=description):
                engine = Mock()
                engine.describe.return_value = description
                with self.assertRaises(ValueError):
                    SourceQueryOwner(engine, {}, {'inertRuleTexts': ['entire source'], 'sourceInputs': {}})
                engine.open_sources.assert_not_called()
                engine.open_rule_sources.assert_not_called()

    def test_recipe_contract_is_explicit_and_exclusive(self):
        from gambit_smp.evidence_capabilities import validate
        args = {'rules': ['rules.ss'], 'rulesContract': INERT_RULE_CONTRACT,
                'queries': {'q': 'Answer'}, 'expected': {'q': []}}
        validate(args, {'rules.ss': 'source hash'})
        with self.assertRaisesRegex(ValueError, 'inert rule contract'):
            validate(dict(args, rulesContract='unknown'), {'rules.ss': 'source hash'})
        with self.assertRaisesRegex(ValueError, 'inert rule contract'):
            validate({'dsl': 'entry.json', 'rulesContract': INERT_RULE_CONTRACT,
                      'queries': args['queries'], 'expected': args['expected']}, {'entry.json': 'hash'})


class NativeAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, cls.identities = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def test_recursive_negation_and_retained_component_reuse(self):
        catalog = load_evidence_catalog(ROOT / "tests/fixtures/evidence/recursive-audit.ss",
                                        constructor="make-recursive-audit", trusted=True)
        answers, metrics = evaluate(self.engine,
            {"edge": [["a", "b"], ["b", "c"]], "bad": [["c"]]}, catalog,
            {"all": "path", "safe": "usable"})
        self.assertEqual(answers["all"], [("a", "b"), ("a", "c"), ("b", "c")])
        self.assertEqual(answers["safe"], [("a", "b")])
        repeated, retained = evaluate(self.engine,
            {"edge": [["a", "b"], ["b", "c"]], "bad": [["c"]]}, catalog,
            {"all": "path", "safe": "usable"})
        self.assertEqual(answers, repeated)
        self.assertTrue(retained["nativeResultReused"])
        self.assertEqual(metrics["sessionOwner"], retained["sessionOwner"])

    def test_decoded_rules_cannot_select_a_python_execution_fallback(self):
        catalog = self.engine.read_rules("(ascent-fragment (relation input ((value symbol?))))")
        with self.assertRaisesRegex(ValueError, "decoded rule dictionaries"):
            evaluate(self.engine, {"input": [["value"]]}, catalog, {"input": "input"})

    def test_actual_full_audit_default_and_managed_engine_agree(self):
        from gambit_smp import research_audit as audit
        from gambit_smp.protocol_evidence import facts as protocol_facts
        from gambit_smp.protocol_source_audit import facts as source_facts
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        inputs.update(base["inputs"])
        audit.reusable_receipts(audit.ROOT, base, facts, inputs)
        for collect in (protocol_facts, source_facts):
            extra, bound = collect(audit.ROOT)
            facts.update(extra)
            inputs.update(bound)
        expected = audit.query(base, facts, audit.ROOT)
        metrics = {}
        actual = audit.query(base, facts, audit.ROOT, engine=self.engine, metrics=metrics)
        self.assertEqual(expected, actual)
        self.assertTrue(metrics["retainedOwner"])
        audit.query(base, facts, audit.ROOT, engine=self.engine, metrics=metrics)
        self.assertTrue(metrics["nativeResultReused"])
        self.assertTrue(all(audit.digest(audit.local(audit.ROOT, name)) == sha for name, sha in inputs.items()))

    def test_retry_denials_and_review_only_match_for_all_boolean_inputs(self):
        from itertools import product
        from gambit_smp import research_audit as audit
        facts = {name: [] for name in audit.ARITIES}
        flags = ("retry_delta", "retry_budget_expanded", "retry_scope_mismatch",
                 "retry_hypothesis", "retry_unbound")
        expected_denials, expected_review = [], []
        for index, values in enumerate(product((False, True), repeat=len(flags))):
            route = str(index)
            facts["retry_route"].append([route])
            for flag, enabled in zip(flags, values):
                if enabled:
                    facts[flag].append([route])
            delta, budget, scope, hypothesis, unbound = values
            reasons = [reason for condition, reason in (
                (not delta, "unchanged-tested-inputs"), (budget, "budget-expanded"),
                (scope, "failure-scope-mismatch"), (not hypothesis, "missing-causal-hypothesis"),
                (unbound, "unreviewed-artifact-identity")) if condition]
            expected_denials.extend((route, reason) for reason in reasons)
            if not reasons:
                expected_review.append((route,))
        result, _ = evaluate(self.engine, facts,
            load_catalog(audit.ROOT / "evidence/research-rules.ss"),
            {"deny": "retry_denied", "review": "retry_review_required"})
        self.assertEqual(sorted(expected_denials), result["deny"])
        self.assertEqual(expected_review, result["review"])


if __name__ == "__main__":
    unittest.main()
