"""Exploration results, runtime closure and source-bound GenMC contracts."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.genmc_capabilities import report, runtime_inventory, validate
from gambit_smp.recipes import load
from gambit_smp.research_kernel import validate_graph

ROOT = Path(__file__).resolve().parents[1]
GOOD = '*** Verification complete.\nNo errors were detected.\nNumber of complete executions explored: 2\n'


class GenmcTests(unittest.TestCase):
    def test_complete_nonempty_exploration_required(self):
        self.assertEqual(report(GOOD, 0, False, {'mode':'verify'}, ['x'], '')['verdict'], 'VERIFIED')
        for text, code, timeout in [(GOOD, 1, False), (GOOD, 0, True),
                (GOOD.replace(': 2', ': 0'), 0, False), ('', 0, False), (GOOD+GOOD, 0, False)]:
            self.assertEqual(report(text, code, timeout, {'mode':'verify'}, ['x'], '')['verdict'], 'INCONCLUSIVE')

    def test_bounds_and_random_do_not_become_exhaustive(self):
        for change in ({'bound':1, 'boundType':'context'}, {'unroll':2}):
            result=report(GOOD, 0, False, {'mode':'verify', **change}, ['x'], '')
            self.assertEqual(result['verdict'], 'BOUNDED')
            self.assertFalse(result['exhaustive'])
            self.assertEqual(result['properties'][0]['status'], 'UNKNOWN')
        text=GOOD.replace('Verification', 'Random exploration')
        self.assertEqual(report(text, 0, False, {'mode':'random', 'randomBudget':2}, ['x'], '')['verdict'], 'SAMPLED')

    def test_first_failure_requires_trace_and_matching_assertion(self):
        text='Assertion violation: x\n*** Verification unsuccesful.\nNumber of complete executions explored: 0\n'
        actual=report(text,42,False,{'mode':'verify'},['x','other'],'digraph {}')
        self.assertEqual(actual['verdict'], 'COUNTEREXAMPLE')
        self.assertEqual([p['status'] for p in actual['properties']], ['FAILURE','UNKNOWN'])
        for assertions, graph in [(['different'],'digraph {}'), (['x'],'')]:
            self.assertEqual(report(text,42,False,{'mode':'verify'},assertions,graph)['verdict'],'INCONCLUSIVE')

    def test_unsupported_or_truncated_output_is_not_success(self):
        self.assertEqual(report('Warning: unsupported operation\n'+GOOD,0,False,{'mode':'verify'},['x'],'')['verdict'], 'INCONCLUSIVE')
        self.assertEqual(report(GOOD.replace('No errors were detected.',''),0,False,{'mode':'verify'},['x'],'')['verdict'], 'INCONCLUSIVE')

    def test_first_builtin_race_is_not_a_later_assertion_after_undefined_behavior(self):
        text='Error: Non-atomic race!\n*** Verification unsuccesful.\nNumber of complete executions explored: 0\n'
        result=report(text,42,False,{'mode':'verify'},[],'digraph {}')
        self.assertEqual(result['verdict'],'COUNTEREXAMPLE')
        self.assertEqual(result['properties'][0]['property'],'genmc.safety')
        self.assertEqual(report(text,42,False,{'mode':'verify'},[],'')['verdict'],'INCONCLUSIVE')

    def test_empty_assertions_keep_builtin_safety_scope(self):
        result=report(GOOD,0,False,{'mode':'verify'},[],'')
        self.assertEqual(result['verdict'],'VERIFIED')
        self.assertEqual(result['properties'][0]['description'],'GenMC builtin race/memory safety')

    def test_recipe_uses_existing_c_contract_and_terminal_evidence(self):
        recipe, steps=load(ROOT,ROOT/'tests/contracts/concurrency/copy-gate/two-carriers/check.recipe.json')
        validate_graph(recipe,steps)
        for step in steps[:-1]:validate(step['arguments'],recipe['inputs'])
        args=copy.deepcopy(steps[0]['arguments'])
        for change in ({'memoryModel':'guess'}, {'defines':['NDEBUG']},
                       {'exploration':{'mode':'verify','bound':2}}, {'exploration':{'mode':'random'}}):
            with self.assertRaises(ValueError):validate({**args,**change},recipe['inputs'])

    def test_runtime_membership_and_bytes_are_independently_bound(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for name in ('genmc','clang'):
                (root/name).write_text('provider');(root/name).chmod(0o755)
            for name in ('model','builtin'):
                (root/name).mkdir();(root/name/'header.h').write_text('int x;')
            (root/'library').write_text('llvm')
            declared=dict(schema='genmc-runtime.v1',binaries={n:str(root/n) for n in ('genmc','clang')},
                directories={'genmc-headers':str(root/'model'),'clang-headers':str(root/'builtin')},libraries=[str(root/'library')])
            _, before=runtime_inventory(declared)
            (root/'model/new.h').write_text('int y;')
            _, after=runtime_inventory(declared)
            self.assertNotEqual(before,after)
            (root/'library').write_text('new llvm')
            self.assertNotEqual(after,runtime_inventory(declared)[1])


if __name__ == '__main__':unittest.main()
