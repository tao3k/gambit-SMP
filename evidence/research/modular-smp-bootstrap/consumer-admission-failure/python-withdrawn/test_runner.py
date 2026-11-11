"""Standalone harness controls; never substitutes for running Scheme on SMP."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('smp_runner', HERE/'run.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class SmpRunnerControls(unittest.TestCase):
    def test_repository_owns_all_fixtures_without_parent_framework(self):
        plan = json.loads((HERE/'plan.json').read_text())
        self.assertEqual(9,len(plan['modules']))
        self.assertEqual(9,len({m['id'] for m in plan['modules']}))
        for case in plan['modules']:
            p = (runner.ROOT/case['program']).resolve(strict=True)
            self.assertTrue(p.is_relative_to(runner.ROOT))
            self.assertLessEqual(case['budget'],180)
        workflow = (runner.ROOT/'.github/workflows/smp.yml').read_text()
        self.assertNotIn('gambit-smp --task', workflow)
        self.assertNotIn('uv run', workflow)
        self.assertNotIn('vendor/gambit', workflow)
        self.assertNotIn('ascent', workflow.lower())
        self.assertNotIn('continue-on-error', workflow)
        self.assertEqual(9,workflow.count('!cancelled()'))

    def test_exit_failure_retains_output_and_exit(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d); records=[]
            with self.assertRaises(RuntimeError):
                runner.execute([sys.executable,'-c',
                                'print("retained failure"); raise SystemExit(7)'],
                               path,dict(os.environ),5,path,'failure',records)
            self.assertEqual(7,records[0]['exit'])
            self.assertEqual('retained failure\n',(path/'failure.stdout').read_text())
            self.assertTrue(records[0]['parentReaped'])
            self.assertTrue(records[0]['processGroupQuiescent'])

    def test_timeout_is_not_a_pass(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d); records=[]
            with self.assertRaises(RuntimeError):
                runner.execute([sys.executable,'-c','import time; time.sleep(30)'],
                               path,dict(os.environ),0.1,path,'timeout',records)
            self.assertTrue(records[0]['timeout'])
            self.assertNotEqual(0,records[0]['exit'])
            self.assertTrue(records[0]['parentReaped'])

    def test_unqualified_runtime_has_failure_receipt(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d); args=SimpleNamespace(module='root-protocol',runtime=path,
                                              out=path/'result',cc=sys.executable)
            self.assertFalse(runner.run(args))
            r=json.loads((args.out/'receipt.json').read_text())
            self.assertEqual('FAIL',r['outcome'])
            self.assertFalse(r['wholeSmpAdmitted'])
            self.assertFalse(r['commitAdmitted'])
            self.assertEqual([],r['commands'])

    def test_multicore_profile_retains_all_concurrency_modes(self):
        flags=json.loads((HERE/'plan.json').read_text())['configure']
        self.assertTrue({'--enable-smp','--enable-multiple-vms',
                         '--enable-multiple-threaded-vms'} <= set(flags))
        self.assertIn('--enable-c-opt=-O1',flags)
        self.assertIn('--enable-c-opt-rts=yes',flags)


if __name__ == '__main__':
    unittest.main()
