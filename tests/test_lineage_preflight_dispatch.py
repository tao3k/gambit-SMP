from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities


class LineagePreflightDispatchTests(unittest.TestCase):
    def setUp(self):
        task = patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': 'fixture'})
        task.start()
        self.addCleanup(task.stop)

    def test_transport_failure_prevents_expensive_core_entry(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / 'makefile').write_text('GAMBIT_BUILD_WITNESS=\n')
            ctx = SimpleNamespace(root=source, planned_steps=[dict(capability='gambit.bootstrap')])
            with patch.object(native_capabilities, 'clone', return_value=source), \
                    patch.object(native_capabilities, 'compiler', return_value=source / 'gcc'), \
                    patch('gambit_smp.make_lineage.preflight', side_effect=ValueError('transport refused')) as preflight, \
                    patch('gambit_smp.gambit_build_primitives.rebuild_source_core') as core:
                with self.assertRaisesRegex(ValueError, 'transport refused'):
                    native_capabilities.source_core({'runtime': 'fixture'}, ctx)
            preflight.assert_called_once_with(ctx, source, source / 'gcc')
            core.assert_not_called()

    def test_explicit_witness_request_is_preflighted_even_without_root_hook(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / 'makefile').write_text('old Make recipe without hooks\n')
            ctx = SimpleNamespace(root=source, planned_steps=[dict(capability='gambit.bootstrap',
                                                       arguments={'makeLineage': True})])
            with patch.object(native_capabilities, 'clone', return_value=source), \
                    patch.object(native_capabilities, 'compiler', return_value=source / 'gcc'), \
                    patch('gambit_smp.make_lineage.preflight', side_effect=ValueError('missing hooks')) as preflight, \
                    patch('gambit_smp.gambit_build_primitives.rebuild_source_core') as core:
                with self.assertRaisesRegex(ValueError, 'missing hooks'):
                    native_capabilities.source_core({'runtime': 'fixture'}, ctx)
            preflight.assert_called_once()
            core.assert_not_called()

    def test_actual_emitter_cut_failure_prevents_workspace_resume_and_whole_core(self):
        ctx = SimpleNamespace(receipt={'workspacePolicy': 'in-place'})
        with patch.object(native_capabilities, 'compiler', return_value='configured-gcc'), \
                patch.object(native_capabilities, 'source_core_module_checks',
                             side_effect=ValueError('kernel emission failed')) as checks, \
                patch.object(native_capabilities, 'source_core_resume') as resume, \
                patch('gambit_smp.gambit_build_primitives.rebuild_source_core') as core:
            with self.assertRaisesRegex(ValueError, 'kernel emission failed'):
                native_capabilities.source_core({'runtime': {'step': 'seed', 'output': 'runtime'}}, ctx)
        checks.assert_called_once()
        resume.assert_not_called()
        core.assert_not_called()
