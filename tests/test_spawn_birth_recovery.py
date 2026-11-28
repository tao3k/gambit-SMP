"""Real SIGKILL/EOF/exec recovery at the owned launch commit boundaries."""
import json
import os
from pathlib import Path
import selectors
import signal
import subprocess
import sys
import time
import unittest
from tests import test_workspace as fixtures
from gambit_smp import workspace as w,work_process as p
from gambit_smp.process_identity import process,same_birth


CHILD='''import json,os,sys,time
from pathlib import Path
from gambit_smp import workspace as w,work_process as p,task_processes as tp
root=Path(sys.argv[1]);phase=sys.argv[2];original=tp.recorder
with p.scope(root,'repair','audit'):
 def recorder():
  actual=original()
  def record(event,token,fields):
   if event=='started' and phase=='pre-started':
    print(json.dumps(dict(phase=phase,token=token)),flush=True);time.sleep(30)
   actual(event,token,fields)
   if event==phase:
    print(json.dumps(dict(phase=phase,token=token)),flush=True)
    time.sleep(30)
  record.root=actual.root;record.spawn_root=actual.spawn_root
  return record
 tp.recorder=recorder
 program="import pathlib,time; p=pathlib.Path('target-effect'); p.write_text('executed once');time.sleep(30)"
 child=tp.spawn([sys.executable,'-c',program],cwd=root)
 print(json.dumps(dict(phase='exec',pid=child.pid)),flush=True)
 child.wait()
'''


class SpawnBirthRecoveryTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp

    def test_metadata_patch_and_process_inventory_use_real_birth_barrier(self):
        from gambit_smp.framework import apply_untracked_patch
        from gambit_smp.task_processes import check
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'):
            out=w.task_output(self.root,'.cache/patch-control');out.mkdir(parents=True)
            (out/'unit.txt').write_text('before\n')
            patch=b'diff --git a/unit.txt b/unit.txt\n--- a/unit.txt\n+++ b/unit.txt\n@@ -1 +1 @@\n-before\n+after\n'
            apply_untracked_patch(out,patch,{'unit.txt'})
            self.assertEqual('after\n',(out/'unit.txt').read_text())
            self.assertTrue(w.git(self.root,'rev-parse','HEAD'))
            self.assertIsInstance(w.active_paths(),list)
            rows=self.rows()
            self.assertEqual(5,len(rows))
            self.assertTrue(all(row['event']=='finished' and row['birth']['process']['pid']==row['pid']
                                and row['spawnProtocol']['schema']=='task-spawn-barrier.v1' for row in rows))
        check(self.root,'repair',process='audit')

    def test_managed_launch_rejects_missing_durable_recorder_before_popen(self):
        from gambit_smp.spawn_protocol import launch
        from unittest.mock import patch
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'), patch('subprocess.Popen') as popen:
            for record in (None,lambda *args:None):
                with self.assertRaisesRegex(ValueError,'durable birth/exec recorder'):
                    launch([sys.executable,'-c','pass'],record=record,token='control')
            popen.assert_not_called()

    def test_framework_has_one_audited_raw_subprocess_boundary(self):
        import ast
        root=Path(__file__).resolve().parents[1]/'src/gambit_smp'
        calls=[]
        for source in root.glob('*.py'):
            tree=ast.parse(source.read_text())
            # Include import aliases: a newly renamed Popen is still a boundary.
            aliases={};direct={}
            for node in ast.walk(tree):
                if isinstance(node,ast.Import):
                    aliases.update({a.asname or a.name:a.name for a in node.names})
                elif isinstance(node,ast.ImportFrom) and node.module in {'subprocess','os','asyncio'}:
                    direct.update({a.asname or a.name:node.module+'.'+a.name for a in node.names})
            for node in ast.walk(tree):
                if not isinstance(node,ast.Call):continue
                f=node.func
                name=(aliases.get(f.value.id,f.value.id)+'.'+f.attr if isinstance(f,ast.Attribute) and isinstance(f.value,ast.Name)
                      else direct.get(f.id,'') if isinstance(f,ast.Name) else '')
                if name in {'subprocess.Popen','subprocess.run','subprocess.call','subprocess.check_output','subprocess.check_call',
                            'os.system','os.popen','os.fork','os.posix_spawn','os.posix_spawnp','asyncio.create_subprocess_exec','asyncio.create_subprocess_shell'}:
                    calls.append((source.name,name))
        self.assertCountEqual(calls,[('spawn_protocol.py','subprocess.Popen')]+
                              [('task_processes.py','subprocess.run'),('task_processes.py','subprocess.check_output')])

    def test_raw_popen_alias_and_system_are_denied_in_actual_scope(self):
        from subprocess import Popen as alias
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'):
            for launch in (lambda:alias([sys.executable,'-c','pass']),lambda:os.system('true')):
                with self.assertRaisesRegex(ValueError,'durable birth/exec boundary'):launch()
            self.assertEqual([],self.rows())

    def start_parent(self,phase):
        w.start(self.root,'repair',adopt=True)
        parent=subprocess.Popen([sys.executable,'-c',CHILD,str(self.root),phase],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.addCleanup(self.cleanup_parent,parent)
        with selectors.DefaultSelector() as selector:
            selector.register(parent.stdout,selectors.EVENT_READ)
            if not selector.select(10):self.fail('launch boundary was not reached')
        line=parent.stdout.readline()
        if not line:self.fail(parent.stderr.read())
        return parent,json.loads(line)

    @staticmethod
    def cleanup_parent(parent):
        if parent.poll() is None:parent.kill();parent.wait(timeout=5)
        parent.stdout.close();parent.stderr.close()

    def rows(self):
        owner=json.loads(p.paths(self.root,'repair','audit')[0].read_text())
        return [json.loads(f.read_text()) for f in (self.root/'.state/task-processes/repair'/owner['run']).glob('*.json')]

    def resume_when_absent(self):
        deadline=time.monotonic()+5
        while True:
            try:return p.resume(self.root,'repair','audit')
            except BlockingIOError:
                if time.monotonic()>=deadline:raise
                time.sleep(.025)
            except ValueError as error:
                if not any(word in str(error) for word in ('still holds','still alive','not quiescent')):raise
                if time.monotonic()>=deadline:raise
                time.sleep(.025)

    def test_controller_dies_after_plan_before_any_popen_birth(self):
        parent,_=self.start_parent('planned');row=self.rows()[0]
        self.assertEqual('planned',row['event']);self.assertNotIn('pid',row)
        parent.kill();self.assertEqual(-signal.SIGKILL,parent.wait(timeout=5))
        self.resume_when_absent();row=self.rows()[0]
        self.assertEqual('cancelled-before-birth',row['spawnReconciliation']['result'])
        self.assertFalse(row['spawnReconciliation']['targetExecuted'])
        self.assertFalse((self.root/'target-effect').exists())
        with p.scope(self.root,'repair','audit',provider='grok'):pass

    def test_controller_dies_after_child_birth_before_exec_permission(self):
        parent,_=self.start_parent('started');row=self.rows()[0]
        birth=row['birth'];self.assertTrue(same_birth(birth['process'],process(row['pid'])))
        directory=self.root/row['spawnProtocol']['directory']
        self.assertFalse((directory/'permission.json').exists())
        self.assertFalse((directory/'exec-intent.json').exists())
        parent.kill();parent.wait(timeout=5)
        self.resume_when_absent();row=self.rows()[0]
        self.assertEqual('cancelled-before-exec',row['spawnReconciliation']['result'])
        self.assertFalse(row['spawnReconciliation']['targetExecuted'])
        self.assertFalse((self.root/'target-effect').exists())
        directory=self.root/row['spawnProtocol']['directory']
        self.assertTrue((directory/'cancelled.json').is_file())

    def test_parent_dies_with_child_birth_durable_but_no_parent_pid_record(self):
        parent,_=self.start_parent('pre-started');row=self.rows()[0]
        self.assertEqual('planned',row['event']);self.assertNotIn('pid',row)
        birth=json.loads((self.root/row['spawnProtocol']['directory']/'birth.json').read_text())
        self.assertTrue(same_birth(birth['process'],process(birth['process']['pid'])))
        parent.kill();parent.wait(timeout=5)
        self.resume_when_absent();recovered=self.rows()[0]
        self.assertEqual(birth['process']['pid'],recovered['pid'])
        self.assertEqual('cancelled-before-exec',recovered['spawnReconciliation']['result'])
        self.assertFalse((self.root/'target-effect').exists())

    def test_live_target_survives_controller_and_blocks_resume_until_real_exit(self):
        parent,message=self.start_parent('never')
        deadline=time.monotonic()+8
        while not (self.root/'target-effect').exists() and time.monotonic()<deadline:time.sleep(.025)
        self.assertEqual('executed once',(self.root/'target-effect').read_text())
        row=self.rows()[0];pid=row['pid'];birth=row['birth']['process']
        try:
            parent.kill();parent.wait(timeout=5)
            with self.assertRaises((ValueError,BlockingIOError)):p.resume(self.root,'repair','audit')
            self.assertTrue(same_birth(birth,process(pid)))
            os.killpg(pid,signal.SIGTERM)
            self.resume_when_absent()
            row=self.rows()[0]
            self.assertEqual('exited-exec-outcome-unclaimed',row['spawnReconciliation']['result'])
            self.assertIsNone(row['spawnReconciliation']['targetExecuted'])
            self.assertEqual('executed once',(self.root/'target-effect').read_text())
            with p.scope(self.root,'repair','audit',provider='grok'):
                self.assertEqual(0,w.execute(self.root,'repair',[sys.executable,'-c','pass']))
        finally:
            if same_birth(birth,process(pid)):
                try:os.killpg(pid,signal.SIGKILL)
                except ProcessLookupError:pass

    def test_legacy_discard_never_accepts_an_arbitrary_command(self):
        from gambit_smp.spawn_reconciliation import metadata_read
        for argv in (['touch','anything'],['git','--no-optional-locks','-C',str(self.root),'reset','--hard','HEAD']):
            with self.assertRaises(ValueError):metadata_read(self.root,argv)

    def test_kernel_child_before_birth_record_retains_real_custody_after_parent_death(self):
        w.start(self.root,'repair',adopt=True)
        script='''import os,sys,time,json,subprocess
from pathlib import Path
from gambit_smp import work_process as p,task_processes as tp
root=Path(sys.argv[1]);original=subprocess.Popen
# Real child startup delay injected before entering the real launcher body.
# The native PID already exists and owns the actual inherited custody fds.
def delayed(argv,**kwargs):
 code="import os,sys,time;from pathlib import Path;Path(sys.argv[1]).write_text(str(os.getpid()));time.sleep(30);sys.path.insert(0,sys.argv[2]);from gambit_smp.spawn_protocol import child;raise SystemExit(child(sys.argv[3],int(sys.argv[4]),int(sys.argv[5]),int(sys.argv[6])))"
 import gambit_smp.spawn_protocol as protocol
 return original([sys.executable,'-I','-S','-B','-c',code,str(root/'kernel-child'),str(Path(protocol.__file__).parents[1]),*argv[-4:]],**kwargs)
subprocess.Popen=delayed
with p.scope(root,'repair','audit'):
 tp.spawn([sys.executable,'-c',"open('target-effect','w').write('bad')"],cwd=root).wait()
'''
        parent=subprocess.Popen([sys.executable,'-c',script,str(self.root)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        self.addCleanup(self.cleanup_parent,parent)
        deadline=time.monotonic()+8
        while not (self.root/'kernel-child').exists() and time.monotonic()<deadline:
            if parent.poll() is not None:self.fail(parent.stderr.read())
            time.sleep(.025)
        pid=int((self.root/'kernel-child').read_text());birth=process(pid)
        row=self.rows()[0];directory=self.root/row['spawnProtocol']['directory']
        self.assertFalse((directory/'birth.json').exists())
        try:
            parent.kill();parent.wait(timeout=5)
            with self.assertRaises((BlockingIOError,ValueError)):p.resume(self.root,'repair','audit')
            self.assertTrue(same_birth(birth,process(pid)))
            os.killpg(pid,signal.SIGKILL)
            self.resume_when_absent();recovered=self.rows()[0]
            self.assertEqual('cancelled-before-birth',recovered['spawnReconciliation']['result'])
            self.assertFalse((self.root/'target-effect').exists())
        finally:
            if same_birth(birth,process(pid)):
                try:os.killpg(pid,signal.SIGKILL)
                except ProcessLookupError:pass

    def test_target_python_site_hook_runs_only_after_durable_birth(self):
        from gambit_smp.task_processes import spawn
        w.start(self.root,'repair',adopt=True)
        hook=self.root/'site-hook';hook.mkdir()
        (hook/'sitecustomize.py').write_text("from pathlib import Path\nr=Path.cwd(); births=list(r.glob('.cache/tasks/repair/processes/audit/runs/*/outputs/process-starts/*.spawn/birth.json'));(r/'hook-phase').write_text('after-birth' if births else 'before-birth')\n")
        with p.scope(self.root,'repair','audit'):
            target=spawn([sys.executable,'-c','pass'],cwd=self.root,env=dict(os.environ,PYTHONPATH=str(hook)))
            self.assertEqual(0,target.wait(timeout=5))
        self.assertEqual('after-birth',(self.root/'hook-phase').read_text())

    def test_request_write_failure_closes_all_launch_descriptors_before_any_spawn(self):
        import errno
        from unittest.mock import patch
        from gambit_smp.task_processes import spawn
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'):
            before=len(os.listdir('/dev/fd'))
            actual=w.write
            def fail(path,value):
                if path.name=='request.json':raise OSError(errno.ENOSPC,'injected request fsync failure')
                return actual(path,value)
            with patch.object(w,'write',side_effect=fail):
                with self.assertRaises(OSError):spawn([sys.executable,'-c','pass'],cwd=self.root)
            self.assertEqual(before,len(os.listdir('/dev/fd')))
            rows=self.rows();self.assertEqual(1,len(rows))
            self.assertEqual('spawn-failed',rows[0]['event'])
            self.assertNotIn('pid',rows[0]);self.assertEqual(errno.ENOSPC,rows[0]['spawnError']['errno'])

    def test_real_exec_failure_preserves_oserror_and_nonexecution_evidence(self):
        from gambit_smp.task_processes import spawn
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'):
            with self.assertRaises(FileNotFoundError):spawn(['/missing/spawn-exec-contract-program'],cwd=self.root)
        row=self.rows()[0]
        self.assertEqual('FileNotFoundError',row['spawnError']['type'])
        self.assertEqual('spawn-failed',row['spawnReconciliation']['previousEvent'])
        self.assertFalse(row['spawnQuiescence']['targetExecuted'])
        self.assertEqual('cancelled-before-exec',row['spawnQuiescence']['result'])

    def test_expired_absolute_launch_deadline_does_not_execute_target(self):
        from gambit_smp.task_processes import spawn
        w.start(self.root,'repair',adopt=True)
        with p.scope(self.root,'repair','audit'):
            with self.assertRaises(subprocess.TimeoutExpired):
                spawn([sys.executable,'-c',"open('target-effect','w').write('bad')"],cwd=self.root,launch_deadline=time.monotonic()-1)
        self.assertFalse((self.root/'target-effect').exists())
        row=self.rows()[0]
        self.assertEqual('cancelled-before-birth',row['spawnQuiescence']['result'])
