"""Real compilation and process interruption; no native repair admission."""
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

from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
from tests import test_workspace as fixtures


class IncrementalBuildWorkspaceTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def inputs(self):
        source = self.root / 'src'
        source.mkdir(exist_ok=True)
        (source / 'a.c').write_text('int a(void) { return 1; }\n')
        (source / 'b.c').write_text('int b(void) { return 2; }\n')
        (source / 'Makefile').write_text('all: a.o b.o\n%.o: %.c\n\t$(CC) $(CFLAGS) -c $< -o $@\n\t@echo $@ >> compiled.log\n')
        return source

    def compile(self, source, *, provider='codex', flags='-O0'):
        cc = shutil.which('cc')
        self.assertIsNotNone(cc)
        with w.execution_scope(self.root, 'repair', provider=provider):
            build = w.build_output(self.root, 'native', compiler=cc, flags=[flags])
            target = build / 'source'; target.mkdir(exist_ok=True)
            with workspace_lease(self.root, target, tree_identity(target)):
                delta = w.sync_build_source(self.root, build, source)
                log = target / 'compiled.log'
                before = log.read_text().splitlines() if log.exists() else []
                self.assertEqual(0, w.execute(self.root, 'repair', [shutil.which('make'), '-j1', '-C',
                    str(target), 'CC=' + cc, 'CFLAGS=' + flags], provider=provider))
                count = len(log.read_text().splitlines()) - len(before)
                w.checkpoint_build_source(target, phase='ready')
                return build, count, delta


    def test_registered_cross_role_reference_reuses_real_objects_and_rejects_other_outputs(self):
        from gambit_smp.work_process import scope
        source=self.inputs()
        w.start(self.root,'repair',adopt=True)
        (self.root/'docs').mkdir(exist_ok=True)
        (self.root/'docs/work-items.json').write_text(json.dumps({
            'schema':'gambit-work-items.v1','items':{'repair':{
                'scope':'repair','processes':{'audit':'maintenance','validation':'maintenance'},
                'buildProducts':{'native':{'owner':'task-or-registered-process'}}}}}))
        build,count,_=self.compile(source,provider='codex')
        self.assertEqual(2,count)
        target=build/'source';inode=target.stat().st_ino
        objects={name:(target/name).read_bytes() for name in ['a.o','b.o']}
        with scope(self.root,'repair','audit'):
            self.assertEqual(target,w.owned_build_reference(self.root,target,'native'))
            with workspace_lease(self.root,target,tree_identity(target)):
                self.assertEqual(0,w.execute(self.root,'repair',[shutil.which('make'),'-j1','-C',
                    str(target),'CC='+shutil.which('cc'),'CFLAGS=-O0'],provider='grok'))
            self.assertEqual(2,len((target/'compiled.log').read_text().splitlines()))
            self.assertEqual(inode,target.stat().st_ino)
            self.assertEqual(objects,{name:(target/name).read_bytes() for name in objects})
            # Build references do not relax ordinary output ownership.
            with self.assertRaises(ValueError):w.task_output(self.root,target)
            for invalid in [self.root/'.cache/tasks/other/build/native'/build.name/'source',
                    self.root/'.cache/tasks/repair/runs/old/outputs/source',
                    self.root/'.cache/tasks/repair/processes/unregistered/build/native'/build.name/'source']:
                with self.assertRaises(ValueError):w.owned_build_reference(self.root,invalid,'native')
        with w.execution_scope(self.root,'repair'):
            config=json.loads((build/'configuration.json').read_text())
            config['flags']=['untrusted-change']
            w.write(build/'configuration.json',config)
        with scope(self.root,'repair','audit'):
            with self.assertRaisesRegex(ValueError,'configuration identity'):
                w.owned_build_reference(self.root,target,'native')

    def test_failed_make_generated_link_recovery_preserves_objects_and_strict_artifact_checks(self):
        self.generated_link_recovery()

    def test_generated_link_recovery_does_not_overwrite_source_drift(self):
        self.generated_link_recovery('drift')

    def test_generated_link_recovery_resumes_after_deletion_interruption(self):
        self.generated_link_recovery('interrupt')

    def generated_link_recovery(self,failure=None):
        source=self.inputs()
        with (source/'Makefile').open('a') as stream:
            stream.write('fail:\n\tmkdir -p bin\n\tln -s ../missing-tool bin/tool\n\tfalse\n')
        w.start(self.root,'repair',adopt=True)
        (self.root/'docs').mkdir()
        (self.root/'docs/work-items.json').write_text(json.dumps({
            'schema':'gambit-work-items.v1','items':{'repair':{'scope':'repair','buildProducts':{
                'native':{'recoveryLinks':{'bin/tool':'../missing-tool'}}}}}}))
        cc=shutil.which('cc')
        with w.execution_scope(self.root,'repair'):
            build=w.build_output(self.root,'native',compiler=cc)
            target=build/'source';target.mkdir()
            with workspace_lease(self.root,target,tree_identity(target)):
                w.sync_build_source(self.root,build,source)
                self.assertEqual(w.execute(self.root,'repair',[shutil.which('make'),'-C',str(target),'CC='+cc]),0)
                self.assertEqual(w.execute(self.root,'repair',[shutil.which('make'),'-C',str(target),'fail']),2)
        objects={name:(target/name).read_bytes() for name in ('a.o','b.o')}
        inode=target.stat().st_ino
        with self.assertRaisesRegex(ValueError,'unresolved symlink'):tree_identity(target)
        if failure=='drift':
            (target/'a.c').write_text('user modification must not be overwritten')
            with self.assertRaisesRegex(ValueError,'source drift'), w.execution_scope(self.root,'repair',provider='grok'):
                state=json.loads((build/'source-state.json').read_text())
                links=w.build_source_links(self.root,build,state)
                with workspace_lease(self.root,target,tree_identity(target,broken_links=links),broken_links=links):
                    w.sync_build_source(self.root,build,source)
            self.assertTrue((target/'bin/tool').is_symlink())
            self.assertEqual((target/'a.c').read_text(),'user modification must not be overwritten')
            return
        if failure=='interrupt':
            from unittest.mock import patch
            original=Path.unlink
            def cut(path,*args,**kwargs):
                result=original(path,*args,**kwargs)
                if path==target/'bin/tool':raise RuntimeError('interrupted after alias deletion')
                return result
            with self.assertRaisesRegex(RuntimeError,'after alias deletion'), w.execution_scope(self.root,'repair',provider='grok'):
                state=json.loads((build/'source-state.json').read_text())
                links=w.build_source_links(self.root,build,state)
                with workspace_lease(self.root,target,tree_identity(target,broken_links=links),broken_links=links), patch.object(Path,'unlink',cut):
                    w.sync_build_source(self.root,build,source)
            self.assertEqual(json.loads((build/'source-state.json').read_text())['phase'],'updating')
            w.resume(self.root,'repair')
        with w.execution_scope(self.root,'repair',provider='grok'):
            state=json.loads((build/'source-state.json').read_text())
            links=w.build_source_links(self.root,build,state)
            with workspace_lease(self.root,target,tree_identity(target,broken_links=links),broken_links=links):
                result=w.sync_build_source(self.root,build,source)
                self.assertEqual(result['retiredGeneratedLinks'],{'bin/tool':'../missing-tool'})
                self.assertEqual(result['changed'],[])
                self.assertEqual(w.execute(self.root,'repair',[shutil.which('make'),'-C',str(target),'CC='+cc]),0)
        self.assertEqual(target.stat().st_ino,inode)
        self.assertFalse((target/'bin/tool').is_symlink())
        self.assertEqual(objects,{name:(target/name).read_bytes() for name in objects})
        self.assertEqual((target/'compiled.log').read_text().splitlines(),['a.o','b.o'])
        self.assertEqual(json.loads((build/'source-state.json').read_text())['retiredGeneratedLinks'],{'bin/tool':'../missing-tool'})

    def test_two_providers_real_cold_noop_source_edit_and_configuration_invalidation(self):
        source = self.inputs()
        w.start(self.root, 'repair', adopt=True)
        cold, count, _ = self.compile(source)
        self.assertEqual(2, count)
        inode = (cold / 'source').stat().st_ino
        warm, count, delta = self.compile(source, provider='grok')
        self.assertEqual(cold, warm); self.assertEqual(0, count); self.assertEqual([], delta['changed'])
        other_object = (warm / 'source/b.o').stat().st_mtime_ns
        (source / 'a.c').write_text('int a(void) { return 42; }\n')
        edited, count, delta = self.compile(source)
        self.assertEqual(cold, edited); self.assertEqual(1, count)
        self.assertEqual(['a.c'], delta['changed'])
        self.assertEqual(inode, (edited / 'source').stat().st_ino)
        self.assertEqual(other_object, (edited / 'source/b.o').stat().st_mtime_ns)
        changed, count, _ = self.compile(source, provider='grok', flags='-O1')
        self.assertNotEqual(cold, changed); self.assertEqual(2, count)

    def test_sync_retains_regeneration_and_fixture_transfer_custody(self):
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        build, _, _ = self.compile(source)
        with w.execution_scope(self.root, 'repair', provider='codex'):
            target = build / 'source'
            with workspace_lease(self.root, target, tree_identity(target)):
                w.checkpoint_build_source(target, regeneration={'receipt': 'actual-command'},
                    additionalFixtures={'tests/unit-tests/extra.scm': 'exact-bytes'})
                w.sync_build_source(self.root, build, source)
                state = json.loads((build / 'source-state.json').read_text())
                self.assertEqual({'receipt': 'actual-command'}, state['regeneration'])
                self.assertEqual({'tests/unit-tests/extra.scm': 'exact-bytes'}, state['additionalFixtures'])

    def test_managed_fixture_reuse_requires_exact_transfer_custody(self):
        from types import SimpleNamespace
        from gambit_smp.native_capabilities import additional_fixtures
        from gambit_smp.framework import digest
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        build, _, _ = self.compile(source)
        authored = self.root / 'models/extra.scm'; authored.parent.mkdir()
        authored.write_text('(display "fixture")')
        args = {'additionalFixtures': {'extra.scm': {
            'source': 'models/extra.scm', 'sha256': digest(authored)}}}
        runtime = build / 'source'; unit = runtime / 'tests/unit-tests'
        ctx = SimpleNamespace(root=self.root, leased_workspaces={runtime}, bind=lambda paths: None)
        with w.execution_scope(self.root, 'repair', provider='grok'):
            with workspace_lease(self.root, runtime, tree_identity(runtime)):
                additional_fixtures(args, ctx, unit)
                target = unit / 'extra.scm'; before = target.stat()
                additional_fixtures(args, ctx, unit)
                self.assertEqual(before.st_mtime_ns, target.stat().st_mtime_ns)
                self.assertEqual(before.st_ino, target.stat().st_ino)
                target.write_text('unreviewed change')
                with self.assertRaisesRegex(ValueError, 'cannot replace'):
                    additional_fixtures(args, ctx, unit)
                self.assertEqual('unreviewed change', target.read_text())
                (unit / 'unknown.scm').write_bytes(authored.read_bytes())
                args['additionalFixtures']['unknown.scm'] = args['additionalFixtures'].pop('extra.scm')
                with self.assertRaisesRegex(ValueError, 'cannot replace'):
                    additional_fixtures(args, ctx, unit)

    def test_unreviewed_input_drift_is_rejected_without_overwriting_it(self):
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        build, _, _ = self.compile(source)
        target = build / 'source/a.c'; target.write_text('unreviewed mutation')
        with self.assertRaisesRegex(ValueError, 'source drift'):
            self.compile(source, provider='grok')
        self.assertEqual('unreviewed mutation', target.read_text())

    def test_real_exit_during_source_delta_recovers_only_its_recorded_transition(self):
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        build, _, _ = self.compile(source)
        (source / 'a.c').write_text('int a(void) { return 7; }\n')
        (source / 'b.c').write_text('int b(void) { return 8; }\n')
        code = '''import os,sys,shutil
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path(sys.argv[1])
with w.execution_scope(root,'repair'):
 build=w.build_output(root,'native',compiler=sys.argv[2],flags=['-O0'])
 target=build/'source'
 with workspace_lease(root,target,tree_identity(target)):
  original=shutil.copyfile
  def cut(before,after,*args,**kwargs):
   result=original(before,after,*args,**kwargs)
   if Path(after).name=='a.c':os._exit(91)
   return result
  shutil.copyfile=cut
  w.sync_build_source(root,build,root/'src')
'''
        result = subprocess.run([sys.executable, '-c', code, str(self.root), shutil.which('cc')], capture_output=True)
        self.assertEqual(91, result.returncode, result.stderr.decode())
        self.assertIn('return 7', (build / 'source/a.c').read_text())
        self.assertIn('return 2', (build / 'source/b.c').read_text())
        self.assertEqual('updating', json.loads((build / 'source-state.json').read_text())['phase'])
        w.resume(self.root, 'repair')
        resumed, count, delta = self.compile(source, provider='grok')
        self.assertEqual(build, resumed); self.assertEqual(2, count)
        self.assertEqual('updating', delta['interruptedPhase'])

    def test_task_plan_admits_only_its_registered_build_products(self):
        (self.root / 'docs').mkdir()
        (self.root / 'docs/work-items.json').write_text(json.dumps(dict(schema='gambit-work-items.v1',
            items={'repair': dict(scope='repair', processes={}, buildProducts={'native': {}})})))
        w.start(self.root, 'repair', adopt=True)
        for provider in ('codex', 'grok'):
            with w.execution_scope(self.root, 'repair', provider=provider):
                with self.assertRaisesRegex(ValueError, 'not registered'):
                    w.build_output(self.root, 'native-2', compiler=shutil.which('cc'))

    def test_real_exit_during_cold_transfer_preserves_authored_inputs_and_can_resume(self):
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        code = '''import os,sys,shutil
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path(sys.argv[1])
with w.execution_scope(root,'repair'):
 staged=w.task_output(root,root/'.cache/cold-staging')
 shutil.copytree(root/'src',staged)
 build=w.build_output(root,'native',compiler=sys.argv[2],flags=['-O0'])
 target=build/'source';target.mkdir()
 with workspace_lease(root,target,tree_identity(target)):
  original=Path.rename
  def cut(before,after):
   result=original(before,after)
   os._exit(92)
  Path.rename=cut
  w.sync_build_source(root,build,staged,consume_staged=True)
'''
        result = subprocess.run([sys.executable, '-c', code, str(self.root), shutil.which('cc')], capture_output=True)
        self.assertEqual(92, result.returncode, result.stderr.decode())
        self.assertEqual({'a.c', 'b.c', 'Makefile'}, {path.name for path in source.iterdir()})
        build = next((self.root / '.cache/tasks/repair/build/native').iterdir())
        self.assertEqual(1, len(list((build / 'source').iterdir())))
        state = json.loads((build / 'source-state.json').read_text())
        self.assertEqual('updating', state['phase']); self.assertEqual({}, state['inputs'])
        w.resume(self.root, 'repair')
        resumed, count, _ = self.compile(source, provider='grok')
        self.assertEqual(build, resumed); self.assertEqual(2, count)

    def test_real_killed_supervisor_keeps_completed_object_and_live_child_blocks_reuse(self):
        source = self.inputs(); w.start(self.root, 'repair', adopt=True)
        # Stop before b.o is compiled. a.o has been produced by the real C compiler.
        wait = "import pathlib,time; p=pathlib.Path('waiting'); p.write_text('ready'); time.sleep(30)"
        (source / 'Makefile').write_text('all: a.o b.o\na.o: a.c\n\t$(CC) -c a.c -o a.o\n\t@echo a.o >> compiled.log\n'
            'b.o: b.c\n\t' + sys.executable + ' -c ' + repr(wait) + '\n\t$(CC) -c b.c -o b.o\n\t@echo b.o >> compiled.log\n')
        cc, make = shutil.which('cc'), shutil.which('make')
        code = '''import json,sys
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path(sys.argv[1])
with w.execution_scope(root,'repair',provider='codex'):
 build=w.build_output(root,'native',compiler=sys.argv[2],flags=['-O0'])
 target=build/'source';target.mkdir(exist_ok=True)
 with workspace_lease(root,target,tree_identity(target)):
  w.sync_build_source(root,build,root/'src')
  print(str(build),flush=True)
  w.execute(root,'repair',[sys.argv[3],'-j1','-C',str(target),'CC='+sys.argv[2]])
'''
        child = subprocess.Popen([sys.executable, '-c', code, str(self.root), cc, make],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        pgid = None
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(child.stdout, selectors.EVENT_READ)
                self.assertTrue(selector.select(timeout=20))
            build = Path(child.stdout.readline().strip()); target = build / 'source'
            until = time.monotonic() + 15
            while not (target / 'waiting').exists() and time.monotonic() < until:
                self.assertIsNone(child.poll()); time.sleep(.025)
            self.assertTrue((target / 'waiting').exists())
            self.assertTrue((target / 'a.o').is_file()); self.assertFalse((target / 'b.o').exists())
            stamp = (target / 'a.o').stat().st_mtime_ns
            owner = json.loads(w.paths(self.root, 'repair')[0].read_text())
            records = list((self.root / '.state/task-processes/repair' / owner['run']).glob('*.json'))
            native = [json.loads(path.read_text()) for path in records]
            pgid = next(row['pgid'] for row in native if row.get('event') == 'started')
            child.kill(); child.wait(timeout=5)
            with self.assertRaises((ValueError, BlockingIOError)):
                w.resume(self.root, 'repair')
            os.killpg(pgid, signal.SIGTERM)
            until = time.monotonic() + 15
            from gambit_smp.task_processes import observe_group
            while observe_group(pgid)['result'] != 'absent' and time.monotonic() < until:
                time.sleep(.025)
            self.assertEqual('absent', observe_group(pgid)['result'])
            pgid = None
            w.resume(self.root, 'repair')
            # Keep the same source bytes; only the test's wait request is released.
            (source / 'Makefile').write_text((source / 'Makefile').read_text().replace(
                sys.executable + ' -c ' + repr(wait), 'true'))
            resumed, count, delta = self.compile(source, provider='grok')
            self.assertEqual(build, resumed); self.assertEqual(1, count)
            self.assertEqual(stamp, (target / 'a.o').stat().st_mtime_ns)
            old = json.loads((self.root / '.state/task-runs/repair' / (owner['run'] + '.json')).read_text())
            self.assertEqual('interrupted', old['state']); self.assertIn('reconciliation', old)
            self.assertEqual('building', delta['interruptedPhase'])
        finally:
            if child.poll() is None:child.kill(); child.wait()
            if pgid is not None:
                try:os.killpg(pgid, signal.SIGKILL)
                except ProcessLookupError:pass
            child.stdout.close(); child.stderr.close()

    def test_real_exit_with_a_pending_internal_alias_is_completed_from_recorded_bytes(self):
        source=self.root/'src';source.mkdir()
        (source/'zz.c').write_text('int value(void){return 1;}\n')
        (source/'alias').symlink_to('zz.c')
        w.start(self.root,'repair',adopt=True)
        code='''import os,sys,shutil
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path(sys.argv[1])
with w.execution_scope(root,'repair',provider='codex'):
 build=w.build_output(root,'native',compiler=sys.argv[2])
 target=build/'source';target.mkdir()
 with workspace_lease(root,target,tree_identity(target)):
  def stop(*args,**kwargs):os._exit(93)
  shutil.copyfile=stop
  w.sync_build_source(root,build,root/'src')
'''
        result=subprocess.run([sys.executable,'-c',code,str(self.root),shutil.which('cc')],capture_output=True)
        self.assertEqual(93,result.returncode,result.stderr.decode())
        build=next((self.root/'.cache/tasks/repair/build/native').iterdir());target=build/'source'
        self.assertTrue((target/'alias').is_symlink());self.assertFalse((target/'alias').exists())
        state=json.loads((build/'source-state.json').read_text())
        self.assertEqual('zz.c',state['pending']['alias']['link'])
        w.resume(self.root,'repair')
        with w.execution_scope(self.root,'repair',provider='grok'):
            from gambit_smp.recipes import ExecutionContext
            out=w.task_output(self.root,self.root/'.cache/resume-alias');out.mkdir(parents=True)
            ctx=ExecutionContext(self.root,out,out,{},time.monotonic()+20,{}, {},{})
            links={'alias':'zz.c'}
            try:
                ctx.lease_workspace(target,tree_identity(target,broken_links=links),broken_links=links)
                w.sync_build_source(self.root,build,source)
                self.assertEqual(tree_identity(source),tree_identity(target))
                ctx.leased_tree_checks.verify()
            finally:ctx.workspace_leases.close()


class RegenerationContinuationTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def test_real_make_timeout_resumes_after_completed_bootclean_without_deleting_partial_work(self):
        from gambit_smp.framework import execute
        from gambit_smp.gambit_build_primitives import rebuild_source_core
        source = self.root / 'src'
        for folder in ('lib', 'gsi', 'gsc'):(source / folder).mkdir(parents=True, exist_ok=True)
        # This is C text in a .scm-named transport fixture, not Scheme validation.
        (source / 'lib/_unit.scm').write_text('int unit(void) { return 7; }\n')
        (source / 'lib/_unit.c').write_text((source / 'lib/_unit.scm').read_text())
        (source / 'main.c').write_text('int main(void) { return 0; }\n')
        (source / 'Makefile').write_text('core: gsi/gsi gsc/gsc lib/libgambit.a\n'
            'gsi/gsi: main.c\n\t$(CC) main.c -o $@\n'
            'gsc/gsc: gsi/gsi\n\tcp $< $@\n'
            'lib/_unit.c: lib/_unit.scm\n\t@while test ! -f allow; do sleep .05; done\n\tcp $< $@\n'
            'lib/unit.o: lib/_unit.c\n\t$(CC) -c $< -o $@\n'
            'lib/libgambit.a: lib/unit.o\n\tar rcs $@ $<\n'
            'bootclean:\n\trm -f lib/_unit.c lib/unit.o lib/libgambit.a\n')
        w.start(self.root, 'repair', adopt=True)
        proof, calls = {}, []
        class Stages:
            progress_mode = False
            def run(inner, name, argv, cwd, cap, **kwargs):
                metadata = {}
                result = execute(argv, cwd, cap, metadata=metadata)
                calls.append((name, result, metadata))
                return result
        with w.execution_scope(self.root, 'repair', provider='codex'):
            build = w.build_output(self.root, 'gambit-core', compiler=shutil.which('cc'))
            target = build / 'source'; target.mkdir(exist_ok=True)
            with workspace_lease(self.root, target, tree_identity(target)):
                w.sync_build_source(self.root, build, source, mutable=['lib/_unit.c'])
                (target / 'allow').touch()
                self.assertEqual(0, w.execute(self.root, 'repair', ['make', '-j1', '-C', str(target), 'core']))
                (target / 'allow').unlink()
                def retain(data):
                    proof.update(data)
                    w.write(build / 'regeneration-checkpoint.json', data)
                ok, failed = rebuild_source_core(Stages(), target, 2, checkpoint=retain)
                self.assertFalse(ok)
                self.assertTrue(calls[-1][1][2])
                self.assertTrue(calls[-1][2]['parentReaped'])
                # Preserve an immediate unknown/denied kernel observation;
                # reconciliation needs a separate, actual absence probe.
                from gambit_smp.task_processes import observe_group
                deadline = time.monotonic() + 2
                while True:
                    group = observe_group(calls[-1][2]['pid'])
                    if group['result'] == 'absent' or time.monotonic() >= deadline:break
                    time.sleep(.01)
                self.assertEqual('absent', group['result'], group)
                self.assertTrue(proof['generatedSources'])
        with w.execution_scope(self.root, 'repair', provider='grok'):
            self.assertEqual(build, w.build_output(self.root, 'gambit-core', compiler=shutil.which('cc')))
            with workspace_lease(self.root, target, tree_identity(target)):
                (target / 'allow').touch()
                retained = json.loads((build / 'regeneration-checkpoint.json').read_text())
                ok, observed = rebuild_source_core(Stages(), target, 2, incremental=True, retained_generation=retained)
                self.assertTrue(ok)
                self.assertEqual('incremental', observed['generationMode'])
                self.assertEqual(1, sum(name == 'bootclean' for name, _, _ in calls))
                self.assertEqual(3, len(observed['artifacts']))


class IncrementalLaunchPolicyTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def test_gc_ffi_inventory_reuses_the_qualified_runtime_with_host_capacity(self):
        from gambit_smp.recipes import load
        from gambit_smp.research_kernel import require_incremental_builds
        root = Path(__file__).resolve().parents[1]
        recipe, steps = load(root, root / 'evidence/research/ci/bazel-profile-gc-ffi-inventory.recipe.json')
        require_incremental_builds(recipe, steps)
        runtime = next(step for step in steps if step['id'] == 'runtime')
        descriptor = runtime['arguments']['archive']
        self.assertIn(descriptor, recipe['inputs'])
        self.assertIn('producerEngine', json.loads((root / descriptor).read_text()))
        suites = [step for step in steps if step['capability'] == 'gambit.suite']
        self.assertEqual({'stress-gsi', 'stress-gsc', 'pr-gsi', 'pr-gsc'},
                         {step['id'] for step in suites})
        for step in suites:
            self.assertNotIn('processors', step['arguments'])
            self.assertEqual(1, step['arguments']['jobs'])
            self.assertEqual(step['arguments']['selection'], step['arguments']['expectedFiles'])
            if step['id'].startswith('stress-'):
                self.assertEqual(3600, step['budgetSeconds'])

    def test_new_native_and_gerbil_declarations_use_the_existing_managed_path(self):
        from gambit_smp.recipes import load
        from gambit_smp.research_kernel import require_incremental_builds
        root = Path(__file__).resolve().parents[1]
        paths = [root / 'evidence/research/ci/three-flag-core.recipe.json',
                 *sorted((root / 'evidence/research/incremental-builds').glob('*.recipe.json'))]
        self.assertGreaterEqual(len(paths), 4)
        for path in paths:
            recipe, steps = load(root, path)
            require_incremental_builds(recipe, steps)
            self.assertEqual('in-place', recipe['workspacePolicy'])

    def test_legacy_isolated_and_unpartitioned_configuration_cannot_launch(self):
        from gambit_smp.research_kernel import require_incremental_builds
        source = dict(id='source', capability='gambit.materialize', arguments={'sourceLock': 'source.lock.json'})
        configure = dict(id='configure', capability='gambit.configure',
                         arguments={'source': {'step':'source','output':'source'}})
        with self.assertRaisesRegex(ValueError, 'incremental workspace'):
            require_incremental_builds({'workspacePolicy':'isolated'}, [source, configure])
        source['arguments']['workspace'] = '.cache/fixtures/previous/source'
        with self.assertRaisesRegex(ValueError, 'incremental workspace'):
            require_incremental_builds({'workspacePolicy':'in-place'}, [source, configure])

    def test_import_and_completed_runtime_cannot_reintroduce_isolated_attempt_copies(self):
        from gambit_smp.research_kernel import require_incremental_builds
        for capability in ('gambit.runtime-import', 'gambit.completed-runtime'):
            steps = [dict(id='runtime', capability=capability)]
            for recipe in ({}, {'workspacePolicy': 'isolated'}):
                with self.assertRaisesRegex(ValueError, 'runtime reuse requires in-place'):
                    require_incremental_builds(recipe, steps)
            require_incremental_builds({'workspacePolicy': 'in-place'}, steps)

    def test_legacy_python_recipe_runner_also_refuses_before_creating_an_attempt(self):
        from gambit_smp import recipes
        from unittest.mock import patch
        source = dict(id='source', capability='gambit.materialize', arguments={'sourceLock':'lock.json'})
        configure = dict(id='configure', capability='gambit.configure',
                         arguments={'source':{'step':'source','output':'source'}})
        out = self.root / '.cache/forbidden-cold-attempt'
        with patch.object(recipes, 'load', return_value=(
                dict(schema='evidence-recipe.v1', workspacePolicy='isolated'), [source, configure])):
            with self.assertRaisesRegex(ValueError, 'incremental workspace'):
                recipes.run(self.root, self.root/'old.recipe.json', out, None, None, allow_native=True)
        self.assertFalse(out.exists())

    def test_bootstrap_reuse_requires_actual_receipt_and_output_bytes(self):
        from gambit_smp.gerbil_build import _current
        file = self.root / 'actual';file.write_bytes(b'observed output')
        from gambit_smp.framework import digest
        self.assertFalse(_current(self.root, {'outputs': {'actual': digest(file)},
            'inputsSha256':'same', 'success': True, 'modelPassed': True}, 'same'))

    def test_interrupted_process_does_not_inherit_a_previous_zero_exit(self):
        from gambit_smp import work_process
        w.start(self.root, 'repair', adopt=True)
        with work_process.scope(self.root, 'repair', 'audit') as (owner, _, _):owner['exit']=0
        with self.assertRaises(subprocess.TimeoutExpired):
            with work_process.scope(self.root, 'repair', 'audit'):
                w.execute(self.root, 'repair', [sys.executable, '-c', 'import time;time.sleep(10)'], wall_seconds=.1)
        owner = json.loads(work_process.paths(self.root, 'repair', 'audit')[0].read_text())
        receipt = json.loads(work_process.run_path(self.root, 'repair', 'audit', owner['run']).read_text())
        self.assertEqual('interrupted', receipt['state']); self.assertTrue(receipt['timedOut'])
        self.assertNotEqual(0, receipt['exit']); self.assertTrue(receipt['parentReaped'])

    def test_authored_migration_carries_lineage_without_restoring_any_stage(self):
        from gambit_smp.framework import digest
        from gambit_smp.recipes import checked_build_migration
        evidence=self.root/'evidence';evidence.mkdir()
        original=evidence/'old.recipe.json';original.write_text(json.dumps({'id':'old'}))
        target=evidence/'new.recipe.json';target.write_text('{}')
        migration=evidence/'migration.json'
        migration.write_text(json.dumps(dict(schema='incremental-build-migration.v1', task='repair',
            protectedExistingDeclarations={'evidence/old.recipe.json':digest(original)},
            allowedSuccessors={'old':['evidence/new.recipe.json']})))
        recipe=dict(id='new', buildMigration='evidence/migration.json')
        previous=dict(recipe='old', inputs={'evidence/old.recipe.json':digest(original)})
        result=checked_build_migration(self.root,target,recipe,previous)
        self.assertEqual([],result['restoredStages']);self.assertFalse(result['runtimeAdmitted'])
        original.write_text(original.read_text()+'\n')
        with self.assertRaisesRegex(ValueError,'original build declaration changed'):
            checked_build_migration(self.root,target,recipe,previous)
