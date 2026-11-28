"""WP proof and smoke semantics; real C runs are retained separately."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.frama_c_capabilities import report as wp_report, runtime_inventory
from gambit_smp.recipes import load
from gambit_smp.research_kernel import validate_graph

ROOT=Path(__file__).resolve().parents[1]


def report(raw, code, timeout):
    return wp_report(raw,code,timeout,'[wp] '+str(len(json.loads(raw)))+' goals scheduled\n')


def goal(name='ensures_bound', verdict='valid', smoke=False):
    return dict(goal=name, property=name, file='actual.c', line=7,
                verdict=verdict, smoke=smoke,
                passed=verdict!='valid' if smoke else verdict=='valid', provers=[])


class FramaCContractTests(unittest.TestCase):
    def test_valid_normal_goals_and_unproved_smoke_do_not_prove_premise_consistency(self):
        d=report(json.dumps([goal(),goal('smoke','unknown',True)]),0,False)
        self.assertEqual(d['verdict'],'VERIFIED')
        self.assertFalse(d['premiseConsistencyProved'])
        self.assertEqual(d['properties'][1]['status'],'SMOKE_UNPROVED')

    def test_smoke_valid_reverses_the_apparent_success(self):
        d=report(json.dumps([goal(),goal('smoke','valid',True)]),0,False)
        self.assertEqual(d['verdict'],'INCONCLUSIVE')
        self.assertEqual(d['contextWarnings'],['smoke'])

    def test_failed_smoke_prover_does_not_qualify_the_campaign(self):
        d=report(json.dumps([goal(),goal('smoke','failed',True)]),0,False)
        self.assertEqual(d['verdict'],'INCONCLUSIVE')
        self.assertEqual(d['toolFailedGoals'],['smoke'])

    def test_failed_goal_is_not_a_source_counterexample(self):
        for status in ('failed','unknown','timeout','stepout','none'):
            with self.subTest(status=status):
                d=report(json.dumps([goal(verdict=status),goal('smoke','unknown',True)]),0,False)
                self.assertEqual(d['verdict'],'INCONCLUSIVE')
                self.assertEqual(d['properties'][0]['status'],'UNKNOWN')

    def test_exit_zero_empty_duplicate_timeout_and_missing_smoke_never_pass(self):
        for rows,code,timeout in [([],0,False),([goal(),goal()],0,False),
                ([goal()],0,False),([goal(),goal('smoke','unknown',True)],2,False),
                ([goal(),goal('smoke','unknown',True)],0,True)]:
            with self.subTest(rows=rows,code=code,timeout=timeout):
                self.assertEqual(report(json.dumps(rows),code,timeout)['verdict'],'INCONCLUSIVE')
        bad=goal();bad['passed']=False
        self.assertEqual(report(json.dumps([bad]),0,False)['properties'],[])

    def test_missing_scheduled_goal_cannot_pass_a_truncated_valid_report(self):
        raw=json.dumps([goal(),goal('smoke','unknown',True)])
        for stdout in ('','[wp] 3 goals scheduled\n'):
            d=wp_report(raw,0,False,stdout)
            self.assertEqual(d['verdict'],'INCONCLUSIVE')
            self.assertFalse(d['goalInventoryComplete'])

    def test_runtime_tracks_membership_bytes_and_rejects_escape(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);binary=root/'tool';binary.write_text('provider');binary.chmod(0o700)
            config=root/'why3.conf';config.write_text('[main]\nmagic = 14\n')
            data=root/'data';data.mkdir();(data/'driver').write_text('driver')
            d=dict(schema='frama-c-wp-runtime.v1',binaries={n:str(binary) for n in ('frama-c','why3','alt-ergo')},
                directories={n:str(data) for n in ('frama-c-lib','frama-c-share','why3-lib','why3-share')},
                why3Config=str(config))
            _,before=runtime_inventory(d)
            (data/'new').write_text('new package file')
            _,after=runtime_inventory(d);self.assertNotEqual(before,after)
            config.write_text('[prover]\ncommand = "/unbound/prover %f"\n')
            with self.assertRaisesRegex(ValueError,'explicitly bound'):runtime_inventory(d)
            config.write_text('[main]\nmagic = 14\n')
            (data/'outside').symlink_to(config)
            with self.assertRaisesRegex(ValueError,'escapes'):runtime_inventory(d)

    def test_real_source_recipes_keep_actual_predicate_and_explicit_controls(self):
        recipe,steps=load(ROOT,ROOT/'evidence/fixtures/dev-cbmc-copy-plan/wp-check.recipe.json')
        validate_graph(recipe,steps)
        self.assertEqual({s['capability'] for s in steps},{'c.frama-c','evidence.evaluate'})
        for step in steps[:-1]:
            a=step['arguments'];h=(ROOT/a['harness']).read_text()
            self.assertIn('#include "fits.inc"',h)
            self.assertNotIn('return ',h)
            self.assertEqual(a['machdep'],'macos_arm')
            branch,ss=load(ROOT,(ROOT/a['harness']).with_name('check.recipe.json'))
            self.assertEqual(ss[0],step)
            validate_graph(branch,ss)


if __name__=='__main__':unittest.main()
