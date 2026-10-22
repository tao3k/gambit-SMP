"""Real upstream Gambit objects and real Gerbil-driver transport controls.

The driver fixture is explicit: it does not claim full Gerbil/SMP acceptance.
"""
import difflib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest

from gambit_smp import native_capabilities as native, workspace as w
from gambit_smp.framework import digest
from gambit_smp.recipes import ExecutionContext, WorkspaceValidationScope, tree_identity
from tests import test_workspace as fixtures

REPOSITORY = Path(__file__).resolve().parents[1]


def gcc():
    for name in ('gcc-16', 'gcc-15', 'gcc-14', 'gcc'):
        path = shutil.which(name)
        if path:
            result = subprocess.run([path, '--version'], capture_output=True, text=True, check=True)
            if 'gcc' in result.stdout.lower() and 'clang' not in result.stdout.lower():
                return Path(path).resolve()
    raise AssertionError('real GNU GCC required for native adapter tests')


@unittest.skipUnless(sys.platform == 'darwin', 'Darwin developer tool dispatch')
class DarwinNativeToolResolutionTests(unittest.TestCase):
    def test_actual_tools_and_compiler_search_path_have_the_same_identity(self):
        tools,env=native.host_tools(gcc(),[{'capability':'gambit.configure'}],dict(os.environ))
        for name in ('as','ld','make','m4'):
            self.assertNotEqual(Path('/usr/bin'),tools[name].parent)
            self.assertEqual(tools[name],Path(shutil.which(name,path=env['PATH'])).resolve())


