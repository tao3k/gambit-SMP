import unittest

from gambit_smp.notification_schedule import matched


class NotificationScheduleTests(unittest.TestCase):
    def negative(self, point=1):
        return dict(point=point, joined=True, finalCount=0, consumed=0, signals=1,
                    waits=1, signalBeforeWait=True, pendingAtWait=True, countAtWait=1)

    def test_observed_lost_notification_never_matches_candidate(self):
        for point in (1, 2):
            actual = self.negative(point)
            self.assertTrue(matched("baseline", point, actual))
            self.assertFalse(matched("candidate", point, actual))

    def test_candidate_requires_consumption_not_just_join_and_zero_count(self):
        actual = self.negative()
        actual.update(consumed=1, pendingAtWait=False)
        self.assertTrue(matched("candidate", 1, actual))
        for key, value in (("consumed", 0), ("signals", 0), ("pendingAtWait", True),
                           ("countAtWait", 0), ("joined", False), ("finalCount", 1)):
            with self.subTest(key=key):
                self.assertFalse(matched("candidate", 1, {**actual, key: value}))

    def test_publication_at_registration_requires_signal_after_actual_wait(self):
        actual = self.negative(2)
        actual.update(consumed=1, signalBeforeWait=False)
        self.assertTrue(matched("candidate", 2, actual))
        self.assertFalse(matched("candidate", 2, {**actual, "signalBeforeWait": True}))

    def test_multiple_publishers_require_both_chunks_and_both_signals(self):
        actual = dict(point=3, consumed=2, signals=2, finalCount=0, joined=True)
        self.assertTrue(matched("candidate", 3, actual))
        self.assertFalse(matched("candidate", 3, {**actual, "consumed": 1}))
        self.assertFalse(matched("candidate", 3, {**actual, "signals": 1}))
        self.assertFalse(matched("baseline", 3, actual))


if __name__ == "__main__":
    unittest.main()
