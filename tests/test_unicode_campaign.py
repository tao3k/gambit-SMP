from dataclasses import replace
import unittest

from gambit_smp.process_observation import Observation
from gambit_smp.unicode_campaign import accepted, run


class UnicodeCampaignTests(unittest.TestCase):
    def test_execution_requires_unique_witness_and_reaped_group(self):
        observation = Observation("NATIVE-OK:unicode_scalar_semantics\n", "", 0,
                                  False, 1, 1, "start", "end", True)
        witness = "NATIVE-OK:unicode_scalar_semantics"
        self.assertTrue(accepted(observation, witness))
        for changed in (replace(observation, exit=1), replace(observation, timeout=True),
                        replace(observation, group_quiescent=False),
                        replace(observation, group_quiescent=None),
                        replace(observation, stdout=""),
                        replace(observation, stdout=observation.stdout * 2)):
            self.assertFalse(accepted(changed, witness))

    def test_missing_comparison_side_rejected_before_launch(self):
        with self.assertRaisesRegex(ValueError, "two source-bound runtimes"):
            run([], None, None, None, 90)
        with self.assertRaisesRegex(ValueError, "positive whole budget"):
            run([None, None], None, None, None, 0)
