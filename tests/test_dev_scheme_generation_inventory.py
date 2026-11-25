"""Source regeneration must reject any recursive Scheme inventory drift."""
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import json
import unittest
from unittest.mock import Mock, patch

from gambit_smp.framework import digest
from gambit_smp.gambit_build_primitives import rebuild_source_core, scheme_inputs


class RecursiveSchemeInventoryTests(unittest.TestCase):
    def test_source_core_rejects_changed_added_and_deleted_nested_inputs(self):
        for change in ('none', 'changed', 'added', 'deleted'):
            with self.subTest(change=change), TemporaryDirectory() as temporary:
                source = Path(temporary)
                for name in ('lib/_unit.scm', 'lib/_unit.c', 'gsc/gsc',
                             'gsi/gsi', 'lib/libgambit.a', 'lib/pkg/nested.scm'):
                    path = source / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text('original')

                def run(stage, argv, cwd, budget, **kwargs):
                    if stage == 'bootclean':
                        (source / 'lib/_unit.c').unlink()
                    else:
                        (source / 'lib/_unit.c').write_text('regenerated')
                        nested = source / 'lib/pkg/nested.scm'
                        if change == 'changed':
                            nested.write_text('changed')
                        elif change == 'added':
                            (nested.parent / 'new.scm').write_text('added')
                        elif change == 'deleted':
                            nested.unlink()
                    return 0, '', False, 0.1

                stages = SimpleNamespace(progress_mode=False, run=run)
                with patch('gambit_smp.gambit_build_primitives.available_processors', return_value=2):
                    ok, observation = rebuild_source_core(stages, source, 10)
                self.assertEqual(change == 'none', ok)
                self.assertEqual(change == 'none', observation['schemeInputsStable'])
                self.assertIn('lib/pkg/nested.scm', observation['schemeInputs'])

    def test_resume_rejects_nested_input_drift_since_bootclean(self):
        from gambit_smp.native_capabilities import source_core
        with TemporaryDirectory() as temporary:
            source = Path(temporary) / 'source'
            nested = source / 'lib/pkg/nested.scm'
            nested.parent.mkdir(parents=True)
            nested.write_text('before')
            boot = source / 'gsc-boot'
            boot.write_text('compiler')
            log = source.parent / 'bootclean.log'
            log.write_text('cleaned')
            previous = {'generatedSources': ['lib/_unit.c'],
                        'bootstrapCompilerSha256': digest(boot),
                        'bootcleanLogSha256': digest(log),
                        'schemeInputs': scheme_inputs(source)}
            (source.parent / 'source-state.json').write_text(
                json.dumps({'regeneration': previous}))
            nested.write_text('after')
            with patch('gambit_smp.native_capabilities.clone', return_value=source), \
                 patch('gambit_smp.native_capabilities.compiler'), \
                 patch('gambit_smp.gambit_build_primitives.rebuild_source_core') as rebuild:
                with self.assertRaisesRegex(ValueError, 'Scheme input inventory changed'):
                    source_core({'runtime': {}}, Mock(planned_steps=()))
            rebuild.assert_not_called()


if __name__ == '__main__':
    unittest.main()
