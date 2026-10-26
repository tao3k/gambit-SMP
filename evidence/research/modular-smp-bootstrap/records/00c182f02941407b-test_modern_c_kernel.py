"""Actual configured modern-C headers; local C contracts, not VM acceptance."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest

from gambit_smp import native_capabilities as native, workspace as w
from gambit_smp.recipes import ExecutionContext, WorkspaceValidationScope, tree_identity
from tests import test_workspace as fixtures
from tests.test_incremental_native_adapters import gcc

ROOT = Path(__file__).resolve().parents[1]
LOCK = 'evidence/research/modular-smp-bootstrap/qualified/source.lock.json'
PROFILE = 'evidence/fixtures/gerbil-bazel-build-profile/profile.json'


@unittest.skipUnless(sys.platform == 'darwin', 'the declared Bazel profile is Darwin')
class ModernCKernelTests(unittest.TestCase):
    validation_domain = {'kind': 'sealed-research', 'budgetSeconds': 180,
                         'workers': 1, 'processesPerWorker': 1}
    setUp = fixtures.WorkspaceTests.setUp

    def check_kernel(self, program, expected):
        (self.root / 'vendor').mkdir()
        subprocess.run(['git', 'clone', '--quiet', '--shared', '--no-checkout',
                        str(ROOT / 'vendor/gambit'), str(self.root / 'vendor/gambit')],
                       check=True, capture_output=True)
        lock = json.loads((ROOT / LOCK).read_text())
        for name in (LOCK, lock['patch'], PROFILE):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        compiler = gcc()
        tools, env = native.host_tools(compiler, [{'capability': 'gambit.configure'}],
                                      dict(PATH=os.environ['PATH'], HOME=str(self.root), LANG='C'))
        w.start(self.root, 'modern-c-kernel', adopt=True)
        with w.execution_scope(self.root, 'modern-c-kernel', provider='codex'):
            out = w.task_output(self.root, self.root / '.cache/kernel'); out.mkdir(parents=True)
            names = [LOCK, lock['patch'], PROFILE]
            receipt = dict(recipe='modern-c-configured-kernel', workspacePolicy='in-place',
                           declaredInputs=names, inputs={str(self.root/n): native.digest(self.root/n)
                                                       for n in names}, steps=[])
            plan = [dict(id='source', capability='gambit.materialize', arguments=dict(
                        sourceLock=LOCK, buildWorkspace='gambit-core')),
                    dict(id='configure', capability='gambit.configure', arguments=dict(
                        source={'step': 'source', 'output': 'source'}, buildProfile=PROFILE))]
            contexts = []; scope = WorkspaceValidationScope()
            try:
                for step, executor in zip(plan, (native.materialize, native.configure)):
                    directory = out / step['id']; directory.mkdir()
                    receipt['steps'].append(step)
                    ctx = ExecutionContext(self.root, out, directory, env, time.monotonic()+120,
                                           {}, receipt, tools, workspace_scope=scope)
                    ctx.planned_steps = plan; contexts.append(ctx)
                    step.update(executor(step['arguments'], ctx), outcome='PASS')
                    ctx.leased_tree_checks.verify(); ctx.workspace_leases.close()
                source = Path(receipt['steps'][0]['sourceDelta']['source'])
                binary = out / 'kernel'
                ctx.require('kernel-build', [compiler, '-std=c23', '-O1', '-pthread',
                    '-DHAVE_CONFIG_H', '-I', source/'include', source/'tests'/program,
                    '-o', binary], source, 30)
                log = ctx.require('kernel-run', [binary], out, 10)
                print('MODERN-C-KERNEL', program, log.strip(), flush=True)
                self.assertEqual(0, ctx.commands[-1].get('stderrBytes', 0))
                if expected is not None:
                    self.assertEqual(expected, log)
                else:
                    self.assertRegex(log, r'^RUNTIME-ROLES-STORAGE-PASS word=64 context=[1-9][0-9]* worker=[1-9][0-9]* participant=[1-9][0-9]* carrier=[1-9][0-9]* vm=[1-9][0-9]*\n$')
                self.assertEqual(tree_identity(source), receipt['steps'][1]['outputs']['source']['identity'])
            finally:
                for context in contexts: context.workspace_leases.close()
                scope.close()

    def test_root_publication_claim_and_arena(self):
        self.check_kernel('gc-root-task.c', 'PUBLICATION-PASS\nCLAIM-RACE-PASS\nARENA-PASS\n')

    def test_context_worker_participant_storage(self):
        self.check_kernel('runtime-roles.c', None)
