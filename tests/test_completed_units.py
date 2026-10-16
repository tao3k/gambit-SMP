import unittest
import sys
import tempfile

from gambit_smp.completed_units import CompletedUnits, validate
from gambit_smp.process_observation import capture


class CompletedUnitTests(unittest.TestCase):
    def setUp(self):
        self.progress = CompletedUnits({"marker": "ROOT-DONE", "count": 2, "result": "987"})

    def test_only_complete_verified_records_count(self):
        self.assertEqual(0, self.progress("heartbeat\nROOT-DONE 1/2 987", ""))
        self.assertEqual(1, self.progress("heartbeat\nROOT-DONE 1/2 987\n", ""))
        self.assertEqual((2, "DONE\n"), self.progress.project(
            "ROOT-DONE 1/2 987\nROOT-DONE 2/2 987\nDONE\n", final=True))

    def test_duplicate_skip_bad_result_and_total_rejected(self):
        for text in ("ROOT-DONE 2/2 987\n", "ROOT-DONE 1/3 987\n",
                     "ROOT-DONE 1/2 986\n", "ROOT-DONE 1/2 987\nROOT-DONE 1/2 987\n"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.progress(text, "")

    def test_final_marker_cannot_substitute_for_missing_units(self):
        with self.assertRaises(ValueError):
            self.progress.project("DONE\n", final=True)

    def test_contract_is_bounded(self):
        for count in (0, True, 1000001, "2"):
            with self.subTest(count=count), self.assertRaises(ValueError):
                validate({"marker": "ROOT-DONE", "count": count, "result": "987"})

    def test_transport_continues_only_for_completed_units(self):
        program = ("import time\nfor i in range(1,3):\n"
                   " print('ROOT-DONE %d/2 987' % i,flush=True)\n time.sleep(.3)")
        with tempfile.TemporaryDirectory() as directory:
            observed = capture([sys.executable, "-u", "-c", program], directory, .5, None,
                               progress=self.progress)
        self.assertFalse(observed.timeout)
        self.assertEqual(0, observed.exit)
        self.assertGreater(observed.seconds, .5)
        self.assertEqual(2, self.progress.project(observed.stdout, final=True)[0])

    def test_ordinary_output_does_not_extend_unit_watchdog(self):
        program = "import time\nfor _ in range(100):\n print('heartbeat',flush=True)\n time.sleep(.02)"
        with tempfile.TemporaryDirectory() as directory:
            observed = capture([sys.executable, "-u", "-c", program], directory, .3, None,
                               progress=self.progress)
        self.assertTrue(observed.timeout)
        self.assertEqual(-9, observed.exit)
        self.assertTrue(observed.group_quiescent)
