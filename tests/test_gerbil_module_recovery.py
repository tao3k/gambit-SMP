"""Actual compiler-process interruption; C transport fixture, not Scheme admission."""
import json
import time
import unittest
from unittest.mock import patch

from gambit_smp import workspace as w
from gambit_smp.recipes import ExecutionContext
from gambit_smp.gerbil_build import _module_stage
from gambit_smp.task_processes import observe_group
from tests import test_incremental_native_adapters as adapters


class GerbilPendingModuleRecoveryTests(unittest.TestCase):
    setUp = adapters.GerbilIncrementalAdapterTests.setUp
    prepare = adapters.GerbilIncrementalAdapterTests.prepare
    lock = adapters.GerbilIncrementalAdapterTests.lock
    build = adapters.GerbilIncrementalAdapterTests.build

    def test_actual_interrupted_module_preserves_only_authenticated_completed_prefix(self):
        self.prepare()
        (self.checkout/'src/bootstrap/gerbil/z.scm').write_text('int z(void) { return 2; }\n')
        w.git(self.checkout,'add','.')
        w.git(self.checkout,'-c','user.name=Test','-c','user.email=test@example.invalid',
              'commit','-qm','explicit second-module interruption')
        self.revision=w.git(self.checkout,'rev-parse','HEAD');self.lock()
        compiler=self.payload/'gsc/gsc'
        compiler.write_text(compiler.read_text().replace('"$CC" -x c',
            'case "$previous" in */z.scm) while test -n "${GERBIL_TEST_PAUSE:-}" && test -f "$GERBIL_TEST_PAUSE"; do sleep .05; done;; esac\n"$CC" -x c'))
        pause=self.root/'.cache/tasks/repair/pause-module';pause.write_text('pause before native compile')
        run=ExecutionContext.run
        def bounded(context,name,argv,cwd,cap,**options):
            if name.startswith('gerbil-stage0-module-'):cap=min(cap,.4)
            return run(context,name,argv,cwd,cap,**options)
        with patch.object(ExecutionContext,'run',bounded):
            with self.assertRaises(TimeoutError):self.build(pause=pause,stage_cap=2)
        failed_path=next(path for path in self.last_output.glob('gerbil-stage0-module-*.process.json')
                         if json.loads(path.read_text())['timeout'])
        failed_bytes=failed_path.read_bytes();failed=json.loads(failed_bytes)
        source=next((self.root/'.cache/tasks/repair/build/gerbil').glob('*/source'))
        modules=json.loads((source.parent/'gerbil-stage0-modules.json').read_text())
        self.assertEqual({'module.scm'},set(modules))
        first=source/'bootstrap/lib/gerbil/module.o1';stamp=first.stat().st_mtime_ns
        self.assertFalse((source/'bootstrap/lib/gerbil/z.o1').exists())
        deadline=time.monotonic()+2
        while True:
            group=observe_group(failed['pid'])
            if group['result']=='absent' or time.monotonic()>=deadline:break
            time.sleep(.01)
        self.assertEqual('absent',group['result'])
        w.resume(self.root,'repair');pause.unlink()
        with patch.object(ExecutionContext,'run',bounded):
            resumed,commands=self.build('grok',stage_cap=2)
        self.assertEqual(str(source),resumed['observation']['workspace'])
        self.assertEqual(stamp,first.stat().st_mtime_ns)
        self.assertNotIn('gerbil-'+_module_stage('module.scm'),[row['stage'] for row in commands])
        self.assertIn('gerbil-'+_module_stage('z.scm'),[row['stage'] for row in commands])
        self.assertEqual(6,len((source/'compiled.log').read_text().splitlines()))
        self.assertEqual(failed_bytes,failed_path.read_bytes())
