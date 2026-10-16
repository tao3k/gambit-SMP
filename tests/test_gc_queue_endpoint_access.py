"""Pinned source-scope checks, not a C memory-model or runtime proof."""
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import read_json


class QueueEndpointAccessTests(unittest.TestCase):
    def test_successor_preserves_every_other_locked_source_file(self):
        parent = read_json(ROOT / "evidence/fixtures/continuation-segment-wake-budget/source.lock.json")
        child = read_json(ROOT / "evidence/fixtures/gc-queue-endpoint-access/source.lock.json")
        self.assertEqual(parent["revision"], child["revision"])
        self.assertEqual(set(parent["files"]), set(child["files"]))
        self.assertEqual({"lib/mem.c"}, {name for name in parent["files"]
                                         if parent["files"][name] != child["files"][name]})
        self.assertEqual(child["patchSha256"], digest(ROOT / child["patch"]))
        self.assertFalse(child["runtimeAdmitted"])
        self.assertFalse(child["releaseAdmitted"])

    def test_locked_overlay_contains_load_and_all_five_store_sites(self):
        parent = read_json(ROOT / "evidence/fixtures/continuation-segment-wake-budget/source.lock.json")
        child = read_json(ROOT / "evidence/fixtures/gc-queue-endpoint-access/source.lock.json")
        old_lines = set((ROOT / parent["patch"]).read_text().splitlines())
        added = [line[1:] for line in (ROOT / child["patch"]).read_text().splitlines()
                 if line.startswith("+") and not line.startswith("+++") and line not in old_lines]
        stores = [line for line in added if "GC_QUEUE_ENDPOINT_STORE(" in line and not line.startswith("#define")]
        self.assertEqual(5, len(stores))
        text = "\n".join(added)
        self.assertIn("__atomic_load_n (&(location), __ATOMIC_RELAXED)", text)
        self.assertIn("__atomic_store_n (&(location), (value), __ATOMIC_RELAXED)", text)
        self.assertIn("defined(__GNUC__) && !defined(___SINGLE_THREADED_VMS)", text)
        self.assertIn("*GC_QUEUE_ENDPOINT_LOAD(heap_chunks_to_scan_tail)", text)
        self.assertIn("GC_QUEUE_ENDPOINT_LOAD(ps->mem.heap_chunks_to_scan_head_)", text)
        self.assertNotIn("___MUTEX_LOCK", text)
        self.assertNotIn("___SPINLOCK_LOCK", text)
