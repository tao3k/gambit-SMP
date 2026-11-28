"""Contract/transport controls. Native Family A scenarios remain separate."""
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import rest_observation as obs
from gambit_smp import family6_recipes
from gambit_smp.framework import ROOT, digest
from gambit_smp.task_processes import run


NATURAL = dict(exit=0, timeout=False, processGroupQuiescent=True)


def contract(checklist=9, situation='race'):
    return dict(schema='family6-rest-observation-contract.v1', gsiSha256='a'*64,
                sourceFiles={p: 'b'*64 for p in obs.required_sources([{'checklist': checklist, 'situation': situation}])}, capacity=1024,
                cases=[dict(id=1, checklist=checklist, spelling='ordinary', situation=situation)])


def event(kind, actor=1, values=(), activation=0, attempt=0, epoch=1):
    return dict(seq=0, kind=kind, case=1, actor=actor, activation=activation,
                attempt=attempt, epoch=epoch, values=list(values)+[0]*(8-len(values)))


def trace(rows):
    rows = [event('case-begin', 0), *copy.deepcopy(rows), event('case-end', 0)]
    for i, row in enumerate(rows, 1):
        row['seq'] = i
    return dict(events=rows, reserved=len(rows), dropped=0, holes=[], closed=True, complete=True)


def wire(t, capacity=1024):
    body = b''.join(obs.RECORD.pack(e['seq'], obs.KINDS.index(e['kind'])+1, e['case'], e['actor'],
                        e['activation'], e['attempt'], e['epoch'], *e['values'], 0) for e in t['events'])
    return obs.HEADER.pack(obs.MAGIC, 1, capacity, len(t['events']), 0, 1, 16, 0)+body+b'\0'*(capacity*128-len(body))


def race(*, total=4, cap_sections=None, assigned=3):
    def row(kind, actor, values):
        return event(kind, actor, values, activation=20+actor, attempt=100+actor)
    still, section_words = 23, 50
    cap_bytes = 0 if cap_sections is None else 8 * (still + section_words * cap_sections)
    after = assigned + 1
    successor = 601 if total > after else 0
    refusal = 1 if cap_sections is not None else 2
    return trace([
        row('section-view', 1, (500, 0, 4096, 4128, 4280, 8000, 8, 6)),
        row('lock-request', 1, (100, 0, 8, 4096, 4280, 16, 8000)),
        row('section-view', 2, (501, 0, 8192, 8224, 8376, 10000, 8, 6)),
        row('lock-request', 2, (100, 1, 8, 8192, 8376, 16, 10000)),
        row('lock', 1, (100, 500, assigned, total, cap_bytes, still, section_words, 600)),
        row('capacity', 1, (100, 600, 8, 8000, 500, assigned, successor, 128)),
        row('claim', 1, (100, 600, 9, 8, 600, after, 16384, 128)), row('unlock', 1, (100,)),
        row('lock', 2, (100, 600, after, total, cap_bytes, still, section_words, successor)),
        row('refuse', 2, (100, 600, after, refusal)),
        row('unlock', 2, (100,)),
        row('section-published', 1, (100, 600, 128, 16384, 16456, 16584, 8, 16)),
        row('section-view', 1, (600, 128, 16384, 16456, 16584, 8000, 8, 7))])


def statuses(report):
    return {c['obligation']: c['status'] for c in report['cases'][0]['checks']}


def tool(name, override=None):
    selected = shutil.which(os.environ.get(override, name) if override else name)
    if selected is None:
        raise RuntimeError('Required test tool is not available on PATH: '+name)
    # Preserve argv[0]: multicall launchers such as elan dispatch "lean" by
    # the selected symlink name. Resolve only when recording file identity.
    return Path(selected).absolute()


