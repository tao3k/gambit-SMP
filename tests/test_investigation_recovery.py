"""Real Scheme hypothesis submission, durable journal and Clue restart recovery."""
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch
from ascent import EngineError

from gambit_smp.trajectory_exploration import repository_clues, repository_submit
from tests import test_source_block_clues

DECLARATION = '''(define-evidence (query)
 (sources) (outputs clue factor)
 (relation clue (id claim polarity source))
 (relation factor (id name value))
 (fact (clue "interrupt-hypothesis" "interrupt-cause" "support" "agent:investigation"))
 (fact (factor "interrupt-hypothesis" "candidate" "retained-producer"))
 (fact (factor "interrupt-hypothesis" "unknown" "inner-exception"))
 (fact (factor "interrupt-hypothesis" "counterevidence" "common-cause-not-established")))'''


def after_restart(root, checkpoint):
    root = Path(root)
    with patch('gambit_smp.artifact_storage.durable_database_path', return_value=root/'history.sqlite3'):
        return repository_clues(root, 'interrupt-cause', checkpoint=checkpoint)


class InvestigationRecoveryTests(unittest.TestCase):
    def setUp(self):
        fixture = test_source_block_clues.SourceBlockClueTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.fixture, self.root = fixture, fixture.root

    def test_native_scheme_submission_survives_fresh_process_and_retains_scope(self):
        written = repository_submit(self.root, DECLARATION, scope='repair-case')
        self.assertFalse(written['executionAuthorized'])
        first = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        family = first['brief']['families'][0]
        self.assertEqual(family['claim'], 'interrupt-cause')
        self.assertEqual(len(family['hypotheses']), 1)
        self.assertEqual(family['observations'], [])
        self.assertIn('inner-exception', json.dumps(family))
        code = ('import json,sys; from tests.test_investigation_recovery import after_restart; '
                'print(json.dumps(after_restart(*json.load(sys.stdin))))')
        child = subprocess.run([sys.executable, '-c', code],
            input=json.dumps([str(self.root), first['checkpoint']]), text=True,
            capture_output=True, timeout=30, check=True)
        resumed = json.loads(child.stdout)
        self.assertEqual(resumed['brief']['families'], [])
        self.assertEqual(resumed['brief']['hypothesisJournal']['scope'], 'repair-case')
        self.assertEqual(resumed['brief']['hypothesisJournal']['retainedHypotheses'], 1)
        self.assertFalse(resumed['brief']['runtimeAdmitted'])
        fresh = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        self.assertEqual(len(fresh['brief']['families'][0]['hypotheses']), 1)

    def test_source_update_does_not_erase_or_promote_retained_investigation(self):
        repository_submit(self.root, DECLARATION, scope='repair-case')
        first = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        self.fixture.document['facts']['attribute'].append(['word-block', 'unrelated', 'new'])
        self.fixture.save()
        changed = repository_clues(self.root, 'interrupt-cause', checkpoint=first['checkpoint'])
        self.assertEqual(changed['brief']['families'], [])
        fresh = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        family = fresh['brief']['families'][0]
        self.assertEqual(family['observations'], [])
        self.assertIn('recorded-input-identity', json.dumps(family))
        other = repository_clues(self.root, 'interrupt-cause', scope='different-investigation')
        self.assertEqual(other['brief']['hypothesisJournal']['retainedHypotheses'], 0)

    def test_related_failure_remains_discoverable_without_relaxing_the_anchor(self):
        views = self.root / 'evidence/views.json'
        registration = json.loads(views.read_text())
        registration['selection'] = dict(source='evidence/clues.ss', constructor='make-stack-entry-navigation')
        views.write_text(json.dumps(registration))
        source = '''(define-evidence (query)
 (sources) (outputs clue factor)
 (relation clue (id claim polarity source))
 (relation factor (id name value))
 (fact (clue "old" "old-frontier" "support" "agent:old"))
 (fact (factor "old" "repair-contract" "gc-ffi"))
 (fact (factor "old" "timed-out-file" "tfib.scm"))
 (fact (clue "new" "new-failure" "counter" "agent:new"))
 (fact (factor "new" "first-file" "tfib.scm")))'''
        repository_submit(self.root, source, scope='repair-case')
        bindings = [('repair-contract', 'gc-ffi'), ('timed-out-file', 'tfib.scm')]
        first = repository_clues(self.root, bindings=bindings, scope='repair-case')
        association = first['brief']['association']
        self.assertEqual(association['question'], [['old-frontier']])
        related = association['related_observation']
        self.assertEqual(len(related), 1)
        self.assertEqual(related[0][0:2], ['new-failure', 'new'])
        self.assertEqual(related[0][3:], ['timed-out-file', 'tfib.scm', 'first-file',
                                         'file-frontier-context-only'])
        gaps = {(row[3], row[4]) for row in association['related_condition_gap']}
        self.assertEqual(gaps, set(bindings))
        self.assertEqual([row['claim'] for row in first['brief']['families']], ['old-frontier'])
        self.assertFalse(first['brief']['runtimeAdmitted'])
        expanded = repository_clues(self.root, bindings=bindings, scope='repair-case',
            checkpoint=first['checkpoint'], expansions=['new-failure'])
        self.assertIn('new-failure', {row['claim'] for row in expanded['brief']['families']})
        self.assertFalse(expanded['brief']['runtimeAdmitted'])
        other = repository_clues(self.root, bindings=[('timed-out-file', 'other.scm')], scope='repair-case')
        self.assertEqual(other['brief']['association']['related_observation'], [])

    def test_task_scope_and_duplicate_conflict_do_not_overwrite_history(self):
        with patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': 'repair-case',
                                     'GAMBIT_SMP_TASK_ROOT': str(self.root)}):
            repository_submit(self.root, DECLARATION)
            with self.assertRaisesRegex(ValueError, 'already retained'):
                repository_submit(self.root, DECLARATION)
            found = repository_clues(self.root, 'interrupt-cause')
        self.assertEqual(found['brief']['hypothesisJournal']['retainedHypotheses'], 1)
        self.assertEqual(len(found['brief']['families'][0]['hypotheses']), 1)

    def test_scoped_opposed_hypotheses_remain_visible_without_evidence_promotion(self):
        views = self.root / 'evidence/views.json'
        registration = json.loads(views.read_text())
        registration['selection'] = dict(source='evidence/clues.ss', constructor='make-stack-entry-navigation')
        views.write_text(json.dumps(registration))
        repository_submit(self.root, DECLARATION, scope='repair-case')
        counter = DECLARATION.replace('interrupt-hypothesis', 'interrupt-counter').replace('"support"', '"counter"')
        repository_submit(self.root, counter, scope='repair-case')
        found = repository_clues(self.root, bindings=[('candidate', 'retained-producer')], scope='repair-case')
        rows = found['brief']['association']['hypothesis_disagreement']
        self.assertEqual(1, len(rows))
        self.assertEqual(['interrupt-cause', 'interrupt-hypothesis', 'interrupt-counter'],
                         [rows[0][0], rows[0][1], rows[0][3]])
        family = found['brief']['families'][0]
        self.assertEqual([], family['observations'])
        self.assertTrue(family['unknown'])
        self.assertFalse(found['brief']['runtimeAdmitted'])
        other = counter.replace('interrupt-counter', 'other-counter').replace('retained-producer', 'other-producer')
        repository_submit(self.root, other, scope='repair-case')
        scoped = repository_clues(self.root, bindings=[('candidate', 'other-producer')], scope='repair-case')
        self.assertEqual([], scoped['brief']['association']['hypothesis_disagreement'])

    def test_read_dispatch_preserves_explicit_task_without_an_execution_lease(self):
        from gambit_smp.cli import main
        from gambit_smp.task_entry import _observation_address
        repository_submit(self.root, DECLARATION, scope='repair-case')
        with patch('gambit_smp.framework.project_root', return_value=self.root), \
             patch('gambit_smp.workspace.execution_scope', side_effect=AssertionError('no execution for reads')):
            result = main(['--task', 'repair-case', 'trajectory', 'clues', '((questions ("interrupt-cause")))'],
                _callback=lambda: repository_clues(self.root, 'interrupt-cause'))
        self.assertEqual(result['brief']['hypothesisJournal']['retainedHypotheses'], 1)
        self.assertIsNone(_observation_address.get())

    def test_submit_dispatch_retains_hypothesis_while_execution_lease_is_held(self):
        from gambit_smp import workspace
        from gambit_smp.cli import main
        from gambit_smp.task_entry import _observation_address
        with workspace.lease(self.root, 'repair-case'), \
                patch('gambit_smp.framework.project_root', return_value=self.root), \
                patch('gambit_smp.workspace.execution_scope', side_effect=AssertionError('journal is not execution')):
            result = main(['--task', 'repair-case', 'trajectory', 'submit', 'hypothesis.ss'],
                _callback=lambda: repository_submit(self.root, DECLARATION))
        self.assertFalse(result['executionAuthorized'])
        self.assertFalse(result['runtimeAdmitted'])
        found = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        self.assertEqual(found['brief']['hypothesisJournal']['retainedHypotheses'], 1)
        self.assertEqual(found['brief']['families'][0]['observations'], [])
        self.assertIsNone(_observation_address.get())

    def test_wire_checkpoint_and_missing_read_hint_preserve_the_durable_journal(self):
        from gambit_smp.ascent_program import engine_api
        from gambit_smp.reasoning_history import _database
        from gambit_smp.trajectory_exploration import _clue_output
        repository_submit(self.root, DECLARATION, scope='repair-case')
        with patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': 'repair-case',
                                     'GAMBIT_SMP_TASK_ROOT': str(self.root)}), engine_api() as (engine, _):
            packet, frame = _clue_output(self.root, {'questions': ['interrupt-cause']}, engine, wire_bytes=8192)
        self.assertLessEqual(len(frame.encode()), 8192)
        with engine_api() as (engine, _):
            resumed, _ = _clue_output(self.root, {'checkpoint': packet['checkpoint']}, engine, wire_bytes=8192)
        self.assertEqual(resumed['brief']['families'], [])
        self.assertEqual(resumed['brief']['hypothesisJournal']['scope'], 'repair-case')
        with _database(self.root) as db:
            db.execute('DELETE FROM clue_read_checkpoints')
        replay = repository_clues(self.root, 'interrupt-cause', scope='repair-case', checkpoint=resumed['checkpoint'])
        self.assertEqual(replay['brief']['checkpointStatus'], 'cache-miss')
        self.assertEqual(replay['brief']['hypothesisJournal']['retainedHypotheses'], 1)
        self.assertEqual(len(replay['brief']['families'][0]['hypotheses']), 1)

    def test_orphan_factors_and_nonrelational_host_callbacks_are_rejected(self):
        malformed = DECLARATION.replace('(fact (factor "interrupt-hypothesis" "candidate"',
                                        '(fact (factor "unknown-id" "candidate"')
        with self.assertRaisesRegex(ValueError, 'unique clue'):
            repository_submit(self.root, malformed, scope='repair-case')
        with self.assertRaises(EngineError):
            repository_submit(self.root, '(system "not-a-relational-declaration")', scope='repair-case')
        result = repository_clues(self.root, 'interrupt-cause', scope='repair-case')
        self.assertEqual(result['brief']['hypothesisJournal']['retainedHypotheses'], 0)

    def test_wire_folding_binds_once_and_does_not_acknowledge_unpublished_trials(self):
        from ascent.trajectory import ClueExchange
        from gambit_smp.ascent_program import engine_api
        from gambit_smp import trajectory_exploration as trajectory
        repository_submit(self.root, DECLARATION, scope='repair-case')
        rendered = []
        render = ClueExchange.render

        def fold_once(packet):
            rendered.append(packet)
            return render(packet) + (' ' * 8192 if len(rendered) == 1 else '')

        with patch.dict('os.environ', {'GAMBIT_SMP_TASK_ID': 'repair-case',
                                      'GAMBIT_SMP_TASK_ROOT': str(self.root)}), engine_api() as (engine, _), \
                patch.object(trajectory, '_repository_snapshot', wraps=trajectory._repository_snapshot) as snapshot, \
                patch.object(trajectory, '_native_exchange', wraps=trajectory._native_exchange) as exchange, \
                patch.object(ClueExchange, 'render', side_effect=fold_once):
            packet, frame = trajectory._clue_output(self.root, {'questions': ['interrupt-cause']}, engine, wire_bytes=8192)
        self.assertGreater(len(rendered), 1)
        self.assertEqual(1, snapshot.call_count)
        self.assertEqual(1, exchange.call_count)
        self.assertEqual(['interrupt-cause'], [family['claim'] for family in packet['brief']['families']])
        self.assertLessEqual(len(frame.encode()), 8192)
        replay = repository_clues(self.root, 'interrupt-cause', scope='repair-case',
                                  checkpoint=packet['checkpoint'], read_confirmed=False)
        self.assertEqual(['interrupt-cause'], [family['claim'] for family in replay['brief']['families']])