class NativeIncrementalAdapterTests(unittest.TestCase):
    validation_domain = {'kind': 'sealed-research', 'budgetSeconds': 240, 'workers': 1,
                         'processesPerWorker': 1}
    setUp = fixtures.WorkspaceTests.setUp

    def lock(self, edited=False):
        name = 'lib/os_thread.c'
        before = subprocess.check_output(['git', '-C', str(self.root / 'vendor/gambit'),
            'show', self.revision + ':' + name]).decode()
        after = ('/* Incremental source identity control. */\n' if edited else '/* Cold source identity control. */\n') + before
        patch = ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
            fromfile='a/' + name, tofile='b/' + name))
        overlay = self.root / 'patches/control.patch'; overlay.parent.mkdir(exist_ok=True); overlay.write_text(patch)
        import hashlib
        lock = dict(schema='gambit-runtime-source-lock.v1', revision=self.revision, submodule='vendor/gambit',
            repository='https://git.cons.io/mighty-gerbils/gambit.git', patch='patches/control.patch',
            patchSha256=digest(overlay), runtimeAdmitted=False, releaseAdmitted=False,
            files={name: dict(baseSha256=hashlib.sha256(before.encode()).hexdigest(),
                             candidateSha256=hashlib.sha256(after.encode()).hexdigest())})
        path = self.root / 'evidence/control.lock.json'; path.parent.mkdir(exist_ok=True)
        path.write_text(json.dumps(lock))

    def build_objects(self, provider='codex', optimization=0):
        with w.execution_scope(self.root, 'repair', provider=provider):
            out = w.task_output(self.root, self.root / '.cache/native-adapter')
            out.mkdir(parents=True)
            names = ['evidence/control.lock.json', 'patches/control.patch']
            receipt = dict(recipe='real-upstream-object-controls', workspacePolicy='in-place',
                inputs={str(self.root / name): digest(self.root / name) for name in names},
                declaredInputs=names, steps=[])
            plan = [dict(id='source', capability='gambit.materialize', arguments=dict(
                sourceLock=names[0], buildWorkspace='gambit-core')),
                dict(id='configure', capability='gambit.configure', arguments=dict(
                    source={'step': 'source', 'output': 'source'}, cOptimization=optimization, rtsOptimization=optimization))]
            scope = WorkspaceValidationScope()
            env = dict(self.tool_environment)
            contexts = []
            try:
                for step, executor in zip(plan, (native.materialize, native.configure)):
                    directory = out / step['id']; directory.mkdir()
                    receipt['steps'].append(step)
                    ctx = ExecutionContext(self.root, out, directory, env, time.monotonic() + 90,
                        {}, receipt, self.tools, workspace_scope=scope)
                    ctx.planned_steps = plan
                    contexts.append(ctx)
                    started = time.monotonic()
                    step.update(executor(step['arguments'], ctx), outcome='PASS')
                    print('UPSTREAM-NATIVE', provider, optimization, step['id'],
                          round(time.monotonic() - started, 3), flush=True)
                    ctx.leased_tree_checks.verify()
                    ctx.workspace_leases.close()
                source = Path(receipt['steps'][0]['sourceDelta']['source'])
                objects = [source / 'lib' / name for name in ('os_thread.o', 'os_shell.o')]
                before = [path.stat().st_mtime_ns if path.exists() else None for path in objects]
                ctx.require('real-native-objects', [self.tools['make'], '-j1', '-C', source / 'lib',
                    'os_thread.o', 'os_shell.o'], source, 60)
                count = sum(old != path.stat().st_mtime_ns for old, path in zip(before, objects))
                w.checkpoint_build_source(source, phase='ready')
                return source, count, receipt['steps'][1]
            except Exception:
                for context in contexts:
                    for name in ('configure.log', 'real-native-objects.log'):
                        path = context.directory / name
                        if path.is_file():print(path.read_text()[-6000:], flush=True)
                raise
            finally:
                for ctx in contexts:ctx.workspace_leases.close()
                scope.close()

    def test_real_upstream_objects_use_the_same_owned_source_across_providers(self):
        self.compiler = gcc()
        self.tools, self.tool_environment = native.host_tools(self.compiler, [{'capability': 'gambit.configure'}],
            dict(PATH=os.environ['PATH'], HOME=str(self.root), LANG='C'))
        (self.root / 'vendor').mkdir()
        subprocess.run(['git', 'clone', '--quiet', '--shared', '--no-checkout',
            str(REPOSITORY / 'vendor/gambit'), str(self.root / 'vendor/gambit')], check=True, capture_output=True)
        self.revision = w.git(self.root / 'vendor/gambit', 'rev-parse', 'HEAD')
        self.lock(); w.start(self.root, 'repair', adopt=True)
        first, count, _ = self.build_objects(); self.assertEqual(2, count)
        inode = first.stat().st_ino
        warm, count, configuration = self.build_objects('grok')
        self.assertEqual(first, warm); self.assertEqual(0, count)
        self.assertTrue(configuration['configurationReuse']['commands'])
        untouched = (first / 'lib/os_shell.o').stat().st_mtime_ns
        self.lock(edited=True)
        changed, count, _ = self.build_objects()
        self.assertEqual(first, changed); self.assertEqual(1, count)
        self.assertEqual(inode, changed.stat().st_ino)
        self.assertEqual(untouched, (changed / 'lib/os_shell.o').stat().st_mtime_ns)
        reconfigured, count, _ = self.build_objects('grok', optimization=1)
        self.assertNotEqual(first, reconfigured); self.assertEqual(2, count)


class GerbilIncrementalAdapterTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp

    def prepare(self):
        self.compiler = gcc()
        self.tools = {name: Path(shutil.which(name)).resolve() for name in ('git', 'make', 'sh', 'tar')}
        self.tools['gcc'] = self.compiler
        self.checkout = self.root / '.data/worktrees/gerbil-input'
        (self.checkout / 'src/gerbil').mkdir(parents=True)
        (self.checkout / 'src/stdlib').mkdir()
        (self.checkout / 'src/bootstrap/gerbil').mkdir(parents=True)
        (self.checkout / 'src/bootstrap/gerbil/module.scm').write_text('int module(void) { return 1; }\n')
        (self.checkout / 'src/gerbil/boot-gxi.c').write_text('int main(void) { return 0; }\n')
        (self.checkout / 'src/core.c').write_text('int main(void) { return 0; }\n')
        (self.checkout / 'src/stdlib/a.c').write_text('int a(void) { return 1; }\n')
        (self.checkout / 'src/stdlib/b.c').write_text('int b(void) { return 2; }\n')
        (self.checkout / 'Makefile').write_text('all: build/lib/a.o build/lib/b.o\ncore: build/bin/gerbil\n'
            'build/bin/gerbil: src/core.c\n\t$(CC) -o $@ $<\n\t@echo core >> compiled.log\n'
            'build/lib/%.o: src/stdlib/%.c\n\t$(CC) -c $< -o $@\n\t@echo $@ >> compiled.log\n')
        (self.checkout / 'src/build.sh').write_text('''#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
case "$1" in
boot-gxi) "$CC" -o src/gerbil/boot-gxi src/gerbil/boot-gxi.c; echo boot-gxi >> compiled.log;;
stage0) "$CC" -c src/core.c -o bootstrap/lib/stage0.o; echo stage0 >> compiled.log;;
stage1) make -j1 core; ln -sf gerbil build/bin/gxi; ln -sf gerbil build/bin/gxc;;
stdlib) make -j1 all;;
libgerbil|lang|tools) make -j1 all;;
*) exit 72;;
esac
''')
        w.git(self.checkout, 'init', '-q'); w.git(self.checkout, 'add', '.')
        w.git(self.checkout, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'real-driver fixture')
        self.revision = w.git(self.checkout, 'rev-parse', 'HEAD')
        self.payload = self.root / 'payload'
        for folder in ('gsi', 'gsc', 'bin', 'lib', 'include'):(self.payload / folder).mkdir(parents=True, exist_ok=True)
        # Real compiled ELF/Mach-O fixture payloads, not an interpreter claim.
        subprocess.run([self.compiler, str(self.checkout / 'src/core.c'), '-o', str(self.payload / 'gsi/gsi')], check=True)
        fixture_compiler = self.payload / 'gsc/gsc'
        fixture_compiler.write_text('''#!/bin/sh
set -eu
output=
previous=
seen_eval=
for item in "$@"; do
  if test "$item" = '-o' && test -n "$seen_eval"; then echo 'misplaced -o after -e' >&2; exit 64; fi
  if test "$item" = '-e'; then seen_eval=1; fi
  if test "$item" = '(write (##current-vm-processor-count))'; then printf 1; exit 0; fi
  if test "$previous" = '-o'; then output="$item"; fi
  previous="$item"
done
"$CC" -x c -c "$previous" -o "$output"
echo stage0 >> "$(dirname "$0")/../../compiled.log"
''')
        fixture_compiler.chmod(0o755)
        (self.payload / 'bin/gambuild-C').write_text('#!/bin/sh\nexit 0\n')
        for name in ('lib/_gambit.c', 'lib/_gambit#.scm', 'lib/_define-syntax.scm', 'include/gambit.h'):
            (self.payload / name).write_text('/* explicit fixture input */\n')
        subprocess.run(['ar', 'rcs', str(self.payload / 'lib/libgambit.a')], check=True)
        self.lock()
        w.start(self.root, 'repair', adopt=True)

    def lock(self, edited=False):
        import hashlib
        before = 'int a(void) { return 1; }\n'
        after = 'int a(void) { return 99; }\n' if edited else before
        lock = dict(schema='gerbil-source-lock.v1', checkout=str(self.checkout.relative_to(self.root)),
            revision=self.revision, runtimeAdmitted=False,
            files={'src/stdlib/a.c': hashlib.sha256(after.encode()).hexdigest()})
        if edited:
            patch = self.root / 'patches/gerbil.patch'; patch.parent.mkdir(exist_ok=True)
            patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                fromfile='a/src/stdlib/a.c', tofile='b/src/stdlib/a.c')))
            lock.update(patch=str(patch.relative_to(self.root)), patchSha256=digest(patch))
        path = self.root / 'evidence/gerbil.lock.json'; path.parent.mkdir(exist_ok=True); path.write_text(json.dumps(lock))

    def build(self, provider='codex', payload_identity='one', *, pause=None, stage_cap=None):
        from gambit_smp.gerbil_build import build
        with w.execution_scope(self.root, 'repair', provider=provider):
            out = w.task_output(self.root, self.root / '.cache/gerbil-adapter'); out.mkdir(parents=True)
            shutil.copytree(self.payload, out / 'runtime')
            if payload_identity != 'one':
                (out / 'runtime/lib/_gambit.c').write_text('/* changed actual runtime source identity */\n')
            runtime = out / 'runtime'
            identity = out / 'identity.json'
            identity.write_text(json.dumps(dict(schema='gambit-recipe-runtime-identity.v1',
                sourceFiles={str(path.relative_to(runtime)): digest(path) for path in runtime.rglob('*')
                    if path.is_file() and path.suffix in {'.c', '.h', '.scm'}},
                binarySha256=digest(runtime / 'gsi/gsi'), gscSha256=digest(runtime / 'gsc/gsc'),
                librarySha256=digest(runtime / 'lib/libgambit.a'), runtimeAdmitted=False, releaseAdmitted=False)))
            names = ['evidence/gerbil.lock.json']
            if (self.root / 'patches/gerbil.patch').exists():names.append('patches/gerbil.patch')
            receipt = dict(recipe='gerbil-driver-controls', workspacePolicy='in-place',
                inputs={str(self.root / name): digest(self.root / name) for name in names}, declaredInputs=names,
                steps=[dict(id='runtime', outcome='PASS', outputs={
                    'runtime': dict(type='source-runtime', path='runtime', identity=tree_identity(out / 'runtime')),
                    'identity': dict(type='runtime-identity', path='identity.json', sha256=digest(identity))})])
            from gambit_smp.research_kernel import retain_run_record
            import uuid
            receipt['journal'] = retain_run_record(self.root,out/'run-header.json','gerbil-driver-controls',
                dict(schema='research-run-header.v1',runId=uuid.uuid4().hex,inputs={}),{})
            directory = out / 'gerbil'; directory.mkdir()
            class ControlledContext(ExecutionContext):
                def require(inner, name, argv, cwd, cap, **kwargs):
                    if name == 'gerbil-stage1' and stage_cap is not None:cap = min(cap, stage_cap)
                    return super().require(name, argv, cwd, cap, **kwargs)
            environment = dict(PATH=os.environ['PATH'], HOME=str(self.root))
            if pause is not None:environment['GERBIL_TEST_PAUSE']=str(pause)
            context = ControlledContext(self.root, out, directory, environment,
                time.monotonic() + 40, {}, receipt, self.tools)
            try:
                result = build(dict(sourceLock=names[0], runtime={'step': 'runtime', 'output': 'runtime'},
                    identity={'step': 'runtime', 'output': 'identity'}), context)
                context.leased_tree_checks.verify()
                return result, context.commands
            finally:
                self.last_commands = context.commands
                self.last_output = directory
                context.workspace_leases.close()

    def test_real_gerbil_driver_transport_reuses_bootstrap_and_invalidates_consumers(self):
        self.prepare()
        cold, commands = self.build()
        source = Path(cold['observation']['workspace']); stamp = (source / 'build/lib/b.o').stat().st_mtime_ns
        lines = (source / 'compiled.log').read_text().splitlines()
        self.assertEqual(5, len(lines))
        warm, commands = self.build('grok')
        self.assertEqual(source, Path(warm['observation']['workspace']))
        self.assertEqual(['boot-gxi', 'stage0', 'stage1'], warm['observation']['bootstrapReused'])
        self.assertEqual(lines, (source / 'compiled.log').read_text().splitlines())
        self.assertEqual(['gerbil-stdlib', 'gerbil-libgerbil', 'gerbil-lang', 'gerbil-tools'],
                         [row['stage'] for row in commands if row['stage'].startswith('gerbil-')
                          and row['stage'] not in {'gerbil-archive','gerbil-extract'}])
        self.lock(edited=True)
        changed, _ = self.build()
        self.assertEqual(source, Path(changed['observation']['workspace']))
        self.assertEqual(6, len((source / 'compiled.log').read_text().splitlines()))
        self.assertEqual(stamp, (source / 'build/lib/b.o').stat().st_mtime_ns)
        configured, _ = self.build('grok', payload_identity='different-Gambit-ABI')
        other = Path(configured['observation']['workspace'])
        self.assertNotEqual(source, other)
        self.assertEqual(5, len((other / 'compiled.log').read_text().splitlines()))

    def test_rewritten_module_receipt_hash_cannot_replace_immutable_completion(self):
        import copy,hashlib
        self.prepare()
        cold,_ = self.build()
        source = Path(cold['observation']['workspace'])
        store = source.parent/'gerbil-stage0-modules.json'
        modules = json.loads(store.read_text())
        proof = modules['module.scm']
        raw = json.loads(proof['receiptBytes'])
        raw['pid'] += 100000
        proof['command']['pid'] = raw['pid']
        proof['receiptBytes'] = json.dumps(raw)
        proof['receiptSha256'] = hashlib.sha256(proof['receiptBytes'].encode()).hexdigest()
        store.write_text(json.dumps(modules))
        stages_path = source.parent/'gerbil-stages.json'
        stages = json.loads(stages_path.read_text())
        stages['stage0']['modules'] = copy.deepcopy(modules)
        stages_path.write_text(json.dumps(stages))
        resumed,commands = self.build('grok')
        self.assertNotIn('stage0',resumed['observation']['bootstrapReused'])
        self.assertEqual(6,len((source/'compiled.log').read_text().splitlines()))
        self.assertTrue(any(row['stage'].startswith('gerbil-stage0-module-') for row in commands))

    def test_changed_bootstrap_alias_requires_the_actual_stage_again(self):
        self.prepare()
        cold, _ = self.build()
        source = Path(cold['observation']['workspace'])
        alias = source / 'build/bin/gxi'
        alias.unlink(); alias.symlink_to('gsc')
        resumed, commands = self.build('grok')
        self.assertNotIn('stage1', resumed['observation']['bootstrapReused'])
        self.assertIn('gerbil-stage1', [row['stage'] for row in commands])
        self.assertEqual('gerbil', str(alias.readlink()))
        self.assertEqual(5, len((source / 'compiled.log').read_text().splitlines()))

    def test_actual_interrupted_gerbil_stage_consumes_completed_bootstrap_receipts(self):
        self.prepare()
        driver = self.checkout / 'src/build.sh'
        driver.write_text(driver.read_text().replace('stage1) make',
            'stage1) while test -n "${GERBIL_TEST_PAUSE:-}" && test -f "$GERBIL_TEST_PAUSE"; do sleep .05; done; make'))
        w.git(self.checkout, 'add', '.')
        w.git(self.checkout, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'explicit interruption fixture')
        self.revision = w.git(self.checkout, 'rev-parse', 'HEAD'); self.lock()
        pause = self.root / '.cache/tasks/repair/pause-stage1'; pause.write_text('controlled fixture stop')
        with self.assertRaises(TimeoutError):self.build(pause=pause, stage_cap=2)
        failed_path = self.last_output / 'gerbil-stage1.process.json'
        failed_bytes = failed_path.read_bytes()
        failed = json.loads(failed_bytes)
        self.assertTrue(failed['timeout']); self.assertNotEqual(0, failed['exit'])
        self.assertTrue(failed['parentReaped'])
        # Darwin can briefly report EPERM while the killed group disappears.
        # Keep that original unknown observation; only a new ESRCH permits
        # reconciliation. This does not extend the timed-out build's budget.
        from gambit_smp.task_processes import observe_group
        deadline = time.monotonic() + 2
        while True:
            group = observe_group(failed['pid'])
            if group['result'] == 'absent' or time.monotonic() >= deadline:break
            time.sleep(.01)
        self.assertEqual('absent', group['result'], group)
        source = next((self.root / '.cache/tasks/repair/build/gerbil').glob('*/source'))
        self.assertEqual(2, len((source / 'compiled.log').read_text().splitlines()))
        proofs = json.loads((source.parent / 'gerbil-stages.json').read_text())
        self.assertEqual({'boot-gxi', 'stage0'}, set(proofs))
        w.resume(self.root, 'repair'); pause.unlink()
        resumed, commands = self.build('grok', stage_cap=2)
        self.assertEqual(str(source), resumed['observation']['workspace'])
        self.assertEqual(['boot-gxi', 'stage0'], resumed['observation']['bootstrapReused'])
        self.assertEqual(5, len((source / 'compiled.log').read_text().splitlines()))
        self.assertEqual(failed_bytes, failed_path.read_bytes())