class BoundaryMeasurementTests(unittest.TestCase):
    def test_locked_final_section_cut_and_old_snapshot_refund_counterexample(self):
        good = obs.project(contract(), race(), NATURAL)
        self.assertTrue(all(s == 'pass' for s in statuses(good).values()), good)
        bad = race()
        next(e for e in bad['events'] if e['kind'] == 'refuse')['values'][1:3] = [500, 3]
        report = obs.project(contract(), bad, NATURAL)
        self.assertEqual(statuses(report)['loser-preserves-winner'], 'fail')
        self.assertEqual(statuses(report)['locked-capacity-claim'], 'fail')
        self.assertTrue(report['cases'][0]['firstFailedContract']['witness'])

    def test_sequential_or_other_vm_is_not_contention(self):
        t = race()
        requests = [e for e in t['events'] if e['kind'] == 'lock-request']
        requests[1]['seq'] = 100
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['real-contention'], 'fail')
        t = race()
        next(e for e in t['events'] if e['kind'] == 'lock' and e['actor'] == 2)['values'][0] = 200
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['real-contention'], 'fail')

    def test_race_requires_post_unlock_publication_and_same_attempt_recheck(self):
        for kind, target in [('section-published', 'winner-post-unlock-publication'),
                             ('section-view', 'winner-renewed-grant')]:
            t = race()
            t['events'].remove(next(e for e in reversed(t['events']) if e['kind'] == kind))
            self.assertEqual(statuses(obs.project(contract(), t, NATURAL))[target], 'missing')
        for field, value in [('attempt', 999), ('epoch', 2)]:
            t = race()
            next(e for e in t['events'] if e['kind'] == 'section-published')[field] = value
            self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['winner-post-unlock-publication'], 'fail')
        for slot, value in [(2, 0), (3, 16376), (4, 16416), (6, 9)]:
            t = race()
            next(e for e in t['events'] if e['kind'] == 'section-published')['values'][slot] = value
            self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['winner-post-unlock-publication'], 'fail')
        t = race()
        publication = next(e for e in t['events'] if e['kind'] == 'section-published')
        publication['seq'] = next(e['seq'] for e in t['events'] if e['kind'] == 'claim')
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['winner-post-unlock-publication'], 'fail')
        t = race()
        next(e for e in reversed(t['events']) if e['kind'] == 'section-view')['values'][7] = 6
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['winner-renewed-grant'], 'fail')

    def test_race_requires_physical_shortage_and_last_eligible_candidate(self):
        t = race()
        next(e for e in t['events'] if e['kind'] == 'section-view')['values'][4] = 4288
        next(e for e in t['events'] if e['kind'] == 'lock-request')['values'][4] = 4288
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['real-contention'], 'fail')
        t = race()
        next(e for e in t['events'] if e['kind'] == 'capacity')['values'][6] = 601
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['unique-last-section'], 'fail')

    def test_race_exhausts_admission_with_physical_successors(self):
        for swap in (False, True):
            t = race(total=8, cap_sections=5, assigned=4)
            if swap:
                for row in t['events']:
                    if row['actor']:
                        row['actor'] = 3 - row['actor']
            report = obs.project(contract(), t, NATURAL)
            self.assertTrue(all(s == 'pass' for s in statuses(report).values()), report)
        t = race(total=8, cap_sections=6, assigned=4)
        report = obs.project(contract(), obs.decode_trace(wire(t)), NATURAL)
        check = next(c for c in report['cases'][0]['checks'] if c['obligation'] == 'unique-last-section')
        self.assertEqual(check['status'], 'fail')
        self.assertIn('slots 2 -> 1', check['detail'])
        self.assertEqual(statuses(report)['winner-renewed-grant'], 'pass')

    def test_race_rejects_wrong_refusal_and_changed_or_missing_locked_inputs(self):
        for kind, slot, value, status in (
                ('refuse', 3, 2, 'fail'), ('lock', 4, 8 * (23 + 5 * 50), 'fail'),
                ('lock', 5, 24, 'fail'), ('lock', 6, 0, 'missing'), ('lock', 7, 0, 'fail')):
            with self.subTest(kind=kind, slot=slot):
                t = race(total=8, cap_sections=4)
                row = next(e for e in t['events'] if e['kind'] == kind and e['actor'] == 2)
                row['values'][slot] = value
                self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['unique-last-section'], status)
        t = race(total=8, cap_sections=4)
        for row in t['events']:
            if row['actor'] == 2:
                row['epoch'] += 1
        self.assertEqual(statuses(obs.project(contract(), t, NATURAL))['unique-last-section'], 'fail')

    def test_source_pin_covers_successor_and_final_read(self):
        def row(kind, values):
            return event(kind, values=values, activation=3, attempt=8)
        c = contract(7, 'cross-break')
        link = row('break-link', (700, 0, 1, 1008, 1200, 1000, 1, 8))
        successor = row('successor', (800, 128, 1, 1200, 700, 0, 1))
        # A successor read that merely repeats the old pin is not the old read.
        tagged = [row('pin', (700, 0, 1, 904, 800, 1104)), link, successor,
                  row('source-read', (800, 128, 1, 1000, 700, 0)),
                  row('unpin', (700, 0, 0))]
        self.assertEqual(statuses(obs.project(c, trace(tagged), NATURAL))['cross-break-custody'], 'missing')
        for order in (
                [row('pin', (700, 0, 1, 904, 800, 1104)), row('source-read', (700, 0, 1, 904)),
                 link, successor, row('unpin', (700, 0, 0))],
                [row('pin', (700, 0, 1, 904, 800, 1104)), link, successor,
                 row('source-read', (700, 0, 1, 904)), row('unpin', (700, 0, 0))]):
            self.assertTrue(all(s == 'pass' for s in statuses(obs.project(c, trace(order), NATURAL)).values()), order)
        released = [row('pin', (700, 0, 1, 904, 800, 1104)), row('source-read', (700, 0, 1, 904)),
                    link, row('unpin', (700, 0, 0)), successor]
        self.assertEqual(statuses(obs.project(c, trace(released), NATURAL))['cross-break-custody'], 'fail')
        late = [row('pin', (700, 0, 1, 904, 800, 1104)), row('source-read', (700, 0, 1, 904)), link, successor,
                row('unpin', (700, 0, 0)), row('source-read', (700, 0, 1, 912))]
        self.assertEqual(statuses(obs.project(c, trace(late), NATURAL))['last-old-source-read-before-release'], 'fail')
        wrong_link = copy.deepcopy(late[:-1])
        wrong_link[2]['values'][4] += 8
        self.assertEqual(statuses(obs.project(c, trace(wrong_link), NATURAL))['cross-break-custody'], 'fail')
        no_link = late[:2]+late[3:-1]
        self.assertEqual(statuses(obs.project(c, trace(no_link), NATURAL))['cross-break-custody'], 'missing')
        late_link = [*no_link[:3], link, no_link[-1]]
        self.assertEqual(statuses(obs.project(c, trace(late_link), NATURAL))['cross-break-custody'], 'fail')

    def test_full_refusal_snapshot_detects_middle_word_and_write_restore(self):
        rows = [event('native-begin', values=(1000, 2032)),
                event('heap-span', values=(1000, 1032, 1000, 1040)),
                event('stack-span', values=(2000, 2040, 2032)),
                event('argument-span', values=(2032, 2040, 2032, 0))]
        def snapshots(phase):
            return [event('snapshot', values=(region, phase, base+8*i, i, base, count))
                    for region, base, count in ((1, 1000, 5), (2, 2000, 5), (3, 2032, 1))
                    for i in range(count)]
        rows += [*snapshots(0), event('watched-demand', values=(1000, 2032, 5, 1, 1, 1, 3, 1)),
                 event('preflight', values=(5, 0, 0, 1, 1000, 2032)),
                 event('native-cut', values=(1000, 2032, 9, 1)),
                 event('argument-span', values=(2032, 2040, 2032, 1)), *snapshots(1)]
        cut = next(i for i, e in enumerate(rows) if e['kind'] == 'native-cut')
        c = contract(6, 'short')
        self.assertTrue(all(s == 'pass' for s in statuses(obs.project(c, trace(rows), NATURAL)).values()))
        exact = copy.deepcopy(rows)
        next(e for e in exact if e['kind'] == 'heap-span')['values'][1] = 1040
        next(e for e in exact if e['kind'] == 'preflight')['values'][2:4] = [1, 0]
        exact.insert(cut, event('store', values=(0, 1000)))
        self.assertTrue(all(s == 'pass' for s in statuses(obs.project(contract(6, 'exact'), trace(exact), NATURAL)).values()))
        next(e for e in exact if e['kind'] == 'store')['values'][1] = 1040
        self.assertEqual(statuses(obs.project(contract(6, 'exact'), trace(exact), NATURAL))['grant-before-store'], 'fail')
        changed = copy.deepcopy(rows)
        next(e for e in changed if e['kind'] == 'snapshot' and e['values'][:3] == [1, 1, 1016])['values'][3] = 99
        self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['refusal-effects'], 'fail')
        changed = copy.deepcopy(rows)
        changed.insert(cut, event('store', values=(2040, 1016)))
        self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['refusal-effects'], 'fail')
        changed = copy.deepcopy(rows)
        changed.pop()
        self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['whole-snapshot'], 'fail')
        for change in (event('gc-begin'), event('fp-adjust', values=(2040, 2032, 1))):
            changed = copy.deepcopy(rows)
            changed.insert(cut, change)
            self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['refusal-effects'], 'fail')
        for field, value in ((2, 4), (3, 0)):
            changed = copy.deepcopy(rows)
            changed[cut]['values'][field] = value
            self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['exact-or-short'], 'fail')
        for reserve in (2, 0):  # More than one physically short, or soft-only short.
            changed = copy.deepcopy(rows)
            changed[cut-2]['values'][5] = reserve
            self.assertEqual(statuses(obs.project(c, trace(changed), NATURAL))['exact-or-short'], 'fail')
        unsafe = copy.deepcopy(rows[:cut])
        unsafe[-1]['values'][2:4] = [1, 0]
        checks = statuses(obs.project(c, trace(unsafe), NATURAL))
        self.assertEqual(checks['exact-or-short'], 'fail')
        self.assertNotEqual(checks['refusal-effects'], 'pass')

    def moving_rows(self, form=1):
        def r(kind, values=()):
            return event(kind, values=values, activation=99, attempt=7, epoch=3)
        keys = int(form != 1)
        old = [10, 20, 30] + [20]*keys + [40]
        new = [10, 120, 30] + [120]*keys + [40]
        return [r('roots', (1000, len(old), 2, keys, 60, 992, 55, 75)),
                *[r('root-value', (i, value, 0)) for i, value in enumerate(old)],
                r('parent', (0, 75, 2016, 21, 1, 0, form, 7)),
                event('gc-begin', values=(500, 2016, 7), epoch=8),
                r('parent', (1, 75, 2016, 21, 1, 0, 8, 7)),
                *[event('root-repaired', actor=2, values=(1000+8*i, a, b, 55, 500, 8), epoch=9)
                  for i, (a, b) in enumerate(zip(old, new)) if a != b],
                event('root-repaired', actor=2, values=(992, 60, 70, 55, 500, 8), epoch=9),
                event('gc-end', values=(500, 3016, 0, 9), epoch=8),
                r('parent', (2, 75, 3016, 22, 1, 128, 8, 9)),
                r('parent', (3, 75, 3000, 22, 1, 128, 2, 9)),
                r('reload', (7000, 2, 6000*keys, keys, len(old), 70)),
                *[r('root-value', (i, value, phase)) for phase in (1, 2)
                  for i, value in enumerate(new)],
                r('reload-installed', (3000, 2, 6000*keys, keys, 70, 10, 40, 9)),
                r('retry-grant', (9, 4000, 4080, 3000, 2904, 3112, 8, 2)),
                event('pop', values=(3000,)), event('store', values=(0, 4000)),
                r('ready', (50,)), r('deliver', (50,)), r('tail', (70, 50)), r('body')]

    def test_three_rest_forms_require_the_native_mode_and_do_not_share_evidence(self):
        for spelling, form in obs.REST_FORMS.items():
            c = contract(8, 'moving-gc')
            c['cases'][0]['spelling'] = spelling
            rows = self.moving_rows(form)
            good = obs.project(c, trace(rows), NATURAL)
            self.assertTrue(all(s == 'pass' for s in statuses(good).values()), good)
            rows = self.moving_rows(1 if form != 1 else 2)
            self.assertEqual(statuses(obs.project(c, trace(rows), NATURAL))['handler-spelling'], 'fail')
            r = obs.project(c, trace([event('roots', activation=99, attempt=1)]), NATURAL)
            self.assertEqual(statuses(r)['single-delivery'], 'missing')

    def test_parent_reload_grant_and_delivery_reject_substituted_native_evidence(self):
        c = contract(8, 'moving-gc')
        for kind, occurrence, slot, value, obligation in (
                ('parent', 1, 4, 2, 'parent-owner-epoch'),
                ('parent', 2, 6, 7, 'parent-owner-epoch'),
                ('parent', 3, 2, 3008, 'retry-coordinates'),
                ('root-repaired', 0, 3, 99, 'moving-gc-repair'),
                ('root-repaired', 0, 5, 9, 'moving-gc-repair'),
                ('root-value', 9, 1, 20, 'complete-root-window'),
                ('retry-grant', 0, 0, 8, 'renewed-grant-before-effects'),
                ('store', 0, 1, 4064, 'renewed-grant-before-effects'),
                ('tail', 0, 0, 60, 'single-delivery')):
            with self.subTest(kind=kind, slot=slot):
                rows = self.moving_rows()
                [r for r in rows if r['kind'] == kind][occurrence]['values'][slot] = value
                self.assertEqual(statuses(obs.project(c, trace(rows), NATURAL))[obligation], 'fail')
        for removed in ('reload-installed', 'tail', 'body'):
            rows = [e for e in self.moving_rows() if e['kind'] != removed]
            self.assertNotEqual(statuses(obs.project(c, trace(rows), NATURAL))['reload-before-delivery'], 'pass')
        for kind in ('deliver', 'body'):
            rows = self.moving_rows()
            rows.append(next(e.copy() for e in rows if e['kind'] == kind))
            self.assertEqual(statuses(obs.project(c, trace(rows), NATURAL))['single-delivery'], 'fail')
        rows = self.moving_rows()
        next(e for e in rows if e['kind'] == 'retry-grant')['attempt'] = 8
        self.assertEqual(statuses(obs.project(c, trace(rows), NATURAL))['renewed-grant-before-effects'], 'fail')

    def test_timeout_missing_close_and_other_attempt_cannot_complete_cut(self):
        a = obs.project(contract(), race(), {**NATURAL, 'exit': -9, 'timeout': True})
        self.assertEqual(statuses(a)['complete-transport'], 'missing')
        b = race(); b['closed'] = b['complete'] = False
        self.assertEqual(statuses(obs.project(contract(), b, NATURAL))['complete-transport'], 'missing')
        base = obs.project(contract(), race(), NATURAL)
        self.assertNotEqual(a['facts']['rest_required'][0][0], base['facts']['rest_required'][0][0])

    def test_binary_torn_record_and_wrong_version(self):
        raw = bytearray(wire(race()))
        raw[64:72] = b'\0'*8
        decoded = obs.decode_trace(raw)
        self.assertFalse(decoded['complete'])
        self.assertEqual(decoded['holes'], [1])
        raw[8:16] = (2).to_bytes(8, 'little')
        with self.assertRaises(ValueError):
            obs.decode_trace(raw)

    def test_runtime_case_can_differ_from_the_logical_case(self):
        probe = race()
        for row in probe['events']:
            row['case'] = 7
        startup = trace([])
        for row in startup['events']:
            row['case'] = 2
        rows = [*startup['events'], *probe['events']]
        combined = dict(probe, events=[dict(row, seq=i) for i, row in enumerate(rows, 1)],
                        reserved=len(rows))
        report = obs.project(contract(), obs.decode_trace(wire(combined)), NATURAL)
        case, = report['cases']
        self.assertEqual((case['id'], case['runtimeCase'], case['startupCases']), (1, 7, [[2, 2]]))
        self.assertTrue(all(check['status'] == 'pass' for check in case['checks']))

        ambiguous = trace([event('case-begin', 0), event('case-end', 0)])
        for row in ambiguous['events'][1:-1]:
            row['case'] = 2
        with self.assertRaisesRegex(ValueError, 'native case outside'):
            obs.project(contract(), ambiguous, NATURAL)

        multiple = contract()
        multiple['cases'].append(dict(multiple['cases'][0], id=3))
        with self.assertRaisesRegex(ValueError, 'native case outside'):
            obs.project(multiple, combined, NATURAL)

    def test_tools_follow_the_current_path_without_a_host_fallback(self):
        with tempfile.TemporaryDirectory() as d:
            executable = Path(d)/'quint'; executable.write_text('#!/bin/sh\nexit 0\n')
            executable.chmod(0o755)
            with patch.dict(os.environ, PATH=d):
                self.assertEqual(tool('quint'), executable)
                with self.assertRaisesRegex(RuntimeError, 'PATH'):
                    tool('missing-native-observer-test-tool')

    def test_contract_factory_preserves_identity_and_refuses_an_old_producer(self):
        c = contract()
        identity = dict(schema='gambit-recipe-runtime-identity.v1', binarySha256=c['gsiSha256'], sourceFiles=c['sourceFiles'])
        self.assertEqual(obs.contract_from_identity(identity, c['cases'], capacity=c['capacity']), c)
        identity['sourceFiles'] = {}
        with self.assertRaisesRegex(ValueError, 'lacks observation sources'):
            obs.contract_from_identity(identity, c['cases'], capacity=c['capacity'])


class NativeTransportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from gambit_smp.native_capabilities import host_tools
        cls.cc = tool('cc', 'GAMBIT_TEST_CC')
        _, cls.env = host_tools(cls.cc, [], dict(os.environ))
        artifacts = os.environ.get('GAMBIT_SMP_TEST_ARTIFACT_DIRECTORY')
        cls.temporary = None if artifacts else tempfile.TemporaryDirectory()
        cls.directory = Path(artifacts)/'native-transport' if artifacts else Path(cls.temporary.name)
        if artifacts:
            cls.directory.mkdir()
        cls.executable = cls.directory/'native-trace'
        result = run([cls.cc, '-std=c23', '-Wall', '-Wextra', '-Werror', '-pthread',
                      '-I', ROOT/'vendor/gambit/lib', '-I', ROOT/'vendor/gambit/include',
                      Path(__file__).with_name('native_trace.c'),
                      '-o', cls.executable], env=cls.env, capture_output=True, text=True, timeout=30)
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.unobserved = cls.directory/'native-unobserved-macros'
        result = run([cls.cc, '-std=c23', '-Wall', '-Wextra', '-Werror', '-pthread',
                      '-DREST_NATIVE_TEST_UNOBSERVED_MACROS', '-I', ROOT/'vendor/gambit/lib',
                      '-I', ROOT/'vendor/gambit/include', Path(__file__).with_name('native_trace.c'),
                      '-o', cls.unobserved], env=cls.env, capture_output=True, text=True, timeout=30)
        if result.returncode:
            raise AssertionError(result.stderr)

    @classmethod
    def tearDownClass(cls):
        if cls.temporary is not None:
            cls.temporary.cleanup()

    def execute(self, name, capacity, mode):
        path = self.directory/name
        obs.create_trace(path, capacity)
        result = run([self.executable, path, mode], env=self.env, capture_output=True, timeout=10)
        return result.returncode, obs.decode_trace(path.read_bytes())

    def test_real_two_thread_writer_commits_all_rows(self):
        code, t = self.execute('threads.bin', 256, 'threads')
        self.assertEqual(code, 0)
        self.assertTrue(t['complete'])
        self.assertEqual(t['reserved'], 202)
        self.assertEqual({e['actor'] for e in t['events'] if e['kind'] == 'store'}, {1, 2})

    def test_environment_open_and_carrier_local_attempt_scope(self):
        code, t = self.execute('carrier.bin', 8, 'carrier')
        self.assertEqual(code, 0)
        self.assertTrue(t['complete'])
        self.assertEqual([(e['case'], e['kind']) for e in t['events']],
                         [(7, 'case-begin'), (7, 'section-view'), (7, 'case-end')])
        view = t['events'][1]
        self.assertTrue(view['activation'] and view['actor'])
        self.assertEqual((view['attempt'], view['epoch']), (11, 19))

    def test_native_body_requires_delivery_and_duplicate_marks_remain_visible(self):
        code, t = self.execute('delivery.bin', 8, 'delivery')
        self.assertEqual(code, 0)
        self.assertTrue(t['complete'])
        events = t['events'][1:-1]
        self.assertEqual([e['kind'] for e in events], ['deliver', 'body', 'body'])
        self.assertEqual(len({obs._attempt(e) for e in events}), 1)
        self.assertEqual(events[0]['values'][0], 19)

    def test_native_overflow_and_crash_prefix_are_inconclusive(self):
        code, t = self.execute('overflow.bin', 8, 'threads')
        self.assertEqual(code, 0)
        self.assertEqual(t['dropped'], 194)
        self.assertFalse(t['complete'])
        code, t = self.execute('crash.bin', 8, 'crash')
        self.assertEqual(code, 70)
        self.assertEqual(t['events'][-1]['kind'], 'preflight')
        self.assertFalse(t['complete'])

    def test_actual_c_macros_record_the_adjusted_first_store_address(self):
        code, t = self.execute('macros.bin', 32, 'macros')
        self.assertEqual(code, 0)
        self.assertTrue(t['complete'])
        stores = [e for e in t['events'] if e['kind'] == 'store' and e['values'][0]]
        self.assertEqual(len(stores), 2)
        self.assertEqual(stores[1]['values'][0], stores[0]['values'][0]-8)
        self.assertEqual(stores[0]['values'][0], stores[0]['values'][1])
        self.assertEqual(stores[1]['values'][1], stores[1]['values'][0]-8)
        self.assertEqual(len([e for e in t['events'] if e['kind'] == 'pop']), 1)

    def test_disabled_production_macros_preserve_values_without_observer_calls(self):
        path = self.directory/'unobserved-macros.bin'; obs.create_trace(path, 32)
        result = run([self.unobserved, path, 'macros'], env=self.env, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0)
        t = obs.decode_trace(path.read_bytes())
        self.assertEqual([e['kind'] for e in t['events']], ['case-begin', 'case-end'])
        self.assertTrue(t['complete'])

    def test_recorder_source_changes_are_real_make_dependencies(self):
        source = (ROOT/'vendor/gambit/lib/makefile.in').read_text()
        lines = source.splitlines(); i = next(i for i,s in enumerate(lines) if s.startswith('MEMORY_SOURCES ='))
        memory = [lines[i]]
        while memory[-1].endswith('\\'):
            i += 1; memory.append(lines[i])
        memory = '\n'.join(memory)
        rule = next(s for s in lines if s.startswith('mem@obj@:')).replace('@obj@', '.o')
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            names = set(memory.replace('\\\n',' ').split('=',1)[1].split())
            names.update(s for s in rule.split(':',1)[1].split() if not s.startswith('$'))
            old = time.time()-120
            for name in names:
                path = root/name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text('dependency fixture\n')
                os.utime(path,(old,old))
            obj = root/'mem.o'; obj.write_text('existing object\n'); os.utime(obj,(old+30,old+30))
            for name in ('rest-observation.h','_mem/rest-observation.inc'):
                makefile = root/'makefile'; makefile.write_text(memory+'\n'+rule+'\n\t@touch $@\n')
                selected = root/name
                self.assertTrue(selected.is_file(), 'Observer source missing from maintained Make inventory')
                current = run([tool('make'), '-r', '-q', 'mem.o'], cwd=root, env=self.env, capture_output=True, timeout=10)
                self.assertEqual(current.returncode, 0)
                os.utime(selected,(old+60,old+60))
                changed = run([tool('make'), '-r', '-q', 'mem.o'], cwd=root, env=self.env, capture_output=True, timeout=10)
                self.assertEqual(changed.returncode, 1)
                makefile.write_text(memory.replace(name,'')+'\n'+rule+'\n\t@touch $@\n')
                omitted = run([tool('make'), '-r', '-q', 'mem.o'], cwd=root, env=self.env, capture_output=True, timeout=10)
                self.assertEqual(omitted.returncode, 0)
                os.utime(selected,(old,old))


