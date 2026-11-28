"""Admission of real reader ownership reports before native consumption."""
import copy
import tempfile
import unittest
from pathlib import Path

from gambit_smp.gerbil_build.dynamic_products import _module_read_reports


class ModuleReadProducts(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.source = self.root/'src/std/body.ss'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('package: explicit\n(def value 42)')
        self.interface = self.root/'build/lib/std/body.ssi'
        self.interface.parent.mkdir(parents=True)
        self.before = dict(schema='gerbil-module-read-products', phase='planned',
            products=[[str(self.source), 'unread', '', 'absent', 'absent']],
            completionAliases=[str(self.source), str(self.interface)])
        self.after = copy.deepcopy(self.before)
        self.after.update(phase='expanded',
            products=[[str(self.source), 'transferred', 'explicit/body', 'absent', 'absent']])

    def refuse(self, change):
        before, after = copy.deepcopy(self.before), copy.deepcopy(self.after)
        change(before, after)
        with self.assertRaises(ValueError):
            _module_read_reports(self.root, before, after)

    def test_read_free_plan_and_actual_identity_join(self):
        receipt = _module_read_reports(self.root, self.before, self.after)
        self.assertEqual(receipt['planningReads'], 0)
        self.assertEqual(receipt['transferred'], 1)
        self.assertFalse(receipt['codeAndEvalPromiseRetired'])

    def test_preexisting_context_is_not_claimed_as_a_new_read(self):
        self.after['products'][0][1:3] = ['unread', '']
        result = _module_read_reports(self.root, self.before, self.after)
        self.assertEqual(result['preexistingContextHits'], 1)
        self.assertEqual(result['transferred'], 0)

    def test_output_parent_need_not_exist_during_planning(self):
        alias = self.root/'build/lib/std/not-created/nested/body.ssi'
        self.assertFalse(alias.parent.exists())
        for report in [self.before, self.after]:
            report['completionAliases'][1] = str(alias)
        self.assertEqual(_module_read_reports(self.root, self.before, self.after)
                         ['completionAliases'], 2)

    def test_later_symlink_cannot_retarget_a_planned_alias(self):
        parent = self.root/'build/lib/std/not-created'
        alias = parent/'body.ssi'
        for report in [self.before, self.after]:
            report['completionAliases'][1] = str(alias)
        _module_read_reports(self.root, self.before, self.after)
        outside = self.root/'another-owner'
        outside.mkdir()
        parent.symlink_to(outside, target_is_directory=True)
        self.refuse(lambda b, a: None)

    def test_eager_read_during_planning_is_refused(self):
        self.refuse(lambda b, a: b['products'][0].__setitem__(1, 'transferred'))

    def test_retained_body_or_reader_context_is_refused(self):
        self.refuse(lambda b, a: a['products'][0].__setitem__(3, 'present'))
        self.refuse(lambda b, a: a['products'][0].__setitem__(4, 'present'))

    def test_failed_ready_and_missing_reports_are_not_completion(self):
        for state in ['reading', 'ready', 'failed']:
            self.refuse(lambda b, a: a['products'][0].__setitem__(1, state))
        self.refuse(lambda b, a: a.pop('products'))

    def test_owner_set_and_aliases_must_survive_the_handoff(self):
        self.refuse(lambda b, a: a['completionAliases'].pop())
        self.refuse(lambda b, a: a['products'].append(a['products'][0]))
        self.refuse(lambda b, a: a['products'][0].__setitem__(0, '/tmp/not-a-provider.ss'))

    def test_missing_source_does_not_pass(self):
        self.source.unlink()
        self.refuse(lambda b, a: None)

    def test_inferred_or_duplicate_identity_is_refused(self):
        self.refuse(lambda b, a: a['products'][0].__setitem__(2, ''))
        other = self.source.with_name('other.ss')
        other.write_text('package: explicit\n(def value 42)')
        self.before['products'].append([str(other), 'unread', '', 'absent', 'absent'])
        self.after['products'].append([str(other), 'transferred', 'explicit/body', 'absent', 'absent'])
        self.before['completionAliases'].append(str(other))
        self.after['completionAliases'].append(str(other))
        self.refuse(lambda b, a: None)


if __name__ == '__main__':
    unittest.main()
