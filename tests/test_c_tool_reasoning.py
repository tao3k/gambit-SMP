"""Existing ASCENT Tool Reasoning offers source tools without scheduling them."""
import copy
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest


class CToolReasoningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name).resolve()
        view_rel = 'evidence/scenarios/tool-reasoning/c-contracts.view.json'
        doc = json.loads((ROOT / view_rel).read_text())
        manifest_rel = doc['manifest']
        manifest_dst = root / manifest_rel
        manifest_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / manifest_rel, manifest_dst)
        manifest_data = json.loads(manifest_dst.read_text())
        for comp in manifest_data.get('components', []):
            src_rel = comp['source']
            if not src_rel.startswith('package:'):
                comp_src = (ROOT / manifest_rel).parent / src_rel
                comp_dst = manifest_dst.parent / src_rel
                comp_dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(comp_src, comp_dst)
        for ref in doc['references']:
            dst = root / ref['path']
            dst.parent.mkdir(parents=True, exist_ok=True)
            if (ROOT / ref['path']).is_file():
                shutil.copyfile(ROOT / ref['path'], dst)
                ref['sha256'] = digest(dst)
            else:
                dst.write_text(json.dumps({'tool': 'frama-c', 'environment': 'synthetic-opam'}) + '\n')
                ref['sha256'] = digest(dst)
        view_dst = root / view_rel
        view_dst.parent.mkdir(parents=True, exist_ok=True)
        view_dst.write_text(json.dumps(doc))
        cls.document, cls.facts, cls.catalog, _ = load(root, view_rel)
        cls.context=engine_api()
        cls.engine,_=cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None,None,None)
        cls.tmp.cleanup()

    def infer(self, **changes):
        return evaluate(self.engine,{**copy.deepcopy(self.facts),**changes},
                        self.catalog,self.document['queries'])[0]

    def test_actual_tools_are_options_with_distinct_missing_premises(self):
        answers=self.infer()
        self.assertEqual({row[2] for row in answers['options']},
                         {'cbmc','frama-c-wp','owned-verifier-sampler'})
        self.assertEqual(answers['ready'],[])
        self.assertIn(('c-section-contracts','source-memory-geometry','frama-c-wp','acsl-contracts'),
                      answers['missing'])
        self.assertIn(('c-section-contracts','machine-arithmetic','cbmc','unwind-completeness'),
                      answers['missing'])
        self.assertIn('frama-c-wp',{row[1] for row in answers['environment_options']})

    def test_missing_policy_withdraws_choices_and_unknown_methods_remain_open(self):
        self.assertEqual(self.infer(source=[r for r in self.facts['source'] if r[0]!='policy'])['options'],[])
        answers=self.infer(tool=[],offers=[],support=[])
        self.assertEqual(answers['options'],[])
        self.assertEqual(len(answers['exploration_window']),5)

    def test_declared_readiness_does_not_change_available_choices(self):
        before=self.infer()
        premises=[['c-section-contracts',p,'source'] for t,p in self.facts['requirement'] if t=='cbmc']
        after=self.infer(available=premises)
        self.assertEqual(after['options'],before['options'])
        self.assertIn(('c-section-contracts','machine-arithmetic','cbmc'),after['ready'])

    def test_options_export_native_clue_witnesses_without_becoming_execution_claims(self):
        answers=self.infer()
        clues=answers['clue']
        self.assertEqual(len(clues),len(answers['options']))
        self.assertTrue(all(row[4]=='hypothesis' for row in clues))
        identity=next(row[0] for row in clues if row[0].endswith(':source-memory-geometry:frama-c-wp'))
        self.assertTrue(any(row[0]==identity and row[2:]==('tool','frama-c-wp') for row in answers['factor']))
        names={row[2] for row in answers['factor'] if row[0]==identity}
        self.assertTrue({'purpose','boundary','rationale','missing-premise'} <= names)
        self.assertTrue(any(row[0]==identity and row[2]=='environment-route' for row in answers['link']))


if __name__=='__main__':unittest.main()
