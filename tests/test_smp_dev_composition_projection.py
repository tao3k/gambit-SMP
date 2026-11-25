from hashlib import sha256
from pathlib import Path
import unittest
import tempfile
import shutil
import json

from gambit_smp.smp_dev_composition_projection import (
    SOURCE_OBLIGATIONS, _validate_cursor_negative, _verified_receipt, project_deopt_transitions, project_model_symbols, project_open_families,
    project_source_obligations, source_observations,
)

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / 'dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml'
NAMES = ('stress-gsi', 'stress-gsc', 'registry', 'lifecycle', 'gc-ffi', 'gerbil', 'release')


def rows():
    return [{'id': number, 'name': name, 'needs': 'round,product'}
            for number, name in enumerate(NAMES, 6)]


class CompositionProjectionTest(unittest.TestCase):
    def test_declared_families_remain_open(self):
        result = project_open_families(ROOT, rows(), sha256(MODEL.read_bytes()).hexdigest())
        self.assertEqual({r[0] for r in result['gap']}, set(NAMES))
        self.assertEqual(result['candidate'], [])

    def test_incomplete_or_stale_declaration_is_rejected(self):
        for mutation in ('missing', 'duplicate', 'owner', 'stale'):
            with self.subTest(mutation=mutation):
                declarations = rows()
                digest = sha256(MODEL.read_bytes()).hexdigest()
                if mutation == 'missing':
                    declarations.pop()
                elif mutation == 'duplicate':
                    declarations[-1] = declarations[0]
                elif mutation == 'owner':
                    declarations[0]['needs'] = 'round,unknown,product'
                else:
                    digest = 'stale'
                with self.assertRaises(ValueError):
                    project_open_families(ROOT, declarations, digest)

    def test_source_anchors_do_not_close_native_obligations(self):
        result = project_source_obligations(ROOT)
        self.assertEqual({r[0] for r in result['relations']['gap']}, set(SOURCE_OBLIGATIONS))
        self.assertEqual(result['relations']['candidate'], [])

    def test_model_actions_do_not_close_source_refinements(self):
        result = project_model_symbols(ROOT)
        self.assertEqual(len(result['relations']['symbolLinked']), 15)
        self.assertEqual({r[0] for r in result['relations']['gap']},
                         {'resume-bridge', 'interpreter-deopt'})
        self.assertEqual(result['relations']['candidate'], [])

    def test_deoptimization_mapping_stays_open_and_rejects_wrong_action(self):
        mapping = {'classify': 'tailCall', 'compact': 'collect', 'capture-request': 'requestCapture',
                   'materialize-begin': 'beginMaterialization', 'materialize-commit': 'materialize',
                   'capture-commit': 'capture', 'binding-guard': 'fastEffect',
                   'later-poll-observation': 'inspectLaterPoll'}
        transitions = [{'id': k, 'qntAction': v} for k, v in mapping.items()]
        model = ROOT / 'dev/refactoring/modern-c/models/sysml/smp-interpreter-tail-deopt.sysml'
        digest = sha256(model.read_bytes()).hexdigest()
        result = project_deopt_transitions(ROOT, transitions, digest)
        self.assertEqual({r[0] for r in result['relations']['gap']}, set(mapping))
        self.assertEqual(result['relations']['candidate'], [])
        transitions[0]['qntAction'] = 'capture'
        with self.assertRaises(ValueError):
            project_deopt_transitions(ROOT, transitions, digest)

    def test_missing_model_action_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            names = [
                'dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml',
                'dev/refactoring/modern-c/models/quint/smp_resume_barrier_bridge.qnt',
                'dev/refactoring/modern-c/models/quint/smp_interpreter_tail_deopt.qnt',
            ]
            for name in names:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, path)
            path = root / names[-1]
            path.write_text(path.read_text().replace('action beginMaterialization =',
                                                     'action renamed =', 1))
            with self.assertRaises(ValueError):
                project_model_symbols(root)

    def test_missing_ordered_anchor_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)
            for files in SOURCE_OBLIGATIONS.values():
                for name in files:
                    path = target / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(ROOT / name, path)
            path = target / 'vendor/gambit/lib/_mem/collection-round.inc'
            text = path.read_text().replace('___RESUME(___vms,worker_id).restored=1;',
                                            '/* missing restored publication */', 1)
            path.write_text(text)
            with self.assertRaises(ValueError):
                source_observations(target)

    def test_native_receipt_requires_exact_bytes_and_quiescent_children(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / 'receipt.json'
            record = {'restored': True, 'artifacts': {'gsi': 'abc'}, 'commands': [
                {'parentReaped': True, 'processGroupQuiescent': True,
                 'exit': 0, 'timeout': False}]}
            path.write_text(json.dumps(record))
            row = {'path': 'receipt.json', 'sha256': sha256(path.read_bytes()).hexdigest(),
                   'artifacts': record['artifacts']}
            self.assertEqual(_verified_receipt(root, row), record)
            record['commands'][0]['processGroupQuiescent'] = False
            path.write_text(json.dumps(record))
            with self.assertRaises(ValueError):
                _verified_receipt(root, row)
            row['sha256'] = sha256(path.read_bytes()).hexdigest()
            with self.assertRaises(ValueError):
                _verified_receipt(root, row)

    def test_cursor_negative_requires_prewrite_rejection_and_keeps_gate_open(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / 'vendor/gambit/tests/smp/gc/restore-first-cursor-negative-probe.h'
            fixture.parent.mkdir(parents=True)
            fixture.write_text('diagnostic fixture')
            packet = {'runtimeAdmitted': False, 'acceptedSmp': 5,
                      'fixtureSha256': sha256(fixture.read_bytes()).hexdigest(), 'receipts': {}}
            for name in ('first-build', 'first-positive', 'first-negative'):
                record = {'restored': True, 'runtimeAdmitted': False, 'profileSha256': 'profile',
                          'sourceDelta': {'source': 'digest'}, 'artifacts': {'gsi': 'digest'},
                          'commands': [{'parentReaped': True, 'processGroupQuiescent': True,
                                        'exit': 0, 'timeout': False}]}
                if name == 'first-build':
                    record['complete'] = True
                else:
                    mode = name.removeprefix('first-')
                    record['probeComplete'] = True
                    record['probe'] = {'mode': mode, 'exit': 0, 'timeout': False,
                                       'stdout': 'PROCESSORS:2\n' + ('PROBE-DONE' if mode == 'positive' else ''),
                                       'stderr': 'DEV-FIRST-CURSOR-' + mode.upper() + ' words=6' +
                                                 (' rejected-before-write' if mode == 'negative' else '')}
                path = root / (name + '.json')
                path.write_text(json.dumps(record))
                packet['receipts'][name] = {'path': path.name, 'sha256': sha256(path.read_bytes()).hexdigest(),
                                            'result': record}
            _validate_cursor_negative(root, packet, 'profile')
            row = packet['receipts']['first-negative']
            row['result']['probe']['stderr'] = 'DEV-FIRST-CURSOR-NEGATIVE words=6'
            path = root / row['path']
            path.write_text(json.dumps(row['result']))
            row['sha256'] = sha256(path.read_bytes()).hexdigest()
            with self.assertRaises(ValueError):
                _validate_cursor_negative(root, packet, 'profile')