class InferenceTests(unittest.TestCase):
    def test_native_ascent_keeps_counterevidence_and_missing_premises(self):
        from gambit_smp.ascent_program import load_inert_catalog, query
        catalog = load_inert_catalog(ROOT/obs.RULES)
        report = obs.project(contract(), race(), NATURAL)
        answer = query(report['facts'], catalog, obs.QUERIES)
        self.assertEqual(len(answer['observed_cut']), 1)
        self.assertFalse(answer['missing'])
        self.assertEqual(obs._inferred_verdict({**report, 'inference': {'relations': answer}}), 'OBSERVED')
        bad = race()
        next(e for e in bad['events'] if e['kind'] == 'refuse')['values'][1:3] = [500, 3]
        report = obs.project(contract(), bad, NATURAL)
        answer = query(report['facts'], catalog, obs.QUERIES)
        self.assertTrue(answer['violation'])
        self.assertTrue(answer['repair_target'])
        self.assertFalse(answer['observed_cut'])
        self.assertEqual(obs._inferred_verdict({**report, 'inference': {'relations': answer}}), 'VIOLATED')
        no_grant = race()
        no_grant['events'].remove(next(e for e in reversed(no_grant['events']) if e['kind'] == 'section-view'))
        report = obs.project(contract(), no_grant, NATURAL)
        answer = query(report['facts'], catalog, obs.QUERIES)
        self.assertEqual(obs._inferred_verdict({**report, 'inference': {'relations': answer}}), 'INCONCLUSIVE')
        self.assertTrue(any(row[3] == 'winner-renewed-grant' and
                            row[4].endswith(':___rest_grant_fits') for row in answer['repair_target']))
        report = obs.project(contract(), race(), {**NATURAL, 'exit': -9, 'timeout': True})
        answer = query(report['facts'], catalog, obs.QUERIES)
        self.assertTrue(answer['missing'])
        self.assertFalse(answer['observed_cut'])


