"""Existing ASCENT Tool Reasoning offers source tools without scheduling them."""
import copy
import unittest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT


class CToolReasoningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document, cls.facts, cls.catalog, _ = load(
            ROOT, 'evidence/scenarios/tool-reasoning/c-contracts.view.json')
        cls.context=engine_api()
        cls.engine,_=cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None,None,None)

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
