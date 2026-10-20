"""Real pinned Gambit bytes, Scheme impact closure and cross-process read hints.

Only small source copies are changed. No runtime build or native stress executes.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from gambit_smp.ascent_program import engine_api
from gambit_smp.evidence_views import evaluate
from gambit_smp.framework import ROOT, digest
from gambit_smp.trajectory_exploration import repository_clues

VIEW = 'evidence/scenarios/stack-header/source-byte-clues.view.json'
SUMMARIES = [name + '-understanding' for name in ('msection-unit', 'msection-size', 'msection-allocation')]


class RealSourceImpactTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True, capture_output=True)
        self.document = self.copy_fixture(self.root)

    @staticmethod
    def copy_fixture(root):
        document = json.loads((ROOT / VIEW).read_text())
        names = {VIEW, document['manifest'],
                 'evidence/scenarios/stack-header/source-understanding.ss',
                 'evidence/scenarios/stack-header/clues.ss',
                 *(row['path'] for row in document['references'])}
        for name in names:
            target = root / name
            if target.exists():
                raise ValueError('fixture destination already contains source')
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        (root / 'evidence/views.json').write_text(json.dumps({
            'schema': 'ascent.evidence-views.v1', 'views': [VIEW],
            'selection': json.loads((ROOT / 'evidence/views.json').read_text())['selection']}))
        (root / 'models/gambit').mkdir(parents=True)
        (root / 'models/gambit/cases.json').write_text('{}\n')
        storage = root / 'evidence/dsl'
        storage.mkdir()
        for name in ('storage.ss', 'history.ss'):
            shutil.copyfile(ROOT / 'evidence/dsl' / name, storage / name)
        manifest = json.loads((ROOT / 'evidence/dsl/components.json').read_text())
        manifest['components'] = [row for row in manifest['components'] if row['id'] == 'state-storage']
        (storage / 'components.json').write_text(json.dumps(manifest))
        return document

    def save(self):
        (self.root / VIEW).write_text(json.dumps(self.document))

    def child(self, **request):
        code = ('import json,sys; from gambit_smp import repository_clues; '
                'r=json.load(sys.stdin); print(json.dumps(repository_clues(**r)))')
        result = subprocess.run([sys.executable, '-c', code],
            input=json.dumps(dict(root=str(self.root), **request)), text=True,
            capture_output=True, timeout=30, check=True)
        return json.loads(result.stdout)

    def test_actual_callers_macros_and_unobserved_configuration_have_distinct_status(self):
        with engine_api() as (engine, _):
            answers = evaluate(self.root, VIEW, engine)['answers']
        for caller in ('setup-heap-caller-bytes', 'resize-heap-caller-bytes'):
            self.assertIn(('word-layout-bytes', caller), answers['impact_path'])
            self.assertIn(('word-rounding-bytes', caller), answers['impact_path'])
            self.assertIn((caller, 'address-mode-bytes', 'unregistered-dependency'),
                          answers['impact_unresolved'])
        self.assertIn(('address-mode-bytes', 'active-generated-configuration',
                       'unobserved-configuration'), answers['impact_gap'])
        self.assertEqual(set(answers['summary_reusable']),
                         {('msection-unit-understanding',), ('msection-size-understanding',)})
        self.assertNotIn(('msection-allocation-understanding',), answers['summary_reusable'])

    def test_unbound_scope_discovers_names_without_dumping_bodies_or_inventing_a_hit(self):
        first = repository_clues(self.root, bindings=())
        brief = first['brief']
        self.assertEqual(brief['association']['unbound_scope'], [[]])
        self.assertIn(['entity'], brief['association']['available_factor'])
        self.assertEqual(brief['association']['question'], [])
        self.assertEqual(brief['families'], [])
        self.assertEqual(brief['counts']['support'], 0)
        self.assertFalse(brief['runtimeAdmitted'])
        self.assertNotIn('#define ___MSECTION_SIZE', json.dumps(first))
        linked = repository_clues(self.root, bindings=(('entity', 'msection'),),
                                  checkpoint=first['checkpoint'])
        self.assertEqual(linked['brief']['association']['unbound_scope'], [])
        self.assertEqual(linked['brief']['counts']['support'], 16)
        self.assertEqual(linked['brief']['counts']['hypotheses'], 3)
        self.assertTrue(linked['brief']['families'])

    def test_cli_accepts_explicit_unbound_discovery_but_not_an_absent_request(self):
        command = [sys.executable, '-m', 'gambit_smp', '--root', str(self.root), 'trajectory', 'clues']
        accepted = subprocess.run(command, input='((bindings ()))', text=True,
                                  capture_output=True, timeout=30)
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertIn('unbound_scope', accepted.stdout)
        self.assertNotIn('#define ___MSECTION_SIZE', accepted.stdout)
        absent = subprocess.run(command, input='()', text=True, capture_output=True, timeout=30)
        self.assertNotEqual(absent.returncode, 0)

    def test_fresh_context_recovers_summaries_and_cache_cleanup_preserves_read_history(self):
        first = repository_clues(self.root, SUMMARIES)
        continued = self.child(question=SUMMARIES, checkpoint=first['checkpoint'])
        self.assertEqual(continued['brief']['families'], [])
        cache = self.root / '.cache'
        cache.mkdir(exist_ok=True)
        (cache / 'disposable').write_text('not evidence')
        shutil.rmtree(cache)
        resumed = self.child(question=SUMMARIES, checkpoint=continued['checkpoint'])
        self.assertEqual(resumed['brief']['families'], [])
        recap = self.child(question=SUMMARIES)
        self.assertEqual({f['claim'] for f in recap['brief']['families']}, set(SUMMARIES))
        self.assertIn('understanding-summary', json.dumps(recap))
        self.assertNotIn('#define ___MSECTION_SIZE', json.dumps(recap))
        self.assertFalse(recap['brief']['runtimeAdmitted'])

    def change_fixture_macro(self):
        path = self.root / 'vendor/gambit/lib/mem.h'
        before = path.read_bytes()
        old, new = b'#define ___MSECTION_SIZE        131072', b'#define ___MSECTION_SIZE        65536'
        self.assertEqual(before.count(old), 1)
        at = before.index(old)
        after = before.replace(old, new)
        path.write_bytes(after)
        for ref in self.document['references']:
            if ref['path'] != 'vendor/gambit/lib/mem.h':
                continue
            ref['sha256'] = digest(path)
            for span in ref.get('ranges', []):
                if span['start'] > at:
                    span['start'] -= 1
                if span['end'] > at:
                    span['end'] -= 1
                span['sha256'] = hashlib.sha256(after[span['start']:span['end']]).hexdigest()
        self.save()

    def test_real_macro_edit_reopens_only_affected_understanding_then_expands_checked_bytes(self):
        first = repository_clues(self.root, SUMMARIES)
        self.change_fixture_macro()
        changed = self.child(question=SUMMARIES, checkpoint=first['checkpoint'])
        claims = {f['claim'] for f in changed['brief']['families']}
        self.assertEqual(claims, {'msection-size-understanding', 'msection-allocation-understanding'})
        self.assertIn('msection-size-bytes', json.dumps(changed))
        self.assertNotIn('#define ___MSECTION_SIZE', json.dumps(changed))
        expanded = self.child(question='msection-size-source-bytes')
        self.assertIn('#define ___MSECTION_SIZE        65536', json.dumps(expanded))
        self.assertFalse(expanded['brief']['runtimeAdmitted'])

    def test_disjoint_enclosing_file_edit_does_not_redisplay_unchanged_summary(self):
        first = repository_clues(self.root, SUMMARIES)
        path = self.root / 'vendor/gambit/lib/mem.c'
        path.write_bytes(path.read_bytes() + b'\n/* unrelated fixture tail */\n')
        for ref in self.document['references']:
            if ref['path'] == 'vendor/gambit/lib/mem.c':
                ref['sha256'] = digest(path)
        self.save()
        after = self.child(question=SUMMARIES, checkpoint=first['checkpoint'])
        self.assertEqual(after['brief']['families'], [])


if __name__ == '__main__':
    unittest.main()
