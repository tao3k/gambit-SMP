"""A live Grok/Codex parent is not proof that its dead build child drained."""
import json
import os
from pathlib import Path
import selectors
import shutil
import signal
import subprocess
import sys
import time
import unittest
from unittest.mock import patch

from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease, workspace_custody
from gambit_smp.recipes import tree_identity
from gambit_smp.task_processes import spawn, observe_group
from tests import test_workspace as fixtures


class WorkspaceChildCustodyTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    if sys.platform == 'darwin':
        def test_footprint_admission_does_not_kill_for_rss_only(self):
            w.start(self.root,'darwin-test',adopt=True)
            sample=dict(rssBytes=1<<40,footprintBytes=16*1024*1024,pgids=[],members=[])
            with patch('gambit_smp.task_processes.memory_sample',return_value=sample) as observer:
                self.assertEqual(0,w.execute(self.root,'darwin-test',
                    [sys.executable,'-c','import time;time.sleep(.1)'],wall_seconds=3,
                    footprint_limit_bytes=64*1024*1024))
            self.assertTrue(observer.call_args.kwargs['footprint'])
            owner=json.loads(w.paths(self.root,'darwin-test')[0].read_text())
            receipt=json.loads((self.root/'.state/task-runs/darwin-test'/(owner['run']+'.json')).read_text())
            self.assertFalse(receipt['rssAdmissionEnabled'])
            self.assertEqual('sum-darwin-phys-footprint',receipt['resourceMetric'])
            self.assertEqual(1<<40,receipt['peakRegisteredRssBytes'])
            self.assertFalse(receipt.get('rssLimitExceeded',False))

        def test_footprint_budget_drains_nested_sessions(self):
            w.start(self.root,'darwin-test',adopt=True)
            child='import time; data=bytearray(32*1024*1024); time.sleep(10)'
            code=('import sys,time;from gambit_smp.task_processes import spawn;'
                  'data=bytearray(32*1024*1024);'
                  'spawn([sys.executable,"-c",'+repr(child)+']);time.sleep(10)')
            with self.assertRaisesRegex(MemoryError,'charged footprint'):
                w.execute(self.root,'darwin-test',[sys.executable,'-c',code],wall_seconds=5,
                          footprint_limit_bytes=64*1024*1024)
            owner=json.loads(w.paths(self.root,'darwin-test')[0].read_text())
            receipt=json.loads((self.root/'.state/task-runs/darwin-test'/(owner['run']+'.json')).read_text())
            self.assertTrue(receipt['footprintLimitExceeded'])
            self.assertFalse(receipt['rssAdmissionEnabled'])
            self.assertGreaterEqual(len(receipt['resourceSample']['pgids']),2)
            self.assertFalse(receipt['registeredGroupCleanup']['unresolved'])

    def test_supervisor_timeout_drains_registered_nested_sessions(self):
        w.start(self.root,'darwin-test',adopt=True)
        code=('import sys,time;from gambit_smp.task_processes import spawn;'
              'child=spawn([sys.executable,"-c","import time;time.sleep(20)"]);'
              'child.wait()')
        with self.assertRaises(subprocess.TimeoutExpired):
            w.execute(self.root,'darwin-test',[sys.executable,'-c',code],wall_seconds=2)
        owner=json.loads(w.paths(self.root,'darwin-test')[0].read_text())
        run=owner['run']
        records=[json.loads(path.read_text()) for path in
                 (self.root/'.state/task-processes/darwin-test'/run).glob('*.json')]
        groups={row['pgid'] for row in records if row.get('pgid')}
        self.assertGreaterEqual(len(groups),2)
        until=time.monotonic()+2
        while any(observe_group(group)['result']!='absent' for group in groups) and time.monotonic()<until:
            time.sleep(.025)
        self.assertTrue(all(observe_group(group)['result']=='absent' for group in groups))
        receipt=json.loads((self.root/'.state/task-runs/darwin-test'/(run+'.json')).read_text())
        self.assertFalse(receipt['registeredGroupCleanup']['unresolved'])

    def test_returned_driver_cannot_admit_a_detached_native_session(self):
        w.start(self.root,'darwin-test',adopt=True)
        code=('import sys;from gambit_smp.task_processes import spawn;'
              'spawn([sys.executable,"-c","import time;time.sleep(20)"])')
        self.assertEqual(125,w.execute(self.root,'darwin-test',
                                      [sys.executable,'-c',code],wall_seconds=3))

    def test_nested_sessions_share_one_resource_budget(self):
        w.start(self.root,'darwin-test',adopt=True)
        child='import time; data=bytearray(24*1024*1024); time.sleep(10)'
        code=('import sys,time;from gambit_smp.task_processes import spawn;'
              'data=bytearray(24*1024*1024);'
              'spawn([sys.executable,"-c",'+repr(child)+']);time.sleep(10)')
        with self.assertRaisesRegex(MemoryError,'registered process-group RSS'):
            w.execute(self.root,'darwin-test',[sys.executable,'-c',code],wall_seconds=5,
                      rss_limit_bytes=64*1024*1024)
        owner=json.loads(w.paths(self.root,'darwin-test')[0].read_text())
        receipt=json.loads((self.root/'.state/task-runs/darwin-test'/(owner['run']+'.json')).read_text())
        self.assertTrue(receipt['rssLimitExceeded'])
        self.assertGreater(receipt['peakRegisteredRssBytes'],64*1024*1024)
        self.assertGreaterEqual(len(receipt['resourceSample']['pgids']),2)
        self.assertFalse(receipt['rssObservationIsHardCap'])
        self.assertFalse(receipt['registeredGroupCleanup']['unresolved'])

    def test_fresh_descriptor_for_another_owners_lock_is_not_inherited_custody(self):
        source = self.root / '.data/fixtures/source';source.mkdir(parents=True)
        with workspace_lease(self.root, source, tree_identity(source)):
            with workspace_custody() as (_, env):
                record = json.loads(env['GAMBIT_SMP_WORKSPACE_LEASES'])[0]
            fd = os.open(record['lock'], os.O_RDWR)
            try:
                record['fd'] = fd
                with patch.dict(os.environ, {'GAMBIT_SMP_WORKSPACE_LEASES':json.dumps([record])}):
                    with self.assertRaisesRegex(ValueError, 'not the lease owner'):
                        with workspace_custody():pass
            finally:os.close(fd)

    def test_last_compiler_consumer_keeps_lease_after_controller_dies_in_same_parent_run(self):
        w.start(self.root, 'repair', adopt=True)
        cc, make = shutil.which('cc'), shutil.which('make')
        source = self.root / 'src';source.mkdir()
        (source / 'a.c').write_text('int a(void){return 1;}\n')
        (source / 'b.c').write_text('int b(void){return 2;}\n')
        wait = "import pathlib,time;pathlib.Path('waiting').write_text('ready');time.sleep(30)"
        (source / 'Makefile').write_text('all: a.o b.o\na.o: a.c\n\t$(CC) -c $< -o $@\n'
            'b.o: b.c\n\t' + sys.executable + ' -c ' + repr(wait) + '\n\t$(CC) -c $< -o $@\n')
        code = '''import sys
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
from gambit_smp.framework import execute
from gambit_smp.process_observation import capture
from gambit_smp.task_processes import spawn
root=Path(sys.argv[1]);target=Path(sys.argv[2]);make=sys.argv[3];mode=sys.argv[4]
with workspace_lease(root,target,tree_identity(target)):
 print('LEASED',flush=True)
 argv=[make,'-j1','CC='+sys.argv[5]]
 if mode=='framework':execute(argv,target,30)
 elif mode=='capture':capture(argv,target,30,dict(__import__('os').environ))
 else:
  helper="import sys;from gambit_smp.task_processes import spawn;spawn([sys.argv[1],'-j1','CC='+sys.argv[3]],cwd=sys.argv[2]).wait()"
  spawn([sys.executable,'-c',helper,make,str(target),sys.argv[5]],cwd=root).wait()
'''
        with w.execution_scope(self.root, 'repair', provider='grok'):
            run = os.environ['GAMBIT_SMP_TASK_RUN']
            for mode in ('framework', 'capture', 'python-helper'):
                with self.subTest(transport=mode):
                    build = w.build_output(self.root, mode, compiler=cc)
                    target = build / 'source';target.mkdir()
                    with workspace_lease(self.root, target, tree_identity(target)):
                        w.sync_build_source(self.root, build, source)
                    child = spawn([sys.executable, '-c', code, str(self.root), str(target), make, mode, cc],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    groups = []
                    try:
                        with selectors.DefaultSelector() as selector:
                            selector.register(child.stdout, selectors.EVENT_READ)
                            self.assertTrue(selector.select(timeout=20))
                        self.assertEqual('LEASED', child.stdout.readline().strip())
                        until = time.monotonic()+15
                        while not (target/'waiting').exists() and time.monotonic()<until:
                            self.assertIsNone(child.poll());time.sleep(.025)
                        self.assertTrue((target/'waiting').exists())
                        self.assertTrue((target/'a.o').is_file());self.assertFalse((target/'b.o').exists())
                        stamp = (target/'a.o').stat().st_mtime_ns
                        records = [json.loads(path.read_text()) for path in
                            (self.root/'.state/task-processes/repair'/run).glob('*.json')]
                        owned = [row for row in records if str(target) in row.get('workspaces',[]) and row['event']=='started']
                        compiler = next(row['pgid'] for row in owned if row['cwd']==str(target))
                        groups = [row['pgid'] for row in owned]
                        child.kill();child.wait(timeout=5)
                        # Kill only the forwarding helper, leaving make and its
                        # actual child alive. The parent task/run stays alive.
                        for pgid in groups:
                            if pgid != compiler:
                                os.killpg(pgid,signal.SIGTERM)
                        self.assertEqual(run,os.environ['GAMBIT_SMP_TASK_RUN'])
                        with self.assertRaisesRegex(ValueError,'already leased'):
                            with workspace_lease(self.root,target,tree_identity(target)):pass
                        os.killpg(compiler,signal.SIGTERM)
                        until=time.monotonic()+15
                        while any(observe_group(g)['result']!='absent' for g in groups) and time.monotonic()<until:
                            time.sleep(.025)
                        self.assertTrue(all(observe_group(g)['result']=='absent' for g in groups))
                        groups=[]
                        with workspace_lease(self.root,target,tree_identity(target)):
                            (source/'Makefile').write_text((source/'Makefile').read_text().replace(
                                sys.executable+' -c '+repr(wait),'true'))
                            w.sync_build_source(self.root,build,source)
                            from gambit_smp.framework import execute
                            result=execute([make,'-j1','CC='+cc],target,10)
                            self.assertEqual(0,result[0]);self.assertTrue((target/'b.o').is_file())
                            self.assertEqual(stamp,(target/'a.o').stat().st_mtime_ns)
                    finally:
                        if child.poll() is None:child.kill();child.wait()
                        for pgid in groups:
                            try:os.killpg(pgid,signal.SIGKILL)
                            except ProcessLookupError:pass
                        child.stdout.close();child.stderr.close()
                    # Restore the explicit wait for the next independent transport.
                    (source/'Makefile').write_text((source/'Makefile').read_text().replace('\n\ttrue\n',
                        '\n\t'+sys.executable+' -c '+repr(wait)+'\n'))
