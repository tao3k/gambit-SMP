import unittest

from gambit_smp import allocator_acquire as acquire
from gambit_smp.framework import ROOT
from gambit_smp.source_materialize import locked_source


class AllocatorAcquireTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with locked_source(ROOT, "evidence/runtime-source-026.lock.json") as (source, _):
            cls.source = (source / "lib/mem.c").read_text()

    def test_candidate_only_changes_threaded_alloc_acquire(self):
        revised = acquire.candidate(self.source)
        self.assertEqual(self.source, revised.replace(acquire.NEW, acquire.OLD, 1))
        self.assertEqual(1, revised.count("#define ALLOC_MEM_LOCK()\n"))
        self.assertIn("#define MISC_MEM_LOCK() ___SPINLOCK_LOCK(misc_mem_lock)", revised)
        self.assertIn("#define ALLOC_MEM_UNLOCK() ___SPINLOCK_UNLOCK(alloc_mem_lock)", revised)
        self.assertEqual(1, revised.count(acquire.NEW))

    def test_conditional_extraction_keeps_single_thread_branch(self):
        fragment = acquire.lock_definitions(acquire.candidate(self.source))
        self.assertTrue(fragment.startswith("#ifdef ___SINGLE_THREADED_VMS"))
        self.assertTrue(fragment.endswith("#endif\n"))
        self.assertIn("#define ALLOC_MEM_LOCK()\n", fragment)
        self.assertIn(acquire.NEW, fragment)

    def test_ambiguous_changed_or_prepatched_macro_is_denied(self):
        for source in (self.source + acquire.OLD + "\n",
                       self.source.replace(acquire.OLD, "#define ALLOC_MEM_LOCK() changed"),
                       acquire.candidate(self.source)):
            with self.subTest(source=source[:20]), self.assertRaisesRegex(ValueError, "definitions changed"):
                acquire.candidate(source)

    def test_call_site_inventory_and_unlock_drift_are_denied(self):
        for source in (self.source + "\n  ALLOC_MEM_LOCK();\n",
                       self.source.replace("#define ALLOC_MEM_UNLOCK() ___SPINLOCK_UNLOCK(alloc_mem_lock)",
                                           "#define ALLOC_MEM_UNLOCK() changed")):
            with self.assertRaises(ValueError):
                acquire.candidate(source)


if __name__ == "__main__":
    unittest.main()
