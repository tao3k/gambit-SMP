"""Real work-item admission, process custody, interruption and retention controls."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unittest
from datetime import date
from tests import test_workspace as fixtures
from gambit_smp import workspace as w, work_process as p

class WorkProcessTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp

    def test_registered_work_items_and_bounded_roles(self):
        w.start(self.root,'repair',adopt=True)
        with self.assertRaisesRegex(ValueError,'work item'):w.start(self.root,'audit',adopt=True)
        with self.assertRaisesRegex(ValueError,'role'): 
            with p.scope(self.root,'repair','audit-20261020'):pass
        (self.root/'docs').mkdir()
        w.write(self.root/'docs/work-items.json',dict(schema='gambit-work-items.v1',items={
            'repair':dict(scope='9',processes={'audit':'maintenance'}),
            'next':dict(scope='10',processes={'audit':'maintenance'})}))
        w.start(self.root,'next',adopt=True)
        with self.assertRaisesRegex(ValueError,'registered work item'):w.start(self.root,'grok-audit',adopt=True)
        self.assertFalse((self.root/'.cache/tasks/grok-audit').exists())

    def test_process_reuses_parent_and_excludes_checkpoint_writes(self):
        w.start(self.root,'repair',adopt=True)
        checkpoint=self.root/'.cache/checkpoint';checkpoint.mkdir(parents=True);(checkpoint/'header').write_text('retain')
        for provider in ('codex','grok'):
            with w.lease(self.root,'repair'):
                with p.scope(self.root,'repair','audit',provider):
                    self.assertIsNotNone(w.inherited_lease(self.root,'repair'))
                    out=w.task_output(self.root,'.cache/actual.json');out.parent.mkdir(parents=True,exist_ok=True);out.write_text('{}')
                    self.assertTrue(out.is_relative_to(p.paths(self.root,'repair','audit')[1]))
                    with self.assertRaises(ValueError):(checkpoint/'header').write_text('forbidden')
                    with self.assertRaises(BlockingIOError):p.collect(self.root,'repair','audit',today=date(2099,1,1),opened=[])
        with p.scope(self.root,'repair','validation'):
            self.assertEqual(7,w.execute(self.root,'repair',[sys.executable,'-c','raise SystemExit(7)']))
        self.assertEqual('retain',(checkpoint/'header').read_text())
        self.assertEqual(['repair'],[x.name for x in (self.root/'.cache/tasks').iterdir()])
        removed=p.collect(self.root,'repair','audit',today=date(2099,1,1),opened=[])
        self.assertEqual(2,len(removed))
        w.finish(self.root,'repair')
        with self.assertRaisesRegex(ValueError,'not open'):
            with p.scope(self.root,'repair','audit'):pass

    def test_real_supervisor_death_requires_reconciliation(self):
        w.start(self.root,'repair',adopt=True)
        code=('from pathlib import Path;import time;from gambit_smp import work_process as p;'
              'from gambit_smp import workspace as w;'
              'root=Path('+repr(str(self.root))+')\n'
              'with p.scope(root,"repair","audit"):\n'
              ' w.task_output(root,".cache/ready").parent.mkdir(parents=True,exist_ok=True)\n'
              ' w.task_output(root,".cache/ready").write_text("ready")\n'
              ' time.sleep(30)\n')
        child=subprocess.Popen([sys.executable,'-c',code],stderr=subprocess.PIPE)
        record,cache=p.paths(self.root,'repair','audit')
        try:
            until=time.monotonic()+10
            while not list(cache.glob('runs/*/outputs/ready')) and time.monotonic()<until:
                if child.poll() is not None:self.fail(child.stderr.read().decode())
                time.sleep(.025)
            self.assertTrue(list(cache.glob('runs/*/outputs/ready')))
            with self.assertRaises(BlockingIOError):w.finish(self.root,'repair')
            child.kill();child.wait(timeout=5)
            with self.assertRaisesRegex(ValueError,'explicit process-resume'):
                with p.scope(self.root,'repair','audit'):pass
            with self.assertRaisesRegex(ValueError,'reconciliation'):w.finish(self.root,'repair')
            p.resume(self.root,'repair','audit')
            row=json.loads(record.read_text());attempt=p.run_path(self.root,'repair','audit',row['run'])
            receipt=json.loads(attempt.read_text());self.assertEqual('interrupted',receipt['state'])
            self.assertFalse(receipt['reconciliation']['nativeAdmitted'])
            with p.scope(self.root,'repair','audit'):pass
            w.finish(self.root,'repair')
        finally:
            if child.poll() is None:child.kill();child.wait()
            child.stderr.close()

    def test_absorb_closed_role_preserves_bytes_and_original_expiry(self):
        w.start(self.root,'old-audit',adopt=True)
        old=w.paths(self.root,'old-audit')[1];old.mkdir(parents=True,exist_ok=True)
        raw=b'{"exit":7,"state":"interrupted"}\n';(old/'negative.json').write_bytes(raw)
        w.finish(self.root,'old-audit')
        w.start(self.root,'repair',adopt=True)
        receipt=p.absorb(self.root,'repair','audit','old-audit')
        target=Path(receipt['destination']);self.assertEqual(raw,(target/'negative.json').read_bytes());self.assertFalse(old.exists())
        self.assertEqual(receipt,p.absorb(self.root,'repair','audit','old-audit'))
        self.assertEqual(['history:old-audit'],p.collect(self.root,'repair','audit',today=date(2099,1,1),opened=[]))
        self.assertFalse(target.exists())
