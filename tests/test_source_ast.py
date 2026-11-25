"""Real Python syntax -> native Evidence; no compiler/package admission."""
import copy
import hashlib
import json
from pathlib import Path
import unittest

from gambit_smp import source_ast
from gambit_smp.ascent_program import engine_api, evaluate, load_evidence_catalog
from gambit_smp.framework import ROOT

BASE = ROOT / 'evidence/scenarios/darwin-acceleration'


class SourceAstTests(unittest.TestCase):
    def extract(self, text):
        data = text.encode()
        return source_ast.extract('a.py', data, module='a',
                                  expected_sha256=hashlib.sha256(data).hexdigest())

    def test_lexical_import_alias_and_nested_call(self):
        facts = self.extract('from x import run as launch\ndef f():\n def finish(): pass\n launch(cap=8)\n finish()\n')
        calls = {(row[1], row[3], row[4]) for row in facts['ast_call']}
        self.assertEqual(calls, {('a.f', 'x.run', 'lexical'), ('a.f', 'a.f.finish', 'lexical')})
        self.assertEqual(facts['ast_keyword'][0][1:], ['cap', 'Constant(value=8)'])

    def test_rebinding_parameters_lambda_and_dynamic_dispatch_are_unresolved(self):
        facts = self.extract('from x import run\ndef f(run):\n run()\ndef g():\n run = other\n run()\ndef h(ctx):\n ctx.run()\n (lambda run: run())(other)\n')
        self.assertTrue(all(row[4] == 'unresolved' for row in facts['ast_call']))

    def test_comments_strings_and_dead_nested_bodies_do_not_belong_to_parent(self):
        facts = self.extract('def f():\n # launch()\n text="launch()"\n def g():\n  unknown()\n')
        self.assertEqual(len(facts['ast_call']), 1)
        self.assertEqual(facts['ast_call'][0][1], 'a.f.g')

    def test_exception_pattern_star_import_and_duplicate_bindings_refuse_resolution(self):
        cases = ['from x import run\ndef f():\n try: pass\n except Exception as run: run()\n',
                 'from x import run\ndef f(x):\n match x:\n  case run: run()\n',
                 'from x import run\nfrom y import *\nrun()\n',
                 'from x import run\nfrom y import run\nrun()\n']
        for text in cases:
            with self.subTest(source=text):
                self.assertTrue(all(row[4] == 'unresolved' for row in self.extract(text)['ast_call']))

    def test_identical_absolute_imports_resolve_without_executing_them(self):
        facts=self.extract('def f():\n from x import run\n if condition:\n  from x import run\n run()\n')
        self.assertEqual(facts['ast_call'][0][3:5],['x.run','lexical'])
        blocked=self.extract('def f():\n from x import run\n run=other\n from x import run\n run()\n')
        self.assertEqual(blocked['ast_call'][0][4],'unresolved')

    def test_method_lexical_scope_excludes_class_attributes(self):
        facts = self.extract('from x import run as invoke\nclass C:\n invoke = other\n invoke()\n def f(self, value=invoke()):\n  invoke()\n  from y import capture\n  capture()\n  self.g()\n')
        calls = [(row[3], row[4]) for row in facts['ast_call']]
        self.assertEqual(calls, [('invoke', 'unresolved'), ('invoke', 'unresolved'),
                                ('x.run', 'lexical'), ('y.capture', 'lexical'),
                                ('self.g', 'unresolved')])

    def test_source_read_role_is_explicit_and_does_not_admit_scripts(self):
        from gambit_smp.contract_capabilities import validate_check
        from gambit_smp.research_kernel import validate_graph
        path = 'src/gambit_smp/workspace.py'
        args = dict(projection=dict(step='model',output='projection'),readSources=[path])
        validate_check(args,[path])
        for names in (['runner.py'], ['src/gambit_smp/runner.sh'], [path, path], []):
            with self.subTest(names=names), self.assertRaises(ValueError):
                validate_check(dict(args,readSources=names),[path])
        with self.assertRaisesRegex(ValueError,'executable scripts'):
            validate_graph(dict(inputs=[path]),[])

    def test_digest_and_invalid_python_refuse(self):
        with self.assertRaisesRegex(ValueError, 'digest mismatch'):
            source_ast.extract('a.py', b'pass', module='a', expected_sha256='0' * 64)
        with self.assertRaises(SyntaxError):
            self.extract('def broken(')

    def test_product_receipt_requires_terminal_matching_custody(self):
        receipt = dict(schema='recipe-process-observation.v1', state='OBSERVED',
            stage='gerbil-stage0', completionObserved=True, exit=0, timeout=False,
            parentReaped=True, processGroupQuiescent=True)
        raw = json.dumps(receipt)
        ledger = dict(schema='gerbil-ci-stage-products', inputsSha256='input',
            completed={'stage0': receipt}, products={'stage0': dict(command=receipt,
                inputsSha256='input', outputs={'test': 'hash'}, receiptBytes=raw,
                receiptSha256=hashlib.sha256(raw.encode()).hexdigest())})
        self.assertEqual(source_ast.recorded_products(json.dumps(ledger))[0][0], 'stage0')
        for field, value in [('parentReaped', False), ('processGroupQuiescent', False),
                             ('completionObserved', False), ('timeout', True), ('exit', -9)]:
            broken = copy.deepcopy(ledger)
            payload = {**receipt, field: value}
            text = json.dumps(payload)
            broken['completed']['stage0'] = payload
            broken['products']['stage0'].update(command=payload, receiptBytes=text,
                receiptSha256=hashlib.sha256(text.encode()).hexdigest())
            with self.assertRaises(ValueError):
                source_ast.recorded_products(json.dumps(broken))
        for key in ('receiptSha256', 'inputsSha256', 'command'):
            broken = copy.deepcopy(ledger)
            broken['products']['stage0'][key] = 'wrong'
            with self.assertRaises(ValueError):
                source_ast.recorded_products(json.dumps(broken))


class DarwinNativeSourceChainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = json.loads((BASE / 'source-chain.contract.json').read_text())
        sources = [(row['path'], (ROOT / row['path']).read_bytes(), row['module'])
                   for row in cls.contract['sources']]
        cls.facts = source_ast.project(sources, set(cls.contract['owners']))
        cls.facts.update({key: cls.contract[key] for key in
            ('required_call', 'component', 'obligation', 'required_receipt')})
        cls.facts.update(dispatch_binding=cls.contract['dispatch_binding'],execution_edge=[])
        cls.facts['source_binding'] = [[p, 'snapshot:' + p, 'checkout:' + p]
                                      for p, _ in cls.facts['ast_source']]
        cls.facts['reference'] = [[prefix + p, p, digest]
            for p, digest in cls.facts['ast_source'] for prefix in ('snapshot:', 'checkout:')]
        cls.facts['observed_receipt'] = []
        cls.catalog = load_evidence_catalog(BASE / 'source-chain.ss',
            constructor='make-darwin-source-chain', trusted=True)
        cls.context = engine_api()
        cls.engine, _ = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def query(self, facts):
        return evaluate(self.engine, facts, self.catalog,
            {name: name for name in ('matched_call', 'missing_call', 'unclosed', 'clue')})[0]

    def test_actual_sources_keep_dynamic_dispatch_and_packages_open(self):
        answers = self.query(self.facts)
        self.assertEqual(set(answers['missing_call']), {('phase-dispatch',), ('package-reference',)})
        self.assertEqual({row[0] for row in answers['matched_call']},
                         {row[0] for row in self.contract['required_call']} -
                         {'phase-dispatch', 'package-reference'})
        self.assertIn(('package-entry', 'mcp-original-test'), answers['unclosed'])
        self.assertIn(('package-entry', 'poo-original-test'), answers['unclosed'])
        self.assertTrue(all(row[4] == 'observation' for row in answers['clue']))
        self.assertEqual({row[0] for row in answers['clue'] if row[3]=='counter'},
                         {'phase-dispatch', 'package-reference'})

    def test_removed_callee_and_missing_current_bytes_do_not_pass(self):
        facts = copy.deepcopy(self.facts)
        facts['ast_call'] = [row for row in facts['ast_call']
                             if row[3] != 'gambit_smp.process_identity.footprint_bytes']
        self.assertIn(('charged-footprint',), self.query(facts)['missing_call'])
        facts = copy.deepcopy(self.facts)
        facts['reference'] = [row for row in facts['reference'] if not row[0].startswith('checkout:')]
        self.assertEqual(self.query(facts)['matched_call'], [])

    def test_digest_drift_and_unknown_method_never_resolve(self):
        facts = copy.deepcopy(self.facts)
        facts['reference'] = [[ref, path, '0' * 64] if ref.startswith('checkout:') else [ref, path, sha]
                              for ref, path, sha in facts['reference']]
        self.assertEqual(self.query(facts)['matched_call'], [])
        facts = copy.deepcopy(self.facts)
        for row in facts['ast_call']:
            if row[3] == 'gambit_smp.gerbil_build.bazel_build._ci_stage_products':
                row[4] = 'unresolved'
        self.assertIn(('stage-producer',), self.query(facts)['missing_call'])

    def test_engine_digest_drift_drops_actual_source_correspondence(self):
        facts = copy.deepcopy(self.facts)
        facts.update(run_engine=[['run', 'engine']],
            engine_source=[['engine', p, d] for p, d in facts['ast_source']],
            recorded_product=[['run', 'stage0', 'receipt', 'inputs']])
        queries = dict(used='used_source', recorded='recorded_phase')
        answers, _ = evaluate(self.engine, facts, self.catalog, queries)
        self.assertEqual(len(answers['used']), len(facts['ast_source']))
        self.assertEqual(len(answers['recorded']), 1)
        facts['engine_source'] = [['engine', p, '0' * 64] for p, _ in facts['ast_source']]
        answers, _ = evaluate(self.engine, facts, self.catalog, queries)
        self.assertEqual(answers['used'], [])
        # Source drift denies current correspondence; it does not erase a
        # historical terminal observation or upgrade it to current admission.
        self.assertEqual(len(answers['recorded']),1)

    def test_observed_dispatch_requires_both_actual_engine_source_digests(self):
        facts=copy.deepcopy(self.facts)
        hashes=dict(facts['ast_source'])
        facts.update(run_engine=[['run','engine']],
            engine_source=[['engine',p,d] for p,d in facts['ast_source']],
            execution_edge=[['run','gambit_smp.gerbil_build.bazel_build._ci_stage_products',
                'gambit_smp.recipes.ExecutionContext.run',hashes['src/gambit_smp/gerbil_build/bazel_build.py'],
                hashes['src/gambit_smp/recipes.py'],'gerbil-gambit','receipt']])
        answers,_=evaluate(self.engine,facts,self.catalog,{'observed':'observed_call'})
        self.assertEqual(answers['observed'],[('phase-dispatch','run','gerbil-gambit','receipt')])
        facts['execution_edge'][0][4]='0'*64
        answers,_=evaluate(self.engine,facts,self.catalog,{'observed':'observed_call'})
        self.assertEqual(answers['observed'],[])

    def test_registered_view_facts_are_actual_extraction_and_keep_package_gaps(self):
        from gambit_smp.evidence_views import load, registry
        name='evidence/scenarios/darwin-acceleration/source-chain.view.json'
        self.assertIn(name,registry(ROOT)[0])
        doc,facts,catalog,_=load(ROOT,name)
        for key in ('ast_source','ast_function','ast_call','ast_keyword'):
            self.assertEqual(facts[key],self.facts[key])
        answers,_=evaluate(self.engine,facts,catalog,doc['queries'])
        # This is source_ast.view's source-only contract, not a journal import.
        # Recorded product and dispatch receipts have independent positive,
        # drift and nonterminal controls above; never invent them in a refresh.
        self.assertNotIn('used_source', doc['queries'])
        self.assertNotIn('recorded_phase', doc['queries'])
        self.assertEqual(facts.get('run_engine', []), [])
        self.assertEqual(facts.get('recorded_product', []), [])
        self.assertEqual(set(answers['unclosed']),
            {tuple(row) for row in self.contract['required_receipt']} |
            {(name, 'missing-or-drifted-syntactic-edge')
             for name in ('phase-dispatch', 'package-reference')})
        self.assertEqual(facts['observed_receipt'],[])

    def test_missing_snapshot_journal_is_unavailable_not_passed(self):
        from unittest.mock import patch
        from gambit_smp import source_identity
        from gambit_smp.evidence_views import load, ReferenceUnavailable
        with patch.object(source_identity,'read_source',side_effect=source_identity.SourceUnavailable('missing journal')):
            with self.assertRaises(ReferenceUnavailable):
                load(ROOT,'evidence/scenarios/darwin-acceleration/source-chain.view.json')

    def test_public_clue_api_exposes_support_and_unresolved_obligations(self):
        from gambit_smp import repository_clues
        result=repository_clues(ROOT,bindings=[('scope','darwin-acceleration')])
        self.assertEqual(result['brief']['counts']['support'],
                         len(self.contract['required_call']) - 2)
        self.assertEqual(result['brief']['counts']['counter'],2)


if __name__ == '__main__':
    unittest.main()
