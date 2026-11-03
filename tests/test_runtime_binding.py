"""Evidence admission controls; these tests do not qualify the C runtime."""
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest

from gambit_smp.runtime_binding import (
    authenticate_predecessor, generated_accessors, prepare_consumers,
    request_observation, sha,
    runtime_delta,
)
from gambit_smp.native_development import compile_phases


class BindingEvidenceTests(unittest.TestCase):
    def test_retirement_is_an_explicit_registered_source_transition(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'retired.c').write_bytes(b'old source')
            parent = dict(canonicalSources={'retired.c': sha(root/'retired.c')},
                          artifacts={'gsc-boot': 'pinned'},
                          generatedArtifacts={'generated.c': 'generated'})
            change = {'retired.c': None}
            self.assertIs(runtime_delta(root, change, parent), change)
            self.assertEqual((root/'retired.c').read_bytes(), b'old source')
            for name in ['unknown.c', 'gsc-boot', 'generated.c', '../retired.c']:
                with self.subTest(name=name), self.assertRaises(ValueError):
                    runtime_delta(root, {'retired.c': None, name: None}, parent)
            self.assertTrue((root/'retired.c').is_file())

    def test_source_delta_cannot_cross_an_alias_or_replace_a_product(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'real').mkdir()
            (root/'alias').symlink_to(root/'real', target_is_directory=True)
            parent = dict(canonicalSources={}, artifacts={'gsc-boot': 'pinned'},
                          generatedArtifacts={'generated.c': 'generated'})
            for name in ['alias/new.c', 'gsc-boot', 'generated.c']:
                with self.subTest(name=name), self.assertRaises(ValueError):
                    runtime_delta(root, {name: b'replacement'}, parent)
            with self.assertRaises(ValueError):
                runtime_delta(root, {'new.c': 'not bytes'}, parent)

    def test_consumer_transition_cannot_adopt_runtime_or_unknown_test_drift(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'tests').mkdir()
            for name in ('runtime.c', 'generated.c', 'gsi', 'tests/test.scm'):
                (root/name).write_text(name)
            parent = dict(complete=True,
                          canonicalSources={n: sha(root/n) for n in ('runtime.c', 'tests/test.scm')},
                          generatedArtifacts={'generated.c': sha(root/'generated.c')},
                          artifacts={'gsi': sha(root/'gsi')})
            for name in ('runtime.c', '../tests/test.scm'):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    prepare_consumers(root, parent, {name: b'changed'})
            prepare_consumers(root, parent, {'tests/test.scm': b'new test'})
            self.assertEqual((root/'runtime.c').read_text(), 'runtime.c')
            self.assertEqual((root/'gsi').read_text(), 'gsi')
            (root/'tests/test.scm').write_text('unregistered drift')
            with self.assertRaises(ValueError):
                prepare_consumers(root, parent, {'tests/test.scm': b'new test'})
    def test_failed_native_phase_restores_the_pinned_seed(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'gsc-boot').write_text('pinned compiler')

            def fail_phase(*args):
                self.assertTrue((root/'gsc-boot').is_dir())
                self.assertEqual((root/'gsc-boot.native-stage-disabled').read_text(),
                                 'pinned compiler')
                raise ValueError('native compiler failed')

            ctx = SimpleNamespace(require=fail_phase, remaining=lambda: 30)
            with self.assertRaisesRegex(ValueError, 'native compiler failed'):
                compile_phases(ctx, root, ['make'])
            self.assertEqual((root/'gsc-boot').read_text(), 'pinned compiler')
            self.assertFalse((root/'gsc-boot.native-stage-disabled').exists())

    def test_missing_native_output_is_rebuilt_only_under_explicit_custody(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            names = ('runtime.c', 'generated.c', 'gsc-boot', 'library.a')
            for name in names:
                (root/name).write_text(name)
            parent = dict(complete=True, canonicalSources={'runtime.c': sha(root/'runtime.c')},
                          generatedArtifacts={'generated.c': sha(root/'generated.c')},
                          artifacts={n: sha(root/n) for n in ('gsc-boot', 'library.a')})
            (root/'library.a').unlink()
            with self.assertRaises(FileNotFoundError):
                authenticate_predecessor(root, parent)
            authenticate_predecessor(root, parent, ('library.a',))
            # Recovery authorizes compilation, never substituting new bytes
            # for an existing artifact or losing the pinned generation seed.
            (root/'library.a').write_text('corrupt')
            with self.assertRaises(ValueError):
                authenticate_predecessor(root, parent, ('library.a',))
            for name in ('gsc-boot', 'generated.c'):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    authenticate_predecessor(root, parent, (name,))

    def test_short_or_nonfinite_workload_cannot_supply_a_cost_sample(self):
        for output in ('(result . 4095) (real-time . 0.01)',
                       '(result . 4096) (real-time . nan)',
                       '(result . 4096) (real-time . -1)'):
            with self.subTest(output=output), self.assertRaises(ValueError):
                request_observation(output, False)

    def test_request_success_does_not_attest_continuation_and_gc_population(self):
        output = '(result . 4096) (real-time . 0.01)'
        self.assertEqual(request_observation(output, False)['requests'], 4096)
        with self.assertRaises(ValueError):
            request_observation(output, True)

    def test_allocation_counter_is_not_admitted_even_when_body_is_complete(self):
        row = request_observation(
            '(result . 4096) (real-time . 0.01) (bytes-allocated . -8)', False)
        self.assertEqual(row['rawBytesAllocated'], -8)
        self.assertFalse(row['allocationCounterAdmitted'])

    def test_late_header_selection_must_reach_actual_preprocessed_host(self):
        macros = ('#define ___PRM(i,g) ___binding_primitive(v,g)\n'
                  '#define ___GLO(i,g) ___binding_global(v,g)\n'
                  '#define ___BEGIN_COD view=&ps->context->binding_view;\n')
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'include').mkdir()
            (root/'include/gambit.h').write_text('header')
            generated = root/'host.c'
            generated.write_text('host')
            ctx = SimpleNamespace(tools={'gcc': 'qualified-compiler'},
                                  require=lambda *args: macros)
            self.assertTrue(generated_accessors(ctx, root, generated)['complete'])
            # The historical silent legacy expansion must fail even when the
            # header source contains the desired accessor definitions.
            for selected in ('___binding_primitive', '___binding_global',
                             'context->binding_view'):
                ctx.require = lambda *args, selected=selected: macros.replace(selected, 'legacy')
                with self.subTest(selected=selected), self.assertRaises(ValueError):
                    generated_accessors(ctx, root, generated)
