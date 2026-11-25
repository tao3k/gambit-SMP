import copy
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

from gambit_smp import bootstrap_artifacts as owner
from gambit_smp.framework import digest
from gambit_smp.recipes import tree_identity


class SourceCoreCheckpointTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.run = self.root / '.cache/tasks/family6/runs/previous'
        self.path = self.run / 'run/source-core/regeneration-checkpoint.json'
        self.path.parent.mkdir(parents=True)
        self.evidence = self.run / 'run/source-core/emission.json'
        self.evidence.write_text('retained successful Make emission')
        self.command = dict(stage='source-core', exit=2, timeout=False,
                            parentReaped=True, processGroupQuiescent=True)
        self.value = dict(schema='source-core-regeneration-checkpoint.v1',
                          writerSha256=digest(Path(owner.__file__)), command=self.command,
                          evidence={str(self.evidence.relative_to(self.root)): digest(self.evidence)},
                          runtimeAdmitted=False)
        self.row = dict(id='source-core', capability='gambit.source-core', outcome='DENY',
                        commands=[self.command])
        self.ctx = SimpleNamespace(root=self.root, bind=Mock())
        self.commit()
        reader = patch('gambit_smp.reasoning_history.read_execution_checkpoint',
                       return_value={'records': [{'payload': {'schema': 'research-step-observation.v1',
                                                               'step': self.row}}]})
        reader.start()
        self.addCleanup(reader.stop)

    def commit(self):
        self.path.write_text(json.dumps(self.value))
        self.reference = dict(run=str(self.run.relative_to(self.root)), step='source-core',
                              path=str(self.path.relative_to(self.root)), sha256=digest(self.path))
        self.row['artifacts'] = {'source-core/regeneration-checkpoint.json': digest(self.path)}

    def test_quiescent_failure_preserves_emission_evidence_without_manufacturing_pass(self):
        result = owner.source_core_checkpoint_read(self.ctx, self.reference)
        self.assertEqual(result['command']['exit'], 2)
        self.assertFalse(result['runtimeAdmitted'])
        self.ctx.bind.assert_called_once()

    def test_edited_checkpoint_or_old_origin_cannot_be_reused(self):
        self.path.write_text('{}')
        with self.assertRaisesRegex(ValueError, 'observation changed'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)
        self.commit()
        self.evidence.write_text('changed')
        with self.assertRaisesRegex(ValueError, 'retained origin changed'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)

    def test_uncommitted_or_non_quiescent_attempt_never_authorizes_reuse(self):
        self.row['artifacts'] = {}
        with self.assertRaisesRegex(ValueError, 'observation changed'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)
        self.command['processGroupQuiescent'] = False
        self.commit()
        with self.assertRaisesRegex(ValueError, 'quiescent'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)

    def test_other_writer_and_escape_are_rejected(self):
        self.value['writerSha256'] = '0' * 64
        self.commit()
        with self.assertRaisesRegex(ValueError, 'known, quiescent'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)
        with self.assertRaises(ValueError):
            owner.source_core_checkpoint_read(self.ctx, dict(self.reference, path='../../elsewhere'))

    def test_external_object_header_drift_invalidates_retained_origins(self):
        header = self.root / 'system-header.h'
        header.write_text('original SDK header')
        event = self.run / 'run/source-core/receipt.json'
        event.write_text(json.dumps({'headersAndSources': {str(header): digest(header)}}))
        self.value['evidence'] = {str(event.relative_to(self.root)): digest(event)}
        self.commit()
        owner.source_core_checkpoint_read(self.ctx, self.reference)
        header.write_text('changed SDK header')
        with self.assertRaisesRegex(ValueError, 'include closure changed'):
            owner.source_core_checkpoint_read(self.ctx, self.reference)

    def test_stale_object_is_denied_even_when_make_would_skip_it(self):
        source = self.root / 'source'
        (source / 'lib').mkdir(parents=True)
        c = source / 'lib/_unit.c'
        obj = source / 'lib/_unit.o'
        c.write_text('new emitted C')
        obj.write_text('old compiled object')
        event = self.root / 'emit.json'
        event.write_text(json.dumps(dict(kind='emit', output='lib/_unit.c', exit=0,
            outputSha256=digest(c), inputs={}, tool={'sha256': 'emitter'})))
        compiled = self.root / 'object.json'
        compiled.write_text(json.dumps(dict(kind='object', output='lib/_unit.o', exit=0,
            outputSha256=digest(obj), inputs={str(c): 'old-C-digest'})))
        origins = {'emit:lib/_unit.c': {'path': str(event), 'sha256': digest(event)},
                   'object:lib/_unit.o': {'path': str(compiled), 'sha256': digest(compiled)}}
        with self.assertRaisesRegex(ValueError, 'output dependency changed'):
            owner.source_core_output_origins(source, tree_identity(source), ['lib/_unit.c'], origins, 'emitter')


class SourceCoreWorkingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.seed = self.root / 'seed/source'
        self.source = self.root / 'work/source'
        for source in (self.seed, self.source):
            for directory in ('gsc', 'gsi', 'lib'):
                (source / directory).mkdir(parents=True)
            for name, value in {'gsc/gsc': 'compiler A', 'gsc-boot': 'compiler A',
                                'lib/_std.scm': '(define a 1)', 'lib/_std.c': 'old C',
                                'lib/_std.o': 'old object'}.items():
                (source / name).write_text(value)
        self.gcc = self.root / 'gcc'
        self.gcc.write_text('configured GCC')
        (self.seed.parent / 'configuration.json').write_text(json.dumps({'compilerSha256': digest(self.gcc)}))
        incoming = tree_identity(self.seed)
        self.origin = dict(seedWorkspace='seed/source', seedIdentity=incoming,
                           compilerSha256=digest(self.seed / 'gsc/gsc'),
                           configurationSha256=digest(self.seed.parent / 'configuration.json'))
        emit_origin = self.root / 'emit-std.json'
        emit_origin.write_text(json.dumps(dict(
            kind='emit', output='lib/_std.c', exit=0,
            outputSha256=digest(self.source / 'lib/_std.c'),
            inputs={str(self.source / 'lib/_std.scm'): digest(self.source / 'lib/_std.scm')},
            tool={'sha256': self.origin['compilerSha256']},
        )))
        obj_origin = self.root / 'obj-std.json'
        obj_origin.write_text(json.dumps(dict(
            kind='object', output='lib/_std.o', exit=0,
            outputSha256=digest(self.source / 'lib/_std.o'),
            inputs={str(self.source / 'lib/_std.c'): digest(self.source / 'lib/_std.c')},
        )))
        link_origin = self.root / 'link-gsc.json'
        link_origin.write_text(json.dumps(dict(
            kind='link', output='gsc/gsc', exit=0,
            outputSha256=digest(self.source / 'gsc/gsc'),
            inputs={str(self.source / 'lib/_std.o'): digest(self.source / 'lib/_std.o')},
        )))
        self.origins = {
            'emit:lib/_std.c': {'path': str(emit_origin), 'sha256': digest(emit_origin)},
            'object:lib/_std.o': {'path': str(obj_origin), 'sha256': digest(obj_origin)},
            'link:gsc/gsc': {'path': str(link_origin), 'sha256': digest(link_origin)},
        }
        self.previous = dict(origin=self.origin, tree=tree_identity(self.source), workspace='work/source',
                             generatedSources=['lib/_std.c'], origins=self.origins)
        state = {'phase': 'building', 'regeneration': {'checkpoint': {'record': 'checked-stage'}}}
        (self.source.parent / 'source-state.json').write_text(json.dumps(state))
        self.ctx = SimpleNamespace(root=self.root, tools={'gcc': str(self.gcc)},
                                   artifact=Mock(return_value=self.seed), lease_workspace=Mock())
        self.sync = Mock(return_value={'changed': []})
        for mock in (patch.object(owner, 'derived_source', return_value=(self.source, incoming)),
                     patch.object(owner, 'source_core_checkpoint_read', return_value=self.previous),
                     patch('gambit_smp.workspace.build_source_links', return_value={}),
                     patch('gambit_smp.workspace.sync_build_source', self.sync)):
            mock.start()
            self.addCleanup(mock.stop)
        self.reference = {'step': 'checked-seed', 'output': 'runtime'}

    def test_exact_typed_seed_reuses_tree_without_reseeding_or_cleaning(self):
        before = tree_identity(self.source)
        result, working = owner.source_core_working(self.ctx, self.reference)
        self.assertEqual(result, self.source)
        self.assertEqual(tree_identity(result), before)
        self.ctx.artifact.assert_called_once_with(self.reference, 'seed-runtime')
        self.ctx.lease_workspace.assert_called_once_with(self.source, before)
        self.assertIs(working['previous'], self.previous)
        self.assertIsNone(self.sync.call_args.kwargs['initial_transfer'])

    def test_seed_or_product_changes_stop_before_sync_and_keep_old_bytes(self):
        for target in ('gsc-boot', 'lib/_std.c', 'lib/_std.o'):
            with self.subTest(target=target):
                original = (self.source / target).read_bytes()
                (self.source / target).write_bytes(b'unbound replacement')
                with self.assertRaisesRegex(ValueError, 'no clean/reseed fallback'):
                    owner.source_core_working(self.ctx, self.reference)
                self.sync.assert_not_called()
                self.assertEqual((self.source / target).read_bytes(), b'unbound replacement')
                (self.source / target).write_bytes(original)

    def test_source_configuration_or_gcc_drift_is_not_a_reuse_hit(self):
        self.previous['origin'] = copy.deepcopy(self.origin)
        self.previous['origin']['configurationSha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'no clean/reseed fallback'):
            owner.source_core_working(self.ctx, self.reference)
        self.sync.assert_not_called()
        self.gcc.write_text('another compiler')
        with self.assertRaisesRegex(ValueError, 'compiler differs'):
            owner.source_core_working(self.ctx, self.reference)

    def test_untyped_state_has_no_fallback_to_a_cohort_pointer(self):
        (self.source.parent / 'source-state.json').write_text('{}')
        route = self.root / '.cache/tasks/fixture/cohort/source-core-workspace.json'
        route.parent.mkdir(parents=True)
        route.write_text(json.dumps({'workspace': str(self.source)}))
        with self.assertRaisesRegex(ValueError, 'unbound source-core directory'):
            owner.source_core_working(self.ctx, self.reference)
        self.sync.assert_not_called()

    def test_recording_a_changed_scheme_file_does_not_rebind_it_to_the_old_seed(self):
        (self.source / 'lib/_std.scm').write_text('(define unrelated 2)')
        self.previous['tree'] = tree_identity(self.source)
        with self.assertRaisesRegex(ValueError, 'source/configuration input drift'):
            owner.source_core_working(self.ctx, self.reference)
        self.sync.assert_not_called()

    def test_existing_legacy_product_cannot_bypass_the_typed_owner(self):
        from gambit_smp.native_capabilities import source_core_resume
        route = self.root / '.cache/tasks/fixture/cohort/source-core-workspace.json'
        route.parent.mkdir(parents=True)
        (self.source / 'gsi/gsi').write_text('existing but unqualified executable')
        route.write_text(json.dumps({'workspace': str(self.source)}))
        self.ctx.receipt = {'workspacePolicy': 'in-place'}
        before = tree_identity(self.source)
        with patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': 'fixture'}), \
                patch.object(owner, 'source_core_working', return_value=('typed-result', {})) as checked:
            self.assertEqual(source_core_resume(self.ctx, {'runtime': self.reference}), ('typed-result', {}))
        checked.assert_called_once_with(self.ctx, self.reference)
        self.assertEqual(tree_identity(self.source), before)


class SourceCoreRealCustodyRecoveryTests(unittest.TestCase):
    """Exercise real workspace.sync_build_source custody, recoveryLinks and pre-write conflict checks."""

    def setUp(self):
        from gambit_smp import workspace as w
        from tests import test_workspace as fixtures
        fixtures.WorkspaceTests.setUp(self)
        (self.root / 'docs').mkdir(exist_ok=True)
        (self.root / 'docs/work-items.json').write_text(json.dumps({
            'schema': 'gambit-work-items.v1',
            'items': {
                'repair': {
                    'scope': 'repair',
                    'processes': {},
                    'buildProducts': {
                        'gambit-core': {
                            'recoveryLinks': {
                                'bin/gsi-script': '../gsi/gsi',
                                'bin/gsc-script': '../gsc/gsc',
                            }
                        }
                    },
                }
            },
        }))
        w.start(self.root, 'repair', adopt=True)
        self.gcc = self.root / 'gcc-16'
        self.gcc.write_text('configured GNU GCC 16')
        self.gcc.chmod(0o755)

        with w.execution_scope(self.root, 'repair', provider='codex'):
            seed_build = w.build_output(self.root, 'gambit-core', compiler=str(self.gcc), flags=['-O1', 'seed'])
            self.seed = seed_build / 'source'
            for directory in ('bin', 'gsc', 'gsi', 'lib'):
                (self.seed / directory).mkdir(parents=True)
            (self.seed / 'gsc/gsc').write_text('seed compiler binary')
            (self.seed / 'gsi/gsi').write_text('seed interpreter binary')
            (self.seed / 'lib/_std.scm').write_text('(define std 1)\n')
            (self.seed / 'lib/_std.c').write_text('/* pregenerated seed C */\n')
            (self.seed / 'lib/_std.o').write_text('seed object')
            (self.seed / 'lib/makefile').write_text('GAMBIT_BUILD_WITNESS=\n')
            (self.seed / 'bin/gsi-script').symlink_to('../gsi/gsi')
            (self.seed / 'bin/gsc-script').symlink_to('../gsc/gsc')

            work_build = w.build_output(self.root, 'gambit-core', compiler=str(self.gcc), flags=['-O1', 'working'])
            self.work_build = work_build
            self.source = work_build / 'source'

            # Cold pass-1 start via real source_core_working
            ctx1 = SimpleNamespace(
                root=self.root,
                tools={'gcc': str(self.gcc)},
                artifact=Mock(return_value=self.seed),
                lease_workspace=Mock(),
                bind=Mock(),
            )
            with patch.object(owner, 'derived_source', return_value=(self.source, tree_identity(self.seed))):
                src1, working1 = owner.source_core_working(ctx1, {'step': 'seed', 'output': 'runtime'})
            self.assertEqual(src1, self.source)
            self.assertIsNone(working1['previous'])

            # Simulate pass-1 partial progress after bootclean: gsc/gsi & old .o removed,
            # bin/* links become unresolved recoveryLinks, new _std.c emitted with receipt.
            (self.source / 'gsc-boot').write_text('seed compiler binary')
            (self.source / 'gsc/gsc').unlink()
            (self.source / 'gsi/gsi').unlink()
            (self.source / 'lib/_std.o').unlink()
            (self.source / 'lib/_std.c').write_text('/* pass-1 freshly emitted C */\n')

            run_dir = self.root / '.cache/tasks/repair/runs/pass1-partial'
            cp_path = run_dir / 'run/source-core/regeneration-checkpoint.json'
            cp_path.parent.mkdir(parents=True)
            emit_receipt = run_dir / 'run/source-core/make-lineage/pass-1/emit/std/receipt.json'
            emit_receipt.parent.mkdir(parents=True)
            emit_receipt.write_text(json.dumps({
                'kind': 'emit',
                'output': 'lib/_std.c',
                'exit': 0,
                'outputSha256': digest(self.source / 'lib/_std.c'),
                'inputs': {str(self.source / 'lib/_std.scm'): digest(self.source / 'lib/_std.scm')},
                'tool': {'sha256': digest(self.seed / 'gsc/gsc')},
            }))
            state_now = json.loads((self.work_build / 'source-state.json').read_text())
            self.links = w.build_source_links(self.root, self.work_build, state_now)
            tree_now = tree_identity(self.source, broken_links=self.links)
            self.assertTrue(tree_now['bin/gsi-script'].get('unresolved'))
            self.assertTrue(tree_now['bin/gsc-script'].get('unresolved'))

            command = dict(stage='source-core', exit=2, timeout=False,
                           parentReaped=True, processGroupQuiescent=True)
            self.cp_value = dict(
                schema='source-core-regeneration-checkpoint.v1',
                writerSha256=digest(Path(owner.__file__)),
                origin=working1['origin'],
                generatedSources=working1['generatedSources'],
                workspace=str(self.source.relative_to(self.root)),
                command=command,
                tree=tree_now,
                origins={'emit:lib/_std.c': {'path': str(emit_receipt), 'sha256': digest(emit_receipt)}},
                evidence={str(emit_receipt.relative_to(self.root)): digest(emit_receipt)},
                regeneration={'generatedSources': working1['generatedSources'],
                              'bootstrapCompilerSha256': working1['origin']['compilerSha256']},
                runtimeAdmitted=False,
            )
            self.cp_path = cp_path
            self.run_dir = run_dir
            self._write_checkpoint(command)

    def _write_checkpoint(self, command):
        from gambit_smp import workspace as w
        self.cp_path.write_text(json.dumps(self.cp_value))
        pointer = dict(
            run=str(self.run_dir.relative_to(self.root)),
            step='source-core',
            path=str(self.cp_path.relative_to(self.root)),
            sha256=digest(self.cp_path),
        )
        w.checkpoint_build_source(
            self.source,
            broken_links=self.links,
            regeneration={'checkpoint': pointer, **self.cp_value['regeneration']},
        )
        self.step_row = dict(
            id='source-core',
            capability='gambit.source-core',
            outcome='DENY',
            commands=[command],
            artifacts={'source-core/regeneration-checkpoint.json': pointer['sha256']},
        )

    def _resume_once(self):
        ctx = SimpleNamespace(
            root=self.root,
            tools={'gcc': str(self.gcc)},
            artifact=Mock(return_value=self.seed),
            lease_workspace=Mock(),
            bind=Mock(),
        )
        with patch.object(owner, 'derived_source', return_value=(self.source, tree_identity(self.seed))), \
                patch('gambit_smp.reasoning_history.read_execution_checkpoint',
                      return_value={'records': [{'payload': {'schema': 'research-step-observation.v1',
                                                             'step': self.step_row}}]}):
            return owner.source_core_working(ctx, {'step': 'seed', 'output': 'runtime'})

    def test_normal_resume_preserves_unresolved_recovery_links_and_emitted_c(self):
        from gambit_smp import workspace as w
        before_tree = tree_identity(self.source, broken_links=self.links)
        c_mtime = (self.source / 'lib/_std.c').stat().st_mtime_ns
        with w.execution_scope(self.root, 'repair', provider='codex'):
            resumed_source, working = self._resume_once()
        self.assertEqual(resumed_source, self.source)
        self.assertEqual(tree_identity(self.source, broken_links=self.links), before_tree)
        self.assertTrue((self.source / 'bin/gsi-script').is_symlink())
        self.assertTrue((self.source / 'bin/gsc-script').is_symlink())
        self.assertEqual((self.source / 'lib/_std.c').stat().st_mtime_ns, c_mtime)
        self.assertEqual(working['sourceDelta']['changed'], [])
        self.assertEqual(working['sourceDelta']['retiredGeneratedLinks'], {})

    def test_missing_origin_receipt_rejects_before_writing_state_or_source(self):
        from gambit_smp import workspace as w
        (self.source / 'lib/_std.o').write_text('untracked manual object')
        self.cp_value['tree'] = tree_identity(self.source, broken_links=self.links)
        self._write_checkpoint(self.cp_value['command'])
        before_state = (self.work_build / 'source-state.json').read_bytes()
        before_tree = tree_identity(self.source, broken_links=self.links)
        with w.execution_scope(self.root, 'repair', provider='codex'):
            with self.assertRaisesRegex(ValueError, 'missing or changed object origin'):
                self._resume_once()
        self.assertEqual((self.work_build / 'source-state.json').read_bytes(), before_state)
        self.assertEqual(tree_identity(self.source, broken_links=self.links), before_tree)

    def test_input_or_sync_conflict_rejects_before_any_disk_mutation(self):
        from gambit_smp import workspace as w
        (self.source / 'lib/makefile').write_text('GAMBIT_BUILD_WITNESS=ad-hoc-flags\n')
        before_state = (self.work_build / 'source-state.json').read_bytes()
        before_tree = tree_identity(self.source, broken_links=self.links)
        with w.execution_scope(self.root, 'repair', provider='codex'):
            with self.assertRaisesRegex(ValueError, 'source/configuration input drift'):
                self._resume_once()
        self.assertEqual((self.work_build / 'source-state.json').read_bytes(), before_state)
        self.assertEqual(tree_identity(self.source, broken_links=self.links), before_tree)

    def test_interrupted_unreconciled_owner_rejects_before_any_disk_mutation(self):
        from gambit_smp import workspace as w
        state = json.loads((self.work_build / 'source-state.json').read_text())
        owner_receipt = self.root / state['custody']
        owner_doc = json.loads(owner_receipt.read_text())
        owner_doc['state'] = 'interrupted'
        owner_doc.pop('reconciliation', None)
        owner_receipt.write_text(json.dumps(owner_doc))
        before_state = (self.work_build / 'source-state.json').read_bytes()
        before_tree = tree_identity(self.source, broken_links=self.links)
        with w.execution_scope(self.root, 'repair', provider='codex'):
            with self.assertRaisesRegex(ValueError, 'interrupted build requires real owner reconciliation'):
                self._resume_once()
        self.assertEqual((self.work_build / 'source-state.json').read_bytes(), before_state)
        self.assertEqual(tree_identity(self.source, broken_links=self.links), before_tree)

