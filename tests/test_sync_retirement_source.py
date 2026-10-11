import unittest
from gambit_smp.sync_retirement_source import expected, extract


class SourceScheduleTests(unittest.TestCase):
    def test_extraction_fails_closed(self):
        for text in ("", "#define SYNC_WAITING -1\n" * 2,
                     "\n\n___HIDDEN void ___sync_wait\n#define SYNC_WAITING -1\n"):
            with self.assertRaises(ValueError):
                extract(text)

    def test_naive_destroy_does_not_become_green(self):
        self.assertEqual(expected(1, 1)["busyDestroy"], 1)
        self.assertEqual(expected(1, 1)["invalid"], 2)
        self.assertEqual(expected(1, 2)["invalid"], 1)

    def test_contract_requires_drain(self):
        for point in (1, 2):
            self.assertEqual(expected(2, point)["destroyed"], 2)
            self.assertEqual(expected(2, point)["invalid"], 0)
            self.assertEqual(expected(2, point)["receiverLocks"], 0)

    def test_init_failure_is_partial_not_rollback(self):
        self.assertEqual(expected(3, 1)["cvLive"], 1)
        self.assertEqual(expected(3, 2)["mutexLive"], 1)
        self.assertEqual(expected(3, 2)["destroyed"], 0)
        with self.assertRaises(ValueError):
            expected(4, 1)


if __name__ == "__main__":
    unittest.main()
