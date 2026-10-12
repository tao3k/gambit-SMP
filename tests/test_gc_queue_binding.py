import unittest

from gambit_smp.framework import ROOT
from gambit_smp.gc_queue_binding import inspect


class GCQueueBindingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (ROOT / ".data/pstate-init-runtime-027/source/lib/mem.c").read_text()

    def test_current_reviewed_source_observes_only_existing_policy(self):
        observed = inspect(self.source)
        self.assertEqual("lexical-order-not-semantic", observed["bindingKind"])
        self.assertFalse(observed["combinedPolicyImplemented"])
        self.assertTrue(observed["nonzeroRestoreBeforeUnlock"])

    def test_notification_inside_queue_lock_is_rejected(self):
        old = ("      ___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);\n"
               "      ___CONDVAR_SIGNAL(scan_termination_condvar);")
        new = ("      ___CONDVAR_SIGNAL(scan_termination_condvar);\n"
               "      ___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);")
        self.assertEqual(1, self.source.count(old))
        with self.assertRaisesRegex(ValueError, "ordering differs"):
            inspect(self.source.replace(old, new, 1))

    def test_new_publisher_mutex_requires_fresh_audit(self):
        old = "      ___CONDVAR_SIGNAL(scan_termination_condvar);"
        changed = self.source.replace(old,
            "      ___MUTEX_LOCK(scan_termination_mutex);\n" + old, 1)
        with self.assertRaisesRegex(ValueError, "fresh lock audit"):
            inspect(changed)

    def test_missing_restore_or_restore_after_unlock_is_rejected(self):
        old = "          (*workers_count)++;"
        self.assertEqual(1, self.source.count(old))
        for replacement in ("", "          ___MUTEX_UNLOCK(scan_termination_mutex);\n" + old):
            with self.subTest(replacement=replacement), self.assertRaises(ValueError):
                inspect(self.source.replace(old, replacement, 1))

    def test_zero_count_restore_is_rejected(self):
        old = "          if (*workers_count == 0)\n            {"
        self.assertEqual(1, self.source.count(old))
        with self.assertRaisesRegex(ValueError, "protocol fragment"):
            inspect(self.source.replace(old, old + "\n              (*workers_count)++;", 1))

    def test_scanning_before_queue_release_is_rejected(self):
        old = "                  scan_complete_heap_chunk (___PSP ptr+1);"
        self.assertEqual(1, self.source.count(old))
        changed = self.source.replace(old, "", 1).replace(
            "                  ___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);",
            old + "\n                  ___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);", 1)
        with self.assertRaisesRegex(ValueError, "protocol fragment"):
            inspect(changed)

    def test_missing_consumer_acquire_and_publisher_fence_are_rejected(self):
        for old in (
            "      ___SHARED_MEMORY_BARRIER(); /* acquire after waiting for the ticket */",
            "      ___SHARED_MEMORY_BARRIER();\n\n      heap_chunks_to_scan_tail = new_tail;",
        ):
            self.assertEqual(1, self.source.count(old))
            with self.subTest(fragment=old), self.assertRaises(ValueError):
                inspect(self.source.replace(old, old.replace("___SHARED_MEMORY_BARRIER();", ""), 1))


if __name__ == "__main__":
    unittest.main()
