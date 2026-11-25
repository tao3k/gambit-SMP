import json
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp.gambit_build_primitives import scheme_inputs
from gambit_smp import make_lineage
from gambit_smp.task_processes import run as task_run


EMITTER = r"""
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
    char output[128];
    const char *input = argv[argc - 1];
    if (strlen(input) < 5 || strlen(input) >= sizeof(output)) return 2;
    strcpy(output, input);
    strcpy(output + strlen(output) - 4, ".c");
    const char *destination = output;
    for (int i = 1; i + 1 < argc; ++i)
        if (!strcmp(argv[i], "-o")) destination = argv[i + 1];
    FILE *in = fopen(input, "rb");
    FILE *out = fopen(destination, "wb");
    if (!in || !out) return 3;
    int byte;
    while ((byte = fgetc(in)) != EOF) if (fputc(byte, out) == EOF) return 4;
    return fclose(in) || fclose(out);
}
"""


@contextmanager
def fixture_execution(root, task):
    from gambit_smp import workspace
    inherited = workspace.inherited_lease

    def selected_lease(selected_root, selected_task):
        # A foreign outer descriptor cannot authorize this temporary repo.
        # Select fresh acquisition instead. Once acquired, every fixture
        # lookup uses the real validator, descriptor and owner/run records.
        if (Path(selected_root).resolve() == root and selected_task == task
                and os.environ.get('GAMBIT_SMP_TASK_ROOT') != str(root)):
            return None
        return inherited(selected_root, selected_task)

    with patch.object(workspace, 'inherited_lease', side_effect=selected_lease):
        with workspace.execution_scope(root, task):
            environment = dict(os.environ)
            environment.pop('GAMBIT_SMP_TASK_PROCESS', None)
            with patch.dict(os.environ, environment, clear=True):
                yield


@unittest.skipUnless(all(shutil.which(tool) for tool in ("make", "cc", "ar", "ranlib")),
                     "Make and native fixture tools are required")
