"""Real compiler reuse and generated-output placement under the existing owner."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest
from datetime import date
from tests import test_workspace as fixtures
from gambit_smp import workspace as w, storage_policy as policy

class CacheBuildLayoutTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp

    def test_generated_runtime_directories_are_rejected_before_creation(self):
        policy.install(self.root)
        for source in ('src','vendor','providers','provide','VR','.venv','.data/worktrees/issue/vendor'):
            for generated in ('pro','profiles','policy','policies','private','provider-source','prompts'):
                target=self.root/source/generated
                with self.subTest(path=str(target)),self.assertRaisesRegex(ValueError,'require .cache'):
                    target.mkdir(parents=True)
                self.assertFalse(target.exists())
        target=self.root/'.cache/tasks/repair/agents/worker/private';target.mkdir(parents=True)
        self.assertTrue(target.is_dir())
        # Ordinary editable source files are still source.
        source=self.root/'src/example.py';source.parent.mkdir(exist_ok=True);source.write_text('value = 1\n')

    def test_provider_cache_environment_is_shared_and_restored(self):
        w.start(self.root,'repair',adopt=True)
        previous=sys.pycache_prefix;old=os.environ.get('UV_CACHE_DIR');seen=[]
        for provider in ('codex','grok'):
            with w.execution_scope(self.root,'repair',provider=provider):
                seen.append((sys.pycache_prefix,os.environ['UV_CACHE_DIR'],os.environ['XDG_CACHE_HOME']))
                self.assertTrue(all(Path(name).is_relative_to(self.root/'.cache') for name in seen[-1]))
                code='import os,sys;from pathlib import Path;assert Path(sys.pycache_prefix).is_relative_to(Path(os.environ["GAMBIT_SMP_TASK_ROOT"])/".cache");assert os.environ["UV_CACHE_DIR"].endswith("/.cache/tools/uv")'
                self.assertEqual(0,w.execute(self.root,'repair',[sys.executable,'-c',code],provider=provider))
        self.assertEqual(seen[0],seen[1]);self.assertEqual(previous,sys.pycache_prefix);self.assertEqual(old,os.environ.get('UV_CACHE_DIR'))

    def test_real_cold_noop_edit_and_configuration_invalidation(self):
        cc=shutil.which('cc');make=shutil.which('make')
        if not cc or not make:self.fail('real cc and make required')
        w.start(self.root,'repair',adopt=True)
        with self.assertRaisesRegex(ValueError,'custody'):w.build_output(self.root,'tiny',compiler=cc)
        counts=[];build=None;configuration_mtime=None
        for stage,provider in [('cold','codex'),('noop','grok'),('edit','codex')]:
            with w.execution_scope(self.root,'repair',provider=provider):
                current=w.build_output(self.root,'tiny',compiler=cc,flags=['-O0'])
                if build is None:
                    build=current
                    (build/'a.c').write_text('int a(void) { return 1; }\n')
                    (build/'b.c').write_text('int b(void) { return 2; }\n')
                    (build/'Makefile').write_text('all: a.o b.o\n%.o: %.c\n\t$(CC) -O0 -c $< -o $@\n\t@echo $@ >> compiled.log\n')
                self.assertEqual(build,current)
                observed=(build/'configuration.json').stat().st_mtime_ns
                if configuration_mtime is None:configuration_mtime=observed
                self.assertEqual(configuration_mtime,observed)
                if stage=='edit':
                    time.sleep(1.05)
                    (build/'a.c').write_text('int a(void) { return 3; }\n')
                before=(build/'compiled.log').read_text().splitlines() if (build/'compiled.log').exists() else []
                b_before=(build/'b.o').stat().st_mtime_ns if (build/'b.o').exists() else None
                self.assertEqual(0,w.execute(self.root,'repair',[make,'-C',str(build),'CC='+cc]))
                after=(build/'compiled.log').read_text().splitlines();counts.append(len(after)-len(before))
                if stage in ('noop','edit'):self.assertEqual(b_before,(build/'b.o').stat().st_mtime_ns)
                if stage=='noop':self.assertEqual(['a.o','b.o'],after)
                if stage=='edit':
                    other=w.build_output(self.root,'tiny',compiler=cc,flags=['-O1'])
                    self.assertNotEqual(build,other);self.assertFalse((other/'a.o').exists())
        self.assertEqual([2,0,1],counts)
        self.assertTrue(build.is_relative_to(self.root/'.cache/tasks/repair/build'))
        # The same collector expires build payloads without deleting source or task.
        from gambit_smp import task_dependencies as deps,task_retention as retention
        relative=str(build.relative_to(self.root))
        deps.adopt(self.root,'repair',[relative]);retention.classify(self.root,'repair',recovery=[relative])
        w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
        self.assertTrue(build.exists())
        deps.release(self.root,'repair',[relative])
        w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
        self.assertFalse(build.exists());self.assertEqual('open',json.loads(w.paths(self.root,'repair')[0].read_text())['state'])

    def test_build_cleanup_real_exit_preserves_inventory_and_denies_new_entries(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            build=w.build_output(self.root,'cleanup',compiler=shutil.which('cc'))
            (build/'a.o').write_bytes(b'first object');(build/'b.o').write_bytes(b'second object')
        code=("import os;from pathlib import Path;from datetime import date;from gambit_smp import workspace as w,storage_retention as s\n"
              "def cut(path):\n (path/'a.o').unlink()\n os._exit(91)\n"
              "s.remove_tree=cut\nw.collect_runs(Path("+repr(str(self.root))+"),'repair',today=date(2099,1,1),opened=[])\n")
        self.assertEqual(91,subprocess.run([sys.executable,'-c',code]).returncode)
        self.assertFalse((build/'a.o').exists());self.assertTrue((build/'b.o').exists())
        extra=build/'new.o';extra.write_bytes(b'created after collector death')
        os.utime(extra,(1,1))
        with self.assertRaisesRegex(ValueError,'new entry'):
            w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
        self.assertTrue(extra.exists());extra.unlink()
        w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
        self.assertFalse(build.exists())

    def test_dead_owner_build_is_retained_until_real_reconciliation(self):
        w.start(self.root,'repair',adopt=True)
        ready=self.root/'.cache/tasks/repair/build-ready'
        code=("from pathlib import Path;import time;from gambit_smp import workspace as w\n"
              "root=Path("+repr(str(self.root))+")\n"
              "with w.execution_scope(root,'repair'):\n"
              " build=w.build_output(root,'interrupted',compiler="+repr(shutil.which('cc'))+")\n"
              " (root/'.cache/tasks/repair/build-ready').write_text(str(build))\n time.sleep(30)\n")
        child=subprocess.Popen([sys.executable,'-c',code],stderr=subprocess.PIPE)
        try:
            until=time.monotonic()+10
            while not ready.exists() and time.monotonic()<until:
                if child.poll() is not None:self.fail(child.stderr.read().decode())
                time.sleep(.025)
            self.assertTrue(ready.exists());build=Path(ready.read_text())
            child.kill();child.wait(timeout=5)
            w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
            self.assertTrue(build.exists())
            w.resume(self.root,'repair')
            w.collect_runs(self.root,'repair',today=date(2099,1,1),opened=[])
            self.assertFalse(build.exists())
        finally:
            if child.poll() is None:child.kill();child.wait()
            child.stderr.close()

    def test_seal_api_rejects_source_output_before_inventory(self):
        from unittest.mock import patch
        from gambit_smp import research_kernel
        w.start(self.root,'repair',adopt=True)
        with patch.object(research_kernel,'ROOT',self.root):
            with self.assertRaisesRegex(ValueError,'runtime output'):
                research_kernel.seal(self.root/'vendor/runtime',gcc=Path('/unused'),ascent_api=Path('/unused'))
        self.assertFalse((self.root/'vendor/runtime').exists())
