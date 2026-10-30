"""Real process death and filesystem interruption; no external model service."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import unittest
from datetime import date
from unittest.mock import patch

from tests import test_workspace as fixtures
from gambit_smp import workspace as w, task_dependencies as deps, task_retention as retention
from gambit_smp import task_migration as migration


class InterruptionTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp
    old=fixtures.WorkspaceTests.old

    def wait_for(self,predicate,seconds=10):
        until=time.monotonic()+seconds
        while time.monotonic()<until:
            if predicate():return
            time.sleep(.025)
        self.fail('real child did not reach bounded observation point')

    def killed_supervisor(self,drop_descriptor):
        w.start(self.root,'repair',adopt=True)
        stop=self.root/'.cache/tasks/repair/stop'
        child=("import os,time;from pathlib import Path;"
               "base=Path(os.environ['GAMBIT_SMP_TASK_CACHE']);"
               "out=base/'runs'/os.environ['GAMBIT_SMP_TASK_RUN']/'outputs';out.mkdir(parents=True,exist_ok=True);"
               +( "os.close(int(os.environ['GAMBIT_SMP_TASK_LOCK_FD']));" if drop_descriptor else '' )+
               "(out/'ready').write_text('actual child running');"
               "deadline=time.monotonic()+20\n"
               "while not (base/'stop').exists() and time.monotonic()<deadline:time.sleep(.025)\n")
        code="from gambit_smp.workspace import execute;from pathlib import Path;import sys;execute(Path("+repr(str(self.root))+"),'repair',[sys.executable,'-c',"+repr(child)+"])"
        supervisor=subprocess.Popen([sys.executable,'-c',code],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,start_new_session=True)
        receipt=None;child_gone=False
        try:
            self.wait_for(lambda:bool(list((self.root/'.cache/tasks/repair/runs').glob('*/outputs/ready'))))
            record=w.paths(self.root,'repair')[0]
            value=json.loads(record.read_text())
            receipt=self.root/'.state/task-runs/repair'/(value['run']+'.json')
            self.wait_for(lambda:json.loads(receipt.read_text()).get('pgid') is not None)
            supervisor.kill();supervisor.wait(timeout=5)
            if drop_descriptor:
                with self.assertRaisesRegex(ValueError,'custody|process group still present'):w.resume(self.root,'repair')
            else:
                with self.assertRaises(BlockingIOError):w.resume(self.root,'repair')
            self.assertEqual('running',json.loads(receipt.read_text())['state'])
            stop.write_text('finish the actual child')
            pgid=json.loads(receipt.read_text())['pgid']
            def gone():
                try:os.killpg(pgid,0)
                except ProcessLookupError:return True
                except PermissionError:return False
                return False
            self.wait_for(gone)
            child_gone=True
            w.resume(self.root,'repair')
            recovered=json.loads(receipt.read_text())
            self.assertEqual('interrupted',recovered['state'])
            self.assertFalse(recovered['reconciliation']['nativeAdmitted'])
            ended=recovered['endedAt']
            w.resume(self.root,'repair')
            self.assertEqual(ended,json.loads(receipt.read_text())['endedAt'])
            output=Path(recovered['output']);self.assertTrue(output.exists())
            self.assertIn(value['run'],w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[]))
            self.assertFalse(output.exists())
            self.assertEqual('interrupted',json.loads(receipt.read_text())['state'])
            self.assertEqual(7,w.execute(self.root,'repair',[sys.executable,'-c','raise SystemExit(7)']))
            w.finish(self.root,'repair')
        finally:
            stop.parent.mkdir(parents=True,exist_ok=True);stop.touch()
            if supervisor.poll() is None:supervisor.kill();supervisor.wait()
            if not child_gone and receipt and receipt.exists():
                pgid=json.loads(receipt.read_text()).get('pgid')
                if pgid:
                    try:os.killpg(pgid,signal.SIGKILL)
                    except ProcessLookupError:pass
            if supervisor.stderr:supervisor.stderr.close()

    def test_sigkill_parent_child_holds_real_lock_until_exit(self):self.killed_supervisor(False)
    def test_sigkill_parent_closed_child_descriptor_still_blocks_by_process_observation(self):self.killed_supervisor(True)

    def test_deletion_crash_resumes_and_rejects_new_old_dated_files(self):
        w.start(self.root,'repair',adopt=True)
        source=self.root/'.cache/checkpoint';source.mkdir(parents=True);(source/'header').write_text('real pinned bytes')
        expired=self.root/'.cache/expired';expired.mkdir();(expired/'a.log').write_text('actual log')
        failed=subprocess.run([sys.executable,'-c','raise SystemExit(7)'])
        raw=json.dumps(dict(exit=failed.returncode)).encode();(expired/'receipt.json').write_bytes(raw)
        for path in [*expired.iterdir(),expired,source/'header',source]:self.old(path)
        deps.adopt(self.root,'repair',['.cache/expired','.cache/checkpoint'])
        retention.classify(self.root,'repair',recovery=['.cache/checkpoint'])
        code=("from pathlib import Path;import os;from datetime import date;from gambit_smp import task_retention as r\n"
              "def cut(path):\n (path/'a.log').unlink()\n os._exit(91)\n"
              "r.remove_tree=cut\nr.collect(Path("+repr(str(self.root))+"),'repair',today=date(2099,1,1),opened=[])\n")
        self.assertEqual(91,subprocess.run([sys.executable,'-c',code]).returncode)
        self.assertFalse((expired/'a.log').exists());self.assertTrue((expired/'receipt.json').exists())
        extra=expired/'unexpected';extra.write_text('not in the original deletion inventory');self.old(extra)
        with self.assertRaisesRegex(ValueError,'new entry'):retention.collect(self.root,'repair',today=date(2099,1,1),opened=[])
        extra.unlink()
        self.assertEqual(['.cache/expired'],retention.collect(self.root,'repair',today=date(2099,1,1),opened=[]))
        self.assertEqual('real pinned bytes',(source/'header').read_text())
        value=json.loads(deps.registry(self.root,'repair').read_text());archived=value['expired'][0]['cleanup']['archivedRecords']
        self.assertTrue(archived);self.assertFalse(expired.exists())
        from gambit_smp.artifact_storage import archived_record
        import hashlib
        self.assertEqual(raw,archived_record(self.root,dict(path='.cache/expired/receipt.json',sha256=hashlib.sha256(raw).hexdigest())))
        self.assertEqual([],retention.collect(self.root,'repair',today=date(2099,1,1),opened=[]))

    def test_every_scope_blocks_forbidden_root_before_mkdir(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            with self.assertRaisesRegex(ValueError,'campaigns/ is forbidden'):(self.root/'campaigns').mkdir()
        self.assertFalse((self.root/'campaigns').exists())
        # Importing the framework in another actual process also activates the base rule.
        env=dict(os.environ,GAMBIT_SMP_TASK_ROOT=str(self.root))
        code="import gambit_smp;from pathlib import Path;Path("+repr(str(self.root/'campaigns'))+").mkdir()"
        result=subprocess.run([sys.executable,'-c',code],env=env,capture_output=True,text=True)
        self.assertNotEqual(0,result.returncode);self.assertFalse((self.root/'campaigns').exists())

    def test_console_module_and_imported_main_share_actual_lifecycle(self):
        w.start(self.root,'repair',adopt=True)
        (self.root/'models/gambit').mkdir(parents=True)
        (self.root/'models/gambit/cases.json').write_text('{}');(self.root/'evidence').mkdir()
        deps.adopt(self.root,'repair',[],default=True)
        env=dict(os.environ,GAMBIT_SMP_ROOT=str(self.root))
        commands=[
            [sys.executable,'-m','gambit_smp','verify','--invalid-option'],
            [sys.executable,'-m','gambit_smp.verify_protocols','--invalid-option'],
            [sys.executable,'-c',"import sys;from gambit_smp.verify_protocols import main;sys.argv=['verify','--invalid-option'];main()"],
        ]
        for command in commands:
            result=subprocess.run(command,env=env,capture_output=True,text=True)
            self.assertEqual(2,result.returncode,result.stderr)
        receipts=[json.loads(p.read_text()) for p in (self.root/'.state/task-runs/repair').glob('*.json')]
        self.assertEqual(3,len(receipts));self.assertTrue(all(row['state']=='returned' and row['exit']==2 for row in receipts))
        self.assertFalse((self.root/'campaigns').exists())

    def test_forbidden_layout_rejects_aliases_and_parent_traversal(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            link=w.paths(self.root,'repair')[1]/'root-alias';link.symlink_to(self.root,target_is_directory=True)
            for path in [link/'campaigns', self.root/'.cache/tasks/repair/../../../campaigns',self.root/'Campaigns']:
                with self.assertRaises(ValueError):path.mkdir()
        self.assertFalse((self.root/'campaigns').exists())

    def test_failed_validation_queue_is_archived_without_completing_pending_test_jobs(self):
        import hashlib,sqlite3
        from contextlib import closing
        w.start(self.root,'repair',adopt=True)
        out=self.root/'.cache/failed-validation';queue=out/'domains/0/queue.sqlite';queue.parent.mkdir(parents=True)
        ids=['tests.sample.Control.test_one','tests.sample.Control.test_two']
        with closing(sqlite3.connect(queue)) as db:
            db.execute('CREATE TABLE jobs(ordinal INTEGER UNIQUE,id TEXT PRIMARY KEY,lane INTEGER)')
            db.executemany('INSERT INTO jobs VALUES(?,?,NULL)',enumerate(ids));db.commit()
        child=subprocess.Popen([sys.executable,'-c',"print('actual failed producer');raise SystemExit(7)"],stdout=subprocess.PIPE,start_new_session=True)
        log=child.communicate()[0];self.assertEqual(7,child.returncode)
        (out/'process.log').write_bytes(log);(out/'test-result.json').write_text('{"status":"FAIL","exit":7}')
        record=dict(schema='gambit-framework-validation.v1',testResultSha256=hashlib.sha256((out/'test-result.json').read_bytes()).hexdigest(),
                    producer=dict(pid=child.pid,endedAt=w.now().isoformat(),log=dict(path='process.log',sha256=hashlib.sha256(log).hexdigest())),
                    executionDomains=[dict(schema='sealed-validation-domain.v1',expectedTestIds=ids)])
        raw=json.dumps(record).encode();(out/'receipt.json').write_bytes(raw)
        for path in [*out.rglob('*'),out]:self.old(path)
        deps.adopt(self.root,'repair',['.cache/failed-validation'])
        retention.classify(self.root,'repair',recovery=[])
        with closing(sqlite3.connect(queue)) as writer:
            writer.execute('BEGIN IMMEDIATE')
            with self.assertRaises(sqlite3.OperationalError):retention.collect(self.root,'repair',today=date(2099,1,1),opened=[])
            self.assertTrue(queue.exists());writer.rollback()
        self.assertEqual(['.cache/failed-validation'],retention.collect(self.root,'repair',today=date(2099,1,1),opened=[]))
        value=json.loads(deps.registry(self.root,'repair').read_text())
        archive=value['expired'][0]['cleanup']['queueArchives'][0]
        self.assertEqual(2,archive['pendingTestJobs'])
        with closing(sqlite3.connect(self.root/archive['path'])) as db:
            self.assertEqual([(0,ids[0],None),(1,ids[1],None)],db.execute('SELECT * FROM jobs ORDER BY ordinal').fetchall())
        self.assertFalse(out.exists())

    def test_validation_isolation_keeps_the_actual_parent_lease(self):
        from gambit_smp.validation_domains import isolated_test_context
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            with isolated_test_context():
                self.assertNotIn('GAMBIT_SMP_TASK_ID',os.environ)
                with self.assertRaises(BlockingIOError):
                    with w.lease(self.root,'repair'):pass
                with self.assertRaisesRegex(ValueError,'campaigns/ is forbidden'):(self.root/'campaigns').mkdir()
            self.assertEqual('repair',os.environ['GAMBIT_SMP_TASK_ID'])

    def test_pipe_child_carries_custody_and_rejects_deferred_context(self):
        from gambit_smp.task_processes import spawn,check
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            saved=dict(os.environ)
            child=spawn([sys.executable,'-c',
                "from pathlib import Path;import os;from gambit_smp.workspace import inherited_lease;"
                "assert inherited_lease(Path(os.environ['GAMBIT_SMP_TASK_ROOT']),os.environ['GAMBIT_SMP_TASK_ID']) is not None;print('custody')"],
                env={},stdout=subprocess.PIPE,text=True)
            self.assertEqual('custody',child.communicate(timeout=10)[0].strip())
            self.assertEqual(0,child.returncode)
            self.assertEqual(1,len(check(self.root,'repair')))
        with self.assertRaisesRegex(ValueError,'no longer current'):
            spawn([sys.executable,'-c','raise SystemExit(99)'],env=saved)
        w.finish(self.root,'repair')

    def test_tool_family_console_module_and_import_share_lifecycle(self):
        w.start(self.root,'repair',adopt=True)
        (self.root/'models/gambit').mkdir(parents=True)
        (self.root/'models/gambit/cases.json').write_text('{}')
        (self.root/'evidence').mkdir()
        deps.adopt(self.root,'repair',[],default=True)
        env=dict(os.environ,GAMBIT_SMP_ROOT=str(self.root))
        commands=[
            [sys.executable,'-m','gambit_smp','tool','process-observation','--invalid-option'],
            [sys.executable,'-m','gambit_smp.process_observation','--invalid-option'],
            [sys.executable,'-c',"import sys;from gambit_smp.process_observation import main;sys.argv=['tool','--invalid-option'];main()"],
        ]
        for command in commands:
            result=subprocess.run(command,env=env,capture_output=True,text=True)
            self.assertEqual(2,result.returncode,result.stderr)
        receipts=[json.loads(p.read_text()) for p in (self.root/'.state/task-runs/repair').glob('*.json')]
        self.assertEqual(3,len(receipts))
        self.assertTrue(all(row['state']=='returned' and row['exit']==2 for row in receipts))

    def test_synchronous_adapter_exit_and_timeout_record_real_groups(self):
        from gambit_smp.task_processes import run,check
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            with self.assertRaises(subprocess.CalledProcessError) as failure:
                run([sys.executable,'-c',"print('actual failure');raise SystemExit(7)"],capture_output=True,text=True,check=True)
            self.assertEqual(7,failure.exception.returncode)
            self.assertIn('actual failure',failure.exception.stdout)
            with self.assertRaises(subprocess.TimeoutExpired):
                run([sys.executable,'-c','import time;time.sleep(20)'],capture_output=True,timeout=.1)
            self.assertEqual(2,len(check(self.root,'repair')))
        w.finish(self.root,'repair')
