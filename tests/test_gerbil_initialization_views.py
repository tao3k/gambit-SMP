"""Derived artifact custody controls; graph semantics use native Scheme PBT."""

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.gerbil_build.initialization_views import materialize_views


class InitializationViewCustodyTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve();self.store=self.root/'products';self.store.mkdir()
        self.source=self.root/'source';(self.source/'build/bin').mkdir(parents=True)
        (self.source/'build/bin/gerbil').write_text('unit-only provider')
        (self.source/'run.sh').write_text('unit-only entry')
        self.out=self.root/'run';self.out.mkdir();header=self.out/'header.json'
        header.write_text(json.dumps(dict(runId='run',inputs={})))
        self.ctx=SimpleNamespace(root=self.root,directory=self.out,commands=[],
            receipt=dict(journal=dict(path=str(header),scope='unit-custody')),
            bind=lambda paths:None,remaining=lambda:30)
        self.programs=[]
        for name in ['a','b']:
            raw=self.source/(name+'.init');raw.write_text(name)
            self.programs.append(dict(context='context',moduleId='std/'+name,
                source='std/'+name,initializationGraph=str(raw),
                identities={str(raw):digest(raw)},completion=dict(path='old-program',sha256='old')))
        self.addCleanup(patch.stopall)
        patch('gambit_smp.research_kernel.retain_run_record',return_value={
            'path':'unit-only-view','sha256':'sha','observation':'view','scope':'unit-custody'}).start()

    def writer(self, *, stopped=True, change_input=False, timed_out=False):
        def run(*args):
            staging=next(self.out.glob('initialization-view-projection-*'))
            target=next(p for p in staging.iterdir()if p.name=='requests.scm')
            self.assertIn('a.init',target.read_text())
            # An emitter seam, not the semantic projector under test.
            key=__import__('hashlib').sha256((self.programs[0]['identities'][self.programs[0]['initializationGraph']]
                 +':'+digest(Path(__file__).resolve().parents[1]/'src/gambit_smp/gerbil_initialization_view.ss')).encode()).hexdigest()
            (staging/(key+'.init')).write_text('unit-only closed projection')
            self.ctx.commands.append(dict(parentReaped=True,processGroupQuiescent=stopped))
            if change_input:Path(self.programs[0]['initializationGraph']).write_text('changed')
            return (-9 if timed_out else 0),'INITIALIZATION-VIEW-COMPLETE 0\n',timed_out,0.01
        return run

    def test_unknown_writer_exit_cannot_issue_view(self):
        self.ctx.run=self.writer(stopped=None)
        with self.assertRaisesRegex(ValueError,'termination is unknown'):
            materialize_views(self.ctx,self.source,self.store,self.programs)
        self.assertEqual(list((self.store/'initialization-views').glob('*.json')),[])

    def test_changed_semantic_input_cannot_issue_view(self):
        self.ctx.run=self.writer(change_input=True)
        with self.assertRaisesRegex(ValueError,'ownership changed'):
            materialize_views(self.ctx,self.source,self.store,self.programs)
        self.assertEqual(list((self.store/'initialization-views').glob('*.json')),[])

    def test_failed_parent_retains_only_closed_view_prefix(self):
        self.ctx.run=self.writer(timed_out=True)
        with self.assertRaisesRegex(ValueError,'batch incomplete'):
            materialize_views(self.ctx,self.source,self.store,self.programs)
        records=list((self.store/'initialization-views').glob('*.json'))
        self.assertEqual(len(records),1)
        record=json.loads(records[0].read_text())
        self.assertFalse(record['moduleComplete']);self.assertTrue(record['parentTimedOut'])
        self.assertEqual(record['sourceProgram'],self.programs[0]['completion'])
