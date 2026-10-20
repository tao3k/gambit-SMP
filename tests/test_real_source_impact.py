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
        self.document = json.loads((ROOT / VIEW).read_text())
        names = {VIEW, self.document['manifest'],
                 'evidence/scenarios/stack-header/source-understanding.ss',
                 *(row['path'] for row in self.document['references'])}
        for name in names:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        (self.root / 'evidence/views.json').write_text(json.dumps({
            'schema': 'ascent.evidence-views.v1', 'views': [VIEW]}))

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

    def test_real_macro_edit_reopens_only_affected_understanding_then_expands_checked_bytes(self):
        first = repository_clues(self.root, SUMMARIES)
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
