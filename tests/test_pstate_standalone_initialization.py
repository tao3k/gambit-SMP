"""Source-shape controls for the standalone Quint backend adaptation."""
import unittest

from gambit_smp.framework import ROOT, digest


class PstateStandaloneInitializationTests(unittest.TestCase):
    def setUp(self):
        self.old = ROOT / ("evidence/model-results/fixtures/vm-constructor-owned-rollback/"
            "processor-publication-init-alias-denial/pstate_log_publication_rollback.qnt")
        self.current = (ROOT / "models/gambit/pstate_log_publication_rollback.qnt").read_text()

    def test_only_dedicated_initializer_is_added(self):
        self.assertEqual("db75df7b553b6ff91cc67a6283b071aad5c90cfd4875edcebd7256a55e9b17cf",
                         digest(self.old))
        start = self.current.index("  // Dedicated standalone entry")
        end = self.current.index("  action initVMOnly", start)
        self.assertEqual(self.old.read_text(), self.current[:start] + self.current[end:])

    def test_initial_domains_and_assignments_are_exact_parameter_substitution(self):
        old = self.old.read_text().split("  action initializeFor", 1)[1]
        body = old.split(" = {\n", 1)[1].split("\n  }\n", 1)[0]
        expected = body.replace("threaded", "true").replace("vmOnlyPolicy", "false").replace("cleanupPolicy", "true")
        actual = self.current.split("  action initStandaloneFixed = {\n", 1)[1].split("\n  }\n", 1)[0]
        self.assertEqual(expected, actual)
