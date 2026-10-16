"""Public fixture and source-binding contracts, not native execution admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest


class PublicVmTopologyTests(unittest.TestCase):
    def setUp(self):
        self.text = (ROOT / "models/gambit/native/public_vm_topology_grid.scm").read_text()

    def test_cleanup_uses_only_existing_public_function_table(self):
        self.assertIn("___GSTATE->___cleanup_pstate(ps)", self.text)
        self.assertIn("___GSTATE->___cleanup_vmstate(vm)", self.text)
        for forbidden in ("___cleanup_owned_vmstate", "RTLD_NEXT", "dlsym", "extern ___SCMOBJ"):
            self.assertNotIn(forbidden, self.text)
        self.assertLess(self.text.index("___GSTATE->___cleanup_vmstate(vm)"),
                        self.text.index("worker->accepted = 1"))

    def test_all_host_derived_topologies_preserve_concurrency(self):
        self.assertIn('getenv("GAMBIT_SMP_AVAILABLE_CPUS")', self.text)
        self.assertIn("count <= maximum", self.text)
        self.assertIn("base + (i < remainder)", self.text)
        self.assertIn("static _Thread_local int fixture_processors", self.text)
        self.assertNotIn("threads[2]", self.text)
        self.assertNotIn("1u <<", self.text)
        self.assertIn("fixture_cycles = cpu > 16 ? (int)cpu : 16", self.text)
        self.assertLess(self.text.index("pthread_join(threads[i]"),
                        self.text.index("atomic_store(&fixture_stop, 1)"))

    def test_gc_join_and_retirement_preconditions_are_not_removed(self):
        for required in ("(##gc)", "(##thread-pin!", "(thread-join! thread)",
                         "pending_join_count", "sfun_frame_count", "(##current-vm-resize ##startup-processor! 1)",
                         "atomic_load(&fixture_interrupts) == 0", "worker->id % 2 == 0"):
            self.assertIn(required, self.text)

    def test_source_successor_keeps_exact_parent_scope(self):
        parent = json.loads((ROOT / "evidence/fixtures/public-cleanup-resource-ownership/source.lock.json").read_text())
        current = json.loads((ROOT / "evidence/fixtures/public-vm-retirement-composition/source.lock.json").read_text())
        self.assertEqual(parent["revision"], current["revision"])
        self.assertEqual(set(parent["files"]), set(current["files"]))
        self.assertEqual({"lib/setup.c"}, {name for name in current["files"]
                                           if parent["files"][name] != current["files"][name]})
        self.assertEqual(current["patchSha256"], digest(ROOT / current["patch"]))
        self.assertFalse(current["runtimeAdmitted"])
        self.assertFalse(current["releaseAdmitted"])


if __name__ == "__main__":
    unittest.main()