class ReceiptBindingTests(unittest.TestCase):
    def fixture(self, root, c=None):
        directory = root/'cut'; directory.mkdir()
        c = c or contract()
        (root/'contract.json').write_text(json.dumps(c))
        rules = root/obs.RULES; rules.parent.mkdir(parents=True)
        rules.write_bytes((ROOT/obs.RULES).read_bytes())
        candidate = dict(binarySha256=c['gsiSha256'], sourceFiles=c['sourceFiles'])
        ctx = SimpleNamespace(root=root, out=root, directory=directory, env={},
            bind=lambda paths: None, commands=[dict(stage='run-executable', **NATURAL)])
        prepared = obs.prepare(dict(contract='contract.json', rules=obs.RULES), ctx,
                               candidate, c['gsiSha256'], root/'runtime')
        (directory/'rest-observation.bin').write_bytes(wire(race()))
        return ctx, prepared

    def test_prepare_selects_only_the_real_physical_short_observer(self):
        with tempfile.TemporaryDirectory() as d:
            ctx, _ = self.fixture(Path(d), contract(6, 'short'))
            self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_CASE'], '1')
            self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_WATCH'], 'physical-one-short')

    def test_moving_cut_loads_the_compiled_module_on_the_bound_gsi(self):
        from gambit_smp import native_capabilities as native
        from gambit_smp.ascent_program import load_inert_catalog, query
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            ctx, prepared = self.fixture(root, contract(8, 'moving-gc'))
            self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_CASE'], '1')
            for path in ctx.directory.iterdir():
                path.unlink()
            runtime = root/'runtime'
            binary = runtime/'gsi/gsi'
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b'bound-gsi-fixture')
            c = prepared['contract']
            c['gsiSha256'] = digest(binary)
            (root/'contract.json').write_text(json.dumps(c))
            (root/'program.scm').write_text('(display "native test")\n')
            identity = root/'identity.json'
            identity.write_text(json.dumps(dict(binarySha256=c['gsiSha256'], sourceFiles=c['sourceFiles'])))
            ctx.artifact = lambda ref, kinds: runtime if ref['output'] == 'runtime' else identity
            ctx.remaining = lambda: 10
            ctx.commands = []
            current = dict(id='cut')
            ctx.receipt = dict(steps=[current])

            def run_fixture(stage, argv, cwd, remaining, **kwargs):
                ctx.commands.append(dict(stage=stage, argv=list(map(str, argv)), cwd=str(cwd), **NATURAL))
                if stage == 'compile-rest-fixture':
                    self.assertNotIn('GAMBIT_REST_OBSERVATION', ctx.env)
                    self.assertEqual(argv[0], runtime/'gsc/gsc')
                    (cwd/'fixture.o1').write_bytes(b'compiled-module-fixture')
                    return ''
                self.assertEqual(argv[0], binary)
                self.assertEqual(argv[-1], cwd/'fixture.o1')
                self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_CASE'], '1')
                rows = BoundaryMeasurementTests().moving_rows()
                Path(ctx.env['GAMBIT_REST_OBSERVATION']).write_bytes(wire(trace(rows)))
                return 'native test\n'

            ctx.require = run_fixture
            args = dict(runtime=dict(step='source', output='runtime'), identity=dict(step='source', output='identity'),
                        program='program.scm', mode='gsi', stdout='native test\n',
                        restObservation=dict(contract='contract.json', rules=obs.RULES))
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.native_capabilities.available_processors', return_value=8), \
                    patch('gambit_smp.native_capabilities.compiler', return_value='test-gcc'), \
                    patch('gambit_smp.native_capabilities.gnu_build_driver', return_value={}), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations',
                          side_effect=lambda ctx, rules, facts, queries, label, **kwargs:
                              query(facts, load_inert_catalog(root/rules[0]), queries)):
                result = native.executable_test(args, ctx)
            self.assertTrue(result['compilationLaunched'])
            current.update(commands=ctx.commands,
                           artifacts={'cut/'+p.name: digest(p) for p in ctx.directory.iterdir() if p.is_file()})
            ordinary = obs.bound_read(root, current)
            self.assertEqual(ordinary['verdict'], 'OBSERVED')
            optional = dict(ordinary, step='optional',
                            cases=[dict(ordinary['cases'][0], spelling='optional')])
            keyword = dict(ordinary, step='keyword', runtimeIdentitySha256='different',
                           cases=[dict(ordinary['cases'][0], spelling='keyword')])
            steps = [dict(id=r['step'], outcome='PASS') for r in (ordinary, optional, keyword)]
            groups = obs.moving_coverage([ordinary, optional, keyword], steps)
            self.assertEqual(groups[0]['missingSpellings'], ['keyword'])
            self.assertFalse(any(r['allThreeObserved'] for r in groups))
            keyword['runtimeIdentitySha256'] = ordinary['runtimeIdentitySha256']
            self.assertTrue(obs.moving_coverage([ordinary, optional, keyword], steps)[0]['allThreeObserved'])
            steps[-1]['outcome'] = 'FAIL'
            self.assertFalse(obs.moving_coverage([ordinary, optional, keyword], steps)[0]['allThreeObserved'])
            (ctx.directory/'fixture.o1').write_bytes(b'substituted')
            with self.assertRaisesRegex(ValueError, 'artifact changed'):
                obs.bound_read(root, current)

    def test_projected_moving_recipe_and_research_read_of_three_receipts(self):
        self.check_projected_recipe_read(moving=True)

    def test_projected_item_6_to_9_recipe_and_mixed_receipt_summary(self):
        self.check_projected_recipe_read(moving=False, mixed=True)

    def test_item10_requires_eleven_passes_and_binds_the_original_campaign(self):
        self.check_projected_recipe_read(moving=False)

    def test_item10_uses_declared_probe_inventory_under_a_different_recipe_id(self):
        self.check_projected_recipe_read(moving=False, observed=True)

    def check_projected_recipe_read(self, *, moving, mixed=False, observed=False):
        from contextlib import redirect_stdout
        from io import StringIO
        from gambit_smp import research_kernel as research
        from gambit_smp.ascent_program import load_inert_catalog, query
        from gambit_smp.recipes import load

        source = ROOT/'evidence/fixtures/dev-rest-original-runner/stress-module-checks.recipe.json'
        original, _ = load(ROOT, source)
        if observed:
            original['steps'] = [dict(
                id='producer', capability=family6_recipes.OBSERVATION_PROVIDER, dependsOn=[], budgetSeconds=60,
                arguments=dict(source='.cache/tasks/modern-c-frame-contract/build/example/' + 'a'*64 + '/source',
                               gsiSha256='a'*64))]
        recipe = family6_recipes.rest_check_recipe(ROOT, original, 'producer', moving=moving)
        provider_count = 1 if observed else 2
        if observed:
            recipe['id'] = 'family6-declared-candidate'
        steps = recipe['steps'][provider_count:-1]
        self.assertEqual(len(steps), 3 if moving else 11)
        if not moving:
            self.assertEqual(recipe['timeoutPolicy']['mode'], 'per-stage')
            self.assertNotIn('budgetSeconds', recipe)
            self.assertEqual(steps[-1]['arguments']['processorTopology'], 'host-managed')
            self.assertEqual([step['arguments']['restObservation']['case']['checklist'] for step in steps],
                             [6, 6, 6, 6, 6, 6, 7, 8, 8, 8, 9])
            self.assertEqual(len({step['arguments']['restObservation']['case']['id'] for step in steps}), 11)
            self.assertEqual(len({step['arguments']['program'] for step in steps}), 2)
        self.assertTrue(all(step['dependsOn'] == ['producer'] for step in steps))
        self.assertEqual({tuple(step['arguments']['runtime'].values()) for step in steps},
                         {('producer', 'runtime')})
        self.assertEqual({tuple(step['arguments']['identity'].values()) for step in steps},
                         {('producer', 'identity')})

        from gambit_smp.ordered_stress import ordered_stress_start_check
        scratch = ROOT/'.cache/tasks/modern-c-frame-contract'
        scratch.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=scratch) as tmp:
            out = Path(tmp)
            (out/'run').mkdir()
            candidate = dict(schema='gambit-recipe-runtime-identity.v1', binarySha256='a'*64,
                             sourceFiles=contract(8, 'moving-gc')['sourceFiles'])
            catalog = load_inert_catalog(ROOT/obs.RULES)
            rows = []
            for step in steps:
                if mixed and step['id'] == 'rest-9-ordinary-race':
                    continue  # Interrupted before the case could produce a step receipt.
                directory = out/'run'/step['id']
                directory.mkdir()
                options = step['arguments']['restObservation']
                options['capacity'] = 1024  # Small traces for the synthetic receipt control.
                case = options['case']
                form = step['arguments']['parameters']['GAMBIT_SMP_REST_FORM']
                (directory/'fixture.scm').write_bytes((ROOT/step['arguments']['program']).read_bytes())
                (directory/'fixture.o1').write_text('fixture module')
                runtime = out/'runtime'
                commands = [
                    dict(stage='compile-rest-fixture', cwd=str(directory), **NATURAL,
                         argv=[str(runtime/'gsc/gsc'), '-f', '-dynamic', '-o', 'fixture.o1', 'fixture.scm']),
                    dict(stage='run-executable', cwd=str(directory), **NATURAL,
                         argv=[str(runtime/'gsi/gsi'), '-:debug-settings=-,io-settings=lu',
                               '-f', str(directory/'fixture.o1')]),
                ]
                ctx = SimpleNamespace(root=ROOT, directory=directory, env={}, bind=lambda paths: None,
                                      commands=commands)
                prepared = obs.prepare(options, ctx, candidate, candidate['binarySha256'], runtime)
                prepared['fixture'] = obs.fixture_identity(directory, commands)
                self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_CASE'], str(case['id']))
                if case['checklist'] == 6:
                    self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_FORM'], str(form))
                    expected_watch = 'physical-exact' if case['situation'] == 'exact' else 'physical-one-short'
                    self.assertEqual(ctx.env['GAMBIT_REST_OBSERVATION_WATCH'], expected_watch)
                observation = self.projected_case_trace(case, form)
                if mixed and step['id'] == 'rest-6-ordinary-short':
                    cut = next(event for event in observation['events'] if event['kind'] == 'native-cut')
                    cut['values'][3] += 1
                if mixed and case['checklist'] == 7:
                    observation = trace([])  # Natural exit, but no cross-break witness.
                for event in observation['events']:
                    event['case'] = case['id']
                (directory/'rest-observation.bin').write_bytes(wire(observation, options['capacity']))
                with patch('gambit_smp.suite_primitives.check_runtime'), \
                        patch('gambit_smp.evidence_capabilities.evaluate_observations',
                              side_effect=lambda ctx, rules, facts, queries, label, **kw:
                                  query(facts, catalog, queries)):
                    descriptor = obs.finish(prepared, ctx)
                outcome = 'PASS' if descriptor['verdict'] == 'OBSERVED' else 'DENY'
                rows.append(dict(step, outcome=outcome, commands=commands, restObservation=descriptor,
                                 artifacts={p.relative_to(out/'run').as_posix(): digest(p)
                                            for p in directory.iterdir()}))

            child = out/'run/receipt.json'
            outcome = 'DENY' if mixed else 'PASS'
            provider = recipe['steps'][provider_count-1]
            producer_identity = out/'run/producer/identity.json'
            producer_identity.parent.mkdir()
            producer_identity.write_text(json.dumps(candidate))
            outputs = dict(runtime=dict(type='source-runtime'),
                           identity=dict(type='runtime-identity', path='producer/identity.json',
                                         sha256=digest(producer_identity)))
            completed = [*[dict(row, outcome='PASS') for row in recipe['steps'][:provider_count-1]],
                         dict(provider, outcome='PASS', outputs=outputs),
                         *rows, dict(recipe['steps'][-1], outcome=outcome)]
            child_data = dict(schema='evidence-recipe-run.v1', recipe=recipe['id'], outcome=outcome,
                              engine=dict(engineId='fixture-engine'), inputsStable=True,
                              steps=completed, plannedSteps=recipe['steps'], declaredInputs=recipe['inputs'])
            child.write_text(json.dumps(child_data))
            (out/'receipt.json').write_text(json.dumps(dict(
                schema='sealed-research-run.v1', root=str(ROOT), engine=str(out/'engine'),
                recipe=recipe['id'], engineId='fixture-engine', outcome=outcome,
                inputs={name: digest(ROOT/name) for name in recipe['inputs']},
                exit=0 if not mixed else 2, timeout=False, parentReaped=True, processGroupQuiescent=True,
                artifacts={}, childReceiptSha256=digest(child))))
            output = StringIO()
            with patch('sys.argv', ['research', '--read', str(out)]), \
                    patch('gambit_smp.research_kernel.manifest_paths', return_value={'engineId': 'fixture-engine'}), \
                    patch('gambit_smp.recipes.inspect_run', return_value={
                        'evidenceBindingStatus': 'CURRENT', 'identityStatus': 'CURRENT',
                        'artifactAvailability': {'status': 'AVAILABLE'}}), \
                    patch('gambit_smp.step_checkpoint.resumption', return_value={}), redirect_stdout(output):
                self.assertEqual(research.main(), 0)
            summary = json.loads(output.getvalue())['executionSummary']
            if moving:
                coverage, = summary['movingRestCoverage']
                self.assertTrue(coverage['allThreeObserved'])
                self.assertEqual(coverage['observedSpellings'], ['ordinary', 'optional', 'keyword'])
            elif mixed:
                coverage, = summary['restCutCoverage']
                self.assertFalse(summary['item10StartCheck']['canStart'])
                with self.assertRaisesRegex(ValueError, 'complete sealed rest Recipe receipt required'):
                    family6_recipes.rest_campaign_recipe(ROOT, out)
                self.assertFalse(coverage['allCasesObserved'])
                self.assertEqual(len(coverage['cases']), 11)
                items = {item['checklist']: item for item in coverage['items']}
                self.assertEqual(len(items[6]['passed']), 5)
                self.assertEqual(items[6]['failed'], ['rest-6-ordinary-short'])
                self.assertEqual(items[7]['missing'], ['rest-7-ordinary-cross-break'])
                self.assertEqual(len(items[8]['passed']), 3)
                self.assertEqual(items[9]['missing'], ['rest-9-ordinary-race'])
                cases = {case['step']: case for case in coverage['cases']}
                self.assertEqual(cases['rest-6-ordinary-short']['firstFailedObligation'], 'exact-or-short')
                self.assertIn('cross-break-custody', cases['rest-7-ordinary-cross-break']['missingObligations'])
                # Reports from distinct runtime identities cannot cover the recipe together.
                observations = summary['restObservations']
                observations[-1]['runtimeIdentitySha256'] = 'different'
                groups = obs.rest_cut_coverage(observations, rows, planned=steps)
                self.assertFalse(any(group['allCasesObserved'] for group in groups))
                self.assertIn('moving-rest-keyword',
                              next(item for item in groups[0]['items'] if item['checklist'] == 8)['missing'])
                interrupted, = obs.rest_cut_coverage(observations[:-1], rows[:-1], planned=steps)
                self.assertFalse(interrupted['allCasesObserved'])
                self.assertEqual(interrupted['cases'][-1]['status'], 'MISSING')
            else:
                coverage, = summary['restCutCoverage']
                self.assertTrue(coverage['allCasesObserved'])
                self.assertTrue(summary['item10StartCheck']['canStart'])
                _, original_steps = load(ROOT, ROOT/'evidence/fixtures/dev-rest-original-runner/stress.recipe.json')
                output = StringIO()
                gate2_path = 'evidence/fixtures/dev-rest-original-runner/stress.recipe.json'
                request = f'((bindings (("review" "gate2") ("correspondence" "{gate2_path}"))))'
                with patch('sys.argv', ['research', '--rest-campaign', str(out), request]), \
                        patch('gambit_smp.research_kernel.manifest_paths', return_value={'engineId': 'fixture-engine'}), \
                        redirect_stdout(output):
                    self.assertEqual(research.main(), 0)
                campaign = json.loads(output.getvalue())
                stress = next(step for step in campaign['steps'] if step['id'] == 'stress')
                plan = stress['arguments']['orderedStress']
                reference = plan['restEvidence']
                self.assertEqual(reference['receiptSha256'], digest(out/'receipt.json'))
                self.assertEqual(plan['gate2Receipt'], gate2_path)
                self.assertIn(gate2_path, campaign['inputs'])
                expected_stress = next(step for step in original_steps if step['id'] == 'stress')
                self.assertEqual(dict(stress['arguments'], orderedStress={
                    key: value for key, value in plan.items() if key not in ('restEvidence', 'gate2Receipt')}),
                    expected_stress['arguments'])
                self.assertEqual((campaign['budgetSeconds'], stress['budgetSeconds']), (300, 295))
                projected = dict(campaign['steps'][provider_count-1]['arguments'])
                if observed:
                    self.assertEqual(projected.pop('retainedRuntime'), dict(reference, step=provider['id']))
                self.assertEqual(projected, provider['arguments'])
                ctx = SimpleNamespace(root=ROOT, bind=lambda paths: None)
                deadline = time.monotonic() + 30
                with patch('gambit_smp.research_kernel.manifest_paths', return_value={'engineId': 'fixture-engine'}):
                    self.assertTrue(ordered_stress_start_check(ctx, plan, candidate, deadline)['canStart'])
                    for other in (dict(candidate, binarySha256='c'*64),
                                  dict(candidate, gscSha256='d'*64)):
                        with self.assertRaisesRegex(ValueError, 'differs from the eleven rest observations'):
                            ordered_stress_start_check(ctx, plan, other, deadline)
                # A subset can pass its own coverage summary and still fail item 10.
                subset = {**child_data, 'plannedSteps': [step for step in recipe['steps']
                          if step['id'] != rows[-1]['id']],
                          'steps': [step for step in completed if step['id'] != rows[-1]['id']]}
                receipt = json.loads((out/'receipt.json').read_text())
                subset_observations = summary['restObservations'][:-1]
                subset_coverage = obs.rest_cut_coverage(subset_observations, subset['steps'],
                                                        planned=subset['plannedSteps'])
                self.assertTrue(subset_coverage[0]['allCasesObserved'])
                self.assertFalse(family6_recipes.item10_start_check(out, receipt, subset, subset_coverage,
                                                       subset_observations)['canStart'])
            self.assertFalse(coverage['runtimeAdmitted'])

            changed = copy.deepcopy(rows[0])
            changed['arguments']['restObservation']['case']['spelling'] = 'optional'
            with self.assertRaisesRegex(ValueError, 'differs from its recipe case'):
                obs.bound_read(out/'run', changed)
            if mixed:
                # A damaged inline receipt cannot erase the other item results.
                (out/'run'/rows[0]['id']/'fixture.o1').write_text('different module')
                aggregate = research.bound_execution_summary(out, json.loads((out/'receipt.json').read_text()))
                damaged, = aggregate['restCutCoverage']
                self.assertEqual(damaged['cases'][0]['status'], 'UNVERIFIED')
                self.assertIn('artifact changed', damaged['cases'][0]['receiptError'])
                self.assertEqual(len(damaged['items'][2]['passed']), 3)
            if not moving and not mixed:
                (out/'run'/rows[0]['id']/'fixture.o1').write_text('different module')
                with self.assertRaisesRegex(ValueError, 'all eleven verified observations'):
                    family6_recipes.rest_campaign_evidence(ROOT, reference)

    def projected_case_trace(self, case, form):
        item = case['checklist']
        if item == 8:
            return trace(BoundaryMeasurementTests().moving_rows(form))
        if item == 9:
            return race()
        if item == 7:
            def row(kind, values):
                return event(kind, values=values, activation=3, attempt=8)
            return trace([
                row('pin', (700, 0, 1, 904, 800, 1104)), row('source-read', (700, 0, 1, 904)),
                row('break-link', (700, 0, 1, 1008, 1200, 1000, 1, 8)),
                row('successor', (800, 128, 1, 1200, 700, 0, 1)), row('unpin', (700, 0, 0)),
            ])
        short = case['situation'] == 'short'
        def snapshots(phase):
            return [event('snapshot', values=(region, phase, base+8*i, i, base, count))
                    for region, base, count in ((1, 1000, 5 if short else 6),
                                                (2, 2000, 5), (3, 2032, 1))
                    for i in range(count)]
        return trace([
            event('native-begin', values=(1000, 2032, 0, 0, form)),
            event('heap-span', values=(1000, 1032 if short else 1040, 1000, 1040 if short else 1048)),
            event('stack-span', values=(2000, 2040, 2032)),
            event('argument-span', values=(2032, 2040, 2032, 0)),
            *snapshots(0), event('watched-demand', values=(1000, 2032, 5, 1, 1, 1, 3, 1)),
            event('preflight', values=(5, 0, int(not short), int(short), 1000, 2032)),
            *([] if short else [event('pop', values=(2032,)), event('store', values=(0, 1000))]),
            event('native-cut', values=(1000 if short else 1024, 2032, 9 if short else 0, 1, form)),
            event('argument-span', values=(2032, 2040, 2032, 1)), *snapshots(1),
        ])

    def test_normal_aggregate_read_rejects_substitution_and_terminal_drift(self):
        from gambit_smp.ascent_program import load_inert_catalog, query
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            ctx, prepared = self.fixture(root)
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations',
                          side_effect=lambda ctx, rules, facts, queries, label, **kwargs:
                              query(facts, load_inert_catalog(root/rules[0]), queries)):
                descriptor = obs.finish(prepared, ctx)
            step = dict(id='cut', restObservation=descriptor, commands=ctx.commands,
                        artifacts={'cut/'+p.name: digest(p) for p in ctx.directory.iterdir() if p.is_file()})
            result = obs.bound_read(root, step)
            self.assertEqual(result['status'], 'RECEIPT_BOUND')
            self.assertEqual(result['verdict'], 'OBSERVED')
            self.assertFalse(result['runtimeAdmitted'])
            # The public aggregate path must expose the same complete report,
            # without invoking a producer or requesting a new native attempt.
            step.update(capability='gambit.executable-test', outcome='PASS',
                        arguments={}, dependsOn=[])
            child = dict(schema='evidence-recipe-run.v1', recipe='rest-unit', steps=[step])
            outer = root/'outer'; (outer/'run').mkdir(parents=True)
            # Keep this fixture's retained artifact layout identical to a run.
            shutil.copytree(ctx.directory, outer/'run/cut')
            child_path = outer/'run/receipt.json'; child_path.write_text(json.dumps(child))
            from gambit_smp.research_kernel import bound_execution_summary
            aggregate = bound_execution_summary(outer, dict(recipe='rest-unit',
                childReceiptSha256=digest(child_path)))
            self.assertEqual(aggregate['restObservations'][0]['facts'], result['facts'])
            step['commands'][0]['exit'] = -9
            with self.assertRaisesRegex(ValueError, 'terminal'):
                obs.bound_read(root, step)
            step['commands'][0]['exit'] = 0
            path = ctx.directory/'rest-observation.bin'
            raw = bytearray(path.read_bytes()); raw[-1] = 1; path.write_bytes(raw)
            with self.assertRaisesRegex(ValueError, 'artifact changed'):
                obs.bound_read(root, step)

    def test_read_rejects_observed_cut_without_actual_publication(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            ctx, prepared = self.fixture(root)
            t = race()
            t['events'] = [e for e in t['events'] if e['kind'] != 'section-published']
            for i, e in enumerate(t['events'], 1):
                e['seq'] = i
            (ctx.directory/'rest-observation.bin').write_bytes(wire(t))
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations', side_effect=TimeoutError):
                descriptor = obs.finish(prepared, ctx)
            report_path = ctx.directory/'rest-observation.json'
            report = json.loads(report_path.read_text())
            report['verdict'] = 'OBSERVED'
            report['inference'] = dict(backend='ASCENT', relations=dict(
                violation=[], missing=[], observed_cut=[report['facts']['rest_required'][0][:3]], repair_target=[]))
            report_path.write_text(json.dumps(report))
            descriptor.update(verdict='OBSERVED', sha256=digest(report_path))
            step = dict(id='cut', restObservation=descriptor, commands=ctx.commands,
                        artifacts={'cut/'+p.name: digest(p) for p in ctx.directory.iterdir() if p.is_file()})
            with self.assertRaisesRegex(ValueError, 'ASCENT verdict'):
                obs.bound_read(root, step)

    def test_historical_physical_tail_receipt_has_no_current_item9_credit(self):
        from gambit_smp.ascent_program import load_inert_catalog, query
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            ctx, prepared = self.fixture(root)
            historical = race()
            for row in historical['events']:
                if row['kind'] == 'lock':
                    row['values'][4:] = [0] * 4
            (ctx.directory/'rest-observation.bin').write_bytes(wire(historical))
            original_project = obs.project
            catalog = load_inert_catalog(root/obs.RULES)
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations',
                          side_effect=lambda ctx, rules, facts, queries, label, **kw: query(facts, catalog, queries)), \
                    patch.object(obs, 'project', side_effect=lambda *args: original_project(*args, legacy_contest=True)), \
                    patch.object(obs, 'REST_CONTEST_REPORT', obs.REST_REPORT):
                descriptor = obs.finish(prepared, ctx)
            step = dict(id='cut', outcome='PASS', restObservation=descriptor, commands=ctx.commands,
                        artifacts={'cut/'+p.name: digest(p) for p in ctx.directory.iterdir() if p.is_file()})
            report = obs.bound_read(root, step)
            self.assertEqual(report['verdict'], 'OBSERVED')
            self.assertTrue(report['legacyContest'])
            plan = [dict(id='cut', arguments={'restObservation': {'case': contract()['cases'][0]}})]
            coverage, = obs.rest_cut_coverage([report], [step], planned=plan)
            self.assertFalse(coverage['allCasesObserved'])
            self.assertEqual(coverage['cases'][0]['missingObligations'], ['unique-last-section'])
            facts = {}
            obs.add_facts(facts, report)
            answers = query(facts, catalog, obs.QUERIES)
            self.assertTrue(any(row[3] == 'unique-last-section' for row in answers['missing']))
            self.assertFalse(answers['observed_cut'])

    def test_same_bytes_replaced_file_and_changed_gsi_are_denied(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); ctx, prepared = self.fixture(root)
            path = ctx.directory/'rest-observation.bin'
            replacement = path.with_suffix('.replacement'); replacement.write_bytes(path.read_bytes())
            replacement.replace(path)
            with self.assertRaisesRegex(ValueError, 'replaced'):
                obs.finish(prepared, ctx)
            candidate = dict(binarySha256='c'*64, sourceFiles=prepared['contract']['sourceFiles'])
            with self.assertRaisesRegex(ValueError, 'exact identity-bound GSI'):
                obs.prepare(prepared['options'], ctx, candidate, 'c'*64, root/'runtime')

    def test_checkpoint_origin_is_read_without_replaying_or_relabeling_execution(self):
        from gambit_smp.step_checkpoint import content_id
        from gambit_smp.ascent_program import load_inert_catalog, query
        def infer(ctx, rules, facts, queries, label, **kwargs):
            return query(facts, load_inert_catalog(ROOT/obs.RULES), queries)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); original = root/'original'; original.mkdir()
            ctx, prepared = self.fixture(original)
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations',
                          side_effect=infer):
                descriptor = obs.finish(prepared, ctx)
            self.assertEqual(descriptor['verdict'], 'OBSERVED')
            previous = dict(id='cut', capability='gambit.executable-test', arguments={}, dependsOn=[],
                budgetSeconds=10, outcome='PASS', restObservation=descriptor, commands=ctx.commands,
                artifacts={'cut/'+p.name:digest(p) for p in ctx.directory.iterdir() if p.is_file()})
            (original/'receipt.json').write_text(json.dumps(dict(schema='evidence-recipe-run.v1', steps=[previous])))
            reused = {k:v for k,v in previous.items() if k not in ('commands','artifacts')}
            reused['reused'] = dict(run='original', step='cut', receipt=content_id(previous))
            current = root/'current'; current.mkdir()
            with patch.object(obs, 'ROOT', root):
                observed = obs.bound_read(current, reused)
                self.assertTrue(observed['executionReused'])
                self.assertFalse(observed['executionLaunched'])
                reused['reused']['receipt'] = '0'*64
                with self.assertRaisesRegex(ValueError, 'origin step receipt changed'):
                    obs.bound_read(current, reused)

    def test_inference_deadline_preserves_native_diagnostic_without_success(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); ctx, prepared = self.fixture(root)
            ctx.commands[0].update(exit=-9, timeout=True)
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations', side_effect=TimeoutError('deadline')):
                descriptor = obs.finish(prepared, ctx)
            self.assertEqual(descriptor['verdict'], 'INCONCLUSIVE')
            report = json.loads((ctx.directory/'rest-observation.json').read_text())
            self.assertEqual(report['terminal']['exit'], -9)
            self.assertEqual(report['inference']['status'], 'NOT_ESTABLISHED')
            self.assertTrue(report['facts']['rest_required'])

    def test_existing_executable_entry_retains_observation_on_native_failure(self):
        from gambit_smp import native_capabilities as native
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); ctx, prepared = self.fixture(root)
            # Re-enter through the real capability rather than calling its
            # finalizer directly. Its producer is a failure fixture, not GSI.
            for p in ctx.directory.iterdir():
                p.unlink()
            runtime = root/'runtime'; (runtime/'gsi').mkdir(parents=True)
            binary = runtime/'gsi/gsi'; binary.write_bytes(b'failure-fixture')
            c = prepared['contract']; c['gsiSha256'] = digest(binary)
            (root/'contract.json').write_text(json.dumps(c))
            identity = root/'identity.json'
            identity.write_text(json.dumps(dict(binarySha256=c['gsiSha256'], sourceFiles=c['sourceFiles'])))
            (root/'program.scm').write_text('(display "not reached")\n')
            ctx.artifact = lambda ref, kinds: runtime if ref['output'] == 'runtime' else identity
            ctx.remaining = lambda: 10
            ctx.commands = []; current = dict(id='cut'); ctx.receipt = dict(steps=[current])
            def failed(*args, **kwargs):
                ctx.commands.append(dict(stage='run-executable', **{**NATURAL, 'exit': 70}))
                raise ValueError('native failure fixture')
            ctx.require = failed
            args = dict(runtime=dict(step='source', output='runtime'), identity=dict(step='source', output='identity'),
                        program='program.scm', mode='gsi', stdout='unused\n',
                        restObservation=dict(contract='contract.json', rules=obs.RULES))
            with patch('gambit_smp.suite_primitives.check_runtime'), \
                    patch('gambit_smp.native_capabilities.available_processors', return_value=8), \
                    patch('gambit_smp.native_capabilities.native_interposition'), \
                    patch('gambit_smp.evidence_capabilities.evaluate_observations', side_effect=TimeoutError('expired')):
                with self.assertRaisesRegex(ValueError, 'native failure fixture'):
                    native.executable_test(args, ctx)
            self.assertEqual(current['restObservation']['verdict'], 'INCONCLUSIVE')
            self.assertEqual(json.loads((ctx.directory/'rest-observation.json').read_text())['terminal']['exit'], 70)


class ModelBridgeTests(unittest.TestCase):
    def test_lean_coordinate_and_scope_lemmas(self):
        result = run([tool('lean'), ROOT/'dev/refactoring/modern-c/models/lean/RestNativeObservation.lean'],
                     capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)

    def test_qnt_scope_and_incomplete_cut_controls(self):
        result = run([tool('quint'), 'test',
                      ROOT/'dev/refactoring/modern-c/models/quint/rest_observation_scope.qnt'],
                     capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)


if __name__ == '__main__':
    unittest.main()
