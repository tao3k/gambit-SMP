"""Publication admission checks the index, not just ignore-file convenience."""
from pathlib import Path
import hashlib
from gambit_smp.task_processes import run
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.research_publication import POLICY, _rules, audit_index, classify
from gambit_smp.storage_policy import StoragePolicyError, validate


class ResearchPublicationTests(unittest.TestCase):
    def test_empty_index_has_no_candidates(self):
        with TemporaryDirectory() as directory:
            run(['git', 'init', '-q', directory], check=True)
            self.assertEqual(dict(gitCandidatesChecked=0, violations=[]), audit_index(directory))

    def test_native_authority_hash_matches_compiled_view(self):
        root = Path(__file__).resolve().parents[1]
        model = root/'dev/modeling/models/sysml/research-storage.sysml'
        self.assertEqual(hashlib.sha256(model.read_bytes()).hexdigest(), _rules.POLICY_SHA256)

    def test_force_added_cache_is_rejected_by_actual_index(self):
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            run(['git', 'init', '-q', directory], check=True)
            (root/'.gitignore').write_text('.cache/\n')
            bad = root/'.cache/tasks/example/runs/one/proof.command.json'
            bad.parent.mkdir(parents=True)
            bad.write_text('{"exit":0}')
            run(['git', 'add', '.gitignore'], cwd=root, check=True)
            run(['git', 'add', '-f', str(bad)], cwd=root, check=True)
            report = audit_index(root)
            self.assertEqual(2, report['gitCandidatesChecked'])
            self.assertEqual(['.cache/tasks/example/runs/one/proof.command.json'],
                             [v['path'] for v in report['violations']])

    def test_unknown_or_renamed_run_assets_do_not_gain_a_role(self):
        for name in ['docs/new.json', 'evidence/research/topic/summary.json',
                     'dev/new.command.json', 'dev/input-cut/model.lean',
                     'evidence/research/published/model-ir.json',
                     'evidence/research/source-references/run.status.json',
                     '../dev/model.qnt']:
            with self.subTest(name=name):
                self.assertEqual('deny', classify(name)['disposition'])
        self.assertEqual('deny', classify('dev/alias.org', mode='120000')['disposition'])

    def test_evidence_writer_rejects_output_but_allows_curated_primary_text(self):
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            for name in ['evidence/research/topic/summary.json',
                         'evidence/research/published/run.command.json',
                         'evidence/dsl/input-cut/alias.ss']:
                with self.subTest(name=name), self.assertRaises(StoragePolicyError):
                    validate(root, root/name)
                validate(root, root/name, deleting=True)
            validate(root, root/'evidence/research/source-references/paper.txt')
            validate(root, root/'.cache/tasks/topic/runs/one/run.command.json')

    def test_metadata_bound_and_fixed_fixture_exception_are_exact(self):
        name = 'evidence/research/retained/topic/receipt.json'
        self.assertEqual('allow', classify(name, POLICY['maxMetadataBytes'])['disposition'])
        self.assertEqual('deny', classify(name, POLICY['maxMetadataBytes']+1)['disposition'])
        self.assertEqual('deny', classify('evidence/review/renamed-summary.json', POLICY['maxMetadataBytes']+1)['disposition'])
        fixtures = POLICY['preservedFixtureFiles'].split(';')
        self.assertTrue(fixtures)
        self.assertEqual('allow', classify(fixtures[0])['disposition'])
        self.assertEqual('deny', classify('tests/fixtures/new-run.log')['disposition'])


if __name__ == '__main__':
    unittest.main()


class ArchitectureViewRelocationTests(unittest.TestCase):
    def test_completed_source_amendment_is_preserved_without_a_mutator(self):
        import json
        from gambit_smp.framework import ROOT
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/darwin-target-amendment.json').read_text())
        self.assertFalse((ROOT/fixture['retired']).exists())
        text=(ROOT/fixture['target']).read_text()
        for change in fixture['changes']:
            self.assertNotIn(change['before'],text)
            self.assertEqual(change['occurrences'],text.count(change['after']))

    def test_owned_renderer_matches_independent_source_ast_identities(self):
        import ast,copy,json
        from gambit_smp.framework import ROOT
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/architecture-view-relocation.json').read_text())
        tree=ast.parse((ROOT/'src/gambit_smp/architecture_views.py').read_text())
        cls=next(n for n in tree.body if isinstance(n,ast.ClassDef))
        names=set(fixture['astIdentities'])-{'deriveBody'}
        mapping={'root':'ROOT','output':'TASK','model':'MODEL','relations':'RELATIONS'}
        class Inverse(ast.NodeTransformer):
            def visit_Attribute(self,node):
                if isinstance(node.value,ast.Name) and node.value.id=='self':
                    if node.attr in mapping:return ast.copy_location(ast.Name(mapping[node.attr],node.ctx),node)
                    if node.attr in names|{'derive'}:return ast.copy_location(ast.Name(node.attr,node.ctx),node)
                return self.generic_visit(node)
        for method in cls.body:
            if not isinstance(method,ast.FunctionDef) or method.name=='__init__':continue
            node=Inverse().visit(copy.deepcopy(method));node.args.args=node.args.args[1:]
            if node.name=='derive':
                payload=ast.Module(body=node.body[:-1],type_ignores=[]);key='deriveBody'
            else:payload=node;key=node.name
            digest=hashlib.sha256(ast.dump(payload,include_attributes=False).encode()).hexdigest()
            self.assertEqual(fixture['astIdentities'][key],digest,key)

    def test_independent_renderer_controls_and_instance_isolation(self):
        import json
        from gambit_smp.framework import ROOT
        from gambit_smp.architecture_views import ArchitectureViews
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/architecture-view-relocation.json').read_text())
        with TemporaryDirectory() as name:
            a=ArchitectureViews(ROOT,Path(name)/'a');b=ArchitectureViews(ROOT,Path(name)/'b')
            self.assertNotEqual(a.output,b.output)
            for case in fixture['controls']:
                function=getattr(a,case['function'])
                try:value=function(*case['args']);value='ok' if value is None else value
                except ValueError:value='ValueError'
                self.assertEqual(case['expected'],value,case)
