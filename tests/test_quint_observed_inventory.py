import unittest

from gambit_smp.quint_capabilities import checked_observed_tests


class QuintObservedInventoryTests(unittest.TestCase):
    def test_exact_named_report_and_empty_or_inconsistent_controls(self):
        report = '  ok firstTest passed 1 test(s)\n  ok secondTest passed 2 test(s)\n\n  2 passing (4ms)\n'
        self.assertEqual(['firstTest', 'secondTest'],
                         checked_observed_tests(report, ['secondTest', 'firstTest']))
        for bad in ('\n  module\n',
                    report.replace('secondTest', 'otherTest'),
                    report.replace('2 passing', '1 passing'),
                    report.replace('secondTest', 'firstTest'),
                    report.replace('passed 2 test(s)', 'passed 0 test(s)')):
            with self.subTest(report=bad), self.assertRaisesRegex(ValueError, 'exact nonempty'):
                checked_observed_tests(bad, ['firstTest', 'secondTest'])


if __name__ == '__main__':
    unittest.main()