class MakeLineageTests(unittest.TestCase):
    @classmethod
    def _default_cc(cls):
        if os.environ.get("GAMBIT_TEST_CC"):
            return Path(os.environ["GAMBIT_TEST_CC"]).resolve()
        for name in ("gcc-16", "gcc-15", "gcc-14", "gcc", "cc"):
            path = shutil.which(name)
            if path:
                out = subprocess.run([path, "--version"], capture_output=True, text=True)
                if out.returncode == 0 and "gcc" in out.stdout.lower() and "clang" not in out.stdout.lower():
                    return Path(path).resolve()
        return Path(shutil.which("cc")).resolve()

    @classmethod
    def setUpClass(cls):
        from gambit_smp.native_capabilities import host_tools
        compiler = cls._default_cc()
        environment = {key: value for key, value in os.environ.items()
                       if key not in {'SDKROOT', 'LIBRARY_PATH', 'CPATH'}}
        _, environment = host_tools(compiler, [{'capability': 'gambit.bootstrap'}], environment)
        # Use the production resolver: an ambient package-manager ld/as must
        # not replace the selected Darwin toolchain in the transport fixture.
        selected = patch.dict(os.environ, environment, clear=True)
        selected.start()
        cls.addClassCleanup(selected.stop)

    def setUp(self):
        work = tempfile.TemporaryDirectory()
        self.addCleanup(work.cleanup)
        self.directory = Path(work.name).resolve()
        self.source = self.directory / "source"
        self.source.mkdir()
        self.cc = self._default_cc()
        flags = os.environ.get("GAMBIT_TEST_CFLAGS", "")
        hooks = "\n".join(line for line in Path("vendor/gambit/gsc/makefile.in").read_text().splitlines()
                          if line.startswith(("WITNESS_", "GAMBIT_WITNESS_PASS")))
        for unit in ("lib", "gsi", "gsc"):
            (self.source / unit).mkdir()
            (self.source / unit / "makefile").write_text(hooks + "\n" + f"""
CC := {self.cc}
.SECONDARY:
BUILD_OBJ_INPUT_FILENAMES_PARAM = $*.c
BUILD_OBJ_OUTPUT_FILENAME_PARAM = $@
%.c: %.scm
	$(WITNESS_EMIT) ../gsc-boot -f -c $<
%.o: %.c
	$(WITNESS_OBJECT) $(CC) {flags} -D___LIBRARY -D___PRIMAL -c -o $(BUILD_OBJ_OUTPUT_FILENAME_PARAM) $(BUILD_OBJ_INPUT_FILENAMES_PARAM)
""")
        (self.source / "makefile").write_text("all:\n")
        (self.source / "seed.c").write_text(EMITTER)
        task_run([self.cc, "seed.c", "-o", "gsc-boot"], cwd=self.source, check=True)
        (self.source / "gsi/_gsi.scm").write_text(
            '#include "entry.h"\nint main(void) { return EXIT_VALUE; }\n')
        (self.source / "gsi/entry.h").write_text("#define EXIT_VALUE 0\n")
        (self.source / "gsc/_gsc.scm").write_text(EMITTER)
        (self.source / "lib/_gambit.scm").write_text("int gambit_fixture(void) { return 0; }\n")
        for unit in ("gsi", "gsc"):
            with (self.source / unit / "makefile").open("a") as f:
                f.write(f"""
{unit}: _{unit}.o ../lib/libgambit.a
	$(WITNESS_LINK) $(CC) -o $@ $^
""")
        promotion = next(line for line in Path("vendor/gambit/gsc/makefile.in").read_text().splitlines()
                         if "GAMBIT_WITNESS_PASS) promote" in line)
        with (self.source / "gsc/makefile").open("a") as f:
            f.write("\nrootfromhere = ..\nEXECUTABLE = gsc\npromote: gsc\n"
                    "\tcp gsc ../gsc-boot\n" + promotion + "\n")
        with (self.source / "lib/makefile").open("a") as f:
            f.write("""
LIBRARY_OBJECTS = _gambit.o
libgambit.a: $(LIBRARY_OBJECTS)
	$(WITNESS_ARCHIVE) ar rc $@ $^
	$(WITNESS_INDEX) ranlib $@
""")
        top = Path("vendor/gambit/makefile.in").read_text().split("from-scratch: fake_target\n", 1)[1]
        (self.source / "makefile").write_text(
            "from-scratch: fake_target\n" + top.split("\n\n", 1)[0] + "\n"
            """
fake_target:
bootclean:
	rm -f lib/*.c lib/*.o lib/*.a gsi/*.c gsi/*.o gsi/gsi gsc/*.c gsc/*.o gsc/gsc
core:
	$(MAKE) -C lib libgambit.a
	$(MAKE) -C gsi gsi
	$(MAKE) -C gsc gsc
bootstrap: core
	$(MAKE) -C gsc promote
""")
        self.generated = ["gsi/_gsi.c", "gsc/_gsc.c", "lib/_gambit.c"]
        self.lineage = self.directory / "make-lineage"
        self.witness = make_lineage.prepare(self.lineage, self.source, self.generated,
                                           self.cc, scheme_inputs(self.source))

    def make(self, unit, target, pass_number=1, *, success=True, force=False):
        result = task_run(["make", *(["-B"] if force else []), self.witness,
                                 f"GAMBIT_WITNESS_PASS={pass_number}", target],
                                cwd=self.source / unit, capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_seed_replacement_is_refused_without_a_generated_edge(self):
        boot = self.source / "gsc-boot"
        frozen = self.lineage / "emitter-1/gsc-boot"
        original = digest(frozen)
        boot.write_bytes(b"replacement")
        result = self.make("gsi", "_gsi.c", success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bootstrap seed was replaced", result.stderr)
        self.assertFalse((self.source / "gsi/_gsi.c").exists())
        self.assertEqual(digest(frozen), original)

    def test_make_skip_does_not_create_an_origin(self):
        path = self.source / "gsi/_gsi.c"
        path.write_text("old unbound output")
        self.make("gsi", "_gsi.c")
        with self.assertRaisesRegex(ValueError, "missing Make emit origin"):
            make_lineage.completed_action(self.lineage, 1, "emit", "gsi/_gsi.c")
        self.assertEqual(path.read_text(), "old unbound output")

    def test_same_byte_fresh_emission_has_an_execution_receipt(self):
        expected = (self.source / "gsi/_gsi.scm").read_bytes()
        output = self.source / "gsi/_gsi.c"
        output.write_bytes(expected)
        old = digest(output)
        self.make("gsi", "_gsi.c", force=True)
        row = make_lineage.completed_action(self.lineage, 1, "emit", "gsi/_gsi.c", old)
        self.assertEqual(row["beforeSha256"], row["outputSha256"])
        self.assertEqual(Path(row["executedArgv"][0]), self.lineage / "emitter-1/gsc-boot")

    def test_checked_prior_origins_allow_make_skip_without_creating_fresh_edges(self):
        self.make('lib', 'libgambit.a')
        previous = self.lineage
        origins = {}
        for path in previous.glob('pass-1/*/*/receipt.json'):
            row = json.loads(path.read_text())
            origins[row['kind'] + ':' + row['output']] = {'path': str(path), 'sha256': digest(path)}
        old_c = self.source / 'lib/_gambit.c'
        stamp = old_c.stat().st_mtime_ns
        self.lineage = self.directory / 'retry-lineage'
        self.witness = make_lineage.prepare(self.lineage, self.source, self.generated,
            self.cc, scheme_inputs(self.source), prior_origins=origins)
        self.make('gsi', 'gsi')
        row = make_lineage.completed_action(self.lineage, 1, 'emit', 'lib/_gambit.c', digest(old_c))
        self.assertEqual(row['outputSha256'], digest(old_c))
        self.assertEqual(old_c.stat().st_mtime_ns, stamp)
        self.assertFalse(make_lineage.action_directory(self.lineage, 1, 'emit', 'lib/_gambit.c').exists())
        receipt = Path(origins['emit:lib/_gambit.c']['path'])
        receipt.write_text('{}')
        with self.assertRaisesRegex(ValueError, 'retained Make origin changed'):
            make_lineage.completed_action(self.lineage, 1, 'emit', 'lib/_gambit.c', digest(old_c))

    def test_focused_make_preserves_a_retained_second_pass_origin(self):
        self.make('gsi', '_gsi.c', force=True)
        name = 'gsi/_gsi.c'
        original = make_lineage.action_directory(self.lineage, 1, 'emit', name) / 'receipt.json'
        retained = make_lineage.action_directory(self.lineage, 2, 'emit', name) / 'receipt.json'
        retained.parent.mkdir(parents=True)
        row = json.loads(original.read_text())
        row['pass'] = 2
        retained.write_text(json.dumps(row))
        origin = {'path': str(retained), 'sha256': digest(retained), 'pass': 2}
        focused = self.directory / 'focused-lineage'
        make_lineage.prepare(focused, self.source, self.generated, self.cc,
                             scheme_inputs(self.source), prior_origins={'emit:' + name: origin})
        self.assertEqual(make_lineage.completed_action(focused, 1, 'emit', name,
                                                       row['outputSha256'])['pass'], 2)
        self.assertFalse(make_lineage.action_directory(focused, 1, 'emit', name).exists())
        with self.assertRaisesRegex(ValueError, 'changed or incomplete Make emit origin'):
            make_lineage.completed_action(focused, 1, 'emit', name, '0' * 64)

    def test_failed_emission_keeps_partial_bytes_outside_make_target(self):
        (self.source / 'failed-seed.c').write_text('''
#include <stdio.h>
int main(void) { FILE *f = fopen("_gsi.c", "w");
  if (!f) return 2; fputs("partial generated C", f); fclose(f); return 1; }
''')
        task_run([str(self.cc), 'failed-seed.c', '-o', 'gsc-boot'], cwd=self.source, check=True)
        self.lineage = self.directory / 'failed-lineage'
        self.witness = make_lineage.prepare(self.lineage, self.source, self.generated,
                                           self.cc, scheme_inputs(self.source))
        result = self.make('gsi', '_gsi.c', success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.source / 'gsi/_gsi.c').exists())
        action = make_lineage.action_directory(self.lineage, 1, 'emit', 'gsi/_gsi.c')
        self.assertEqual((action / 'failed-output').read_text(), 'partial generated C')
        self.assertEqual(json.loads((action / 'failed.json').read_text())['exit'], 1)
        self.assertFalse((action / 'receipt.json').exists())

    def test_three_modules_emit_and_check_c23_without_a_core_build(self):
        self.check_modules(hosted=False)

    def test_hosted_source_modules_need_no_target_gsi_or_compiled_gsc(self):
        self.check_modules(hosted=True)

    def check_modules(self, *, hosted):
        from gambit_smp.gambit_build_primitives import regenerate_module
        from gambit_smp.native_capabilities import Stages
        from gambit_smp.recipes import ExecutionContext
        from gambit_smp import workspace
        (self.source / 'include').mkdir()
        (self.source / 'include/fixture.h').write_text('#define MODULE_VALUE 0\n')
        if hosted:
            # Transport fixture only: the real source compiler uses this same
            # environment binding, but this script copies C instead of compiling Scheme.
            (self.source / 'gsc/igsc.scm').write_text(
                '#!/bin/sh\n'
                'test "$GAMBIT_COMPILER_TRACE" = 1 || exit 99\n'
                "printf 'GAMBIT-COMPILER-TRACE\\tv1\\tcf\\tenter\\t0\\t0\\tfixture\\n'\n"
                'exec "$GAMBIT_BOOT_GSI" "$@"\n')
            (self.source / 'gsc/igsc.scm').chmod(0o755)
            self.assertFalse((self.source / 'gsc/gsc').exists())
            self.assertFalse((self.source / 'gsi/gsi').exists())
        else:
            shutil.copyfile(self.source / 'gsc-boot', self.source / 'gsc/gsc')
            (self.source / 'gsc/gsc').chmod(0o755)
        (self.source / 'lib/makefile').write_text(f'''
%.c: %.scm
	../gsc-boot -f -c $<
%.o: %.c
	{self.cc} -std=c23 -D___LIBRARY -D___PRIMAL -I../include -c $(BUILD_OBJ_INPUT_FILENAMES_PARAM) -o $(BUILD_OBJ_OUTPUT_FILENAME_PARAM)
''')
        for name in ('_kernel', '_nonstd', '_system'):
            (self.source / ('lib/' + name + '.scm')).write_text(
                '#include "fixture.h"\nint checked_module(void) { return MODULE_VALUE; }\n')
            (self.source / ('lib/' + name + '.c')).write_text('old bound seed C\n')
        # A fourth case reproduces a generated-C failure without any Scheme fix.
        (self.source / 'lib/_invalid.scm').write_text('int broken(void) { return ___LBL(); }\n')
        (self.source / 'lib/_invalid.c').write_text('old bound seed C\n')
        root = self.directory
        task_run(['git', 'init', '-q', str(root)], check=True)
        task_run(['git', '-C', str(root), '-c', 'user.name=Fixture', '-c',
                        'user.email=fixture@example.invalid', 'commit', '--allow-empty', '-qm', 'fixture'], check=True)
        workspace.start(root, 'module-fixture', adopt=True)
        # Fault injection edits a declared fixture source area, never an
        # unregistered output or a production build workspace.
        fixture_source = root / 'tests/module-source'
        fixture_source.parent.mkdir()
        self.source.rename(fixture_source)
        self.source = fixture_source
        before = scheme_inputs(self.source)
        with fixture_execution(root, 'module-fixture'):
            out = workspace.task_output(root, '.cache/module-checks')
            for name in ('_kernel', '_nonstd', '_system', '_invalid'):
                with self.subTest(module=name):
                    directory = out / name
                    directory.mkdir(parents=True)
                    ctx = ExecutionContext(root, out, directory, dict(os.environ), time.monotonic() + 60,
                                           {}, {'engine': {}}, {})
                    stages = Stages(ctx)
                    if hosted:
                        stages.env['GAMBIT_BOOT_GSI'] = 'must-be-restored'
                        stages.env['GAMBIT_COMPILER_TRACE'] = 'must-be-restored'
                    try:
                        ok, result = regenerate_module(stages, self.source, 'lib/' + name + '.scm',
                            60, syntax_check=True, gcc=str(self.cc), interpreted=hosted,
                            bootstrap_host=self.source / 'gsc-boot' if hosted else None)
                    finally:
                        ctx.workspace_leases.close()
                    self.assertEqual(ok, name != '_invalid')
                    self.assertEqual(result['syntaxChecked'], ok)
                    self.assertEqual(result['generatedSha256'], digest(directory / (name + '.c')))
                    self.assertFalse((directory / (name + '.o')).exists())
                    if hosted:
                        self.assertEqual(stages.env['GAMBIT_BOOT_GSI'], 'must-be-restored')
                        self.assertEqual(stages.env['GAMBIT_COMPILER_TRACE'], 'must-be-restored')
                        self.assertEqual(result['hostEnvironment']['GAMBIT_COMPILER_TRACE'], '1')
                        from gambit_smp.compiler_trace import module_compiler_trace
                        trace = module_compiler_trace(out, dict(id=name, capability='gambit.regenerate-module',
                            arguments={'bootstrapHost': 'fixture', 'module': 'lib/' + name + '.scm'},
                            commands=ctx.commands))
                        self.assertEqual(trace['status'], 'RECEIPT_BOUND')
                        self.assertEqual(trace['frontier']['phase'], 'cf')
                        self.assertFalse(result['targetProducerAdmitted'])
                        self.assertFalse(result['familyAdmitted'])
                        self.assertEqual(result['hostSha256'], digest(self.source / 'gsc-boot'))
                        self.assertIn('gsc/igsc.scm', result['inputs'])
                        self.assertIn('lib/_system.scm', result['inputs'])
                    self.assertTrue(all(command['stage'] not in {'source-core', 'seed-core', 'from-scratch'}
                                        for command in ctx.commands))
                    if ok:
                        self.assertIn(str(self.source / 'include/fixture.h'), result['headersAndSources'])
                    else:
                        self.assertEqual(result['failedAt'], 'syntax')
            if hosted:
                host = self.source / 'gsc-boot'
                original = host.read_bytes()
                for changed in ('declared-host', 'executing-host', 'target-header'):
                    with self.subTest(drift=changed):
                        directory = out / changed
                        directory.mkdir()
                        ctx = ExecutionContext(root, out, directory, dict(os.environ), time.monotonic() + 60,
                                               {}, {'engine': {}}, {})
                        stages = Stages(ctx)
                        native_run = stages.run
                        def run(stage, *args):
                            value = native_run(stage, *args)
                            if stage == 'regenerate-module':
                                if changed == 'executing-host':
                                    host.write_bytes(b'replaced after execution')
                                elif changed == 'target-header':
                                    (self.source / 'include/fixture.h').write_text('#define MODULE_VALUE 1\n')
                            return value
                        stages.run = run
                        try:
                            if changed == 'declared-host':
                                with self.assertRaisesRegex(ValueError, 'changed before freezing'):
                                    regenerate_module(stages, self.source, 'lib/_system.scm', 60,
                                        interpreted=True, syntax_check=True, gcc=str(self.cc),
                                        bootstrap_host=host, bootstrap_host_sha256='0' * 64)
                                self.assertFalse(any(c['stage'] == 'regenerate-module' for c in ctx.commands))
                            else:
                                ok, result = regenerate_module(stages, self.source, 'lib/_system.scm', 60,
                                    interpreted=True, syntax_check=True, gcc=str(self.cc),
                                    bootstrap_host=host, bootstrap_host_sha256=digest(host))
                                self.assertFalse(ok)
                                self.assertFalse(result['inputsStable'])
                                self.assertEqual(result['failedAt'], 'emission')
                            self.assertNotIn('GAMBIT_BOOT_GSI', stages.env)
                        finally:
                            ctx.workspace_leases.close()
                            host.write_bytes(original)
                            (self.source / 'include/fixture.h').write_text('#define MODULE_VALUE 0\n')
        self.assertEqual(scheme_inputs(self.source), before)

    def test_failed_core_resumes_same_seed_under_real_storage_custody(self):
        from gambit_smp import workspace, native_capabilities
        from gambit_smp.recipes import ExecutionContext, tree_identity
        # Construct a tiny complete seed, then a failing regeneration input.
        result = task_run(['make', self.witness, 'from-scratch'], cwd=self.source,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        top = self.source / 'makefile'
        top.write_text('GAMBIT_BUILD_WITNESS ?=\n' + top.read_text())
        for unit in ('_kernel', '_nonstd', '_system'):
            (self.source / ('lib/' + unit + '.scm')).write_text('int fixture_unit(void) { return 0; }\n')
            (self.source / ('lib/' + unit + '.c')).write_text('int fixture_unit(void) { return 0; }\n')
        (self.source / 'gsi/_gsi.scm').write_text('this is deliberately invalid C\n')
        root = self.directory
        task_run(['git', 'init', '-q', str(root)], check=True)
        task_run(['git', '-C', str(root), '-c', 'user.name=Fixture', '-c',
                        'user.email=fixture@example.invalid', 'commit', '--allow-empty', '-qm', 'fixture'], check=True)
        workspace.start(root, 'core-fixture', adopt=True)
        (root / 'docs').mkdir(exist_ok=True)
        input_spec = root / 'docs/fixture-input.json'
        input_spec.write_text('{"input":"fixed native fixture"}')
        steps = []
        with fixture_execution(root, 'core-fixture'):
            build = workspace.build_output(root, 'gambit-core', compiler=str(self.cc), flags=['-std=c23'])
            seed = build / 'source'
            shutil.copytree(self.source, seed)
            out = workspace.task_output(root, '.cache/core-first') / 'run'
            directory = out / 'seed'
            directory.mkdir(parents=True)
            receipt = dict(recipe='core-fixture', workspacePolicy='in-place',
                           inputs={str(input_spec): digest(input_spec)}, steps=steps,
                           engine={'engineId': 'fixture'})
            ctx = ExecutionContext(root, out, directory, dict(os.environ), time.monotonic() + 120,
                                   {}, receipt, {'gcc': str(self.cc), 'make': shutil.which('make')})
            ctx.lease_workspace(seed, tree_identity(seed))
            outputs = ctx.publish('runtime', 'seed-runtime', seed)
            steps.append(dict(id='seed', outcome='PASS', outputs=outputs))
            directory = out / 'source-core'
            directory.mkdir()
            ctx.directory = directory
            with self.assertRaisesRegex(ValueError, 'source-regenerated core'):
                native_capabilities.source_core({'runtime': {'step': 'seed', 'output': 'runtime'}}, ctx)
            working = next(path.parent for path in (root / '.cache/tasks/core-fixture/build/gambit-core').glob(
                '*/source-state.json') if json.loads(path.read_text()).get('regeneration', {}).get('checkpoint')) / 'source'
            before = tree_identity(working)
            row = dict(id='source-core', capability='gambit.source-core', outcome='DENY', commands=ctx.commands,
                       artifacts={str(p.relative_to(out)): digest(p) for p in directory.rglob('*') if p.is_file()})
            core_command = next(c for c in ctx.commands if c['stage'] == 'source-core')
            self.assertEqual(core_command['exit'], 2)
            self.assertTrue(core_command['processGroupQuiescent'])
            ctx.workspace_leases.close()
        with fixture_execution(root, 'core-fixture'):
            out2 = workspace.task_output(root, '.cache/core-second') / 'run'
            directory2 = out2 / 'source-core'
            directory2.mkdir(parents=True)
            # Carry the exact typed seed reference rather than a workspace path.
            receipt2 = dict(receipt, steps=[])
            ctx2 = ExecutionContext(root, out2, directory2, dict(os.environ), time.monotonic() + 120,
                                    {}, receipt2, {'gcc': str(self.cc), 'make': shutil.which('make')})
            ctx2.lease_workspace(seed, tree_identity(seed))
            seed_directory = out2 / 'seed'
            seed_directory.mkdir()
            ctx2.directory = seed_directory
            outputs2 = ctx2.publish('runtime', 'seed-runtime', seed)
            receipt2['steps'].append(dict(id='seed', outcome='PASS', outputs=outputs2))
            ctx2.directory = directory2
            # The underlying journal verifier has independent custody tests;
            # this fixture supplies its authenticated failed-stage projection.
            with patch('gambit_smp.reasoning_history.read_execution_checkpoint', return_value={
                    'records': [{'payload': {'schema': 'research-step-observation.v1', 'step': row}}]}):
                source, state = native_capabilities.source_core_resume(ctx2,
                    {'runtime': {'step': 'seed', 'output': 'runtime'}})
            self.assertEqual(source, working)
            self.assertEqual(tree_identity(source), before)
            self.assertTrue(state['previous']['origins'])
            self.assertFalse(ctx2.commands)
            ctx2.workspace_leases.close()

    def test_two_real_make_passes_bind_objects_and_final_executable(self):
        result = task_run(["make", self.witness, "from-scratch"], cwd=self.source,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        path = make_lineage.finish(self.lineage, self.source)
        manifest = json.loads(path.read_text())
        self.assertEqual(manifest["gsiSha256"], digest(self.source / "gsi/gsi"))
        binding = {"path": str(path.relative_to(self.directory)), "sha256": digest(path),
                   "gsiSha256": manifest["gsiSha256"]}
        make_lineage.verify_retained(self.directory, binding, manifest["gsiSha256"])
        row = make_lineage.completed_action(self.lineage, 2, "object", "gsi/_gsi.o")
        self.assertEqual(row["headersAndSources"][str(self.source / "gsi/entry.h")],
                         digest(self.source / "gsi/entry.h"))
        link = make_lineage.completed_action(self.lineage, 2, "link", "gsi/gsi")
        self.assertEqual(link["orderedFileArguments"],
                         [str(self.source / "gsi/_gsi.o"), str(self.source / "lib/libgambit.a")])
        task_run([self.source / "gsi/gsi"], check=True)
        self.assertFalse(manifest["familyAdmitted"])
        (self.source / "gsi/gsi").write_bytes(b"unbound link")
        with self.assertRaisesRegex(ValueError, "changed or incomplete Make link origin"):
            make_lineage.finish(self.lineage, self.source)
        action = next((self.lineage / "pass-2/object").glob("*/receipt.json"))
        action.write_text("{}")
        with self.assertRaisesRegex(ValueError, "retained Make lineage artifact changed"):
            make_lineage.verify_retained(self.directory, binding, manifest["gsiSha256"])

    def test_transport_preflight_uses_real_managed_children_and_reuses_only_bound_success(self):
        from gambit_smp import workspace, task_processes
        from gambit_smp.recipes import ExecutionContext
        from gambit_smp.storage_policy import StoragePolicyError
        root = self.directory
        task_run(['git', 'init', '-q', str(root)], check=True)
        task_run(['git', '-C', str(root), '-c', 'user.name=Fixture', '-c',
                        'user.email=fixture@example.invalid', 'commit', '--allow-empty', '-qm', 'fixture'], check=True)
        workspace.start(root, 'lineage-fixture', adopt=True)
        with fixture_execution(root, 'lineage-fixture'):
            out = workspace.task_output(root, '.cache/preflight-run')
            directory = out / 'core'
            directory.mkdir(parents=True)
            deadline = time.monotonic() + 120
            ctx = ExecutionContext(root, out, directory, dict(os.environ), deadline, {},
                {'steps': [], 'engine': {'engineId': 'fixture-transport-only'}},
                {'make': shutil.which('make')})
            self.addCleanup(ctx.workspace_leases.close)
            # The same storage audit which caught the production failures is
            # active here. No subprocess/loader or module import is mocked.
            with self.assertRaisesRegex(StoragePolicyError, 'durable birth/exec'):
                subprocess.run(['/usr/bin/true'])
            # compiler(ctx) returns its configured tool as a string.
            binding = make_lineage.preflight(ctx, self.source, str(self.cc))
            row = json.loads((out / binding['path']).read_text())
            self.assertFalse(row['familyAdmitted'])
            self.assertIn('lineage-preflight-make', [command['stage'] for command in ctx.commands])
            self.assertTrue(task_processes.check(root, 'lineage-fixture', all_processes=True))
            original_count = len(ctx.commands)
            ctx.receipt['steps'].append(dict(outcome='PASS', makeLineagePreflight=binding))
            self.assertEqual(make_lineage.preflight(ctx, self.source, self.cc), binding)
            self.assertEqual(len(ctx.commands), original_count)
            (out / binding['path']).write_text('{}')
            with self.assertRaisesRegex(ValueError, 'preflight changed'):
                make_lineage.preflight(ctx, self.source, self.cc)
